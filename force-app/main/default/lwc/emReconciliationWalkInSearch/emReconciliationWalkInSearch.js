import { LightningElement, api, track, wire } from 'lwc';
import ATTENDEE_RECONCILIATION_COMPLETE from '@salesforce/schema/EM_Attendee_vod__c.Event_vod__r.Attendee_Reconciliation_Complete_vod__c';
import EM_ATTENDEE_OBJ from '@salesforce/schema/EM_Attendee_vod__c';
import ADDRESS_OBJ from '@salesforce/schema/Address_vod__c';
import ACCOUNT_OBJ from '@salesforce/schema/Account';
import DATA_CHANGE_REQUEST_OBJECT from '@salesforce/schema/Data_Change_Request_vod__c';
import DATA_CHANGE_REQUEST_LINE_OBJECT from '@salesforce/schema/Data_Change_Request_Line_vod__c';
import DCR_FIELD_TYPE_OBJECT from '@salesforce/schema/DCR_Field_Type_vod__c';
import ATTENDEE_NAME from '@salesforce/schema/EM_Attendee_vod__c.Attendee_Name_vod__c';
import ACCOUNT from '@salesforce/schema/EM_Attendee_vod__c.Account_vod__c';
import USER from '@salesforce/schema/EM_Attendee_vod__c.User_vod__c';
import NETWORK_ID from '@salesforce/schema/EM_Attendee_vod__c.Network_ID_vod__c';
import WALK_IN_STATUS from '@salesforce/schema/EM_Attendee_vod__c.Walk_In_Status_vod__c';
import ONLINE_REGISTRATION_STATUS from '@salesforce/schema/EM_Attendee_vod__c.Online_Registration_Status_vod__c';
import WALK_IN_TYPE from '@salesforce/schema/EM_Attendee_vod__c.Walk_In_Type_vod__c';
import EVENT from '@salesforce/schema/EM_Attendee_vod__c.Event_vod__c';
import FIRST_NAME from '@salesforce/schema/EM_Attendee_vod__c.First_Name_vod__c';
import LAST_NAME from '@salesforce/schema/EM_Attendee_vod__c.Last_Name_vod__c';
import EMAIL from '@salesforce/schema/EM_Attendee_vod__c.Email_vod__c';
import PHONE from '@salesforce/schema/EM_Attendee_vod__c.Phone_vod__c';
import CITY from '@salesforce/schema/EM_Attendee_vod__c.City_vod__c';
import ZIP from '@salesforce/schema/EM_Attendee_vod__c.Zip_vod__c';
import STATE from '@salesforce/schema/EM_Attendee_vod__c.State_vod__c';
import EM_ATTENDEE from '@salesforce/schema/Data_Change_Request_vod__c.EM_Attendee_vod__c';
import REGISTRATION_TIMESTAMP from '@salesforce/schema/EM_Attendee_vod__c.Registration_Timestamp_vod__c';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue, getFieldDisplayValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { VeevaMessageRequest } from 'c/veevaMessageService';
import { getService } from 'c/veevaServiceFactory';
import LightningAlert from 'lightning/alert';
import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import EmEventConstant from 'c/emEventConstant';
import EmBusRuleViolationsModal from 'c/emBusRuleViolationsModal';
import { BusRuleConstant } from 'c/emBusRuleUtils';

