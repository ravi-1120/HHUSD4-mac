import { LightningElement, wire } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import getImplicitFilters from '@salesforce/apex/VeevaGlobalAccountSearchController.getImplicitFilters';
import getLocationsWithAppliesToValues from '@salesforce/apex/VeevaGlobalAccountSearchController.getLocationsWithAppliesToValues';
import { getPageController } from 'c/veevaPageControllerFactory';
import VeevaObjectInfo from 'c/veevaObjectInfo';
import VeevaToastEvent from 'c/veevaToastEvent';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ADDRESS_OBJECT from '@salesforce/schema/Address_vod__c';
import IMPLICIT_FILTER_OBJECT from '@salesforce/schema/Implicit_Filter_vod__c';
import LOCATION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Location_vod__c';
import APPLIES_TO_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Applies_To_vod__c';
import INCLUSION_FIELD from '@salesforce/schema/Implicit_Filter_vod__c.Inclusion_vod__c';

const LOCATION_FIELD_LOWER = LOCATION_FIELD.fieldApiName.toLowerCase();
const APPLIES_TO_FIELD_LOWER = APPLIES_TO_FIELD.fieldApiName.toLowerCase();
const INCLUSION_FIELD_LOWER = INCLUSION_FIELD.fieldApiName.toLowerCase();

const actions = [
  { label: 'Edit', name: 'edit' },
  { label: 'Delete', name: 'delete' },
];

export default class GasImplicitFilters extends LightningElement {
  // Implicit Filter Details properties
  showImplicitFilterDetail = false;
  implicitFilterDetailAction;
  implicitFilterId;

  // Implicit Filters properties
  minColumnWidth = 100;
  tableMetadataReady = false;
  loadingImplicitFilters = true;
  implicitFilterKey = 'id';
  implicitFilters = [];
  implicitFiltersColumns = [
    { label: 'Location', fieldName: LOCATION_FIELD_LOWER },
    { label: 'Applies To', fieldName: APPLIES_TO_FIELD_LOWER },
    { label: 'Inclusion', fieldName: INCLUSION_FIELD_LOWER, type: 'boolean' },
    { label: 'Saved Filters', fieldName: 'filter_set' },
    { type: 'action', typeAttributes: { rowActions: actions } },
  ];
  locationsWithAppliesToValues = [];
  appliesToValues = [];

  // Labels from Veeva Messages
  gasImplicitFiltersLabel = 'Implicit Filters';
  newButtonLabel = 'New';
  errorLabel = 'Looks like something went wrong. Please log a ticket with Veeva Support.';

  objectInfos;

  @wire(getObjectInfos, { objectApiNames: [ACCOUNT_OBJECT, ADDRESS_OBJECT, IMPLICIT_FILTER_OBJECT] })
  async wireObjectInfos({ error, data: objectInfos }) {
    if (error) {
      this.setError(error);
    } else if (objectInfos) {
      const accountObjectInfo = new VeevaObjectInfo(objectInfos.results[0].result);
      const addressObjectInfo = new VeevaObjectInfo(objectInfos.results[1].result);
      const implicitFilterObjectInfo = objectInfos.results[2].result;
      this.updateLabelsUsingObjectInfo(implicitFilterObjectInfo);

      this.objectInfos = {
        [ACCOUNT_OBJECT.objectApiName]: accountObjectInfo,
        [ADDRESS_OBJECT.objectApiName]: addressObjectInfo,
        [IMPLICIT_FILTER_OBJECT.objectApiName]: implicitFilterObjectInfo,
      };
      this.tableMetadataReady = true;

      // After we retrieve the Object Infos we will retrieve our Implicit Filters and Locations with Applies To values
      const [locationsWithAppliesToValues, implicitFilters] = await Promise.all([getLocationsWithAppliesToValues(), getImplicitFilters()]);
      this.locationsWithAppliesToValues = locationsWithAppliesToValues;
      this.appliesToValues = getAppliesToValues(locationsWithAppliesToValues);
      this.implicitFilters = this.formatImplicitFilters(implicitFilters);
      this.loadingImplicitFilters = false;
    }
  }

