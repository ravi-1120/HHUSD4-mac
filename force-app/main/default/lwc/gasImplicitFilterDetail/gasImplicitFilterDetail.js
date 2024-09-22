import { getRecord } from 'lightning/uiRecordApi';
import { api, LightningElement, track, wire } from 'lwc';
import IMPLICIT_FILTER_OBJ from '@salesforce/schema/Implicit_Filter_vod__c';
import LOCATION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Location_vod__c';
import APPLIES_TO_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Applies_To_vod__c';
import INCLUSION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Inclusion_vod__c';
import getLocationsWithAppliesToValues from '@salesforce/apex/VeevaGlobalAccountSearchController.getLocationsWithAppliesToValues';
import getImplicitFilterFields from '@salesforce/apex/VeevaGlobalAccountSearchController.getImplicitFilterFields';
import { getPageController } from 'c/veevaPageControllerFactory';
import VeevaToastEvent from 'c/veevaToastEvent';
import VeevaRecord from 'c/veevaRecord';
import VeevaObjectInfo from 'c/veevaObjectInfo';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ADDRESS_OBJECT from '@salesforce/schema/Address_vod__c';
import GasDisplayValueMapper from 'c/gasDisplayValueMapper';
import GasImplicitFilterService from 'c/gasImplicitFilterService';
import GasFilterFieldPageController from 'c/gasFilterFieldPageController';

const IMPLICIT_FILTER_FIELDS = [LOCATION_FIELD, APPLIES_TO_FIELD, INCLUSION_FIELD];

export default class GasImplicitFilterDetail extends LightningElement {
  @api action = 'new';
  @api filterId;

  gasImplicitFilterService = new GasImplicitFilterService();
  existingFilterConditions = [];

  locationOptions = [];
  appliesToOptions = [];
  implicitFilterMasterRecordTypeId;
  isSelectionValid = true;

  selectedLocation = null;
  selectedAppliesTo = null;
  selectedInclusion = true;
  selectedRecordTypes = [];

  gasImplicitFiltersLabel = 'Implicit Filters';
  saveButtonLabel = 'Save';
  cancelButtonLabel = 'Cancel';
  recordTypeLabel = 'Record Type';
  detailsSectionLabel = 'Details';
  filtersSectionLabel = 'Filters';
  locationFieldLabel = 'Location';
  appliesToFieldLabel = 'Applies To';
  inclusionFieldLabel = 'Inclusion';

  #objectInfos = {};
  @track filterFieldPageCtrlsByObject = {};
  @track labelOptionsByField = null;
  @track implicitFilterFields = [];
  _isLoadingImplicitFilterConditions = true;
  _isLoadingImplicitFilterFields = true;

  /**
   * objectInfos will be a map of object name to its objectInfo
   */
  @api
  get objectInfos() {
    return this.#objectInfos;
  }

  set objectInfos(objectInfoByObjectName) {
    const accountObjectInfo = objectInfoByObjectName[ACCOUNT_OBJECT.objectApiName];
    const addressObjectInfo = objectInfoByObjectName[ADDRESS_OBJECT.objectApiName];
    const implicitFilterObjectInfo = objectInfoByObjectName[IMPLICIT_FILTER_OBJ.objectApiName];
    this.retrieveLabelsFromObjectInfo(implicitFilterObjectInfo);
    this.setObjectInfoAndPageControllers(accountObjectInfo, addressObjectInfo);
  }

  get isEditMode() {
    return this.action === 'edit';
  }

  get cannotModifyAppliesTo() {
    return this.action === 'edit' || this.appliesToOptions.length === 0;
  }

  get isLoadingImplicitFilterConditions() {
    return (
      this._isLoadingImplicitFilterFields || (this.action === 'edit' && this._isLoadingImplicitFilterConditions && this.labelOptionsByField == null)
    );
  }

  get currentLocation() {
    return this.selectedLocation ? this.locationOptions.find(location => location.value === this.selectedLocation) : null;
  }

  get filterIdToRetrieve() {
    return this.hasRequiredForFilterFieldLabels() ? this.filterId : null;
  }

  get filterFields() {
    return [...this.template.querySelectorAll('c-gas-filter-field')];
  }

  get selectedFilterFieldValues() {
    return this.filterFields.flatMap(filterField =>
      filterField.getSelectedValues().map(value => ({
        objectName: filterField.objectName,
        fieldName: filterField.fieldName,
        criteria: `${value.value}`, // Cast to String since Criteria_vod must be a String
      }))
    );
  }

