/**
 * Component Name:      MSD_CORE_RegistrationControllerTest
 * Created By:          Focal CXM
 * @description:        Used for MSD_CORE_RegistrationController
 * Class Type:          Test
 */
@isTest
public class MSD_CORE_RegistrationControllerTest {
    
    /**
     * @description: Cover SavePassword method
     * @return; void
    */
    @isTest
    static void testSavePassword() {

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;
        
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c(
            MSD_CORE_Account__c = testAccount.Id,
            MSD_CORE_Status__c = 'In Progress',
            MSD_CORE_Email__c = 'test@example.com'
        );
        insert testEligibility;

        String result = MSD_CORE_RegistrationController.savePassword(testAccount.Id, 'testpassword');

        List<MSD_CORE_Eligibility__c> updatedEligibility = [
            SELECT MSD_CORE_Portal_User_Password__c, MSD_CORE_Status__c, MSD_CORE_Stage__c, MSD_CORE_Approver__c
            FROM MSD_CORE_Eligibility__c
            WHERE MSD_CORE_Account__c = :testAccount.Id
        ];
    }

    /**
     * @description: Cover SavePasswordElse method
     * @return; void
    */
    @isTest
    static void testSavePasswordElse() {

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Test.startTest();
        String result = MSD_CORE_RegistrationController.savePassword(testAccount.Id, 'testpassword');
        Test.stopTest();

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c(
            MSD_CORE_Account__c = testAccount.Id,
            MSD_CORE_Status__c = 'In Progress',
            MSD_CORE_Email__c = 'test@example.com'
        );
        insert testEligibility;
        
    }

    /**
     * @description: Cover testGetAccountDetail method
     * @return; void
    */
    @isTest
    static void testGetAccountDetail() {
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        Account testAccount = new Account(
            Name = 'Test Account',
            Preferred_Salutation_MRK__c = 'Mr.',
            Preferred_First_Name_MRK__c = 'John',
            Preferred_Last_Name_MRK__c = 'Doe',
            Preferred_Suffix_MRK__c = 'Jr.',
            IMS_Sub_Specialty_MRK__c = 'Test Specialty',
            MSD_CORE_IDS_Customer_Designation__c = 'Test Designation'
        );
        insert testAccount;


        Account result = MSD_CORE_RegistrationController.getAccountDetail(testAccount.Id);

        // Assert the expected results
        System.assertEquals(testAccount.Id, result.Id);
        System.assertEquals(testAccount.Preferred_Salutation_MRK__c, result.Preferred_Salutation_MRK__c);
        System.assertEquals(testAccount.Preferred_First_Name_MRK__c, result.Preferred_First_Name_MRK__c);
        System.assertEquals(testAccount.Preferred_Last_Name_MRK__c, result.Preferred_Last_Name_MRK__c);
        System.assertEquals(testAccount.Preferred_Suffix_MRK__c, result.Preferred_Suffix_MRK__c);
        System.assertEquals(testAccount.IMS_Sub_Specialty_MRK__c, result.IMS_Sub_Specialty_MRK__c);
        System.assertEquals(testAccount.MSD_CORE_IDS_Customer_Designation__c, result.MSD_CORE_IDS_Customer_Designation__c);
    }

    /**
     * @description: Cover GetOrganizationWithSearchKey method
     * @return; void
    */
    @isTest
    static void testGetOrganizationsWithSearchKey() {

        MSD_CORE_Organization__c org1 = new MSD_CORE_Organization__c(
            Name = 'Test Organization 1'
        );
        MSD_CORE_Organization__c org2 = new MSD_CORE_Organization__c(
            Name = 'Test Organization 2'
        );
        insert new List<MSD_CORE_Organization__c>{org1, org2};

        List<MSD_CORE_Organization__c> result = MSD_CORE_RegistrationController.getOrganizations('Test');
    }