const NAME_COL = 'name';
const ADDRESSES_COL = 'addresses';
const EMAILS_COL = 'emails';
const PHONE_NUMBERS_COL = 'phoneNumbers';
const DISMISSED_VOD = 'Dismissed_vod';
const NEEDS_RECONCILIATION_VOD = 'Needs_Reconciliation_vod';
const RECONCILED_TO_EXISTING_USER = 'Reconciled_To_Existing_User_vod';
const RECONCILED_TO_CUSTOMER_MASTER = 'Reconciled_To_Customer_Master_vod';
const RECONCILED_TO_EXISTING_ACCOUNT = 'Reconciled_To_Existing_Account_vod';
const RECONCILED_TO_NEW_ACCOUNT = 'Reconciled_To_New_Account_vod';
const PENDING_VERIFICATION_VOD = 'Pending_Verification_vod';
const RECONCILIATION_REJECTED_VOD = 'Reconciliation_Rejected_vod';
const MATCHED_STATUSES = [RECONCILED_TO_EXISTING_USER, RECONCILED_TO_CUSTOMER_MASTER, RECONCILED_TO_EXISTING_ACCOUNT, RECONCILED_TO_NEW_ACCOUNT];
const NAW_RECONCILIATION_CALLER_PARAM = 'emReconciliation';
const MESSAGES = [
  { key: 'SEARCH_FOR_MATCHES', category: 'EVENT_MANAGEMENT', defaultMessage: 'Search for Matches' },
  { key: 'NO_RECORDS', category: 'Common', defaultMessage: 'No records to display' },
  { key: 'CONFIRM_MATCH', category: 'EVENT_MANAGEMENT', defaultMessage: 'Confirm Match' },
  { key: 'CONFIRM_MATCH_ALERT', category: 'EVENT_MANAGEMENT', defaultMessage: 'Match attendee {0} to {1}?' },
  { key: 'RESET_MATCH', category: 'EVENT_MANAGEMENT', defaultMessage: 'Reset Match' },
  {
    key: 'RESET_MATCH_ALERT',
    category: 'EVENT_MANAGEMENT',
    defaultMessage: 'This action will clear your existing match. Are you sure you would like to continue?',
  },
  { key: 'DISMISS', category: 'EVENT_MANAGEMENT', defaultMessage: 'Dismiss' },
  {
    key: 'DISMISS_DETAILS',
    category: 'EVENT_MANAGEMENT',
    defaultMessage:
      'This attendee has been dismissed. The attendee record is maintained, but this attendee does not exist in the CRM database. You can still search for potential matches.',
  },
  {
    key: 'RECONCILIATION_COMPLETE_DIMISSED_ATTENDEE',
    category: 'EVENT_MANAGEMENT',
    defaultMessage: 'This attendee has been dismissed. The attendee record is maintained, but this attendee does not exist in the CRM database.',
  },
  { key: 'NAME', category: 'Common', defaultMessage: 'Name' },
  { key: 'CANCEL', category: 'Common', defaultMessage: 'Cancel' },
  { key: 'PREVIOUS', category: 'Common', defaultMessage: 'Previous' },
  { key: 'NEXT', category: 'Common', defaultMessage: 'Next' },
  { key: 'DONE', category: 'Common', defaultMessage: 'Done' },
  { key: 'SHOWING_X_OF_Y', category: 'Common', defaultMessage: 'Showing {0} of {1}' },
  { key: 'NEW_ACCOUNT', category: 'CallReport', defaultMessage: 'New Account'},
  { key: 'PENDING_VERIFICATION_DETAILS', category: 'EVENT_MANAGEMENT', defaultMessage: 'This attendee has a pending data change request. You can still search and reconcile against potential matches.'},
  { key: 'RECONCILIATION_REJECTED_DETAILS', category: 'EVENT_MANAGEMENT', defaultMessage: 'The data change request for this attendee has been rejected. You can still search for potential matches to reconcile this attendee.'},
  { key: 'ERROR_EVENT_BUSINESS_RULE_SYSTEM_DESCRIPTION', category: 'EVENT_MANAGEMENT', defaultMessage: 'The requested action cannot be completed. Please try again or contact your administrator.'},
];

const COLUMN_INITIAL_WIDTH = 175;
const INPUT_FIELDS_TO_NAME = {
  First_Name_vod__c: 'firstName',
  Last_Name_vod__c: 'lastName',
  Phone_vod__c: 'phone',
  Email_vod__c: 'email',
  City_vod__c: 'city',
  Zip_vod__c: 'zip',
};
// Input fields order is intentional
const INPUT_FIELDS = [FIRST_NAME.fieldApiName, EMAIL.fieldApiName, CITY.fieldApiName, LAST_NAME.fieldApiName, PHONE.fieldApiName, ZIP.fieldApiName];
const DEFAULT_FIELDS = [
  ATTENDEE_NAME.fieldApiName,
  WALK_IN_STATUS.fieldApiName,
  ONLINE_REGISTRATION_STATUS.fieldApiName,
  WALK_IN_TYPE.fieldApiName,
  ACCOUNT.fieldApiName,
  USER.fieldApiName,
  NETWORK_ID.fieldApiName,
  STATE.fieldApiName,
  REGISTRATION_TIMESTAMP.fieldApiName,
  ...INPUT_FIELDS,
];

