import EmController from 'c/emController';
import EmEventConstant from 'c/emEventConstant';
import EmExpenseConstant from 'c/emExpenseConstant';
import EmEventRecord from 'c/emEventRecord';
import EmAttendeeRelatedListController from 'c/emAttendeeRelatedListController';
import EmBusRuleViolationsModal from 'c/emBusRuleViolationsModal';
import EmCallRelatedListController from 'c/emCallRelatedListController';
import EmEventMaterialRelatedListController from 'c/emEventMaterialRelatedListController';
import EmEventRelatedListController from 'c/emEventRelatedListController';
import EmEventSessionRelatedListController from 'c/emEventSessionRelatedListController';
import EmEventSpeakerRelatedListController from 'c/emEventSpeakerRelatedListController';
import EmEventTeamMemberRelatedListController from 'c/emEventTeamMemberRelatedListController';
import EmNextStepsSideBarController from 'c/emNextStepsSideBarController';
import EmEventEngageService from 'c/emEventEngageService';
import VeevaAddressPicklistController from 'c/veevaAddressPicklistController';
import LookupDataReferenceController from 'c/lookupDataReferenceController';
import VeevaAddressService from 'c/veevaAddressService';
import EmDatetimeFieldService from 'c/emDatetimeFieldService';
import { getNextStepsHTMLContent, getNextStepsTitle } from 'c/emNextStepsContent';
import TOPIC from '@salesforce/schema/EM_Event_vod__c.Topic_vod__c';
import ENGAGE_WEBINAR from '@salesforce/schema/EM_Event_vod__c.Engage_Webinar_vod__c';
import MEETING_ID from '@salesforce/schema/Remote_Meeting_vod__c.Meeting_Id_vod__c';
import SCHEDULED from '@salesforce/schema/Remote_Meeting_vod__c.Scheduled_vod__c';
import ALLOW_JOINING_VIA_ZOOM from '@salesforce/schema/Remote_Meeting_vod__c.Allow_for_Joining_Event_via_Zoom_vod__c';
import ZOOM_JOIN_TOKEN from '@salesforce/schema/Remote_Meeting_vod__c.Zoom_Join_Token_vod__c';
import VEXTERNAL_ID from '@salesforce/schema/Remote_Meeting_vod__c.VExternal_Id_vod__c';
import ADDRESS from '@salesforce/schema/EM_Event_vod__c.Address_vod__c';
import ACCOUNT from '@salesforce/schema/EM_Event_vod__c.Account_vod__c';
import EVENT_CONFIGURATION from '@salesforce/schema/EM_Event_vod__c.Event_Configuration_vod__c';
import VENUE from '@salesforce/schema/EM_Event_vod__c.Venue_vod__c';
import AV_EQUIPMENT from '@salesforce/schema/EM_Event_vod__c.AV_Equipment_vod__c';
import FLAT_FEE_EXPENSE from '@salesforce/schema/EM_Event_vod__c.Flat_Fee_Expense_vod__c';
import MEAL_TYPE from '@salesforce/schema/EM_Event_vod__c.Meal_Type_vod__c';
import EVENT_FORMAT from '@salesforce/schema/EM_Event_vod__c.Event_Format_vod__c';
import LOCATION_TYPE from '@salesforce/schema/EM_Event_vod__c.Location_Type_vod__c';
import PARENT_EVENT from '@salesforce/schema/EM_Event_vod__c.Parent_Event_vod__c';
import KEY_CONTACT from '@salesforce/schema/EM_Event_vod__c.Key_Contact_vod__c';
import KEY_CONTACT_NAME from '@salesforce/schema/EM_Event_vod__c.Key_Contact_Name_vod__c';
import KEY_CONTACT_EMAIL from '@salesforce/schema/EM_Event_vod__c.Key_Contact_Email_vod__c';
import KEY_CONTACT_PHONE from '@salesforce/schema/EM_Event_vod__c.Key_Contact_Phone_vod__c';
import USER_ID from '@salesforce/user/Id';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import getUserPreferenceCountryConfig from '@salesforce/apex/EmEventController.getUserPreferenceCountryConfig';
import hasEngageWebinarEditAccess from '@salesforce/apex/EmEventController.hasEngageWebinarEditAccess';
import getRelatedRecords from '@salesforce/apex/VeevaRelatedObjectController.getRelatedRecords';
import LightningConfirm from 'lightning/confirm';
import TopicReferenceController from './topicReferenceController';
import EmDatetimeFieldController from './emDatetimeFieldController';
import ZvodLocalDateTimeController from './zvodLocalDateTimeController';
import EmBusinessRulePicklistController from './emBusinessRuleMultiPicklistController';
import MealTypePicklistController from './mealTypePicklistController';
import fieldWithoutUndoTemplate from './fieldWithoutUndoTemplate.html';

const END_TIME_BEFORE_START_TIME_MESSAGE_DEFAULT = 'The end time must be later than the start time.';
const NO_EVENT_CONFIG_DEFAULT = 'You are not allowed to schedule this type of event during this time frame. Please contact your administrator.';
const START_TIME_DEFAULT = 'Start Time';
const END_TIME_DEFAULT = 'End Time';
const RETRY_ENGAGE_BUTTON_NAME = 'Retry_Engage_vod';
const RETRY_DEFAULT = 'Retry Schedule Engage';
const RETRY_HOVER_DEFAULT = 'Something went wrong with Engage';
const REGISTRATION_UPDATE_CONFIRMATION_DEFAULT = 'Event registration is already published. Updates to the event may result in different form fields captured for registrants.';

