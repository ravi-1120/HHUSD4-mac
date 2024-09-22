@isTest
private class PDS_UtilityTest {
      @IsTest
    static void testGetPicklistValues() {
        String objectApiName = 'PDS_Donation_Request__c';
        String fieldApiName = 'PDS_Donation_Type__c';
        
        List<Map<String, String>> picklistValues = PDS_Utility.getPicklistValues(objectApiName, fieldApiName);
        
        System.assertNotEquals(0, picklistValues.size(), 'Picklist values should not be empty');
        for (Map<String, String> picklistValue : picklistValues) {
            System.assert(picklistValue.containsKey('label'), 'Picklist value should have a label');
            System.assert(picklistValue.containsKey('value'), 'Picklist value should have a value');
        }
    }
    
     @IsTest
    static void testGetCopyrightLabel() {
        String copyrightLabel = PDS_Utility.getCopyrightLabel();
        
        System.assert(copyrightLabel.contains(String.valueOf(System.today().year())), 'Copyright label should contain the current year');
    }
    
     @isTest
    static void testAttachRecordDocumentsSuccess() {
        
		PDS_Donation_Request__c req = new PDS_Donation_Request__c(Name='M-1021',PDS_Donation_Request_Status__c = 'Reviewed');
        insert req;      
        // Test for successful attachment
        String recordId = req.Id;
        String base64String = 'sampleBase64String';
        String fileName = 'sampleFileName';
        String fileType = 'pdf';
        
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
        contentDocumentLinks1.Visibility = 'AllUsers';
        insert contentDocumentLinks1;
        Test.startTest();
        String result = PDS_Utility.attachRecordDocuments(req.Id, base64String, fileName, fileType);
        Test.stopTest();
        
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c(DATA_CHANGE_REQUEST_MODE_vod__c = 2);    
        insert vsc;
        
        Account acc = new Account(Name = 'Test Account', Territory_vod__c = '101', Enable_Restricted_Products_vod__c = true);
        insert acc;
        
        
        
       /* PW_Robot_User__c rob = new PW_Robot_User__c();
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
        contentDocumentLinks1.Visibility = 'AllUsers';
        insert contentDocumentLinks1;
        Test.startTest();
        Map<String, Object> result = PDS_RequestDetailController.getContentDocuments(req.Id);
        Test.stopTest();*/
        
        
    }
 
}