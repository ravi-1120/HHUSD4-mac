import PicklistController from 'c/picklistController';

export default class VeevaAddressPicklistController extends PicklistController {
  constructor(meta, pageCtrl, field, record, addressService, resetCtrl) {
    super(meta, pageCtrl, field, record);
    this.addressService = addressService;
    this.resetCtrl = resetCtrl; // Tracks Undo clicks
  }

  get controllingFieldChanged() {
    const controllingField = this.field.controllerName;
    return this.data.old?.[controllingField] && this.data.fields?.[controllingField].value !== this.data.old[controllingField];
  }

  initTemplate() {
    this.veevaCombobox = true;
    return this;
  }

  async getSelectedOrDefaultValue(firstTime) {
    this._picklists = (await this.options()).values;
    let selected = this.selected || this.getDefaultAddress(firstTime);
    // Set the name for invalid selected Addess Id
    if (firstTime && selected && !this._picklists.some(el => el.value === selected) && !this.controllingFieldChanged) {
      const intitalAddress = await this.addressService.getInvalidAddress(selected);
      this._picklists.unshift(intitalAddress);
    }

    if (selected && !this._picklists.find(option => option.value === selected)) {
      selected = '';
    }
    return selected;
  }

  getDefaultAddress(firstTime) {
    let selected = '';
    if (!firstTime || (this.pageCtrl.isNew && !this.resetCtrl)) {
      selected = this.addressService.getDefaultAddress(this.controllingValue);
    }
    return selected;
  }

  // Address field pulls new options for every new account
  async options() {
    let options = [];
    if (this.controllingValue) {
      options = await this.addressService.getAddressOptions(this.controllingValue);
    }
    return { values: options };
  }
}