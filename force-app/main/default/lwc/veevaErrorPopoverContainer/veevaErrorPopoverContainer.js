import { LightningElement, api } from 'lwc';
import { getService } from 'c/veevaServiceFactory';

export default class VeevaErrorPopoverContainer extends LightningElement {
  _recordErrors;
  _fieldErrors;
  // {Array} of Strings
  @api get recordErrors() {
    return this._recordErrors;
  }

  set recordErrors(value) {
    this._recordErrors = value;
    if (value && value.length > 0) this.showPopover = true;
  }

  // {Array} of field objects
  @api get fieldErrors() {
    return this._fieldErrors;
  }

  set fieldErrors(value) {
    this._fieldErrors = value ? this.getFieldErrorsWithIndex(value) : [];
    if (value && value.length > 0) this.showPopover = true;
  }

  // eslint-disable-next-line class-methods-use-this
  getFieldErrorsWithIndex(fieldErrors) {
    return fieldErrors.map((fieldError, index) => ({ ...fieldError, index }));
  }

  defaultErrorLabel = 'Error';
  showPopover;

  get showPopoverWrapper() {
    return this.errorsPresent && this.showPopover;
  }

  get errorsPresent() {
    return this._fieldErrors?.length > 0 || this._recordErrors?.length > 0;
  }

  connectedCallback() {
    this.template.addEventListener('errorclicked', () => {
      this.showPopover = false;
    });
    this.loadDefaultVeevaMessages();
  }

  disconnectedCallback() {
    this.template.removeEventListener('errorclicked');
  }

  async loadDefaultVeevaMessages() {
    const veevaMessageService = getService('messageSvc');
    this.defaultErrorLabel = await veevaMessageService.getMessageWithDefault('Error', 'Common', this.defaultErrorLabel);
  }

  handleClick() {
    this.showPopover = !this.showPopover;
  }

  handleClose() {
    this.showPopover = false;
    this.template.querySelector('button')?.focus();
  }
}