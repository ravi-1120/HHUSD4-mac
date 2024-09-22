import EmEventConstant from 'c/emEventConstant';
import { toSearchColumn, emLookupToSearchRecord } from 'c/emObjectLookupSearch';
import LookupDataService from 'c/lookupDataService';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import VeevaUtils from 'c/veevaUtils';

import ATTENDEE from '@salesforce/schema/EM_Attendee_vod__c';
import EVENT_SPEAKER from '@salesforce/schema/EM_Event_Speaker_vod__c';
import TEAM_MEMBER from '@salesforce/schema/EM_Event_Team_Member_vod__c';
import VENDOR from '@salesforce/schema/EM_Vendor_vod__c';
import VENUE from '@salesforce/schema/EM_Venue_vod__c';

import EXPENSE_ATTR from '@salesforce/schema/Expense_Attribution_vod__c';
import INCURRED_EXPENSE_TYPE from '@salesforce/schema/Expense_Attribution_vod__c.Incurred_Expense_Type_vod__c';
import INCURRED_EXPENSE_ATTENDEE from '@salesforce/schema/Expense_Attribution_vod__c.Incurred_Expense_Attendee_vod__c';
import INCURRED_EXPENSE_SPEAKER from '@salesforce/schema/Expense_Attribution_vod__c.Incurred_Expense_Speaker_vod__c';
import INCURRED_EXPENSE_TEAM_MEMBER from '@salesforce/schema/Expense_Attribution_vod__c.Incurred_Expense_Team_Member_vod__c';
import INCURRED_EXPENSE_VENDOR from '@salesforce/schema/Expense_Attribution_vod__c.Incurred_Expense_Vendor_vod__c';
import INCURRED_EXPENSE_VENUE from '@salesforce/schema/Expense_Attribution_vod__c.Incurred_Expense_Venue_vod__c';
import getAttendeeIcons from '@salesforce/apex/EmExpensesController.getAttendeeIcons';

const OBJECT_TO_INCURRED_EXPENSE_FIELD = {
  [ATTENDEE.objectApiName]: INCURRED_EXPENSE_ATTENDEE.fieldApiName,
  [EVENT_SPEAKER.objectApiName]: INCURRED_EXPENSE_SPEAKER.fieldApiName,
  [TEAM_MEMBER.objectApiName]: INCURRED_EXPENSE_TEAM_MEMBER.fieldApiName,
  [VENDOR.objectApiName]: INCURRED_EXPENSE_VENDOR.fieldApiName,
  [VENUE.objectApiName]: INCURRED_EXPENSE_VENUE.fieldApiName,
};

const KNOWN_INCURRED_EXPENSE_TYPES = ['Attendee_vod', 'Event_Speaker_vod', 'Event_Team_Member_vod', 'Vendor_vod', 'Venue_vod'];

const NAME = 'Name';

export default class SelectParticipantsModalController {
  attendeeIcons = {};

  constructor(pageCtrl) {
    this.pageCtrl = pageCtrl;
    this.expenseAttrInfo = pageCtrl.expenseAttrInfo;
    this.lookupDataSvc = new LookupDataService(pageCtrl.dataSvc);
    this.splitExpenseLine = pageCtrl.getSplitExpenseLine();
    this.dataStore = getService(SERVICES.BYPASS_PROXY_DATA_STORE);
  }

  async loadMetadata() {
    [this.objectInfoMap, this.typePicklistValues] = await Promise.all([
      this.pageCtrl.uiApi.objectInfos([ATTENDEE, EVENT_SPEAKER, TEAM_MEMBER, VENDOR, VENUE].map(o => o.objectApiName)),
      this.pageCtrl.uiApi.getPicklistValues(this.expenseAttrInfo.defaultRecordTypeId, EXPENSE_ATTR.objectApiName, INCURRED_EXPENSE_TYPE.fieldApiName),
    ]);
  }

  async getViews() {
    await this.loadMetadata();
    const views = [];
    Object.entries(OBJECT_TO_INCURRED_EXPENSE_FIELD).forEach(([referenceObject, attrField]) => {
      if (this.expenseAttrInfo.fields?.[attrField] && this.objectInfoMap[referenceObject]) {
        views.push({ label: this.objectInfoMap[referenceObject].labelPlural, value: referenceObject });
      }
    });
    return views;
  }

  getInitialSelection() {
    this.nonDisplayableAttrs = [];
    const attrsToReturn = [];
    this.splitExpenseLine.attributions.forEach(a => {
      (KNOWN_INCURRED_EXPENSE_TYPES.includes(a.Incurred_Expense_Type_vod__c) ? attrsToReturn : this.nonDisplayableAttrs).push(a);
    });
    return JSON.parse(JSON.stringify(attrsToReturn));
  }

