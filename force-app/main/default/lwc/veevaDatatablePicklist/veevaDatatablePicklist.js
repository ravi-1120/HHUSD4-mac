import { LightningElement, track, api } from 'lwc';
import { getService, SERVICES } from 'c/veevaServiceFactory';

export default class VeevaDatatablePicklist extends LightningElement {
  _initialValue;
  options;

  @api context;
  @api recordId;
  @api recordtypeId;
  @api objectApiName;
  @api
  get initialValue() {
    return this._initialValue;
  }

  set initialValue(val) {
    this._initialValue = val || '';
    this.value = this._initialValue;
  }

  @track value;

  async connectedCallback() {
    this.uiSvc = getService(SERVICES.UI_API);
    this.msgSvc = getService(SERVICES.MESSAGE);
    const [msgMap, picklistValues] = await Promise.all([
      this.loadMessages(),
      this.uiSvc.getPicklistValues(this.recordtypeId, this.objectApiName, this.context),
    ]);
    this.msgMap = msgMap;
    this.options = picklistValues.values;
    this.options.unshift({ label: this.msgMap.none, value: '' });
    this.template.querySelector('lightning-combobox').focus();
  }

  async loadMessages() {
    return this.msgSvc
      .createMessageRequest()
      .addRequest('NONE', 'Common', '--None--', 'none')
      .sendRequest();
  }

  handleChange(event) {
    event.stopPropagation();
    this.value = event.detail.value;
    this.dispatchValueChange();
  }

  handleBlur(event) {
    event.stopPropagation();
    this.dispatchValueChange();
  }

  dispatchValueChange() {
    const label = this.getPicklistLabel();
    this.dispatchCustomEvent('valuechange', [
      {
        context: this.context,
        value: this.value || null,
        label,
        recordId: this.recordId,
      },
    ]);
  }

  getPicklistLabel() {
    const label = this.value === '' ? '' : this.options.find(option => option.value === this.value)?.label;
    return label;
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
}