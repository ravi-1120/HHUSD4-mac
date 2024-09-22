import { api, LightningElement, track } from 'lwc';

const SUPPORTED_INPUT_TYPES = new Set(['String', 'Url', 'Double', 'Currency', 'Percent']);
const SUPPORTED_FIELD_TYPES = new Set([...SUPPORTED_INPUT_TYPES, 'Boolean', 'Picklist', 'Reference']);

export default class GasFilterField extends LightningElement {
  @api objectName;
  @api fieldName;
  @api pageCtrl;
  @api initValues;

  @track selectedValues = [];

  // Private fields
  #fieldInfo;
  #fieldDataType;

  get isBoolean() {
    return 'Boolean' === this.#fieldDataType;
  }

  get isSupportedFieldType() {
    return SUPPORTED_FIELD_TYPES.has(this.#fieldDataType);
  }

  get hasPills() {
    return !this.isBoolean;
  }

  get pillValues() {
    return this.selectedValues?.map(selectedValue => ({
      name: selectedValue.value,
      label: selectedValue.label,
    }));
  }

  connectedCallback() {
    this.#fieldInfo = this.getFieldInfo();
    this.#fieldDataType = this.#fieldInfo.dataType;
    this.selectedValues = this.getInitialSelectedValues();
  }

  getFieldInfo() {
    return this.pageCtrl.objectInfo.getFieldInfo(this.fieldName);
  }

  getInitialSelectedValues() {
    let selectedValues = [];
    if (this.initValues) {
      selectedValues = this.initValues.map(value => ({
        value: this.getValueForInitialValue(value),
        label: value.label,
      }));
    }
    return selectedValues;
  }

  @api
  getSelectedValues() {
    const inputNotSaved = this.getTextValuesNotIncluded();
    if (inputNotSaved){
      this.selectedValues.push(inputNotSaved);
    }
    return this.selectedValues.map(selectedValue => ({
      value: selectedValue.value,
      label: selectedValue.label,
    }));
  }

  @api
  clearSelectedValues() {
    this.selectedValues = [];
  }

  @api
  checkValidity() {
    let errors = [...this.template.querySelectorAll("[data-validity]")].filter(
      item => item.checkValidity && item.checkValidity() === false);
    return !errors.length;
  }

  getValueForInitialValue(value) {
    return this.isBoolean ? 'true' === value.value.toLowerCase() : value.value;
  }

  handleUpdatedValues(event) {
    const { values } = event.detail;
    if (values) {
      this.selectedValues = values.map(value => ({
        value: value.value,
        label: value.label ?? value.value,
      }));
    } else {
      this.selectedValues = [];
    }
  }

  removeSelectedValue(event) {
    const indexToRemove = event.detail.index;
    this.selectedValues.splice(indexToRemove, 1);
  }

  /**
   * Returns any value present for text fields not yet added to pills
   * @returns String
   */
  getTextValuesNotIncluded(){
    let inputFieldText;
    const baseFilterFieldCmp = this.baseFilterField;
    if (baseFilterFieldCmp && baseFilterFieldCmp.ctrlSelectedValue){
      inputFieldText = {
        value : baseFilterFieldCmp.ctrlSelectedValue,
        label : baseFilterFieldCmp.ctrlSelectedValue
      };
      baseFilterFieldCmp.resetFieldValue();
    }
    return inputFieldText;
  }

  get baseFilterField() {
    return this.template.querySelector('c-gas-base-filter-field');
  }
}