@isTest
public class PDS_RequestDetailControllerTest {
    @isTest
    static void testgetdonationreqdetails(){
        PDS_Donation_Request__c donReq = new PDS_Donation_Request__c();
        donReq.Name = 'M-1022';
        donReq.PDS_Donation_Request_Status__c = 'Pending';
        donReq.PDS_Indication__C = 'ONCHOCERCIASIS';
        Test.startTest();
        PDS_Donation_Request__c result = PDS_RequestDetailController.getdonationreqdetails(donReq.Id);
        Test.stopTest(); 
    }
     @isTest
    static void testGetContentDocuments() {
        
        PDS_Donation_Request__c req = new PDS_Donation_Request__c(Name='M-1021',PDS_Donation_Request_Status__c = 'Reviewed');
        insert req;
        
        PW_Robot_User__c rob = new PW_Robot_User__c();
        rob.Name = 'RobotUserSetting';
        rob.External_ID__c = 'MSD-000001';
        rob.Robot_User__c = 'testuser@merck.com.invalid';
        insert rob;
        
        ContentVersion version1 = new ContentVersion(
            Title = 'Application',
            PathOnClient = 'Application.pdf',
            VersionData = Blob.valueOf('Test content for Application Document')
        );
        insert version1;
        List<ContentDocument> documents = [SELECT Id, Title, FileExtension, LatestPublishedVersionId FROM ContentDocument Where LatestPublishedVersionId =:version1.Id];
        
        ContentDocumentLink contentDocumentLinks1 = new ContentDocumentLink();
        contentDocumentLinks1.LinkedEntityId = req.Id;
        contentDocumentLinks1.ContentDocumentId = documents[0].Id;
        //contentDocumentLinks1.Visibility = 'AllUsers';
        insert contentDocumentLinks1;
        Test.startTest();
        Map<String, Object> result = PDS_RequestDetailController.getContentDocuments(req.Id);
        Test.stopTest();
        
    }

    @isTest
    static void testcancelRequest(){       
        PDS_Donation_Request__c donReq = new PDS_Donation_Request__c(
            Name = 'M-1022',
            PDS_Donation_Request_Status__c = 'Closed',
            PDS_Request_Resolution__c = 'Canceled'
        );
        insert donReq;
        Test.startTest();
        String result = PDS_RequestDetailController.cancelRequest(donReq.Id);
        Test.stopTest();
    }
   @IsTest
    static void testTranslatePicklistValue() {
        Schema.DescribeFieldResult fieldResult = Account.Industry.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                Map<String, String> picklistValue = new Map<String, String>();
                picklistValue.put('label', entry.getLabel());
                picklistValue.put('value', entry.getValue());
                picklistValues.add(picklistValue);
            }
        }
        
        // Test cases
        // Case 1: Valid translation
        String valueToTranslate = 'Chemicals';
        String expectedLabel = 'Chemicals';
        String translatedLabel = PDS_RequestDetailController.translatePicklistValue('Account', 'Industry', valueToTranslate);
        System.assertEquals(expectedLabel, translatedLabel);
        
        // Case 2: Non-existent value (should return original value)
        valueToTranslate = 'NonexistentValue';
        expectedLabel = valueToTranslate;
        translatedLabel = PDS_RequestDetailController.translatePicklistValue('Account', 'Industry', valueToTranslate);
        System.assertEquals(expectedLabel, translatedLabel);
        
        // Case 3: Exception handling (simulate exception in utility method)
        Test.startTest();
        try {
            String translatedLabelWithException = PDS_RequestDetailController.translatePicklistValue('InvalidObject', 'Industry', 'Chemicals');
            System.assertEquals('Chemicals', translatedLabelWithException); 
        } catch (Exception e) {
            System.debug('Exception handled: ' + e.getMessage());
        }
        Test.stopTest();
    }
}