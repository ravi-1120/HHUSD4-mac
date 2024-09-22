@isTest
public class AppointmentSchedulerControllerTest {
    
    
    @isTest
    static void test_AppointmentController(){
        Date dt = Date.today();
        String scheduleString = '{"localHour":"23","localMinute":"0","schedulingGroup":"NE","Email":"hrushikesh.madugula@merck.com", "FirstName":"Hrushikesh", "LastName":"Hrushi", "Phone":"7396188273","Extension":"", "communicationMode":"Call me now", "dateLabel":"Friday, October 08", "dateValue":"2021-10-08","timeSlotValue":"23:0:0", "isCallMeNow":false, "localDateValue":"Fri Oct 08 2021 23:15:00 GMT+0530 (India Standard Time)", "localHour":"23","templateLabel": "Clinical study information","professionalDesignation":"MD","tumorIndication":"lungs",}';
        //Map<String,Object> schMap = (Map <String,Object> ) JSON.deserializeUntyped(scheduleString);
        Map<String,Object> schMap = TestDataFactory_MODTest.schedulerSaveResponseTest();
        Event evt = TestDataFactory_MODTest.testCreateEvent();
        Scheduler_Configuration__c sc = TestDataFactory_MODTest.testCreateSchedulerConfig();
        //EmailTemplate et = TestDataFactory_MODTest.testCreateEmailTemplate();
        List<Appointment_Template__c> appointments = TestDataFactory_MODTest.testCreateAppointments();
        //List<MenuWrapper> menuList = AppointmentSchedulerController.getAppointmentTypes();
        Test.startTest();
        AppointmentSchedulerController.getAppointmentDates(dt);
        Map<String,Object> testsave = AppointmentSchedulerController.saveAppointmentScheduleDetails(schMap);
        Map<String,Object> testsave1 =  AppointmentSchedulerController.saveAppointmentScheduleDetails(TestDataFactory_MODTest.schedulerSaveResponseTest1());
      //  AppointmentSchedulerController.formatDateTime('2021-10-08','23:0:0');
        AppointmentSchedulerController.sendEmailInvite(schMap,evt);
         AppointmentSchedulerController.sendEmailInvite(TestDataFactory_MODTest.schedulerSaveResponseTest1(),evt);
        AppointmentSchedulerController.getHCPDataStructurebyId(sc.Id,Date.Today());
        AppointmentSchedulerController.getHCPDataStructureAMO(Date.Today());
        AppointmentSchedulerController.getScheduledSlots('OREG',String.valueOf(Date.Today()));
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true)
    static void test_SendEmailInvite(){
        Test.startTest();
        AppointmentSchedulerController.sendEmailInvite(TestDataFactory_MODTest.schedulerSaveResponseTest(),TestDataFactory_MODTest.testCreateEvent());
        Test.stopTest();
    }
    
    @isTest
    static void test_monthVal(){
        Test.startTest();
        AppointmentSchedulerController.monthVal('Jan'); 
        AppointmentSchedulerController.monthVal('Feb'); 
        AppointmentSchedulerController.monthVal('Mar'); 
        AppointmentSchedulerController.monthVal('Apr'); 
        AppointmentSchedulerController.monthVal('May'); 
        AppointmentSchedulerController.monthVal('Jun'); 
        AppointmentSchedulerController.monthVal('Jul'); 
        AppointmentSchedulerController.monthVal('Aug'); 
        AppointmentSchedulerController.monthVal('Sep'); 
        AppointmentSchedulerController.monthVal('Oct'); 
        AppointmentSchedulerController.monthVal('Nov'); 
        AppointmentSchedulerController.monthVal('Dec'); 
        Test.stopTest();
    }
    
