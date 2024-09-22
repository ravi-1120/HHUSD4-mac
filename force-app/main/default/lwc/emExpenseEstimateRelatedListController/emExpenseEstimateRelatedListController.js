import EmRelatedListController from 'c/emRelatedListController';
import ESTIMATED_COST from '@salesforce/schema/EM_Event_vod__c.Estimated_Cost_vod__c';
import ESTIMATE from '@salesforce/schema/EM_Event_Budget_vod__c.Estimate_vod__c';

export default class EmExpenseEstimateRelatedListController extends EmRelatedListController {
  async deleteRow(rowId, objectApiName) {
    const response = await super.deleteRow(rowId, objectApiName);

    const parentRecord = this.pageCtrl.record;
    const fieldsToPoll = [ESTIMATED_COST.fieldApiName, ESTIMATE.fieldApiName];

    this.pageCtrl.refreshParentRecordUi(true, parentRecord.id, fieldsToPoll);

    return response;
  }
}