  saveAttributions(attributions) {
    return this.dataStore.put([...attributions.filter(a => VeevaUtils.validSfdcId(a.Id) || !a.Deleted), ...this.nonDisplayableAttrs]);
  }

  async search(object, term, offset, limit, sortBy, sortDir) {
    const queryParams = {
      field: OBJECT_TO_INCURRED_EXPENSE_FIELD[object],
      refTo: object,
      id: this.pageCtrl.record.rawValue('Event_vod__c'),
      q: term,
      offset,
      limit,
      sort: sortBy,
      descend: sortDir === 'desc',
    };
    const response = await this.lookupDataSvc.search(EXPENSE_ATTR.objectApiName, queryParams);

    const columns = this._processColumns(response.metadata, this.objectInfoMap[object]);
    const records = await this._processRecords(response.payload, columns, object);

    return { columns, records };
  }

  _processColumns(columns, objectInfo) {
    if (!columns) {
      return [];
    }
    let processedColumns = columns.map(column => ({
      ...toSearchColumn(column),
      sortable: !column.lookup && objectInfo.fields?.[column.name]?.sortable,
      hideDefaultActions: true,
    }));
    const nameField = EmEventConstant.OBJECT_TO_NAME_FIELD[objectInfo.apiName] ?? NAME;
    const nameColumn = processedColumns.find(col => col.fieldName === nameField);
    if (nameColumn) {
      nameColumn.type = 'text';
      nameColumn.cellAttributes = { iconName: { fieldName: 'icon' } };
    }
    if (nameField !== NAME) {
      processedColumns = processedColumns.filter(col => col.fieldName !== NAME);
    }
    return processedColumns;
  }

  async _processRecords(records, columns, object) {
    if (!records) {
      return [];
    }
    if (object === ATTENDEE.objectApiName) {
      const attendeesNeedingIcons = [];
      records.forEach(record => {
        if (!this.attendeeIcons[record.Id]) {
          attendeesNeedingIcons.push(record.Id);
        }
      });
      if (attendeesNeedingIcons.length) {
        try {
          const attendeeIcons = await getAttendeeIcons({ attendeeIds: attendeesNeedingIcons });
          this.attendeeIcons = {
            ...this.attendeeIcons,
            ...attendeeIcons,
          };
        } catch (error) {
          // ignore error
        }
      }
    }
    return records.map(record => ({
      ...emLookupToSearchRecord(record, columns),
      ...this._addMetadataToRecord(record, object),
    }));
  }

  _addMetadataToRecord(record, object) {
    const metadata = {
      Incurred_Expense_vod__c: record.Name,
      participantId: record.Id,
    };
    switch (object) {
      case ATTENDEE.objectApiName:
        metadata.icon = this.attendeeIcons[record.Id] ?? 'standard:person_account';
        metadata.Incurred_Expense_vod__c = record.Attendee_Name_vod__c;
        metadata.Incurred_Expense_Type_vod__c = 'Attendee_vod';
        metadata.Incurred_Expense_Attendee_vod__c = record.Id;
        break;
      case EVENT_SPEAKER.objectApiName:
        metadata.icon = 'custom:custom84';
        metadata.Incurred_Expense_vod__c = record.Speaker_Name_vod__c;
        metadata.Incurred_Expense_Type_vod__c = 'Event_Speaker_vod';
        metadata.Incurred_Expense_Speaker_vod__c = record.Id;
        break;
      case TEAM_MEMBER.objectApiName:
        metadata.icon = 'standard:user';
        metadata.Incurred_Expense_Type_vod__c = 'Event_Team_Member_vod';
        metadata.Incurred_Expense_Team_Member_vod__c = record.Id;
        break;
      case VENDOR.objectApiName:
        metadata.icon = 'custom:custom16';
        metadata.Incurred_Expense_Type_vod__c = 'Vendor_vod';
        metadata.Incurred_Expense_Vendor_vod__c = record.Id;
        break;
      case VENUE.objectApiName:
        metadata.icon = 'custom:custom16';
        metadata.Incurred_Expense_Type_vod__c = 'Venue_vod';
        metadata.Incurred_Expense_Venue_vod__c = record.Id;
        break;
      default:
        break;
    }
    metadata.toLabel_Incurred_Expense_Type_vod__c = this._getIncurredExpenseTypeLabel(metadata.Incurred_Expense_Type_vod__c);
    return metadata;
  }

  _getIncurredExpenseTypeLabel(type) {
    const picklistVal = this.typePicklistValues?.values?.find(value => value.value === type);
    return picklistVal?.label ?? type;
  }
}