/*
* MSD_CORE_ManageVeevaCaseTriggerTest
* Created By:    Roman Lerman
* Created Date:  8/24/2015
* Description:   This is the test class for the MSD_CORE_ManageVeevaCaseTrigger class
*/
@isTest
private class MSD_CORE_ManageVeevaCaseTriggerTest {
    private static Account testAccount;
    private static Case interaction;
    private static Case request;

	static {
		TestDataFactoryMVN.createSettings(true);
	}

    @isTest static void testCreateAVeevaCaseFromARequest() {
        testAccount = TestDataFactoryMVN.createTestHCP();
        interaction = TestDataFactoryMVN.createTestCase(testAccount.Id,[select PersonContactId from Account where Id = :testAccount.Id].PersonContactId);
        
        Test.startTest();
            request = TestDataFactoryMVN.createTestRequest(interaction);
        Test.stopTest();

        request = [select Id, CaseNumber, AccountId from Case where Id = :request.Id];

        MSD_CORE_Veeva_Case__c veevaCase = [select MSD_CORE_External_ID__c, MSD_CORE_Case_Number__c, MSD_CORE_Customer__c
        										from MSD_CORE_Veeva_Case__c
        										where MSD_CORE_External_ID__c = :request.Id limit 1];

    	System.assertEquals(request.Id, veevaCase.MSD_CORE_External_ID__c);
    	System.assertEquals(request.CaseNumber, veevaCase.MSD_CORE_Case_Number__c);
    	System.assertEquals(request.AccountId, veevaCase.MSD_CORE_Customer__c);
    }

    @isTest static void testCreateAConsumerVeevaCaseFromARequest() {
        testAccount = TestDataFactoryMVN.createTestPersonAccount();
        interaction = TestDataFactoryMVN.createTestCase(testAccount.Id,[select PersonContactId from Account where Id = :testAccount.Id].PersonContactId);
        
        Test.startTest();
            request = TestDataFactoryMVN.createTestRequest(interaction);
        Test.stopTest();

        request = [select Id, CaseNumber, AccountId from Case where Id = :request.Id];

        MSD_CORE_Veeva_Case__c veevaCase = [select MSD_CORE_External_ID__c, MSD_CORE_Case_Number__c, MSD_CORE_Customer__c
        										from MSD_CORE_Veeva_Case__c
        										where MSD_CORE_External_ID__c = :request.Id limit 1];

    	System.assertEquals(request.Id, veevaCase.MSD_CORE_External_ID__c);
    	System.assertEquals(request.CaseNumber, veevaCase.MSD_CORE_Case_Number__c);
    	System.assertEquals(request.AccountId, veevaCase.MSD_CORE_Customer__c);
    }

    @isTest static void testRemoveAVeevaCaseWhenRequestIsCancelled() {
        testAccount = TestDataFactoryMVN.createTestHCP();
        interaction = TestDataFactoryMVN.createTestCase(testAccount.Id,[select PersonContactId from Account where Id = :testAccount.Id].PersonContactId);
        
        Test.startTest();
            request = TestDataFactoryMVN.createTestRequest(interaction);
        Test.stopTest();
    	
    	System.assertEquals(1, [select count() from MSD_CORE_Veeva_Case__c]);

    	request.Status = 'Cancelled';

    	update request;

    	System.assertEquals(0, [select count() from MSD_CORE_Veeva_Case__c]);
    }
}