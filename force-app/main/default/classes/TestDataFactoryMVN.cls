/*
* TestDataFactoryMVN
* Created By:    Roman Lerman
* Created Date:  3/4/2013
* Modified By:   Samuel Rosen
* Modified On:   Oct 2013
* Description:   This is the data factory used to generate data by all of the test classes
*/
public class TestDataFactoryMVN {
    public static Integer TEST_DATA_SIZE = 25;
    private static String SAP_ID_TYPE = 'SAPID';

    public static String interactionRecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'Interaction_MVN'].Id;
    public static String requestRecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'Request_MVN'].Id;
    public static String fulfillmentRecordTypeId = [select Id from RecordType where SObjectType = 'Fulfillment_MVN__c' and DeveloperName = 'Fulfillment_MVN'].Id;
    public static String consumerRecordTypeId = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'Consumer_MVN'].Id;

    public static Service_Cloud_Settings_MVN__c mainSettings;

    public static List<MSD_CORE_Type_To_Record_Type_Map__c> typeMappingSettings;
    public static List<MSD_CORE_Account_Fields_To_Stamp_Map__c> accountFieldsToStampSettings;

    public static List<Case> createInteractions() {
        List<Case> cases = new List<Case>();
        for(Integer i=0; i<TEST_DATA_SIZE; i++) {
            cases.add(new Case(RecordTypeId = interactionRecordTypeId,
                      Status='Open')
            );
        }
        insert cases;

        return cases;
    }

    public static List<Case> createRequests(List<Case> interactions, String status){
         List<Case> requests = new List<Case>();
         for (Case c : interactions) {
             Case request = c.clone(false);
         request.RecordTypeId = requestRecordTypeId;
             request.ParentId = c.id;
             request.Status = status;

             requests.add(request);
             requests.add(request.clone(false));
         }
         insert requests;

         return requests;
    }
