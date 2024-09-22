import EmEventConstant from 'c/emEventConstant';
import EmExpenseConstant from 'c/emExpenseConstant';
import { wire } from 'lwc';
import { fireEvent } from 'c/pubsub';
import { createMessageContext, publish } from 'lightning/messageService';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import STUB_SFDC_ID from '@salesforce/schema/EM_Event_vod__c.Stub_SFDC_Id_vod__c';
import EmBusRuleViolationsModal from 'c/emBusRuleViolationsModal';
import getEngageVMOC from '@salesforce/apex/EmEventController.getEngageVMOC';
import EmSubmitToCventModal from 'c/emSubmitToCventModal';
import EmRescheduleDialog from 'c/emRescheduleDialog';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import BaseButtonController from './baseButtonController';
import EventButtonService from '../services/eventButtonService';

const KEY_MESSAGE_CDN_FIELDS = ['CDN_Path_vod__c', 'Vault_GUID_vod__c', 'Status_vod__c', 'Vault_External_Id_vod__c'];
const CLM_PRESENTATION_CDN_FIELDS = ['Version_vod__c', 'Status_vod__c', 'Vault_External_Id_vod__c'];

export default class EventButtonController extends BaseButtonController {
  navigationHandlers = {
    Send_Email_vod: this.getSendEmailUrl,
    Record_a_Call_vod: this.getRecordACallUrl,
    View_Signatures_vod: this.getViewSignaturesUrl,
    Manage_Attendees_vod: this.getManageAttendeesHubUrl,
    Manage_Attendees_Hub_vod: this.getManageAttendeesHubUrl,
    Failed_Expense_vod: this.getExpenseHeaderPageRef,
  };

  clickHandlers = {
    Generate_Invitations_vod: this.openPrintTemplateDialog,
    Generate_Sign_In_vod: this.openPrintTemplateDialog,
    Attendee_Reconciliation_vod: this.attendeeReconcilation,
    Submit_to_Cvent_vod: this.openSubmitToCventModal,
    Preview_Event_QR_Code_vod: this.previewQRCode,
    Schedule_Engage_vod: this.scheduleEngageMeeting,
    Start_Webinar_vod: this.startEngageMeeting,
    Retry_Engage_vod: this.scheduleEngageMeeting,
    Failed_Expenses_vod: this.getFailedExpenseHeaders,
    default: this.eventAction,
  };

  get medEventId() {
    return this.pageCtrl.record.rawValue(STUB_SFDC_ID.fieldApiName);
  }
  objectApiNames = ['Key_Message_vod__c', 'Clm_Presentation_vod__c'];
  engageObjectInfos = {};

  @wire(getObjectInfos, { objectApiNames: '$objectApiNames' })
  wiredObjectInfos({ data }) {
    if (data) {
      this.engageObjectInfos = Object.fromEntries(data.results.filter(e => e.result.apiName).map(e => [e.result.apiName, e.result]));
    }
  }

  constructor(meta, pageCtrl) {
    super(meta, pageCtrl);
    this.messageContext = createMessageContext();
  }

  openPrintTemplateDialog() {
    const dialogMeta = {
      button: this.meta,
      dataSvc: this.pageCtrl.dataSvc,
      messageSvc: this.pageCtrl.messageSvc,
      recordTypeName: this.meta.name === 'Generate_Sign_In_vod' ? 'Print_Sign_In_Template_vod' : 'Print_Invitation_Template_vod',
    };
    fireEvent(this, EmEventConstant.DISPLAY_PRINT_TEMPLATE_DIALOG, dialogMeta);
  }

  attendeeReconcilation() {
    const payload = {
      key: EmEventConstant.ATTENDEE_RECONCILIATION,
      eventId: this.recordId,
    };
    publish(this.messageContext, eventsManagementChannel, payload);
  }

