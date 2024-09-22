@isTest
public class PDS_EmailControllerTest {
    
    @testSetup
    static void setupTestData() {
         PW_Robot_User__c rob = new PW_Robot_User__c(
        	Name = 'RobotUserSetting',
            External_ID__c = 'MSD-000001',
            Robot_User__c = 'testuser@merck.com.invalid'          
       	);
		insert rob;

        PDS_Donation_Request__c donationRequest = new PDS_Donation_Request__c(
           	Name = 'M-1022',
            PDS_Request_Submit_Date__c  = Date.today(),
            PDS_Approval_Date__c = Date.today(),
            PDS_Donation_Request_Status__c = 'Reviewed'
        );
        insert donationRequest;

       ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            VersionData = Blob.valueOf('Test content'),
            PathOnClient = 'TestDocument.txt'
        );
        insert contentVersion;

            ContentDocumentLink contentDocLink = new ContentDocumentLink(
                LinkedEntityId = donationRequest.Id,
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId
            );
            insert contentDocLink;
        PDS_Product__c product = new PDS_Product__c(
        	Name = 'Product'
        );
		insert product;
        
        PDS_Product_Line_Item__c productLineItem = new PDS_Product_Line_Item__c(
            PDS_Donation_Request__c = donationRequest.Id,
            PDS_Country__c = 'India',
            PDS_Product__c = product.Id
        );
        insert productLineItem;
       
    }
    
    @isTest
    static void testSendEmailWithAttachment() {
        PDS_Donation_Request__c donationRequest = [SELECT Id FROM PDS_Donation_Request__c LIMIT 1];
       
        PDS_EmailController.emailProperties emailProps = new PDS_EmailController.emailProperties();
        emailProps.recordId = donationRequest.Id;
        emailProps.flowType = 'Approval';
        emailProps.emailList = 'test1@example.com,test2@example.com';
        emailProps.docList = 'Test Document';
        emailProps.emailService = true;
        emailProps.emailTemplateName = 'Approval';
        
        List<PDS_EmailController.emailProperties> emailPropsList = new List<PDS_EmailController.emailProperties>{emailProps};
        
        Test.startTest();
        PDS_EmailController.sendEmailWithAttachment(emailPropsList);
        Test.stopTest();
        System.assertEquals(emailProps.recordId, donationRequest.Id, 'Record Id does not match');
        System.assertEquals(emailProps.flowType, 'Approval', 'Flow Type does not match');
        System.assertEquals(emailProps.emailList, 'test1@example.com,test2@example.com', 'Email List does not match');
        System.assertEquals(emailProps.docList, 'Test Document', 'Document List does not match');
        System.assertEquals(emailProps.emailService, true, 'Email Service does not match');
        System.assertEquals(emailProps.emailTemplateName, 'Approval', 'Email Template Name does not match');

    }
}