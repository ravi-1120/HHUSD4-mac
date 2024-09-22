import EmRelatedListController from 'c/emRelatedListController';
import VeevaUtils from 'c/veevaUtils';
import getFilters from '@salesforce/apex/VeevaRelatedListFilterController.getFilters';

const FILTER_FIELDS = ['Role_vod__c'];

export default class EmEventTeamMemberRelatedListController extends EmRelatedListController {
  async getFilters(params) {
    return getFilters({ ...params, filterFields: FILTER_FIELDS });
  }

  /**
   * Send a delete request vs sending a save request with a Deleted flag
   */
  async doDeleteRow(rowId, objectApiName) {
    let result = {};
    try {
      result = await this.pageCtrl.dataSvc.delete(objectApiName, rowId);
    } catch (error) {
      const erroredResult = VeevaUtils.getConvertedToSaveErrorFormat(error);
      result = Promise.reject(erroredResult);
    }

    return result;
  }

  showFilter() {
    return true;
  }
}