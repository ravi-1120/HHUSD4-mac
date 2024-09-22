import { LightningElement, api, track } from 'lwc';
import VeevaConstant from 'c/veevaConstant';
import { VeevaFieldError, getNestedFieldErrors, focusOn } from 'c/veevaPageFieldErrors';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class MedInqDeliveryMethod extends VeevaErrorHandlerMixin(LightningElement) {
  @api item; // zvodDeliveryMethodController

  @api get method() {
    return this._method;
  }
  set method(value) {
    this._method = value;
    this.initialize();
  }
  @api isPrimaryMethod;
  @api isLast;
  @api newOption = false; // new address, email, fax or phone
  @track selected = {};
  @track options;
  @track textCtrl;
  @track checked;
  @api recordUpdateFlag;
  @track hasSelectedBeenUpdated;
  @track hasCheckboxBeenUpdated;
  validityElementsSelector = '[data-validity]';

  get deliveryMethodDataIdAttribute() {
    const id = this.isPrimaryMethod ? 'primary' : this.method.signal;
    return `[data-veeva-delivery-method-id=${id}]`;
  }

  async initialize() {
    if (this.item && this.method) {
      this.selected = await this.item.selected(this.method.signal);
      if (this.item.actionView) {
        this.textCtrl = { label: this.method.label, displayValue: this.selected.label, editable: false, dataType: this.method.dataType };
      } else {
        this.initializeCheckbox();
        this.initializeOptions();
      }
    }
  }
  async initializeOptions() {
    let options = await this.item.options(this.method.signal);
    const newModeNotCloneNotCopy = this.item.isNewModeNotCloneNotCopy();

    let matchedOption = this.selected && options.find(x => x.value === this.selected.value);
    if (this.method && this.method.signal) {
      if (this.method.signal === 'eom') {
        matchedOption =
          this.selected &&
          options.find(
            x =>
              x.Address_Line_1_vod__c === this.selected.Address_Line_1_vod__c &&
              x.Address_Line_2_vod__c === this.selected.Address_Line_2_vod__c &&
              x.City_vod__c === this.selected.City_vod__c
          );
        if (matchedOption) {
          this.selected.label = matchedOption.value;
          this.selected.value = matchedOption.value;
        }
      }
    }
    if (!newModeNotCloneNotCopy && this.selected && this.selected.value && !matchedOption && this.newOption && this.method.checkbox) {
      this.checked = true;
    } else {
      this.checked = false;
    }
    const none = await this.item.pageCtrl.getMessageWithDefault('NONE', 'Common', '--None--');
    options = [{ label: none, value: '' }, ...options];
    this.options = options;
  }

  initializeCheckbox() {
    if (this.method.checkbox && !this.method.checkbox.setFieldValue) {
      this.method.checkbox.setFieldValue = checked => {
        this.checked = checked;
        this.selected = {};
        this.item.toggleNewOption(this.method.signal);
      };
    }
  }

  get border() {
    return !this.isLast ? 'slds-form-element_readonly' : '';
  }

  get required() {
    return this.isPrimaryMethod && !this.checked;
  }

  handleChange(event) {
    const {value} = event.target;
    const obj = this.options.find(elem => elem.value === value);
    return this.item.handleChange(obj, this.method.signal);
  }

  handleSelectedChange(event) {
    this.hasSelectedBeenUpdated = true;
    this.handleChange(event);
  }

  handleSelectedUndoClick() {
    this.hasSelectedBeenUpdated = false;
    this.item.handleChange(this.selected, this.method.signal);

    const lwcInputFields = this.template.querySelectorAll('lightning-combobox');
    if (lwcInputFields) {
      lwcInputFields.forEach(field => {
        field.value = this.selected.value;
      });
    }
  }

  handleCheckboxChange() {
    this.hasCheckboxBeenUpdated = true;
    const fieldChangeEvent = new CustomEvent('fieldchange');
    this.dispatchEvent(fieldChangeEvent);
  }

  handleCheckboxUndoClick() {
    this.hasCheckboxBeenUpdated = false;

    const undoNewFieldsEvent = new CustomEvent('undonewfields');
    this.dispatchEvent(undoNewFieldsEvent);
    this.handleSelectedUndoClick();
  }

  @api focusOn(path) { // override focusOn veevaErrorHandlerMixin  
    if (path[0] === 'lightning-combobox') {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(() => {
        this.getComboboxElement()?.focus();
      }, 100);
    } else {
      focusOn(this, path);
    }
  }

  @api getFieldErrors() { // override getFieldErrors veevaErrorHandlerMixin  
    let fieldErrors = getNestedFieldErrors(this.getDataValidityElements(), this.deliveryMethodDataIdAttribute);
    fieldErrors = [...fieldErrors, ...this.getComboboxFieldErrors()];
    return fieldErrors;
  }

  getComboboxFieldErrors() {
    const fieldErrors = [];
    const combobox = this.getComboboxElement();
    if (combobox?.reportValidity() === false) {
      fieldErrors.push(new VeevaFieldError(this.method.label, this.method.label, [this.deliveryMethodDataIdAttribute, 'lightning-combobox']));
    }
    return fieldErrors;
  }

  getComboboxElement() {
    return this.template.querySelector('lightning-combobox');
  }

  get readOnly() {
    return this.checked || (this.isPrimaryMethod && this.item.data.isFieldSet(VeevaConstant.FLD_SIGNATURE_DATE_VOD));
  }
}