  async connectedCallback() {
    try {
      const veevaMessageSvc = getPageController('messageSvc');
      // Separate the Promises calls because we need the System Error in case there is an error while
      // loading implicit filters and locations with applies to values.
      let filterSetLabel;
      [this.newButtonLabel, this.errorLabel, filterSetLabel] = await Promise.all([
        veevaMessageSvc.getMessageWithDefault('NEW', 'Common', this.newButtonLabel),
        veevaMessageSvc.getMessageWithDefault('ERROR_VEEVA_SUPPORT_TICKET', 'Common', this.errorLabel),
        veevaMessageSvc.getMessageWithDefault('SAVED_FILTERS', 'Global Account Search', 'Saved Filters'),
      ]);
      this.updateImplicitFiltersColumnsUsingVeevaMessageValue(filterSetLabel);
    } catch (error) {
      this.setError(this.errorLabel);
    }
  }

  formatImplicitFilters(implicitFilters) {
    const columnFieldNames = this.implicitFiltersColumns.map(column => column.fieldName);
    const expectedFields = new Set(columnFieldNames);
    expectedFields.add('id');
    const formattedImplicitFilters = implicitFilters.map(dataRecord => {
      const formattedRecord = {
        filter_set: '',
      };
      Object.keys(dataRecord)
        .filter(dataRecordField => expectedFields.has(dataRecordField.toLowerCase()))
        .forEach(dataRecordField => {
          formattedRecord[dataRecordField.toLowerCase()] = formatField(
            dataRecord,
            dataRecordField,
            this.locationsWithAppliesToValues,
            this.appliesToValues
          );
        });

      if (
        dataRecord.Implicit_Filter_Condition_vod__r?.length > 0 &&
        this.objectInfos &&
        ACCOUNT_OBJECT.objectApiName in this.objectInfos &&
        ADDRESS_OBJECT.objectApiName in this.objectInfos
      ) {
        const uniqueSelectedImplicitFilterFields = new Set(this.getJoinedConditionObjectNameAndField(dataRecord));
        const sortedSelectedImplicitFiltersFields = [...uniqueSelectedImplicitFilterFields].sort();
        formattedRecord.filter_set = sortedSelectedImplicitFiltersFields.join(', ');
      }
      return formattedRecord;
    });
    formattedImplicitFilters.sort(implicitFilterSort());
    return formattedImplicitFilters;
  }

  updateLabelsUsingObjectInfo(implicitFilterObjectInfo) {
    this.gasImplicitFiltersLabel = implicitFilterObjectInfo.labelPlural;
    const lowerCaseFieldNameMap = getLowerCaseFieldMap(implicitFilterObjectInfo);

    this.implicitFiltersColumns = this.implicitFiltersColumns.map(column => {
      let { label } = column;
      if (column.fieldName && lowerCaseFieldNameMap.has(column.fieldName)) {
        label = lowerCaseFieldNameMap.get(column.fieldName).label;
      }
      return {
        ...column,
        label,
      };
    });
  }

  updateImplicitFiltersColumnsUsingVeevaMessageValue(filterSetLabel) {
    this.implicitFiltersColumns = this.implicitFiltersColumns.map(column => {
      let { label } = column;
      if (column.fieldName === 'filter_set') {
        label = filterSetLabel;
      }
      return {
        ...column,
        label,
      };
    });
  }

  getJoinedConditionObjectNameAndField(dataRecord) {
    return dataRecord.Implicit_Filter_Condition_vod__r.map(condition => {
      const objectInfo = this.objectInfos[condition.Object_Name_vod__c];
      const objectLabel = objectInfo?.label ?? condition.Object_Name_vod__c;
      const fieldLabel = objectInfo?.fields[condition.Field_Name_vod__c]?.label ?? condition.Field_Name_vod__c;
      return `${objectLabel}.${fieldLabel}`;
    });
  }

