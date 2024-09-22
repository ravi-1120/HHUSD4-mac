@isTest
public class PDS_EmailApprovalHandlerTest {
   @isTest
    static void testRejectEmail() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Please reject';
        email.plainTextBody = 'Reject';

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        Test.startTest();
        PDS_EmailApprovalHandler handler = new PDS_EmailApprovalHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
    }
    @isTest
    static void testEmailWithoutStatus() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = null;
        email.plainTextBody = 'No Status';

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        Test.startTest();
        PDS_EmailApprovalHandler handler = new PDS_EmailApprovalHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
    }
    @isTest
    static void testEmailWithoutBody() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Please approve';
        email.plainTextBody = null;

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        Test.startTest();
        PDS_EmailApprovalHandler handler = new PDS_EmailApprovalHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

    }
    @isTest
    static void testApprovalProcessError() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '';
        email.plainTextBody = ''; 

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        Test.startTest();
        PDS_EmailApprovalHandler handler = new PDS_EmailApprovalHandler();
        
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();
    }   
   @isTest
    static void testHandleInboundEmailApproveSuccess() {
        Profile p = [Select Id from Profile Limit 1];
         User usr= new User(
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

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'approve';
        email.plainTextBody = workItemId;

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        PDS_EmailApprovalHandler handler = new PDS_EmailApprovalHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
    }


}