    /**
     * @description: Cover GetOrganizationsWithoutSearchKey method
     * @return; void
    */
    @isTest
    static void testGetOrganizationsWithoutSearchKey() {

        MSD_CORE_Organization__c org1 = new MSD_CORE_Organization__c(
            Name = 'Test Organization 1'
        );
        MSD_CORE_Organization__c org2 = new MSD_CORE_Organization__c(
            Name = 'Test Organization 2'
        );
        insert new List<MSD_CORE_Organization__c>{org1, org2};

        List<MSD_CORE_Organization__c> result = MSD_CORE_RegistrationController.getOrganizations('');
    }

    /**
     * @description: Cover testGetPicklistValue method
     * @return; void
    */
    @isTest
    static void testGetPicklistValue() {

        List<String> result = MSD_CORE_RegistrationController.getPicklistValue('Account', 'Salutation');

        System.assertNotEquals(null, result);
        System.assertNotEquals(0, result.size());
    }

    /**
     * @description: Cover SubmitEligibility method
     * @return; void
    */
    @isTest
    static void testSubmitEligibility() {

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Account__c = testAccount.Id;
        testEligibility.MSD_CORE_Status__c = 'In Progress';
        testEligibility.MSD_CORE_Organization_Street_1__c = 'Test Street 1';
        testEligibility.MSD_CORE_Organization_Street_2__c = 'Test Street 2';
        testEligibility.MSD_CORE_Organization_City__c = 'Test City';
        testEligibility.MSD_CORE_Organization_ZIP__c = '12345';
        testEligibility.MSD_CORE_Organization_Phone__c = '1234567890';
        testEligibility.MSD_CORE_Organization_Extension__c = '123';
        testEligibility.MSD_CORE_P_T_Process__c = true;
        testEligibility.MSD_CORE_Other_Role__c = 'Other Role';
        insert testEligibility;

        List<License__c> liclst = new List<License__c>();

        License__c lic = new License__c(
            Name = 'Test',
            MSD_CORE_License_Number__c = '123243546',
            MSD_CORE_Eligibility__c = testEligibility.Id
        );
        insert lic;

        License__c lic1 = new License__c(
            Name = 'Test 1',
            MSD_CORE_License_Number__c = '3245657',
            MSD_CORE_Eligibility__c = testEligibility.Id
        );
        insert lic1;

        List<License__c> testLicenses = [SELECT Name, MSD_CORE_License_Number__c, MSD_CORE_License_State__c, MSD_CORE_Type_of_license__c, MSD_CORE_Eligibility__c FROM License__c WHERE MSD_CORE_Eligibility__c = :testEligibility.Id];

        Map<String,Object> licensedata = new Map<String,Object>();
        licensedata.put('nameval', lic.Name);
        licensedata.put('numberval', lic.MSD_CORE_License_Number__c);
        
        Map<String,Object> licensedata1 = new Map<String,Object>();
        licensedata1.put('nameval', lic1.Name);
        licensedata1.put('numberval', lic1.MSD_CORE_License_Number__c);


        Map<String, Map<String, Object>> licmainwrap =  new Map<String, Map<String, Object>>();
        licmainwrap.put('1', licensedata);
        licmainwrap.put('2', licensedata1);

        String licensedatawrap = JSON.serialize(licmainwrap);

        String wrapData = '{"salutation": "Mr.", "firstname": "John", "lastname": "Doe", "suffix": "Jr.", "Specialty": "Test Specialty", "designation": "Test Designation"}';
        // String licensedata = '{"License1": {"nameval": "License 1", "numberval": "12345", "stateval": "Test State", "typeval": "Test Type"}, "License2": {"nameval": "License 2", "numberval": "67890", "stateval": "Test State", "typeval": "Test Type"}}';


        String result = MSD_CORE_RegistrationController.submitEligibility(testAccount.Id, wrapData, licensedatawrap);

        List<MSD_CORE_Eligibility__c> updatedEligibility = [
            SELECT MSD_CORE_Salutation__c, MSD_CORE_First_Name__c, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c,
                MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Status__c, MSD_CORE_Stage__c
            FROM MSD_CORE_Eligibility__c
            WHERE MSD_CORE_Account__c = :testAccount.Id
        ];

        List<License__c> createdLicenses = [
            SELECT Name, MSD_CORE_License_Number__c, MSD_CORE_License_State__c, MSD_CORE_Type_of_license__c, MSD_CORE_Eligibility__c
            FROM License__c
            WHERE MSD_CORE_Eligibility__c = :testEligibility.Id
        ];
    }

