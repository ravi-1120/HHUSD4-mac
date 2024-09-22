/* eslint-disable no-unused-vars */
import ADDRESS from '@salesforce/schema/Address_vod__c';
import ACCOUNT from '@salesforce/schema/Account';
import ACCOUNT_LOOKUP from '@salesforce/schema/EM_Attendee_vod__c.Account_vod__c';
import CHILD_ACCOUNT_OBJ from '@salesforce/schema/Child_Account_vod__c';
import CHILD_ACCOUNT_LOOKUP from '@salesforce/schema/Child_Account_vod__c.Child_Account_vod__c';
import FORMATTED_NAME from '@salesforce/schema/Account.Formatted_Name_vod__c';
import NAME from '@salesforce/schema/EM_Attendee_vod__c.Name';
import USER_LOOKUP from '@salesforce/schema/EM_Attendee_vod__c.User_vod__c';
import CONTACT_LOOKUP from '@salesforce/schema/EM_Attendee_vod__c.Contact_vod__c';
import ENTITY_REFERENCE_ID from '@salesforce/schema/EM_Attendee_vod__c.Entity_Reference_Id_vod__c';
import LOCATION_ID from '@salesforce/schema/EM_Attendee_vod__c.Location_Id_vod__c';
import CHILD_ACCOUNT_ID from '@salesforce/schema/EM_Attendee_vod__c.Child_Account_Id_vod__c';
import PARENT_CHILD_NAME from '@salesforce/schema/Child_Account_vod__c.Parent_Child_Name_vod__c';
import DuplicateError from '../support/duplicateError';
import AttendeeSelectionController from './attendeeSelectionController';

const CUSTOM_BUTTON_ICON = 'customButtonIcon';
const ALL_LOCATIONS = 'all_loc';
const ALL_USERS = 'user';
const ALL_CONTACTS = 'contact';
const ATTENDEE_SEARCH_VIEWS = [ALL_USERS, ALL_CONTACTS]; // Perform attendee search for the following views
const OUTSIDE_SEARCH_SUPPORTED_VIEWS = [ALL_LOCATIONS];
const DEEFAULT_DEUPLICATE_ATTENDEE_MESSAGE = 'Duplicate Attendee for {0}';
const DUPLICATE_ICON = 'utility:warning';
const DUPLICATE_STYLE = '--slds-c-icon-color-foreground-default: #ba0517;';
const DEFAULT_SHAPE = 'circle';
const DUPLICATE_SHAPE = 'square';

export default class ChildAccountAttendeeSelectionController extends AttendeeSelectionController {
  constructor(record, relatedList, service, uiApi, veevaMessageService) {
    super(record, relatedList, service, uiApi, veevaMessageService);
    this.duplicateAttendeeMessage = DEEFAULT_DEUPLICATE_ATTENDEE_MESSAGE;
    this.getMessage({ key: 'DUPLICATE_ATTENDEE', category: 'EVENT_MANAGEMENT', defaultMessage: 'Duplicate Attendee for {0}' }).then(message => {
      this.duplicateAttendeeMessage = message;
    });
  }

  get outsideSupportedViews() {
    return OUTSIDE_SEARCH_SUPPORTED_VIEWS;
  }

  async getViews() {
    this.views = await this.service.getChildAccountViews();
    return this.views;
  }

  async getDefaultColumns(objectInfo) {
    const defaultColumns = await super.getDefaultColumns(objectInfo);
    defaultColumns.push({
      label: await this.getMessage({ key: 'EM_ADDRESS', category: 'EVENT_MANAGEMENT', defaultMessage: 'Address' }),
      fieldName: objectInfo.childRelationships.find(el => el.childObjectApiName === ADDRESS.objectApiName)?.relationshipName,
      sortable: false,
    });
    return defaultColumns;
  }

  getPills(selectedRows) {
    const duplicateRows = this.getDuplicateRows(selectedRows);
    const pills = Object.values(selectedRows) ?? [];
    return pills.map(row => this.createPill(row, duplicateRows));
  }

  getIcon(row) {
    const copy = { ...row, Id: row.childId ?? row.Id };
    const name = super.getIcon(copy);
    return name;
  }

  createPill(row, duplicateRows) {
    const isDuplicate = Boolean(duplicateRows.get(row.Id));
    let pill = {};
    if (isDuplicate) {
      pill = {
        id: row.Id,
        icon: isDuplicate ? DUPLICATE_ICON : this.getIcon(row),
        label: this.getNameForObject(row),
        shape: isDuplicate ? DUPLICATE_SHAPE : DEFAULT_SHAPE,
        ...(isDuplicate && { style: DUPLICATE_STYLE }),
      };
    } else {
      pill = super.createPill(row);
    }
    return pill;
  }

