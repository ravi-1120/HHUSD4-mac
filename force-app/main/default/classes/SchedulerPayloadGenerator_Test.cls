@isTest
public with sharing class SchedulerPayloadGenerator_Test {
    @TestSetup
    static void setupData(){
        List<Appointment_Template__c> appointments = TestDataFactory_MODTest.testCreateAppointments();
        List<Holidays__c> holidays = TestDataFactory_MODTest.testCreateHolidays();
        List<Scheduling_Groups__c> groups = TestDataFactory_MODTest.testCreateGroups();
        Operating_Hours__c ohObj = TestDataFactory_MODTest.testCreateBusinessHours();
        Product_vod__c product =TestDataFactory_MODTest.testCreateProduct();
        MSD_CORE_Product_Payor__c product2 = TestDataFactory_MODTest.testCreateProduct2();


        for(Scheduling_Groups__c gObj : groups){
            gObj.Operating_Hours__c = ohObj.id;
        }
        update groups;
        List<Group_Holidays__c> groupHolidays = new List<Group_Holidays__c>();
        for(Scheduling_Groups__c g: groups){
            for(Holidays__c h: holidays){
                groupHolidays.add(
                    new Group_Holidays__c(
                        Holiday__c = h.id,
                        Scheduling_Group__c = g.id
                    )
                );
            }
        }
        insert groupHolidays;
    }
    @isTest static void TestTemplateController2(){
        Scheduler_Configuration__c scObj = new Scheduler_Configuration__c();
        scObj = TestDataFactory_MODTest.testCreateSchedulerConfig();
        List<Scheduler_Template__c> sList = TemplateController.getSchedulerTemplates(scObj.id);
        List<Appointment_Template__c> appointments = [Select Name, id from Appointment_Template__c];
        MSD_CORE_Product_Payor__c product = [select id from MSD_CORE_Product_Payor__c limit 1 ];
        List<Id> templateIds = new List<Id>();
        List<Scheduler_Template__c> stList = new List<Scheduler_Template__c>();
        List<Map<String,Object>> orderIdMap= new List<Map<String,Object>>();
        List<Map<String,Object>> productIds= new List<Map<String,Object>>();
        
        for(Appointment_Template__c aObj : appointments){
            stList.add(
                new Scheduler_Template__c(
                    Scheduler_Configuration__c = scObj.id,
                    Appointment_Template__c = aObj.id,
                    Order__c='1'
                )
            );
            templateIds.add(aObj.id);
                orderIdMap.add(new Map<String,Object>{'id'=>aObj.id,'order'=>'1','ProductPayorID'=>product.id});
        }
        insert stList;

        productIds.add(new Map<String,Object>{'order'=>'1','id'=>product.id});
        SchedulerPayloadGenerator.generateJSON(new Set<Id> {scObj.id},true);
        stList = TemplateController.createSchedulerTemplates(scObj.id, templateIds,orderIdMap,productIds);
        system.assert(stList.size() > 0, 'No Admin templates created');

        Appointment_Template__c att2 = TestDataFactory_MODTest.testCreateAppointmentTemplate();
        Scheduler_Template__c stt2 = new Scheduler_Template__c(Scheduler_Configuration__c = scObj.id, Appointment_Template__c = appointments[0].id, Order__c='2');
        insert stt2;
        stList = TemplateController.createSchedulerTemplates(scObj.id, templateIds,orderIdMap,productIds);
        system.assert(stList.size() > 0, 'No Admin templates created');
    }

    @isTest static void SchedulerPayloadGeneratorTest2(){
        Scheduler_Configuration__c scObj = new Scheduler_Configuration__c();
        scObj = TestDataFactory_MODTest.testCreateSchedulerConfig();
        List<Appointment_Template__c> appointments = [Select Name, id from Appointment_Template__c];
        MSD_CORE_Product_Payor__c product = [select id,MSD_CORE_Product_Catalog__c from MSD_CORE_Product_Payor__c limit 1 ];
        List<Id> templateIds = new List<Id>();
        List<Scheduler_Template__c> stList = new List<Scheduler_Template__c>();
        List<Map<String,Object>> orderIdMap= new List<Map<String,Object>>();
        
        for(Appointment_Template__c aObj : appointments){
            stList.add(
                new Scheduler_Template__c(
                    Scheduler_Configuration__c = scObj.id,
                    Appointment_Template__c = aObj.id,
                    Order__c='1'
                )
            );
            templateIds.add(aObj.id);
                orderIdMap.add(new Map<String,Object>{'id'=>aObj.id,'order'=>'1','ProductPayorID'=>product.id});
        }
        insert stList;

        Admin_Product__c admProd = new Admin_Product__c(Scheduler_Configuration__c=scObj.id,
                Product_Payor__c=product.Id,Order__c='1');
        insert admProd;

        Product_Template__c pTemp = new Product_Template__c(Product_Payor__c = product.Id, Appointment_Template__c = appointments[0].Id,Product_Catalog__c = product.MSD_CORE_Product_Catalog__c);
        insert pTemp;

        SchedulerPayloadGenerator.generateJSON(new Set<Id> {scObj.id},true);
        system.assert(stList.size() > 0, 'No Admin templates created');

        BusinessRulesController.getSelectedTemplates((String)scObj.Id);
    }

    @isTest static void TemplateControllerTest(){
        Scheduler_Configuration__c scObj = new Scheduler_Configuration__c(
            Name = 'Test MOOD App', 
            Communication_Channels__c = 'Call Me Now;Schedule a Callback'
        );
        insert scObj;
        TemplateController tObj = new TemplateController();
         TemplateController.getTemplates(scObj.id);

    }

    @isTest static void BusinessRulesControllerTest(){
        BusinessRulesController bcObj = new BusinessRulesController();
        system.assert(BusinessRulesController.getTemplatesMapping().size() > 0, 'No Templates mapping');
    }

    @isTest static void ScheduleRequestTest(){
        ScheduleRequest sObj = ScheduleRequest.createScheduleRequest();
        system.assert(sObj!=null, 'Object not created');
        sObj = ScheduleRequest.parse(System.JSON.serialize(sObj));
        system.assert(sObj!=null, 'Object not parased');
    }

    @isTest static void payloadGeneratorTest(){
        ScheduleRequest sObj = ScheduleRequest.createScheduleRequest();
        String cChannels = 'Call Me Now;Schedule a Callback';
        SchedulerPayloadGenerator.addChannels(sObj,cChannels);
        system.assert(sObj!=null, 'Object not created');

        Scheduler_Configuration__c sc = TestDataFactory_MODTest.testCreateSchedulerMapping();
        SchedulerPayloadGenerator.updateCommunicationChannels((String)sc.Id);
        system.assert(sc!=null, 'Object not created');
    }

    @isTest static void SchedulerControllerTest(){
        SchedulerController sObj = new SchedulerController();
        Scheduler_Configuration__c scObj = new Scheduler_Configuration__c(
            Name = 'Test MOOD App', 
            Communication_Channels__c = 'Call Me Now;Schedule a Callback'
        );
        insert scObj;

        List<Appointment_Template__c> appointments = [Select Name, id from Appointment_Template__c];
        List<Id> templateIds = new List<Id>();
        List<Scheduler_Template__c> stList = new List<Scheduler_Template__c>();
        for(Appointment_Template__c aObj : appointments){
            stList.add(
                new Scheduler_Template__c(
                    Scheduler_Configuration__c = scObj.id,
                    Appointment_Template__c = aObj.id
                )
            );
            templateIds.add(aObj.id);
        }
        insert stList;
        //System.assert(SchedulerController.getSchedulerLink(scObj.id, 'source') != null , 'No site available');
    }
    
    @isTest static void getHolidaysTest(){
       Group_Holidays__c gh = TestDataFactory_MODTest.testCreateGroupHolidays();
        List<Group_Holidays__c> testgetHolidays =  BusinessRulesController.getHolidays(String.valueOf(gh.Id));
        String testSaveHoliday = BusinessRulesController.saveHolidays('testholiday',String.valueOf(Date.today()),gh.Scheduling_Group__c);
        
        System.assert(String.isNotBlank(testSaveHoliday) , true);
    }
    
    @isTest static void addHolidaysByGroupTest(){
        Scheduler_Configuration__c sc = TestDataFactory_MODTest.testCreateSchedulerMapping();
        Group_Holidays__c gh =TestDataFactory_MODTest.testCreateGroupHolidays();
        BusinessRulesController.addHolidaysByGroup(sc.Id);
        System.assert(String.isNotBlank(sc.Name), true);
    }
    
    @isTest static void getCallRoutingTest(){
        Scheduler_Configuration__c sc = TestDataFactory_MODTest.testCreateSchedulerMapping();
        List<String> appointmentTemplates = new List<String> {'Clinical Study Information'};
        List<String> products = new List<String> {'Keytruda'};
        Test.setMock(HttpCalloutMock.class, new DecisionManagerMock());
        Test.startTest();
    	String routing = BusinessRulesController.getCallRouting(appointmentTemplates, products,sc.Id);
        System.assert(String.isNotBlank(routing), true);
        Test.stopTest();
    }
    
    
    private class DecisionManagerMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody('{"professionalDesignation":"MD"}');
            res.setStatusCode(200);
            return res;
        } 
    }
       
}