// Matches GasCreateAccountAccess
const NETWORK_CUSTOMER_MASTER_MODE_DISABLED = '0';
const DCR_MODE_DISABLED = '0';
const DCR_MODE_ENABLED = '1';
const DCR_MODE_SHADOW_ACCTS = '2';
const NON_DISABLED_DCR_MODES = [DCR_MODE_ENABLED, DCR_MODE_SHADOW_ACCTS];

export default class EmReconciliationWalkInSearch extends NavigationMixin(LightningElement) {
  @wire(CurrentPageReference)
  pageRef;

  @api set walkInIndex(value) {
    this.index = value;
    if (this.selectedWalkIns?.[this.index]) {
      this.attendeeId = this.selectedWalkIns[this.index].Id;
    }
  }
  get walkInIndex() {
    return this.index;
  }
  @api set walkInFields(value) {
    this._walkInFields = value;
    if (this.objInfo) {
      this.calculateQueryFields();
    }
  }
  get walkInFields() {
    return this._walkInFields;
  }
  @api selectedWalkIns;
  @api service;
  @track inputFields = [];
  @track readOnlyFields = [];
  attendeeId;
  searchTerms = {};
  searchTermsInitialized = false;
  componentInitialized = true; // only used when on first load of a walk in attendee
  loadingResults = false;
  msgMap;
  objInfo;
  accountObjInfo;
  addressObjInfo;
  dcrObjInfo;
  dcrLineObjInfo;
  dcrFieldTypeObjInfo;
  queryFields;
  attendeeRecord;
  searchColumns;
  searchResults = [];
  addressLabel = 'Address';
  noResultsLabel;
  hasAccountCreationPermission = false;
  hasDcrMode = false;
  isNAWEnabled = false;

  @wire(getRecord, { recordId: '$attendeeId', fields: '$queryFields', optionalFields: [ATTENDEE_RECONCILIATION_COMPLETE] })
  wireGetRecord({ data }) {
    if (data && this.objInfo) {
      this.attendeeRecord = data;
      this.init().finally(() => {
        this.componentInitialized = false;
        this.loadingResults = false;
      });
    }
  }

  @wire(getObjectInfos, { objectApiNames: [EM_ATTENDEE_OBJ, ADDRESS_OBJ, ACCOUNT_OBJ, ADDRESS_OBJ, DATA_CHANGE_REQUEST_OBJECT, DATA_CHANGE_REQUEST_LINE_OBJECT, DCR_FIELD_TYPE_OBJECT] })
  wireObjectInfo({ data }) {
    if (data?.results) {
      data.results.forEach(response => {
        if (response?.statusCode === 200) {
          const objectInfo = response.result;
          if (objectInfo.apiName === EM_ATTENDEE_OBJ.objectApiName) {
            this.objInfo = objectInfo;
            this.calculateQueryFields();
          } else if (objectInfo.apiName === ADDRESS_OBJ.objectApiName) {
            this.addressLabel = objectInfo.label;
            this.addressObjInfo = objectInfo;
          } else if (objectInfo.apiName === ACCOUNT_OBJ.objectApiName) {
            this.accountObjInfo = objectInfo;
          } else if (objectInfo.apiName === DATA_CHANGE_REQUEST_OBJECT.objectApiName) {
            this.dcrObjInfo = objectInfo;
          } else if (objectInfo.apiName === DATA_CHANGE_REQUEST_LINE_OBJECT.objectApiName) {
            this.dcrLineObjInfo = objectInfo;
          } else if (objectInfo.apiName === DCR_FIELD_TYPE_OBJECT.objectApiName) {
            this.dcrFieldTypeObjInfo = objectInfo;
          }
        }
      });
      this.setNewAcctButtonVisibility(this.accountObjInfo?.createable, this.dcrObjInfo?.createable,
        this.dcrLineObjInfo?.createable, this.dcrFieldTypeObjInfo?.queryable);
    }
  }

  // matches globalAccountSearch except for FLS check on DCR.EM_Attendee_vod
  async setNewAcctButtonVisibility(canCreateAccount, canCreateDCR, canCreateDCRLine, canQueryDCRFieldType) {
    const customSettingValues = await this.service.getCustomSettingsForNewButtonConfig();
    this.hasDcrMode = NON_DISABLED_DCR_MODES.includes(customSettingValues.dcrMode);
    this.isNAWEnabled = customSettingValues.isNAWEnabled;
    this.hasAccountCreationPermission = !this.isAccountNotCreateable(canCreateAccount, canCreateDCR, 
      canCreateDCRLine, canQueryDCRFieldType, customSettingValues);
    if (this.hasDcrMode) {
      this.hasAccountCreationPermission = this.hasAccountCreationPermission && this.dcrObjInfo.fields[EM_ATTENDEE.fieldApiName] != null;
    }
  }