export default class EmEventController extends EmController {
  constructor(dataSvc, userInterface, messageSvc, metaStore, emPageLayoutEngineSvc, eventActionSvc, emDataSvc) {
    super(dataSvc, userInterface, messageSvc, metaStore, emPageLayoutEngineSvc);
    this.eventActionSvc = this.getProxiedService(eventActionSvc);
    this.emDataSvc = this.getProxiedService(emDataSvc);
    this.emEventEngageSvc = new EmEventEngageService(this.uiApi, this.dataSvc);
  }

  get endTimeBeforeStartTimeMessage() {
    return this._endTimeBeforeStartTimeMessage || END_TIME_BEFORE_START_TIME_MESSAGE_DEFAULT;
  }

  get noEventConfigMessage() {
    return this._noEventConfigMessage || NO_EVENT_CONFIG_DEFAULT;
  }

  get veevaAddressService() {
    if (!this._veevaAddressService) {
      this._veevaAddressService = new VeevaAddressService();
    }
    return this._veevaAddressService;
  }

  get emDatetimeFieldService() {
    if (!this._emDatetimeFieldService) {
      this._emDatetimeFieldService = new EmDatetimeFieldService();
    }
    return this._emDatetimeFieldService;
  }

  async getPicklistValues(field, recordTypeId) {
    switch (field) {
      case AV_EQUIPMENT.fieldApiName:
      case FLAT_FEE_EXPENSE.fieldApiName:
      case MEAL_TYPE.fieldApiName: {
        return this.picklistOptionMap[field] ?? { values: [] };
      }
      default:
        return super.getPicklistValues(field, recordTypeId);
    }
  }

  get shouldShowFileUpload() {
    const lockedEventStatusValues = ['Canceled_vod', 'Closed_vod'];
    return !(this.record.isLocked || lockedEventStatusValues.includes(this.record.rawValue('Status_vod__c')));
  }

  toVeevaRecord(value) {
    return value instanceof EmEventRecord ? value : new EmEventRecord(value);
  }

  initItemController(meta, record, resetCtrl) {
    const { field } = meta;
    if (field) {
      const fieldDescribe = this.objectInfo.getFieldInfo(field);
      if (field === TOPIC.fieldApiName) {
        return new TopicReferenceController(meta, this, fieldDescribe, record);
      }
      if (field === ADDRESS.fieldApiName && this.action !== 'View') {
        fieldDescribe.controllerName = ACCOUNT.fieldApiName;
        // Store veevaAddressService instance to keep cached addresses, when field undo resets the item controller
        return new VeevaAddressPicklistController(meta, this, fieldDescribe, record, this.veevaAddressService, resetCtrl);
      }
      if (field === ACCOUNT.fieldApiName) {
        return new LookupDataReferenceController(meta, this, fieldDescribe, record);
      }
      if (record.rawValue(VENUE.fieldApiName) && Object.values(EmEventConstant.VENUE_FIELD_TO_EVENT_FIELD_MAP).includes(field)) {
        return super.initItemController({ ...meta, disabled: true }, record);
      }
      if(field === KEY_CONTACT_NAME.fieldApiName && record.rawValue(KEY_CONTACT.fieldApiName)) {
        return super.initItemController({ ...meta, disabled: true }, record);
      }
      if (field === EmEventConstant.START_TIME || field === EmEventConstant.END_TIME) {
        return new EmDatetimeFieldController(meta, this, fieldDescribe, record, this.emDatetimeFieldService);
      }
      if (field === EmEventConstant.ZVOD_START_TIME || field === EmEventConstant.ZVOD_END_TIME) {
        return new ZvodLocalDateTimeController(
          meta,
          this,
          fieldDescribe,
          record,
          field === EmEventConstant.ZVOD_START_TIME,
          this.emDatetimeFieldService
        );
      }
      // eslint-disable-next-line @locker/locker/distorted-shadow-root-mode-getter
      if (this.page.layout.mode !== 'View') {
        if (field === MEAL_TYPE.fieldApiName && this.featureFlags?.BUSINESS_RULE_EVENT_FORMAT_LOCATION_TYPE) {
          return new MealTypePicklistController(meta, this, fieldDescribe, record, true);
        }
        if (field === MEAL_TYPE.fieldApiName || field === AV_EQUIPMENT.fieldApiName || field === FLAT_FEE_EXPENSE.fieldApiName) {
          return new EmBusinessRulePicklistController(meta, this, fieldDescribe, record, true);
        }
      }
    }
    return super.initItemController(meta, record);
  }

