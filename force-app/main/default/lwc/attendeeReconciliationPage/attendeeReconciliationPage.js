import EM_EVENT from '@salesforce/schema/EM_Event_vod__c';
import ATTENDEE_RECONCILIATION_COMPLETE from '@salesforce/schema/EM_Event_vod__c.Attendee_Reconciliation_Complete_vod__c';
import EM_ATTENDEE from '@salesforce/schema/EM_Attendee_vod__c';
import ID from '@salesforce/schema/EM_Attendee_vod__c.Id';
import ATTENDEE_NAME from '@salesforce/schema/EM_Attendee_vod__c.Attendee_Name_vod__c';
import WALK_IN_STATUS from '@salesforce/schema/EM_Attendee_vod__c.Walk_In_Status_vod__c';
import ONLINE_REGISTRATION_STATUS from '@salesforce/schema/EM_Attendee_vod__c.Online_Registration_Status_vod__c';
import FIRST_NAME from '@salesforce/schema/EM_Attendee_vod__c.First_Name_vod__c';
import LAST_NAME from '@salesforce/schema/EM_Attendee_vod__c.Last_Name_vod__c';
import EMAIL from '@salesforce/schema/EM_Attendee_vod__c.Email_vod__c';
import PHONE from '@salesforce/schema/EM_Attendee_vod__c.Phone_vod__c';
import CITY from '@salesforce/schema/EM_Attendee_vod__c.City_vod__c';
import ZIP from '@salesforce/schema/EM_Attendee_vod__c.Zip_vod__c';
import WALK_IN_TYPE from '@salesforce/schema/EM_Attendee_vod__c.Walk_In_Type_vod__c';
import WALK_IN_FIELDS from '@salesforce/schema/EM_Event_vod__c.Walk_In_Fields_vod__c';
import PRESCRIBER_WALK_IN_FIELDS from '@salesforce/schema/EM_Event_vod__c.Prescriber_Walk_In_Fields_vod__c';
import NON_PRESCRIBER_WALK_IN_FIELDS from '@salesforce/schema/EM_Event_vod__c.Non_Prescriber_Walk_In_Fields_vod__c';
import OTHER_WALK_IN_FIELDS from '@salesforce/schema/EM_Event_vod__c.Other_Walk_In_Fields_vod__c';
import EVENT_ATTENDEE from '@salesforce/schema/Event_Attendee_vod__c';

import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import { MessageContext, subscribe, unsubscribe } from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningAlert from 'lightning/alert';
import LightningConfirm from 'lightning/confirm';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import { getService } from 'c/veevaServiceFactory';
import EmEventConstant from 'c/emEventConstant';
import { VeevaMessageRequest } from 'c/veevaMessageService';
import VeevaToastEvent from 'c/veevaToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
// eslint-disable-next-line camelcase
import toast_msg_styles from '@salesforce/resourceUrl/toast_msg_styles';
import AttendeeReconciliationService from './attendeeReconciliationService';


const META_MESSAGES = 'veevaMessages';
const META_WALK_IN_TYPE_ENABLED = 'walkInTypeEnabled';
const META_OBJECT_INFOS = 'objectInfos';
const META_FILTERS_MAP = 'filtersMap';
const META_ALL_WALK_INS = 'allWalkIns';
const META_QUERY_FIELDS = 'queryFields';
const META_ALL_WALK_IN_FIELDS = 'allWalkInFields';

const TOLABEL_PREFIX = 'toLabel_';
const REQUIRED_TOKEN = '<R>';
const REQUIRED_EVENT_FIELDS = [ ATTENDEE_RECONCILIATION_COMPLETE, WALK_IN_FIELDS ];
const OPTIONAL_EVENT_FIELDS = [ PRESCRIBER_WALK_IN_FIELDS, NON_PRESCRIBER_WALK_IN_FIELDS, OTHER_WALK_IN_FIELDS ];
const DISMISSED_VOD = 'Dismissed_vod';
const NEEDS_RECONCILIATION_VOD = 'Needs_Reconciliation_vod';
const PENDING_VERIFICATION_VOD = 'Pending_Verification_vod';
const RECONCILIATION_REJECTED_VOD = 'Reconciliation_Rejected_vod';
const WALK_IN_NEEDS_RECONCILIATION_STATUSES = [ NEEDS_RECONCILIATION_VOD, RECONCILIATION_REJECTED_VOD ];
const PRESCRIBER_VOD = 'Prescriber_vod';
const NON_PRESCRIBER_VOD = 'Non_Prescriber_vod';
const OTHER_VOD = 'Other_vod';

const MAX_RESULTS = 2000;
const COLUMN_INITIAL_WIDTH = 175;

