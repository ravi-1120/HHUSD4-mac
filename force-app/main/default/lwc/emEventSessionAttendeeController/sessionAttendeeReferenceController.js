import LookupDataReferenceController from 'c/lookupDataReferenceController';
import ATTENDEE_NAME from '@salesforce/schema/EM_Attendee_vod__c.Attendee_Name_vod__c';
import EVENT_SESSION from '@salesforce/schema/EM_Event_Session_Attendee_vod__c.Event_Session_vod__c';
import SPEAKER_NAME from '@salesforce/schema/EM_Event_Speaker_vod__c.Speaker_Name_vod__c';

const OBJECT_TO_NAME_FIELD = {
  EM_Attendee_vod__c: ATTENDEE_NAME.fieldApiName,
  EM_Event_Speaker_vod__c: SPEAKER_NAME.fieldApiName,
};

export default class SessionAttendeeReferenceController extends LookupDataReferenceController {
  getQueryParams(term) {
    const params = super.getQueryParams(term);
    params.id = this.data.rawValue(EVENT_SESSION.fieldApiName);
    return params;
  }

  toSearchRecord(record) {
    const result = super.toSearchRecord(record);
    result.name = result[OBJECT_TO_NAME_FIELD[this.targetSObject]] || result.name;
    return result;
  }
}