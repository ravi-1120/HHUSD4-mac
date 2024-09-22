import { LightningElement, api, track } from 'lwc';
import { getService, SERVICES } from 'c/veevaServiceFactory';

export default class VeevaDatatableLookup extends LightningElement {
  _initialValue;

  @api context;
  @api recordId;
  @api recordtypeId;
  @api objectApiName;
  @api lookupObject;
  @api
  get initialValue() {
    return this._initialValue;
  }

  set initialValue(val) {
    this._initialValue = val;
    this.value = val;
  }

  get fieldName() {
    let base = this.context.split('__r')[0];
    base = `${base}__c`;
    return base;
  }

  @track value;

  connectedCallback() {
    this.uiSvc = getService(SERVICES.UI_API);
  }

  handleLoad() {
    const inputField = this.getInputField();
    // eslint-disable-next-line
    setTimeout(() => {
      inputField?.focus();
    }, 100);
  }

  getInputField() {
    return this.template.querySelector('lightning-input-field');
  }

  async handleChange(event) {
    const value = event.detail.value[0];
    if (!value) {
      this.dispatchCustomEvent(
        'valuechange',
        [
          {
            context: this.context,
            value: null,
            label: '',
            recordId: this.recordId,
          },
        ],
        'LookupCleared'
      );
    } else {
      const record = await this.uiSvc.getRecord(value, [`${this.lookupObject}.Name`], true);
      const label = record.fields.Name.value;
      this.dispatchCustomEvent('valuechange', [
        {
          context: this.context,
          value,
          label,
          recordId: this.recordId,
        },
      ]);
    }
  }

  @api
  async closeLookup() {
    const { value } = this.getInputField();
    const record = await this.uiSvc.getRecord(value, [`${this.lookupObject}.Name`], true);
    const label = record?.fields?.Name.value;
    this.dispatchCustomEvent('valuechange', [
      {
        context: this.context,
        value: value || null,
        label,
        recordId: this.recordId,
      },
    ]);
  }

  dispatchCustomEvent(eventName, data, source) {
    this.dispatchEvent(
      new CustomEvent(eventName, {
        composed: true,
        bubbles: true,
        cancelable: true,
        detail: {
          data,
          source,
        },
      })
    );
  }
}