import EmController from 'c/emController';
import VeevaUtils from 'c/veevaUtils';
import ATTENDEE from '@salesforce/schema/EM_Event_Session_Attendee_vod__c.Attendee_vod__c';
import EVENT_SESSION from '@salesforce/schema/EM_Event_Session_Attendee_vod__c.Event_Session_vod__c';
import SPEAKER from '@salesforce/schema/EM_Event_Session_Attendee_vod__c.Speaker_vod__c';
import TEAM_MEMBER from '@salesforce/schema/EM_Event_Session_Attendee_vod__c.Team_Member_vod__c';
import SessionAttendeeReferenceController from './sessionAttendeeReferenceController';

export default class EmEventSessionAttendeeController extends EmController {
  get shouldShowFileUpload() {
    const lockedEventStatusValues = ['Canceled_vod', 'Closed_vod'];
    const eventSession = this.record.rawValue('Event_Session_vod__r');
    const event = eventSession?.fields?.Event_vod__r?.value;
    return !(event?.fields?.Lock_vod__c?.value || lockedEventStatusValues.includes(event?.fields?.Status_vod__c?.value));
  }

  async getEventId() {
    let eventId = null;
    if (this.record.rawValue(EVENT_SESSION.fieldApiName)) {
      const sessionRecord = await this.uiApi.getRecord(this.record.rawValue(EVENT_SESSION.fieldApiName), ['EM_Event_Session_vod__c.Event_vod__c']);
      eventId = sessionRecord?.fields.Event_vod__c?.value;
    }
    this._eventId = eventId;
    return eventId;
  }

  async getPleParams() {
    let params = {};

    if (!this.objectInfo.getFieldInfo(EVENT_SESSION.fieldApiName) || !this.record.rawValue(EVENT_SESSION.fieldApiName)) {
      return params;
    }

    if (this.action !== 'New') {
      const eventSession = this.record.rawValue('Event_Session_vod__r');
      const event = eventSession?.fields?.Event_vod__r?.value;
      params = this.populatePleParams(event);
    } else if (this.pleParamsInPageRef && Object.keys(this.pleParamsInPageRef).length > 0) {
      params = this.pleParamsInPageRef;
    } else if (this.record.rawValue(EVENT_SESSION.fieldApiName)) {
      const sessionRecord = await this.uiApi.getRecord(this.record.rawValue(EVENT_SESSION.fieldApiName), [
        'EM_Event_Session_vod__c.Event_vod__c',
        'EM_Event_Session_vod__c.Event_vod__r.Status_vod__c',
        'EM_Event_Session_vod__c.Event_vod__r.Country_vod__r.Alpha_2_Code_vod__c',
        'EM_Event_Session_vod__c.Event_vod__r.Event_Configuration_vod__c',
      ]);
      const event = VeevaUtils.lookupTraversal(sessionRecord)(['Event_vod__r']);
      params = this.populatePleParams(event);
    }
    return params;
  }

  getQueryFields() {
    let queryFields = super.getQueryFields();
    if (this.objectInfo.getFieldInfo(EVENT_SESSION.fieldApiName)) {
      queryFields = queryFields.concat([
        `${this.objectApiName}.Event_Session_vod__r.Event_vod__r.Status_vod__c`,
        `${this.objectApiName}.Event_Session_vod__r.Event_vod__r.Country_vod__r.Alpha_2_Code_vod__c`,
        `${this.objectApiName}.Event_Session_vod__r.Event_vod__r.Event_Configuration_vod__c`,
      ]);
    }
    return queryFields;
  }

  getOptionalQueryFields() {
    let queryFields = super.getOptionalQueryFields();
    if (this.objectInfo.getFieldInfo(EVENT_SESSION.fieldApiName)) {
      queryFields = queryFields.concat([`${this.objectApiName}.Event_Session_vod__r.Event_vod__r.Lock_vod__c`]);
    }
    return queryFields;
  }

  initItemController(meta, record) {
    const { field } = meta;
    if (field) {
      const fieldDescribe = this.objectInfo.getFieldInfo(field);
      if (field === ATTENDEE.fieldApiName || field === SPEAKER.fieldApiName || field === TEAM_MEMBER.fieldApiName) {
        return new SessionAttendeeReferenceController(meta, this, fieldDescribe, record);
      }
    }
    return super.initItemController(meta, record);
  }

  getPageRefForDelete() {
    if (this.eventId) {
      return {
        type: 'standard__recordPage',
        attributes: {
          recordId: this.eventId,
          objectApiName: 'EM_Event_vod__c',
          actionName: 'view',
        },
      };
    }
    return super.getPageRefForDelete();
  }

  initTemplate(ctrl) {
    if (ctrl.fieldApiName === EVENT_SESSION.fieldApiName && ctrl.displayValue) {
      ctrl.editable = false;
    }
    return super.initTemplate(ctrl);
  }

  getEmDefaultFieldValues() {
    const defVals = super.getEmDefaultFieldValues();
    if (this.record?.rawValue('Event_Session_vod__r')?.id) {
      defVals.Event_Session_vod__c = {
        value: this.record.rawValue('Event_Session_vod__r').id,
        displayValue: this.record.fields.Event_Session_vod__r.displayValue,
      };
    } else if (this.record?.rawValue(EVENT_SESSION.fieldApiName)) {
      defVals.Event_Session_vod__c = this.record.fields.Event_Session_vod__c;
    }
    return defVals;
  }
}