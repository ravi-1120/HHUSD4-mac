import getVisibleHTMLReports from "@salesforce/apex/MyInsightsService.getVisibleHTMLReports";
import CommandError from 'c/commandError';
import CommandHandler from './commandHandler';
import NavigationTarget from "../support/navigationTarget";

export default class ViewRecordCommand extends CommandHandler {
  constructor(veevaUserInterfaceAPI, veevaDataService, myInsightsController) {
    super(veevaUserInterfaceAPI);
    this.veevaDataService = veevaDataService;
    this.myInsightsController = myInsightsController;
  }

  async response(config) {
    const { object } = config.configObject;
    if (object) {
      const { fields } = config.configObject;
      const target = config.configObject.target ?? []
      const updateRecordRequest = await this.updateRecordRequest(object, fields);
      await this.navigateToViewRecord(updateRecordRequest, object, fields, target);
    }
  }

  async navigateToViewRecord(updateRecordRequest, object, fields, target) {
    try {
      // The request to CRM will determine if we support this object
      const response = await this.veevaDataService.request(updateRecordRequest);
      if (response.data.success && response.data.url) {
        // Will check for a targetId if target list is provided
        let targetId;
        if (target) {
          const htmlReports = await this.getValidReports(fields)
          targetId = NavigationTarget.findTarget(target, htmlReports)?.targetSalesforceId;
        }

        // Once we know that this object is supported we will go ahead and navigate
        this.navigateUsingLightning(object, fields, targetId);
      } else {
        this.throwCommandError(response.data.errorMessage);
      }
    } catch (e) {
      let { message } = e;
      if (e instanceof CommandError) {
        message = e.errorData.message;
      }
      this.throwCommandError(`Could not navigate to view record - ${message}`);
    }
  }

  navigateUsingLightning(object, fields, targetId) {
    // Let's find the record id from fields and make sure that fieldValue is truthy
    const recordId = this.getRecordId(fields)
    if (object && recordId) {
      this.myInsightsController.navigateToViewRecord(object, recordId, targetId);
    } else {
      this.throwCommandError(`Expected object name and id of record to view. Instead received object: ${object} and fields.Id: ${fields.Id}`);
    }
  }

  async updateRecordRequest(object, fields) {
    const request = await this.veevaDataService.initVodRequest();
    request.url += `/api/v1/smart-linking/view-record/${object}`;
    request.body = JSON.stringify(fields);
    request.method = 'POST';
    return request;
  }

  getRecordId(fields){
    return Object.entries(fields).find(([fieldName, fieldValue]) => fieldName.toLowerCase() === 'id' && fieldValue)[1];
  }

  async getValidReports(fields) {
    let htmlReports;
    const recordId = this.getRecordId(fields);
    try {
      htmlReports = await getVisibleHTMLReports({
        recordId,
        reportValue: {
          id: undefined
        }
      });
    } catch (e) {
      htmlReports = [];
    }
    return htmlReports
  }

}