import { api, LightningElement } from 'lwc';
import GasFilterFieldPageController from 'c/gasFilterFieldPageController';
import { getPageController } from 'c/veevaPageControllerFactory';
import VeevaObjectInfo from 'c/veevaObjectInfo';
import VeevaRecord from 'c/veevaRecord';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ADDRESS_OBJECT from '@salesforce/schema/Address_vod__c';

export default class GasUserFilters extends LightningElement {
  // Private fields
  #objectInfos;
  #filterFieldPageCtrlsByObject;

  // Labels
  applyLabel;
  clearFilterLabel;
  filtersLabel;

  // User filters visible to user
  filters = [];

  // Validation flag
  isSelectionValid = true;

  @api show;
  @api userFilterFields = [];

  /**
   * @type {VeevaObjectInfo[]}
   */
  @api get objectInfos() {
    return this.#objectInfos;
  }

  set objectInfos(value) {
    this.#objectInfos = null;
    const objectInfos = {};
    if (value) {
      Object.entries(value).forEach(([key, objectInfo]) => {
        objectInfos[key] = new VeevaObjectInfo(objectInfo);
      });
    }
    this.#objectInfos = objectInfos;
    this.setFilterFieldPageControllers(objectInfos);
  }

  get filterFields() {
    return [...this.template.querySelectorAll('c-gas-filter-field')];
  }

  get formattedFilters() {
    return this.filterFields.map(filter => ({
      objectApiName: filter.objectName,
      fieldApiName: filter.fieldName,
      selectedOptions: filter.getSelectedValues(),
    }));
  }

  get userFiltersPanelCss() {
    const cssClasses = ['slds-panel', 'slds-panel_docked', 'slds-panel_docked-right'];
    if (this.show) {
      cssClasses.push('slds-is-open');
    }
    return cssClasses.join(' ');
  }

  @api
  checkValidity() {
    const allValid = [...this.template.querySelectorAll('[data-validity]')]
      .reduce((validSoFar, inputCmp) => validSoFar && inputCmp.checkValidity(), true);
    return allValid;
  }

  async connectedCallback() {
    await this.loadVeevaMessages();
    this.filters = this.getFilters();
  }

  async loadVeevaMessages() {
    const veevaMessageService = getPageController('messageSvc');
    await veevaMessageService.loadVeevaMessageCategories(['Common', 'Global Account Search']);

    [this.applyLabel, this.clearFilterLabel, this.filtersLabel] = await Promise.all([
      veevaMessageService.getMessageWithDefault('APPLY', 'Common', 'Apply'),
      veevaMessageService.getMessageWithDefault('CLEAR_FILTER', 'Common', 'Clear'),
      veevaMessageService.getMessageWithDefault('GAS_FILTERS', 'Global Account Search', 'Filters'),
    ]);
  }

  setFilterFieldPageControllers(objectInfos) {
    const accountObjectInfo = objectInfos[ACCOUNT_OBJECT.objectApiName];
    const addressObjectInfo = objectInfos[ADDRESS_OBJECT.objectApiName];
    const dataSvc = getPageController('dataSvc');
    const userInterfaceSvc = getPageController('userInterfaceSvc');
    const messageSvc = getPageController('messageSvc');
    const metaStore = getPageController('metaStore');
    const accountRecord = new VeevaRecord({ apiName: ACCOUNT_OBJECT.objectApiName, recordTypeId: VeevaRecord.MASTER_RECORD_TYPE_ID });
    const accountFieldPageCtrl = new GasFilterFieldPageController(dataSvc, userInterfaceSvc, messageSvc, metaStore, accountObjectInfo, accountRecord);

    const addressRecord = new VeevaRecord({ apiName: ADDRESS_OBJECT.objectApiName, recordTypeId: VeevaRecord.MASTER_RECORD_TYPE_ID });
    const addressFieldPageCtrl = new GasFilterFieldPageController(dataSvc, userInterfaceSvc, messageSvc, metaStore, addressObjectInfo, addressRecord);

    this.#filterFieldPageCtrlsByObject = {
      [ACCOUNT_OBJECT.objectApiName]: accountFieldPageCtrl,
      [ADDRESS_OBJECT.objectApiName]: addressFieldPageCtrl,
    };
  }

  getFilters() {
    return this.userFilterFields
      .filter(filter => this.objectInfos[filter.objectApiName].fields[filter.fieldApiName])
      .map(filter => {
        const key = `${filter.objectApiName}.${filter.fieldApiName}`;
        const pageCtrl = this.#filterFieldPageCtrlsByObject[filter.objectApiName];
        return {
          key,
          objectName: filter.objectApiName,
          fieldName: filter.fieldApiName,
          initValues: filter.initValues?.map(initValue => ({
            value: `${initValue.value}`,
            label: `${initValue.label}`,
          })),
          pageCtrl,
        };
      });
  }

  clearFilters() {
    this.filterFields.forEach(filter => {
      filter.clearSelectedValues();
    });
  }

  applyFilters() {
    this.isSelectionValid = true;
    if (!this.checkValidity()){
      this.isSelectionValid = false;
      return;
    }
    this.dispatchEvent(
      new CustomEvent('apply', {
        detail: {
          userFilters: this.formattedFilters,
        },
      })
    );
  }
}