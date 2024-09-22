import CommandError from 'c/commandError';
import CommandHandler from './commandHandler';

export default class FirstSlidePresentationsCommand extends CommandHandler {
  constructor(veevaUserInterfaceAPI, querySvc) {
    super(veevaUserInterfaceAPI);
    this.querySvc = querySvc;
  }

  async response(config) {
    const resultMap = {};
    config.presentationIds.forEach(id => {
      resultMap[id] = null;
    });
    const presentationSlides = await this.getSlidesFromPresentations(config.presentationIds);

    const fieldsFromFirstSlidePromises = presentationSlides.map(presentation => this.getFieldsFromFirstSlide(presentation));
    const fieldsFromFirstSlideResults = await Promise.all(fieldsFromFirstSlidePromises);
    fieldsFromFirstSlideResults.forEach(result => {
      resultMap[result.id] = this.formatSlideInfo(result.fields);
    });

    return this.formatResponse(resultMap);
  }

  async getSlidesFromPresentations(presentationIds) {
    const idString = `'${presentationIds.join("','")}'`;
    const query = `Select Id, (Select Id, Key_Message_vod__c, Display_Order_vod__c from CLM_Presentation_Slide_vod__r Where Key_Message_vod__r.Active_vod__c = True ORDER BY Display_Order_vod__c Limit 1) from CLM_Presentation_vod__c where Id IN (${idString})`;
    const results = await this.performQuery(query);
    if (results.success) {
      return results.data.records;
    }

    return [];
  }

  async getFieldsFromFirstSlide(presentation) {
    const id = presentation.Id;
    if (presentation.Clm_Presentation_Slide_vod__r && presentation.Clm_Presentation_Slide_vod__r.totalSize) {
      const firstSlide = presentation.Clm_Presentation_Slide_vod__r.records[0].Key_Message_vod__c;
      const query = `SELECT Id, Name, Media_File_Name_vod__c FROM Key_Message_vod__c WHERE Id = '${firstSlide}'`;
      return { id, fields: await this.performQuery(query) };
    }

    return { id, fields: null };
  }

  async performQuery(query) {
    let response;
    try {
      response = await this.querySvc.query(query);
    } catch (e) {
      this.throwCommandError('Failed to perform query');
    }

    if (response.error) {
      const { errorStatus } = response.error;
      const errorMessages = response.error.errorData;
      const firstError = errorMessages.length > 0 ? errorMessages[0].message : '';
      const errorData = {
        errors: errorMessages,
        message: `${errorStatus} - ${firstError}`,
      };
      throw new CommandError(errorData, this.constructor.name);
    }

    return response;
  }

  formatSlideInfo(slideResponse) {
    if (slideResponse) {
      const slideInfo = slideResponse.data.records[0];
      return {
        ID: slideInfo.Id,
        Name: slideInfo.Name,
        Media_File_Name_vod__c: slideInfo.Media_File_Name_vod__c || null,
      };
    }

    return null;
  }

  formatResponse(resultMap) {
    return {
      success: true,
      data: resultMap,
    };
  }
}