const MESSAGES = [
  { key: 'ATTENDEE_RECONCILIATION', category: 'EVENT_MANAGEMENT', defaultMessage: 'Attendee Reconciliation' },
  { key: 'WALK_IN_TOTAL_COUNT', category: 'EVENT_MANAGEMENT', defaultMessage: 'Walk In Total: {0}' },
  { key: 'WALK_IN_RECONCILED_COUNT', category: 'EVENT_MANAGEMENT', defaultMessage: 'Reconciled: {0}' },
  { key: 'COMPLETE_RECONCILIATION', category: 'EVENT_MANAGEMENT', defaultMessage: 'Complete Reconciliation' },
  { key: 'RECONCILIATION_COMPLETE', category: 'EVENT_MANAGEMENT', defaultMessage: 'Reconciliation Complete'}, 
  { key: 'COMPLETE_RECONCILIATION_CONFIRM', category: 'EVENT_MANAGEMENT', defaultMessage: 'All unmatched attendees will be dismissed. Would you like to continue?' },
  { key: 'RECONCILIATION_COMPLETE_HEADER', category: 'EVENT_MANAGEMENT', defaultMessage: 'Reconciliation is complete. Click the Reopen button to add or modify attendee information'}, 
  { key: 'REOPEN', category: 'EVENT_MANAGEMENT', defaultMessage: 'Reopen' },
  { key: 'SEARCH_FOR_MATCHES', category: 'EVENT_MANAGEMENT', defaultMessage: 'Search for Matches' },
  { key: 'DISMISS', category: 'EVENT_MANAGEMENT', defaultMessage: 'Dismiss' },
  { key: 'DISMISS_HELP', category: 'EVENT_MANAGEMENT', defaultMessage: 'Dismissed attendees do not have a matched account, but will remain in the system for expense purposes.' },
  { key: 'NO_RECORDS', category: 'Common', defaultMessage: 'No records to display'}, 
  { key: 'ATTENDEE_RECONCILIATION_FAIL', category: 'EVENT_MANAGEMENT', defaultMessage: 'Attendee Reconciliation cannot be completed.' },
  { key: 'ATTENDEE_RECONCILIATION_SUCCESS', category: 'EVENT_MANAGEMENT', defaultMessage: 'Attendee Reconciliation was completed successfully.' },
  { key: 'CONFIRM_DISMISS', category: 'EVENT_MANAGEMENT', defaultMessage: 'All selected attendees will be dismissed. Would you like to continue?' },
  { key: 'DISMISS_DETAILS_BULK_FAIL', category: 'EVENT_MANAGEMENT', defaultMessage: 'You are not able to dismiss the following attendees from the event:' },
  { key: 'DISMISS_DETAILS_BULK_SUCCESS', category: 'EVENT_MANAGEMENT', defaultMessage: 'All selected attendees have been successfully dismissed.' },
  { key: 'NEEDS_RECONCILIATION_ONLY', category: 'EVENT_MANAGEMENT', defaultMessage: 'Only attendees with a status of Needs Reconciliation can be selected. All other attendees will be deselected.' },
  { key: 'ATTENDEE_RECONCILIATION_TRUNCATED_RESULTS', category: 'EVENT_MANAGEMENT', defaultMessage: 'Results are truncated at 2000 records. Please use filter options to refine your results.' },
  { key: 'Error', category: 'Common', defaultMessage: 'Error' },
  { key: 'NEW_WALK_IN', category: 'EVENT_MANAGEMENT', defaultMessage: 'New Walk-In' },
  { key: 'FILTER', category: 'Common', defaultMessage: 'Filter' },
  { key: 'ALERT_INSUFFICIENT_PRIVILEGES', category: 'Common', defaultMessage: 'Insufficient Access' },
];

const BASE_VIEW_STATE = {
  displayPage: false,
  displayFilters: false,
  displaySearchForMatches: false,
  displayNewWalkIn: false,
  errors: {},
  loading: false,
  walkIns: [],
  selectedRows: [],
  selectedIndex: 0,
  selectedWalkInFields: [],
  selectedWalkIns: [],
  selectedFilters: {},
  selectedFiltersPills: [],
  pageTitle: '',
  reconciliationCompleteLabel: '',
  filters: [],
  completed: false,
  columns: [],
  noResults: false,
  noResultsLabel: '',
  resultsTruncatedLabel: '',
  selectedWalkInsCount: 0,
  walkInTotalCount: '',
  reconciledCount: '',
  dismissedCount: '',
  pendingVerificationCount: '',
  needsReconcilitionCount: '',
  dismissLabel: '',
  dismissHelpText: '',
  reopenHelpText: '',
  searchForMatchesLabel: '',
  completeReopenLabel: '',
  sortedBy: ATTENDEE_NAME.fieldApiName,
  sortDirection: 'asc',
  isTruncated: false,
};
const FILTER_PILLS_ORDER = ['Needs_Reconciliation_vod','Reconciled_To_Existing_Account_vod','Reconciled_To_Existing_User_vod','Reconciled_To_Customer_Master_vod','Reconciled_To_New_Account_vod','Dismissed_vod','Prescriber_vod', 'Non_Prescriber_vod','Other_vod'];
const FIXED_COLUMNS = [ ATTENDEE_NAME.fieldApiName, WALK_IN_STATUS.fieldApiName, WALK_IN_TYPE.fieldApiName ];
const DEFAULT_QUERY_FIELDS = [ FIRST_NAME.fieldApiName, LAST_NAME.fieldApiName, EMAIL.fieldApiName, PHONE.fieldApiName, CITY.fieldApiName, ZIP.fieldApiName ];

