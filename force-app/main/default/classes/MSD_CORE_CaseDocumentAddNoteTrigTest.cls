/*
* MSD_CORE_CaseDocumentAddNoteTrigTest
* Created By:    Samuel Rosen
* Created Date:  5/20/2015
* Description:   This is a test class for the MSD_CORE_CaseDocumentAddNoteTrigger class
*/
@isTest
private class MSD_CORE_CaseDocumentAddNoteTrigTest {

    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Case pqc = new Case(); 
    
    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();
        pqc.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.Product_Complaint_Record_Type_MVN__c].Id; 
        insert pqc; 
    }

    @isTest static void addCaseDocumentWithoutQuestions() {
        Test.startTest();
            Case_Document_MVN__c cd = new Case_Document_MVN__c();
            cd.Case_MVN__c = pqc.Id;
            cd.Document_ID_MVN__c = '123456789876543212';
            insert cd; 
        Test.stopTest();

        List<MSD_CORE_Note__c> noteList = [SELECT Id FROM MSD_CORE_Note__c WHERE MSD_CORE_Case__c = :pqc.Id]; 
        System.assertEquals(0, noteList.size());
    }

    @isTest static void addCaseDocumentWithQuestions() {
        Test.startTest();
            Case_Document_MVN__c cd = new Case_Document_MVN__c();
            cd.MSD_CORE_Questions__c = 'question'; 
            cd.Case_MVN__c = pqc.Id;
            cd.Document_ID_MVN__c = '123456789876543212';
            insert cd; 
        Test.stopTest();

        List<MSD_CORE_Note__c> noteList = [SELECT Id, MSD_CORE_Note__c FROM MSD_CORE_Note__c WHERE MSD_CORE_Case__c = :pqc.Id]; 
        System.assertEquals(1, noteList.size());
        System.assertEquals('question', noteList[0].MSD_CORE_Note__c);
    }
}