    /**
     * @description: Cover GetEligibilityDetails method
     * @return; void
    */
    @isTest
    static void testGetEligibilityDetails() {

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Account__c = testAccount.Id;
        testEligibility.MSD_CORE_Status__c = 'In Progress';
        testEligibility.MSD_CORE_Organization_Street_1__c = 'Test Street 1';
        testEligibility.MSD_CORE_Organization_Street_2__c = 'Test Street 2';
        testEligibility.MSD_CORE_Organization_City__c = 'Test City';
        testEligibility.MSD_CORE_Organization_ZIP__c = '12345';
        testEligibility.MSD_CORE_Organization_Phone__c = '1234567890';
        testEligibility.MSD_CORE_Organization_Extension__c = '123';
        testEligibility.MSD_CORE_P_T_Process__c = true;
        testEligibility.MSD_CORE_Role__c = 'Consultant';
        testEligibility.MSD_CORE_Healthcare_Professional__c = true;
        //testEligibility.MSD_CORE_Other_Role__c = 'Other Role';
        insert testEligibility;

        MSD_CORE_Related_Organizations__c testRelatedOrganization = new MSD_CORE_Related_Organizations__c(
            MSD_CORE_Email__c = 'test@example.com',
            MSD_CORE_Organization_Type__c = 'Test Organization Type'
        );
        insert testRelatedOrganization;

        MSD_CORE_Eligibility__c result = MSD_CORE_RegistrationController.getEligibilityDetails(testAccount.Id);

        // Assert the expected results
        System.assertNotEquals(null, result);
        System.assertEquals(testEligibility.MSD_CORE_Organization_Type__c, result.MSD_CORE_Organization_Type__c);
        System.assertEquals(testAccount.PersonEmail, result.MSD_CORE_Account__r.PersonEmail);
        System.assertEquals(testEligibility.MSD_CORE_Role__c, result.MSD_CORE_Role__c);
        System.assertEquals(testEligibility.MSD_CORE_Status__c, result.MSD_CORE_Status__c);
        System.assertEquals(testEligibility.MSD_CORE_Organization_Street_1__c, result.MSD_CORE_Organization_Street_1__c);
        System.assertEquals(testEligibility.MSD_CORE_Organization_Street_2__c, result.MSD_CORE_Organization_Street_2__c);
        System.assertEquals(testEligibility.MSD_CORE_Organization_City__c, result.MSD_CORE_Organization_City__c);
        System.assertEquals(testEligibility.MSD_CORE_Organization_ZIP__c, result.MSD_CORE_Organization_ZIP__c);
        System.assertEquals(testEligibility.MSD_CORE_Organization_Phone__c, result.MSD_CORE_Organization_Phone__c);
        System.assertEquals(testEligibility.MSD_CORE_Organization_Extension__c, result.MSD_CORE_Organization_Extension__c);
        System.assertEquals(testEligibility.MS_CORE_Organization_State_Code__c, result.MS_CORE_Organization_State_Code__c);
        System.assertEquals(testEligibility.MSD_CORE_P_T_Process__c, result.MSD_CORE_P_T_Process__c);
    }


