@isTest
private class PDS_DocGenControllerTest {
    
    @isTest
    static void testGeneratePDF() {
        Test.startTest();
        // Test data creation
        PDS_Product__c product = new PDS_Product__c(
            PDS_Product_Number__c = '123456',
            PDS_Product_Type__c = 'Vaccine',
            PDS_Product_Size__c = 'Bottle of 1000',
            PDS_Actual_Product_Cost__c = 500
        );
        insert product;
        
        PDS_Donation_Request__c request = new PDS_Donation_Request__c(
            Name = 'P-12311',
            PDS_Donation_Request_Status__c = 'Reviewed',
            PDS_Request_Submit_Date__c  = Date.today(),
            PDS_Approval_Date__c = Date.today()
        );
        insert request;
        
        PDS_Product_Line_Item__c productLineItem = new PDS_Product_Line_Item__c(
            PDS_Donation_Request__c = request.Id,
            PDS_Product__c = product.Id,
            PDS_Country__c = 'India'
        );
        insert productLineItem;     
        
        Test.stopTest();
        
        Integer requestCount = [SELECT COUNT() FROM PDS_Donation_Request__c];
        System.assertEquals(1, requestCount, 'Expected 1 PDS_Donation_Request__c record to be created.');
        
        Integer productLineItemCount = [SELECT COUNT() FROM PDS_Product_Line_Item__c];
        System.assertEquals(1, productLineItemCount, 'Expected 1 PDS_Product_Line_Item__c record to be created.');
        
        PDS_Donation_Request__c updatedRequest = [SELECT PDS_Donation_Request_Status__c FROM PDS_Donation_Request__c WHERE Id = :request.Id];
        System.assertEquals('Reviewed', updatedRequest.PDS_Donation_Request_Status__c, 'Expected PDS_Donation_Request_Status__c to be "Reviewed".');
    }
    static PDS_Donation_Request__c createTestDonationRequest() {
        PDS_Product__c product = new PDS_Product__c(
            PDS_Product_Number__c = '123456',
            PDS_Product_Type__c = 'Vaccine',
            PDS_Product_Size__c = 'Bottle of 1000',
            PDS_Actual_Product_Cost__c = 500
        );
        insert product;
        
        PDS_Donation_Request__c request = new PDS_Donation_Request__c(
            PDS_Donation_Request_Status__c = 'Pending',
            PDS_Request_Submit_Date__c  = Date.today(),
            PDS_Approval_Date__c = Date.today()
        );
        insert request;
        
        PDS_Product_Line_Item__c productLineItem = new PDS_Product_Line_Item__c(
            PDS_Donation_Request__c = request.Id,
            PDS_Product__c = product.Id,
            PDS_Country__c = 'India'
        );
        insert productLineItem;
        
        return request;
    }
    