  initTemplate(ctrl) {
    switch (ctrl.fieldApiName) {
      // Render as text, not checkbox
      case EmEventConstant.ZVOD_EVENT_LAYOUT:
        ctrl.veevaText = true;
        return ctrl;
      case EmEventConstant.ZVOD_ZOOM_JOIN_TOKEN:
        ctrl.veevaText = true;
        ctrl.editable = false;
        return ctrl;
      case EmEventConstant.COUNTRY:
        if (this.record.isNew) {
          ctrl.editable = false;
        }
        return super.initTemplate(ctrl);
      case EmEventConstant.ZVOD_START_TIME:
      case EmEventConstant.ZVOD_END_TIME:
        if (
          this.record.isNew ||
          (this.action !== 'View' &&
            ((ctrl.fieldApiName === EmEventConstant.ZVOD_START_TIME && this.layoutFields[EmEventConstant.ZVOD_START_TIME].editableForUpdate) ||
              (ctrl.fieldApiName === EmEventConstant.ZVOD_END_TIME && this.layoutFields[EmEventConstant.ZVOD_END_TIME].editableForUpdate)))
        ) {
          ctrl.editable = true;
          ctrl.required = true;
          ctrl.veevaLightningInput = true;
        } else {
          ctrl.veevaText = true;
        }
        return ctrl;
      case EmEventConstant.TIME_ZONE:
        if (this.record.isNew) {
          ctrl.editable = true;
          ctrl.required = true;
        } else if (this.record.isEdit && ctrl.editable) {
          ctrl.required = true;
        }
        return super.initTemplate(ctrl);
      case EmEventConstant.START_TIME:
      case EmEventConstant.END_TIME:
        if (this.record.isNew) {
          ctrl.editable = true;
          ctrl.required = true;
          ctrl.veevaLightningInput = true;
        }
        return super.initTemplate(ctrl);
      case EmEventConstant.WEBINAR_STATUS:
        ctrl.editable = false; // shown as always read-only
        return super.initTemplate(ctrl);
      case MEAL_TYPE.fieldApiName:
      case EVENT_FORMAT.fieldApiName:
      case LOCATION_TYPE.fieldApiName:
        if (this.featureFlags?.BUSINESS_RULE_EVENT_FORMAT_LOCATION_TYPE && this.isFieldOnLayout(MEAL_TYPE.fieldApiName)) {
          ctrl.template = fieldWithoutUndoTemplate;
        }
        return super.initTemplate(ctrl);
      default:
        return super.initTemplate(ctrl);
    }
  }

  async loadMetadata() {
    this.engageButtonsPromise =
      this.action === 'View' ? this.emEventEngageSvc.checkIncludeEngageButtons(this.id, this.objectInfo, this.record) : Promise.resolve({});
    this.failedConcurExpenseHeadersPromise = this.action === 'View' ? this.getFailedConcurStatusExpenseHeaders() : Promise.resolve([]);
    await Promise.all([super.loadMetadata(), this.populateEventMessageMap()]);
  }

  async populateEventMessageMap() {
    const messageMap = await this.messageSvc
      .createMessageRequest()
      .addRequest('END_TIME_BEFORE_START_TIME', 'EVENT_MANAGEMENT', END_TIME_BEFORE_START_TIME_MESSAGE_DEFAULT, 'endTimeBeforeStartTime')
      .addRequest('NO_EVENT_CONFIG', 'EVENT_MANAGEMENT', NO_EVENT_CONFIG_DEFAULT, 'noEventConfig')
      .addRequest('START_TIME', 'EVENT_MANAGEMENT', START_TIME_DEFAULT, 'startTime')
      .addRequest('END_TIME', 'EVENT_MANAGEMENT', END_TIME_DEFAULT, 'endTime')
      .addRequest('RETRY_SCHEDULE_ENGAGE', 'EVENT_MANAGEMENT', RETRY_DEFAULT, 'retryScheduleEngage')
      .addRequest('WEBINAR_ERROR_NOTIFICATION', 'EVENT_MANAGEMENT', RETRY_HOVER_DEFAULT, 'webinarErrorNotification')
      .addRequest('FAILED_EXPENSES', 'Concur', 'Failed Expense(s)', 'failedExpensesLabel')
      .addRequest('CONCUR_FAILURE_EVENT_VIEW', 'Concur', 'Concur Failed', 'concurFailedLabel')
      .addRequest('REGISTRATION_UPDATE_CONFIRMATION', 'EVENT_MANAGEMENT', REGISTRATION_UPDATE_CONFIRMATION_DEFAULT, 'registrationUpdateConfirmation')
      .sendRequest();
    this._endTimeBeforeStartTimeMessage = messageMap.endTimeBeforeStartTime;
    this._noEventConfigMessage = messageMap.noEventConfig;
    this.startTimeLabel = messageMap.startTime;
    this.endTimeLabel = messageMap.endTime;
    this.retryEngageButtonLabel = messageMap.retryScheduleEngage;
    this.retryEngageButtonHover = messageMap.webinarErrorNotification;
    this.failedExpenseButtonLabel = messageMap.failedExpensesLabel;
    this.failedExpenseButtonHover = messageMap.concurFailedLabel;
    this.registrationUpdateConfirmationLabel = messageMap.registrationUpdateConfirmation;
  }

  getSideBarController() {
    const emSideBarController = new EmNextStepsSideBarController(null, this);
    return emSideBarController.initTemplate();
  }

  hasSideBar() {
    return !!((this.isEdit || this.isNew) && this.nextSteps);
  }

