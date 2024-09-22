//This is a test class.
@isTest
public class MSD_CORE_AE_Contact_RecordTest {
    public static Account testAccount =  new Account();
    public static Case testCase = new Case();
    public static List<Case> testCaseList = new List<Case>();
    public static Service_Cloud_Settings_MVN__c mainSettings = new Service_Cloud_Settings_MVN__c();
    static {
        //TestDataFactoryMVN.createSettings(true);
        Service_Cloud_Settings_MVN__c mainSettings = new Service_Cloud_Settings_MVN__c();

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
            //mainSettings.MSD_CORE_SAP_ID_Type__c = SAP_ID_TYPE;
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
        
        
        testAccount = TestDataFactoryMVN.createTestHCP();
        
        testCase = TestDataFactoryMVN.createTestCase(null, false);        
    }
    
    @isTest static void testSearch()
    {
        Test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        MSD_CORE_AE_Contact_Record_Selector_Cont cntrl = new MSD_CORE_AE_Contact_Record_Selector_Cont();
        cntrl.cont = new MSD_CORE_AE_Case_Con_Search_Extension(sc);
        cntrl.getObjList();
        cntrl.runQuery();
        
        cntrl.contfirstName = 'Test';
        cntrl.contlastName = 'Account';
        cntrl.contPhone = '5555555555';
        cntrl.contType = 'CONSUMER';
        cntrl.runQuery();
        
        cntrl.contZip = '33433';
        cntrl.runQuery();
        
        Map<String, Object> m = new Map<String, Object>();
        m.put('First Name', 'Test');
        m.put('Last Name', 'Account');
        m.put('Phone', '5555555555');
        //m.put('City', 'sd');
        //m.put('Zip', 'sd');
        MSD_CORE_AE_Contact_Record_Selector_Cont.runQueryOnAddressLtg(JSON.serialize(m), 'CONSUMER');
        
        MSD_CORE_AE_Contact_Record_Selector_Cont.runQueryOnAccountLtg(JSON.serialize(m), 'CONSUMER');
        
        List<MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper> wList = new List<MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper>();
        MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper w = new MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper();
        w.include = true;
        wList.add(w);
        
        MSD_CORE_AE_Contact_Record_Selector_Cont.createCaseContacts(JSON.serialize(wList), testCase.Id);
        
        Test.stopTest();
    }
    
    @isTest static void testSearchEMPLOYEE()
    {
        Test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        MSD_CORE_AE_Contact_Record_Selector_Cont cntrl = new MSD_CORE_AE_Contact_Record_Selector_Cont();
        cntrl.cont = new MSD_CORE_AE_Case_Con_Search_Extension(sc);
        cntrl.getObjList();
        cntrl.runQuery();
        
        cntrl.contfirstName = 'Test';
        cntrl.contlastName = 'Account';
        cntrl.contPhone = '5555555555';
        cntrl.contType = 'EMPLOYEE';
        cntrl.runQuery();
        
        cntrl.contZip = '33433';
        cntrl.runQuery();
        
        Map<String, Object> m = new Map<String, Object>();
        m.put('First Name', 'Test');
        m.put('Last Name', 'Account');
        m.put('Phone', '5555555555');
        //m.put('City', 'sd');
        //m.put('Zip', 'sd');
        MSD_CORE_AE_Contact_Record_Selector_Cont.runQueryOnAddressLtg(JSON.serialize(m), 'EMPLOYEE');
        
        MSD_CORE_AE_Contact_Record_Selector_Cont.runQueryOnAccountLtg(JSON.serialize(m), 'EMPLOYEE');
        
        List<MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper> wList = new List<MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper>();
        MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper w = new MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper();
        w.include = true;
        wList.add(w);
        
        MSD_CORE_AE_Contact_Record_Selector_Cont.createCaseContacts(JSON.serialize(wList), testCase.Id);
        
        Test.stopTest();
    }
    
    @isTest static void testSearchBUSINESS()
    {
        Test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        MSD_CORE_AE_Contact_Record_Selector_Cont cntrl = new MSD_CORE_AE_Contact_Record_Selector_Cont();
        cntrl.cont = new MSD_CORE_AE_Case_Con_Search_Extension(sc);
        cntrl.getObjList();
        cntrl.runQuery();
        
        cntrl.contfirstName = 'Test';
        cntrl.contlastName = 'Account';
        cntrl.contPhone = '5555555555';
        cntrl.contType = 'HEALTHCARE BUSINESS PROF';
        cntrl.runQuery();
        
        cntrl.contZip = '33433';
        cntrl.runQuery();
        
        Map<String, Object> m = new Map<String, Object>();
        m.put('First Name', 'Test');
        m.put('Last Name', 'Account');
        m.put('Phone', '5555555555');
        //m.put('City', 'sd');
        //m.put('Zip', 'sd');
        MSD_CORE_AE_Contact_Record_Selector_Cont.runQueryOnAddressLtg(JSON.serialize(m), 'HEALTHCARE BUSINESS PROF');
        
        MSD_CORE_AE_Contact_Record_Selector_Cont.runQueryOnAccountLtg(JSON.serialize(m), 'HEALTHCARE BUSINESS PROF');
        
        List<MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper> wList = new List<MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper>();
        MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper w = new MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper();
        w.include = true;
        wList.add(w);
        
        MSD_CORE_AE_Contact_Record_Selector_Cont.createCaseContacts(JSON.serialize(wList), testCase.Id);
        
        Test.stopTest();
    }
    
    @isTest static void testSearchHEALTHCARE()
    {
        Test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        MSD_CORE_AE_Contact_Record_Selector_Cont cntrl = new MSD_CORE_AE_Contact_Record_Selector_Cont();
        cntrl.cont = new MSD_CORE_AE_Case_Con_Search_Extension(sc);
        cntrl.getObjList();
        cntrl.runQuery();
        
        cntrl.contfirstName = 'Test';
        cntrl.contlastName = 'Account';
        cntrl.contPhone = '5555555555';
        cntrl.contType = 'INDIV HEALTHCARE PROF';
        cntrl.runQuery();
        
        cntrl.contZip = '33433';
        cntrl.runQuery();
        
        Map<String, Object> m = new Map<String, Object>();
        m.put('First Name', 'Test');
        m.put('Last Name', 'Account');
        m.put('Phone', '5555555555');
        //m.put('City', 'sd');
        //m.put('Zip', 'sd');
        MSD_CORE_AE_Contact_Record_Selector_Cont.runQueryOnAddressLtg(JSON.serialize(m), 'INDIV HEALTHCARE PROF');
        
        MSD_CORE_AE_Contact_Record_Selector_Cont.runQueryOnAccountLtg(JSON.serialize(m), 'INDIV HEALTHCARE PROF');
        
        List<MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper> wList = new List<MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper>();
        MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper w = new MSD_CORE_AE_Contact_Record_Selector_Cont.Wrapper();
        w.include = true;
        w.firstName = 'est';
        w.lastName = 'est';
        w.addressLine1 = 'est';
        w.city = 'est';
        w.state = 'est';
        w.zip = 'est';
        w.phone = 'est';
        wList.add(w);
        
        MSD_CORE_AE_Contact_Record_Selector_Cont.createCaseContacts(JSON.serialize(wList), testCase.Id);
        MSD_CORE_AE_Contact_Record_Selector_Cont.createNewLtg(JSON.serialize(m), testCase.Id);
        MSD_CORE_AE_Contact_Record_Selector_Cont.fillAddress(new Address_vod__c(), new Account());
        MSD_CORE_AE_Contact_Record_Selector_Cont.fillAddress(new Address_vod__c());
        Test.stopTest();
    }
}