@testvisible 
    public static Account constructTestPersonAccount() {
        Account personAccount = new Account();
        personAccount.FirstName = 'Test';
        personAccount.Preferred_First_Name_MRK__c = 'Test';
        personAccount.LastName = 'Account';
        personAccount.Preferred_Last_Name_MRK__c = 'Account';
        personAccount.RecordTypeId = consumerRecordTypeId;
        personAccount.Phone = '3333333333';
        personAccount.PersonHomePhone = '4444444444';
        personAccount.PersonMobilePhone = '4444444444';
        personAccount.PersonOtherPhone = '5555555555';
        personAccount.Class_of_Trade_MRK__c = 'INDIV HEALTHCARE PROF';

        return personAccount;
    }

    public static Account createTestPersonAccount() {
        Account personAccount = constructTestPersonAccount();

        insert personAccount;

        return personAccount;
    }

    public static Account createTestPersonAccountByCountry(String country){
        Account personAccount = constructTestPersonAccount();
        personAccount.MSD_CORE_Country_Code__c = country;

        insert personAccount;

        return personAccount;
    }

    public static Account createTestPersonAccountForAnonymization(String country){
        Account personAccount = constructTestPersonAccount();
        personAccount.MSD_CORE_Country_Code__c = country;
        personAccount.Anonymize_MVN__c = true;

        insert personAccount;

        return personAccount;
    }

    public static Account createTestEmployee() {
        Account personAccount = new Account();
        personAccount.FirstName = 'Johnny';
        personAccount.Preferred_First_Name_MRK__c = 'Johnny';
        personAccount.LastName = 'Employee';
        personAccount.Preferred_Last_Name_MRK__c = 'Employee';
        personAccount.Preferred_Salutation_MRK__c = 'Mr.';
        personAccount.RecordTypeId = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'Employee_MVN'][0].Id;
        personAccount.Phone = '4444444444';
        personAccount.Class_of_Trade_MRK__c = 'EMPLOYEE';
        personAccount.MSD_CORE_Merck_Employee_ID__c = 'testID';
        insert personAccount;

        return personAccount;
    }
    public static Account createTestHCP() {
        Account personAccount = new Account();
        personAccount.FirstName = 'Test';
        personAccount.Preferred_First_Name_MRK__c = 'Test';
        personAccount.LastName = 'Account';
        personAccount.Preferred_Last_Name_MRK__c = 'Account';
        personAccount.Middle_vod__c = 'Little';
        personAccount.Preferred_Middle_Name_MRK__c = 'Little';
        personAccount.RecordTypeId = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'HCP'][0].Id;
        personAccount.Phone = '5555555555';
        personAccount.Class_of_Trade_MRK__c = 'INDIV HEALTHCARE PROF';
        insert personAccount;

        return personAccount;
    }

    public static Account createBusiness() {
        Account businessAccount = new Account(
            Name = 'Test business',
            Preferred_Full_Name_MRK__c = 'Test business',
            RecordTypeId = [select Id from RecordType where SObjectType = 'Account' and DeveloperName = 'Hospital_vod'][0].Id,
            Class_of_Trade_MRK__c = 'HOSPITAL');
        insert businessAccount;

        Communication_Mechanism_MRK__c communicationMechanism = new Communication_Mechanism_MRK__c(
            Account_MRK__c = businessAccount.Id,
            Phone_MRK__c = '9999999999',
            Do_Not_Use_Inbound_Routing_MRK__c = false);
        insert communicationMechanism;

        Alternate_Identifier_MRK__c alternateIdentifier = new Alternate_Identifier_MRK__c(
            Account_MRK__c = businessAccount.Id,
            Alternate_Identifier_Value_MRK__c = 'anAlternateId',
            Type_MRK__c = SAP_ID_TYPE);
        insert alternateIdentifier;

        return businessAccount;
    }

    public static Child_Account_vod__c relateAccounts(Account child, Account parent){
        System.debug('Creating relationship between ' + child.Id + ' and parent ' + parent.Id);
        Child_Account_vod__c childAccount = new Child_Account_vod__c(
            Child_Account_vod__c = child.Id,
            Parent_Account_vod__c = parent.Id);

        insert childAccount;

        return childAccount;
    }

    public static Case createTestCase(Id accountId, Id contactId) {
        Case testCase = new Case();
        testCase.AccountId = accountId;
        testCase.ContactId = contactId;
        testCase.RecordTypeId = interactionRecordTypeId;
        insert testCase;

        return testCase;
    }

    public static Case createClosedTestCase() {
        Account personAccount = createTestPersonAccount();

        Case testCase = new Case();
        testCase.AccountId = personAccount.Id;
        testCase.ContactId = [select PersonContactId from Account where Id = :personAccount.Id].PersonContactId;
        testCase.RecordTypeId = interactionRecordTypeId;
        testCase.Address_MVN__c = createTestAddress(personAccount).Id;
        testCase.Status = 'Closed';
        insert testCase;

        return testCase;
    }

    public static Case createClosedTestRequest(Case parentCase) {
        return createClosedTestRequest(parentCase, null);
    }

    public static Case createClosedTestRequest(Case parentCase, String productId) {
        Case testCase = new Case();
        testCase.ParentId = parentCase.Id;
        testCase.AccountId = parentCase.AccountId;
        testCase.ContactId = [select PersonContactId from Account where Id = :parentCase.AccountId].PersonContactId;
        testCase.RecordTypeId = requestRecordTypeId;
        testCase.Address_MVN__c = parentCase.Address_MVN__c;
        testCase.Status = 'Closed';
        if(productId != null){
            testCase.Category_MVN__c = 'Product Specific';
            testCase.Product_MVN__c = productId;
        }
        insert testCase;

        return testCase;
    }

    public static Case createTestCase() {
        return createTestCase(null);
    }

    public static Case createTestCase(String productId) {
        return createTestCase(productId, true);
    }
    
    public static Case createTestCase(String productId, Boolean withAddress) {
        Account personAccount = createTestPersonAccount();

        Case testCase = new Case();
        testCase.AccountId = personAccount.Id;
        testCase.ContactId = [select PersonContactId from Account where Id = :personAccount.Id].PersonContactId;
        testCase.RecordTypeId = interactionRecordTypeId;
        if(withAddress) {
            testCase.Address_MVN__c = createTestAddress(personAccount).Id;
        }
        if(productId != null){
            testCase.Category_MVN__c = 'Product Specific';
            testCase.Product_MVN__c = productId;
        }
        testCase.Interaction_Notes_MVN__c = 'sdf';
        try {
            database.upsert(testCase, true);
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return testCase;
    }

    public static Case createTestRequest(Case parentCase) {
        return createTestRequest(parentCase, null);
    }

    public static Case createTestRequest(Case parentCase, String productId) {
        Case testCase = new Case();
        testCase.ParentId = parentCase.Id;
        testCase.AccountId = parentCase.AccountId;
        testCase.ContactId = parentCase.ContactId;
        testCase.RecordTypeId = requestRecordTypeId;
        testCase.Address_MVN__c = parentCase.Address_MVN__c;
        if(productId != null){
            testCase.Category_MVN__c = 'Product Specific';
            testCase.Product_MVN__c = productId;
        }
        insert testCase;

        return testCase;
    }

    public static Address_vod__c createTestAddress(Account acct){
        return createTestAddressByCountry(acct, 'us');
    }

    public static Address_vod__c createTestAddressByCountry(Account acct, String country){
        return createTestAddressByCountry(acct, country, null);
    }

    public static Address_vod__c createTestAddressByCountry(Account acct, String country, String externalId){
        Address_vod__c address = new Address_vod__c(Name = '123 Fake St.');
        address.city_vod__c = 'San Francisco Treat';
        address.zip_vod__c = '94941';
        address.state_vod__c = 'ca';
        address.country_vod__c = country;
        address.Account_vod__c = acct.Id;
        address.Phone_vod__c = '1111111111';
        address.External_ID_vod__c = externalId;
        insert address;

        return address;
    }

    public static Case createTestEmailRequest() {
        Case testCase = new Case();
        testCase.Origin = 'Email';
        testCase.RecordTypeId = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = :Service_Cloud_Settings_MVN__c.getInstance().Request_Record_Type_MVN__c].Id;
        testCase.Subject = 'Test';
        testCase.Description = 'Test';
        insert testCase;

        return testCase;
    }

    public static User createTestUser(){
        User user = new User(alias='ccusysad', email= 'callcentertestusermvn@example.com',
                                emailencodingkey='UTF-8', firstName='Reginald', lastname='Wellington', languagelocalekey='en_US',
                                localesidkey='en_US', profileid = [select Id from Profile where Name = 'System Administrator'].Id,
                                isActive = true, timezonesidkey='America/Los_Angeles', username='callcentertestusermvn@callcenter.com',
                                MSD_CORE_Country_Code__c = 'US', UserPermissionsKnowledgeUser = true, 
                                Default_Document_Search_Language_MVN__c = 'en_US');
        user.Default_Document_Search_Language_MVN__c = 'English';

        insert user;

        return user;
    }

    public static void createSettings(Boolean isEnterprise){
        if(mainSettings == null) {
            mainSettings = new Service_Cloud_Settings_MVN__c();

            mainSettings.Document_Search_Max_Results_MVN__c = 50;
            mainSettings.Interaction_Record_Type_MVN__c = 'Interaction_MVN';
            mainSettings.Interaction_Anonymize_Countries_MVN__c = 'US';
            mainSettings.Document_Search_Family_Type_MVN__c = 'Family';
            mainSettings.Request_Record_Type_MVN__c = 'Request_MVN';
            mainSettings.HCP_Record_Type_MVN__c = 'HCP';
            mainSettings.Employee_Record_Type_MVN__c = 'Employee_MVN';
            mainSettings.Administrator_Email_MVN__c = 'test@example.com';
            mainSettings.Open_Status_MVN__c = 'Open';
            mainSettings.Closed_Status_MVN__c = 'Closed';
            mainSettings.Vault_Base_URL_MVN__c = 'https://test.veevavault.com';
            mainSettings.Vault_API_Version_MVN__c = 'v8.0';
            mainSettings.Vault_Viewer_Doc_Type_Exclusion_List_MVN__c = 'MedicalLetter';
            mainSettings.Document_Search_Utility_Class_MVN__c = 'VaultSearchUtilityMVN';
            mainSettings.Account_Search_Utility_Classes_MVN__c = 'SFAccountSearchUtilityMVN';
            mainSettings.Temporary_Account_Hold_Period_Days_MVN__c = 0;
            mainSettings.Vault_Relationship_Includes_MVN__c = 'supporting_documents__vs';
            mainSettings.Person_Account_Search_Types_MVN__c = 'INDIV HEALTHCARE PROF,HEALTHCARE BUSINESS PROF,EMPLOYEE,CONSUMER'; 
            mainSettings.MSD_CORE_Prod_Complaint_Closed_Rec_Type__c = 'Product_Complaint_Closed_MVN';
            mainSettings.MSD_CORE_Request_Closed_Record_Type__c = 'Request_Closed_MVN'; 
            mainSettings.MSD_CORE_Adverse_Event_Closed_Rec_Type__c = 'Adverse_Event_Closed_MVN';
            mainSettings.MSD_CORE_Compensation_Req_Record_Type__c = 'MSD_CORE_Compensation_Request';
            mainSettings.MSD_CORE_Temp_Excursion_Record_Type__c = 'MSD_CORE_Temperature_Excursion';
            mainSettings.MSD_CORE_Temp_Not_Supported_Outcome__c = 'Not Supported';
            mainSettings.MSD_CORE_Default_to_Business_Search__c ='MSD_CORE Contact Center - MVCC Agent';
            mainSettings.MSD_CORE_AEPQC_Note_Filter__c = 'PQC Details for Case #,AE Details for Case #';
            mainSettings.MSD_CORE_Submitted_Status__c = 'Submitted'; 
            mainSettings.MSD_CORE_Product_Comp_Submitted_Type__c = 'Adverse_Event_Closed_MVN, Product_Complaint_Closed_MVN, MSD_CORE_Product_Complaint_Submitted';
            mainSettings.MSD_CORE_Temp_Exc_Closed_Record_Type__c = 'MSD_CORE_Temperature_Excursion_Closed'; 
            mainSettings.MSD_CORE_Case_Origin_Email__c = 'Email';
            mainSettings.Cancelled_Status_MVN__c = 'Cancelled';
            mainSettings.MSD_CORE_Address_Country_Requires_State__c = 'US';
            mainSettings.MSD_CORE_Type_Has_Business_Address__c = 'INDIV HEALTHCARE PROF,HEALTHCARE BUSINESS PROF';
            mainSettings.MSD_CORE_SAP_ID_Type__c = SAP_ID_TYPE;
            mainSettings.MSD_CORE_DCR_Record_Types__c = 'HBP,HCP,Hospital_vod,Pharmacy_vod,Organization_vod';
            mainSettings.Consumer_Record_Type_MVN__c = 'CONSUMER_MVN';
            mainSettings.MSD_CORE_Social_Other_Provider__c = 'Other';
            mainSettings.MSD_CORE_Social_Facebook_Provider__c = 'Facebook';
            mainSettings.MSD_CORE_Social_Twitter_Provider__c = 'Twitter';
            mainSettings.MSD_CORE_Social_Other_Origin__c = 'Other Social Media';
            mainSettings.MSD_CORE_Social_Private_Message_Type__c = 'Private';
            mainSettings.MSD_CORE_Edit_Account_DCR_Record_Type__c = 'Account_vod';
            mainSettings.Combo_Case_Preview_Record_Type__c = 'Combo_Case_Preview';

            insert mainSettings;
        }

        if(typeMappingSettings == null){
            typeMappingSettings = new List<MSD_CORE_Type_To_Record_Type_Map__c>();
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = '1', MSD_CORE_Type_MVN__c = 'CONSUMER', MSD_CORE_Record_Type_MVN__c = 'Consumer_MVN', MSD_CORE_Is_Person_Type__c = true));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = '2', MSD_CORE_Type_MVN__c = 'INDIV HEALTHCARE PROF', MSD_CORE_Record_Type_MVN__c = 'HBP', MSD_CORE_Is_Person_Type__c = true));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = '3', MSD_CORE_Type_MVN__c = 'EMPLOYEE', MSD_CORE_Record_Type_MVN__c = 'Employee_MVN', MSD_CORE_Is_Person_Type__c = true));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = '4', MSD_CORE_Type_MVN__c = 'HEALTHCARE BUSINESS PROF', MSD_CORE_Record_Type_MVN__c = 'HBP', MSD_CORE_Is_Person_Type__c = true));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = 'Business 1', MSD_CORE_Type_MVN__c = 'BUSINESSES/EMPLOYERS', MSD_CORE_Record_Type_MVN__c = 'Organization_vod', MSD_CORE_Is_Person_Type__c = false));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = 'Business 2', MSD_CORE_Type_MVN__c = 'CONTRACTING AGENT', MSD_CORE_Record_Type_MVN__c = 'Organization_vod', MSD_CORE_Is_Person_Type__c = false));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = 'Business 3', MSD_CORE_Type_MVN__c = 'DISTRIBUTOR', MSD_CORE_Record_Type_MVN__c = 'Organization_vod', MSD_CORE_Is_Person_Type__c = false));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = 'Business 4', MSD_CORE_Type_MVN__c = 'HOSPITAL', MSD_CORE_Record_Type_MVN__c = 'Hospital_vod', MSD_CORE_Is_Person_Type__c = false));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = 'Business 5', MSD_CORE_Type_MVN__c = 'LONG-TERM CARE', MSD_CORE_Record_Type_MVN__c = 'Organization_vod', MSD_CORE_Is_Person_Type__c = false));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = 'Business 6', MSD_CORE_Type_MVN__c = 'MANAGED CARE ORG', MSD_CORE_Record_Type_MVN__c = 'Organization_vod', MSD_CORE_Is_Person_Type__c = false));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = 'Business 7', MSD_CORE_Type_MVN__c = 'MISCELLANEOUS', MSD_CORE_Record_Type_MVN__c = 'Organization_vod', MSD_CORE_Is_Person_Type__c = false));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = 'Business 8', MSD_CORE_Type_MVN__c = 'NON-INSTIT HLTH CARE SVC', MSD_CORE_Record_Type_MVN__c = 'Organization_vod', MSD_CORE_Is_Person_Type__c = false));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = 'Business 9', MSD_CORE_Type_MVN__c = 'OUTPATIENT MEDICAL FCLTY', MSD_CORE_Record_Type_MVN__c = 'Organization_vod', MSD_CORE_Is_Person_Type__c = false));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(
                Name = 'Business 10', MSD_CORE_Type_MVN__c = 'PHARMACY', MSD_CORE_Record_Type_MVN__c = 'Pharmacy_vod', MSD_CORE_Is_Person_Type__c = false));
            typeMappingSettings.add(new MSD_CORE_Type_To_Record_Type_Map__c(

                Name = 'Business 11', MSD_CORE_Type_MVN__c = 'PUBLIC SERVICE', MSD_CORE_Record_Type_MVN__c = 'Organization_vod', MSD_CORE_Is_Person_Type__c = false));

            upsert typeMappingSettings;
        }

        List<Case_Document_Fields_MVN__c> documentFields = new List<Case_Document_Fields_MVN__c>();
        documentFields.add(new Case_Document_Fields_MVN__c(
            Name = 'General - After Call Instructions',
            Case_Document_Field_MVN__c = 'MSD_CORE_After_Call_Instructions__c',
            Document_Field_MVN__c = 'MSD_CORE_After_Call_Instructions__c',
            Document_Type_MVN__c = 'General_MVN__kav'));
        documentFields.add(new Case_Document_Fields_MVN__c(
            Name = 'General - Category',
            Case_Document_Field_MVN__c = 'MSD_CORE_Category__c',
            Document_Field_MVN__c = 'MSD_CORE_Category__c',
            Document_Type_MVN__c = 'General_MVN__kav'));
        documentFields.add(new Case_Document_Fields_MVN__c(
            Name = 'General - Country',
            Case_Document_Field_MVN__c = 'Country_MVN__c',
            Document_Field_MVN__c = 'MSD_CORE_Country__c',
            Document_Type_MVN__c = 'General_MVN__kav'));
        documentFields.add(new Case_Document_Fields_MVN__c(
            Name = 'General - Customer Type',
            Case_Document_Field_MVN__c = 'MSD_CORE_Customer_Type__c',
            Document_Field_MVN__c = 'MSD_CORE_Customer_Type__c',
            Document_Type_MVN__c = 'General_MVN__kav'));
        documentFields.add(new Case_Document_Fields_MVN__c(
            Name = 'General - Demographics Required',
            Case_Document_Field_MVN__c = 'MSD_CORE_Demographics_Required__c',
            Document_Field_MVN__c = 'MSD_CORE_Demographics_Required__c',
            Document_Type_MVN__c = 'General_MVN__kav'));
        documentFields.add(new Case_Document_Fields_MVN__c(
            Name = 'General - Disclaimer',
            Case_Document_Field_MVN__c = 'MSD_CORE_Disclaimer__c',
            Document_Field_MVN__c = 'MSD_CORE_Disclaimer__c',
            Document_Type_MVN__c = 'General_MVN__kav'));
        documentFields.add(new Case_Document_Fields_MVN__c(
            Name = 'General - Document Preview',
            Case_Document_Field_MVN__c = 'MSD_CORE_Document_Preview__c',
            Document_Field_MVN__c = 'Preview_MVN__c',
            Document_Type_MVN__c = 'General_MVN__kav'));
        documentFields.add(new Case_Document_Fields_MVN__c(
            Name = 'General - Instructions/Answer',
            Case_Document_Field_MVN__c = 'MSD_CORE_Instructions_Answer__c',
            Document_Field_MVN__c = 'MSD_CORE_Instructions_Answer__c',
            Document_Type_MVN__c = 'General_MVN__kav'));
        documentFields.add(new Case_Document_Fields_MVN__c(
            Name = 'General - Product Id',
            Case_Document_Field_MVN__c = 'Product_ID_MVN__c',
            Document_Field_MVN__c = 'Product_ID_MVN__c',
            Document_Type_MVN__c = 'General_MVN__kav'));
        documentFields.add(new Case_Document_Fields_MVN__c(
            Name = 'General - Questions',
            Case_Document_Field_MVN__c = 'MSD_CORE_Questions__c',
            Document_Field_MVN__c = 'MSD_CORE_Questions__c',
            Document_Type_MVN__c = 'General_MVN__kav'));
        documentFields.add(new Case_Document_Fields_MVN__c(
            Name = 'General - Subtype',
            Case_Document_Field_MVN__c = 'Document_Subtype_MVN__c',
            Document_Field_MVN__c = 'MSD_CORE_Subtype__c',
            Document_Type_MVN__c = 'General_MVN__kav'));
        insert documentFields;
        
        List<MSD_CORE_Interaction_Log_Comp_Visibility__c> interactonVisibility = MSD_CORE_Interaction_Log_Comp_Visibility__c.getall().values(); 
        if(interactonVisibility.size() == 0) {
            MSD_CORE_Interaction_Log_Comp_Visibility__c setting = new MSD_CORE_Interaction_Log_Comp_Visibility__c(); 
            setting.Name = 'aeButton';
            setting.MSD_CORE_Profile_Visibility__c = 'System Administrator'; 
            insert setting; 

            setting = new MSD_CORE_Interaction_Log_Comp_Visibility__c(); 
            setting.Name = 'crButton';
            setting.MSD_CORE_Profile_Visibility__c = 'System Administrator'; 
            insert setting;

            setting = new MSD_CORE_Interaction_Log_Comp_Visibility__c(); 
            setting.Name = 'notesField';
            setting.MSD_CORE_Profile_Visibility__c = 'System Administrator'; 
            insert setting;

            setting = new MSD_CORE_Interaction_Log_Comp_Visibility__c(); 
            setting.Name = 'pqcButton';
            setting.MSD_CORE_Profile_Visibility__c = 'System Administrator'; 
            insert setting;

            setting = new MSD_CORE_Interaction_Log_Comp_Visibility__c(); 
            setting.Name = 'teButton';
            setting.MSD_CORE_Profile_Visibility__c = 'System Administrator'; 
            insert setting;
        }


        MSD_CORE_DCR_Service_Layer_Settings__c dsls = 
                                                    new MSD_CORE_DCR_Service_Layer_Settings__c(
                                                            Name = 'Main', 
                                                            MSD_CORE_HCP_Account_GDGS_Steward_Fields__c = 'Class_of_Trade_Sub_MRK__c,IMS_Sub_Specialty_MRK__c', 
                                                            MSD_CORE_Org_Address_GDGS_Steward_Fields__c = 'Name,Address_line_2_vod__c,Address_Line_3_MRK__c,City_vod__c,Zip_vod__c'
                                                    );
        insert dsls; 
 
        if(accountFieldsToStampSettings == null){
            accountFieldsToStampSettings = new List<MSD_CORE_Account_Fields_To_Stamp_Map__c>();
            accountFieldsToStampSettings.add(new MSD_CORE_Account_Fields_To_Stamp_Map__c(
                Name = 'Preferred_Last_Name_MRK__c',
                MSD_CORE_Target_Field__c = 'LastName',
                MSD_CORE_Is_Person__c = true));
            accountFieldsToStampSettings.add(new MSD_CORE_Account_Fields_To_Stamp_Map__c(
                Name = 'Preferred_First_Name_MRK__c',
                MSD_CORE_Target_Field__c = 'FirstName',
                MSD_CORE_Is_Person__c = true));
            accountFieldsToStampSettings.add(new MSD_CORE_Account_Fields_To_Stamp_Map__c(
                Name = 'Preferred_Full_Name_MRK__c',
                MSD_CORE_Target_Field__c = 'Name',
                MSD_CORE_Is_Person__c = false));
        }
        insert accountFieldsToStampSettings;

        Case_Document_Fields_MVN__c caseDocumentFields = new Case_Document_Fields_MVN__c();
        caseDocumentFields.name = '1';
        caseDocumentFields.Case_Document_Field_MVN__c = 'Document_Summary_MVN__c';
        caseDocumentFields.Document_Field_MVN__c = 'summary__v';
        insert caseDocumentFields;

        List<Vault_Value_Mapping_MVN__c> mapping = new List<Vault_Value_Mapping_MVN__c>();

        Vault_Value_Mapping_MVN__c language = new Vault_Value_Mapping_MVN__c();
        language.name = '2';
        language.SFDC_Value_MVN__c = 'en_US';
        language.Vault_Value_MVN__c = 'English';

        mapping.add(language);

        insert mapping;
    }

    public static Fulfillment_MVN__c createTestFulfillment(Id accountId, Id caseId){
        Fulfillment_MVN__c fulfillment = new Fulfillment_MVN__c();
        fulfillment.Account_Name_MVN__c = accountId;
        fulfillment.Case_MVN__c = caseId;
        fulfillment.RecordTypeId = fulfillmentRecordTypeId;
        insert fulfillment;

        return fulfillment;
    }

    public static Fulfillment_MVN__c createClosedTestFulfillment(Id accountId, Id caseId){
        Fulfillment_MVN__c fulfillment = new Fulfillment_MVN__c();
        fulfillment.Account_Name_MVN__c = accountId;
        fulfillment.Case_MVN__c = caseId;
        fulfillment.RecordTypeId = fulfillmentRecordTypeId;
        fulfillment.Status_MVN__c = 'Closed';
        insert fulfillment;

        return fulfillment;
    }

    public static Product_vod__c createProduct(){
        return (createProduct('test_external_id'));
    }

    public static Product_vod__c createProduct(String externalId){
        Product_vod__c product = new Product_vod__c(
            Name='Test Product', 
            Product_Type_vod__c = 'Family', 
            External_Id_vod__c = externalId, 
            Active_MRK__c = true);

        database.upsert(product, true);

        return product;
    }

    public static List<MSD_CORE_NAW_Field_Types__c> createDCRFieldTypes(){

        List<MSD_CORE_NAW_Field_Types__c> insertList = new List<MSD_CORE_NAW_Field_Types__c>(); 
        insertList.add(new MSD_CORE_NAW_Field_Types__c());
        insertList.get(0).Field_API_Name__c = 'FirstName';
        insertList.get(0).Record_Type__c = mainSettings.HCP_Record_Type_MVN__c;
        insertList.get(0).Object_API_Name__c = 'Account';
        insertList.get(0).Required__c = true;
        insertList.get(0).Active__c = true;
        insertList.get(0).Profile__c = 'Systemadministrator';
        insertList.get(0).Country_Code__c = 'us';
        insertList.get(0).DCR__c = true;
        insertList.get(0).External_Id__c = 'MRK_REL60_00001';

        insertList.add(new MSD_CORE_NAW_Field_Types__c());
        insertList.get(1).Field_API_Name__c = 'Name';
        insertList.get(1).Record_Type__c = mainSettings.HCP_Record_Type_MVN__c;
        insertList.get(1).Object_API_Name__c = 'Address_vod__c';
        insertList.get(1).Required__c = true;
        insertList.get(1).Active__c = true;
        insertList.get(1).Profile__c = 'Systemadministrator';
        insertList.get(1).Country_Code__c = 'us';
        insertList.get(1).DCR__c = true; 
        insertList.get(1).External_Id__c = 'MRK_REL60_00002';

        insertList.add(new MSD_CORE_NAW_Field_Types__c());
        insertList.get(2).Field_API_Name__c = 'Status_MRK__c';
        insertList.get(2).Record_Type__c = mainSettings.HCP_Record_Type_MVN__c;
        insertList.get(2).Object_API_Name__c = 'Account';
        insertList.get(2).Required__c = false;
        insertList.get(2).Active__c = true;
        insertList.get(2).Profile__c = 'Systemadministrator';
        insertList.get(2).Country_Code__c = 'us';
        insertList.get(2).DCR__c = false;
        insertList.get(2).External_Id__c = 'MRK_REL60_00003';

        insertList.add(new MSD_CORE_NAW_Field_Types__c());
        insertList.get(3).Field_API_Name__c = 'Merck_ID_MRK__c';
        insertList.get(3).Record_Type__c = mainSettings.HCP_Record_Type_MVN__c;
        insertList.get(3).Object_API_Name__c = 'Account';
        insertList.get(3).Required__c = false;
        insertList.get(3).Active__c = true;
        insertList.get(3).Profile__c = 'Systemadministrator';
        insertList.get(3).Country_Code__c = 'us';
        insertList.get(3).DCR__c = false;
        insertList.get(3).External_Id__c = 'MRK_REL60_00004';

        insertList.add(new MSD_CORE_NAW_Field_Types__c());
        insertList.get(4).Field_API_Name__c = 'RecordTypeId';
        insertList.get(4).Record_Type__c = mainSettings.HCP_Record_Type_MVN__c;
        insertList.get(4).Object_API_Name__c = 'Account';
        insertList.get(4).Required__c = false;
        insertList.get(4).Active__c = true;
        insertList.get(4).Profile__c = 'Systemadministrator';
        insertList.get(4).Country_Code__c = 'us';
        insertList.get(4).DCR__c = false;
        insertList.get(4).External_Id__c = 'MRK_REL60_00005';

        insert insertList;

        return insertList;
    }

    public static List<MSD_CORE_DCRService_DCR__c> createDCRServices(){
        List<MSD_CORE_DCRService_DCR__c> dcrServices = new List<MSD_CORE_DCRService_DCR__c>();

        MSD_CORE_DCRService_DCR__c dcrServicePrime = new MSD_CORE_DCRService_DCR__c();
        dcrServicePrime.MSD_CORE_Active__c = true;
        dcrServicePrime.MSD_CORE_Country_Code__c = 'US';
        dcrServicePrime.MSD_CORE_DCR_Status__c = 'Submitted_vod';
        dcrServicePrime.MSD_CORE_DCR_User_Status__c = 'Submitted';
        dcrServicePrime.MSD_CORE_Object__c = 'Account';
        dcrServicePrime.MSD_CORE_Type__c = 'New_vod';
        dcrServicePrime.MSD_CORE_External_Id__c = 'DCRS002';
        dcrServicePrime.MSD_CORE_Object_Record_Type_Name__c = 'Hospital_vod';
        dcrServices.add(dcrServicePrime);

        MSD_CORE_DCRService_DCR__c dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS004';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'Organization_vod';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS016';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'HCP';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS003';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'Pharmacy_vod';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS013';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'HBP';
        dcrService.MSD_CORE_DCR_User_Status__c = 'Pre-Approved';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS012';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'Pharmacy_vod';
        dcrService.MSD_CORE_Object__c = 'Address_vod__c';
        dcrService.MSD_CORE_Type__c = 'New_Standalone';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS011';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'Hospital_vod';
        dcrService.MSD_CORE_Object__c = 'Address_vod__c';
        dcrService.MSD_CORE_Type__c = 'New_Standalone';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS009';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'Organization_vod';
        dcrService.MSD_CORE_Object__c = 'Address_vod__c';
        dcrService.MSD_CORE_Type__c = 'New_Standalone';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS007';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'Hospital_vod';
        dcrService.MSD_CORE_Object__c = 'Address_vod__c';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS006';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'Organization_vod';
        dcrService.MSD_CORE_Object__c = 'Address_vod__c';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS005';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'HCP';
        dcrService.MSD_CORE_Object__c = 'Address_vod__c';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS008';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'Pharmacy_vod';
        dcrService.MSD_CORE_Object__c = 'Address_vod__c';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS015';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'HCP';
        dcrService.MSD_CORE_Object__c = 'Address_vod__c';
        dcrService.MSD_CORE_Type__c = 'New_Standalone';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS014';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'HBP';
        dcrService.MSD_CORE_Object__c = 'Address_vod__c';
        dcrService.MSD_CORE_DCR_User_Status__c = 'Pre-Approved';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS010';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = 'HBP';
        dcrService.MSD_CORE_Object__c = 'Address_vod__c';
        dcrService.MSD_CORE_DCR_User_Status__c = 'Pre-Approved';
        dcrService.MSD_CORE_Type__c = 'New_Standalone';
        dcrServices.add(dcrService);

        dcrService = dcrServicePrime.clone();
        dcrService.MSD_CORE_External_Id__c = 'DCRS001';
        dcrService.MSD_CORE_Object_Record_Type_Name__c = '';
        dcrService.MSD_CORE_Object__c = 'Child_Account_vod__c';
        dcrService.MSD_CORE_DCR_User_Status__c = 'Pre-Approved';
        dcrService.MSD_CORE_Type__c = 'New_vod';
        dcrServices.add(dcrService);

        insert dcrServices;

        return dcrServices;
    }
}