// Template for custom name column, label value needs to be updated according to user language
const NAME_COLUMN = { label: 'Attendee Name', fieldName: ATTENDEE_NAME.fieldApiName, type: 'nameDetails', hideDefaultActions: true, sortable: true, typeAttributes: { id: {fieldName: ID.fieldApiName}}};
const TOLABEL_PICKLIST_COLUMNS = [WALK_IN_STATUS.fieldApiName, ONLINE_REGISTRATION_STATUS.fieldApiName, WALK_IN_TYPE.fieldApiName];
export default class AttendeeReconciliationPage extends LightningElement {
  
  @api recordId;
  meta = {};
  service;

  // View Properties
  displayPage = false;
  displayFilters = false;
  displaySearchForMatches = false;
  displayNewWalkIn = false;
  errors = {};
  loading = false;
  pageTitle;
  reconciliationCompleteLabel;
  filters;
  selectedFilters = {};
  selectedFiltersPills = [];
  completed;
  walkIns = [];
  columns;
  selectedRows = [];
  selectedIndex;
  selectedWalkInFields;
  _selectedWalkIns = [];
  noResults;
  noResultsLabel;
  resultsTruncatedLabel;
  selectedWalkInsCount;
  walkInTotalCount;
  reconciledCount;
  dismissedCount;
  pendingVerificationCount;
  needsReconcilitionCount;
  dismissLabel;
  dismissHelpText;
  reopenHelpText;
  searchForMatchesLabel;
  completeReopenLabel;
  sortedBy;
  sortDirection;
  isTruncated;

  stylesLoaded; // do not include in base view state

  @wire(MessageContext)
  messageContext;

  @wire(getRecord, { recordId: '$recordId', fields: REQUIRED_EVENT_FIELDS, optionalFields: OPTIONAL_EVENT_FIELDS})
  wireGetRecord({data}) {
    if (data) {
      this.eventRecord = data;
    }
    if (this.displayPage) { // Page is already open
      this.loading = true;
      this.initView().finally(() => {
        this.loading = false;
      });
    }
  }

  @wire(getObjectInfos, { objectApiNames: [ EM_ATTENDEE, EVENT_ATTENDEE, EM_EVENT ] })
  wireObjectInfo({data}) {
      if (data?.results) {
        const objInfo = {};
        data.results.forEach(response => {
        if (response?.statusCode === 200) {
          const objectInfo = response.result;
          if (objectInfo.apiName === EM_ATTENDEE.objectApiName) {
            objInfo[EM_ATTENDEE.objectApiName] = objectInfo;
          } else if (objectInfo.apiName === EVENT_ATTENDEE.objectApiName) {
            objInfo[EVENT_ATTENDEE.objectApiName] = objectInfo;
          } else if (objectInfo.apiName === EM_EVENT.objectApiName) {
            objInfo[EM_EVENT.objectApiName] = objectInfo;
          }
        }
        this.meta[META_OBJECT_INFOS] = objInfo;
      });
    }
  }

  constructor() {
    super();
    this.service = new AttendeeReconciliationService();
    this.messageService = getService('messageSvc');
  }

  get noneSelectedOrLoading() {
    return this.selectedRows.length === 0 || this.loading;
  }

  get sortedByLabel() {
    let label = '';
    if (this.sortedBy && this.columns?.length > 0) {
      label = this.columns.find(col => col.fieldName === this.sortedBy)?.label;
    }
    return label;
  }

  get canCreateWalkIn() {
    const createable = this.meta[META_OBJECT_INFOS][EM_ATTENDEE.objectApiName]?.createable ?? false;
    const walkInTypeFieldsPopulated = this.isWalkInTypeEnabled() && (this.getWalkInFields(PRESCRIBER_WALK_IN_FIELDS.fieldApiName)?.length > 0 || this.getWalkInFields(NON_PRESCRIBER_WALK_IN_FIELDS.fieldApiName)?.length > 0 || this.getWalkInFields(OTHER_WALK_IN_FIELDS.fieldApiName)?.length > 0);
    return createable && (this.getWalkInFields(WALK_IN_FIELDS.fieldApiName).length > 0 || walkInTypeFieldsPopulated);
  }

  get allWalkInFields() {
    return this.meta[META_ALL_WALK_IN_FIELDS];
  }

