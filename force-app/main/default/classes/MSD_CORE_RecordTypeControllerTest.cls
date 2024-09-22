/*
* MSD_CORE_RecordTypeControllerTest
* Created By: Roman Lerman
* Created Date: September 11, 2015
* Description: This is the test class for the CaseRecordTypeControllerMVN 
*              and FulfillmentRecordTypeControllerMVN classes
*/
@isTest
private class MSD_CORE_RecordTypeControllerTest {
    static Account acct;
    static Case interaction;
    static Case request;
    static Case adverseEvent;
    static Case tempExcursion;

    static Fulfillment_MVN__c fulfillment;
    private static Service_Cloud_Settings_MVN__c settings;
    
    static{
        TestDataFactoryMVN.createSettings(true);

        settings = Service_Cloud_Settings_MVN__c.getInstance();
        
        interaction = TestDataFactoryMVN.createTestCase();
    }

    @isTest static void testCaseRecordTypeControllerForRequest(){       
        Test.startTest();
            request = TestDataFactoryMVN.createTestRequest(interaction);
            
            ApexPages.StandardController con = new ApexPages.StandardController(request);
            CaseRecordTypeControllerMVN extension = new CaseRecordTypeControllerMVN(con);
        Test.stopTest();

        String caseRecordTypeName = [select toLabel(RecordType.Name) from Case where Id = :request.Id].RecordType.Name;
        System.assertEquals(caseRecordTypeName, extension.recordTypeName);
    }

    @isTest static void testCaseRecordTypeControllerForAdverseEvent(){      
        Test.startTest();
            adverseEvent = TestDataFactoryMVN.createTestRequest(interaction);
            adverseEvent.RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Case' and DeveloperName = :settings.Adverse_Event_Record_Type_MVN__c].Id;
            update adverseEvent;
            
            ApexPages.StandardController con = new ApexPages.StandardController(adverseEvent);
            CaseRecordTypeControllerMVN extension = new CaseRecordTypeControllerMVN(con);
            
            extension.caseRecordTypeName = 'Combo Case';
            extension.updateRecordType();
            extension.saveCase();
        Test.stopTest();

        String caseRecordTypeName = [select toLabel(RecordType.Name) from Case where Id = :adverseEvent.Id].RecordType.Name;
        System.assertEquals(caseRecordTypeName, extension.caseRecordTypeName );
    }

    @isTest static void testCaseRecordTypeControllerForTempExcursion(){         
        Test.startTest();   
            tempExcursion = TestDataFactoryMVN.createTestRequest(interaction);
            tempExcursion.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.MSD_CORE_Temp_Excursion_Record_Type__c].Id;
            update tempExcursion;
            
            ApexPages.StandardController con = new ApexPages.StandardController(tempExcursion);
            CaseRecordTypeControllerMVN extension = new CaseRecordTypeControllerMVN(con);
        Test.stopTest();

        String caseRecordTypeName = [select toLabel(RecordType.Name) from Case where Id = :tempExcursion.Id].RecordType.Name;
        System.assertEquals(caseRecordTypeName, extension.recordTypeName);
    }

    @isTest static void testFulfillmentRecordTypeController(){              
        Test.startTest();
            fulfillment = TestDataFactoryMVN.createTestFulfillment(interaction.AccountId, interaction.Id);
            
            ApexPages.StandardController con = new ApexPages.StandardController(fulfillment);
            FulfillmentRecordTypeControllerMVN extension = new FulfillmentRecordTypeControllerMVN(con);
        Test.stopTest();

        String fulfillmentRecordTypeName = [select toLabel(RecordType.Name) from Fulfillment_MVN__c where Id = :fulfillment.Id].RecordType.Name;
        System.assertEquals(fulfillmentRecordTypeName, extension.recordTypeName);
    }
}