  connectedCallback() {
    this.messageService = getService('messageSvc');
    this.componentInitialized = true;
  }

  get containerClass() {
    let css = 'container';
    if (!this.componentInitialized) {
      css += ' container-loaded';
    }
    return css;
  }

  get eventId() {
    return getFieldValue(this.attendeeRecord, EVENT);
  }

  get walkInName() {
    return getFieldValue(this.attendeeRecord, ATTENDEE_NAME);
  }

  get walkInTypeLabel() {
    return getFieldDisplayValue(this.attendeeRecord, WALK_IN_TYPE) ?? '';
  }

  get walkInStatusLabel() {
    return getFieldDisplayValue(this.attendeeRecord, WALK_IN_STATUS);
  }

  get walkInStatus() {
    return getFieldValue(this.attendeeRecord, this.statusField);
  }

  get reconciliationComplete() {
    return getFieldValue(this.attendeeRecord, ATTENDEE_RECONCILIATION_COMPLETE);
  }

  get statusField() {
    let statusField = WALK_IN_STATUS;
    if (getFieldValue(this.attendeeRecord, ONLINE_REGISTRATION_STATUS)) {
      statusField = ONLINE_REGISTRATION_STATUS;
    }
    return statusField;
  }

  get walkInReferenceId() {
    return getFieldValue(this.attendeeRecord, ACCOUNT) || getFieldValue(this.attendeeRecord, USER) || getFieldValue(this.attendeeRecord, NETWORK_ID);
  }

  get eventName() {
    return this.attendeeRecord.fields?.Event_vod__r?.displayValue;
  }

  get needsReconciliation() {
    return this.walkInStatus === NEEDS_RECONCILIATION_VOD;
  }

  get dismissed() {
    return this.walkInStatus === DISMISSED_VOD;
  }

  get pendingVerification() {
    return this.walkInStatus === PENDING_VERIFICATION_VOD;
  }

  get reconciliationRejected() {
    return this.walkInStatus === RECONCILIATION_REJECTED_VOD;
  }

  get disableDismiss() {
    return this.dismissed || this.loading || this.pendingVerification;
  }

  get matched() {
    return MATCHED_STATUSES.includes(this.walkInStatus);
  }

  get loading() {
    return this.componentInitialized || this.loadingResults;
  }

  get disableAccountCreation() {
    return this.loading || this.pendingVerification || this.matched;
  }

  get isFirstSelection() {
    return this.index === 0 || this.loading;
  }

  get isLastSelection() {
    return this.index === this.selectedWalkIns.length - 1 || this.loading;
  }

  get statusBadgeStyle() {
    let style = 'slds-theme_success';
    if (this.needsReconciliation || this.reconciliationRejected) {
      style = 'slds-theme_error';
    } else if (this.dismissed || this.pendingVerification) {
      style = 'badge-dismissed';
    }
    return style;
  }

  get additionalWalkInFields() {
    return this.walkInFields
      .filter(({ apiName }) => !DEFAULT_FIELDS.includes(apiName) && (this.accountObjInfo.fields[apiName] || this.addressObjInfo.fields[apiName]))
      .map(({ apiName }) => apiName);
  }

  get nextDoneButtonLabel() {
    let label = this.msgMap['NEXT;;Common'];
    if (this.isLastSelection) {
      label = this.msgMap['DONE;;Common'];
    }
    return label;
  }

  get showNoResultsLabel() {
    return this.searchResults.length === 0 && !this.reconciliationComplete;
  }

  get dismissHelpText() {
    let text = this.msgMap['DISMISS_DETAILS;;EVENT_MANAGEMENT'];
    if (this.reconciliationComplete) {
      text = this.msgMap['RECONCILIATION_COMPLETE_DIMISSED_ATTENDEE;;EVENT_MANAGEMENT'];
    }
    return text;
  }

  get pendingHelpText() {
    return this.msgMap['PENDING_VERIFICATION_DETAILS;;EVENT_MANAGEMENT'];
  } 