  renderedCallback() {
    if (!this.stylesLoaded) {
        loadStyle(this, toast_msg_styles);
        this.stylesLoaded = true;
    }
  }

  set selectedWalkIns(value) {
    this._selectedWalkIns = value;
    this.selectedRows = value.map(walkIn => walkIn.Id);
    this.selectedWalkInsCount = value.length;
  }
  get selectedWalkIns() {
    return this._selectedWalkIns;
  }

  get disableNewWalkInButton() {
    return this.completed || this.loading;
  }

  connectedCallback() {
    if (!this.subscription) {
      this.subscription = subscribe(this.messageContext, eventsManagementChannel, message => this.handleMessage(message));
    }
  }

  disconnectedCallback() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  handleMessage({ key, eventId }) {
    if (key === EmEventConstant.ATTENDEE_RECONCILIATION && this.recordId === eventId) {
      this.loading = true;
      this.resetView();
      this.init().finally(() => {
        this.loading = false;
      });
    }
  }

  resetView() {
    Object.entries(BASE_VIEW_STATE).forEach(([prop, value]) => {
      this[prop] = value;
    });
  }

  closePage() {
    this.displayPage = false;
  }

  async init() {
    await this.initMeta();
    await this.initView();
  }

  async initMeta() {
    this.meta[META_WALK_IN_TYPE_ENABLED] = this.isWalkInTypeEnabled();
    this.meta[META_FILTERS_MAP] = await this.service.getFilters();
    this.meta[META_MESSAGES] = await this.getMessages(); // Need filters before messages for some picklist labels
    this.parseWalkInFields();
  }

  async initView() {
    this.completed = getFieldValue(this.eventRecord, ATTENDEE_RECONCILIATION_COMPLETE);

    // Labels
    this.pageTitle = this.meta[META_MESSAGES]['ATTENDEE_RECONCILIATION;;EVENT_MANAGEMENT'];
    this.dismissLabel = this.meta[META_MESSAGES]['DISMISS;;EVENT_MANAGEMENT'] ;
    this.searchForMatchesLabel = this.meta[META_MESSAGES]['SEARCH_FOR_MATCHES;;EVENT_MANAGEMENT'];
    this.completeReopenLabel = this.completed ? this.meta[META_MESSAGES]['REOPEN;;EVENT_MANAGEMENT'] : this.meta[META_MESSAGES]['COMPLETE_RECONCILIATION;;EVENT_MANAGEMENT'];
    this.noResultsLabel = this.meta[META_MESSAGES]['NO_RECORDS;;Common'];
    this.dismissHelpText = this.meta[META_MESSAGES]['DISMISS_HELP;;EVENT_MANAGEMENT'];
    this.reopenHelpText = this.meta[META_MESSAGES]['RECONCILIATION_COMPLETE_HEADER;;EVENT_MANAGEMENT'];
    this.reconciliationCompleteLabel = this.meta[META_MESSAGES]['RECONCILIATION_COMPLETE;;EVENT_MANAGEMENT'];
    this.resultsTruncatedLabel = this.meta[META_MESSAGES]['ATTENDEE_RECONCILIATION_TRUNCATED_RESULTS;;EVENT_MANAGEMENT'];
    this.newWalkInLabel = this.meta[META_MESSAGES]['NEW_WALK_IN;;EVENT_MANAGEMENT'];
    this.filterLabel = this.meta[META_MESSAGES]['FILTER;;Common'];

    this.displayPage = true;

    // Fiilters
    this.filters = [this.meta[META_FILTERS_MAP][WALK_IN_STATUS.fieldApiName], this.meta[META_FILTERS_MAP][WALK_IN_TYPE.fieldApiName]];
    
    // Table
    this.columns = this.getColumns();
    await Promise.all([this.updateTable(), this.updateCounts()]);
  }

  isWalkInTypeEnabled() {
    const walkInTypeFLS = this.meta[META_OBJECT_INFOS][EM_ATTENDEE.objectApiName].fields[WALK_IN_TYPE.fieldApiName];
    const emEventDescribeFields = this.meta[META_OBJECT_INFOS][EM_EVENT.objectApiName].fields;
    const prescriberWalkInFieldsFLS = emEventDescribeFields[PRESCRIBER_WALK_IN_FIELDS.fieldApiName];
    const nonPrescriberWalkInFieldsFLS = emEventDescribeFields[NON_PRESCRIBER_WALK_IN_FIELDS.fieldApiName];
    const otherWalkInFieldsFLS = emEventDescribeFields[OTHER_WALK_IN_FIELDS.fieldApiName];
    return Boolean(walkInTypeFLS) && (Boolean(prescriberWalkInFieldsFLS) || Boolean(nonPrescriberWalkInFieldsFLS) || Boolean(otherWalkInFieldsFLS));
  }

