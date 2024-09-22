import CommandError from 'c/commandError';
import MEDICAL_INQUIRY_OBJ from '@salesforce/schema/Medical_Inquiry_vod__c';
import MEDICAL_INSIGHT_OBJ from '@salesforce/schema/Medical_Insight_vod__c';
import CommandHandler from './commandHandler';

/**
 * This Set keeps track of Objects that currently have a LEX Creation page
 *
 * Note:
 * LEX MyInsights currently interacts with the /smart-linking endpoint in the SmartLinkingService class in crmdev
 * This endpoint has a set of Objects that it currently supports and how to create the records in most cases we will
 * use the URL provided by the endpoint, however in some cases we will use our LEX Record Creation.
 * The objects below are the objects that will use our LEX Record Creation.
 */
const OBJECTS_WITH_LEX_CREATION = new Set([
  MEDICAL_INQUIRY_OBJ.objectApiName.toLowerCase(),
  MEDICAL_INSIGHT_OBJ.objectApiName.toLowerCase(),
]);

export default class NewRecordCommand extends CommandHandler {
  constructor(veevaUserInterfaceAPI, veevaDataService, myInsightsController) {
    super(veevaUserInterfaceAPI);
    this.veevaDataService = veevaDataService;
    this.myInsightsController = myInsightsController;
  }

  async response(config) {
    const { object } = config.configObject;
    if (object) {
      const { fields } = config.configObject;
      const newRecordRequest = await this.newRecordRequest(object, fields);
      await this.navigateToNewRecord(newRecordRequest, object, fields);
    }
  }

  async navigateToNewRecord(newRecordRequest, object, fields) {
    try {
      // The request to CRM will determine if we support this object
      // For instance even if a user has access to "Account" objects we will not reach
      // navigate to create a new Account record from this newRecord command
      const response = await this.veevaDataService.request(newRecordRequest);
      if (response.data.success && response.data.url) {
        if (OBJECTS_WITH_LEX_CREATION.has(object.toLowerCase())) {
          this.myInsightsController.navigateToNewRecord(object, fields);
        } else {
          // Once we know that this object is supported we will go ahead and navigate
          this.myInsightsController.navigateToUrl(response.data.url);
        }
      } else {
        this.throwCommandError(response.data.errorMessage);
      }
    } catch (e) {
      let { message } = e;
      if (e instanceof CommandError) {
        message = e.errorData.message;
      }
      this.throwCommandError(`Could not navigate to new record url - ${message}`);
    }
  }

  async newRecordRequest(object, fields) {
    const request = await this.veevaDataService.initVodRequest();
    request.url += `/api/v1/smart-linking/new-record/${object}`;
    request.body = JSON.stringify(fields);
    request.method = 'POST';
    return request;
  }
}