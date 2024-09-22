/* 
 * Class: MSD_CORE_Events_Future_Calls_Util
 * 
 * This Class contains FUTURE methods used to offload heavy processing during Transactions 
 * 
 * Author: Kevin Brace
 * 
 * Change Log: 
 * KRB 6/11/2019 - Initial Version
*/

public class MSD_CORE_Events_Future_Calls_Util {

    @future
    public static void insertEMAttendee(id eventId, id teamMemberId, id recordTypeId) {
       EM_Attendee_vod__c attdee = new EM_Attendee_vod__c();
       attdee.Event_vod__c = eventId;
       attdee.User_vod__c = teamMemberId;
       attdee.RecordTypeId = recordTypeId;
        
       insert attdee;

    }
    
}