  async getMessages() {
    const vmr = new VeevaMessageRequest();
    MESSAGES.forEach(({key, category, defaultMessage}) => vmr.addRequest(key, category, defaultMessage, `${key};;${category}`));
    let msgMap = {};
    try {
      msgMap = await this.messageService.getMessageMap(vmr);
    } catch (e) {
      // fallback to default english message if error
      MESSAGES.forEach(({key, category, defaultMessage}) => {
        msgMap[`${key};;${category}`] = defaultMessage;
      });
    }

    const walkInStatusOptions = this.meta[META_FILTERS_MAP][WALK_IN_STATUS.fieldApiName];
    walkInStatusOptions.options.forEach(({value, label}) => {
      if (value === NEEDS_RECONCILIATION_VOD) {
        msgMap[NEEDS_RECONCILIATION_VOD] = label;
      } else if (value === DISMISSED_VOD) {
        msgMap[DISMISSED_VOD] = label;
      } else if (value === PENDING_VERIFICATION_VOD) {
        msgMap[PENDING_VERIFICATION_VOD] = label;
      }
    });
    return msgMap;
  }

  getWalkInFields(field) {
    return this.meta[META_ALL_WALK_IN_FIELDS][field];
  }

  parseWalkInFields() {
    this.meta[META_ALL_WALK_IN_FIELDS] = {};
    if (this.meta[META_WALK_IN_TYPE_ENABLED]) {
      const prescriberWalkInFieldsString = getFieldValue(this.eventRecord, PRESCRIBER_WALK_IN_FIELDS);
      const nonPrescriberWalkInFieldsString = getFieldValue(this.eventRecord, NON_PRESCRIBER_WALK_IN_FIELDS);
      const otherWalkInFieldsString = getFieldValue(this.eventRecord, OTHER_WALK_IN_FIELDS);
      
      this.meta[META_ALL_WALK_IN_FIELDS][PRESCRIBER_WALK_IN_FIELDS.fieldApiName] = this.parseWalkInField(prescriberWalkInFieldsString);
      this.meta[META_ALL_WALK_IN_FIELDS][NON_PRESCRIBER_WALK_IN_FIELDS.fieldApiName] = this.parseWalkInField(nonPrescriberWalkInFieldsString);
      this.meta[META_ALL_WALK_IN_FIELDS][OTHER_WALK_IN_FIELDS.fieldApiName] = this.parseWalkInField(otherWalkInFieldsString);
    }
    const walkInFieldsString = getFieldValue(this.eventRecord, WALK_IN_FIELDS);
    this.meta[META_ALL_WALK_IN_FIELDS][WALK_IN_FIELDS.fieldApiName] = this.parseWalkInField(walkInFieldsString);
  }

  parseWalkInField(fieldValue) {
    const walkInFields = [];
    fieldValue?.split(';').filter(field => field).forEach(field => {
      const required = field.endsWith(REQUIRED_TOKEN);
      let apiName = field;
      if (required) {
        apiName = apiName.slice(0, field.length - REQUIRED_TOKEN.length);
      }
      let fieldDescribe = this.meta[META_OBJECT_INFOS][EM_ATTENDEE.objectApiName].fields[apiName];
      if (!fieldDescribe && !apiName.endsWith('__c')) {
        apiName = apiName.concat('__c');
      }
      fieldDescribe = this.meta[META_OBJECT_INFOS][EM_ATTENDEE.objectApiName].fields[apiName];
      if (fieldDescribe) {
        const { label } = fieldDescribe;
        walkInFields.push({ label, apiName, required });
      }
    });
    return walkInFields;
  }

  getInitialWidth(numColumns) {
    let initialWidth = COLUMN_INITIAL_WIDTH;
    // modals take up 90% of viewport, subtract 2rem of padding
    const tableWidth = (document.documentElement.clientWidth*0.9) - 2*(parseInt(getComputedStyle(document.documentElement).fontSize, 10));
    // 52px row number column, 32px checkbox column width
    const minColumnsWidth = (numColumns * COLUMN_INITIAL_WIDTH) + 52 + 32;
    if (tableWidth > minColumnsWidth) {
      initialWidth = 0;
    }
    return initialWidth;
  }