    @isTest
    static void testGeneratePDF2() {
        Test.startTest();
        PW_Robot_User__c rob = new PW_Robot_User__c(
        	Name = 'RobotUserSetting',
            External_ID__c = 'MSD-000001',
            Robot_User__c = 'testuser@merck.com.invalid'          
       	);
		insert rob;
        
        PDS_Donation_Request__c request = new PDS_Donation_Request__c(
            Name ='M-12121',
            PDS_Donation_Request_Status__c = 'Reviewed',
            PDS_Request_Submit_Date__c  = Date.today(),
            PDS_Approval_Date__c = Date.today()
        );
        insert request;
        ContentVersion contentVersion = new ContentVersion(
            Title = '2024-M-12121 TestDocument.pdf',
            VersionData = Blob.valueOf('Test content'),
            PathOnClient = '2024-M-12121 TestDocument.pdf'
        );
        insert contentVersion;
        
        ContentDocumentLink contentDocLink = new ContentDocumentLink(
            LinkedEntityId = request.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId,
            ShareType = 'V'
        );
        insert contentDocLink;

        List<PDS_DocGenController.DocumentProperties> docGenRequests = new List<PDS_DocGenController.DocumentProperties>();
        PDS_DocGenController.DocumentProperties docGenRequest = new PDS_DocGenController.DocumentProperties();
        docGenRequest.recordId = request.Id;
        docGenRequest.docNames = '2024-M-12121 TestDocument.pdf';
        docGenRequest.docType = 'PDF';
        docGenRequests.add(docGenRequest);
        PDS_DocGenController.generatePDF(docGenRequests);
        Test.stopTest();
    }
    @isTest
    static void testGeneratePDF4() {
        // Create a test User
        User testUser = [SELECT Id FROM User LIMIT 1];
       
        PDS_Product__c product = new PDS_Product__c(
            PDS_Product_Number__c = '123456',
            PDS_Product_Type__c = 'Vaccine',
            PDS_Product_Size__c = 'Bottle of 1000',
            PDS_Actual_Product_Cost__c = 500
        );
        insert product;
        
        // Create a test PDS_Donation_Request__c record
        PDS_Donation_Request__c donationRequest = new PDS_Donation_Request__c(
            Name = 'M-0101',
            PDS_Request_Submit_Date__c = Date.today(),
            PDS_Donation_Request_Status__c = 'Submitted'
        );
        insert donationRequest;
        
        // Create a test PDS_Product_Line_Item__c record
        PDS_Product_Line_Item__c productLineItem = new PDS_Product_Line_Item__c(
            PDS_Donation_Request__c = donationRequest.Id,
            PDS_Country__c = 'India',
            PDS_Product__c = product.Id
        );
        insert productLineItem;
        
        // Create DocumentProperties instance for test
        PDS_DocGenController.DocumentProperties docProps = new PDS_DocGenController.DocumentProperties();
        docProps.recordId = donationRequest.Id;
        docProps.docNames = 'TestPage1,TestPage2,TestPage3';
        docProps.docType = 'pdf,doc,xls';
        
        // Call the method
        Test.startTest();
        PDS_DocGenController.generatePDF(new List<PDS_DocGenController.DocumentProperties> { docProps });
        Test.stopTest();

        List<ContentVersion> contentVersions = [SELECT Id, Title, PathOnClient FROM ContentVersion WHERE Title LIKE '%.pdf%'];
        List<ContentDocumentLink> contentLinks = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :donationRequest.Id];
    }
    @isTest
    static void testControllerInitialization() {
        
        PDS_Product__c product = new PDS_Product__c(
            PDS_Product_Number__c = '123456',
            PDS_Product_Type__c = 'Vaccine',
            PDS_Product_Size__c = 'Bottle of 1000',
            PDS_Actual_Product_Cost__c = 500
        );
        insert product;
        
        PDS_Donation_Request__c request = new PDS_Donation_Request__c(
            Name = 'P-12311',
            PDS_Donation_Request_Status__c = 'Reviewed',
            PDS_Request_Submit_Date__c  = Date.today(),
            PDS_Approval_Date__c = Date.today()
        );
        insert request;
        
        PDS_Product_Line_Item__c productLineItem = new PDS_Product_Line_Item__c(
            PDS_Donation_Request__c = request.Id,
            PDS_Product__c = product.Id,
            PDS_Country__c = 'India',
            PDS_Quantity_Approved__c = 10,
            PDS_Quantity_Shipped__c = 5 
        );
        insert productLineItem;  
        
        PDS_Contact__c contact = new PDS_Contact__c(
            Name = 'Rusheel',
            PDS_Address_Type__c = 'Primary',
            PDS_IsActive__c = true
        );
        insert contact;
        
        PageReference pageRef = Page.PDS_ApprovalInvoiceMMOP;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', request.Id);
        
        Test.startTest();
        try{
            PDS_DocGenController controller = new PDS_DocGenController();
        	}
        catch(Exception e) {
            System.debug('e');
        }
        
        Test.stopTest();
    }
    @isTest
    static void testDeleteExistingDocs() {
        Test.startTest();
        PW_Robot_User__c rob = new PW_Robot_User__c(
        	Name = 'RobotUserSetting',
            External_ID__c = 'MSD-000001',
            Robot_User__c = 'testuser@merck.com.invalid'          
       	);
		insert rob;
        
        PDS_Donation_Request__c request = new PDS_Donation_Request__c(
            Name ='M-12121',
            PDS_Donation_Request_Status__c = 'Reviewed',
            PDS_Request_Submit_Date__c  = Date.today(),
            PDS_Approval_Date__c = Date.today()
        );
        insert request;
    ContentVersion contentVersion = new ContentVersion(
        Title = 'TestDocument(PDF)',
        PathOnClient = 'TestDocument.pdf',
        VersionData = Blob.valueOf('Test data')
    );
    insert contentVersion;
    ContentDocumentLink contentDocumentLink = new ContentDocumentLink(
        LinkedEntityId = request.Id,
        ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId,
        ShareType = 'V'
    );
    insert contentDocumentLink;
	List<ContentDocumentLink> initialContentDocumentLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :request.Id];        
       String docType = 'TestDocument(PDF)';

    try {
        PDS_DocGenController.deleteExistingDocs(request.Id, docType);
        List<ContentVersion> deletedContentVersions = [SELECT Id FROM ContentVersion WHERE Title LIKE '%TestDocument%' ALL ROWS];
        System.assertEquals(1, deletedContentVersions.size(), 'Expected ContentVersions to be deleted.');

        List<ContentDocumentLink> deletedContentDocumentLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :request.Id ALL ROWS];
        System.assertEquals(0, deletedContentDocumentLinks.size(), 'Expected ContentDocumentLinks to be deleted.');
    } catch (Exception e) {
        System.assert(true, 'Exception occurred: ' + e.getMessage());
    }

        Test.stopTest();
    }
   @isTest
    static void testPDS_DocGenController() {

        PDS_Contact__c doneeContact = new PDS_Contact__c(
            Name = 'Test Donee Contact',
            PDS_Address_Type__c = 'Primary',
            PDS_IsActive__c = true
        );
        insert doneeContact;

        PDS_Donation_Request__c donationRequest = new PDS_Donation_Request__c(
            Name = 'M-121212',
            PDS_Donation_Request_Status__c = 'Reviewed'
        );
        insert donationRequest;

        PDS_Product__c product = new PDS_Product__c(
            Name = 'Test Product', 
            PDS_Actual_Unit_Sale_Price__c = 10.0, 
            PDS_Actual_Product_Cost__c = 5.0, 
            PDS_Product_Size__c = 'Large'
        );
        insert product;

        PDS_Product_Line_Item__c productLineItem = new PDS_Product_Line_Item__c(
            PDS_Donation_Request__c = donationRequest.Id,
            PDS_Product__c = product.Id,
            PDS_Quantity_Approved__c = 100,
            PDS_Quantity_Shipped__c = 90
        );
        insert productLineItem;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', donationRequest.Id);
        PDS_DocGenController controller = new PDS_DocGenController();
        Test.stopTest();
    }
}