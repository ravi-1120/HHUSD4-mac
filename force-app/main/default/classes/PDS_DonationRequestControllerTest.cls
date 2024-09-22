@isTest
public class PDS_DonationRequestControllerTest {
    
    @isTest
    static void testSubmitDonationRequest() {
        // Setup test data
        String recordTypeName = 'MMOP';
        String productId;
        String doneeId;
        
        RecordType donationRequestRecordType = new RecordType(
            SObjectType = 'PDS_Donation_Request__c',
            DeveloperName = recordTypeName,
            Name = recordTypeName
        );
        
        RecordType lineItemRecordType = new RecordType(
            SObjectType = 'PDS_Product_Line_Item__c',
            DeveloperName = recordTypeName,
            Name = recordTypeName
        );
        
        User reviewer = [SELECT Id, Username FROM User WHERE IsActive = true LIMIT 1];
        User approver = [SELECT Id, Username FROM User WHERE IsActive = true LIMIT 1];
        
        PDS_Product__c product = new PDS_Product__c(
            Name = 'Test Product',
            PDS_Actual_Product_Cost__c = 100,
            PDS_Actual_Unit_Sale_Price__c = 120
        );
        insert product;
        productId = product.Id;
        
        PDS_Donation_Request__c testDonationRequest = new PDS_Donation_Request__c(
            PDS_Donation_Request_Status__c = 'Reviewed'
        );
        insert testDonationRequest;
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c(DATA_CHANGE_REQUEST_MODE_vod__c = 2);    
        insert vsc;
        
        Account donee = new Account(Name = 'Test Account', Territory_vod__c = '101', Enable_Restricted_Products_vod__c = true);
        insert donee;
        doneeId = donee.Id;
        
        PDS_Contact__c con  = new PDS_Contact__c(Name = 'ContactTest');
        insert con;
        
        PDS_Program__c program = new PDS_Program__c(Name ='MMOP');
        insert program;
        
        PDS_Proposal__c proposal = new PDS_Proposal__c(Name = 'Annual Allotment',PDS_Program__c = program.Id,PDS_Donation_Type__c='Annual Allotment');
        insert proposal;
        
        String requestString = '{"donationReqId":"'+testDonationRequest.Id+'",  "recordTypeName": "' + recordTypeName + '", "reviewer": "' + reviewer.Id + '", "approver": "' + approver.Id + '", "doneeId": "' + doneeId + '", "applicationNumber": "APP-001", "applicantName": "Applicant Name", "donationType": "Annual Allotment", "addInfoValue": "Additional Info", "requestStatus": "Reviewed", "shippingStatus": "Pending", "destinationValue": "Domestic", "poNumber": "PO-1234", "applicantIns": "Institution1", "taxValue": "Yes", "indicationValue": "ONCHOCERCIASIS", "consignee": "' + con.Id + '", "finalRecipient": "' + con.Id + '", "fwdAgent": "Agent1", "requestSubmitDate": "2023-01-01", "approvalDate": "2023-02-01", "shipNotify": "' + con.Id + '", "totalValue": 1000, "minExpDate": "6 months", "updateNotify": "Update1", "proposalId": "'+proposal.Id+'", "productLineItems": [{"productId": "' + productId + '", "tabletsReq": 100, "country": "India", "localPartner": "Partner1", "actualproductPrice": 100, "actualSalePrice": 120, "expDate": "2023-12-31", "batchNumber": "Batch1"}], "proposalDocument": "proposalDoc", "approvalLetter": "approvalLetter"}';
        
        Test.startTest();
        PDS_DonationRequestController.DonationRequestWrapper result;
        try {
            result = PDS_DonationRequestController.submitDonationRequest(requestString);
            System.debug('result::' + result);
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        PDS_Donation_Request__c insertedDonation = new PDS_Donation_Request__c();
        try{
            insertedDonation = [SELECT Id, RecordTypeId, PDS_Donee__c, PDS_Application_Number__c, PDS_Applicant_Name__c, 
                                PDS_Donation_Type__c, PDS_Additional_Information__c, PDS_Donation_Request_Status__c, 
                                PDS_Shipping_Status__c, PDS_Destination__c, PDS_PO_Number__c, PDS_Reviewer__c, 
                                PDS_Approver__c, PDS_Requestor__c, PDS_Applicant_Institution__c, PDS_Tax_Report_Inclusion__c, 
                                PDS_Indication__c, PDS_Consignee__c, PDS_Final_Recipient__c, PDS_Forwarding_Agent__c, 
                                PDS_Program__c, PDS_Request_Submit_Date__c, PDS_Approval_Date__c, PDS_Ship_Notify__c, 
                                PDS_Total_Donation_Value__c, PDS_Minimum_Expiration_Dating__c, PDS_Update_Summary__c, 
                                PDS_Proposal__c 
                                FROM PDS_Donation_Request__c WHERE Id = :testDonationRequest.Id];
        } catch(Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
        
        
        PDS_Product_Line_Item__c insertedLineItem = new PDS_Product_Line_Item__c();
        try{
            insertedLineItem = [SELECT Id, PDS_Donation_Request__c, PDS_Shipping_Status__c, PDS_Product__c, PDS_Country__c, 
                                PDS_Local_Partner__c, PDS_Actual_Product_Cost__c, PDS_Actual_Unit_Sale_Price__c, 
                                PDS_Quantity_Requested__c, PDS_Expiration_Date__c, PDS_Batch_Number__c 
                                FROM PDS_Product_Line_Item__c WHERE PDS_Donation_Request__c = :insertedDonation.Id LIMIT 1]; 
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        
        
    }
    
    @isTest
    static void testSubmitDonationRequestWithErrors() {
        Profile pdsTaskforceProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example369Green.com.test',
            Alias = 'tuser',
            ProfileId = pdsTaskforceProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        User usr = [SELECT Id FROM User WHERE Id = :testUser.Id LIMIT 1];
        
        PDS_Contact__c con  = new PDS_Contact__c(Name = 'ContactN');
        insert con;
        
        Date today = (DATE)System.today();
        String requestString = '{"recordTypeName":"MDP","reviewer":"testuser@example.com.test","approver":"testuser@example.com.test","donationReqId":"","doneeId":"","applicationNumber":"","applicantName":"","donationType":"","addInfoValue":"","requestStatus":"","shippingStatus":"","destinationValue":"","poNumber":"","applicantIns":"","taxValue":"no","indicationValue":"","consignee":"'+con.id+'","finalRecipient":"'+con.id+'","fwdAgent":"","requestSubmitDate":"'+con.id+'","approvalDate":"invalid-date","shipNotify":"'+con.id+'","totalValue":10000.0,"minExpDate":"","updateNotify":"","proposalId":"","productLineItems":[{"tabletsReq":100,"productId":"invalid-product-id","country":"Invalid Country","localPartner":"Invalid Partner","actualproductPrice":50.0,"actualSalePrice":45.0,"lineItemId":"","expDate":"invalid-date","batchNumber":"Invalid Batch"}]}';
        Test.startTest();
        PDS_DonationRequestController.DonationRequestWrapper result;
        try {
            result = PDS_DonationRequestController.submitDonationRequest(requestString);
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.debug('Expected AuraHandledException: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('Unexpected Exception: ' + e.getMessage());
            System.assert(false, 'Unexpected Exception was thrown: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testDonationRequestWrapper() {
        PDS_Donation_Request__c testDonationRequest = new PDS_Donation_Request__c(
            PDS_Donation_Request_Status__c = 'Reviewed'
        );
        insert testDonationRequest;
        
        PDS_Product__c testProduct = new PDS_Product__c(
            Name = 'Keytruda'
        );
        insert testProduct;
        
        List<Id> testProductLineItemIds = new List<Id>();
        List<PDS_Product_Line_Item__c> productLineItems = new List<PDS_Product_Line_Item__c>();
        for (Integer i = 0; i < 3; i++) {
            PDS_Product_Line_Item__c testProductLineItem = new PDS_Product_Line_Item__c(
                PDS_Local_Partner__c = 'Test Product Line Item ' + i,
                PDS_Product__c	= testProduct.Id,
                PDS_Donation_Request__c = testDonationRequest.Id
                
            );
            productLineItems.add(testProductLineItem);
        }
        insert productLineItems;
        for (PDS_Product_Line_Item__c item : productLineItems) {
            testProductLineItemIds.add(item.Id);
        }
        
        Map<Id, List<Id>> testProductToLineItemsMap = new Map<Id, List<Id>>();
        for (Id productLineItemId : testProductLineItemIds) {
            testProductToLineItemsMap.put(productLineItemId, new List<Id>{ productLineItemId });
        }
        
        PDS_DonationRequestController.DonationRequestWrapper wrapper = new PDS_DonationRequestController.DonationRequestWrapper(
            testDonationRequest,
            testProductLineItemIds,
            testProductToLineItemsMap
        );
        
        
        System.assertEquals(testDonationRequest.Id, wrapper.donationRequest.Id, 'Donation Request ID should match');
        System.assertEquals(testProductLineItemIds.size(), wrapper.productLineItemIds.size(), 'Product Line Item IDs size should match');
        
        for (Id id : testProductLineItemIds) {
            System.assert(wrapper.productLineItemIds.contains(id), 'Product Line Item IDs should contain ' + id);
        }
        
        System.assertEquals(testProductToLineItemsMap.size(), wrapper.productToLineItemsMap.size(), 'Product to Line Items map size should match');
        
        for (Id key : testProductToLineItemsMap.keySet()) {
            System.assert(wrapper.productToLineItemsMap.containsKey(key), 'Product to Line Items map should contain key ' + key);
            System.assertEquals(testProductToLineItemsMap.get(key).size(), wrapper.productToLineItemsMap.get(key).size(), 'Product to Line Items map values size should match');
            for (Id lineItemId : testProductToLineItemsMap.get(key)) {
                System.assert(wrapper.productToLineItemsMap.get(key).contains(lineItemId), 'Product to Line Items map should contain line item ID ' + lineItemId);
            }
        }
    }
    
    @IsTest
    static void testGetProductDetails() {
        PDS_Product__c activeProduct = new PDS_Product__c(
            Name = 'Active Product',
            PDS_Is_Active__c = true,
            PDS_Product_Size__c = 'Large'
        );
        insert activeProduct;
        
        PDS_Product__c inactiveProduct = new PDS_Product__c(
            Name = 'Inactive Product',
            PDS_Is_Active__c = false,
            PDS_Product_Size__c = 'Small'
        );
        insert inactiveProduct;
        
        Test.startTest();
        List<Map<String, String>> results = PDS_DonationRequestController.getProductDetails(activeProduct.Id);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'There should be one active product returned');
        Map<String, String> result = results[0];
        System.assertEquals(activeProduct.Id, result.get('value'), 'Product ID should match');
        System.assertEquals(activeProduct.Name + ' - ' + activeProduct.PDS_Product_Size__c, result.get('label'), 'Product label should match');
    }  
    
    @IsTest
    static void testGetDoneeOptions() {
        PDS_Program__c testProgram = new PDS_Program__c(
            Name = 'Test Program'
        );
        insert testProgram;
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c(DATA_CHANGE_REQUEST_MODE_vod__c = 2);    
        insert vsc;
        
        Account activeDonee = new Account(Name = 'Test Account', Territory_vod__c = '101', Enable_Restricted_Products_vod__c = true);
        insert activeDonee;
        
        PDS_Program_Access__c activeProgramAccess = new PDS_Program_Access__c(
            PDS_Donee__c = activeDonee.Id,
            PDS_Program__c = testProgram.Id,
            PDS_Is_Active__c = true
        );
        insert activeProgramAccess;
        
        Test.startTest();
        List<Map<String, String>> results = PDS_DonationRequestController.getDoneeOptions('Test Program');
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'There should be one active donee returned');
        Map<String, String> result = results[0];
        System.assertEquals(activeDonee.Id, result.get('value'), 'Donee ID should match');
        System.assertEquals(activeDonee.Name, result.get('label'), 'Donee name should match');  
    }
    
    @isTest
    static void testParseDate() {
        
        String dateString1 = '12/31/2023';
        Date expectedDate1 = Date.newInstance(2023, 12, 31);
        Date parsedDate1 = PDS_DonationRequestController.parseDate(dateString1);
        System.assertEquals(expectedDate1, parsedDate1, 'The parsed date should match the expected date in MM/DD/YYYY format');
        
        String dateString2 = '2023-12-31';
        Date expectedDate2 = Date.newInstance(2023, 12, 31);
        Date parsedDate2 = PDS_DonationRequestController.parseDate(dateString2);
        System.assertEquals(expectedDate2, parsedDate2, 'The parsed date should match the expected date in YYYY-MM-DD format');
        
        String invalidDateString = 'invalid-date';
        Date parsedInvalidDate = PDS_DonationRequestController.parseDate(invalidDateString);
        System.assertEquals(null, parsedInvalidDate, 'The parsed date for an invalid date string should be null');
    }
    
    @isTest
    static void testGetAccountName() {
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c(DATA_CHANGE_REQUEST_MODE_vod__c = 2);    
        insert vsc;
        
        Account businessAccount = new Account(Name = 'Test Account', Territory_vod__c = '101', Enable_Restricted_Products_vod__c = true);
        insert businessAccount;
        
        String businessAccountName = PDS_DonationRequestController.getAccountName(businessAccount.Id);
        
    }
    
    @isTest
    static void testGetDonationRequestDetails() {
        
        PDS_Donation_Request__c donationRequest = new PDS_Donation_Request__c(
            PDS_Destination__c = 'Domestic',
            PDS_Tax_Report_Inclusion__c = true,
            PDS_Application_Number__c = '123456',
            PDS_Applicant_Name__c = 'Test Applicant',
            PDS_Applicant_Institution__c = 'Test Institution',
            PDS_Approval_Date__c = Date.today(),
            PDS_Forwarding_Agent__c = 'Test Agent',
            PDS_Additional_Information__c = 'Test Information',
            PDS_Request_Submit_Date__c = Date.today(),
            PDS_Donation_Request_Status__c = 'Approved',
            PDS_Shipping_Status__c = 'Pending'
        );
        insert donationRequest;
        
        PDS_Product__c product = new PDS_Product__c(
            Name = 'Mectizan'
        );
        insert product;
        
        PDS_Product_Line_Item__c productLineItem1 = new PDS_Product_Line_Item__c(
            PDS_Donation_Request__c = donationRequest.Id,
            PDS_Product__c = product.Id,
            PDS_Quantity_Requested__c = 10,
            PDS_Local_Partner__c = 'Local Partner 1',
            PDS_Country__c = 'India',
            PDS_Shipping_Status__c = 'Pending',
            PDS_Tablets_Requested__c = 100,
            PDS_Batch_Number__c = 'Batch001',
            PDS_Expiration_Date__c = Date.today().addMonths(12),
            PDS_Actual_Unit_Sale_Price__c = 10,
            PDS_Actual_Product_Cost__c = 8
        );
        insert productLineItem1;
        
        PW_Robot_User__c rob = new PW_Robot_User__c();
        rob.Name = 'RobotUserSetting';
        rob.External_ID__c = 'MSD-000001';
        rob.Robot_User__c = 'testuser@merck.com.invalid';
        insert rob;
        
        ContentVersion version1 = new ContentVersion(
            Title = 'Approval Letter',
            PathOnClient = 'Approval Letter.pdf',
            VersionData = Blob.valueOf('Test content for Application Document')
        );
        insert version1;
        
        List<ContentDocument> documents = [SELECT Id, Title, FileExtension, LatestPublishedVersionId FROM ContentDocument Where LatestPublishedVersionId =:version1.Id];
        
        ContentDocumentLink contentDocumentLinks1 = new ContentDocumentLink();
        contentDocumentLinks1.LinkedEntityId = donationRequest.Id;
        contentDocumentLinks1.ContentDocumentId = documents[0].Id;
        insert contentDocumentLinks1;
        
        
        Test.startTest();
        PDSDonationRequest result = PDS_DonationRequestController.getDonationRequestDetails(donationRequest.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetDonationRequestDetails2() {
        
        PDS_Donation_Request__c donationRequest = new PDS_Donation_Request__c(
            PDS_Destination__c = 'Domestic',
            PDS_Tax_Report_Inclusion__c = true,
            PDS_Application_Number__c = '123456',
            PDS_Applicant_Name__c = 'Test Applicant',
            PDS_Applicant_Institution__c = 'Test Institution',
            PDS_Approval_Date__c = Date.today(),
            PDS_Forwarding_Agent__c = 'Test Agent',
            PDS_Additional_Information__c = 'Test Information',
            PDS_Request_Submit_Date__c = Date.today(),
            PDS_Donation_Request_Status__c = 'Approved',
            PDS_Shipping_Status__c = 'Pending'
        );
        insert donationRequest;
        
        PDS_Product__c product = new PDS_Product__c(
            Name = 'Mectizan'
        );
        insert product;
        
        PDS_Product_Line_Item__c productLineItem1 = new PDS_Product_Line_Item__c(
            PDS_Donation_Request__c = donationRequest.Id,
            PDS_Product__c = product.Id,
            PDS_Quantity_Requested__c = 10,
            PDS_Local_Partner__c = 'Local Partner 1',
            PDS_Country__c = 'India',
            PDS_Shipping_Status__c = 'Pending',
            PDS_Tablets_Requested__c = 100,
            PDS_Batch_Number__c = 'Batch001',
            PDS_Expiration_Date__c = Date.today().addMonths(12),
            PDS_Actual_Unit_Sale_Price__c = 10,
            PDS_Actual_Product_Cost__c = 8
        );
        insert productLineItem1;
        
        PW_Robot_User__c rob = new PW_Robot_User__c();
        rob.Name = 'RobotUserSetting';
        rob.External_ID__c = 'MSD-000001';
        rob.Robot_User__c = 'testuser@merck.com.invalid';
        insert rob;
        
        ContentVersion version1 = new ContentVersion(
            Title = 'Approval Letter',
            PathOnClient = 'Approval Letter.pdf',
            VersionData = Blob.valueOf('Test content for Application Document')
        );
        insert version1;
        
        List<ContentDocument> documents = [SELECT Id, Title, FileExtension, LatestPublishedVersionId FROM ContentDocument Where LatestPublishedVersionId =:version1.Id];
        
        ContentDocumentLink contentDocumentLinks1 = new ContentDocumentLink();
        contentDocumentLinks1.LinkedEntityId = donationRequest.Id;
        contentDocumentLinks1.ContentDocumentId = documents[0].Id;
        insert contentDocumentLinks1;
        Test.startTest();
        try {
            PDSDonationRequest resultInvalid = PDS_DonationRequestController.getDonationRequestDetails('invalidId');
            System.assert(false, 'Exception should have been thrown for invalid Id');
        } catch (Exception e) {
            System.assertEquals('Invalid id: invalidId', e.getMessage(), 'Exception message should indicate invalid Id');
        }
        Test.stopTest();
        
    }  
    
    @isTest
    static void testProcessApproval() {
        
        User user = [SELECT Id, Username FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(user) {
            
            Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c(DATA_CHANGE_REQUEST_MODE_vod__c = 2);
            insert vsc;
            
            Account testAccount = new Account(Name = 'Test Account', Territory_vod__c = '101', Enable_Restricted_Products_vod__c = true);
            insert testAccount;
            
            PDS_Donation_Request__c testDonationRequest = new PDS_Donation_Request__c(
                PDS_Donation_Request_Status__c = 'Reviewed'
            );
            insert testDonationRequest;
            
            ProcessInstanceWorkitem workitem = new ProcessInstanceWorkitem(
                ProcessInstanceId = testAccount.Id,
                ActorId = user.Id,
                OriginalActorId = user.Id,
                ProcessInstance = new ProcessInstance(
                    TargetObjectId = testAccount.Id,
                    Status = 'Pending'
                )
            );
            
            PDS_Application_Setting__mdt setting = new PDS_Application_Setting__mdt(
                DeveloperName = 'MDP_Flow_Settings',
                PDS_OrgWideEmailAddress__c = 'orgwide@example.com'
            );
            
            OrgWideEmailAddress owea = new OrgWideEmailAddress(
                Address = 'orgwide@example.com',
                DisplayName = 'Org Wide Email'
            );
            
            MEDs_Approval_Mapping__mdt mapping = new MEDs_Approval_Mapping__mdt(
                Username__c = user.Username,
                Email_Service_Address__c = 'approver@example.com'
            );
            
            Test.startTest();
            String result = PDS_DonationRequestController.processApproval('approve', testAccount.Id);
            Test.stopTest();
            
            
        }
    }
    
    @isTest
    static void testProcessApprovalReject() {
        PDS_Donation_Request__c testDonationRequest = new PDS_Donation_Request__c(
            PDS_Donation_Request_Status__c = 'Reviewed'
        );
        insert testDonationRequest;
        
        String recordId = testDonationRequest.Id;
        String status = 'reject';
        
        Test.startTest();
        String result = PDS_DonationRequestController.processApproval(status, recordId);
        Test.stopTest();
    }
    
    @isTest
    static void testProcessApprovalInvalidStatus() {
        PDS_Donation_Request__c testDonationRequest = new PDS_Donation_Request__c(
            PDS_Donation_Request_Status__c = 'Reviewed'
        );
        insert testDonationRequest;
        String recordId = testDonationRequest.Id;
        String status = 'invalid';
        
        try {
            Test.startTest();
            PDS_DonationRequestController.processApproval(status, recordId);
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    /*  @isTest
static void testSubmitDonationRequest2() {        
Account acc = new Account(Name = 'Test Account', Territory_vod__c = '101', Enable_Restricted_Products_vod__c = true);
insert acc;
PDS_Donation_Request__c req = new PDS_Donation_Request__c(Name='M-1021',PDS_Donation_Request_Status__c = 'Reviewed');
insert req;
Profile pdsTaskforceProfile = [SELECT Id FROM Profile WHERE Name = 'PDS Taskforce' LIMIT 1];

User testUser = new User(
FirstName = 'Test',
LastName = 'User',
Email = 'testuser@example.com',
Username = 'testuser@example.com.test',
Alias = 'tuser',
ProfileId = pdsTaskforceProfile.Id,
TimeZoneSidKey = 'America/Los_Angeles',
LocaleSidKey = 'en_US',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US'
);
insert testUser;
User usr = [SELECT Id FROM User WHERE Id = :testUser.Id LIMIT 1];
// Query for an existing Record Type or use a default one
RecordType donationRequestRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'PDS_Donation_Request__c' LIMIT 1];
RecordType productLineItemRecordType = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'PDS_Product_Line_Item__c' LIMIT 1];
PDS_Contact__c con  = new PDS_Contact__c(Name = 'ContactN');
insert con;
// Create related data
PDS_Program__c program = new PDS_Program__c(Name = 'TestProgram');
insert program;
PDS_Proposal__c proposal = new PDS_Proposal__c(Name = 'Proposal');
insert proposal;

PDS_Product__c product = new PDS_Product__c(Name = 'TestProduct', PDS_Actual_Product_Cost__c = 100, PDS_Actual_Unit_Sale_Price__c = 150);
insert product;

// Create a JSON string to simulate the input to the submitDonationRequest method
String requestString = '{"recordTypeName":"' + donationRequestRecordType.Name + '","reviewer":"standarduser@test.com","approver":"standarduser@test.com","donationReqId":"'+req.Id+'","doneeId":"'+acc.Id+'","applicationNumber":"12345","applicantName":"Test Applicant","donationType":"Annual Allotment","addInfoValue":"Additional Info","requestStatus":"Reviewed","shippingStatus":"Pending","destinationValue":"Domestic","poNumber":"PO12345","applicantIns":"Test Institution","taxValue":"yes","indicationValue":"Test Indication","consignee":"'+con.id+'","finalRecipient":"'+con.id+'","fwdAgent":"Test Agent","requestSubmitDate":"2023-01-01","approvalDate":"2023-01-01","shipNotify":"'+con.Id+'","totalValue":1000,"minExpDate":"2024-01-01","updateNotify":"Update Summary","proposalId":"'+proposal.Id+'","productLineItems":[{"tabletsReq":100,"productId":"' + product.Id + '","country":"India","localPartner":"Local Partner","actualproductPrice":100.0,"actualSalePrice":150.0}]}';

// Call the method to test
Test.startTest();
PDS_DonationRequestController.DonationRequestWrapper result = PDS_DonationRequestController.submitDonationRequest(requestString);
Test.stopTest();
}*/
    @isTest
    static void testProcessApprovalSuccess() {
        // Create a user
        Profile p = [Select Id from Profile Limit 1];
        User usr = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'user1@merck.com',
            Username = 'user1@merck.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert usr;
        
        // Create a donation request
        PDS_Donation_Request__c donationRequest = new PDS_Donation_Request__c(
            Name = 'Test Donation Request',
            PDS_Request_Submit_Date__c = Date.today(),
            PDS_Donation_Request_Status__c = 'Reviewed',
            PDS_Reviewer__c = usr.Id,
            PDS_Approver__c = usr.Id
        );
        insert donationRequest;
        
        Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
        submitRequest.setComments('Submitting request for approval');
        submitRequest.setObjectId(donationRequest.Id);
        Approval.ProcessResult submitResult = Approval.process(submitRequest);
        
        String workItemId = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :donationRequest.Id LIMIT 1].Id;
        
        Test.startTest();
        String result = PDS_DonationRequestController.processApproval('approve', donationRequest.Id);
        Test.stopTest();
    }
    @isTest
    static void testProcessApprovalReject2() {
        // Create a user
        Profile p = [Select Id from Profile Limit 1];
        User usr = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'user1@merck.com',
            Username = 'user1@merck.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert usr;
        
        // Create a donation request
        PDS_Donation_Request__c donationRequest = new PDS_Donation_Request__c(
            Name = 'Test Donation Request',
            PDS_Request_Submit_Date__c = Date.today(),
            PDS_Donation_Request_Status__c = 'Reviewed',
            PDS_Reviewer__c = usr.Id,
            PDS_Approver__c = usr.Id
        );
        insert donationRequest;
        
        Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
        submitRequest.setComments('Submitting request for approval');
        submitRequest.setObjectId(donationRequest.Id);
        Approval.ProcessResult submitResult = Approval.process(submitRequest);
        
        String workItemId = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :donationRequest.Id LIMIT 1].Id;
        List<MEDs_Approval_Mapping__mdt> mappingRecord = [SELECT Username__c, Email_Service_Address__c FROM MEDs_Approval_Mapping__mdt WHERE Username__c = :usr.Username LIMIT 1];
        PDS_Application_Setting__mdt[] pdsSettings = [select id,PDS_OrgWideEmailAddress__c,DeveloperName from PDS_Application_Setting__mdt where DeveloperName='MDP_Flow_Settings'];
        String orgwideadd = pdsSettings[0].PDS_OrgWideEmailAddress__c;
        OrgWideEmailAddress[] owea = [Select Id from OrgWideEmailAddress where Address =:orgwideadd];

        Test.startTest();
        String result = PDS_DonationRequestController.processApproval('reject', donationRequest.Id);
        Test.stopTest();
    }
    
}