  get filters() {
    let filters = [];
    if (this.hasRequiredForFilterFieldLabels() && (this.action !== 'edit' || this.labelOptionsByField)) {
      filters = this.implicitFilterFields
        // Verify that the field is accessible to the user
        .filter(filterField => this.#objectInfos[filterField.objectApiName].getFieldInfo(filterField.fieldApiName))
        .map(filterField => {
          const pageCtrl = this.filterFieldPageCtrlsByObject[filterField.objectApiName];
          const initValues = this.getInitialValuesForFilterField(filterField);

          return {
            ...filterField,
            key: `${filterField.objectApiName}.${filterField.fieldApiName}`,
            pageCtrl,
            initValues,
          };
        });
    }
    return filters;
  }

  @wire(getLocationsWithAppliesToValues)
  wireLocationsWithAppliesToValues({ error, data }) {
    if (error) {
      logError(error);
    } else if (data) {
      this.locationOptions = data;
    }
  }

  @wire(getRecord, { recordId: '$filterIdToRetrieve', fields: IMPLICIT_FILTER_FIELDS })
  async wireExistingImplicitFilterInfo({ error, data }) {
    if (error) {
      logError(error);
      this._isLoadingImplicitFilterConditions = false;
    } else if (data) {
      this.selectedLocation = data.fields[LOCATION_FIELD.fieldApiName].value;
      this.selectedAppliesTo = data.fields[APPLIES_TO_FIELD.fieldApiName].value;
      this.selectedInclusion = data.fields[INCLUSION_FIELD.fieldApiName].value;
      this.appliesToOptions = this.currentLocation.appliesTo;
      await this.populateExistingFilterConditions();
      this._isLoadingImplicitFilterConditions = false;
    }
  }

  async connectedCallback() {
    await this.retrieveVeevaMessagesForLabels();
    this.implicitFilterFields = await getImplicitFilterFields();
    this._isLoadingImplicitFilterFields = false;
  }

  async retrieveVeevaMessagesForLabels() {
    const veevaMessageSvc = getPageController('messageSvc');
    await veevaMessageSvc.loadVeevaMessageCategories(['Common', 'Global Account Search']);
    const [saveButtonLabel, cancelButtonLabel, recordTypeLabel, detailsSectionLabel, filtersSectionLabel] = await Promise.all([
      veevaMessageSvc.getMessageWithDefault('SAVE', 'Common', this.saveButtonLabel),
      veevaMessageSvc.getMessageWithDefault('CANCEL', 'Common', this.cancelButtonLabel),
      veevaMessageSvc.getMessageWithDefault('RECORD_TYPE_LABEL', 'Common', this.recordTypeLabel),
      veevaMessageSvc.getMessageWithDefault('GAS_IMPLICIT_FILTERS_DETAILS', 'Global Account Search', this.detailsSectionLabel),
      veevaMessageSvc.getMessageWithDefault('GAS_FILTERS', 'Global Account Search', this.filtersSectionLabel),
    ]);
    this.saveButtonLabel = saveButtonLabel;
    this.cancelButtonLabel = cancelButtonLabel;
    this.recordTypeLabel = recordTypeLabel;
    this.detailsSectionLabel = detailsSectionLabel;
    this.filtersSectionLabel = filtersSectionLabel;
  }

  async populateExistingFilterConditions() {
    this.existingFilterConditions = await this.gasImplicitFilterService.retrieveConditions(this.filterId);
    this.labelOptionsByField = await this.getLabelOptionsByField(this.existingFilterConditions);
  }

  async getLabelOptionsByField(filterConditions) {
    const fieldsWithValues = filterConditions.map(filterCondition => ({
      key: `${filterCondition.objectName}.${filterCondition.fieldName}`,
      objectApiName: filterCondition.objectName,
      fieldApiName: filterCondition.fieldName,
      value: filterCondition.criteria,
    }));
    const gasDisplayValueMapper = new GasDisplayValueMapper(getPageController('userInterfaceSvc'));
    return gasDisplayValueMapper.generateDisplayValueMap(fieldsWithValues, this.filterFieldPageCtrlsByObject);
  }

  retrieveLabelsFromObjectInfo(implicitFilterObjectInfo) {
    this.gasImplicitFiltersLabel = implicitFilterObjectInfo.labelPlural;
    this.locationFieldLabel = implicitFilterObjectInfo.fields[LOCATION_FIELD.fieldApiName].label;
    this.appliesToFieldLabel = implicitFilterObjectInfo.fields[APPLIES_TO_FIELD.fieldApiName].label;
    this.inclusionFieldLabel = implicitFilterObjectInfo.fields[INCLUSION_FIELD.fieldApiName].label;
  }

  setObjectInfoAndPageControllers(accountObjectInfo, addressObjectInfo) {
    this.#objectInfos = {
      [ACCOUNT_OBJECT.objectApiName]: new VeevaObjectInfo(accountObjectInfo),
      [ADDRESS_OBJECT.objectApiName]: new VeevaObjectInfo(addressObjectInfo),
    };
    this.setPageControllersForGasFilterField(accountObjectInfo, addressObjectInfo);
  }

