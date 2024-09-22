/**
 * Component Name:      MSD_CORE_RequestDetail_Controller
 * Created By:          Focal CXM
 * @description:        Server side controller for mSD_CORE_RequestDetail LWC component
 * Test Class:          MSD_CORE_RequestDetail_ControllerTest
 */
public without sharing class mSD_CORE_RequestDetail_Controller {
    /**
        * @description getmeetingreqdetails
        * @return String
        * @param requestid
    */
    @AuraEnabled(cacheable = true)
    public static Meeting_Request_vod__c getmeetingreqdetails(String requestid){
        try {
            Meeting_Request_vod__c meetinginfo = [SELECT ID, Name, MSD_CORE_Status__c, ScheduleFilter__c,MSD_CORE_Meeting_preference__c, MSD_CORE_Request_Resolution__c, Meeting_Type_vod__c, CreatedDate, MHEE_Name__c, Start_DateTime_vod__c, MSD_CORE_Request_Progress__c,Assignee_vod__r.FirstName,Assignee_vod__r.LastName,MSD_CORE_Completion_Date__c,
                                (SELECT ID, MSD_CORE_TimeSlot__c, MSD_CORE_Time_Slot__c, MSD_CORE_Selected__c, MSD_CORE_Meeting_Date__c, MSD_CORE_Duration__c FROM Meeting_Times__r) 
                                FROM Meeting_Request_vod__c WHERE ID =: requestid];
            return meetinginfo;
        } catch (Exception e) { System.debug(LoggingLevel.WARN, 'error ===> '+ e.getMessage()); return null;}
    }

    /**
        * @description cancelMeetingRequest
        * @return String
        * @param requestid, status
    */
    @AuraEnabled
    public static string cancelMeetingRequest(String requestid, String status){
        System.debug('#### status : '+status);
        String returnvalue = '';
        try {
            Meeting_Request_vod__c meetinginfo = [SELECT ID, Name, MSD_CORE_Status__c, MSD_CORE_Request_Resolution__c, MSD_CORE_Request_Progress__c
                                                  FROM Meeting_Request_vod__c WHERE ID =: requestid];
            System.debug('#### meetinginfo : '+meetinginfo.MSD_CORE_Status__c);
            if (status == 'Pending') {
                meetinginfo.MSD_CORE_Request_Progress__c = 'Request Submitted';
            } else if (status == 'Approved') {
                meetinginfo.MSD_CORE_Request_Progress__c = 'Appointment Scheduled';
            }
            meetinginfo.MSD_CORE_Status__c = 'Closed';
            meetinginfo.MSD_CORE_Request_Resolution__c = 'Request Cancelled';
            update meetinginfo;

            returnvalue = 'Meeting Request Cancelled Successfully';

        } catch (Exception e) { returnvalue = e.getMessage();}
        return returnvalue;
    }
}