  processLayout(layout) {
    this.picklistOptionMap = layout.picklistOptionMap ?? {};

    super.processLayout(layout);

    this.processZvodField(layout);

    this.featureFlags = layout.featureFlags;
    this.nextSteps = layout.nextSteps;
    this.expenseRelatedListFields = layout.expenseRelatedListFields;

    return layout;
  }

  async initData() {
    const promises = [super.initData()];
    if (this.isLocalDateTimeActive()) {
      this.processZvodTimeFields();
      if (this.record.isNew) {
        promises.push(this.setDefaultTimeZone());
      }
    }
    promises.push(this.fetchNextStepsContent());
    await Promise.all(promises);
  }

  async fetchNextStepsContent() {
    [this.nextStepsContent, this.nextStepsTitle] = await Promise.all([getNextStepsHTMLContent(this), getNextStepsTitle(this)]);
  }

  isItemToHide(item) {
    let toHide;
    switch (item.field) {
      case AV_EQUIPMENT.fieldApiName:
      case FLAT_FEE_EXPENSE.fieldApiName:
      case MEAL_TYPE.fieldApiName:
        toHide =
          this.action !== 'View' &&
          (!this.picklistOptionMap[item.field] || this.picklistOptionMap[item.field]?.values?.length === 0) &&
          !this.record.rawValue(item.field);
        break;
      default:
        toHide = super.isItemToHide(item);
        break;
    }
    return toHide;
  }

  shouldKeepDefaultField(fieldApiName) {
    return fieldApiName === PARENT_EVENT.fieldApiName || super.shouldKeepDefaultField(fieldApiName);
  }

  processZvodField(layout) {
    if (this.objectInfo.getFieldInfo(EmEventConstant.ZVOD_EVENT_LAYOUT)) {
      this.record.setFieldValue(EmEventConstant.ZVOD_EVENT_LAYOUT, layout.layoutName);
    }
    if (this.objectInfo.getFieldInfo(EmEventConstant.ZVOD_ZOOM_JOIN_TOKEN)) {
      const zoomToken = this.getZoomJoinToken();
      if (zoomToken) {
        this.record.setFieldValue(EmEventConstant.ZVOD_ZOOM_JOIN_TOKEN, this.deObfuscateZoomLink(zoomToken));
      }
    }
  }

  processZvodTimeFields() {
    if (this.objectInfo.getFieldInfo(EmEventConstant.ZVOD_START_TIME) && this.objectInfo.getFieldInfo(EmEventConstant.ZVOD_END_TIME)) {
      this.record.setFieldValue(
        EmEventConstant.ZVOD_START_TIME,
        this.formatLocalDateTimetoZvod(EmEventConstant.START_TIME_LOCAL, EmEventConstant.START_DATE)
      );
      this.record.setFieldValue(
        EmEventConstant.ZVOD_END_TIME,
        this.formatLocalDateTimetoZvod(EmEventConstant.END_TIME_LOCAL, EmEventConstant.END_DATE)
      );
    }
  }

  formatLocalDateTimetoZvod(localTime, localDate) {
    const localTimeField = this.record.rawValue(localTime);
    const localDateField = this.record.rawValue(localDate);
    if (localTimeField && localDateField) {
      return `${localDateField}T${localTimeField}`;
    }
    return null;
  }

  async isValidTimeZone(timeZone) {
    if (!timeZone) {
      return false;
    }
    if (!this.timeZonePicklistValues) {
      this.timeZonePicklistValues = await this.getPicklistValues(EmEventConstant.TIME_ZONE);
    }
    return this.timeZonePicklistValues?.values.some(value => value.value === timeZone);
  }

  async setDefaultTimeZone() {
    if (!this.objectInfo.getFieldInfo(EmEventConstant.TIME_ZONE) || (await this.isValidTimeZone(this.record.rawValue(EmEventConstant.TIME_ZONE)))) {
      return;
    }
    let timeZone = null;
    const timeZonePreference = await getRelatedRecords({
      fields: 'Time_Zone_vod__c',
      objectApiName: 'Preferences_vod__c',
      relationField: 'User_vod__c',
      id: USER_ID,
      duplicateRawFields: true,
    });
    if (await this.isValidTimeZone(timeZonePreference?.[0]?.Time_Zone_vod__c)) {
      timeZone = timeZonePreference[0].Time_Zone_vod__c;
    } else if (await this.isValidTimeZone(TIME_ZONE)) {
      timeZone = TIME_ZONE;
    }
    this.record.setFieldValue(EmEventConstant.TIME_ZONE, timeZone);
  }

  getZoomJoinToken() {
    const engageWebinarFieldInfo = this.objectInfo.getFieldInfo(ENGAGE_WEBINAR.fieldApiName);
    const remoteMeeting = engageWebinarFieldInfo && this.record.rawValue(engageWebinarFieldInfo.relationshipName);
    const allowForJoiningEventViaZoom = remoteMeeting?.fields?.Allow_for_Joining_Event_via_Zoom_vod__c?.value;
    const zoomJoinToken = remoteMeeting?.fields?.Zoom_Join_Token_vod__c?.value;
    return allowForJoiningEventViaZoom && zoomJoinToken ? zoomJoinToken : null;
  }