  async openSubmitToCventModal() {
    // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
    return EmSubmitToCventModal.open({
      label: this.meta.label,
      size: 'small',
      recordId: this.recordId,
    });
  }

  async previewQRCode() {
    const eventButtonSvc = new EventButtonService(this.pageCtrl.dataSvc);

    try {
      const response = await eventButtonSvc.getEventQRCode(this.recordId);

      if (response?.status !== -1 && response.data?.QrCode) {
        // convert base64 to blob
        const byteCharacters = window.atob(response.data.QrCode);
        const byteNumbers = new Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) {
          byteNumbers[i] = byteCharacters.charCodeAt(i);
        }
        const byteArray = new Uint8Array(byteNumbers);
        const file = new Blob([byteArray], { type: 'image/png' });

        // open image in new tab
        const a = document.createElement('a');
        a.href = window.URL.createObjectURL(file);
        a.target = '_blank';
        a.dispatchEvent(new MouseEvent('click'));
      }
    } catch (error) {
      // suppress errors
    }
  }

  async scheduleEngageMeeting() {
    const eventButtonSvc = new EventButtonService(this.pageCtrl.dataSvc);

    const postData = {
      Id: this.recordId,
      Event_Display_Name_vod__c: this.pageCtrl.record.rawValue('Event_Display_Name_vod__c') || this.pageCtrl.record.name,
      disableWebinar: false,
      meetingType: 'EVENT',
    };
    try {
      await eventButtonSvc.scheduleEngageMeeting(postData);
    } catch (error) {
      if (!error.data?.errorRecordedInObject) {
        throw error;
      }
    }

    getRecordNotifyChange([{ recordId: this.recordId }]);
  }

  async startEngageMeeting() {
    const engageUrl = await this.getEngageUrl(this.recordId);
    if (engageUrl) {
      window.open(engageUrl);
    }
  }

  async getEngageUrl(eventId) {
    const eventButtonSvc = new EventButtonService(this.pageCtrl.dataSvc);
    const vodInfo = await this.pageCtrl.dataSvc.sessionService.getVodInfo();
    const baseUrl = vodInfo.engageUrl;
    const path = '/h.html';
    const vExternalId = this.pageCtrl.getVExternalId();
    const queryParams = {
      j: vExternalId ?? eventId,
      i: vodInfo.userId,
      u: vodInfo.userName,
      t: vodInfo.sfSession,
      e: vodInfo.sfEndpoint,
      b: `${vodInfo.veevaServer}/${vodInfo.veevaVersion}`,
    };
    const engageVMOC = await getEngageVMOC();
    if (engageVMOC) {
      const sessionMinValid = parseInt(vodInfo.sessionSecondsValid, 10) / 60;
      queryParams.stl = sessionMinValid === 0 ? 1 : sessionMinValid;
      queryParams.msu = vodInfo.mcServer;
      queryParams.mcr = vodInfo.mcVersion;
    }
    const queryParamStr = Object.entries(queryParams)
      .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
      .join('&');
    let url = `${baseUrl}${path}?${queryParamStr}`;
    if (url && engageVMOC && this.hasKeyMessageCDNAndCLMPermission()) {
      const data = { meetingId: this.recordId };
      const response = await eventButtonSvc.startPackageCreation(data);
      url += `&jid=${encodeURIComponent(response.data.data.jobId)}`;
    }
    return url;
  }

  hasKeyMessageCDNAndCLMPermission() {
    return (
      KEY_MESSAGE_CDN_FIELDS.every(field => this.engageObjectInfos?.Key_Message_vod__c?.fields?.[field]?.isQueryable) &&
      CLM_PRESENTATION_CDN_FIELDS.every(field => this.engageObjectInfos?.Clm_Presentation_vod__c?.fields?.[field]?.isQueryable)
    );
  }

  getSendEmailUrl() {
    const queryParamsString = `&eventId=${this.recordId}`;
    return EventButtonController.constructVfpPageRef('Events_Management_Approved_Email_vod', { queryParams: queryParamsString });
  }

  getRecordACallUrl() {
    const queryParamsString = `id=${this.medEventId}&retUrl=/${this.recordId}&typ=Event`;
    return EventButtonController.constructVfpPageRef('Call_New_vod', {
      queryParams: queryParamsString ,
      EMEventId: `${this.recordId}`,
    });
  }

  getViewSignaturesUrl() {
    return EventButtonController.constructVfpPageRef('View_Event_Signatures_vod', { id: this.medEventId });
  }

  getManageAttendeesHubUrl() {
    return EventButtonController.constructVfpPageRef('EM_Attendee_Hub_vod', {
      retURL: `/${this.recordId}`,
      medEventId: this.medEventId,
      eventId: this.recordId,
      hideAddAttendee: '1',
    });
  }

  getExpenseHeaderPageRef() {
    return {
      type: 'standard__recordPage',
      attributes: {
        recordId: this.pageCtrl?.failedExpenses[0]?.Id,
        objectApiName: EmExpenseConstant.EXPENSE_HEADER,
        actionName: 'view',
      },
    };
  }

  getFailedExpenseHeaders() {
    publish(this.messageContext, eventsManagementChannel, { relatedListTab: EmExpenseConstant.EXPENSE_HEADER_RELATED });
  }

  async eventAction() {
    const response = await this.pageCtrl.eventActionSvc.getEventAction(this.recordId, this.meta.name);

    const busRuleErrors = [];
    const busRuleViolations = [];
    const eventOverrides = [];
    const eventActions = [];

    response.data.forEach(data => {
      if (data.businessRuleError) {
        busRuleErrors.push(data);
      } else if (data.EM_Business_Rule_vod__c) {
        busRuleViolations.push(data);
      } else if (data.Name?.startsWith('EO')) {
        eventOverrides.push(data);
      } else {
        eventActions.push(data);
      }
    });

    if (busRuleErrors.length) {
      throw new Error(busRuleErrors[0].businessRuleError.errorMessage);
    }

    if (busRuleViolations.length) {
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      const result = await EmBusRuleViolationsModal.open({
        violations: busRuleViolations,
        buttonName: this.meta.name,
        eventId: this.recordId,
        eventName: this.pageCtrl.record.name,
        label: this.meta.label,
        size: 'medium',
      });
      if (result !== 'success') {
        return;
      }
    }

    const eventAction = eventActions[0];

    const dialogMeta = { eventAction, button: this.meta, ctrl: this.pageCtrl };
    if (this.meta.name === 'Reschedule_vod') {
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      EmRescheduleDialog.open({
        size: 'small',
        dialog: dialogMeta,
      });
    } else if (EventButtonController.displayEventActionDialog(this.meta.name, eventAction)) {
      fireEvent(this, EmEventConstant.DISPLAY_EVENT_ACTION_DIALOG, dialogMeta);
    } else {
      const eventActionResponse = await this.pageCtrl.handleEventActionResult(eventAction.Id, {}, this.meta.label);
      if (eventActionResponse.requiredFieldMissing) {
        fireEvent(this, EmEventConstant.DISPLAY_EVENT_ACTION_DIALOG, {
          ...dialogMeta,
          requiredFieldMissing: eventActionResponse.requiredFieldMissing,
        });
      } else if (!eventActionResponse.success && eventActionResponse.message) {
        throw new Error(eventActionResponse.message);
      }
    }
  }

  static displayEventActionDialog(buttonName, eventAction) {
    // check event action and determine if we should show a dialog
    const actionType = eventAction.SFDC_Action_Type_vod__c;
    return (
      (!actionType && buttonName === 'Submit_for_Approval_vod') ||
      actionType === 'Submit_Manual_vod' ||
      eventAction.Allow_Comments_vod__c ||
      eventAction.Confirmation_Message_vod__c
    );
  }
}