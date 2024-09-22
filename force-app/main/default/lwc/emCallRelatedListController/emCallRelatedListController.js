import VeevaRelatedListController from 'c/veevaRelatedListController';
import STUB_SFDC_ID from '@salesforce/schema/EM_Event_vod__c.Stub_SFDC_Id_vod__c';

export default class EmCallRelatedListController extends VeevaRelatedListController {
  // eslint-disable-next-line no-unused-vars
  getPageRefForNew(context) {
    const queryParams = {
      queryParams: `&id=${this.pageCtrl.record.rawValue(STUB_SFDC_ID.fieldApiName)}&retUrl=/${this.pageCtrl.recordId}&typ=Event`,
    };
    return {
      type: 'standard__webPage',
      attributes: {
        url: `/apex/Call_New_vod?${new URLSearchParams(queryParams).toString()}&EMEventId=${this.pageCtrl.recordId}`,
      },
    };
  }
}