  getColumns() {
    const attendeeDescribe = this.meta[META_OBJECT_INFOS][EM_ATTENDEE.objectApiName];
    const walkInTypeEnabled = this.meta[META_WALK_IN_TYPE_ENABLED];
    const fields = FIXED_COLUMNS.filter(field => field !== WALK_IN_TYPE.fieldApiName || walkInTypeEnabled).map(field => ({
      apiName: field,
      label: attendeeDescribe.fields[field].label
    }));
    if (walkInTypeEnabled) {
      fields.push(this.getWalkInFields(PRESCRIBER_WALK_IN_FIELDS.fieldApiName));
      fields.push(this.getWalkInFields(NON_PRESCRIBER_WALK_IN_FIELDS.fieldApiName));
      fields.push(this.getWalkInFields(OTHER_WALK_IN_FIELDS.fieldApiName));
    }
    fields.push(this.getWalkInFields(WALK_IN_FIELDS.fieldApiName));

    const initialWidth = this.getInitialWidth(fields.flat().length);
    const seen = new Set();
    const cols = fields.flat().reduce((columns, field) => {
      const fieldName = field.apiName;
      if (!seen.has(fieldName)) {
        const fieldDescribe = attendeeDescribe.fields[fieldName];
        let columnField = fieldName;
        if (TOLABEL_PICKLIST_COLUMNS.includes(fieldName)) {
          columnField = `${TOLABEL_PREFIX}${fieldName}`;
        }
        let col = {
          label: field.label,
          fieldName: columnField,
          type: 'text',
          hideDefaultActions: true,
          sortable: fieldDescribe.sortable,
          initialWidth,
        };
        if (fieldName === NAME_COLUMN.fieldName) {
          col = { 
            ...col, 
            ...NAME_COLUMN
          };
          col.label = field.label;
        } else if (fieldDescribe?.dataType === 'Reference') {
          col.type = 'lookup';
          col.typeAttributes = {
            lookupRecord: { fieldName: fieldDescribe.relationshipName }
          };
        } else if (fieldDescribe?.dataType === 'Boolean') {
          col.type = 'boolean';
        }
        seen.add(fieldName);
        columns.push(col);
      }
      return columns;
    }, []);
    DEFAULT_QUERY_FIELDS.forEach(field => seen.add(field)); // Add required query fields after column model is built
    this.meta[META_QUERY_FIELDS] = Array.from(seen);
    return cols;
  }

  async handleSelection(event) {
    const { selectedRows } = event.detail;
    this.selectedWalkIns = selectedRows;
  }

  resetSelection() {
    this.handleSelection({detail: { selectedRows: [] }});
  }

