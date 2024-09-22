/*
* CreateCasesForMedicalInquiryTestMVN
* Created By: Kai Chen
* Created Date: 7/28/2013
* Updated By: Rick Locke
* Updated Date: 5/2/2014
* Description: Test cases for CreateCasesForMedicalInquiryMVN class
*/
@isTest
private class CreateCasesForMedicalInquiryTestMVN {

    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Account testAccount = new Account();

    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();

        testAccount.RecordTypeId = [select id from RecordType where SObjectType = 'Account' AND DeveloperName ='HCP'].Id;
        testAccount.FirstName = 'Test';
        testAccount.LastName = 'Account';

        insert testAccount;
    }

    @isTest static void createMedicalInquiry() {

        Case_Delivery_Method_Map_MVN__c dmMap = new Case_Delivery_Method_Map_MVN__c();
        dmMap.Name = 'Mail_vod';
        dmMap.Case_Translation_MVN__c = 'Mail';
        insert dmMap;

        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();

        inquiry.Account_vod__c = testAccount.Id;

        inquiry.Address_Line_1_vod__c = '123 Main St.';
        inquiry.Address_Line_2_vod__c = 'Apt. 456';
        inquiry.Status_vod__c = settings.Medical_Inquiry_Submitted_Status_MVN__c;
        inquiry.Delivery_Method_vod__c = 'Mail_vod';
        inquiry.Inquiry_Text__c = 'Test Inquiry Text';
        inquiry.Phone_Number_vod__c = '123-456-7890';
        inquiry.Fax_Number_vod__c = '987-654-4321';
        inquiry.City_vod__c = 'Chicago';
        inquiry.State_vod__c = 'IL';
        inquiry.Zip_vod__c = '60606';
        inquiry.Country_vod__c = 'us';
        inquiry.Product__c = 'Pradaxa';
        inquiry.Email_vod__c = 'testemail@test.com';
        inquiry.Requested_Date_MRK__c = Date.today();

        insert inquiry;

        List<Case> childCases = [select Id, Interaction_Notes_MVN__c, RecordTypeId, case_AddressLine1_MVN__c, case_AddressLine2_MVN__c,
                                MSD_CORE_Global_MedInfo_Delivery_Method__c, ParentId, Origin, ContactId, Details_MVN__c,
                                case_Account_Phone_MVN__c, case_Account_Fax_MVN__c, case_Account_Email_MVN__c, case_State_MVN__c, case_City_MVN__c, case_Postal_Code_MVN__c
                                from Case where Medical_Inquiry_MVN__c = :inquiry.Id];

        System.assert(2==childCases.size() || 1==childCases.size());

        Case interaction;
        Case request;

        for(Case childCase : childCases){
            if(childCase.RecordTypeId == [select Id from RecordType where SOBjectType = 'Case' AND DeveloperName = :settings.Interaction_Record_Type_MVN__c].ID){
                interaction = childCase;
            } else if(childCase.RecordTypeId == [select Id from RecordType where SOBjectType = 'Case' AND DeveloperName = :settings.Request_Record_Type_MVN__c].ID){
                request = childCase;
            }
        }


        if(interaction != null) {
            System.assertEquals(request.ParentId, interaction.Id);
            //System.assert(String.isNotBlank(interaction.Interaction_Notes_MVN__c));
        }

        //System.assert(String.isNotBlank(request.Interaction_Notes_MVN__c));
        //System.assert(request.Interaction_Notes_MVN__c.contains('Mail'));
        //System.assert(request.Interaction_Notes_MVN__c.contains('123 Main St.'));
        //System.assert(request.Interaction_Notes_MVN__c.contains('Chicago'));
        //System.assert(request.Interaction_Notes_MVN__c.contains('IL'));
        //System.assert(request.Interaction_Notes_MVN__c.contains('60606'));
        //System.assert(request.Interaction_Notes_MVN__c.contains('Pradaxa'));
        //System.assert(!request.Interaction_Notes_MVN__c.contains('testEmail@test.com'));
        //System.assert(!request.Interaction_Notes_MVN__c.contains('123-456-7890'));
        //System.assert(!request.Interaction_Notes_MVN__c.contains('987-654-4321'));
        System.assertEquals(request.Origin, settings.Medical_Inquiry_Source_MVN__c);
        //System.assertEquals(request.case_AddressLine1_MVN__c, inquiry.Address_Line_1_vod__c);
        //System.assertEquals(request.case_AddressLine2_MVN__c, inquiry.Address_Line_2_vod__c);
        //System.assertEquals(request.case_City_MVN__c, inquiry.City_vod__c);
        //System.assertEquals(request.case_State_MVN__c, inquiry.State_vod__c);
        //System.assertEquals(request.case_Postal_Code_MVN__c, inquiry.Zip_vod__c);
        //System.assertEquals(request.case_Account_Phone_MVN__c, inquiry.Phone_Number_vod__c);
        //System.assertEquals(request.case_Account_Fax_MVN__c, inquiry.Fax_Number_vod__c);
        //System.assertEquals(request.case_Account_Email_MVN__c, inquiry.Email_vod__c);
        System.assertEquals(request.MSD_CORE_Global_MedInfo_Delivery_Method__c, 'Mail');
        System.assertEquals(request.Details_MVN__c, inquiry.Inquiry_Text__c);

        testAccount = [select PersonContactId from Account where Id = :testAccount.Id];
        System.assertEquals(request.ContactId, testAccount.PersonContactId);

        inquiry.Status_vod__c = 'Test';

        update inquiry;

        inquiry.Status_vod__c = settings.Medical_Inquiry_Submitted_Status_MVN__c;

        update inquiry;

        childCases = [select Id from Case where Medical_Inquiry_MVN__c = :inquiry.Id];

        System.assert(2==childCases.size() || 1==childCases.size());
    }

    @isTest static void updateMedicalInquiry() {

        Case_Delivery_Method_Map_MVN__c dmMap = new Case_Delivery_Method_Map_MVN__c();
        dmMap.Name = 'Urgent_Mail_vod';
        dmMap.Case_Translation_MVN__c = 'Mail';
        insert dmMap;

        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();

        inquiry.Account_vod__c = testAccount.Id;

        inquiry.Address_Line_1_vod__c = '123 Main St.';
        inquiry.Address_Line_2_vod__c = 'Apt. 456';
        inquiry.Status_vod__c = 'Save_vod';
        inquiry.Delivery_Method_vod__c = 'Urgent_Mail_vod';
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

        List<Case> childCases = [select Id, Interaction_Notes_MVN__c from Case where Medical_Inquiry_MVN__c = :inquiry.Id];

        System.assertEquals(0, childCases.size());

        inquiry.Status_vod__c = settings.Medical_Inquiry_Submitted_Status_MVN__c;

        update inquiry;

        childCases = [select Id, Interaction_Notes_MVN__c, RecordTypeID, MSD_CORE_Global_MedInfo_Delivery_Method__c, ParentId, case_AddressLine1_MVN__c, case_AddressLine2_MVN__c,  Origin from Case where Medical_Inquiry_MVN__c = :inquiry.Id];

        System.assert(2==childCases.size() || 1==childCases.size());

        Case interaction;
        Case request;

        for(Case childCase : childCases){
            if(childCase.RecordTypeId == [select Id from RecordType where SOBjectType = 'Case' AND DeveloperName = :settings.Interaction_Record_Type_MVN__c].ID){
                interaction = childCase;
            } else if(childCase.RecordTypeId == [select Id from RecordType where SOBjectType = 'Case' AND DeveloperName = :settings.Request_Record_Type_MVN__c].ID){
                request = childCase;
            }
        }

        if(interaction != null) {
            System.assertEquals(request.ParentId, interaction.Id);
            //System.assert(String.isNotBlank(interaction.Interaction_Notes_MVN__c));
        }

        //System.assert(String.isNotBlank(request.Interaction_Notes_MVN__c));
        //System.assert(request.Interaction_Notes_MVN__c.contains('Mail'));
        //System.assert(request.Interaction_Notes_MVN__c.contains('123 Main St.'));
        //System.assert(request.Interaction_Notes_MVN__c.contains('Chicago'));
        //System.assert(request.Interaction_Notes_MVN__c.contains('IL'));
        //System.assert(request.Interaction_Notes_MVN__c.contains('60606'));
        //System.assert(request.Interaction_Notes_MVN__c.contains('Pradaxa'));
        //System.assert(!request.Interaction_Notes_MVN__c.contains('testEmail@test.com'));
        //System.assert(!request.Interaction_Notes_MVN__c.contains('123-456-7890'));
        //System.assert(!request.Interaction_Notes_MVN__c.contains('987-654-4321'));
        System.assertEquals(request.Origin, settings.Medical_Inquiry_Source_MVN__c);
        //System.assertEquals(request.case_AddressLine1_MVN__c, inquiry.Address_Line_1_vod__c);
        //System.assertEquals(request.case_AddressLine2_MVN__c, inquiry.Address_Line_2_vod__c);
        System.assertEquals(request.MSD_CORE_Global_MedInfo_Delivery_Method__c, 'Mail');
    }

    @isTest static void bulkTest() {

        List<Medical_Inquiry_vod__c> inquiriesToInsert = new List<Medical_Inquiry_vod__c>();

        Case_Delivery_Method_Map_MVN__c dmMap = new Case_Delivery_Method_Map_MVN__c();
        dmMap.Name = 'Fax_vod';
        dmMap.Case_Translation_MVN__c = 'Fax';
        insert dmMap;

        for(Integer i = 0; i < 10; i++){
            Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();

            inquiry.Account_vod__c = testAccount.Id;

            inquiry.Address_Line_1_vod__c = '123 Main St.';
            inquiry.Address_Line_2_vod__c = 'Apt. 456';
            inquiry.Status_vod__c = settings.Medical_Inquiry_Submitted_Status_MVN__c;
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

        List<Case> childCases = [select Id, Interaction_Notes_MVN__c from Case where Medical_Inquiry_MVN__c = :inquiriesMap.keySet()];

        System.assert(20==childCases.size());
    }

    @isTest static void createSiblingMedicalInquiries(){
        Case_Delivery_Method_Map_MVN__c dmMap = new Case_Delivery_Method_Map_MVN__c();
        dmMap.Name = 'Mail_vod';
        dmMap.Case_Translation_MVN__c = 'Mail';
        insert dmMap;

        List<Medical_Inquiry_vod__c> inquiries = new List<Medical_Inquiry_vod__c>();

        Medical_Inquiry_vod__c inquiry = new Medical_Inquiry_vod__c();

        inquiry.Account_vod__c = testAccount.Id;

        inquiry.Address_Line_1_vod__c = '123 Main St.';
        inquiry.Address_Line_2_vod__c = 'Apt. 456';
        inquiry.Status_vod__c = settings.Medical_Inquiry_Submitted_Status_MVN__c;
        inquiry.Delivery_Method_vod__c = 'Mail_vod';
        inquiry.Inquiry_Text__c = 'Test Inquiry Text';
        inquiry.Phone_Number_vod__c = '123-456-7890';
        inquiry.Fax_Number_vod__c = '987-654-4321';
        inquiry.City_vod__c = 'Chicago';
        inquiry.State_vod__c = 'IL';
        inquiry.Zip_vod__c = '60606';
        inquiry.Country_vod__c = 'us';
        inquiry.Product__c = 'Pradaxa';
        inquiry.Email_vod__c = 'testemail@test.com';
        inquiry.Group_Identifier_vod__c = '12345';
        inquiry.Requested_Date_MRK__c = Date.today();

        inquiries.add(inquiry);

        Medical_Inquiry_vod__c siblingInquiry = new Medical_Inquiry_vod__c();

        siblingInquiry.Account_vod__c = testAccount.Id;

        siblingInquiry.Address_Line_1_vod__c = '123 Main St.';
        siblingInquiry.Address_Line_2_vod__c = 'Apt. 456';
        siblingInquiry.Status_vod__c = settings.Medical_Inquiry_Submitted_Status_MVN__c;
        siblingInquiry.Delivery_Method_vod__c = 'Phone_vod';
        siblingInquiry.Inquiry_Text__c = 'Test Inquiry Text 2';
        siblingInquiry.Phone_Number_vod__c = '123-456-7890';
        siblingInquiry.Fax_Number_vod__c = '987-654-4321';
        siblingInquiry.City_vod__c = 'Chicago';
        siblingInquiry.State_vod__c = 'IL';
        siblingInquiry.Zip_vod__c = '60606';
        siblingInquiry.Country_vod__c = 'us';
        siblingInquiry.Product__c = 'Cholecap';
        siblingInquiry.Email_vod__c = 'testemail@test.com';
        siblingInquiry.Group_Identifier_vod__c = '12345';
        siblingInquiry.Requested_Date_MRK__c = Date.today();

        inquiries.add(siblingInquiry);

        insert inquiries;

        Id requestRecordTypeId = [select Id from RecordType where SOBjectType = 'Case' AND DeveloperName = :settings.Request_Record_Type_MVN__c].ID;

        List<Case> childCases = [select Id, ParentId, RecordTypeId from Case where Medical_Inquiry_MVN__c = :inquiry.Id AND RecordTypeId = :requestRecordTypeId];

        System.assert(1==childCases.size());

        List<Case> siblingChildCases = [select Id, ParentId, RecordTypeId from Case where Medical_Inquiry_MVN__c = :siblingInquiry.Id AND RecordTypeId = :requestRecordTypeId];

        System.debug('SIBLING CASES: ' + siblingChildCases);

        System.assert(1==siblingChildCases.size());

        System.assertEquals(childCases[0].ParentId, siblingChildCases[0].ParentId);
    }
}