  getVExternalId() {
    const engageWebinarFieldInfo = this.objectInfo.getFieldInfo(ENGAGE_WEBINAR.fieldApiName);
    const remoteMeeting = engageWebinarFieldInfo && this.record.rawValue(engageWebinarFieldInfo.relationshipName);
    return remoteMeeting?.fields?.[VEXTERNAL_ID.fieldApiName]?.value;
  }

  deObfuscateZoomLink(token) {
    const decodeBase64 = window.atob(token);
    const deObfuscateArr = new Array(decodeBase64.length);
    for (let i = 0; i < decodeBase64.length; i++) {
      // eslint-disable-next-line no-bitwise
      const shiftedChar = (decodeBase64.charCodeAt(i) & 0xff) >>> 1;
      deObfuscateArr[i] = String.fromCharCode(shiftedChar);
    }
    return deObfuscateArr.join('');
  }

  setCountryField(countryId) {
    if (this.objectInfo.getFieldInfo(EmEventConstant.COUNTRY)) {
      this.record.setFieldValue(EmEventConstant.COUNTRY, countryId);
    }
  }

  setEventConfigField(eventId) {
    if (this.objectInfo.getFieldInfo(EmEventConstant.EVENT_CONFIG)) {
      this.record.setFieldValue(EmEventConstant.EVENT_CONFIG, eventId);
    }
  }

  async initRecordCreate(pageRef) {
    await this.initRecordCreateBase(pageRef);
    this.defVals = pageRef.state.defaultFieldValues && JSON.parse(pageRef.state.defaultFieldValues);

    this.setCountryField(this.defVals.countryId);
    this.setEventConfigField(this.defVals.eventConfigId);
    await this.initPageLayout();
  }

  getEventPleParams({ countryAlpha2Code, eventConfigId, recordTypeId }) {
    return { countryAlpha2Code, eventConfigId, recordTypeId };
  }

  /**
   * For Edit and View pages get PLE fields from getQueryFields
   * For New Pages get PLE fields from flow default values
   * @returns {Object} containing PLE fields
   */
  async getPleParams() {
    let params = {};
    if (this.action !== 'New') {
      params.eventStatus = this.record.rawValue('Status_vod__c');
      params.countryAlpha2Code = this.record.rawValue('Country_vod__r')?.fields?.Alpha_2_Code_vod__c.value;
      params.eventConfigId = this.record.rawValue('Event_Configuration_vod__c');
      params.cventMeetingRequestId = this.record.rawValue('Cvent_Meeting_Request_ID_vod__c');
      params.eventCountry = this.record.rawValue('Country_vod__c');
      params.eventStartTime = this.record.rawValue('Start_Time_vod__c');
    } else {
      params = this.getEventPleParams(this.defVals);
    }
    return params;
  }

  /**
   * For Edit and View pages get PLE fields with the rest of the fields
   * @returns {Array} of query fields with appended PLE fields
   */
  getQueryFields() {
    const queryFields = super.getQueryFields();
    if (this.action !== 'New') {
      queryFields.push(`${this.objectApiName}.Country_vod__r.Alpha_2_Code_vod__c`);
    }

    return queryFields;
  }

  getOptionalQueryFields() {
    const queryFields = super.getOptionalQueryFields();
    const remoteMeetingFieldInfo = this.objectInfo.getFieldInfo(ENGAGE_WEBINAR.fieldApiName);
    if (remoteMeetingFieldInfo?.relationshipName) {
      queryFields.push(`${this.objectApiName}.${remoteMeetingFieldInfo.relationshipName}.${MEETING_ID.fieldApiName}`);
      queryFields.push(`${this.objectApiName}.${remoteMeetingFieldInfo.relationshipName}.${SCHEDULED.fieldApiName}`);
      queryFields.push(`${this.objectApiName}.${remoteMeetingFieldInfo.relationshipName}.${ALLOW_JOINING_VIA_ZOOM.fieldApiName}`);
      queryFields.push(`${this.objectApiName}.${remoteMeetingFieldInfo.relationshipName}.${ZOOM_JOIN_TOKEN.fieldApiName}`);
      queryFields.push(`${this.objectApiName}.${remoteMeetingFieldInfo.relationshipName}.RecordType.DeveloperName`);
      queryFields.push(`${this.objectApiName}.${remoteMeetingFieldInfo.relationshipName}.${VEXTERNAL_ID.fieldApiName}`);
    }
    return queryFields;
  }

  async handleEventActionResult(eventActionId, data, buttonLabel) {
    const response = { success: true };
    try {
      const actionResult = await this.eventActionSvc.statusChange(this.id, eventActionId, data, true);
      if (actionResult?.data?.length) {
        // handle business rules
        // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
        const modalResult = await EmBusRuleViolationsModal.open({
          violations: actionResult.data,
          buttonName: data.buttonName,
          eventId: this.id,
          eventName: this.record.name,
          label: buttonLabel,
          size: 'medium',
        });
        if (modalResult !== 'success') {
          // cancel event action save process
          throw new Error();
        }
        // redo status change without business rules
        await this.eventActionSvc.statusChange(this.id, eventActionId, data, false);
      }
      this.processForLDSCache({ Id: this.id });
    } catch (error) {
      response.success = false;
      switch (error.message) {
        case 'REQUIRED_FIELD_MISSING':
          response.requiredFieldMissing = true;
          break;
        case 'NO_APPLICABLE_PROCESS':
          response.message = error.errors.NO_APPLICABLE_PROCESS.errorMessage;
          break;
        default:
          response.message = error.message;
      }
    }
    return response;
  }