  get rejectedHelpText() {
    return this.msgMap['RECONCILIATION_REJECTED_DETAILS;;EVENT_MANAGEMENT'];
  }

  get showTooltip() {
    return this.dismissed || this.pendingVerification || this.reconciliationRejected;
  }

  get tooltipHelpText() {
    let text = '';
    if (this.dismissed) {
      text = this.dismissHelpText;
    } else if (this.pendingVerification) {
      text = this.pendingHelpText;
    } else if (this.reconciliationRejected) {
      text = this.rejectedHelpText;
    }
    return text;
  }

  async init() {
    await this.getLabels();
    if (!this.searchTermsInitialized) {
      this.updateDetails();
      this.searchTermsInitialized = true;
    }
    this.updateColumns();
    if (this.walkInReferenceId) {
      await this.retrieveMatch();
    } else if (!this.reconciliationComplete) {
      await this.searchForMatches();
    }
  }

  calculateQueryFields() {
    const allFields = [EVENT.fieldApiName, DEFAULT_FIELDS, this.walkInFields.map(({ apiName }) => apiName)];
    const qFields = new Set();
    allFields.flat().forEach(field => {
      const fieldDescribe = this.objInfo.fields[field];
      if (fieldDescribe) {
        qFields.add(`${EM_ATTENDEE_OBJ.objectApiName}.${field}`);
        qFields.add(`${EM_ATTENDEE_OBJ.objectApiName}.${this.getFieldName(field)}`); // If its a lookup, include the relation
      }
    });
    this.queryFields = Array.from(qFields);
  }

  async getLabels() {
    if (!this.msgMap) {
      this.msgMap = {};
      const vmr = new VeevaMessageRequest();
      MESSAGES.forEach(({ key, category, defaultMessage }) => vmr.addRequest(key, category, defaultMessage, `${key};;${category}`));
      try {
        this.msgMap = await this.messageService.getMessageMap(vmr);
      } catch (e) {
        // fallback to default english message if error
        MESSAGES.forEach(({ key, category, defaultMessage }) => {
          this.msgMap[`${key};;${category}`] = defaultMessage;
        });
      }
    }
    this.dismissButtonLabel = this.msgMap['DISMISS;;EVENT_MANAGEMENT'];
    this.searchForMatchesButtonLabel = this.msgMap['SEARCH_FOR_MATCHES;;EVENT_MANAGEMENT'];
    this.createNewAccountButtonLabel = this.msgMap['NEW_ACCOUNT;;CallReport'];
    this.resetMatchButtonLabel = this.msgMap['RESET_MATCH;;EVENT_MANAGEMENT'];
    this.noResultsLabel = this.msgMap['NO_RECORDS;;Common'];
    this.cancelButtonLabel = this.msgMap['CANCEL;;Common'];
    this.previousButtonLabel = this.msgMap['PREVIOUS;;Common'];
    this.showing = this.msgMap['SHOWING_X_OF_Y;;Common'].replace('{0}', this.index + 1).replace('{1}', this.selectedWalkIns.length);
  }

  updateDetails() {
    this.inputFields = INPUT_FIELDS.map(apiName => {
      const objFieldName = `${EM_ATTENDEE_OBJ.objectApiName}.${apiName}`;
      this.searchTerms[INPUT_FIELDS_TO_NAME[apiName]] = getFieldValue(this.attendeeRecord, objFieldName);
      return {
        label: this.objInfo.fields[apiName].label,
        apiName,
        name: INPUT_FIELDS_TO_NAME[apiName],
        required: apiName === LAST_NAME.fieldApiName && !this.reconciliationComplete,
        disabled: this.dismissed,
        value: getFieldValue(this.attendeeRecord, objFieldName),
      };
    });
    if (this.walkInFields?.length > 0) {
      this.readOnlyFields = this.walkInFields
        .filter(field => !DEFAULT_FIELDS.includes(field.apiName))
        .map(({ apiName, label }) => ({
          label,
          apiName,
          name: apiName,
          isCheckbox: this.objInfo.fields[apiName].dataType === 'Boolean',
          value:
            getFieldDisplayValue(this.attendeeRecord, `${EM_ATTENDEE_OBJ.objectApiName}.${this.getFieldName(apiName)}`) ??
            getFieldValue(this.attendeeRecord, `${EM_ATTENDEE_OBJ.objectApiName}.${this.getFieldName(apiName)}`),
        }));
    }
  }

