/* eslint-disable no-param-reassign */
/* eslint-disable class-methods-use-this */
import ID from '@salesforce/schema/EM_Attendee_vod__c.Id';
import EM_ATTENDEE from '@salesforce/schema/EM_Attendee_vod__c';
import NAME from '@salesforce/schema/EM_Attendee_vod__c.Name';
import ATTENDEE_NAME from '@salesforce/schema/EM_Attendee_vod__c.Attendee_Name_vod__c';
import ACCOUNT from '@salesforce/schema/Account';
import IS_PERSON_ACCOUNT from '@salesforce/schema/Account.IsPersonAccount';
import FORMATTED_NAME from '@salesforce/schema/Account.Formatted_Name_vod__c';
import USER from '@salesforce/schema/User';
import CONTACT from '@salesforce/schema/Contact';
import ACCOUNT_LOOKUP from '@salesforce/schema/EM_Attendee_vod__c.Account_vod__c';
import USER_LOOKUP from '@salesforce/schema/EM_Attendee_vod__c.User_vod__c';
import CONTACT_LOOKUP from '@salesforce/schema/EM_Attendee_vod__c.Contact_vod__c';
import ENTITY_REFERENCE_ID from '@salesforce/schema/EM_Attendee_vod__c.Entity_Reference_Id_vod__c';
import RECORD_TYPE from '@salesforce/schema/EM_Attendee_vod__c.RecordTypeId';
import EVENT_CONFIG from '@salesforce/schema/EM_Event_vod__c.Event_Configuration_vod__c';
import COUNTRY from '@salesforce/schema/EM_Event_vod__c.Country_vod__c';
import CHILD_ACCOUNT_OBJ from '@salesforce/schema/Child_Account_vod__c';
import PARENT_ACCOUNT_LOOKUP from '@salesforce/schema/Child_Account_vod__c.Parent_Account_vod__c';
import CHILD_ACCOUNT_LOOKUP from '@salesforce/schema/Child_Account_vod__c.Child_Account_vod__c';
import EmBusRuleWarningsModal from 'c/emBusRuleWarningsModal';
import { BusRuleConstant } from 'c/emBusRuleUtils';
import EmEventConstant from 'c/emEventConstant';

const ALL_ACCOUNTS = 'all';
const ALL_PERSON_ACCOUNTS = 'per';
const ALL_BUSINESS_ACCOUNTS = 'bus';
const ALL_USERS = 'user';
const ALL_CONTACTS = 'contact';
const CUSTOM_BUTTON_ICON = 'customButtonIcon';
const ATTENDEE_FIELD_KEYWORDS = ['Address', 'LastTopic', 'RecentEvents', 'MCCP'];
const DEFAULT_QUERY_FIELDS = [NAME.fieldApiName];
const ACCOUNT_DEFAULT_QUERY_FIELDS = [FORMATTED_NAME.fieldApiName, IS_PERSON_ACCOUNT.fieldApiName];
const OOT_ICON_BACKGROUD_COLOR = '#706e6b';
const OUTSIDE_SEARCH_SUPPORTED_VIEWS = [ALL_ACCOUNTS, ALL_PERSON_ACCOUNTS, ALL_BUSINESS_ACCOUNTS];

export default class AttendeeSelectionController {
  constructor(record, relatedList, service, uiApi, veevaMessageService) {
    this.record = record;
    this.relatedList = relatedList;
    this.service = service;
    this.uiApi = uiApi;
    this.veevaMessageService = veevaMessageService;
    this.canRemoveAll = true;
    this.viewsIds = {};
    this.initialAttendeesOnEvent = [];
    this.viewIdToAttendeeCountCache = {}; // Prevents re-querying attendee counts on infininite scrolling
  }

  get eventId() {
    return this.getFieldValue(ID.fieldApiName);
  }

  get pageTitleMessage() {
    return { key: 'SELECT_ATTENDEE', category: 'EVENT_MANAGEMENT', defaultMessage: 'Select Attendees' };
  }

