import { LightningElement, api } from 'lwc';

export default class VeevaDatatableTextAreaEdit extends LightningElement {
  inputRef;

  @api value;
  @api context;
  @api recordId;
  @api maxLength;

  handleChange(event) {
    event.stopPropagation();
    this.value = event.target.value;
  }

  handleKeyDown(event) {
    if (event.code === 'Enter' && !event.shiftKey) {
      this.dispatchValueChange();
    }
  }

  handleBlur(event) {
    event.stopPropagation();
    this.dispatchValueChange();
  }

  dispatchValueChange() {
    this.dispatchCustomEvent('valuechange', [
      {
        context: this.context,
        value: this.value || null,
        recordId: this.recordId,
      },
    ]);
  }

  dispatchCustomEvent(eventName, data) {
    this.dispatchEvent(
      new CustomEvent(eventName, {
        composed: true,
        bubbles: true,
        cancelable: true,
        detail: {
          data,
        },
      })
    );
  }

  renderedCallback() {
    // lightning-input is available in DOM after connectedCallback
    if (!this.inputRef) {
      this.inputRef = this.getTextArea();
      this.inputRef.focus();
    }
  }

  getTextArea() {
    return this.template.querySelector('lightning-textarea');
  }
}