  getFieldName(apiName) {
    const describe = this.objInfo.fields[apiName];
    let fieldName = apiName;
    if (describe?.dataType === 'Reference') {
      fieldName = `${describe.relationshipName}.Name`;
    }
    return fieldName;
  }

  getInitialWidth(numColumns) {
    let initialWidth = COLUMN_INITIAL_WIDTH;
    // Reconciliation modal 90% of page, Search window is 95% of that
    const tableWidth = document.documentElement.clientWidth * 0.9 * 0.95;
    const minColumnsWidth = numColumns * COLUMN_INITIAL_WIDTH;
    if (tableWidth > minColumnsWidth) {
      initialWidth = 0;
    }
    return initialWidth;
  }

  updateColumns() {
    const defaultColumns = [
      {
        apiName: NAME_COL,
        label: this.msgMap['NAME;;Common'],
      },
      {
        apiName: ADDRESSES_COL,
        label: this.addressLabel,
      },
      {
        apiName: EMAILS_COL,
        label: this.objInfo.fields[EMAIL.fieldApiName].label,
      },
      {
        apiName: PHONE_NUMBERS_COL,
        label: this.objInfo.fields[PHONE.fieldApiName].label,
      },
    ];
    const additionalColumns = this.additionalWalkInFields.map(apiName => ({
      apiName,
      label: this.objInfo.fields[apiName].label,
    }));

    const terms = { ...this.searchTerms };
    this.additionalWalkInFields.forEach(apiName => {
      terms[apiName] = this.readOnlyFields?.find(field => field.apiName === apiName)?.value;
    });

    const columns = [...defaultColumns, ...additionalColumns].map(field => ({
      label: field.label,
      fieldName: field.apiName,
      type: this.objInfo.fields[field.apiName]?.dataType === 'Boolean' ? 'boolean' : 'reconciliation',
      hideDefaultActions: true,
      typeAttributes: {
        type: field.apiName,
        terms,
      },
      sortable: false,
    }));
    if (!this.matched) {
      columns.unshift({
        fieldName: 'confirmMatch',
        type: 'button',
        cellAttributes: {
          alignment: 'center',
        },
        typeAttributes: {
          variant: 'base',
          label: this.msgMap['CONFIRM_MATCH;;EVENT_MANAGEMENT'],
        },
        hideLabel: true,
        hideDefaultActions: true,
        sortable: false,
      });
    }
    const initialWidth = this.getInitialWidth(columns.length);
    if (initialWidth > 0) {
      columns.forEach(col => {
        col.initialWidth = initialWidth;
      });
    }
    this.searchColumns = columns;
  }

  handleChange(event) {
    this.searchTerms[event.target.name] = event.detail.value;
  }

  handlePrevious() {
    this.componentInitialized = true;
    this.searchTermsInitialized = false;
    this.dispatchEvent(new CustomEvent('previous'));
  }

  handleNext() {
    if (this.isLastSelection) {
      this.exit();
    } else {
      this.componentInitialized = true;
      this.searchTermsInitialized = false;
      this.dispatchEvent(new CustomEvent('next'));
    }
  }

  exit() {
    this.dispatchEvent(new CustomEvent('close'));
  }

  async searchForMatches() {
    const allValid = [...this.template.querySelectorAll('lightning-input')].reduce(
      (validSoFar, inputCmp) => validSoFar && inputCmp.checkValidity(),
      true
    );
    if (!allValid) {
      return;
    }
    this.loadingResults = !this.componentInitialized;
    this.searchColumns = [];
    this.searchResults = [];

    const { firstName, lastName, email, phone, city, zip } = this.searchTerms;
    this.updateColumns();
    const { data, message } = await this.service.searchForMatches(
      this.eventId,
      this.attendeeId,
      firstName,
      lastName,
      email,
      phone,
      city,
      zip,
      this.additionalWalkInFields
    );
    this.searchResults = data;
    if (message) {
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      await LightningAlert.open({
        message,
        variant: 'headerless',
      });
    }
    this.loadingResults = false;
  }

  async retrieveMatch() {
    const { data } = await this.service.retrieveMatch(this.walkInReferenceId, this.attendeeId, this.additionalWalkInFields);
    this.searchResults = data;
  }

  // eslint-disable-next-line class-methods-use-this
  buildName(match) {
    return `${match.lastName}, ${match.firstName}`;
  }

