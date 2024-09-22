import { LightningElement, api, track } from 'lwc';
import VeevaConstant from 'c/veevaConstant';
import { getFieldErrors } from 'c/veevaPageFieldErrors';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

const RICH_TEXT_FORMATS = [
  'font',
  'size',
  'bold',
  'italic',
  'underline',
  'strike',
  'list',
  'indent',
  'align',
  'link',
  'image',
  'clean',
  'table',
  'header',
  'color',
  'background',
  'code',
  'code-block',
  'script',
  'blockquote',
  'direction',
];

export default class VeevaFieldTextArea extends VeevaErrorHandlerMixin(LightningElement) {
  @track value;
  invalidRichMessage;
  richValid = true;

  @api get ctrl() {
    return this._ctrl;
  }
  set ctrl(value) {
    this._ctrl = value;
    this.retrieveDisplayValue();
  }

  async retrieveDisplayValue() {
    this.value = await this.ctrl.displayValue;
    if (this.isRichTextArea && this.value === null) {
      // necessary to set value to empty string instead of null after undo
      // otherwise salesforce lwc doesn't update UI
      this.value = '';
    }
  }

  /**
   * slds-has-error marks invalid message red
   * white-background prevents undo yellow highlightning overflow
   */
  get richTextAreaClass() {
    return this.richValid ? '' : 'slds-has-error white-background';
  }

  handleChange(event) {
    event.preventDefault();
    window.clearTimeout(this.delayTimeout);
    const {value} = event.target;
    if (value === this.value) {
      // necessary after undo is pressed in order to not retrigger handleFieldChange in veevaItem
      // unlike other salesforce lwc as change event is fired even when value is changed via code, not only UI
      event.stopPropagation();
    } else {
      this.value = value;
      // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
      this.delayTimeout = setTimeout(() => {
        this.ctrl.setFieldValue(value);
      }, VeevaConstant.DEBOUNCE_DELAY);
    }
  }

  @api checkValidity() {
    let valid = true;

    if (this.isRichTextArea) {
      valid = this._reportRichTextValidity();
      this.richValid = valid;
    } else {
      valid = this._reportTextAreaValidity();
    }

    return valid;
  }

  _reportTextAreaValidity() {
    const textAreaElement = this.getDataValidityElements();
    textAreaElement.setCustomValidity('');
    if (textAreaElement.checkValidity && textAreaElement.checkValidity()) {
      this.ctrl.validate();
      textAreaElement.setCustomValidity(this.ctrl.getError());
    }
    return !textAreaElement.reportValidity || textAreaElement.reportValidity();
  }

  _reportRichTextValidity() {
    let valid = true;
    const requiredAndEmpty = this.ctrl.required && !this.value;
    const overMaxLength = this.value && this.value.length > this.ctrl.maxlength;
    if (requiredAndEmpty || overMaxLength || this.ctrl.getError()) {
      valid = false;
      this._setInvalidRichMessage(requiredAndEmpty, overMaxLength, this.ctrl.getError());
    }
    return valid;
  }

  async _setInvalidRichMessage(requiredAndEmpty, overMaxLength, serverErrorMsg) {
    let message;
    if (requiredAndEmpty) {
      message = await this.ctrl.pageCtrl.getMessageWithDefault('REQUIRED_VALUE', 'Account', 'Complete this field.');
    } else if (overMaxLength) {
      message = await this.ctrl.pageCtrl.getMessageWithDefault(
        'TOO_MANY_CHARS',
        'Common',
        `data value too large: ${this.value} (max length=${this.ctrl.maxlength})`
      );
      if (message.includes('{0}')) {
        message = `${message.replace('{0}', this.ctrl.maxlength)}: ${this.value}`;
      }
    } else if (serverErrorMsg) {
      message = serverErrorMsg;
    }
    this.invalidRichMessage = message;
  }

  get isRichTextArea() {
    return this.ctrl.field && this.ctrl.field.extraTypeInfo === 'RichTextArea';
  }

  get formats() {
    return RICH_TEXT_FORMATS;
  }

  @api focusOn() { // override focusOn veevaErrorHandlerMixin  
    // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
    setTimeout(() => {
      this.getDataValidityElements()?.focus();
    }, 100);
  }

  getDataValidityElements() { // override getDataValidityElements veevaErrorHandlerMixin  
    return this.template.querySelector('[data-validity]');
  }

  @api getFieldErrors() {// override getFieldErrors veevaErrorHandlerMixin  
    return getFieldErrors(this, 'c-veeva-field-text-area');
  }
}