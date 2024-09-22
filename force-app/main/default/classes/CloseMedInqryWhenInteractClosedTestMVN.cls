/*
* CloseMedInqryWhenInteractClosedTestMVN
* Created By:    Kai Chen
* Created Date:  7/28/2013
* Description:   Test cases for the CloseMedInqryWhenInteractClosedMVN class
*/
@isTest
private class CloseMedInqryWhenInteractClosedTestMVN {
    static {
        TestDataFactoryMVN.createSettings(true);
    }

    @isTest static void testCancelInteraction() {
        Account testAccount = new Account();
        testAccount.RecordTypeId = [select id from RecordType where SObjectType = 'Account' AND DeveloperName ='HCP'].Id;
        testAccount.FirstName = 'Test';
        testAccount.LastName = 'Account';

        insert testAccount;

        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();

        inquiry.Account_vod__c = testAccount.Id;

        inquiry.Address_Line_1_vod__c = '123 Main St.';
        inquiry.Address_Line_2_vod__c = 'Apt. 456';
        inquiry.Status_vod__c = Service_Cloud_Settings_MVN__c.getInstance().Medical_Inquiry_Submitted_Status_MVN__c;
        inquiry.Delivery_Method_vod__c = 'Mail_vod';
        inquiry.Inquiry_Text__c = 'Test Inquiry Text';
        inquiry.Phone_Number_vod__c = '123-456-7890';
        inquiry.Fax_Number_vod__c = '987-654-4321';
        inquiry.City_vod__c = 'Chicago';
        inquiry.State_vod__c = 'IL';
        inquiry.Zip_vod__c = '60606';
        inquiry.Country_vod__c = 'us';
        inquiry.Product__c = 'Pradaxa';
        inquiry.Email_vod__c = 'testEmail@test.com';
        inquiry.Requested_Date_MRK__c = Date.today();

        insert inquiry;

        List<Case> childCases = [select Id, Interaction_Notes_MVN__c, RecordTypeId, Status from Case where Medical_Inquiry_MVN__c = :inquiry.Id];

        Id interactionId = [select Id from RecordType where SObjectType = 'Case' AND DeveloperName = 'Interaction_MVN'].Id; 

        Test.startTest();
            for(Case childCase : childCases){
                if(childCase.RecordTypeId == interactionId){
                    childCase.Status = 'Cancelled';
                }
            }

            update childCases;
        Test.stopTest();

        inquiry = [select Id, Status_vod__c from Medical_Inquiry_vod__c where Id = :inquiry.Id];

        System.assertEquals(Service_Cloud_Settings_MVN__c.getInstance().Medical_Inquiry_Submitted_Status_MVN__c, inquiry.Status_vod__c);
    }

    @isTest static void testCloseInteraction() {
        Account testAccount = new Account();
        testAccount.RecordTypeId = [select id from RecordType where SObjectType = 'Account' AND DeveloperName ='HCP'].Id;
        testAccount.FirstName = 'Test';
        testAccount.LastName = 'Account';

        insert testAccount;

        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();

        inquiry.Account_vod__c = testAccount.Id;

        inquiry.Address_Line_1_vod__c = '123 Main St.';
        inquiry.Address_Line_2_vod__c = 'Apt. 456';
        inquiry.Status_vod__c = Service_Cloud_Settings_MVN__c.getInstance().Medical_Inquiry_Submitted_Status_MVN__c;
        inquiry.Delivery_Method_vod__c = 'Mail_vod';
        inquiry.Inquiry_Text__c = 'Test Inquiry Text';
        inquiry.Phone_Number_vod__c = '123-456-7890';
        inquiry.Fax_Number_vod__c = '987-654-4321';
        inquiry.City_vod__c = 'Chicago';
        inquiry.State_vod__c = 'IL';
        inquiry.Zip_vod__c = '60606';
        inquiry.Country_vod__c = 'us';
        inquiry.Product__c = 'Pradaxa';
        inquiry.Email_vod__c = 'testEmail@test.com';
        inquiry.Requested_Date_MRK__c = Date.today();

        insert inquiry;

        List<Case> childCases = [select Id, Interaction_Notes_MVN__c, RecordTypeId, Status from Case where Medical_Inquiry_MVN__c = :inquiry.Id];

        Id interactionId = [select Id from RecordType where SObjectType = 'Case' AND DeveloperName = 'Interaction_MVN'].Id; 

        Test.startTest();
            for(Case childCase : childCases){
                if(childCase.RecordTypeId == interactionId){
                    childCase.Status = Service_Cloud_Settings_MVN__c.getInstance().Closed_Status_MVN__c;
                }
            }

            update childCases;
        Test.stopTest();
        
        inquiry = [select Id, Status_vod__c from Medical_Inquiry_vod__c where Id = :inquiry.Id];

        System.assertEquals(Service_Cloud_Settings_MVN__c.getInstance().Closed_Status_MVN__c, inquiry.Status_vod__c);
    }

    @isTest static void testBulkClose() {
        Account testAccount = new Account();
        testAccount.RecordTypeId = [select id from RecordType where SObjectType = 'Account' AND DeveloperName ='HCP'].Id;
        testAccount.FirstName = 'Test';
        testAccount.LastName = 'Account';

        insert testAccount;

        List<Medical_Inquiry_vod__c> inquiriesToInsert = new List<Medical_Inquiry_vod__c>();

        for(Integer i = 0; i < 2; i++){
            Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();

            inquiry.Account_vod__c = testAccount.Id;

            inquiry.Address_Line_1_vod__c = '123 Main St.';
            inquiry.Address_Line_2_vod__c = 'Apt. 456';
            inquiry.Status_vod__c = Service_Cloud_Settings_MVN__c.getInstance().Medical_Inquiry_Submitted_Status_MVN__c;
            inquiry.Delivery_Method_vod__c = 'Fax_vod';
            inquiry.Inquiry_Text__c = 'Test Inquiry Text';
            inquiry.Phone_Number_vod__c = '123-456-7890';
            inquiry.Fax_Number_vod__c = '987-654-4321';
            inquiry.City_vod__c = 'Chicago';
            inquiry.State_vod__c = 'IL';
            inquiry.Zip_vod__c = '60606';
            inquiry.Country_vod__c = 'us';
            inquiry.Product__c = 'Pradaxa';
            inquiry.Email_vod__c = 'testEmail@test.com';
            inquiry.Requested_Date_MRK__c = Date.today();

            inquiriesToInsert.add(inquiry);
        }

        insert inquiriesToInsert;

        Map<Id, Medical_Inquiry_vod__c> inquiriesMap = new Map<Id, Medical_Inquiry_vod__c>(inquiriesToInsert);

        List<Case> childCases = [select Id, Interaction_Notes_MVN__c, Status, RecordTypeId from Case where Medical_Inquiry_MVN__c = :inquiriesMap.keySet()];

        Id interactionId = [select Id from RecordType where SOBjectType = 'Case' AND DeveloperName = 'Interaction_MVN'].Id; 
        for(Case childCase : childCases){
            if(childCase.RecordTypeId == interactionId){
                childCase.Status = 'Closed';
            }
        }

        Test.startTest();
            update childCases;
        Test.stopTest();
        inquiriesToInsert = [select Id, Status_vod__c from Medical_Inquiry_vod__c where Id in :inquiriesMap.keySet()];

        for(Medical_Inquiry_vod__c inquiry : inquiriesToInsert){
            System.assertEquals(Service_Cloud_Settings_MVN__c.getInstance().Closed_Status_MVN__c, inquiry.Status_vod__c);
        }
    }
}