  get ootEnabled() {
    return Boolean(this.ootConfig?.enabled);
  }

  get showAttendeeResultTruncatedWarning() {
    return this.soqlQueryCount > EmEventConstant.ATTENDEE_SELCTION_SOQL_LIMIT;
  }

  getFieldValue(field) {
    return this.record?.fields[field]?.value;
  }

  async getToggle() {
    let ootToggle = null;
    this.ootConfig = await this.service.getOutsideTerritoryConfig(
      this.eventId,
      this.getFieldValue(EVENT_CONFIG.fieldApiName),
      this.getFieldValue(COUNTRY.fieldApiName)
    );
    if (this.ootConfig?.enabled) {
      ootToggle = {
        label: await this.getMessage({ key: 'INCLUDE_OUTSIDE_TERRITORY', category: 'EVENT_MANAGEMENT', defaultMessage: 'Include Outside Territory' }),
        disableArgs: ['currentView'], // Must be property on emSelectionPage
        disable: view => !this.outsideSupportedViews.includes(view),
      };
    }
    return ootToggle;
  }

  get outsideSupportedViews() {
    return OUTSIDE_SEARCH_SUPPORTED_VIEWS;
  }

  async getMessage(msg) {
    return this.veevaMessageService.getMessageWithDefault(msg.key, msg.category, msg.defaultMessage);
  }

  async getObjectInfo(view) {
    if (!this.objectInfo) {
      const objects = [EM_ATTENDEE.objectApiName, ACCOUNT.objectApiName, USER.objectApiName, CONTACT.objectApiName, CHILD_ACCOUNT_OBJ.objectApiName];
      this.objectInfo = await this.uiApi.objectInfos(objects);
      objects.forEach(objectName => {
        if (!this.objectInfo[objectName]) {
          this.objectInfo[objectName] = {
            fields: {},
          };
        }
      });
    }
    return this.objectInfo[this.getViewObject(view)];
  }

  async getViews() {
    const accountId = this.record.fields?.Account_vod__c?.value;
    this.views = await this.service.getViews();
    if (accountId) {
      const accountRecord = await this.uiApi.getRecord(accountId, [
        `${ACCOUNT.objectApiName}.${IS_PERSON_ACCOUNT.fieldApiName}`,
        `${ACCOUNT.objectApiName}.${FORMATTED_NAME.fieldApiName}`,
      ]);
      if (accountRecord.fields?.[IS_PERSON_ACCOUNT.fieldApiName]?.value === false) {
        const defaultHierarchyView = {
          label: accountRecord.fields?.[FORMATTED_NAME.fieldApiName]?.value,
          value: accountRecord.id,
          prefixIconName: 'utility:hierarchy',
          hierarchy: true,
        };
        this.views.unshift(defaultHierarchyView);
      }
    }
    return this.views;
  }

  async getViewIds(viewId) {
    if (!this.viewsIds[viewId]) {
      this.viewsIds[viewId] = this.service.getAccountsForView(viewId);
    }
    return this.viewsIds[viewId];
  }

  getViewObject(view) {
    let object = ACCOUNT.objectApiName;
    if (view === ALL_USERS) {
      object = USER.objectApiName;
    } else if (view === ALL_CONTACTS) {
      object = CONTACT.objectApiName;
    }
    return object;
  }

  getPills(selectedRows) {
    const pills = Object.values(selectedRows) ?? [];
    return pills.map(row => this.createPill(row));
  }

  getIcon(row) {
    let iconName = this.getObjectType(row.Id).toLowerCase();
    if (row[IS_PERSON_ACCOUNT.fieldApiName]) {
      iconName = `person_${iconName}`;
    }
    return `standard:${iconName}`;
  }

  createPill(row) {
    const icon = this.getIcon(row);
    const pill = {
      id: row.Id,
      icon,
      label: this.getNameForObject(row),
      shape: 'circle',
    };
    if (row.outside) {
      pill.style = `--veeva-pill-icon-color-background: ${OOT_ICON_BACKGROUD_COLOR}`;
    }
    return pill;
  }