  async validate() {
    let startTime;
    let endTime;
    if (this.isLocalDateTimeActive()) {
      startTime = this.formatLocalDateTimetoZvod(EmEventConstant.START_TIME_LOCAL, EmEventConstant.START_DATE);
      endTime = this.formatLocalDateTimetoZvod(EmEventConstant.END_TIME_LOCAL, EmEventConstant.END_DATE);
    } else {
      startTime = this.record.rawValue(EmEventConstant.START_TIME);
      endTime = this.record.rawValue(EmEventConstant.END_TIME);
    }
    return this.isEndTimeAfterStartTime(startTime, endTime) && this.isStartTimeWithinEventConfig(startTime);
  }

  isEndTimeAfterStartTime(startTime, endTime) {
    let startTimeIsBeforeEndTime = true;
    if (startTime != null && endTime != null && startTime > endTime) {
      this.addRecordError(this.endTimeBeforeStartTimeMessage);
      startTimeIsBeforeEndTime = false;
    }
    return startTimeIsBeforeEndTime;
  }

  getRelatedListController(meta, pageCtrl) {
    let ctrl = null;
    switch (meta.relationship) {
      case 'EM_Attendee_Event_vod__r':
        ctrl = new EmAttendeeRelatedListController(meta, pageCtrl);
        break;
      case 'EM_Event_Speaker_vod__r':
        ctrl = new EmEventSpeakerRelatedListController(meta, pageCtrl);
        break;
      case 'EM_Event_Session_vod__r':
        ctrl = new EmEventSessionRelatedListController(meta, pageCtrl);
        break;
      case 'Call2_vod__r':
        ctrl = new EmCallRelatedListController(meta, pageCtrl);
        break;
      case 'EM_Event_Parent_Event_vod__r':
        ctrl = new EmEventRelatedListController(meta, pageCtrl);
        break;
      case 'EM_Event_Team_Member_vod__r':
        ctrl = new EmEventTeamMemberRelatedListController(meta, pageCtrl);
        break;
      case 'Event_Materials__r':
        ctrl = new EmEventMaterialRelatedListController(meta, pageCtrl);
        break;
      default:
        ctrl = super.getRelatedListController(meta, pageCtrl);
    }
    return ctrl;
  }

  useFlowNavAfterNew() {
    return false;
  }

  useFlowNavAfterEdit() {
    return false;
  }

  async isStartTimeWithinEventConfig(startTime) {
    const recordTypeDeveloperName = this.record.fields?.RecordType?.value?.fields?.DeveloperName?.value ?? '';
    const { countryAlpha2Code } = await this.getPleParams();

    const { configId, errorMessage } = await this.getEventConfig(startTime, recordTypeDeveloperName, countryAlpha2Code);
    if (configId) {
      this.setEventConfig(configId);
    }
    if (errorMessage) {
      this.setEventConfigError(errorMessage);
    }

    return !!configId;
  }

  async getEventConfig(startDate, eventType, countryCode) {
    const path = '/api/v1/layout3/em-wizard/configs';
    let configId = null;
    const defaultCountryConfig = await getUserPreferenceCountryConfig();
    const [defaultCountryCode] = defaultCountryConfig.split(';');
    const params = {
      eventType,
      countryCode,
      defaultCountryCode,
      startDate: startDate.toLocaleString(),
    };
    let errorMessage = null;

    Object.entries(params).forEach(([key, value]) => {
      params[key] = value || '';
    });

    try {
      const response = await this.dataSvc.sendRequest('GET', path, params, null, 'getEventConfig', null);
      if (response?.payload) {
        if (response.payload.errors?.length > 0) {
          throw new Error(response.payload.errors[0]);
        } else {
          configId = response.payload.countryToConfig?.[countryCode];
          if (!configId) {
            throw new Error(this.noEventConfigMessage);
          }
        }
      }
    } catch (error) {
      errorMessage = error;
    }
    return { configId, errorMessage };
  }

  setEventConfig(eventConfigId) {
    this.record.setFieldValue(EVENT_CONFIGURATION.fieldApiName, eventConfigId, null);
  }

  setEventConfigError(error) {
    let message = error;
    if (error) {
      if (error.payload?.errors?.length > 0) {
        [message] = error.payload.errors;
      } else if (error.message) {
        message = error.message;
      }
    }
    this.addRecordError(message);
  }

  setFieldValue(field, value, reference, record, source) {
    super.setFieldValue(field, value, reference, record, source);

    if ((field.apiName || field) === VENUE.fieldApiName) {
      this.setLocationFields(value, record);
    }
    if ((field.apiName || field) === KEY_CONTACT.fieldApiName) {
      this.setKeyContactFields(value, record);
    }
  }

