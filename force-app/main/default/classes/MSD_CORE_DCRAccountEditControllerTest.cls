/*
 * MSD_CORE_DCRAccountEditControllerTest
 * Created by: David Andrew Helmer
 * Created Date: July 10th, 2014
 * Last Modified Date: July 23rd, 2014
 * Description: These are tests for the MSD_CORE_DCRAccountEditController
 */

@isTest
private class MSD_CORE_DCRAccountEditControllerTest {
	private static Service_Cloud_Settings_MVN__c settings = new Service_Cloud_Settings_MVN__c();
    private static MSD_CORE_DCRAccountEditController controller;

    private static Account testAccount;
    private static Address_vod__c testAddress;
    private static User callCenterUser;

    private static MSD_CORE_NAW_Field_Types__c editableField;
    private static MSD_CORE_NAW_Field_Types__c dcrField;
    private static MSD_CORE_NAW_Field_Types__c readOnlyField;
    private static MSD_CORE_NAW_Field_Types__c requiredField;
    private static MSD_CORE_NAW_Field_Types__c wrongCountryField;
    private static MSD_CORE_NAW_Field_Types__c nullCountryField;
    private static MSD_CORE_NAW_Field_Types__c wrongProfileField;
    private static MSD_CORE_NAW_Field_Types__c contactCenterProfileField;
    private static MSD_CORE_NAW_Field_Types__c inactiveProfileField;
    private static MSD_CORE_NAW_Field_Types__c wrongObjectField; 
    private static MSD_CORE_NAW_Field_Types__c addressField;
    private static List<MSD_CORE_NAW_Field_Types__c> fieldTypeList;

    private static String SECTION1 = 'Account Information';
    private static String SECTION2 = 'Contact Information';

    private static String NEW_LAST_NAME = 'A new last name'; 
    private static String NEW_FIRST_NAME = 'A new first name';

    private static String ORIGINAL_FIRST_NAME = 'A First name';

    static {
        TestDataFactoryMVN.createSettings(true);
        settings = Service_Cloud_Settings_MVN__c.getInstance();

        initializeTestData();        
    }

    private static void initializeTestData(){
        Id hcpRecordType = [SELECT Id 
                              FROM RecordType 
                             WHERE DeveloperName = :settings.HCP_Record_Type_MVN__c].Id;
        Profile p = [select Id from Profile where Name='System Administrator'];

        testAccount = new Account(
            RecordTypeId = hcpRecordType,
            FirstName = ORIGINAL_FIRST_NAME,
            LastName = 'testlastname',
            Preferred_First_Name_MRK__c = ORIGINAL_FIRST_NAME,
            Preferred_Last_Name_MRK__c = 'testlastname',
            Class_Of_Trade_MRK__c = 'tools');

        testAddress = new Address_vod__c(
            Name = 'A random address',
            Address_Line_2_vod__c = 'Line 2 of the address',
            City_vod__c = 'Chicago',
            State_vod__c = 'IL',
            Country_vod__c = 'US');        

        callCenterUser = new User(Alias = 'mrtest', Email='mrtest@example.com',
                        EmailEncodingKey='UTF-8', FirstName = 'mr', LastName='test', LanguageLocaleKey='de',
                        LocaleSidKey='de', ProfileId = p.Id, MSD_CORE_Country_Code__c = 'us',
                        TimeZoneSidKey='Europe/Berlin', UserName='mrtest@merk.com');
        insert callCenterUser;

        initializeFieldTestData();
    }

