import EmRelatedListController from 'c/emRelatedListController';
import getFilters from '@salesforce/apex/VeevaRelatedListFilterController.getFilters';

const FILTER_FIELDS = ['RecordTypeId'];

export default class EmEventMaterialRelatedListController extends EmRelatedListController {
  async getFilters(params) {
    return getFilters({ ...params, filterFields: FILTER_FIELDS });
  }

  showFilter() {
    return true;
  }
}