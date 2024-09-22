import { LightningElement, api, track } from 'lwc';

import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class EmSplitExpenseLineSection extends VeevaErrorHandlerMixin(LightningElement) {
  @api ctrl;
  @api recordUpdateFlag;

  get combinedRecordUpdateFlag() {
    return !this.recordUpdateFlag !== !this.page.recordUpdateFlag;
  }

  currentElementSelector = 'c-em-split-expense-line-section';
  validityElementsSelector = 'c-veeva-section';

  sections = [];
  @track expenseLineCtrl = {};
  @track page = {
    recordUpdateFlag: false,
    requests: [],
  };

  get pageReady() {
    return !!this.page.layout?.sections;
  }

  get loading() {
    return !this.pageReady || !!this.page.requests.length;
  }

  connectedCallback() {
    this.init();
  }

  async init() {
    this.expenseLineCtrl = await this.ctrl.getExpenseLinePageCtrl(this.page);
    await this.expenseLineCtrl.initPageLayout();
  }
}