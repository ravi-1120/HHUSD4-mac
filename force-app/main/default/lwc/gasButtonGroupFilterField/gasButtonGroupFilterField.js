import { api, LightningElement } from 'lwc';

export default class GasButtonGroupFilterField extends LightningElement {
  _options = [];
  _maxSelectedValues;

  @api label;

  @api values = [];

  @api get maxSelectedValues() {
    return this._maxSelectedValues ?? 1;
  }

  set maxSelectedValues(value) {
    this._maxSelectedValues = value;
  }

  @api get options() {
    const options = this._options.map(value => ({
      key: `${value.label}-${value.value}`,
      label: value.label,
      value: value.value,
      variant: this.valueSet.has(value.value) ? 'brand' : 'neutral',
    }));
    return options;
  }

  set options(values) {
    this._options = values;
  }

  get valueSet() {
    return new Set(this.values);
  }

  handleSelected(event) {
    const { key } = event.target.dataset;
    const newValues = this.getNewValues(key);

    // Check to make sure we do not have too many selected items
    if (newValues.length > this.maxSelectedValues) {
      newValues.shift(); // Removes first item in array if greater than max
    }

    this.dispatchEvent(
      new CustomEvent('change', {
        detail: {
          values: newValues,
        },
      })
    );
  }

  // Determines the new values to be selected based on newValueKey just selected
  // We will find an option using newValueKey and toggle the option
  //    - if it was already selected it will be unselected
  //    - if it was not selected then it will be selected
  getNewValues(newValueKey) {
    const { value } = this.options.find(option => option.key === newValueKey);
    const selectedValueSet = new Set([...this.values]);
    let newValues;
    if (selectedValueSet.has(value)) {
      // Toggles value if it was already selected
      selectedValueSet.delete(value);
      newValues = this.values.filter(val => selectedValueSet.has(val));
    } else {
      newValues = [...this.values];
      newValues.push(value);
    }
    return newValues;
  }
}