    private static void initializeFieldTestData(){
        fieldTypeList = new List<MSD_CORE_NAW_Field_Types__c>();
        editableField = new MSD_CORE_NAW_Field_Types__c(
            Field_API_Name__c = 'Preferred_Last_Name_MRK__c',
            Record_Type__c = settings.HCP_Record_Type_MVN__c,
            Object_API_Name__c = 'Account',
            Required__c = true,
            Active__c = true,
            Profile__c = 'Systemadministrator',
            Country_Code__c = 'us',
            Page_Section__c = SECTION1,
            Display_Order__c = 101,
            DCR__c = false,
            Editable__c = true,
            Read_Only__c = false,
            External_Id__c = 'MRK_REL60_00001');
        fieldTypeList.add(editableField);

        dcrField = editableField.clone(false, false);
        dcrField.Field_API_Name__c = 'Preferred_First_Name_MRK__c';
        dcrField.Required__c = true;
        dcrField.DCR__c = true;
        dcrField.Editable__c = false;
        dcrField.Read_Only__c = false;
        dcrField.Display_Order__c = 102;
        dcrField.External_Id__c = 'MRK_REL60_00002';
        fieldTypeList.add(dcrField);

        readOnlyField = editableField.clone(false, false);
        readOnlyField.Field_API_Name__c = 'PersonEmail';
        readOnlyField.Required__c = false;
        readOnlyField.DCR__c = false;
        readOnlyField.Editable__c = false;
        readOnlyField.Read_Only__c = true;
        readOnlyField.Display_Order__c = 104;
        readOnlyField.External_Id__c = 'MRK_REL60_00003';
        fieldTypeList.add(readOnlyField);

        requiredField = editableField.clone(false, false);
        requiredField.Field_API_Name__c = 'Phone';
        requiredField.Required__c = true;
        requiredField.DCR__c = false;
        requiredField.Editable__c = true;
        requiredField.Read_Only__c = false;
        requiredField.Display_Order__c = 201;
        requiredField.External_Id__c = 'MRK_REL60_00004';
        fieldTypeList.add(requiredField);

        wrongCountryField = requiredField.clone(false, false);
        wrongCountryField.Country_Code__c = 'gb';
        wrongCountryField.External_Id__c = 'MRK_REL60_00005';
        fieldTypeList.add(wrongCountryField);

        nullCountryField = editableField.clone(false, false);
        nullCountryField.Field_API_Name__c = 'Preferred_Salutation_MRK__c';
        nullCountryField.Country_Code__c = null;        
        nullCountryField.Display_Order__c = 202;
        nullCountryField.External_Id__c = 'MRK_REL60_00006';
        fieldTypeList.add(nullCountryField);

        wrongProfileField = editableField.clone(false, false);
        wrongProfileField.Profile__c = 'Number one record in the WORLD';
        wrongProfileField.External_Id__c = 'MRK_REL60_00007';
        fieldTypeList.add(wrongProfileField);

        contactCenterProfileField = editableField.clone(false, false);
        contactCenterProfileField.Field_API_Name__c = 'PersonEmail';
        contactCenterProfileField.Profile__c = settings.MSD_CORE_Contact_Center_Profile_Prefix__c;      
        contactCenterProfileField.Display_Order__c = 0;
        contactCenterProfileField.Page_Section__c = SECTION2;
        contactCenterProfileField.External_Id__c = 'MRK_REL60_00008';
        fieldTypeList.add(contactCenterProfileField);

        addressField = editableField.clone(false, false);
        addressField.Field_API_Name__c = 'Name';
        addressField.Object_API_Name__c = 'Address_vod__c';
        addressField.Page_Section__c = null;
        addressField.External_Id__c = 'MRK_REL60_00009';

        fieldTypeList.add(addressField);

        insert fieldTypeList;
    }

    private static void insertTestAccountAddress(){
        insert testAccount;

        testAddress.Account_vod__c = testAccount.Id;
        insert testAddress;
    }

    private static void repOpensDCREdit() {
        insertTestAccountAddress();

        Test.startTest();
        System.runAs(callCenterUser){
            controller = new MSD_CORE_DCRAccountEditController(
                new ApexPages.StandardController(testAccount));
        }
        Test.stopTest();        
    }

