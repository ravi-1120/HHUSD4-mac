/*
* MSD_CORE_DCRUtility
* Created By:    Samuel Rosen
* Created Date:  6/20/2015
* Description:   This is the test class for the MSD_CORE_DCRUtility class
*/
@isTest
private class MSD_CORE_DCRUtilityTest {
    private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static Account testAccount; 
    private static Address_vod__c testAddress; 
    private static User callCenterUser;
    private static Id hcpRecordType;

    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();
        hcpRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = :settings.HCP_Record_Type_MVN__c].Id;

        testAccount = new Account(); 
        testAccount.RecordTypeId = hcpRecordType; 
        testAccount.FirstName = 'Paul';
        testAccount.LastName = 'Jones';
        testAccount.Preferred_First_Name_MRK__c = 'Paul';
        testAccount.Preferred_Last_Name_MRK__c = 'Jones';
        testAccount.Class_of_Trade_MRK__c = 'tools';
        insert testAccount; 

        testAddress = new Address_vod__c(); 
        testAddress.Name = 'Random Road';
        testAddress.Address_line_2_vod__c = '15';
        testAddress.City_vod__c = 'Chicago';
        testAddress.State_vod__c = 'IL';
        testAddress.Country_vod__c = 'US'; 
        testAddress.Account_vod__c = testAccount.Id; 
        insert testAddress;

        Profile p = [select Id from Profile where Name='System Administrator'];
        callCenterUser = new User(Alias = 'mrtest', Email='mrtest@example.com',
                        EmailEncodingKey='UTF-8', FirstName = 'mr', LastName='test', LanguageLocaleKey='de',
                        LocaleSidKey='de', ProfileId = p.Id, MSD_CORE_Country_Code__c = 'us',
                        TimeZoneSidKey='Europe/Berlin', UserName='mrtest@merk.com');
        insert callCenterUser;

        TestDataFactoryMVN.createDCRFieldTypes();
        TestDataFactoryMVN.createDCRServices();
    }

    @isTest static void createDCRWithNewAccountAndAddress() {
        Test.startTest();
        System.runAs(callCenterUser){
            MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(testAccount, testAddress);
        }
        Test.stopTest();

        testAccount = [SELECT Status_MRK__c, Status_Reason_MRK__c FROM Account WHERE Id = :testAccount.Id];
        testAddress = [SELECT Inactive_vod__c FROM Address_vod__c WHERE Id = :testAddress.Id];

        System.assertEquals(true, testAddress.Inactive_vod__c);
        System.assertEquals(settings.MSD_CORE_Account_Status_Pending__c, testAccount.Status_MRK__c);


    }

    @isTest static void createDCRWithNewAddressOnly() {
        Address_vod__c testAddress2 = testAddress.clone(false, true, false, false);
        insert testAddress2;
        Test.startTest();
        System.runAs(callCenterUser){
            MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(testAccount, testAddress);
            MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(testAccount, testAddress2);
        }
        Test.stopTest();

        testAccount = [SELECT Status_MRK__c, Status_Reason_MRK__c FROM Account WHERE Id = :testAccount.Id];
        testAddress = [SELECT Inactive_vod__c FROM Address_vod__c WHERE Id = :testAddress.Id];
        testAddress2 = [SELECT Inactive_vod__c FROM Address_vod__c WHERE Id = :testAddress2.Id];

        System.assertEquals(true, testAddress.Inactive_vod__c);
        System.assertEquals(true, testAddress2.Inactive_vod__c);
        System.assertEquals(settings.MSD_CORE_Account_Status_Pending__c, testAccount.Status_MRK__c);
        

    }

    @isTest static void createDCRWithNewAccountOnly() {
        Test.startTest();
        System.runAs(callCenterUser){
            MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(testAccount, null);
        }
        Test.stopTest();

        testAccount = [SELECT Status_MRK__c, Status_Reason_MRK__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(settings.MSD_CORE_Account_Status_Need_More_Info__c, testAccount.Status_MRK__c);


    }

    @isTest static void createDCRWithUnqualifiedAccount() {
        callCenterUser.MSD_CORE_Country_Code__c = 'de'; 
        update callCenterUser;
        Test.startTest();
        System.runAs(callCenterUser){
            MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(testAccount, testAddress);
        }
        Test.stopTest();

        testAccount = [SELECT Status_MRK__c, Status_Reason_MRK__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(settings.MSD_CORE_Account_Status_Need_More_Info__c, testAccount.Status_MRK__c);


    }

    @isTest static void createDCRWithUnqualifiedAddress() {
        MSD_CORE_NAW_Field_Types__c dcrField = new MSD_CORE_NAW_Field_Types__c();
        dcrField.Field_API_Name__c = 'Address_Line_3_MRK__c';
        dcrField.Record_Type__c = settings.HCP_Record_Type_MVN__c;
        dcrField.Object_API_Name__c = 'Address_vod__c';
        dcrField.Required__c = true;
        dcrField.Active__c = true;
        dcrField.DCR__c = true; 
        dcrField.Profile__c = 'Systemadministrator';
        dcrField.Country_Code__c = 'us';
        dcrField.External_Id__c = 'MRK_REL60_00012';
        insert dcrField;

        Test.startTest();
        System.runAs(callCenterUser){
            MSD_CORE_DCRUtility.checkAndSubmitNewRecordsToDCR(testAccount, testAddress);
        }
        Test.stopTest();

        testAccount = [SELECT Status_MRK__c, Status_Reason_MRK__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(settings.MSD_CORE_Account_Status_Need_More_Info__c, testAccount.Status_MRK__c);


    }

    @isTest static void createDCRForEditedAccount() {
        Test.startTest();
        System.runAs(callCenterUser){
            Map<String, String> updatedFieldsMap = new Map<String, String>(); 
            updatedFieldsMap.put('Preferred_First_Name_MRK__c', 'James');
            updatedFieldsMap.put('Preferred_Last_Name_MRK__c', 'Franko');
            MSD_CORE_DCRUtility.submitUpdatedAccount(testAccount, updatedFieldsMap);
        }
        Test.stopTest();

        Data_Change_Request_vod__c dcr = [SELECT MSD_CORE_Application_Source__c, Country_Mapping_vod__c, MSD_CORE_DCR_Status__c, (SELECT Field_API_Name_vod__c, New_Value_vod__c, Old_Value_vod__c FROM Data_Change_Request_Lines_vod__r ORDER BY Field_API_Name_vod__c) FROM Data_Change_Request_vod__c WHERE Account_vod__c =: testAccount.Id];

        System.assertNotEquals(null, dcr);
        System.assertEquals(2, dcr.Data_Change_Request_Lines_vod__r.size());
        System.assertEquals(settings.MSD_CORE_DCR_Application_Source__c, dcr.MSD_CORE_Application_Source__c);
        System.assertEquals('us', dcr.Country_Mapping_vod__c);
       

        System.assertEquals('Preferred_First_Name_MRK__c', dcr.Data_Change_Request_Lines_vod__r[0].Field_API_Name_vod__c);
        System.assertEquals('James', dcr.Data_Change_Request_Lines_vod__r[0].New_Value_vod__c);
        System.assertEquals(testAccount.Preferred_First_Name_MRK__c, dcr.Data_Change_Request_Lines_vod__r[0].Old_Value_vod__c);

        System.assertEquals('Preferred_Last_Name_MRK__c', dcr.Data_Change_Request_Lines_vod__r[1].Field_API_Name_vod__c);
        System.assertEquals('Franko', dcr.Data_Change_Request_Lines_vod__r[1].New_Value_vod__c);
        System.assertEquals(testAccount.Preferred_Last_Name_MRK__c, dcr.Data_Change_Request_Lines_vod__r[1].Old_Value_vod__c);
    }
}