  setPageControllersForGasFilterField(accountObjectInfo, addressObjectInfo) {
    const dataSvc = getPageController('dataSvc');
    const userInterfaceSvc = getPageController('userInterfaceSvc');
    const messageSvc = getPageController('messageSvc');
    const metaStore = getPageController('metaStore');
    const accountRecord = new VeevaRecord({ apiName: ACCOUNT_OBJECT.objectApiName, recordTypeId: VeevaRecord.MASTER_RECORD_TYPE_ID });
    const accountFieldPageCtrl = new GasFilterFieldPageController(dataSvc, userInterfaceSvc, messageSvc, metaStore, accountObjectInfo, accountRecord);

    const addressRecord = new VeevaRecord({ apiName: ADDRESS_OBJECT.objectApiName, recordTypeId: VeevaRecord.MASTER_RECORD_TYPE_ID });
    const addressFieldPageCtrl = new GasFilterFieldPageController(dataSvc, userInterfaceSvc, messageSvc, metaStore, addressObjectInfo, addressRecord);

    this.filterFieldPageCtrlsByObject = {
      [ACCOUNT_OBJECT.objectApiName]: accountFieldPageCtrl,
      [ADDRESS_OBJECT.objectApiName]: addressFieldPageCtrl,
    };
  }

  getInitialValuesForFilterField(filterField) {
    return this.action === 'new'
      ? []
      : this.existingFilterConditions
          .filter(condition => condition.objectName === filterField.objectApiName && condition.fieldName === filterField.fieldApiName)
          .map(condition => {
            const conditionFieldKey = `${condition.objectName}.${condition.fieldName}`;
            const { criteria } = condition;
            return {
              value: criteria,
              label: this.labelOptionsByField[conditionFieldKey][criteria],
            };
          });
  }

  hasRequiredForFilterFieldLabels() {
    return (
      !this._isLoadingImplicitFilterFields &&
      ACCOUNT_OBJECT.objectApiName in this.filterFieldPageCtrlsByObject &&
      ACCOUNT_OBJECT.objectApiName in this.#objectInfos &&
      ADDRESS_OBJECT.objectApiName in this.filterFieldPageCtrlsByObject &&
      ADDRESS_OBJECT.objectApiName in this.#objectInfos
    );
  }

  hideImplicitFilterDetail() {
    const doneEvent = new CustomEvent('done');
    this.dispatchEvent(doneEvent);
  }

  async saveImplicitFilter() {
    this.isSelectionValid = true;
    if (!this.checkValidity()){
      this.isSelectionValid = false;
      return;
    }
    if (this.changesMade()) {
      const saved = await this.saveChanges();
      if (saved) {
        const doneEvent = new CustomEvent('done');
        this.dispatchEvent(doneEvent);
      }
    } else {
      this.handleClose();
    }
  }

  async saveChanges() {
    let couldNotCreateFilter = false;
    let filterIdToSave = this.filterId;
    if (this.action !== 'edit') {
      const [implicitFilterCreationResult] = await this.gasImplicitFilterService.createFilters([
        {
          location: this.selectedLocation,
          appliesTo: this.selectedAppliesTo,
          inclusion: this.selectedInclusion,
        },
      ]);
      couldNotCreateFilter = !implicitFilterCreationResult.success;
      if (couldNotCreateFilter) {
        this.dispatchEvent(VeevaToastEvent.error({ message: implicitFilterCreationResult.message }));
      } else {
        filterIdToSave = implicitFilterCreationResult.id;
      }
    }
    await this.gasImplicitFilterService.updateConditions(filterIdToSave, this.selectedFilterFieldValues, this.existingFilterConditions);
    return !couldNotCreateFilter;
  }

  changesMade() {
    const changesMade = this.currentLocation !== null && (!this.currentLocation.requiresAppliesToValue || this.selectedAppliesTo !== null);
    if (this.action === 'edit') {
      return changesMade && this.changesMadeToFilterFields();
    }
    return changesMade;
  }

  changesMadeToFilterFields() {
    return this.filterFields.some(filterField => {
      const initialValues = new Set(filterField.initValues.map(value => value.value));
      const selectedValues = filterField.getSelectedValues().map(value => `${value.value}`); // casts selected values to String
      return initialValues.size !== selectedValues.length || selectedValues.some(value => !initialValues.has(value));
    });
  }

  updateSelectedLocation(event) {
    this.selectedLocation = event.detail.value;
    this.appliesToOptions = this.currentLocation.appliesTo;
    this.selectedAppliesTo = null;
  }

  updateSelectedAppliesTo(event) {
    this.selectedAppliesTo = event.detail.value;
  }

  updateSelectedInclusion(event) {
    this.selectedInclusion = event.detail.checked;
  }

  handleClose() {
    const closeEvent = new CustomEvent('close');
    this.dispatchEvent(closeEvent);
  }

  get isAppliesToFieldRequired(){
    return (this.currentLocation && this.currentLocation.requiresAppliesToValue);
  }

  checkValidity(){
    const allValid = [...this.template.querySelectorAll('[data-validity]')]
        .reduce((validSoFar, inputCmp) => {
                    return validSoFar && inputCmp.checkValidity();
        }, true);
    return allValid;
  }
}

function logError(error) {
  console.log(error);
}