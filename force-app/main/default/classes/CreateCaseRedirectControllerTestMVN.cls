/*
* CreateCaseRedirectControllerTestMVN
* Created By: Roman Lerman
* Created Date: 3/6/2013
* Description: Test class for CreateCaseRedirectControllerMVN
*/
@isTest
private class CreateCaseRedirectControllerTestMVN {
	static testMethod void testCreateCase(){
		TestDataFactoryMVN.createSettings(true);

		Case cs = new Case();

		ApexPages.StandardController con = new ApexPages.StandardController(cs);

        CreateCaseRedirectControllerMVN extension = new CreateCaseRedirectControllerMVN(con);

    	Test.startTest();
    		extension.getRedirect();
    	Test.stopTest();

        System.assertNotEquals(null, extension.newCase.Id);

        List<Case> newCases = [select Id, RecordType.DeveloperName from Case];

        Integer numInteractions = 0;
        Integer numRequests = 0;

        for(Case c : newCases) {
            if(c.RecordType.DeveloperName == Service_Cloud_Settings_MVN__c.getInstance().Interaction_Record_Type_MVN__c) {
                numInteractions++;
            } else if (c.RecordType.DeveloperName == Service_Cloud_Settings_MVN__c.getInstance().Request_Record_Type_MVN__c) {
                numRequests++;
            }
        }

        System.assertEquals(1, numInteractions);
    	System.assertEquals(0, numRequests);
	}

    static testMethod void testCreateCaseWithAccount(){
        TestDataFactoryMVN.createSettings(true);

        Case cs = new Case();

        Account testAccount = new Account();

        testAccount.RecordTypeId = [select Id from RecordType where SObjectType='Account' and DeveloperName='HCP' limit 1].Id;
        testAccount.FirstName = 'Test';
        testAccount.LastName = 'Account';

        insert testAccount;

        Campaign campaign = new Campaign();
        campaign.Name = 'Test Campaign';
        campaign.MSD_CORE_Product__c = TestDataFactoryMVN.createProduct('12345').Id;
        campaign.IsActive = true;
        insert campaign;

        MSD_CORE_Source__c source = new MSD_CORE_Source__c();
        source.Name = 'Test';
        source.MSD_CORE_External_Id__c = '12345678';
        source.MSD_CORE_Active__c = true;
        source.MSD_CORE_Campaign__c = campaign.Id;
        insert source;

        ApexPages.StandardController con = new ApexPages.StandardController(cs);

        ApexPages.currentPage().getParameters().put('def_account_id', testAccount.Id);
        ApexPages.currentPage().getParameters().put('interactionId', '5555555555');
        ApexPages.currentPage().getParameters().put('sourceId', '12345678');
        ApexPages.currentPage().getParameters().put('language', 'English');

        CreateCaseRedirectControllerMVN extension = new CreateCaseRedirectControllerMVN(con);

        Test.startTest();
            extension.getRedirect();
        Test.stopTest();

        System.assertNotEquals(null, extension.newCase.Id);

        System.assertEquals(testAccount.Id, extension.newCase.AccountId);

        Id contactId = [select ContactId from Case where Id = :extension.newCase.Id].ContactId;

        testAccount = [select Id, PersonContactId from Account where Id = :testAccount.Id];

        System.assertEquals(testAccount.PersonContactId, contactId);

        List<Case> newCases = [select Id, RecordType.DeveloperName, MSD_CORE_Preferred_Language__c, 
                                        MSD_CORE_Source__c, MSD_CORE_Campaign__c from Case];

        Integer numInteractions = 0;
        Integer numRequests = 0;

        for(Case c : newCases) {
            if(c.RecordType.DeveloperName == Service_Cloud_Settings_MVN__c.getInstance().Interaction_Record_Type_MVN__c) {
                numInteractions++;
            } else if (c.RecordType.DeveloperName == Service_Cloud_Settings_MVN__c.getInstance().Request_Record_Type_MVN__c) {
                numRequests++;
            }
        }

        System.assertEquals(1, numInteractions);
        System.assertEquals(0, numRequests);
        System.assertEquals(newCases[0].MSD_CORE_Preferred_Language__c, 'English');
        System.assertEquals(newCases[0].MSD_CORE_Source__c, source.Id);
        System.assertEquals(newCases[0].MSD_CORE_Campaign__c, campaign.Id);
    }

    static testMethod void testUnableToCreateCase(){
        TestDataFactoryMVN.createSettings(true);

        Test.setReadOnlyApplicationMode(true);
            Case cs = new Case();

            ApexPages.StandardController con = new ApexPages.StandardController(cs);

            CreateCaseRedirectControllerMVN extension = new CreateCaseRedirectControllerMVN(con);

            Test.startTest();
                extension.getRedirect();
            Test.stopTest();
        Test.setReadOnlyApplicationMode(false);

        System.assert(ApexPages.getMessages().size() == 1);
    }

    static testMethod void testInteractionIdNotProvided(){
        TestDataFactoryMVN.createSettings(true);

        Case cs = new Case();

        ApexPages.StandardController con = new ApexPages.StandardController(cs);

        ApexPages.currentPage().getParameters().put('interactionId', '0');

        CreateCaseRedirectControllerMVN extension = new CreateCaseRedirectControllerMVN(con);

        Test.startTest();
            extension.getRedirect();
        Test.stopTest();

        System.assertEquals(0, [select count() from Case]);
    }

    static testMethod void testRetrieveExistingCase(){
        TestDataFactoryMVN.createSettings(true);
        
        Case originalCase = new Case();
        originalCase.RecordTypeId = TestDataFactoryMVN.interactionRecordTypeId;
        originalCase.MSD_CORE_External_Id__c = '1111';
        insert originalCase;

        Case cs = new Case();

        ApexPages.StandardController con = new ApexPages.StandardController(cs);

        ApexPages.currentPage().getParameters().put('interactionId', '1111');

        CreateCaseRedirectControllerMVN extension = new CreateCaseRedirectControllerMVN(con);

        Test.startTest();
            extension.getRedirect();
        Test.stopTest();

        System.assertEquals(1, [select count() from Case]);
    }
}