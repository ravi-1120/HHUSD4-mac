import FieldController from 'c/fieldController';
import VeevaUtils from 'c/veevaUtils';

export default class PicklistController extends FieldController {
  _picklistValuesPromise;
  _defaultValue;

  constructor(meta, pageCtrl, field, record) {
    super(meta, pageCtrl, field, record);

    // reset selectedValue if this is new dependent picklist without controlling value but value exists
    if (this.data.isNew && this.field.controllerName && !this.controllingValue && this.rawValue) {
      this.setFieldValue('');
    }
  }

  get isDependentPicklist() {
    return this.field.controllerName && !VeevaUtils.isEmptyObject(this._metaOptions?.controllerValues)
  }

  async getDefaultValue() {
    if (!this._defaultValue && this._defaultValue !== '') {
      let setAsDefault = '';

      const options = await this.options();
      if (options && options.defaultValue) {
        setAsDefault = options.defaultValue.value;
      }

      this._defaultValue = setAsDefault;
    }
    return this._defaultValue;
  }

  initTemplate() {
    if (this.dataType === 'MultiPicklist') {
      this.multiPicklist = true;
    } else {
      this.veevaCombobox = true;
    }
    return this;
  }

  get picklists() {
    if (!this._picklists) {
      return this.options().then(options => {
        // check if the picklist is a regular picklist
        if (!this.isDependentPicklist) {
          this._picklists = options.values;
        }
        // picklist is a dependent picklist
        else {
          // check if controlling value is accessible
          const controllerIndex = options.controllerValues[this.controllingValue];

          // controlling value is not accessible
          // add entry for the controlling value to the controllerValues map
          if (controllerIndex === undefined && this.controllingValue) {
            options.controllerValues[this.controllingValue] = this.controllingValue;

            // check if this.rawValue already exists in the options from the server
            let option = options.values.find(value => value.value === this.rawValue);

            // create new option if it doesn't exist
            if (option === undefined) {
              option = {
                label: this.displayValue,
                value: this.rawValue,
                validFor: [],
              };
              options.values.push(option);
            }

            // update the option to make it valid for the controllingValue
            option.validFor.push(this.controllingValue);
          }

          this._picklists = this.getDependentOptions(options, this.controllingValue);
        }
        return this._picklists;
      });
    }
    return this._picklists;
  }

  set picklists(value) {
    this._picklists = value;
  }

  async options() {
    if (!this._metaOptions) {
      const picklists = await this.pageCtrl.getPicklistValues(this.meta.field, this.recordTypeId);
      this._metaOptions = picklists;
    }
    return this._metaOptions;
  }

  get selected() {
    return this.rawValue;
  }

  set selected(value) {
    this.setFieldValue(value);
  }

  get controllingValue() {
    if (this._controllingVal === undefined) {
      this._controllingVal = this.data.rawValue(this.field.controllerName);
    }
    return this._controllingVal;
  }

  set controllingValue(value) {
    this.updateControllingValue(value);
  }

  get excludeNone() {
    return this._excludeNone;
  }

  set excludeNone(value) {
    this._excludeNone = value;
  }

  setFieldValue(value, reference, source) {
    let fieldValueToUse = value;

    if (source === 'UndoClick' && this.isDependentPicklist) {

      if (this.multiPicklist) {
        const hasSomeInvalidOption = value?.split(';').some(option => !this.picklists.find(p => p.value === option));
        if (hasSomeInvalidOption) {
          fieldValueToUse = '';
        }
      } else if (!this.multiPicklist && !this.picklists.find(p => p.value === value)) {
        fieldValueToUse = '';
      }
    }
    
    super.setFieldValue(fieldValueToUse, reference, source);
  }

  updateControllingValue(value) {
    this._controllingVal = value;
    if (this._metaOptions) {
      this._picklists = this.getDependentOptions(this._metaOptions, value);
      const { selected } = this;
      // remove invalid selection based on new controlling value
      if (this.multiPicklist) {
        if (selected) {
          const valid = selected.split(';').filter(x => this._picklists.find(opt => opt.value === x));
          this.setFieldValue(valid.join(';'));
        }
      } else if (!selected || !this._picklists.find(x => x.value === selected)) {
        this.setFieldValue(''); // clear selected
      }
    }
  }

  get controllerLabel() {
    let controllerLabel = '';
    if (this.field.controllerName) {
      const controllerFldMeta = this.pageCtrl.objectInfo.fields[this.field.controllerName];
      controllerLabel = controllerFldMeta ? controllerFldMeta.label : '';
    }
    return controllerLabel;
  }

  getDependentOptions(options, controllingValue) {
    const index = options.controllerValues[controllingValue];

    // controlling value is not available for the user
    if (index === undefined) {
      return [];
    }
    return options.values.filter(x => x.validFor.includes(index));
  }

  track(element, funcName) {
    if (this.field.controllerName) {
      this.pageCtrl.track(this.field.controllerName, element, funcName);
    }
  }

  async getSelectedOrDefaultValue(firstTime) {
    let selectedValue = this.selected || '';

    // handle creating a new record
    if (this.data?.isNew) {
      // reset selectedValue if this is a dependent picklist WITHOUT controlling value
      if (selectedValue && this.field.controllerName && !this.controllingValue) {
        selectedValue = '';
      } else if (!selectedValue && !this.meta.noDefaultSelected) {
        selectedValue = await this.getDefaultValue();
      }
    }

    const options = await this.picklists;
    const isNewOrNotInit = (this.data && this.data.isNew) || !firstTime;

    // reset `selectedValue`
    // if the value is not in options
    //  && it's not new or initial select
    //  && we should not persist selected picklist vlaue
    if (selectedValue && !options.find(option => option.value === selectedValue) && isNewOrNotInit) {
      selectedValue = '';
    }

    if (!selectedValue && this.required && options.length === 1) {
      selectedValue = options[0].value;
    }

    return selectedValue;
  }

  getLabelForValue(value) {
    let label = value;
    // get label for picklist value
    if (this._metaOptions) {
      const availableOptions = this._metaOptions.values;
      const matchingValue = availableOptions.find(option => option.value === value && option.label);
      const field = this.record.fields?.[this.fieldApiName];

      if (matchingValue) {
        label = matchingValue.label;
      } else if (field?.value === value && field?.displayValue) {
        label = field.displayValue;
      }
    }
    return label;
  }

  async getOptionsForValue(selectedValue, selectedLabel, firstTime, excludeNone) {
    let options = await this.picklists;
    // check if selected option is not in list of options
    if (selectedValue && selectedLabel && !options.find(option => option.value === selectedValue)) {
      const isInitAndExisting = firstTime && this.data && !this.data.isNew;
      // alllow invalid option on initialization on View and Edit
      if (isInitAndExisting) {
        options = [{ label: selectedLabel, value: selectedValue }, ...options];
      }
    }

    const requiredSingleOption = this.required && options.length === 1;
    if (!requiredSingleOption && !excludeNone) {
      const none = await this.pageCtrl.getMessageWithDefault('NONE', 'Common', '--None--');
      options = [{ label: none, value: '' }, ...options];
    }

    return options;
  }
}