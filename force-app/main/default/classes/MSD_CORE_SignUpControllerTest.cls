@isTest
public class MSD_CORE_SignUpControllerTest {
    @testSetup
    static void setupTestData() {
        // Create Custom Metadata Settings
        // CustomMetadataHelper.MetadataSettings metadataSettings = new CustomMetadataHelper.MetadataSettings();
        // metadataSettings.primaryExecutiveId = '0051t000000xxxx';
        // metadataSettings.medicalAEId = '0051t000000yyyy';
        // metadataSettings.oncologyAEId = '0051t000000zzzz';
        // insert metadataSettings;
        
        User user = new User(LastName = 'Userton',
                             FirstName='User',
                             Alias = 'usus',
                             Email = 'user.test@merck.com',
                             Username = Math.random() + '@' + Math.random(),
                             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
                             UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'System Administrator' LIMIT 1].Id,
                             TimeZoneSidKey = 'GMT',
                             LanguageLocaleKey = 'en_US',
                             EmailEncodingKey = 'UTF-8',
                             LocaleSidKey = 'en_US'
                            );
        insert user;
        
        
        
        System.runAs(user) {
            User userr = new User(
                FirstName='Test',
                LastName = 'User1234',
                Alias = 'ndebe',
                Email = 'test1234@merck.com',
                Username = 'test'+String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','')+'@merck.com',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'MRK - Account Exec'].Id,
                TimeZoneSidKey = 'GMT',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LocaleSidKey = 'en_US'
                // ContactId = conId
            );
            insert userr;
            
            // Create test data for MSD_CORE_Organization__c
            MSD_CORE_Organization__c org1 = new MSD_CORE_Organization__c(Name = 'Organization 1');
            MSD_CORE_Organization__c org2 = new MSD_CORE_Organization__c(Name = 'Organization 2');
            insert new List<MSD_CORE_Organization__c>{org1, org2};
            
            Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c(DATA_CHANGE_REQUEST_MODE_vod__c = 0);
            insert vsc;
            
            
            RecordType hcpRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'HCP' LIMIT 1];
            
            // Create test Account
            Account testAccount = new Account(
                FirstName = 'Test',
                LastName = 'User',
                PersonEmail = 'test.user@example.com',
                Phone = '1234567890',
                RecordTypeId = hcpRecordType.Id,
                MSD_CORE_Health_Care_Decision_Maker__pc = true,
                Primary_Executive__pc = userr.ID,
                MSD_CORE_Medical_AE__pc = userr.ID,
                MSD_CORE_Oncology_AE__pc = userr.ID,
                MSD_CORE_Created_outside_of_DCR_Process__c = null
            );
            insert testAccount;
            