  async handleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    this.sortedBy = sortedBy;
    this.sortDirection = sortDirection;
    await this.updateTable();
  }

  async updateTable() {
    const alreadyLoading = this.loading;
    this.loading = alreadyLoading || true;
    const queryFields = this.meta[META_QUERY_FIELDS];
    let sortBy = this.sortedBy;
    if (sortBy?.startsWith(TOLABEL_PREFIX)) {
      sortBy = sortBy.slice(TOLABEL_PREFIX.length);
    }
    const walkIns = await this.service.getWalkIns(this.recordId, queryFields, this.selectedFilters[WALK_IN_STATUS.fieldApiName], this.selectedFilters[WALK_IN_TYPE.fieldApiName], sortBy, this.sortDirection);
    this.noResults = walkIns.length === 0;
    this.isTruncated = walkIns.length > MAX_RESULTS;
    this.walkIns = walkIns.slice(0, MAX_RESULTS);
    this.updateAllWalkInRecords(walkIns);
    this.loading = alreadyLoading || false;
  }

  updateAllWalkInRecords(newRecords) {
    if (!this.meta[META_ALL_WALK_INS]) {
      this.meta[META_ALL_WALK_INS] = new Map();
    }
    newRecords.forEach(record => {
      this.meta[META_ALL_WALK_INS].set(record.Id, record);
    });
  }

  async updateCounts() {
    const { total, reconciled, dismissed, pendingVerification, needsReconciliation } = await this.service.getCounts(this.recordId);
    this.walkInTotalCount = this.meta[META_MESSAGES]['WALK_IN_TOTAL_COUNT;;EVENT_MANAGEMENT']?.replace('{0}', total) ?? '';
    this.reconciledCount = this.meta[META_MESSAGES]['WALK_IN_RECONCILED_COUNT;;EVENT_MANAGEMENT']?.replace('{0}', reconciled) ?? '';
    this.dismissedCount = `${this.meta[META_MESSAGES][DISMISSED_VOD]}: ${dismissed ?? 0}`;
    this.pendingVerificationCount = `${this.meta[META_MESSAGES][PENDING_VERIFICATION_VOD]}: ${pendingVerification ?? 0}`;
    this.needsReconcilitionCount = `${this.meta[META_MESSAGES][NEEDS_RECONCILIATION_VOD]}: ${needsReconciliation ?? 0}`;
  }

  toggleFilterPopover() {
    const displayFilter = this.displayFilters;
    this.displayFilters = !displayFilter;
  }
  
  async applyFilters(event) {
    const { value: toRemove, filters } = event.detail;
    let currentFilters = this.selectedFilters;
    if (toRemove) { // Remove filter via pill
      const filterGroup = event.target.getAttribute('data-filter-group');
      currentFilters[filterGroup] = currentFilters[filterGroup].filter(f => f !== toRemove); 
    } else if (filters) { // Apply filters
      currentFilters = filters;
    }
    this.selectedFilters = currentFilters;

    const allFiltersMap = this.meta[META_FILTERS_MAP];
    const pills = Object.entries(currentFilters).map(([filterGroup, options]) => {
      const filterGroupOptions = allFiltersMap[filterGroup].options;
      return options.map(value => ({ filterGroup, value, label: filterGroupOptions.find(option => option.value === value).label }));
    }).flat().sort((a, b) => {
      const indexA = FILTER_PILLS_ORDER.indexOf(a.value);
      const indexB = FILTER_PILLS_ORDER.indexOf(b.value);
      let order = 0
      if (indexA > indexB && indexB >= 0) {
        order = 1;
      } else if (indexA < indexB && indexA >= 0) {
        order = -1;
      }
      return order;
    });
    this.selectedFiltersPills = pills;
    this.closeFilters();
    await this.updateTable();
  }
  
  closeFilters() {
    this.displayFilters = false;
  }

  getNeedsReconciliationRows(walkIns) {
    return walkIns.filter(attendee => WALK_IN_NEEDS_RECONCILIATION_STATUSES.includes(attendee[WALK_IN_STATUS.fieldApiName]) || attendee[ONLINE_REGISTRATION_STATUS.fieldApiName] === NEEDS_RECONCILIATION_VOD);
  }

  async verifyNeedsReconciliationRows() {
    const needsReconciliationRows = this.getNeedsReconciliationRows(this.selectedWalkIns);
    if (this.selectedWalkIns.length > needsReconciliationRows.length) {
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      await LightningAlert.open({
        message: this.meta[META_MESSAGES]['NEEDS_RECONCILIATION_ONLY;;EVENT_MANAGEMENT'], 
        theme: 'warning', 
        variant: 'headerless'
      });
      this.selectedWalkIns = needsReconciliationRows;
    }
  }

  /* BUTTON LISTENERS */
  async dismiss() {
    await this.verifyNeedsReconciliationRows();
    // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
    const confirm = await LightningConfirm.open({
      message: this.meta[META_MESSAGES]['CONFIRM_DISMISS;;EVENT_MANAGEMENT'],
      variant: 'headerless',
    });
    if (confirm && this.selectedWalkIns.length > 0) {
      this.loading = true;
      const success = await this.dismissAttendees(this.selectedWalkIns);
      if (success) {
        this.dispatchEvent(VeevaToastEvent.successMessage(this.meta[META_MESSAGES]['DISMISS_DETAILS_BULK_SUCCESS;;EVENT_MANAGEMENT']));
      }
      this.updateCounts();
      this.resetSelection();
      await this.updateTable();
      this.loading = false;
    }
  }

  async dismissAttendees(attendees) {
    let success = true;
    if (attendees?.length > 0) {
      const attendeesToDismiss = attendees.map(attendee => {
        const toDismiss = {
          Id: attendee.Id
        };
        let statusField = '';
        if (attendee[WALK_IN_STATUS.fieldApiName]) {
          statusField = WALK_IN_STATUS.fieldApiName;
        } else if (attendee[ONLINE_REGISTRATION_STATUS.fieldApiName]) {
          statusField = ONLINE_REGISTRATION_STATUS.fieldApiName;
        }
        toDismiss[statusField] = DISMISSED_VOD;
        return toDismiss;
      });
      const response = await this.service.dismissAttendees(this.recordId, attendeesToDismiss);
      if (response.status === -1 && response.data) {
        this.populateErrors(response.data);
        this.dispatchEvent(VeevaToastEvent.error({ message: this.meta[META_MESSAGES]['DISMISS_DETAILS_BULK_FAIL;;EVENT_MANAGEMENT'] }));
        success = false;
      } else {
        this.updateCounts();
      }
    }
    return success;
  }

  handleNewWalkIn() {
    this.displayNewWalkIn = true;
  }

  async closeNewWalkIn(event) {
    event.stopPropagation();
    this.displayNewWalkIn = false;
    this.loading = true;
    this.sortedBy = BASE_VIEW_STATE.sortedBy;
    this.sortDirection = BASE_VIEW_STATE.sortDirection;
    this.updateCounts();
    this.resetSelection();
    await this.applyFilters({ detail: { filters: {} }});
    this.loading = false;
  }

  populateErrors(errorResponse) {
    const attendeeChildRelation = this.meta[META_OBJECT_INFOS][EM_EVENT.objectApiName]?.childRelationships?.find(r => r.childObjectApiName === EM_ATTENDEE.objectApiName)?.relationshipName ?? 'EM_Attendee_Event_vod__r';
    const rows = errorResponse?.[attendeeChildRelation].reduce((errors, error) => {
      const errorMessages = error.recordErrors;
      if (errorMessages?.length > 0) {
        errors[error.Id] = {
          title: this.meta[META_MESSAGES]['Error;;Common'],
          messages: errorMessages
        };
      }
      return errors;
    }, {});
    this.errors = { rows };
  }

  updateCurrentWalkIn(index) {
    let walkInFields = [];
    if (this.staticSelectedWalkIns?.length > 0 && index > -1) {
      const type = this.staticSelectedWalkIns[index][WALK_IN_TYPE.fieldApiName];
      if (type === PRESCRIBER_VOD) {
        walkInFields = this.getWalkInFields(PRESCRIBER_WALK_IN_FIELDS.fieldApiName);
      } else if (type === NON_PRESCRIBER_VOD) {
        walkInFields = this.getWalkInFields(NON_PRESCRIBER_WALK_IN_FIELDS.fieldApiName);
      } else if (type === OTHER_VOD) {
        walkInFields = this.getWalkInFields(OTHER_WALK_IN_FIELDS.fieldApiName);
      } else {
        walkInFields = this.getWalkInFields(WALK_IN_FIELDS.fieldApiName);
      }
    } 
    this.selectedWalkInFields = walkInFields; // set selectedWalkInFields before index, index invokes the init method on search window
    this.selectedIndex = index;
  }

  async searchForMatches(event) {
    const id = event?.detail?.record?.id;
    if (!id) {
      await this.verifyNeedsReconciliationRows();
    }
    if (this.selectedWalkIns.length > 0 || id) {
      let selected = [ ...this.selectedWalkIns ];
      if (id) {
        selected = [ this.walkIns.find(walkIn => walkIn.Id === id) ];
      }
      this.displaySearchForMatches = true;
      this.staticSelectedWalkIns = selected;
      this.updateCurrentWalkIn(0);
    }
  }

  closeSearch() {
    this.displaySearchForMatches = false;
    this.resetSelection();
    this.updateTable();
    this.updateCounts();
  }

  previousWalkIn() {
    this.updateCurrentWalkIn(this.selectedIndex-1);
  }

  nextWalkIn() {
    this.updateCurrentWalkIn(this.selectedIndex+1);
  }

  async completeReopen() {
    const complete = this.completed;
    if (complete) { // button click when event is already completed means we want to reopen for reconciliation
      this.reopenReconciliation();
    } else {
      this.completeReconciliation();
    }
  }

  async completeReconciliation() {
    const hasReconciliationCompleteFls = this.checkHasReconciliationCompleteFlsAndShowError();
    if (!hasReconciliationCompleteFls) {
      return;
    }
    const attendeesToDismiss = this.getNeedsReconciliationRows(Array.from(this.meta[META_ALL_WALK_INS].values()));
    let dismissSucceeded = true;
    if (attendeesToDismiss.length > 0) {
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      const confirmed = await LightningConfirm.open({
        message: this.meta[META_MESSAGES]['COMPLETE_RECONCILIATION_CONFIRM;;EVENT_MANAGEMENT'],
        variant: 'headerless',
      });
      if (confirmed) {
        this.loading = true;
        dismissSucceeded = await this.dismissAttendees(attendeesToDismiss);
      }
      if (!confirmed || !dismissSucceeded) {
        this.loading = false;
        return;
      }
    }
    
    this.loading = true;
    const completeResponse = await this.service.completeReopenReconciliation(this.recordId, true);
    let toast = VeevaToastEvent.successMessage(this.meta[META_MESSAGES]['ATTENDEE_RECONCILIATION_SUCCESS;;EVENT_MANAGEMENT']);
    if (completeResponse.status === -1) {
      toast = new ShowToastEvent({
        title: this.meta[META_MESSAGES]['ATTENDEE_RECONCILIATION_FAIL;;EVENT_MANAGEMENT'],
        message: completeResponse.data.recordErrors.join('\n'),
        variant: 'error'
      });
    } else {
      getRecordNotifyChange([{recordId: this.recordId}]);
      this.closePage();
    }
    this.dispatchEvent(toast);
    this.loading = false;
  }

  checkHasReconciliationCompleteFlsAndShowError() {
    if (!this.meta[META_OBJECT_INFOS][EM_EVENT.objectApiName].fields.Attendee_Reconciliation_Complete_vod__c?.updateable) {
      const toast = VeevaToastEvent.error({message: this.meta[META_MESSAGES]['ALERT_INSUFFICIENT_PRIVILEGES;;Common']});
      this.dispatchEvent(toast);
      return false;
    }
    return true;
  }

  async reopenReconciliation() {
    const hasReconciliationCompleteFls = this.checkHasReconciliationCompleteFlsAndShowError();
    if (!hasReconciliationCompleteFls) {
      return;
    }
    this.loading = true;
    const response = await this.service.completeReopenReconciliation(this.recordId, false);
    if (response.status === -1) {
      this.dispatchEvent(new ShowToastEvent({
        title: response.data.message,
        message: response.data.recordErrors.join('\n'),
        variant: 'error'
      }))
      this.loading = false;
    } else {
      getRecordNotifyChange([{recordId: this.recordId}]);
    }
  }

}