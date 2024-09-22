import { LightningElement, api, track } from 'lwc';
import { getFieldErrors } from 'c/veevaPageFieldErrors';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

// TODO #of visible lines is set to default 4 as it is not available in layout
export default class VeevaMultiPicklist extends VeevaErrorHandlerMixin(LightningElement) {
  @api get ctrl() {
    return this._ctrl;
  }
  set ctrl(value) {
    this.selected = '';
    this._ctrl = value;
    this.initialize();
    this._ctrl.track(this, 'updateOptions');
  }

  @track options;
  @track selected;

  @track labelSelected;
  @track labelAvailable;

  async connectedCallback() {
    this.labelSelected = await this.ctrl.pageCtrl.getMessageWithDefault('SELECTED_ITEMS', 'Common', 'Selected');
    this.labelAvailable = await this.ctrl.pageCtrl.getMessageWithDefault('AVAILABLE', 'Common', 'Available');
  }

  get values() {
    return this.selected ? this.selected.split(';') : [];
  }

  get disabled() {
    return !this.ctrl.editable || !this.hasOptions;
  }

  get isDisplayable() {
    return this.options && !this.ctrl.readonly;
  }

  get hasOptions() {
    return this.options && this.options.length > 0;
  }

  get selectedList() {
    return this.selected?.split(';').map(value => this.ctrl.getLabelForValue(value)).join(', ');
  }

  async initialize() {
    this.options = await this.ctrl.picklists;
    this.selected = this.ctrl.selected;
  }

  @api updateOptions(value, source) {
    this.ctrl.controllingValue = value;
    this.initialize();
    const eventSource = source || 'ControllingFieldChanged';
    const changedEvent = new CustomEvent('change', { detail: eventSource });
    this.dispatchEvent(changedEvent);
  }

  handleChange(event) {
    this.ctrl.setFieldValue(event.detail.value.join(';'));
  }

  @api checkValidity() {
    const element = this.getDataValidityElements();
    if (!element) {
      return true;
    }
    element.setCustomValidity('');
    if (element.checkValidity()) {
      this.ctrl.validate();
      element.setCustomValidity(this.ctrl.getError());
    }
    return element.reportValidity();
  }

  @api focusOn() { // override focusOn veevaErrorHandlerMixin  
    // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
    setTimeout(() => {
      this.getDataValidityElements()?.focus();
    }, 100);
  }

  getDataValidityElements() { // override getDataValidityElements veevaErrorHandlerMixin  
    return this.template.querySelector('lightning-dual-listbox');
  }

  @api getFieldErrors() { // override getFieldErrors veevaErrorHandlerMixin  
    return getFieldErrors(this, 'c-veeva-multi-picklist');
  }
}