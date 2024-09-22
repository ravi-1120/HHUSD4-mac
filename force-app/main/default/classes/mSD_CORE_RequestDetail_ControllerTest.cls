/**
 * Component Name:      mSD_CORE_RequestDetail_ControllerTest
 * Created By:          Focal CXM
 * @description:        Test class of mSD_CORE_RequestDetail_Controller
 */

@isTest
public class mSD_CORE_RequestDetail_ControllerTest {

    /**
     * @description: Cover GetMeetingReqDetails method
     * @return; void
    */
    @isTest
    static void testGetMeetingReqDetails() {
        // Create a test meeting request record
        Meeting_Request_vod__c meetingReq = new Meeting_Request_vod__c(
            MSD_CORE_Status__c = 'Closed',
            ScheduleFilter__c = 'Filter',
            MSD_CORE_Meeting_preference__c = 'In-Person',
            MSD_CORE_Request_Resolution__c = 'Request Cancelled',
            Start_DateTime_vod__c = Date.today()
        );
        insert meetingReq;

        MSD_CORE_Meeting_Time__c meettime = new MSD_CORE_Meeting_Time__c(
            MSD_CORE_Meeting_Request__c = meetingReq.Id,
            MSD_CORE_Time_Slot__c = '10 AM to 12 PM',
            MSD_CORE_Selected__c = true,
            MSD_CORE_Meeting_Date__c = Date.today(),
            MSD_CORE_Duration__c = 60
        );
    
        insert meettime;

        // Call the getmeetingreqdetails method
        Meeting_Request_vod__c result = mSD_CORE_RequestDetail_Controller.getmeetingreqdetails(meetingReq.Id);

        // Verify that the meeting request record was returned
        System.assertEquals(meetingReq.Id, result.Id);
        System.assertEquals(meetingReq.MSD_CORE_Status__c, result.MSD_CORE_Status__c);
        System.assertEquals(meetingReq.ScheduleFilter__c, result.ScheduleFilter__c);
        System.assertEquals(meetingReq.MSD_CORE_Meeting_preference__c, result.MSD_CORE_Meeting_preference__c);
        System.assertEquals(meetingReq.Start_DateTime_vod__c, result.Start_DateTime_vod__c);
    }

    /**
     * @description: Cover CancelMeetingRequest method
     * @return; void
    */
    @isTest
    static void testCancelMeetingRequest() {
        // Create a test meeting request record
        Meeting_Request_vod__c meetingReq = new Meeting_Request_vod__c(
            MSD_CORE_Status__c = 'Closed',
            MSD_CORE_Request_Progress__c = 'Request Submitted',
            MSD_CORE_Request_Resolution__c = 'Request Cancelled'
        );
        insert meetingReq;

        // Call the CancelMeetingRequest method
        String result = mSD_CORE_RequestDetail_Controller.CancelMeetingRequest(meetingReq.Id, 'Pending');

        // Verify that the meeting request record was updated and the method returned the expected value
        meetingReq = [SELECT MSD_CORE_Status__c, MSD_CORE_Request_Progress__c, MSD_CORE_Request_Resolution__c FROM Meeting_Request_vod__c WHERE Id = :meetingReq.Id];
        System.assertEquals('Closed', meetingReq.MSD_CORE_Status__c);
        System.assertEquals('Request Submitted', meetingReq.MSD_CORE_Request_Progress__c);
        System.assertEquals('Meeting Request Cancelled Successfully', result);
    }
}