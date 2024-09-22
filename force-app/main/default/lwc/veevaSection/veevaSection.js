import { LightningElement, api, track } from 'lwc';
import { getNestedFieldErrors } from 'c/veevaPageFieldErrors';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';
import SectionTemplate from './veevaSection.html';

export default class VeevaSection extends VeevaErrorHandlerMixin(LightningElement) {
  @api pageCtrl;
  @api section;
  @api variant;
  @api open;
  @api first;
  @api sectionKey;
  @api record;
  @track ctrl;
  static delegatesFocus = true;
  validityElementsSelector = '[data-validity]';

  @api
  get recordUpdateFlag() {
    return this._recordUpdateFlag;
  }

  set recordUpdateFlag(value) {
    this._recordUpdateFlag = value;
    this.ctrl = this.pageCtrl.getSectionController(this.section);
  }
  
  @api refreshComponent(key){
    if (this.ctrl.shouldRefreshComponent && this.ctrl.shouldRefreshComponent(key)) {
      this._recordUpdateFlag = !this._recordUpdateFlag; 
    }else{
      const children = this.getDataValidityElements();
      children.forEach( (child) => {
        if(child.refreshComponent){
          child.refreshComponent(key);
        }
      });
    }
  }

  @api getFieldErrors() {
    if (this.pageCtrl.deleted && !this.ctrl.template) {
      return []; // skip validation for deletion
    }
    return getNestedFieldErrors(this.getDataValidityElements(), `[data-veeva-section-id='${this.sectionKey}']`);
  }

  render() {
    return this.ctrl.template || SectionTemplate;
  }
}