    @isTest
    public static void test_getAgentAvilability(){
        String scheduleString = JSON.serialize(TestDataFactory_MODTest.schedulerSaveResponseTest1()); 
        Map<String,Object> schMap = (Map <String,Object> ) JSON.deserializeUntyped(scheduleString);
        Test.setMock(HttpCalloutMock.class, new AgentAvailabilityMock());
        Test.startTest();
        NiceInContactController.getAgentAvilability(schMap);
        Test.stopTest();        
    }
    private class AgentAvailabilityMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            String response = '{"lastPollTime": "2020-10-28T18y23y18.047Z","skillActivity": [{"serverTime": "2020-10-28T18y21y20.000Z","businessUnitId": 4597972,"agentsACW": 0,"agentsAvailable": 0,"agentsIdle": 0,"agentsLoggedIn": 1,"agentsUnavailable": 1,"agentsWorking": 0,"campaignId": 2570145,"campaignName": "MVCC","contactsActive":0,"earliestQueueTime": null,"emailFromAddress": ""}]}';
            res.setBody(response);
            res.setStatusCode(200);
            return res;
        }
    }
    
    // -------------------------------------------
   
    private class ContactIdMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody('<body><div><span id="lblSpawn"><strong>Script spawned. Contact ID:129730144568</strong></span></div></form></body>');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    public static void test_callMeNowHttpRequest(){
        String scheduleString = JSON.serialize(TestDataFactory_MODTest.schedulerSaveResponseTest());
        Test.setMock(HttpCalloutMock.class, new ContactIdMock());
        Test.startTest();
        NiceInContactController.callMeNowHttpRequest(scheduleString,'1234');
        NiceInContactController.scheduleCallbackHttpRequest(scheduleString,'1234');
        Test.stopTest();        
    }

    
        @isTest
    static void testGetAppointmentTypes() {
        // Create test data
        List<Appointment_Template__c> templates = new List<Appointment_Template__c>();
        templates.add(new Appointment_Template__c(Name='Product Access: Coverage, Reimbursement, Coding, Billing', isActive__c=true, IsSchedulable__c=true, Template_Message__c='Please Contact Merck Access Program', Convey_Tumor__c=true));
        templates.add(new Appointment_Template__c(Name='Product Access', isActive__c=true, IsSchedulable__c=false, Template_Message__c='Please Contact Merck Access Program', Convey_Tumor__c=false));
        insert templates;

        // Call the method being tested
        Test.startTest();
      //  List<AppointmentSchedulerController.MenuWrapper> menuList = AppointmentSchedulerController.getAppointmentTypes();
        Test.stopTest();

        // Assert the results
    //    System.assertEquals(2, menuList.size());

     /*   AppointmentSchedulerController.MenuWrapper wrapper1 = menuList[0];
        Appointment_Template__c template1 = templates[0];
        System.assertEquals(template1.Id, wrapper1.value);
        System.assertEquals(template1.Name, wrapper1.label);
        System.assertEquals(template1.IsSchedulable__c, wrapper1.isSchedulable);
        System.assertEquals(template1.Template_Message__c, wrapper1.templateMessage);
        System.assertEquals(template1.Convey_Tumor__c, wrapper1.conveyTumor);
        System.assertEquals(1, wrapper1.order);

        AppointmentSchedulerController.MenuWrapper wrapper2 = menuList[1];
        Appointment_Template__c template2 = templates[1];
        System.assertEquals(template2.Id, wrapper2.value);
        System.assertEquals(template2.Name, wrapper2.label);
        System.assertEquals(template2.IsSchedulable__c, wrapper2.isSchedulable);
        System.assertEquals(template2.Template_Message__c, wrapper2.templateMessage);
        System.assertEquals(template2.Convey_Tumor__c, wrapper2.conveyTumor);
        System.assertEquals(5, wrapper2.order); */
    }
    
     @IsTest
    static void testGetHCPData() {
        // Test case 1: Test when href is null
        Date testDate1 = Date.today();
        Map<String, Object> result1 = AppointmentSchedulerController.getHCPData(null, testDate1);
        Map<String, Object> expected1 = AppointmentSchedulerController.getHCPDataStructureAMO(testDate1);
        System.assertEquals(expected1, result1, 'Test case 1 failed');

        // Test case 2: Test when href does not contain 'schedulerId='
        Date testDate2 = Date.newInstance(2022, 1, 1);
        Map<String, Object> result2 = AppointmentSchedulerController.getHCPData('https://example.com', testDate2);
        Map<String, Object> expected2 = AppointmentSchedulerController.getHCPDataStructurebyId('https://example.com', testDate2);
        System.assertEquals(expected2, result2, 'Test case 2 failed');

        // Test case 3: Test when href contains 'schedulerId='
        Date testDate3 = Date.newInstance(2023, 4, 5);
        Map<String, Object> result3 = AppointmentSchedulerController.getHCPData('https://example.com?schedulerId=123', testDate3);
        Map<String, Object> expected3 = AppointmentSchedulerController.getHCPDataStructurebyId('123', testDate3);
        System.assertEquals(expected3, result3, 'Test case 3 failed');
    }
    
}