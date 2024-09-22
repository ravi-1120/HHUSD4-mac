/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-03-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class PDS_DashboardControllerTest { 
    @isTest
    static void testGetRequestPage(){
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c(DATA_CHANGE_REQUEST_MODE_vod__c = 2);    
        insert vsc;
        Account acc = new Account(Name = 'Test Account', Territory_vod__c = '101', Enable_Restricted_Products_vod__c = true);
        insert acc;
        Contact con = new Contact(FirstName = 'Name', LastName = 'Last', AccountId = acc.Id);
        insert con;
        
        Profile pdsTaskforceProfile = [SELECT Id FROM Profile WHERE Name = 'PDS Taskforce' LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example1.com.test',
            Alias = 'tuser',
            ProfileId = pdsTaskforceProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = con.Id
        );
        insert testUser;

        User usr = [SELECT Id FROM User WHERE Id = :testUser.Id LIMIT 1];
        PDS_Program__c program = new PDS_Program__c(Name='MDP',PDS_Is_Active__c=true);
        insert program;
        PDS_Program_Access__c paccess = new PDS_Program_Access__c(PDS_Donee__c=acc.Id,PDS_Program__c=program.Id);
        insert paccess;
        Test.startTest();
        String result = PDS_DashboardController.getRequestPage(usr.Id);
        Test.stopTest();
    }
        @isTest
    static void testGetRequestPage2(){
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c(DATA_CHANGE_REQUEST_MODE_vod__c = 2);    
        insert vsc;
        Account acc = new Account(Name = 'Test Account', Territory_vod__c = '101', Enable_Restricted_Products_vod__c = true);
        insert acc;
        Contact con = new Contact(FirstName = 'Name', LastName = 'Last', AccountId = acc.Id);
        insert con;
        Profile pdsTaskforceProfile = [SELECT Id FROM Profile WHERE Name = 'PDS Taskforce' LIMIT 1];
    
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example2.com.test',
            Alias = 'tuser',
            ProfileId = pdsTaskforceProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = con.Id
        );
        insert testUser;

        User usr = [SELECT Id FROM User WHERE Id = :testUser.Id LIMIT 1];
        PDS_Program__c program = new PDS_Program__c(Name='MMOP',PDS_Is_Active__c=true);
        insert program;
        PDS_Program_Access__c paccess = new PDS_Program_Access__c(PDS_Donee__c=acc.Id,PDS_Program__c=program.Id);
        insert paccess;
        Test.startTest();
        String result = PDS_DashboardController.getRequestPage(usr.Id);
        Test.stopTest();
    }
        @isTest
    static void testGetRequestPage3(){
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c(DATA_CHANGE_REQUEST_MODE_vod__c = 2);    
        insert vsc;
        Account acc = new Account(Name = 'Test Account', Territory_vod__c = '101', Enable_Restricted_Products_vod__c = true);
        insert acc;
        Profile pdsTaskforceProfile = [SELECT Id FROM Profile LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example3.com.test',
            Alias = 'tuser',
            ProfileId = pdsTaskforceProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        User usr = [SELECT Id FROM User WHERE Id = :testUser.Id LIMIT 1];
        PDS_Program__c program = new PDS_Program__c(Name='MMOP',PDS_Is_Active__c=true);
        insert program;
        PDS_Program_Access__c paccess = new PDS_Program_Access__c(PDS_Donee__c=acc.Id,PDS_Program__c=program.Id);
        insert paccess;
        Test.startTest();
        String result = PDS_DashboardController.getRequestPage(usr.Id);
        Test.stopTest();
    }
    @isTest
    static void testgetRelatedDonationTypes(){
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c(DATA_CHANGE_REQUEST_MODE_vod__c = 2);    
        insert vsc;
        Account acc = new Account(Name = 'Test Account', Territory_vod__c = '101', Enable_Restricted_Products_vod__c = true);
        insert acc;

        User usr = [SELECT Id FROM User WHERE Profile.Name = 'PDS Taskforce' LIMIT 1];
        PDS_Proposal__c proposal = new PDS_Proposal__c(
            Name = 'Proposal 1',
            PDS_Donation_Type__c = 'Annual Allotment',
            PDS_Status__c = 'Submitted'
        );
        insert proposal;
        PDS_Proposal_Access__c access1 = new PDS_Proposal_Access__c(
            Donee__c = acc.Id,
            Proposal__c = proposal.Id
        );
        insert access1;
        Test.startTest();
		PDS_DashboardController.getRelatedDonationTypes(usr.Id);
        Test.stopTest();

    }
    @isTest
    static void testgetRelatedDonationTypes2() {
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c(DATA_CHANGE_REQUEST_MODE_vod__c = 2);    
        insert vsc;
        Account acc = new Account(Name = 'Test Account', Territory_vod__c = '101', Enable_Restricted_Products_vod__c = true);
        insert acc;
        Contact con = new Contact(FirstName = 'Name', LastName = 'Last', AccountId = acc.Id);
        insert con;
        Profile pdsTaskforceProfile = [SELECT Id FROM Profile WHERE Name = 'PDS Taskforce' LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example4.com.test',
            Alias = 'tuser',
            ProfileId = pdsTaskforceProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = con.Id
        );
        insert testUser;
        User usr = [SELECT Id FROM User WHERE Id = :testUser.Id LIMIT 1];

        PDS_Proposal__c proposal = new PDS_Proposal__c(
            Name = 'Proposal 1',
            PDS_Donation_Type__c = 'Annual Allotment',
            PDS_Status__c = 'Submitted'
        );
        insert proposal;
        PDS_Proposal_Access__c access1 = new PDS_Proposal_Access__c(
            Donee__c = acc.Id,
            Proposal__c = proposal.Id
        );
        insert access1;

        Test.startTest();
        PDS_DashboardController.getRelatedDonationTypes(usr.Id);
        Test.stopTest();
    }
    @isTest
    static void testGetRelatedProducts() {
        PDS_Product__c testProduct = new PDS_Product__c(
            Name = 'Test Product',
            PDS_Actual_Unit_Sale_Price__c = 100.00,
            PDS_NDC_Number__c = '123456789',
            PDS_Cold_Chain__c = true,
            PDS_SAP_Code__c = 'SAP123'
        );
        insert testProduct;
        
        PDS_Proposal__c testProposal = new PDS_Proposal__c(
            Name = 'Test Proposal',
            PDS_Donation_Type__c = 'Annual Allotment',
            PDS_Status__c = 'Submitted'
        );
        insert testProposal;
        PDS_Related_Product__c testRelatedProduct = new PDS_Related_Product__c(
            PDS_Proposal__c = testProposal.Id,
            PDS_Product__c = testProduct.Id,
            PDS_Available_Quantity__c = 10,
            PDS_Batch_Number__c = 'Batch123',
            PDS_Expiration_Date__c = Date.today().addMonths(12)
        );
        insert testRelatedProduct;
        Test.startTest();
        PDS_DashboardController.getRelatedProducts('Annual Allotment',testProposal.Id);
        Test.stopTest();
    }
   @isTest
    static void testCompare() {
        PDS_Proposal__c proposal = new PDS_Proposal__c(Name = 'Test Proposal', PDS_Donation_Type__c = 'Annual Allotment', PDS_Status__c = 'Submitted');
        insert proposal;
        
        PDS_Product__c prod1 = new PDS_Product__c(Name = 'Mectizan');
        PDS_Product__c prod2 = new PDS_Product__c(Name = 'Keytruda');
        PDS_Product__c prod3 = new PDS_Product__c(Name = 'Gardasil');
        
        insert new List<PDS_Product__c> {prod1, prod2, prod3};

        PDS_Related_Product__c relatedProduct1 = new PDS_Related_Product__c(PDS_Product__c = prod1.Id,PDS_Proposal__c = proposal.Id);
        PDS_Related_Product__c relatedProduct2 = new PDS_Related_Product__c(PDS_Product__c = prod2.Id,PDS_Proposal__c = proposal.Id);
        PDS_Related_Product__c relatedProduct3 = new PDS_Related_Product__c(PDS_Product__c = prod3.Id,PDS_Proposal__c = proposal.Id);
        
        insert new List<PDS_Related_Product__c> {relatedProduct1, relatedProduct2, relatedProduct3};
 
        relatedProduct1.PDS_Product__r = prod1;
        relatedProduct2.PDS_Product__r = prod2;
        relatedProduct3.PDS_Product__r = prod3;
        List<PDS_Related_Product__c> relatedProducts = new List<PDS_Related_Product__c> {relatedProduct3, relatedProduct1, relatedProduct2};
        relatedProducts.sort(new PDS_DashboardController.ComparatorProductName());
    }
    @isTest
    static void testGenerateProposalNotification() {
        // Create EmailProperties List
        List<PDS_DashboardController.EmailProperties> emailPropertiesList = new List<PDS_DashboardController.EmailProperties>();
        PDS_DashboardController.EmailProperties emailProps = new PDS_DashboardController.EmailProperties();
        emailProps.DonationType = 'Donation';
        emailProps.DoneeName = 'John Doe';
        emailProps.emailList = 'test1@example.com,test2@example.com';
        emailPropertiesList.add(emailProps);

        Test.startTest();
        PDS_DashboardController.generateProposalNotification(emailPropertiesList);
        Test.stopTest();
    }
}