    private static void everythingInTheRightPlace(){
        System.assertEquals(2, controller.dcrFieldsSectionMap.size(), 'Expecting 2 sections');
        System.assertEquals(7, controller.dcrFieldsSectionMap.get(SECTION1).size(), 
            'Section 1 should have 7 fields but has ' + String.join(getAllFieldNames(controller.dcrFieldsSectionMap.get(SECTION1)), ', '));
        System.assertEquals(2, controller.dcrFieldsSectionMap.get(SECTION2).size(), 
            'Section 2 should have 1 field but has ' + String.join(getAllFieldNames(controller.dcrFieldsSectionMap.get(SECTION2)), ', '));

        MSD_CORE_NAW_Field_Types__c fieldToAssert = controller.dcrFieldsSectionMap.get(SECTION1).get(0);
        System.assertEquals(editableField.Field_API_Name__c, fieldToAssert.Field_API_Name__c
            ,'101 is first');

        fieldToAssert = controller.dcrFieldsSectionMap.get(SECTION1).get(1);
        System.assertEquals(requiredField.Field_API_Name__c, fieldToAssert.Field_API_Name__c
            ,'201 is second');

        fieldToAssert = controller.dcrFieldsSectionMap.get(SECTION1).get(2);
        System.assertEquals(dcrField.Field_API_Name__c, fieldToAssert.Field_API_Name__c
            ,'102 is third');

        fieldToAssert = controller.dcrFieldsSectionMap.get(SECTION1).get(3);
        System.assertEquals(nullCountryField.Field_API_Name__c, fieldToAssert.Field_API_Name__c
            ,'202 is fourth');

        fieldToAssert = controller.dcrFieldsSectionMap.get(SECTION1).get(4);
        System.assertEquals(null, fieldToAssert.Field_API_Name__c,
            'Expected spacer field (none at 103)');

        fieldToAssert = controller.dcrFieldsSectionMap.get(SECTION1).get(5);
        System.assertEquals(null, fieldToAssert.Field_API_Name__c,
            'Expected spacer field (no more on "right")');

        fieldToAssert = controller.dcrFieldsSectionMap.get(SECTION1).get(6);
        System.assertEquals(readOnlyField.Field_API_Name__c, fieldToAssert.Field_API_Name__c
            ,'104 is seventh');

        fieldToAssert = controller.dcrFieldsSectionMap.get(SECTION2).get(1);
        System.assertEquals(contactCenterProfileField.Field_API_Name__c, fieldToAssert.Field_API_Name__c
            ,'Section 2 mapped');
    }

    private static List<String> getAllFieldNames(List<MSD_CORE_NAW_Field_Types__c> fields){
        List<String> fieldNames = new List<String>();

        for(MSD_CORE_NAW_Field_Types__c field : fields){
            fieldNames.add(field.Field_API_Name__c);
        }

        return fieldNames;
    }

	@isTest static void displaysTheCorrectFields() {
        // set up
        repOpensDCREdit();

        // check it
        everythingInTheRightPlace();
	}

    private static void repUpdatesEditableField() {
        controller.dcrAccount.put(editableField.Field_API_Name__c, NEW_LAST_NAME);
    }

    private static void repClicksSave() {
        controller.saveDCR();
    }

    private static void lastNameGotUpdated() {
        Account updatedAccount = [SELECT Id, LastName, Preferred_Last_Name_MRK__c FROM Account WHERE Id=:testAccount.Id LIMIT 1][0];
        System.assertEquals(NEW_LAST_NAME, updatedAccount.LastName);
        System.assertEquals(NEW_LAST_NAME, updatedAccount.Preferred_Last_Name_MRK__c);
    }

    private static void thereIsNoNewDCRWithLastName() {
        List<Data_Change_Request_vod__c> dcrList = [SELECT Id
                                                      FROM Data_Change_Request_vod__c
                                                     WHERE Id IN (SELECT Data_Change_Request_vod__c
                                                                    FROM Data_Change_Request_Line_vod__c
                                                                   WHERE Field_API_Name_vod__c = :editableField.Field_API_Name__c)
                                                       AND Account_vod__c = :testAccount.Id];
        System.assertEquals(0, dcrList.size(), 'Should be no LastName fields in Data_Change_Request_vod__c for testAccount');
    }
	
	@isTest static void editableFieldsSaveToAccount() {
		// set up
        repOpensDCREdit();
        repUpdatesEditableField();
        repClicksSave();

        // check it
        lastNameGotUpdated();
        thereIsNoNewDCRWithLastName();
	}

    private static void repUpdatesDCRField() {
        controller.dcrAccount.put(dcrField.Field_API_Name__c, NEW_FIRST_NAME);
    }

    private static void thereIsDCRWithWithFirstName (){
        List<Data_Change_Request_vod__c> dcrList = [SELECT Id,
                                                           (SELECT New_Value_vod__c,
                                                                   Old_Value_vod__c 
                                                              FROM Data_Change_Request_Lines_vod__r)
                                                      FROM Data_Change_Request_vod__c
                                                     WHERE Id IN (SELECT Data_Change_Request_vod__c
                                                                    FROM Data_Change_Request_Line_vod__c
                                                                   WHERE Field_API_Name_vod__c = :dcrField.Field_API_Name__c)
                                                       AND Account_vod__c = :testAccount.Id];
        System.assertEquals(1, dcrList.size(), 'Should be a Data_Change_Request_vod__c for testAccount');
        System.assertEquals(1, dcrList.get(0).Data_Change_Request_Lines_vod__r.size(), 'Should be a Data_Change_Request_Line_vod__c for testAccount');

        Data_Change_Request_Line_vod__c dcrLine = dcrList.get(0).Data_Change_Request_Lines_vod__r.get(0);

        System.assertEquals(ORIGINAL_FIRST_NAME, dcrLine.Old_Value_vod__c, 'Not saving the old value to DCR');
        System.assertEquals(NEW_FIRST_NAME, dcrLine.New_Value_vod__c, 'Not saving the new value to DCR');
    }
	
