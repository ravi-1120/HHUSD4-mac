import verifyContentPresentOnCdn from '@salesforce/apex/MyInsightsService.verifyContentPresentOnCdn';
import CommandHandler from './commandHandler';

export default class MediaImagesSlidesCommand extends CommandHandler {
  constructor(veevaUserInterfaceAPI, myInsightsPageController) {
    super(veevaUserInterfaceAPI);
    this.myInsightsPageController = myInsightsPageController;
  }

  async response(config) {
    const resultMap = {};
    const fieldMap = await this.getCDNPathMap(config.slideIds);

    const promises = [];
    for (const id in fieldMap) {
      if (fieldMap[id]) {
        promises.push(this.getMediaImagesFromCDN(id, fieldMap[id]));
      } else {
        promises.push(this.getNullImageResponse(id));
      }
    }
    await Promise.all(promises).then(
      promises.forEach(imagePromise =>
        imagePromise.then(data => {
          resultMap[data.id] = { thumb: data.thumb, preview: data.preview };
        })
      )
    );

    return this.formatResponse(resultMap);
  }

  async getCDNPathMap(slideIds) {
    const map = {};

    const records = await this.veevaUserInterfaceApi.getBatchRecords(slideIds, ['Key_Message_vod__c.CDN_Path_vod__c']);
    if (records.length) {
      records.forEach(record => {
        if (record.fields) {
          map[record.id] = record.fields.CDN_Path_vod__c?.value;
        } else {
          this.throwCommandError(record[0].message);
        }
      });
    } else {
      this.throwCommandError(`Unable to retrieve records with ids: ${slideIds}. This may be due to an expired session.`);
    }

    return map;
  }

  async getMediaImagesFromCDN(id, cdnPath) {
    const imageResponse = { id };
    const mediaName = encodeURIComponent(cdnPath.substring(cdnPath.lastIndexOf('/') + 1, cdnPath.indexOf('.zip')));
    const rootPath = cdnPath.substring(0, cdnPath.lastIndexOf('/') + 1);

    [imageResponse.thumb, imageResponse.preview] = await Promise.all([
      this.findValidImagePath(rootPath, [`${mediaName}/${mediaName}-thumb.jpg`, `${mediaName}/${mediaName}-thumb.png`, 'thumb.png', 'thumb.jpg']),
      this.findValidImagePath(rootPath, [`${mediaName}/${mediaName}-full.jpg`, `${mediaName}/${mediaName}-full.png`, 'poster.png']),
    ]);

    return imageResponse;
  }

  async findValidImagePath(rootPath, options) {
    for (const option of options) {
      const path = `${rootPath}${option}`;
      // eslint-disable-next-line no-await-in-loop
      const token = await this.myInsightsPageController.getCdnAuthToken(path);
      if (token == null) {
        // in this case, the MC request threw an error
        this.throwCommandError('Unable to get CDN Authorization token from MC. This may be due to an expired session.');
      }
      const url = `${path}?${token}`;
      // eslint-disable-next-line no-await-in-loop
      if (await verifyContentPresentOnCdn({ requestUrl: url })) {
        return url;
      }
    }

    return null;
  }

  async getNullImageResponse(id) {
    return {
      id,
      thumb: null,
      preview: null,
    };
  }

  formatResponse(resultMap) {
    return {
      success: true,
      data: resultMap,
    };
  }
}