    /**
     * @description: Cover SaveEligibility method
     * @return; void
    */
    @isTest
    static void testSaveEligibility() {

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        String accountId = testAccount.Id;

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Account__c = testAccount.Id;
        testEligibility.MSD_CORE_Other_Role__c = 'Test';
        testEligibility.MSD_CORE_Role__c = 'Consultant';
        testEligibility.MSD_CORE_P_T_Process__c = true;
        testEligibility.MSD_CORE_Status__c = 'In Progress';
        insert testEligibility;

        MSD_CORE_Organization__c organization = new MSD_CORE_Organization__c();
        organization.Name = 'Test Organization';
        insert organization;

        List<MSD_CORE_Related_Organizations__c> organizationlst = new List<MSD_CORE_Related_Organizations__c>();
        MSD_CORE_Related_Organizations__c org = new MSD_CORE_Related_Organizations__c();
        org.MSD_CORE_Eligibility__c = testEligibility.Id;
        org.MSD_CORE_Email__c = 'test@merck.com';
        org.MSD_CORE_Organization_Type__c = 'Academic institution or academic medical center';
        org.MSD_CORE_Organization__c = organization.Id;
        organizationlst.add(org);

        Map<String,Object> wrapData = new Map<String,Object>();
        Map<String,Object> wrapRelatedOrgData = new Map<String,Object>();
        wrapData.put('otherRole', testEligibility.MSD_CORE_Other_Role__c);
        wrapData.put('role', testEligibility.MSD_CORE_Role__c);
        wrapData.put('pt', testEligibility.Id);
        
        wrapData.put('orgname', organization.Name);
        wrapData.put('orgId',organization.Id);
        wrapData.put('healthdecisionmaker',true);
        
        
        wrapRelatedOrgData.put('diffemail',false );
        wrapRelatedOrgData.put('myemail',true);
            wrapRelatedOrgData.put('diffemailAddress','test@123.com');
            wrapRelatedOrgData.put('orgname' ,'test org');
            wrapRelatedOrgData.put('orgId' ,null);
            wrapRelatedOrgData.put('orgtype' ,'Academic institution or academic medical center');
            wrapRelatedOrgData.put('orgIdValid', false);
            wrapRelatedOrgData.put('orgtypeValid' , false);
            wrapRelatedOrgData.put('diffemailAddressValid',true);
            wrapRelatedOrgData.put('relatedOrgId', null);
        wrapData.put('relatedOrg', new List<object>{wrapRelatedOrgData});
        

        String wrapDataJson = JSON.serialize(wrapData);

        Test.startTest();
        String result = MSD_CORE_RegistrationController.saveEligibility(accountId, wrapDataJson);
        Test.stopTest();

        MSD_CORE_Eligibility__c eligibility = [SELECT Id, MSD_CORE_Account__c, MSD_CORE_Organization__c, MSD_CORE_Role__c, MSD_CORE_Status__c, MSD_CORE_Stage__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Account__c = :accountId];

        List<MSD_CORE_Related_Organizations__c> relatedOrgs = [SELECT Id, MSD_CORE_Eligibility__c, MSD_CORE_Organization__c FROM MSD_CORE_Related_Organizations__c WHERE MSD_CORE_Eligibility__c = :eligibility.Id];
    }
    
    /**
     * @description: Cover SaveEligibility method
     * @return; void
    */
    @isTest
    static void testSaveEligibility2() {

        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        String accountId = testAccount.Id;

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Account__c = testAccount.Id;
        testEligibility.MSD_CORE_Other_Role__c = 'Test';
        testEligibility.MSD_CORE_Role__c = 'Consultant';
        testEligibility.MSD_CORE_P_T_Process__c = true;
        testEligibility.MSD_CORE_Status__c = 'In Progress';
        insert testEligibility;

        MSD_CORE_Organization__c organization = new MSD_CORE_Organization__c();
        organization.Name = 'Test Organization';
        insert organization;

        List<MSD_CORE_Related_Organizations__c> organizationlst = new List<MSD_CORE_Related_Organizations__c>();
        MSD_CORE_Related_Organizations__c org = new MSD_CORE_Related_Organizations__c();
        org.MSD_CORE_Eligibility__c = testEligibility.Id;
        org.MSD_CORE_Email__c = 'test@merck.com';
        org.MSD_CORE_Organization_Type__c = 'Academic institution or academic medical center';
        org.MSD_CORE_Organization__c = organization.Id;
        organizationlst.add(org);

        Map<String,Object> wrapData = new Map<String,Object>();
        wrapData.put('otherRole', testEligibility.MSD_CORE_Other_Role__c);
        wrapData.put('role', testEligibility.MSD_CORE_Role__c);
        wrapData.put('pt', testEligibility.Id);
        wrapData.put('relatedOrg', organizationlst);
        wrapData.put('orgname', 'Test Org Name');
        wrapData.put('orgId', null);
        wrapData.put('diffemail',false );
        wrapData.put('myemail',true);
        wrapData.put('healthdecisionmaker',true);

        String wrapDataJson = JSON.serialize(wrapData);

        Test.startTest();
        String result = MSD_CORE_RegistrationController.saveEligibility(accountId, wrapDataJson);
        Test.stopTest();

        MSD_CORE_Eligibility__c eligibility = [SELECT Id, MSD_CORE_Account__c, MSD_CORE_Organization__c, MSD_CORE_Role__c, MSD_CORE_Status__c, MSD_CORE_Stage__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Account__c = :accountId];

        List<MSD_CORE_Related_Organizations__c> relatedOrgs = [SELECT Id, MSD_CORE_Eligibility__c, MSD_CORE_Organization__c FROM MSD_CORE_Related_Organizations__c WHERE MSD_CORE_Eligibility__c = :eligibility.Id];
    }