  attendeeForUpdate(match, status, registrationStatus) {
    const data = {
      Id: this.attendeeId,
      Network_ID_vod__c: '',
      Walk_In_Reference_ID_vod__c: '',
    };
    let walkInStatus = NEEDS_RECONCILIATION_VOD;
    let name = `${getFieldValue(this.attendeeRecord, LAST_NAME)}, ${getFieldValue(this.attendeeRecord, FIRST_NAME)}`;
    if (match?.Id) {
      if (match.isUser) {
        walkInStatus = RECONCILED_TO_EXISTING_USER;
      } else if (match.fromNetwork) {
        walkInStatus = RECONCILED_TO_CUSTOMER_MASTER;
      } else {
        walkInStatus = RECONCILED_TO_EXISTING_ACCOUNT;
      }
      data.Walk_In_Reference_ID_vod__c = match.Id;
      data.Network_ID_vod__c = match.networkVid;
      name = this.buildName(match);
    }
    data[this.statusField.fieldApiName] = walkInStatus;
    data.Attendee_Name_vod__c = name.replace(/<(?:.|\n)*?>/gm, '');
    if (status) {
      data.Status_vod__c = status;
    }
    if (registrationStatus) {
      data.Registration_Status_vod__c = registrationStatus;
    }
    return data;
  }

