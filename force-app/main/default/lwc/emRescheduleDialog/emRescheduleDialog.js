import LightningModal from 'lightning/modal';
import { api, track } from 'lwc';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { VeevaMessageRequest } from 'c/veevaMessageService';
import EmEventConstant from 'c/emEventConstant';
import EM_EVENT_HISTORY from '@salesforce/schema/EM_Event_History_vod__c';
import START_TIME from '@salesforce/schema/EM_Event_vod__c.Start_Time_vod__c';
import END_TIME from '@salesforce/schema/EM_Event_vod__c.End_Time_vod__c';
import COMMENTS from '@salesforce/schema/EM_Event_History_vod__c.Comment_vod__c';

export default class EmRescheduleDialog extends LightningModal {
  @api dialog;

  @track model = {};
  @track warnings = [];
  @track errors = [];

  componentInitialized = false;
  isLoading = true;
  isConfirming = false;

  RESCHEDULE_START_DATE_TIME = 'startDatetime';
  RESCHEDULE_END_DATE_TIME = 'endDatetime';
  TIME_ZONE_FIELD = 'timeZone';
  MESSAGES = {
    endTimeError: {
      key: 'END_TIME_BEFORE_START_TIME',
      category: 'EVENT_MANAGEMENT',
      defaultMessage: 'The end time must be later than the start time.',
    },
    rescheduleError: {
      key: 'RESCHEDULE_ERROR',
      category: 'EVENT_MANAGEMENT',
      defaultMessage: 'You cannot reschedule to this date because of the following errors:',
    },
    noEventConfig: {
      key: 'NO_EVENT_CONFIG',
      category: 'EVENT_MANAGEMENT',
      defaultMessage: 'You are not allowed to schedule this type of event during this time frame. Please contact your administrator.',
    },
    rescheduleWarning: {
      key: 'RESCHEDULE_WARNING',
      category: 'EVENT_MANAGEMENT',
      defaultMessage: 'If you reschedule to this date, please be aware that:',
    },
    budgetWarning: {
      key: 'NEW_BUDGET_PERIOD_WARNING',
      category: 'EVENT_MANAGEMENT',
      defaultMessage: 'The new event time is in a new budget period. You may have to manually select new budgets.',
    },
    rescheduleRelatedEvents: {
      key: 'RESCHEDULE_RELATED_EVENTS',
      category: 'EVENT_MANAGEMENT',
      defaultMessage: 'Other events in this series will also be rescheduled',
    },
  };

  async connectedCallback() {
    if(!this.componentInitialized){
      this.componentInitialized = true;
      await this.init();
    }
  }

  async init() {
    await Promise.all([this.getMessages(), this.getEventHistory()]);
    this.model.eventActionId = this.dialog.eventAction.Id;
    this.pageCtrl = this.dialog.ctrl;

    this.model[this.RESCHEDULE_START_DATE_TIME] = this.currentStartTime;
    this.model[this.RESCHEDULE_END_DATE_TIME] = this.currentEndTime;
    if (this.isLocalDateTimeActive) {
      this.userTimeZone = 'UTC';
      this.setTimeZoneField(this.dialog.eventAction.timeZoneInfo);
    }
    this.isDateRangeValid();

    this.isLoading = false;
  }

  async getMessages() {
    const messageService = getService(SERVICES.MESSAGE);
    const messageRequest = new VeevaMessageRequest();

    Object.entries(this.MESSAGES).forEach(([label, {key, category, defaultMessage}]) => {
      messageRequest.addRequest(key, category, defaultMessage, label);
    });

    const messageMap = await messageService.getMessageMap(messageRequest);

    Object.entries(messageMap).forEach(([label, message]) => {
      this[label] = message;
    });
  }

  async getEventHistory() {
    const userInterfaceService = getService(SERVICES.UI_API);
    const eventHistory = await userInterfaceService.objectInfo(EM_EVENT_HISTORY.objectApiName);
    this.eventHistoryDescribe = eventHistory;
  }

  async confirmation() {
    this.disableClose = true;
    this.isConfirming = true;
    
    this.model.buttonName = this.buttonName;
    const response = await this.pageCtrl.handleEventActionResult(this.dialog.eventAction.Id, this.model, this.dialog.button.label);
    if (response.success) {
      this.disableClose = false;
      this.close();
    } else {
      this.responseError = response.message || null;
      this.showResponseError = true;
    }

    this.isConfirming = false;
    this.disableClose = false;
  }

  updateModel(event) {
    this.model[event.target.name] = event.target.value;
    if (event.target.name === this.RESCHEDULE_START_DATE_TIME || event.target.name === this.RESCHEDULE_END_DATE_TIME) {
      this.isDateRangeValid();
    }
  }

  async isDateRangeValid() {
    const startDateTimeValue = this.model[this.RESCHEDULE_START_DATE_TIME];
    const endDateTimeValue = this.model[this.RESCHEDULE_END_DATE_TIME];

    const startDateTime = new Date(startDateTimeValue);
    const endDateTime = new Date(endDateTimeValue);
    if (startDateTime && endDateTime && startDateTime < endDateTime) {
      this.showEndTimeError = false;

      const response = await this.pageCtrl.eventActionSvc.rescheduleValidation(this.pageCtrl.id, this.model[this.RESCHEDULE_START_DATE_TIME]);
      if (response && response.data && response.data.length === 1) {
        const responseData = response.data[0];
        this.showConfigError = responseData.noConfigError;
        this.showBudgetWarning = responseData.budgetWarning;
        this.showChildWarning = responseData.childRescheduleWarning;
      }
    } else {
      this.showEndTimeError = true;
    }
  }