  async setLocationFields(venue, record) {
    if (venue) {
      const venueFields = Object.keys(EmEventConstant.VENUE_FIELD_TO_EVENT_FIELD_MAP).map(field => `EM_Venue_vod__c.${field}`);
      const venueRecord = await this.uiApi.getRecord(venue, venueFields);
      Object.entries(EmEventConstant.VENUE_FIELD_TO_EVENT_FIELD_MAP).forEach(([venueField, eventField]) => {
        const value = venueRecord.fields?.[venueField]?.value ?? null;
        record.setFieldValue(eventField, value, null);
      });
    }
    this.page.recordUpdateFlag = !this.page.recordUpdateFlag;
  }

  async setKeyContactFields(value, record) {
    let keyContact = {};
    if (value) {
      keyContact = await this.uiApi.getRecord(value, ['User.Name', 'User.Email', 'User.Phone']);
    }
    record.setFieldValue(KEY_CONTACT_NAME.fieldApiName, keyContact.fields?.Name?.value ?? null, null);
    record.setFieldValue(KEY_CONTACT_EMAIL.fieldApiName, keyContact.fields?.Email?.value ?? null, null);
    record.setFieldValue(KEY_CONTACT_PHONE.fieldApiName, keyContact.fields?.Phone?.value ?? null, null);
    this.page.recordUpdateFlag = !this.page.recordUpdateFlag;
  }

  async getHeaderButtons() {
    const buttons = super.getHeaderButtons();
    const engageWarningButton = this.getEngageWarningButton();
    if (engageWarningButton) {
      buttons.unshift(engageWarningButton);
    }
    const failedConcurExpenseHeaders = await this.failedConcurExpenseHeadersPromise;
    if (failedConcurExpenseHeaders.length > 0) {
      buttons.unshift(await this.getFailedExpensesButton(failedConcurExpenseHeaders));
    }
    this.engageButtons = await this.engageButtonsPromise;
    return buttons.filter(button => this.shouldShowButton(button));
  }
  shouldShowButton(button) {
    let showButton;
    switch (button.name) {
      case 'Preview_Event_QR_Code_vod':
        showButton = this.record.rawValue('QR_Sign_In_Enabled_vod__c') === 'Yes_vod';
        break;
      case 'Start_Webinar_vod':
        showButton = !!this.engageButtons.includeStartWebinarButton;
        break;
      case 'Schedule_Engage_vod':
        showButton = !!this.engageButtons.includeScheduleEngageButton;
        break;
      default:
        showButton = true;
    }
    return showButton;
  }

  getFailedExpensesButton(failedConcurExpenseHeaders) {
    const buttonName = failedConcurExpenseHeaders.length === 1 ? 'Failed_Expense_vod' : 'Failed_Expenses_vod';
    return {
      name: buttonName,
      label: this.failedExpenseButtonLabel,
      title: this.failedExpenseButtonHover,
      edit: false,
      isWarning: true,
    };
  }

  getEngageWarningButton() {
    let engageWarningButton;
    if (this.page.action === 'View' && 'Failed_vod' === this.record.rawValue('Webinar_Status_vod__c')) {
      const parentEventFieldInfo = this.objectInfo.getFieldInfo(PARENT_EVENT.fieldApiName);
      const parentEvent = this.record.rawValue(parentEventFieldInfo?.relationshipName);
      const parentEventEngageWebinar = parentEvent?.fields?.Engage_Webinar_vod__c?.value;
      if (!parentEvent || !parentEventEngageWebinar) {
        engageWarningButton = {
          name: RETRY_ENGAGE_BUTTON_NAME,
          label: this.retryEngageButtonLabel,
          title: this.retryEngageButtonHover,
          edit: false,
          isWarning: true,
        };
      }
    }
    return engageWarningButton;
  }

  isLocalDateTimeActive() {
    return this.featureFlags?.LOCAL_DATE_TIME;
  }

  getPageRefForDelete() {
    return {
      type: 'standard__namedPage',
      attributes: {
        pageName: 'home',
      },
    };
  }

  async delete() {
    if ('On_vod' === this.record.rawValue('Webinar_Status_vod__c')) {
      return this.emEventEngageSvc.deleteWebinar(this.id);
    }
    return super.delete();
  }
  addDefaultFieldValues(state) {
    if (state?.defaultFieldValues) {
      const values = JSON.parse(state.defaultFieldValues);
      Object.entries(values)
        .filter(([key]) => key !== 'RecordTypeId')
        .forEach(([key, value]) => {
          if (this.record.fields[key] || this.objectInfo.getFieldInfo(key)) {
            this.record.setFieldValue(key, value);
          }
        });
    }
    super.addDefaultFieldValues(state);
  }

  async doSave(data) {
    this.filterOutUnchangedRegistrationFields(data);
    if (this.action === 'Edit' && this.shouldDisplayRegistrationConfirmation(data)) {
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      const confirmed = await LightningConfirm.open({
        message: this.registrationUpdateConfirmationLabel,
        variant: 'headerless',
      });
      if (!confirmed) {
        throw new Error();
      }
    }
    if (this.action !== 'View' && this.featureFlags?.BUSINESS_RULE_CREATION_RULE) {
      this.addFieldsToValidateCreationRulePicklists(data);
    }

    let response;
    if (this.action === 'New' && this.record.rawValue('Parent_Event_vod__c')) {
      response = this.doEventTemplateSave(data);
    } else if (
      Object.keys(data).length > 0 &&
      this.action === 'Edit' &&
      (this.record.rawValue('Webinar_Status_vod__c') === 'On_vod' ||
        (this.record.rawValue('Parent_Event_vod__c') && !this.record.rawValue('Engage_Webinar_vod__c'))) &&
      (await hasEngageWebinarEditAccess())
    ) {
      response = this.doSaveWithEngage(data);
    } else {
      response = super.doSave(data);
    }
    return response;
  }