  getNameForObject(record) {
    let nameField = NAME.fieldApiName;
    if (this.getObjectType(record.Id) === ACCOUNT.objectApiName) {
      nameField = FORMATTED_NAME.fieldApiName;
    }
    return record[nameField];
  }

  async getAttendeeFields(obj) {
    if (!this.attendeeFields) {
      this.attendeeFields = await this.service.getAttendeeFields(this.eventId);
    }
    return this.attendeeFields[obj];
  }

  isHierarchyEnabled() {
    const childAccountObjInfo = this.objectInfo[CHILD_ACCOUNT_OBJ.objectApiName];
    return (
      childAccountObjInfo?.queryable === true &&
      childAccountObjInfo.fields[PARENT_ACCOUNT_LOOKUP.fieldApiName] &&
      childAccountObjInfo.fields[CHILD_ACCOUNT_LOOKUP.fieldApiName]
    );
  }

  async getDefaultColumns(objectInfo) {
    return [
      {
        label: objectInfo.fields[NAME.fieldApiName].label,
        fieldName: NAME.fieldApiName,
      },
    ];
  }

  async getColumns(view) {
    const viewObject = this.getViewObject(view);
    const [objectInfo, attendeeFields] = await Promise.all([this.getObjectInfo(view), this.getAttendeeFields(viewObject)]);
    let defaultQueryFields = DEFAULT_QUERY_FIELDS;
    if (viewObject === ACCOUNT.objectApiName) {
      defaultQueryFields = defaultQueryFields.concat(ACCOUNT_DEFAULT_QUERY_FIELDS);
    }
    this.queryFields = defaultQueryFields;

    const attendeeFieldsToQuery = attendeeFields
      ?.filter(field => !field.isKeyword && !defaultQueryFields.includes(field.apiName))
      .map(field => field.apiName);
    if (attendeeFieldsToQuery?.length > 0) {
      this.queryFields = this.queryFields.concat(attendeeFieldsToQuery);
    }

    const columns = await this.getDefaultColumns(objectInfo);
    this.columns = columns.concat(
      attendeeFields
        .filter(field => !ATTENDEE_FIELD_KEYWORDS.includes(field.apiName) && NAME.fieldApiName !== field.apiName)
        .map(field => ({
          label: field.label,
          fieldName: field.apiName,
        }))
    );
    if (this.isHierarchyEnabled()) {
      this.columns.unshift({
        fieldName: CUSTOM_BUTTON_ICON,
      });
    }
    return this.columns;
  }

  async search(term, filters, orderBy, orderDirection, limit, offset) {
    let data = [];
    const viewId = filters?.find(filter => filter.view)?.value;
    const oot = this.ootEnabled && filters?.find(filter => filter.toggle)?.value;
    orderBy = this.getOrderBy(orderBy, viewId);
    try {
      const args = {
        fields: this.queryFields,
        orderBy,
        orderDirection,
        qLimit: limit,
        offset,
        viewId,
        includeAddress: false,
        useCustomFieldFormatting: false,
      };
      if (term) {
        args.termString = term;
      }
      if (this.views.find(v => viewId === v.value)?.customView) {
        args.viewAccountIds = await this.getViewIds(viewId);
      }
      data = await this._search(args, oot);
    } catch (ex) {
      data = [];
    }
    return data;
  }

  getOrderBy(currentOrderBy, viewId) {
    let orderBy = currentOrderBy;
    if (orderBy === NAME.fieldApiName && this.getViewObject(viewId) === ACCOUNT.objectApiName) {
      orderBy = FORMATTED_NAME.fieldApiName;
    }
    return orderBy;
  }

