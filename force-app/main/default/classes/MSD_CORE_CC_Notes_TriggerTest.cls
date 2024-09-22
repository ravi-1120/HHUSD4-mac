@isTest
public with sharing class MSD_CORE_CC_Notes_TriggerTest {

    @isTest
      public static void testNotesTrigger(){
       Account testAccount =  new Account();
    Case testCase = new Case();
    List<Case> testCaseList = new List<Case>();
          TestDataFactoryMVN.createSettings(true);
        testAccount = TestDataFactoryMVN.createTestHCP();
        
        testCase.AccountId = testAccount.Id;
        testCase.Type = 'General';
        testCase.Status = 'Open';
        testCase.Details_MVN__c = 'Test';
        testCase.case_AddressLine1_MVN__c = 'Address1';
        testCase.MSD_CORE_Customer_Contact_Salutation__c = 'Mr.';
        testCase.case_City_MVN__c = 'Herndon';
        testCase.case_Account_Phone_MVN__c = '5712689929'; 
        testCase.MSD_CORE_AE_Present__c = true;
        testCase.MSD_CORE_Preferred_Language__c = 'English'; 
        testCase.MSD_CORE_CR_Present__c = true;
        testCase.MSD_CORE_Notes__c = 'Test Notes';
        testCase.MSD_CORE_Preferred_Language__c = 'English';
        testCase.case_AddressLine1_MVN__c = 'Address1';
        testCase.case_AddressLine2_MVN__c = 'Address2';
        testCase.case_City_MVN__c = 'Ci';
        testCase.case_State_MVN__c = 'ST';
        testCase.case_Postal_Code_MVN__c = '5712689929';
        testCase.case_Country_MVN__c = 'City';
        testCase.RecordTypeId = TestDataFactoryMVN.interactionRecordTypeId;
        try{
            insert testCase;
        }catch(exception e){}
        
          test.startTest();
          try{
        MSD_CORE_Note__c note = new MSD_CORE_Note__c(); 
         note.MSD_CORE_Note__c = 'test';
         note.MSD_CORE_Case__c = testCase.Id;
        insert note;
          note.MSD_CORE_Note__c = 'test1';
          update note;
          }catch(exception e){}
          test.stopTest();
    }
}