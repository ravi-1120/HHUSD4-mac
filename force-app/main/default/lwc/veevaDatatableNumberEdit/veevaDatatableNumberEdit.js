import { LightningElement, api } from 'lwc';

export default class VeevaDatatableNumberEdit extends LightningElement {
  _value;
  inputRef;

  @api context;
  @api recordId;
  @api scale;

  @api get value() {
    return this._value;
  }

  set value(val) {
    this._value = val;
  }

  handleKeyDown(event) {
    if (event.code === 'Enter') {
      this.dispatchValueChange();
    }
  }

  handleChange(event) {
    event.stopPropagation();
    this.value = event.target.value;
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
      this.inputRef = this.getLightningInput();
      this.inputRef.focus();
    }
  }

  getLightningInput() {
    return this.template.querySelector('lightning-input');
  }
}