  async _search(args, oot) {
    this.soqlQueryCount = 0;
    let soqlQueryCountPromise = Promise.resolve(0);
    let data = [];
    if (!args.termString) {
      soqlQueryCountPromise = this.viewIdToAttendeeCountCache[args.viewId] ?? this.getSoqlQueryCount(args, oot);
    }
    if (oot) {
      args.oot = this.ootConfig;
      [data, this.soqlQueryCount] = await Promise.all([this.service.getOutsideAttendees(args), soqlQueryCountPromise]);
    } else {
      [data, this.soqlQueryCount] = await Promise.all([this.service.getAttendees(args), soqlQueryCountPromise]);
    }
    if (!args.termString) {
      this.viewIdToAttendeeCountCache[args.viewId] = this.viewIdToAttendeeCountCache[args.viewId] ?? this.soqlQueryCount;
    }
    return data;
  }

  async getSoqlQueryCount(args, oot) {
    let soqlQueryCount = 0;
    if (oot) {
      args.oot = this.ootConfig;
      soqlQueryCount = this.service.getOutsidetAttendeeSoqlCount(args);
    } else {
      soqlQueryCount = this.service.getAttendeeSoqlCount(args);
    }
    return soqlQueryCount;
  }

  processRecord(row) {
    row.icon = {
      name: this.getIcon(row),
    };
    if (row.outside) {
      row.icon.style = `--sds-c-icon-color-background: ${OOT_ICON_BACKGROUD_COLOR}`;
    }
    if (this.isHierarchyEnabled() && row[IS_PERSON_ACCOUNT.fieldApiName] === false && (row.outside === undefined || row.outside === null)) {
      row[CUSTOM_BUTTON_ICON] = {
        type: 'hierarchy',
      };
    }
    return row;
  }

  async getExistingRecords() {
    if (this.ootEnabled) {
      this.initialAttendeesOnEvent = await this.getOutsideExistingAttendees();
    } else {
      this.initialAttendeesOnEvent = await this.service.getExistingAttendees(this.eventId);
    }
    this.getDeletableAttendeeTypes(this.initialAttendeesOnEvent);
    return this.initialAttendeesOnEvent?.reduce((obj, record) => {
      let lookupId = '';
      let relatedRecord = {};
      [lookupId, relatedRecord] =
        this.getRecordFor(ACCOUNT_LOOKUP.fieldApiName, record) ||
        this.getRecordFor(USER_LOOKUP.fieldApiName, record) ||
        this.getRecordFor(CONTACT_LOOKUP.fieldApiName, record) ||
        this.getRecordFor(undefined);

      // if no account/user/contact/childAccount then we don't include the record
      if (lookupId !== '' && Object.keys(relatedRecord).length > 0) {
        obj[lookupId] = relatedRecord;
        if (this.ootEnabled) {
          obj[lookupId].outside = record.outside;
        }
      }
      return obj;
    }, {});
  }

  getOutsideExistingAttendees() {
    return this.service.getOutsideExistingAttendees(this.eventId);
  }

  /**
   * @param {*} fieldApiName
   * @param {*} record containing a several related records, i.e User_vod__r
   * @returns Either a [lookupId, relatedRecord] pair OR undefined
   * undefined return is used to simplify cascading logic of addigning related records
   */
  getRecordFor(fieldApiName, record) {
    let lookupId = '';
    let relatedRecord = {};
    if (!fieldApiName) {
      return [lookupId, relatedRecord];
    }

    const relationshipName = fieldApiName.slice(0, -1).concat('r');
    if (record[fieldApiName]) {
      lookupId = record[fieldApiName];
      relatedRecord = record[relationshipName];
      return [lookupId, relatedRecord];
    }
    return undefined;
  }

  getObjectType(id) {
    let object = '';
    if (id.startsWith(this.objectInfo[ACCOUNT.objectApiName]?.keyPrefix)) {
      object = ACCOUNT.objectApiName;
    } else if (id.startsWith(this.objectInfo[USER.objectApiName]?.keyPrefix)) {
      object = USER.objectApiName;
    } else if (id.startsWith(this.objectInfo[CONTACT.objectApiName]?.keyPrefix)) {
      object = CONTACT.objectApiName;
    }
    return object;
  }