  getOutsideExistingAttendees() {
    return this.service.getOutsideExistingAttendeesWithChildAccounts(this.eventId);
  }

  getOrderBy(currentOrderBy, viewId) {
    let orderBy = currentOrderBy;
    // Assign a default order by to Parent Child Name field
    if (orderBy === NAME.fieldApiName && this.getViewObject(viewId) === ACCOUNT.objectApiName) {
      orderBy = PARENT_CHILD_NAME.fieldApiName;
    } else if (!this.objectInfo[CHILD_ACCOUNT_OBJ.objectApiName].fields?.[orderBy] && this.getViewObject(viewId) === ACCOUNT.objectApiName) {
      // Prepend a Child_Account_vod__r. to the field, if the field is not part of the Child Account Object
      orderBy = `Child_Account_vod__r.${orderBy}`;
    }
    return orderBy;
  }

  async _search(args, oot) {
    let data = [];
    if (ATTENDEE_SEARCH_VIEWS.includes(args?.viewId)) {
      return super._search(args, undefined);
    }
    if (oot) {
      args.oot = this.ootConfig;
      data = await this.service.getOutsideChildAccounts(args);
    } else {
      data = await this.service.getChildAccounts(args);
    }
    return data;
  }

  getRecordFor(fieldApiName, record) {
    if (fieldApiName === ACCOUNT_LOOKUP.fieldApiName) {
      if (record[CHILD_ACCOUNT_LOOKUP.fieldApiName]) {
        return [
          record[CHILD_ACCOUNT_LOOKUP.fieldApiName],
          {
            ...record.Child_Account_vod__r,
            childId: record.Child_Account_vod__r?.Child_Account_vod__c,
            Name: record.Child_Account_vod__r?.Parent_Child_Name_vod__c,
            IsPersonAccount: record.Child_Account_vod__r?.Child_Account_vod__r?.IsPersonAccount,
          },
        ];
      }
      // Do not show Account Records when Child Account Setting is Enabled
      return undefined;
    }
    return super.getRecordFor(fieldApiName, record);
  }

  processRecord(row, duplicateRows) {
    const record = super.processRecord(row);
    // Remove any icon on the record
    delete record[CUSTOM_BUTTON_ICON];
    if (duplicateRows.get(record.Id)) {
      record[CUSTOM_BUTTON_ICON] = {
        type: 'warning',
        tooltip: this.duplicateAttendeeMessage.replace('{0}', this.getRowDuplicateName(row)),
      };
    }
    return record;
  }

  getDuplicateRows(selectedRows) {
    const childIdMap = new Map();
    const idToRecordMap = new Map();

    Object.entries(selectedRows).forEach(([key, record]) => {
      const { childId } = record;
      if (childId) {
        const existingRecords = childIdMap.get(childId) || [];
        existingRecords.push(record);
        childIdMap.set(childId, existingRecords);
      }
    });

    // Filter out the unique values
    Array.from(childIdMap.values())
      .filter(records => records.length > 1)
      .flat()
      .forEach(record => idToRecordMap.set(record.Id, record));

    return idToRecordMap;
  }

  getAttendeesToAdd(selectedAttendees, recordType) {
    const duplicates = this.getDuplicateRows(selectedAttendees);
    if (duplicates.size > 0) {
      const erroredNames = new Set();
      duplicates.forEach((record, recordId) => {
        erroredNames.add(this.getRowDuplicateName(record));
      });
      throw new DuplicateError(Array.from(erroredNames));
    }
    return super.getAttendeesToAdd(selectedAttendees, recordType);
  }

  getRowDuplicateName(row) {
    return row.IsPersonAccount ? `${row.LastName} ${row.FirstName}` : row[FORMATTED_NAME.fieldApiName];
  }

  getAttendeeToAdd(recordType, id, record) {
    const attendee = super.getAttendeeToAdd(recordType, record.childId ?? id, record);
    if (record.outside) {
      // Trigger Uses 3 text fields to stamp Account, Location, and Child Account lookups to avoid corss-reference error for OOT records
      attendee[LOCATION_ID.fieldApiName] = record.parentId;
      attendee[CHILD_ACCOUNT_ID.fieldApiName] = id;
    } else if (attendee[ACCOUNT_LOOKUP.fieldApiName]) {
      attendee[CHILD_ACCOUNT_LOOKUP.fieldApiName] = id;
    }
    return attendee;
  }

  getRelatedRecordId(attendee) {
    return attendee[CHILD_ACCOUNT_LOOKUP.fieldApiName] || attendee[USER_LOOKUP.fieldApiName] || attendee[CONTACT_LOOKUP.fieldApiName];
  }
}