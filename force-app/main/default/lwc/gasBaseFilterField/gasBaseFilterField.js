import { api, LightningElement } from 'lwc';
import { getPageController } from 'c/veevaPageControllerFactory';

const SUPPORTED_INPUT_TYPES = new Set(['String', 'Url', 'Double', 'Currency', 'Percent']);

export default class GasBaseFilterField extends LightningElement {
  @api objectName;
  @api fieldName;
  @api pageCtrl;
  @api values = [];

  ctrl;
  label;

  // Private fields
  #fieldInfo;
  #fieldDataType;

  // Veeva Message Labels
  trueLabel;
  falseLabel;

  get selectedValues() {
    return this.values.map(value => value.value);
  }

  get isInputType() {
    return SUPPORTED_INPUT_TYPES.has(this.#fieldDataType);
  }

  get isVeevaField() {
    return this.#fieldDataType && !this.isBoolean;
  }

  get isBoolean() {
    return 'Boolean' === this.#fieldDataType;
  }

  get booleanOptions() {
    return [
      { label: this.trueLabel, value: true },
      { label: this.falseLabel, value: false },
    ];
  }

  @api
  checkValidity() {
    let errors = [...this.template.querySelectorAll("[data-validity]")].filter(
      item => item.checkValidity && item.checkValidity() === false);
    return !errors.length;
  }

  @api
  get ctrlSelectedValue() {
    return this.ctrl.veevaFieldReference ? this.ctrl.selected.id : this.ctrl.rawValue;
  }

  get ctrlSelectedLabel() {
    let selectedLabel;
    if (this.ctrl.veevaFieldReference) {
      selectedLabel = this.ctrl.selected.name;
    } else if (this.ctrl.veevaCombobox) {
      selectedLabel = this.ctrl?.picklists?.find(option => this.ctrlSelectedValue === option.value)?.label;
    }
    selectedLabel = selectedLabel ?? this.ctrl.displayValue;
    return selectedLabel;
  }

  async connectedCallback() {
    this.#fieldInfo = this.getFieldInfo();
    this.#fieldDataType = this.#fieldInfo.dataType;
    this.label = this.getLabel(this.#fieldInfo);
    this.ctrl = this.createFieldCtrl();

    await this.loadVeevaMessages();
  }

  getLabel(fieldInfo) {
    return `${this.pageCtrl.objectLabel} ${fieldInfo.label}`;
  }

  getFieldInfo() {
    return this.pageCtrl.objectInfo.getFieldInfo(this.fieldName);
  }

  createFieldCtrl() {
    const item = {
      field: this.fieldName,
      label: this.label,
      editable: true,
    };
    const ctrl = this.pageCtrl.getItemController(item);
    ctrl.initTemplate();

    if (ctrl.veevaCombobox) {
      ctrl.excludeNone = true;
    }

    return ctrl;
  }

  async loadVeevaMessages() {
    const veevaMessageService = getPageController('messageSvc');
    [this.trueLabel, this.falseLabel] = await Promise.all([
      veevaMessageService.getMessageWithDefault('BOOLEAN_TRUE', 'View', 'True'),
      veevaMessageService.getMessageWithDefault('BOOLEAN_FALSE', 'View', 'False'),
    ]);
  }

  handleFieldChange() {
    if (!this.isInputType) {
      this.addValueFromField();
    }
  }

  handleKeyUpForField(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      this.addValueFromField();
    }
  }

  setSelectedBooleanValue(event) {
    const { values } = event.detail;
    this.dispatchUpdatedValues(
      values.map(value => ({
        value,
      }))
    );
  }

  addValueFromField() {
    const value = this.ctrlSelectedValue;
    const label = this.ctrlSelectedLabel;

    // Does not add the value if the field value is empty or null
    if (!value) {
      return;
    }

    const selectedValueSet = new Set(this.values.map(val => val.value));
    if (value && label && !selectedValueSet.has(value)) {
      const updateValues = [
        ...this.values,
        {
          label,
          value,
        },
      ];
      this.dispatchUpdatedValues(updateValues);
    }
    this.resetFieldValue();
  }

  dispatchUpdatedValues(updateValues) {
    this.dispatchEvent(
      new CustomEvent('updatedvalues', {
        detail: {
          values: updateValues,
        },
      })
    );
  }

  @api
  resetFieldValue() {
    this.ctrl.setFieldValue(null);
    this.ctrl = this.createFieldCtrl();
  }
}