  async getDeletableAttendeeTypes(attendees) {
    if (!this.canDelete) {
      const attendeeRecordTypes = [];
      const eventFields = this.record?.fields;
      const status = eventFields?.Status_vod__c?.value;
      const countryCode = eventFields?.Country_vod__r?.value?.fields?.Alpha_2_Code_vod__c?.value;
      const eventConfigId = eventFields?.Event_Configuration_vod__c?.value;

      attendees.forEach(attendee => {
        const recordType = attendee[RECORD_TYPE.fieldApiName];
        if (!attendeeRecordTypes.includes(recordType)) {
          attendeeRecordTypes.push(recordType);
        }
      });
      this.canDelete = this.service.hasDeleteButton(this.eventId, EM_ATTENDEE.objectApiName, attendeeRecordTypes, status, countryCode, eventConfigId);
    }
    return this.canDelete;
  }

  async checkAttendeeRuleWarnings(attendeesToAdd) {
    let remainingAttendees = attendeesToAdd;
    let warnings;
    let modalLabel;
    try {
      [warnings, modalLabel] = await Promise.all([
        this.service.getAttendeeRuleWarnings(attendeesToAdd, this.eventId),
        this.getMessage({
          key: 'EM_RULE_POTENTIAL_ATTENDANCE_WARNING_TITLE',
          category: 'EVENT_MANAGEMENT',
          defaultMessage: 'The Following Attendee(s) have Potential Rule Violations',
        }),
      ]);
    } catch (e) {
      const errorMessage = await this.getMessage({
        key: 'ERROR_EVENT_BUSINESS_RULE_SYSTEM_DESCRIPTION',
        category: 'EVENT_MANAGEMENT',
        defaultMessage: 'The requested action cannot be completed. Please try again or contact your administrator.',
      });
      const abortSave = new Error(errorMessage);
      abortSave.name = 'AbortSaveError';
      throw abortSave;
    }
    if (warnings?.length > 0) {
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      const result = await EmBusRuleWarningsModal.open({
        warnings,
        type: BusRuleConstant.RULE_TYPE.PER_ATTENDEE,
        label: modalLabel,
        size: 'medium',
      });
      if (result?.recordsToRemove) {
        remainingAttendees = remainingAttendees.filter(attendee =>
          [ACCOUNT_LOOKUP, ENTITY_REFERENCE_ID, USER_LOOKUP, CONTACT_LOOKUP].every(
            ({ fieldApiName }) => !result.recordsToRemove.includes(attendee[fieldApiName])
          )
        );
      } else {
        const abortSave = new Error();
        abortSave.name = 'AbortSaveError';
        throw abortSave;
      }
    }
    return remainingAttendees;
  }

  async getAttendeesToRemove(selectedAttendees) {
    const selectedIdsSet = new Set(Object.keys(selectedAttendees));
    const [canDelete, notAllowedToDeleteMsg] = await Promise.all([
      this.getDeletableAttendeeTypes(this.initialAttendeesOnEvent),
      this.getMessage({ key: 'NOT_ALLOWED_TO_DELETE', category: 'Common', defaultMessage: 'You do not have permission to delete this record.' }),
    ]);
    const nonDeletableAttendees = [];
    const attendeesToRemove = [];
    this.initialAttendeesOnEvent.forEach(attendee => {
      const relatedRecordId = this.getRelatedRecordId(attendee);
      if (relatedRecordId && !selectedIdsSet.has(relatedRecordId)) {
        if (!canDelete[attendee[RECORD_TYPE.fieldApiName]]) {
          nonDeletableAttendees.push({
            id: attendee[ID.fieldApiName],
            messages: [notAllowedToDeleteMsg],
            name: attendee[ATTENDEE_NAME.fieldApiName],
          });
        } else {
          attendeesToRemove.push(attendee.Id);
        }
      }
    });
    return [attendeesToRemove, nonDeletableAttendees];
  }