  async confirmResetMatch(event) {
    let message = '';
    let row = {};
    if (event?.target?.dataset?.id === 'reset-match-button') {
      message = this.msgMap['RESET_MATCH_ALERT;;EVENT_MANAGEMENT'];
    } else {
      row = event.detail.row;
      message = this.msgMap['CONFIRM_MATCH_ALERT;;EVENT_MANAGEMENT'].replace('{0}', this.buildName(row)).replace('{1}', this.walkInName);
    }
    // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
    const confirm = await LightningConfirm.open({
      message,
      variant: 'headerless',
    });
    if (confirm) {
      let status;
      let registrationStatus;

      if (this.shouldRunBusinessRules(row)) {
        this.loadingResults = true;
        const busRuleResponse = await this.service.getAttendeeRuleWarnings([{ Account_vod__c: row.Id }], this.eventId);
        if (busRuleResponse.status === -1) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: this.msgMap['ERROR_EVENT_BUSINESS_RULE_SYSTEM_DESCRIPTION;;EVENT_MANAGEMENT'],
              variant: 'error',
            })
          );
          this.loadingResults = false;
          return;
        }

        if (busRuleResponse?.data?.length) {
          const [result, hasHardWarning] = await this.constructWarningsAndLaunchModal(busRuleResponse.data);
          if (!result || result === 'exitEarly') {
            this.loadingResults = false;
            return;
          }
          if (result === 'success' && hasHardWarning) {
            status = 'Registration_Rejected_vod';
            registrationStatus = 'Rejected_vod';
          }
        }
      }

      this.loadingResults = true;
      const response = await this.service.updateAttendee(this.attendeeForUpdate(row, status, registrationStatus));
      if (response.status === -1) {
        const subMessage = Object.values(response.errors)
          .map(({ errorMessage }) => errorMessage)
          .join('\n');
        this.dispatchEvent(
          new ShowToastEvent({
            title: response.message,
            message: subMessage,
            variant: 'error',
          })
        );
        this.loadingResults = false;
      } else {
        getRecordNotifyChange([{ recordId: response?.data?.Id }]);
      }
    }
  }

  async dismissWalkIn() {
    this.loadingResults = true;
    const toDismiss = {
      Id: this.attendeeId,
    };
    toDismiss[this.statusField.fieldApiName] = DISMISSED_VOD;
    const response = await this.service.dismissAttendees(this.eventId, [toDismiss]);
    if (response.status === -1) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: response.message,
          message: response.data.recordErrors.join('\n'),
          variant: 'error',
        })
      );
      this.loadingResults = false;
    } else {
      getRecordNotifyChange([{ recordId: this.attendeeId }]);
    }
  }

  async createNewAccount() {
    if (this.isNAWEnabled) {
      this.navigateToNewAccountWizard();
    } else {
      this.navigateToNewAccountPage();
    }
  }
  
  async navigateToNewAccountWizard() {
    const newAccountWizardUrl = '/apex/NewAccountWithRecordTypeLgtnVod';
    const currentUrl = await this[NavigationMixin.GenerateUrl](this.pageRef);
    // Strip any params off
    const redirectUrl = `${currentUrl.split('?')[0]}?c__action=${EmEventConstant.ATTENDEE_RECONCILIATION}`;
    const queryParams = new URLSearchParams({
      retURL: redirectUrl,
      caller: NAW_RECONCILIATION_CALLER_PARAM
    });
    if (this.attendeeId && this.eventId) {
      queryParams.append('callerParams', `attId:${this.attendeeId},eventId:${this.eventId}`);
    }
    if (this.hasDcrMode) {
      queryParams.append('dcr', 'true');
    }
    const url = `${newAccountWizardUrl}?${queryParams.toString()}`;
    this.navigateToUrl(url);
  }

  navigateToUrl(url) {
    this[NavigationMixin.Navigate]({
      type: 'standard__webPage',
      attributes: {
        url,
      },
    });
  }

  navigateToNewAccountPage() {
    const state = { useRecordTypeCheck: 1 };
    this.navigateToRecordPage('standard__objectPage', 'new', 'Account', null, state);
  }
    
  navigateToRecordPage(type, actionName, objectApiName, recordId, state) {
    this[NavigationMixin.Navigate]({
      type,
      attributes: {
        actionName,
        recordId,
        objectApiName,
      },
      state
    });
  }

 // Matches GasCreateAccountAccess
 isAccountNotCreateable(canCreateAccount, canCreateDCR, canCreateDCRLine, canQueryDCRFieldType, customSettingValues) {
    let cannotCreateRecord = true;
    const { networkCustomerMasterMode, hasNoManagedAccountTypeSettings, dcrMode } = customSettingValues;
    if (canCreateAccount && (hasNoManagedAccountTypeSettings === 'true' || this.dcrDisabledAndNoNetwork(networkCustomerMasterMode, dcrMode))) {
      cannotCreateRecord = false;
    } else if (NON_DISABLED_DCR_MODES.includes(dcrMode) && canCreateDCR && canCreateDCRLine && canQueryDCRFieldType) {
      cannotCreateRecord = false;
    }
    return cannotCreateRecord;
  }

  dcrDisabledAndNoNetwork(networkCustomerMasterMode, dcrMode) {
    return networkCustomerMasterMode === NETWORK_CUSTOMER_MASTER_MODE_DISABLED && dcrMode === DCR_MODE_DISABLED;
  }

  shouldRunBusinessRules(row) {
    return getFieldValue(this.attendeeRecord, REGISTRATION_TIMESTAMP) && getFieldValue(this.attendeeRecord, WALK_IN_STATUS) && 
            Object.keys(row).length && !row.isUser && !row.fromNetwork;
  }

  async constructWarningsAndLaunchModal(busRuleResponse) {
    let result;
    let hasHardWarning = false;
    const busRuleWarnings = this.constructWarnings(busRuleResponse);
    if (busRuleWarnings?.length) {
      hasHardWarning = busRuleWarnings.some(warning => warning.EM_Business_Rule_vod__c?.Warning_Type_vod__c === BusRuleConstant.WARNING_TYPE.HARD)
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      result = await EmBusRuleViolationsModal.open({
        violations: busRuleWarnings,
        eventId: this.eventId,
        eventName: this.eventName,
        size: 'medium',
        entryPoint: EmEventConstant.ATTENDEE_RECONCILIATION,
      });
    }
    return [result, hasHardWarning];
  }

  constructWarnings(response) {
    const warningsResponse = response[0];
    const attendeeName = warningsResponse.Attendee_Name_vod__c;
    const busRuleWarnings = warningsResponse.warnings.map(warning => ({
      EM_Business_Rule_vod__c: {
        RecordTypeId: warning.ruleRecordType,
        Warning_Type_vod__c: warning.warningType,
      },
      EM_Event_Override_vod__c: {
        Event_vod__c: this.eventId,
        Event_Action_vod__c: 'Attendee_Reconciliation_vod',
        RecordTypeId: warning.eventOverrideRecordTypeId,
        Veeva_ID_vod__c: warning.ruleId,
        EM_Attendee_vod__c: this.attendeeId,
        Comment_Box_vod__c: warning.commentBox,
        Warning_Text_vod__c: warning.warningText,
      },
      EM_Attendee_vod__c: {
        Id: this.attendeeId,
        Attendee_Name_vod__c: attendeeName,
      }
    }));
    return busRuleWarnings;
  }
}