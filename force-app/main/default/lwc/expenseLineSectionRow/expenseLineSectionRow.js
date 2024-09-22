import { LightningElement, api } from 'lwc';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class ExpenseLineSectionRow extends VeevaErrorHandlerMixin(LightningElement) {
  @api record;
  @api recordUpdateFlag;
  @api linesUpdatedFlag;
  @api menuAlign;
  @api get expenseLineSectionRowKey() {
    return this._expenseLineSectionRowKey;
  }

  set expenseLineSectionRowKey(key) {
    this._expenseLineSectionRowKey = key;
    this.currentElementSelector = `[data-expense-line-section-row='${this._expenseLineSectionRowKey}']`;
  }

  get rowClass() {
    return this.record.pageCtrl?.action === 'View' ? 'slds-border_bottom' : '';
  }

  validityElementsSelector = 'c-veeva-item';

  nameCtrl = {};

  handleMenuAction(event) {
    this.dispatchEvent(
      new CustomEvent('select', {
        detail: {
          action: event.detail.value,
          recordId: event.currentTarget.dataset.id,
        },
      })
    );
  }
}