  async save(selectedAttendees, recordType) {
    let attendeesToAdd = this.getAttendeesToAdd(selectedAttendees, recordType);
    if (attendeesToAdd.length > 0) {
      attendeesToAdd = await this.checkAttendeeRuleWarnings(attendeesToAdd);
    }

    const [attendeesToRemove, nonDeletableAttendees] = await this.getAttendeesToRemove(selectedAttendees);

    const promises = [];
    if (attendeesToAdd.length > 0) {
      promises.push(
        this.service.createAttendees(attendeesToAdd).then(response => {
          if (response?.failedInsertRecords?.length > 0) {
            response.failedInsertRecords.forEach(record => {
              record.name = selectedAttendees[record.id][NAME.fieldApiName];
            });
          }
          return response;
        })
      );
    }
    if (attendeesToRemove.length > 0) {
      promises.push(this.service.deleteAttendees(attendeesToRemove));
    }
    const results = await Promise.all(promises);

    let attendeeSaveResults = null;
    if (promises.length > 0 || nonDeletableAttendees.length > 0) {
      attendeeSaveResults = {
        icon: 'standard:person_account',
        objectLabel: this.objectInfo[EM_ATTENDEE.objectApiName].label,
        objectLabelPlural: this.objectInfo[EM_ATTENDEE.objectApiName].labelPlural,
      };
      results.forEach(result => {
        Object.assign(attendeeSaveResults, result);
      });
      if (!attendeeSaveResults.failedDeleteCount) {
        attendeeSaveResults.failedDeleteCount = 0;
      }
      attendeeSaveResults.failedDeleteCount += nonDeletableAttendees.length;
      if (!attendeeSaveResults.failedDeleteRecords) {
        attendeeSaveResults.failedDeleteRecords = [];
      }
      attendeeSaveResults.failedDeleteRecords = attendeeSaveResults.failedDeleteRecords.concat(nonDeletableAttendees);
    }
    return attendeeSaveResults;
  }

  getAttendeesToAdd(selectedAttendees, recordType) {
    const toAdd = [];
    const existingAttendeesSet = new Set();
    this.initialAttendeesOnEvent.forEach(attendee => {
      const relatedRecordId = this.getRelatedRecordId(attendee);
      if (relatedRecordId) {
        existingAttendeesSet.add(relatedRecordId);
      }
    });

    Object.entries(selectedAttendees).forEach(([id, record]) => {
      const alreadyAddedToEvent = existingAttendeesSet.has(id);
      if (!alreadyAddedToEvent) {
        const attendee = this.getAttendeeToAdd(recordType, id, record);
        toAdd.push(attendee);
      }
    });
    return toAdd;
  }

  getAttendeeToAdd(recordType, id, record) {
    const attendee = {
      Event_vod__c: this.eventId,
      RecordTypeId: recordType,
    };

    const object = this.getObjectType(id);
    let lookup = ACCOUNT_LOOKUP.fieldApiName;
    if (record.outside) {
      lookup = ENTITY_REFERENCE_ID.fieldApiName;
    } else if (object === ACCOUNT.objectApiName) {
      lookup = ACCOUNT_LOOKUP.fieldApiName;
    } else if (object === USER.objectApiName) {
      lookup = USER_LOOKUP.fieldApiName;
    } else if (object === CONTACT.objectApiName) {
      lookup = CONTACT_LOOKUP.fieldApiName;
    }
    attendee[lookup] = id;
    return attendee;
  }

  /**
   * @param {Object} attendee record, which is part of the selectedAttendees data
   * @returns related record id
   */
  getRelatedRecordId(attendee) {
    return attendee[ACCOUNT_LOOKUP.fieldApiName] || attendee[USER_LOOKUP.fieldApiName] || attendee[CONTACT_LOOKUP.fieldApiName];
  }
}