import { LightningElement, api } from 'lwc';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class VeevaMpiSectionRecord extends VeevaErrorHandlerMixin(LightningElement) {
  @api ctrl;
  @api record;
  @api labelCopy;
  @api labelDel;
  @api displayAddSectionCopy;
  @api displayDeleteLink;
  @api get recordKey(){
    return this._recordKey;
  }

  set recordKey(key){
    this._recordKey = key;
    this.currentElementSelector = `[data-veeva-mpi-section-record=${this._recordKey}]`;
  }

  validityElementsSelector = 'c-veeva-row';

  copyInquiry(event) {
    this.dispatchEvent(
      new CustomEvent('copyinquiry', {
        detail: {
          id: event.target.value,
        },
      })
    );
  }

  deleteInquiry(event) {
    this.dispatchEvent(
      new CustomEvent('deleteinquiry', {
        detail: {
          id: event.target.value,
        },
      })
    );
  }
}