  handleImplicitFilterRowAction(event) {
    const { action } = event.detail;
    const { row } = event.detail;
    switch (action.name) {
      case 'edit': {
        this.handleEditEvent(row);
        break;
      }
      case 'delete': {
        this.handleDeleteEvent(row);
        break;
      }
      default:
        break;
    }
  }

  handleEditEvent(row) {
    this.showImplicitFilterDetail = true;
    this.implicitFilterDetailAction = 'edit';
    this.implicitFilterId = row.id;
  }

  async handleDeleteEvent(row) {
    try {
      await deleteRecord(row.id);
    } catch (e) {
      this.setError(e);
    }
    await this.refreshImplicitFilters();
  }

  createNewImplicitFilter() {
    this.showImplicitFilterDetail = true;
    this.implicitFilterDetailAction = 'new';
    this.implicitFilterId = null;
  }

  closeImplicitFiltersDetail() {
    this.showImplicitFilterDetail = false;
  }

  doneModifyingImplicitFilter() {
    this.showImplicitFilterDetail = false;
    // We currently do not receive any information from the Implicit Filter Detail modal when it is done
    // This is why we will force a refresh when the user is done modifying.
    this.refreshImplicitFilters();
  }

  async refreshImplicitFilters() {
    this.loadingImplicitFilters = true;
    const implicitFilters = await getImplicitFilters();
    const formattedImplicitFilters = this.formatImplicitFilters(implicitFilters);
    this.implicitFilters = formattedImplicitFilters;
    this.loadingImplicitFilters = false;
  }

  setError(e) {
    const errMsg = e.body && e.body.message ? e.body.message : e;
    const error = { message: errMsg };
    this.dispatchEvent(VeevaToastEvent.error(error, 'sticky'));
  }
}

function getAppliesToValues(locationsWithAppliesToValues) {
  let appliesToValues = [];
  locationsWithAppliesToValues.forEach(locationWithAppliesTo => {
    appliesToValues = [...appliesToValues, ...locationWithAppliesTo.appliesTo];
  });
  return appliesToValues;
}

function getLowerCaseFieldMap(objectInfo) {
  const lowerCaseFieldMap = new Map();
  Object.entries(objectInfo.fields).forEach(([fieldName, field]) => {
    lowerCaseFieldMap.set(fieldName.toLowerCase(), field);
  });
  return lowerCaseFieldMap;
}

function formatField(record, field, locations, appliesToValues) {
  const recordFieldValue = record[field];
  if (recordFieldValue && field.toLowerCase() === LOCATION_FIELD_LOWER) {
    return locations.find(location => location.value === recordFieldValue).label;
  }
  if (recordFieldValue && field.toLowerCase() === APPLIES_TO_FIELD_LOWER) {
    const appliesToValue = appliesToValues.find(appliesTo => appliesTo.value === recordFieldValue);
    return appliesToValue ? appliesToValue.label : '';
  }
  return recordFieldValue;
}

function implicitFilterSort() {
  // We will perform a case-insensitive sort, where inclusion is a boolean value
  const location = x => x[LOCATION_FIELD_LOWER]?.toLowerCase();
  const appliesTo = x => x[APPLIES_TO_FIELD_LOWER]?.toLowerCase() ?? '';
  const inclusion = x => x[INCLUSION_FIELD_LOWER];

  return (first, second) => {
    const firstLocation = location(first);
    const firstAppliesTo = appliesTo(first);
    const firstInclusion = inclusion(first);

    const secondLocation = location(second);
    const secondAppliesTo = appliesTo(second);

    // Sorts Implicit Filters first by Location, then by Applies To, and finally by Inclusion where true comes first
    return firstLocation.localeCompare(secondLocation) || firstAppliesTo.localeCompare(secondAppliesTo) || (firstInclusion ? -1 : 1);
  };
}