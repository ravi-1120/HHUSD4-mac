import { api, LightningElement } from 'lwc';

export default class VeevaListViewSelector extends LightningElement {
  @api disabled;
  @api options = [];
  @api value;

  get views() {
    if (!this.options) {
      return [];
    }
    return this.getOptionsWithChecked(this.options);
  }

  get selectedOption() {
    if (!this.options) {
      return null;
    }
    return this.options.find(obj => obj.value === this.value);
  }

  get selectedLabel() {
    return this.selectedOption?.label;
  }

  getOptionsWithChecked(options) {
    return options.map(option => ({ ...option, checked: this.value === option.value }));
  }

  handleViewSelection(event) {
    const { value } = event.detail;
    if (this.value !== value) {
      this.dispatchEvent(
        new CustomEvent('change', {
          detail: {
            value,
          },
        })
      );
    }
  }
}