    @isTest static void dcrFieldsGoIntoDCR() {
        // set up
        repOpensDCREdit();
        repUpdatesEditableField();
        repUpdatesDCRField();
        repClicksSave();

        // check it        
        thereIsNoNewDCRWithLastName();
        thereIsDCRWithWithFirstName();
    }

    private static void allNonReadOnlyFieldsAreEditable(){

        System.assertEquals(true, controller.dcrFieldsSectionMap.get(SECTION1).get(0).Editable__c, 'editableField should be editable');
        System.assertEquals(false, controller.dcrFieldsSectionMap.get(SECTION1).get(0).DCR__c, 'editableField should not be a dcr field');

        System.assertEquals(true, controller.dcrFieldsSectionMap.get(SECTION1).get(1).Editable__c, 'requiredField should be editable');
        System.assertEquals(false, controller.dcrFieldsSectionMap.get(SECTION1).get(1).DCR__c, 'requiredField should not be a dcr field');

        System.assertEquals(true, controller.dcrFieldsSectionMap.get(SECTION1).get(2).Editable__c, 'dcrField should be editable');
        System.assertEquals(false, controller.dcrFieldsSectionMap.get(SECTION1).get(2).DCR__c, 'dcrField should not be a dcr field');

        System.assertEquals(true, controller.dcrFieldsSectionMap.get(SECTION1).get(3).Editable__c, 'nullCountryField should be editable');
        System.assertEquals(false, controller.dcrFieldsSectionMap.get(SECTION1).get(3).DCR__c, 'nullCountryField should not be a dcr field');

        System.assertEquals(true, controller.dcrFieldsSectionMap.get(SECTION1).get(6).Editable__c, 'readOnlyField should be editable');
        System.assertEquals(false,  controller.dcrFieldsSectionMap.get(SECTION1).get(6).DCR__c, 'readOnlyField should not be a dcr field');
        System.assertEquals(true, controller.dcrFieldsSectionMap.get(SECTION1).get(6).Read_Only__c, 'readOnlyField should still be readOnly');

        System.assertEquals(true, controller.dcrFieldsSectionMap.get(SECTION2).get(1).Editable__c, 'contactCenterProfileField should be editable');
        System.assertEquals(false, controller.dcrFieldsSectionMap.get(SECTION2).get(1).DCR__c, 'contactCenterProfileField should not be a dcr field');
    }

    @isTest static void allNonReadOnlyFieldsBecomeEditable() {
        // set up
        testAccount.Status_MRK__c = settings.MSD_CORE_Account_Status_Need_More_Info__c;
        repOpensDCREdit();
        repClicksSave();

        // check it
        allNonReadOnlyFieldsAreEditable();
    }

    private static void insertBadFieldName() {
        insert new MSD_CORE_NAW_Field_Types__c(
            Field_API_Name__c = 'kfjasdjhgbnaskjhb',
            Record_Type__c = settings.HCP_Record_Type_MVN__c,
            Object_API_Name__c = 'Account',
            Required__c = true,
            Active__c = true,
            Profile__c = 'Systemadministrator',
            Country_Code__c = 'us',
            Page_Section__c = SECTION1,
            Display_Order__c = 101,
            DCR__c = false,
            Editable__c = true,
            Read_Only__c = false,
            External_Id__c = 'MRK_REL60_00010');
    }

    private static void hasFatalError(){
        List<ApexPages.Message> messages = ApexPages.getMessages();

        System.assertEquals(1, messages.size());
        System.assertEquals(ApexPages.Severity.FATAL, messages.get(0).getSeverity());
    }

    @isTest static void showsErrorWhenBadFieldNameExists() {
        // set up
        insertBadFieldName();
        repOpensDCREdit();
        
        // check it
        hasFatalError();
    }

    @isTest static void handlesNoFields() {
        // set up
        delete fieldTypeList;
        repOpensDCREdit();

        // check it
        hasFatalError();
    }
}