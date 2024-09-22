import { LightningElement, api } from 'lwc';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class VeevaField extends VeevaErrorHandlerMixin(LightningElement) {
  @api ctrl;
  static delegatesFocus = true;
  currentElementSelector = '[data-validity]';
  validityElementsSelector = '[data-validity]';

  handleChange(event) {
    const changedEvent = new CustomEvent('fieldchange', { detail: event.detail });
    this.dispatchEvent(changedEvent);
  }

  get isLookup() {
    return this.ctrl.veevaFieldReference && this.ctrl.editable;
  }

  get isPreview() {
    return this.ctrl.veevaFieldReference && this.ctrl.readonly;
  }
}