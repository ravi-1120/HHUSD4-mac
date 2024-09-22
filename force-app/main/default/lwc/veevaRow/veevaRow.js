import { LightningElement, api } from 'lwc';
import { getNestedFieldErrors } from 'c/veevaPageFieldErrors';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class VeevaRow extends VeevaErrorHandlerMixin(LightningElement) {
  @api pageCtrl;
  @api record;
  @api row;
  @api lastRow;
  @api rowKey;
  @api recordUpdateFlag;
  static delegatesFocus = true;
  currentElementSelector;
  validityElementsSelector = 'c-veeva-item';

  get sldsItem() {
    let value = 'slds-form-element_horizontal';
    if (this.row.skipAllFormatting) {
      value = 'full-width-section';
    } else {
      if (this.row.layoutItems.length === 1 && !this.row.skipColumnStyle) {
        value += ' slds-form-element_1-col';
      }
      if (!this.row.isInsideNestedForm) {
        value += ' slds-form-element';
      }
      if (this.pageCtrl.page.action === 'View') {
        value += ' slds-m-around_none';
        if (!this.lastRow && !this.row.noBottomBorder) {
          value += ' slds-form-element_readonly'; // no bottom border
        }
      } else {
        value += ' slds-is-editing';
      }
    }
    return value;
  }

  @api getFieldErrors() {
    const checkRecord = this.record || this.pageCtrl.record;
    if (checkRecord.Deleted) {
      return [];
    }
    return getNestedFieldErrors(this.getDataValidityElements(), `[data-veeva-row-id='${this.rowKey}']`);
  }

  @api refreshComponent(key) {
    const children = this.getDataValidityElements();
    children.forEach(child => {
      if (child.refreshComponent) {
        child.refreshComponent(key);
      }
    });
  }
}