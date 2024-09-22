import ATTENDEE_NAME from '@salesforce/schema/EM_Attendee_vod__c.Attendee_Name_vod__c';

import BaseWarningHandler from './baseWarningHandler';

export default class AttendeeWarningHandler extends BaseWarningHandler {
  get nameField() {
    return ATTENDEE_NAME.fieldApiName;
  }

  get header() {
    return this.messages.POTENTIAL_ATTENDANCE_WARNING_TITLE;
  }

  get subheader() {
    return this.messages.POTENTIAL_ATTENDANCE_WARNING_SUBTITLE;
  }
}