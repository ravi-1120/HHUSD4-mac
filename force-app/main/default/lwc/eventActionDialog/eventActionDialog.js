import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import EmNextApproverController from 'c/emNextApproverController';
import EmEventConstant from 'c/emEventConstant';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { VeevaMessageRequest } from 'c/veevaMessageService';
import EM_EVENT from '@salesforce/schema/EM_Event_vod__c';
import EM_EVENT_HISTORY from '@salesforce/schema/EM_Event_History_vod__c';
import COMMENTS from '@salesforce/schema/EM_Event_History_vod__c.Comment_vod__c';
import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class EventActionDialog extends LightningElement {
  @api objectApiName;
  @api recordId;

  @wire(getObjectInfo, { objectApiName: EM_EVENT_HISTORY })
  eventHistoryDescribe;

  @track model = {};
  @track display = false;
  @track warnings = [];
  @track errors = [];
  @track timeZoneOptions = [];
  timeZoneLabel;
  currentTimeZoneValue;
  currentTimeZoneLabel;
  userTimeZone = TIME_ZONE;

  dialog = {};
  approverCtrl = {};

  isConfirming = false;
  approverRequired = false;

  APPROVER_ID = EmEventConstant.APPROVER_ID;
  MESSAGES = {
    nextApproverLabel: {
      key: 'NEXT_APPROVER',
      category: 'EVENT_MANAGEMENT',
      defaultMessage: 'Next Approver',
    },
    approverRequiredLabel: {
      key: 'APPROVER_REQUIRED',
      category: 'EVENT_MANAGEMENT',
      defaultMessage: 'Please select an approver to continue',
    },
    cancelRelatedEvents: {
      key: 'CANCEL_RELATED_EVENTS',
      category: 'EVENT_MANAGEMENT',
      defaultMessage: 'All future events in this series will also be canceled',
    },
  };

  connectedCallback() {
    registerListener(EmEventConstant.DISPLAY_EVENT_ACTION_DIALOG, this.displayDialog, this);
    this.getMessages();
  }

  async getMessages() {
    const messageService = getService(SERVICES.MESSAGE);
    const messageRequest = new VeevaMessageRequest();

    Object.entries(this.MESSAGES).forEach(([label, { key, category, defaultMessage }]) => {
      messageRequest.addRequest(key, category, defaultMessage, label);
    });

    const messageMap = await messageService.getMessageMap(messageRequest);

    Object.entries(messageMap).forEach(([label, message]) => {
      this[label] = message;
    });
  }

  disconnectedCallback() {
    unregisterAllListeners(this);
  }

  async displayDialog(meta) {
    this.dialog = meta;
    this.model.eventActionId = meta.eventAction.Id;
    this.pageCtrl = meta.ctrl;

    // reset warnings/errors
    this.showResponseError = false;
    this.approverRequired = Boolean(this.dialog.requiredFieldMissing);
    this.showApproverWarning = this.approverRequired;
    this.showCancelWarning = this.eventAction.Ending_Status_vod__c === 'Canceled_vod' && this.eventAction.hasChildEvents;

    this.approverCtrl = this.nextApproverCtrl();

    this.display = true;
  }

  closeModal() {
    const prevComment = this.model.comment;
    this.model = {};
    if (prevComment) {
      // keep comment
      this.model.comment = prevComment;
    }
    this.display = false;
  }

  async confirmation() {
    this.isConfirming = true;

    this.model.buttonName = this.buttonName;
    const response = await this.pageCtrl.handleEventActionResult(this.dialog.eventAction.Id, this.model, this.dialog.button.label);
    if (response.success) {
      this.model = {};
      this.display = false;
    } else {
      this.responseError = response.message || null;
      this.showResponseError = true;
      this.approverRequired = Boolean(response.requiredFieldMissing);
      this.showApproverWarning = this.approverRequired;
    }

    this.isConfirming = false;
  }

  updateModel(event) {
    this.model[event.target.name] = event.target.value;
  }

  nextApproverCtrl() {
    const meta = {
      required: true,
      editable: true,
      label: this.nextApproverLabel,
      objectList: this.eventAction.objectPicklist || [],
    };

    return new EmNextApproverController(EM_EVENT.objectApiName, meta, this.pageCtrl, this.model);
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

  // UI conditionals
  get confirmationMessage() {
    return this.eventAction.Confirmation_Message_vod__c;
  }

  get showApproverLookup() {
    const actionType = this.eventAction.SFDC_Action_Type_vod__c;
    return (!actionType && this.buttonName === 'Submit_for_Approval_vod') || actionType === 'Submit_Manual_vod' || this.approverRequired;
  }

  get showComments() {
    return this.eventAction.Allow_Comments_vod__c;
  }

  get commentsLabel() {
    return this.eventHistoryDescribe.data?.fields[COMMENTS.fieldApiName].label;
  }

  // Warning and Errors
  set showApproverWarning(value) {
    this.addOrRemoveAlert(this.warnings, 'approverRequiredLabel', value);
  }

  set showCancelWarning(value) {
    this.addOrRemoveAlert(this.warnings, 'cancelRelatedEvents', value);
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

  get disableButton() {
    return (
      this.hasNonResponseErrors() ||
      (this.showApproverLookup && !this.model[EmEventConstant.APPROVER_ID]) || // empty approver lookup
      this.pageCtrl.page.requests.length > 0
    );
  }
}