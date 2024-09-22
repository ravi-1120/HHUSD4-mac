@isTest
private class ScheduleRequestTest{
    @isTest
    private static void createScheduleRequestTest(){
        Test.startTest();
        ScheduleRequest.createScheduleRequest();
        Test.stopTest();
    }
    @isTest
    private static void parseTest(){
        Test.startTest();
        String jsonString = '{"name": "Test Schedule Request", "id": "123", "uiCss": {"bgColor": "green", "fgColor": "green"}, "templates": [{"label": "Efficacy and trial information on FDA approved indications", "isSchedulable": true, "order": 1, "value": "template1", "templateMessage": "Sample template message", "conveyTumor": false}], "products": [{"label": "Efficacy and trial information on FDA approved indications", "order": 1, "value": "product1", "parentID": "catalog1", "inquiryTypes": ["type1"], "isBlackBox": false, "additionalInformation": "Additional info", "productAcessInquiry": {"header": "Header", "body": "Body", "footer": "Footer"}}], "communicationModes": [{"label": "Call Me Now", "value": "true", "message": "Sample message"}], "businessHours": [{"operatingHours": [{"startTime": "8:00 AM", "endTime": "8:00 PM", "weekName": "Monday"}], "operatingHoursMessage": "Operating hours message", "OutsideOperatingHoursMessage": "Outside hours message", "groupName": "Group 1", "groupId": "group1"}], "professionalDesignation": [{"label": "Designation 1", "value": "designation1", "order": 1}], "assignmentGroups": [{"groupName": "Group 1", "groupId": "group1", "professionalDesignation": ["designation1"], "appointmentTemplate": ["template1"], "routingGroup": [{"appointmentTemplate": "template1", "professionalDesignation": ["designation1"], "product": ["product1"]}], "businessHours": [{"startTime": "8:00 AM", "endTime": "8:00 PM", "weekName": "Monday"}]}], "holidaysByGroup": [{"groupName": "Group 1", "groupId": "group1", "holidays": ["holiday1"]}] }';
        ScheduleRequest.parse(jsonString);
        Test.stopTest();
    }
    @isTest
    private static void ScheduleRequestTest(){
        ScheduleRequest obj = new ScheduleRequest();
    }
    @isTest
    private static void UICssTest(){
        ScheduleRequest.UICss obj = new ScheduleRequest.UICss();
    }
    @isTest
    private static void TemplatesTest(){
        ScheduleRequest.Templates obj = new ScheduleRequest.Templates();
    }
    @isTest
    private static void ProductsTest(){
        ScheduleRequest.Products obj = new ScheduleRequest.Products();
    }
    @isTest
    private static void ProductAcessInquiryTest(){
        ScheduleRequest.ProductAcessInquiry obj = new ScheduleRequest.ProductAcessInquiry();
    }
    @isTest
    private static void CommunicateModesTest(){
        ScheduleRequest.CommunicateModes obj = new ScheduleRequest.CommunicateModes();
    }
    @isTest
    private static void OperatingHoursTest(){
        ScheduleRequest.OperatingHours obj = new ScheduleRequest.OperatingHours();
    }
    @isTest
    private static void BusinessHoursNewTest(){
        ScheduleRequest.BusinessHoursNew obj = new ScheduleRequest.BusinessHoursNew();
    }
    @isTest
    private static void BusinessHoursTest(){
        ScheduleRequest.BusinessHours obj = new ScheduleRequest.BusinessHours();
    }
    @isTest
    private static void AssignmentGroupsTest(){
        ScheduleRequest.AssignmentGroups obj = new ScheduleRequest.AssignmentGroups();
    }
    @isTest
    private static void ProfessionalDesignationTest(){
        ScheduleRequest.ProfessionalDesignation obj = new ScheduleRequest.ProfessionalDesignation();
    }
    @isTest
    private static void RoutingGroupTest(){
        ScheduleRequest.RoutingGroup obj = new ScheduleRequest.RoutingGroup();
    }
    @isTest
    private static void HolidaysByGroupTest(){
        ScheduleRequest.HolidaysByGroup obj = new ScheduleRequest.HolidaysByGroup();
    }
}