            // Create test Eligibility record
            MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c(
                MSD_CORE_Account__c = testAccount.Id,
                MSD_CORE_First_Name__c = 'Test',
                MSD_CORE_Last_Name__c = 'User',
                MSD_CORE_Status__c = 'In Progress',
                MSD_CORE_Stage__c = 'Eligibility'
            );
            insert testEligibility;
        }
        // Create OTP Configuration
        // MFR_Config__mdt otpConfig = new MFR_Config__mdt(
        //     Label = 'OTP Expiration Duration',
        //     MSD_CORE_Duration__c = 10
        // );
        // insert otpConfig;
    }
    
    
    
    @isTest
    static void testGetOrganizations() {
        Test.startTest();
        List<MSD_CORE_Organization__c> orgs = MSD_CORE_SignUpController.getOrganizations('Organization');
        System.assertEquals(2, orgs.size(), 'Expected 2 organizations');
        
        orgs = MSD_CORE_SignUpController.getOrganizations('');
        System.assertEquals(2, orgs.size(), 'Expected 2 organizations ordered by Name');
        Test.stopTest();
    }
    
    @isTest
    static void testGetPicklistValue() {
        Test.startTest();
        List<String> picklistValues = MSD_CORE_SignUpController.getPicklistValue('Account', 'Industry');
        System.assertNotEquals(0, picklistValues.size(), 'Expected non-empty picklist values');
        Test.stopTest();
    }
    
    @isTest
    static void testGetRoles() {
        Test.startTest();
        List<MSD_CORE_SignUpController.PicklistOption> roles = MSD_CORE_SignUpController.getRoles();
        System.assertNotEquals(0, roles.size(), 'Expected non-empty roles');
        Test.stopTest();
    }
    
    @isTest
    static void testCreateEligibility() {
        Test.startTest();
        String data = '{"FirstName":"Test","LastName":"User","Email":"test.user@example.com","Phone":"1234567890","OrganizationType":"Health plan","Zip":"12345","WorkAddress":"123 Test St","Unit":"Apt 1","City":"Testville","State":"TS","Role":"Clinician / Physician","PleaseSpecify":""}';
        Map<Id, Boolean> result = MSD_CORE_SignUpController.createEligibility(null, data, false, false, 'Yes', 'PortalType', null);
        Test.stopTest();
    }
    
    @isTest
    static void testCreateEligibilityConsultancy() {
        Test.startTest();
        String data = '{"FirstName":"Consultant","LastName":"User","Email":"consultant.user@example.com","Phone":"1234567890","ConsultancyAgency":"Test Agency","AgencyEmail":"agency@example.com"}';
        
        List<MSD_CORE_SignUpController.OrganizationInfo> sampleData = new List<MSD_CORE_SignUpController.OrganizationInfo>();
        
        // First record
        MSD_CORE_SignUpController.OrganizationInfo org1 = new MSD_CORE_SignUpController.OrganizationInfo();
        org1.Organization = new MSD_CORE_SignUpController.Field();
        org1.Organization.fieldValue = 'Eruditeworks Pvt Limited';
        org1.Organization.required = true;
        org1.Organization.error = false;
        org1.Organization.errorMessage = '';
        org1.Organization.showLabel = true;

        org1.OrganizationType = new MSD_CORE_SignUpController.Field();
        org1.OrganizationType.fieldValue = 'Consulting';
        org1.OrganizationType.required = true;
        org1.OrganizationType.error = false;
        org1.OrganizationType.errorMessage = '';
        org1.OrganizationType.showLabel = true;

        org1.OrganizationEmail = new MSD_CORE_SignUpController.Field();
        org1.OrganizationEmail.fieldValue = 'contact@eruditeworks.com';
        org1.OrganizationEmail.required = true;
        org1.OrganizationEmail.error = false;
        org1.OrganizationEmail.errorMessage = '';
        org1.OrganizationEmail.showLabel = true;

        sampleData.add(org1);

        // Second record
        MSD_CORE_SignUpController.OrganizationInfo org2 = new MSD_CORE_SignUpController.OrganizationInfo();
        org2.Organization = new MSD_CORE_SignUpController.Field();
        org2.Organization.fieldValue = 'Tech Innovations Inc.';
        org2.Organization.required = true;
        org2.Organization.error = false;
        org2.Organization.errorMessage = '';
        org2.Organization.showLabel = true;

        org2.OrganizationType = new MSD_CORE_SignUpController.Field();
        org2.OrganizationType.fieldValue = 'Software Development';
        org2.OrganizationType.required = true;
        org2.OrganizationType.error = false;
        org2.OrganizationType.errorMessage = '';
        org2.OrganizationType.showLabel = true;

        org2.OrganizationEmail = new MSD_CORE_SignUpController.Field();
        org2.OrganizationEmail.fieldValue = 'info@techinnovations.com';
        org2.OrganizationEmail.required = true;
        org2.OrganizationEmail.error = false;
        org2.OrganizationEmail.errorMessage = '';
        org2.OrganizationEmail.showLabel = true;

        sampleData.add(org2);
        
        String orgList = JSON.serialize(sampleData);
        
        Account acc = [SELECT Id FROM Account];
        
        Map<Id, Boolean> result = MSD_CORE_SignUpController.createEligibility(acc.Id, data, false, false, 'Yes', 'PortalType', null);
        result = MSD_CORE_SignUpController.createEligibilityConsultancy(acc.Id, data, true, false, 'Yes', 'PortalType', orgList);
        
        MSD_CORE_SignUpController.isEmailDomainValid(null);
        MSD_CORE_SignUpController.isEmailDomainValid('test@test.com');
        
        Test.stopTest();
    }
    
    @isTest
    static void testCreateOTP() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String otpId = MSD_CORE_SignUpController.createOTP(testAccount.Id);
        System.assertNotEquals(null, otpId, 'Expected non-null OTP Id');
        Test.stopTest();
    }
    
    @isTest
    static void testSubmitOTP() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String otpId = MSD_CORE_SignUpController.createOTP(testAccount.Id);
        MSD_CORE_OTP__c otp = [SELECT MSD_CORE_Token__c FROM MSD_CORE_OTP__c WHERE Id = :otpId];
        String result = MSD_CORE_SignUpController.submitOTP(testAccount.Id, otp.MSD_CORE_Token__c);
        System.assertEquals('Valid OTP!', result, 'Expected Valid OTP');
        Test.stopTest();
    }
    
    @isTest
    static void testSubmitEligibility() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String result = MSD_CORE_SignUpController.submitEligibility(testAccount.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateEligibilityManualProcess() {
        Test.startTest();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        String result = MSD_CORE_SignUpController.updateEligibilityManualProcess(testAccount.Id);
        Test.stopTest();
    }
}