import VeevaRelatedListController from 'c/veevaRelatedListController';

const HISTORY_RELATIONSHIP = 'ActivityHistories';

export default class VeevaTasksRelatedListController extends VeevaRelatedListController {
  #objectDescribePromise = this.pageCtrl.uiApi.getObjectInfoFromRestApi('Task').then(result => {
    this.objectDescribe = result;
  });

  get iconName() {
    return 'custom:custom19';
  }

  get isHistoryList() {
    return this.meta.relationship === HISTORY_RELATIONSHIP;
  }

  async getButtons() {
    if (this.isHistoryList) {
      return [];
    }
    await this.#objectDescribePromise;
    return super.getButtons();
  }

  async getColumns() {
    await this.#objectDescribePromise;
    return super.getColumns();
  }

  async fetchRecords(params) {
    return super.fetchRecords(this.addFilterToParams(params));
  }

  async fetchRecordsWithTotals(params) {
    return super.fetchRecordsWithTotals(this.addFilterToParams(params));
  }

  addFilterToParams(params) {
    const filters = { IsClosed: [this.isHistoryList] };
    return { ...params, filters };
  }

  // eslint-disable-next-line no-unused-vars
  getPageRefForNew(context) {
    const showRtSelector = Object.values(this.objectDescribe.recordTypeInfos).filter(rt => rt.available && !rt.master).length > 1;
    const queryParams = new URLSearchParams({
      objectType: 'Task',
      veevaModule: 'pl',
      veevaPage: 'edit',
      retUrl: `/${this.pageCtrl.id}`,
      hasRecordTypes: showRtSelector,
      queryParams: `WhatId=${this.pageCtrl.id}&retUrl=/${this.pageCtrl.id}`,
    }).toString();
    const url = `/apex/SObject_New_vod?${queryParams}`;
    return {
      type: 'standard__webPage',
      attributes: { url },
    };
  }
}