    /**
     * @description: Cover CheckExistingUser method
     * @return; void
    */
    @isTest
    static void testCheckExistingUser() {
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Account__c = testAccount.Id;
        insert testEligibility;

        MSD_CORE_RegistrationController.registrationwrap wrap = MSD_CORE_RegistrationController.checkExistingUser(testAccount.Id,true,true);

        System.assertNotEquals(null, wrap);
    }

    /**
     * @description: Cover createOTP method
     * @return; void
    */
    @isTest
    static void testcreateOTP() {
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Account__c = testAccount.Id;
        insert testEligibility;
        Decimal duration = [SELECT Id, Label, MSD_CORE_Duration__c FROM MFR_Config__mdt WHERE Label = 'OTP Expiration Duration'].MSD_CORE_Duration__c;
        
        MSD_CORE_OTP__c otp = new MSD_CORE_OTP__c();
        otp.MSD_CORE_Customer__c = testAccount.Id;
        otp.MSD_CORE_Expiration_DateTime__c = System.now().addMinutes(Integer.valueOf(duration));
        otp.MSD_CORE_Type__c = 'Self Registration';
        otp.MSD_CORE_Token__c = String.valueOf(Math.round((Math.random() * (900000) + 100000)));
        otp.MSD_CORE_Status__c = 'New';
        insert otp;

        String str = MSD_CORE_RegistrationController.createOTP(testAccount.Id);
    }

    /**
     * @description: Cover submitOTP method
     * @return; void
    */
    @isTest
    static void testsubmitOTP() {
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Account__c = testAccount.Id;
        insert testEligibility;
        Decimal duration = [SELECT Id, Label, MSD_CORE_Duration__c FROM MFR_Config__mdt WHERE Label = 'OTP Expiration Duration'].MSD_CORE_Duration__c;
        
        MSD_CORE_OTP__c otp = new MSD_CORE_OTP__c();
        otp.MSD_CORE_Customer__c = testAccount.Id;
        otp.MSD_CORE_Expiration_DateTime__c = System.now().addMinutes(Integer.valueOf(duration));
        otp.MSD_CORE_Type__c = 'Self Registration';
        otp.MSD_CORE_Token__c = String.valueOf(Math.round((Math.random() * (900000) + 100000)));
        otp.MSD_CORE_Status__c = 'New';
        insert otp;

        String str = MSD_CORE_RegistrationController.submitOTP(testAccount.Id,otp.MSD_CORE_Token__c);
    }

    /**
     * @description: Cover getEligibilityDetail method
     * @return; void
    */
    @isTest
    static void testgetEligibilityDetail() {
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Account__c = testAccount.Id;
        insert testEligibility;

        MSD_CORE_Eligibility__c ele = MSD_CORE_RegistrationController.getEligibilityDetail();
    }

    /**
     * @description: Cover updateResendInvitation method
     * @return; void
    */
    @isTest
    static void testupdateResendInvitation() {
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;

        Account testAccount = new Account(
            Name = 'Test Account',
            MSD_CORE_Resend_Invitation__c = true
        );
        insert testAccount;

        MSD_CORE_RegistrationController.updateResendInvitation(testAccount.Id);
    }
}