  setTimeZoneField(timeZoneInfo) {
    const timezone = this.record.fields[EmEventConstant.TIME_ZONE];
    if (timezone.value) {
      this.currentTimeZoneValue = timezone.value;
      this.currentTimeZoneDisplayValue = timezone.displayValue;
    } else {
      this.currentTimeZoneValue = timeZoneInfo?.defaultTimeZone;
    }
    if (timeZoneInfo?.timeZoneFieldMetadata) {
      this.timeZoneOptions = timeZoneInfo.timeZoneFieldMetadata.picklist;
      this.timeZoneFieldLabel = timeZoneInfo.timeZoneFieldMetadata.label;
      this.timeZoneFieldName = timeZoneInfo.timeZoneFieldMetadata.name;
      this.model.timeZone = this.currentTimeZoneValue;
      if(this.isTimeZoneReadOnly) {
        this.currentTimeZoneLabel = this.timeZoneOptions.find(e => e.value === this.currentTimeZoneValue)?.label;
        this.readOnlyTimeZoneCtrl = {
          label: this.timeZoneFieldLabel,
          displayValue: this.currentTimeZoneLabel
        }
      }
    }
  }

  addOrRemoveAlert(list, key, toAdd) {
    const idx = list.findIndex(alert => alert.key === key);
    if (idx >= 0 && !toAdd) {
      list.splice(idx, 1);
    } else if (idx < 0 && toAdd && this[key]) {
      const alert = {
        key,
        message: this[key],
      };
      list.push(alert);
    }
  }

  hasNonResponseErrors() {
    return this.errors.some(error => error.key !== 'responseError');
  }

  get record() {
    return this.dialog?.ctrl?.record || {};
  }

  get eventAction() {
    return this.dialog?.eventAction || {};
  }

  get buttonName() {
    return this.dialog?.button?.name || '';
  }

  get buttonLabel() {
    return this.dialog?.button?.label || '';
  }

  get isLocalDateTimeActive() {
    return this.pageCtrl?.isLocalDateTimeActive();
  }

  get currentStartTime() {
    if (this.isLocalDateTimeActive) {
      return `${this.record.rawValue(EmEventConstant.START_DATE)}T${this.record.rawValue(EmEventConstant.START_TIME_LOCAL)}`;
    }
    return this.record.rawValue(START_TIME.fieldApiName);
  }

  get currentEndTime() {
    if (this.isLocalDateTimeActive) {
      return `${this.record.rawValue(EmEventConstant.END_DATE)}T${this.record.rawValue(EmEventConstant.END_TIME_LOCAL)}`;
    }
    return this.record.rawValue(END_TIME.fieldApiName);
  }

  // UI conditionals
  get confirmationMessage() {
    return this.eventAction.Confirmation_Message_vod__c;
  }

  get startTimeLabel() {
    if(this.isLocalDateTimeActive) {
      return this.pageCtrl.startTimeLabel;
    }
    return this.pageCtrl.objectInfo.getFieldInfo([START_TIME.fieldApiName]).label;
  }

  get endTimeLabel() {
    if(this.isLocalDateTimeActive) {
      return this.pageCtrl.endTimeLabel;
    }
    return this.pageCtrl.objectInfo.getFieldInfo([END_TIME.fieldApiName]).label;
  }

  get isTimeZoneReadOnly() {
    return this.isLocalDateTimeActive && !this.pageCtrl?.objectInfo.getFieldInfo(EmEventConstant.TIME_ZONE)?.updateable;
  }

  get showTimeZonePicker() {
    return this.isLocalDateTimeActive && !this.isTimeZoneReadOnly;
  }

  get showComments() {
    return this.eventAction.Allow_Comments_vod__c;
  }

  get commentsLabel() {
    return this.eventHistoryDescribe?.fields[COMMENTS.fieldApiName].label;
  }

  // Warning and Errors
  set showChildWarning(value) {
    this.addOrRemoveAlert(this.warnings, 'rescheduleRelatedEvents', value);
  }

  set showBudgetWarning(value) {
    this.addOrRemoveAlert(this.warnings, 'budgetWarning', value);
  }

  set showConfigError(value) {
    this.addOrRemoveAlert(this.errors, 'noEventConfig', value);
  }

  set showEndTimeError(value) {
    this.addOrRemoveAlert(this.errors, 'endTimeError', value);
  }

  set showResponseError(value) {
    this.addOrRemoveAlert(this.errors, 'responseError', value);
  }

  get hasWarnings() {
    return this.warnings.length > 0;
  }

  get hasErrors() {
    return this.errors.length > 0;
  }

  get showSpinner() {
    return this.isLoading || this.isConfirming;
  }

  get disableButton() {
    return (
      this.isLoading || 
      this.hasNonResponseErrors() ||
      this.pageCtrl.page.requests.length > 0
    );
  }

  // styles
  get rescheduleInputClass() {
    let css = '';
    if (this.hasErrors) {
      css += 'slds-has-error';
    }
    return css;
  }
}