  shouldDisplayRegistrationConfirmation(data) {
    return this.record.fields.Publish_Event_vod__c?.value && EmEventConstant.REGISTRATION_FORM_ASSIGNMENT_FIELDS.some(field => field in data);
  }

  filterOutUnchangedRegistrationFields(data) {
    Object.keys(data).forEach(key => {
        if (["Location_Type_vod__c", "Event_Format_vod__c"].includes(key) && this.record.old[key] === null && data[key] === "") {
            delete data[key];
        }
    });
    return data;
  }

  async doEventTemplateSave(data) {
    try {
      const response = await this.emDataSvc.eventTemplateSave(data);
      if (response.hasAccess) {
        return { data: response };
      }
      let errorMessage = await this.getMessageWithDefault(
        'EVENT_RELATED_LIST_MISSING',
        'EVENT_MANAGEMENT',
        'Unable to create the event because you are missing FLS for the following:\n\nObject Fields: {0}\n\nObjects: {1}\n\nRecord Types: {2}'
      );
      errorMessage = errorMessage
        .replace('{0}', response.fields?.join(', ') || '')
        .replace('{1}', response.objects?.join(', ') || '')
        .replace('{2}', response.recordTypes?.join(', ') || '');
      // eslint-disable-next-line prefer-promise-reject-errors
      return Promise.reject({ data: { recordErrors: [errorMessage] } });
    } catch (error) {
      this.removeFieldErrorsFromRecordErrors(error);
      // eslint-disable-next-line prefer-promise-reject-errors
      return Promise.reject({ data: error });
    }
  }

  async doSaveWithEngage(data) {
    data.Event_Display_Name_vod__c = data.Event_Display_Name_vod__c || this.record.rawValue('Event_Display_Name_vod__c');
    data.Name = data.Name || this.record.name;
    data.disableWebinar = false;
    data.Parent_Event_vod__c = this.record.rawValue('Parent_Event_vod__c');
    data.Engage_Webinar_vod__c = this.record.rawValue('Engage_Webinar_vod__c');
    data.skipSchedulingEngage = true;
    try {
      const response = await this.emEventEngageSvc.scheduleEngage(data);
      return response;
    } catch (error) {
      this.removeFieldErrorsFromRecordErrors(error.data);
      throw error;
    }
  }

  removeFieldErrorsFromRecordErrors(error) {
    if (error.fieldErrors && error.recordErrors) {
      error.recordErrors = error.recordErrors.filter(recordError => !Object.values(error.fieldErrors).includes(recordError));
    }
  }

  processError(error) {
    super.processError(error);
    if (error.picklistOptionMap) {
      this.record.setFieldValue('Meal_Type_vod__c', '');
      this.record.setFieldValue('Flat_Fee_Expense_vod__c', '');
      this.record.setFieldValue('AV_Equipment_vod__c', '');
      this.page.layout.picklistOptionMap = error.picklistOptionMap;
      this.picklistOptionMap = this.page.layout.picklistOptionMap ?? {};
      this.page.recordUpdateFlag = !this.page.recordUpdateFlag;
    }
  }

  addFieldsToValidateCreationRulePicklists(data) {
    if (Object.keys(data).length === 0) {
      return;
    }

    data.validateCreationRulePicklists = true;
    if (!this.isNew) {
      // add all fields required for validation to edit payload
      const fieldsToResave = [
        'AV_Equipment_vod__c',
        'Country_vod__c',
        'Event_Configuration_vod__c',
        'Flat_Fee_Expense_vod__c',
        'Meal_Type_vod__c',
        'RecordTypeId',
      ];
      if (this.featureFlags.LOCAL_DATE_TIME) {
        fieldsToResave.push('Start_Date_vod__c', 'Start_Time_Local_vod__c', 'Time_Zone_vod__c');
      } else {
        fieldsToResave.push('Start_Time_vod__c');
      }
      fieldsToResave.forEach(field => {
        const fieldInfo = this.objectInfo.getFieldInfo(field);
        if (fieldInfo?.updateable) {
          data[field] = this.record.rawValue(field);
        }
      });
    }
  }

  async getFailedConcurStatusExpenseHeaders() {
    let expenseHeaders;
    try {
      expenseHeaders = await getRelatedRecords({
        fields: EmExpenseConstant.CONCUR_STATUS,
        objectApiName: EmExpenseConstant.EXPENSE_HEADER,
        relationField: 'Event_vod__c',
        id: this.id,
        duplicateRawFields: true,
      });
    } catch (error) {
      return [];
    }
    const failedExpenses = expenseHeaders.filter(header =>
      EmExpenseConstant.RESUBMIT_CONCUR_STATUSES.includes(header?.[EmExpenseConstant.CONCUR_STATUS])
    );
    this.failedExpenses = failedExpenses;
    return failedExpenses;
  }
}