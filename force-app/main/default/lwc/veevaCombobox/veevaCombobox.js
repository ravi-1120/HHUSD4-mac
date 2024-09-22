import { LightningElement, api, track } from 'lwc';
import { getFieldErrors } from 'c/veevaPageFieldErrors';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class VeevaCombobox extends VeevaErrorHandlerMixin(LightningElement) {
  @api get ctrl() {
    return this._ctrl;
  }

  set ctrl(value) {
    if (value) {
      const firstTime = this._ctrl !== value;
      this._ctrl = value;
      if (this._ctrl.track) {
        this._ctrl.track(this, 'updateOptions');
      }
      this.setOptionsAndSelected(firstTime);
    } else {
      this.selected = '';
    }
  }

  get disabled() {
    return !this.ctrl.editable || !this.hasOptions || this.ctrl.disabled;
  }

  get isDisplayable() {
    return this.options && !this.ctrl.readonly;
  }

  get hasOptions() {
    let hasOptions = this.options && this.options.length > 0;
    if (hasOptions) {
      hasOptions = this.options.length > 1 || this.options[0].value;
    }
    return hasOptions;
  }

  @api excludeNone;
  @track options;
  @track selected;
  @track label;

  async setOptionsAndSelected(firstTime) {
    const selectedValue = await this.ctrl.getSelectedOrDefaultValue(firstTime);
    const selectedLabel = this.ctrl.getLabelForValue(selectedValue);
    let options = await this.ctrl.getOptionsForValue(selectedValue, selectedLabel, firstTime, this.excludeNone);
    // re-assign to a deep copy of the proxied object for performance purposes
    if (options) {
      options = JSON.parse(JSON.stringify(options));
    }
    
    this.selected = selectedValue;
    if (this.ctrl.selected !== selectedValue) {
      this.ctrl.selected = selectedValue;
    }
    this.label = selectedLabel;
    this.options = options;
  }

  async updateOptions(value, source) {
    this.ctrl.controllingValue = value;
    await this.setOptionsAndSelected(false);
    const sourceDescription = source || 'ControllingFieldChanged';
    const changedEvent = new CustomEvent('change', { detail: sourceDescription });
    this.dispatchEvent(changedEvent);
  }

  handleChange(event) {
    this.ctrl.selected = event.target.value;
    this.selected = event.target.value;
  }

  @api checkValidity() {
    const element = this.getDataValidityElements();
    if (!element) {
      return true;
    }
    element.setCustomValidity('');
    if (element.checkValidity()) {
      this.ctrl.validate(element);
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
    return this.template.querySelector('lightning-combobox');
  }

  @api getFieldErrors() { // override getFieldErrors veevaErrorHandlerMixin
    return getFieldErrors(this, 'c-veeva-combobox');
  }
}