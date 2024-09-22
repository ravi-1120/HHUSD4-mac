@isTest
public class MSD_CORE_SettingsController_Test {
    @isTest
    static void testGetEligibilityRecords() {
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Username = 'testtwen@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        Contact testContact = new Contact(
           FirstName = 'Test',
            LastName = 'Contact',
            MSD_CORE_Health_Care_Decision_Maker__c = false,
            MSD_CORE_Title__c = 'Test Title'
        );
        insert testContact;     
        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
            testEligibility.MSD_CORE_First_Name__c = 'First Name';
            testEligibility.MSD_CORE_Last_Name__c = 'Last Name';
            testEligibility.MSD_CORE_Organization_Type__c = 'Health plan';
            testEligibility.MSD_CORE_Role__c = 'Health Economist';
        	testEligibility.MSD_CORE_Other_Role__c = 'Dr.';
            testEligibility.MSD_CORE_Organization_Street_1__c = 'Street 1';
        	testEligibility.MSD_CORE_Organization_Street_2__c = 'Street 2';
            testEligibility.MSD_CORE_Organization_City__c = 'City';
        	testEligibility.MSD_CORE_Organization_Extension__c = '5555555';
            testEligibility.MSD_CORE_Organization_ZIP__c = '12345';
            testEligibility.MSD_CORE_Organization_Phone__c = '123-456-7890';
            testEligibility.MSD_CORE_P_T_Process__c = false;
            testEligibility.MSD_CORE_Specialty__c = 'ADOLESCENT MEDICINE-IM';
            testEligibility.MSD_CORE_Other_Role__c = 'Other Role';
            testEligibility.MSD_CORE_Suffix__c = 'III';
            testEligibility.MSD_CORE_Designation__c = 'APN';
            testEligibility.MSD_CORE_Status__c = 'Approved';
        	testEligibility.MS_CORE_Organization_State_Code__c = 'AE';
        	testEligibility.MSD_CORE_Healthcare_Professional__c = true;
            testEligibility.MSD_CORE_Next_Review_Date__c = System.today().addDays(30);
            testEligibility.MSD_CORE_Payor__c = testUser.Id;
            insert testEligibility;

        License__c testLicense = new License__c();
            testLicense.MSD_CORE_Organization_Type__c = 'Health System';
            testLicense.MSD_CORE_Email_Address__c = 'test@example.com';
            testLicense.MSD_CORE_License_Number__c = '123456';
            testLicense.MSD_CORE_License_State__c = 'CA';
            testLicense.Name = 'License';
            testLicense.MSD_CORE_Type_of_license__c = 'AMA Medical Education Number';
            //testLicense.MSD_CORE_Eligibility__c = testEligibility.Id;
            insert testLicense;

        MSD_CORE_Related_Organizations__c testrelorg = new MSD_CORE_Related_Organizations__c();
            testrelorg.MSD_CORE_Organization_Type__c = 'Correctional healthcare';
            testrelorg.MSD_CORE_Email__c = 'test@example.com';
            testrelorg.MSD_CORE_Is_Active__c = true;
            //testLicense.MSD_CORE_Eligibility__c = testEligibility.Id;
            insert testrelorg;

        Test.startTest();
        MSD_CORE_SettingsController.Eligibilitywrapper cw = MSD_CORE_SettingsController.getEligibilityRecords(testUser.Id);
        Test.stopTest();
        System.assertNotEquals(null, cw);
    }
    @isTest
    static void testGetEligibilityRecords2() {
        
       User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'testuserone@test.merck.com',
            Email = 'testuser@test.merck.com',
            CommunityNickname = 'testuser',
            Alias = 'tuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
           ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
                testEligibility.MSD_CORE_Status__c = 'Rejected';
                testEligibility.MSD_CORE_Next_Review_Date__c = System.today().addDays(30);
                testEligibility.MSD_CORE_Payor__c = testUser.Id;
                insert testEligibility;
        
                Test.startTest();
                MSD_CORE_SettingsController.Eligibilitywrapper cw = MSD_CORE_SettingsController.getEligibilityRecords(testUser.Id);
                Test.stopTest();
                System.assertNotEquals(null, cw);    
    }
    
    @isTest
    static void testGetEligibilityRecordsexpired() {
        
       User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'testuserone@test.merck.com',
            Email = 'testuser@test.merck.com',
            CommunityNickname = 'testuser',
            Alias = 'tuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
           ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
                testEligibility.MSD_CORE_Status__c = 'Pending';
                testEligibility.MSD_CORE_Next_Review_Date__c = System.today().addDays(-30);
                testEligibility.MSD_CORE_Payor__c = testUser.Id;
                insert testEligibility;
        
                Test.startTest();
                MSD_CORE_SettingsController.Eligibilitywrapper cw = MSD_CORE_SettingsController.getEligibilityRecords(testUser.Id);
                Test.stopTest();
                System.assertNotEquals(null, cw);    
    }

    @isTest
    static void testGetEligibilityRecords3() {
        
       User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'testrec@test.merck.com',
            Email = 'testrec@test.merck.com',
            CommunityNickname = 'testuser',
            Alias = 'tuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
           ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;   
        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
                testEligibility.MSD_CORE_Status__c = 'Pending';
                testEligibility.MSD_CORE_Next_Review_Date__c = Date.today().addMonths(2);
                testEligibility.MSD_CORE_Payor__c = testUser.Id;
                insert testEligibility;
        
                Test.startTest();
                MSD_CORE_SettingsController.Eligibilitywrapper cw = MSD_CORE_SettingsController.getEligibilityRecords(testUser.Id);
                Test.stopTest();
                System.assertNotEquals(null, cw);    
    }
    
    @isTest
    static void testGetEligibilityRecords4() {
        
       User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'testrec@test.merck.com',
            Email = 'testrec@test.merck.com',
            CommunityNickname = 'testuser',
            Alias = 'tuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
           ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
                testEligibility.MSD_CORE_Status__c = 'Approved';
                testEligibility.MSD_CORE_Next_Review_Date__c = Date.today().addMonths(2);
                testEligibility.MSD_CORE_Payor__c = testUser.Id;
                insert testEligibility;
        
                Test.startTest();
                MSD_CORE_SettingsController.Eligibilitywrapper cw = MSD_CORE_SettingsController.getEligibilityRecords(testUser.Id);
                Test.stopTest();
                System.assertNotEquals(null, cw);    
    }
    
    @isTest
    static void testGetEligibilityRecords5() {
      User communityUser = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
      Test.startTest();
      MSD_CORE_SettingsController.Eligibilitywrapper cw; 
      cw = MSD_CORE_SettingsController.getEligibilityRecords((String)communityUser.Id);
      Test.stopTest();
	  //System.assertEquals(cw,String, 'Record Exists');
     User usr = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
      System.runAs(usr) {
        Contact con = [SELECT ID, MSD_CORE_Oncology_AE__c FROM Contact WHERE Id = :communityUser.ContactId];
        con.MSD_CORE_Oncology_AE__c = communityUser.Id;
        update con;
        System.debug(LoggingLevel.WARN, 'Current User: ' + UserInfo.getUserName());
        System.debug(LoggingLevel.WARN, 'Current Profile: ' + UserInfo.getProfileId());
       
  }    
    }

    @isTest
    static void testGetEligibilityRecords6() {
        
       User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'testrec@test.merck.com',
            Email = 'testrec@test.merck.com',
            CommunityNickname = 'testuser',
            Alias = 'tuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
           ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
                testEligibility.MSD_CORE_Status__c = 'Approved';
                testEligibility.MSD_CORE_Next_Review_Date__c = Date.today().addMonths(2);
                testEligibility.MSD_CORE_Payor__c = testUser.Id;
                insert testEligibility;
        
        License__c testLic = new License__c();
        		testLic.MSD_CORE_Eligibility__c = testEligibility.Id;
        		testLic.MSD_CORE_Organization_Type__c = 'Health Plan';
        		testLic.MSD_CORE_Email_Address__c = 'testmerck@merck.com';
        		testLic.MSD_CORE_License_Number__c='12121212';
        		testLic.MSD_CORE_License_State__c = 'AA';
        		testLic.MSD_CORE_Type_of_license__c = 'AMA Medical Education Number';
        		insert testLic;
        
                Test.startTest();
                MSD_CORE_SettingsController.Eligibilitywrapper cw = MSD_CORE_SettingsController.getEligibilityRecords(testUser.Id);
                Test.stopTest();
                System.assertNotEquals(null, cw);    
    }
    @isTest
    static void testgetPayorNotificationsData() {

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Username = 'test@exampleone.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        Test.startTest();
        user testuser1 = MSD_CORE_SettingsController.getPayorNotificationsData();
        Test.stopTest();
    }

    @isTest
    static void testUpdateNotificationSetting() {
        User testUser2 = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Username = 'test@exampleone.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser2;
        testUser2.Last_Digest_Email_Sent__c = Datetime.now().addMinutes(-40);
        update testUser2;

        Test.startTest();
        
        
        System.runAs(testUser2) {
            MSD_CORE_SettingsController.updateNotificationSetting('Daily_Digest_Summary__c', true);
        }
        
        Test.stopTest();
    }

    

    @isTest
    static void testGetEligibilityDetails() {

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Username = 'test@exampleone.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Payor__c = testUser.Id;
        testEligibility.MSD_CORE_Status__c = 'In Progress';
        testEligibility.MSD_CORE_Organization_Street_1__c = 'Street 1';
        testEligibility.MSD_CORE_Organization_Street_2__c = 'Street 2';
        testEligibility.MSD_CORE_Organization_City__c = 'City';
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
            MSD_CORE_Organization_Type__c = 'Health Plan'
        );
        insert testRelatedOrganization;

        MSD_CORE_Eligibility__c result = MSD_CORE_SettingsController.getEligibilityDetails(testUser.Id);

        System.assertNotEquals(null, result);
        System.assertEquals(testEligibility.MSD_CORE_Organization_Type__c, result.MSD_CORE_Organization_Type__c);
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


    @isTest
    static void testsubmitPersonal(){
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'merckruser@example.com',
            Username = 'merckruser@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Payor__c = testUser.Id;
        testEligibility.MSD_CORE_Status__c = 'Approved';
        testEligibility.MSD_CORE_Organization_Street_1__c = 'Street 1';
        testEligibility.MSD_CORE_Organization_Street_2__c = ' Street 2';
        testEligibility.MSD_CORE_Organization_City__c = ' City';
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
        
        Test.startTest();
        String result = MSD_CORE_SettingsController.submitPersonalPage(licensedatawrap,wrapData);
		Test.stopTest();
        
        List<MSD_CORE_Eligibility__c> updatedEligibility = [
            SELECT MSD_CORE_Salutation__c, MSD_CORE_First_Name__c, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c,
                MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Status__c, MSD_CORE_Stage__c
            FROM MSD_CORE_Eligibility__c
            WHERE MSD_CORE_Payor__c = :testUser.Id
        ];

        List<License__c> createdLicenses = [
            SELECT Name, MSD_CORE_License_Number__c, MSD_CORE_License_State__c, MSD_CORE_Type_of_license__c, MSD_CORE_Eligibility__c
            FROM License__c
            WHERE MSD_CORE_Eligibility__c = :testEligibility.Id
        ];        

    }
    @isTest
    static void testsubmitPersonal2(){
        List<License__c> testLicenses = new List<License__c>{
            new License__c(Name = 'Test License 1', MSD_CORE_License_Number__c = '123', MSD_CORE_License_State__c = 'Test State', MSD_CORE_Type_of_license__c = 'Test Type'),
            new License__c(Name = 'Test License 2', MSD_CORE_License_Number__c = '456', MSD_CORE_License_State__c = 'Test State', MSD_CORE_Type_of_license__c = 'Test Type')
        };
        insert testLicenses;
        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c(
            MSD_CORE_Payor__c = UserInfo.getUserId(),
            MSD_CORE_Salutation__c = 'Mr.',
            Name = 'Test Eligibility'
        );
        insert testEligibility;
        String wrapData = '{"salutation":"Dr.","firstname":"John","lastname":"Doe","suffix":"II","speciality":"FAMILY MEDICINE","designation":"ANP"}';
        Map<String, Object> mainmap = new Map<String, Object>{
            'license1' => new Map<String, Object>{'nameval' => 'Test License 1', 'numberval' => '789', 'stateval' => 'AP', 'typeval' => 'NPI Number'}
        };
        String licensedata = JSON.serialize(mainmap);
        Test.startTest();
        String result = MSD_CORE_SettingsController.submitPersonalPage(wrapData, licensedata);
        System.assertEquals('Success', result, 'Expected success result');
        testEligibility = [SELECT MSD_CORE_Salutation__c, MSD_CORE_First_Name__c, MSD_CORE_Last_Name__c, MSD_CORE_Suffix__c, MSD_CORE_Specialty__c, MSD_CORE_Designation__c, MSD_CORE_Stage__c FROM MSD_CORE_Eligibility__c WHERE Id = :testEligibility.Id];
        System.assertEquals('DR.', testEligibility.MSD_CORE_Salutation__c);
        System.assertEquals('John', testEligibility.MSD_CORE_First_Name__c);
        System.assertEquals('Doe', testEligibility.MSD_CORE_Last_Name__c);
        System.assertEquals('II', testEligibility.MSD_CORE_Suffix__c);
        System.assertEquals('FAMILY MEDICINE', testEligibility.MSD_CORE_Specialty__c);
        System.assertEquals('ANP', testEligibility.MSD_CORE_Designation__c);
        List<License__c> insertedLicenses = [SELECT Id, Name, MSD_CORE_License_Number__c, MSD_CORE_License_State__c, MSD_CORE_Type_of_license__c, MSD_CORE_Eligibility__c FROM License__c];
        License__c insertedLicense = insertedLicenses[0];
        System.assertEquals('Test License 1', insertedLicense.Name);
        delete insertedLicenses;
        delete testEligibility;
        Test.stopTest();      
    }
    @isTest
    static void testsubmitEligibility() {

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'merckruser@example.com',
            Username = 'merckruser@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;


        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Payor__c = testUser.Id;
        testEligibility.MSD_CORE_Other_Role__c = 'Test';
        testEligibility.MSD_CORE_Role__c = 'Consultant';
        testEligibility.MSD_CORE_P_T_Process__c = false;
        testEligibility.MSD_CORE_Status__c = 'In Progress';
        testEligibility.MSD_CORE_Healthcare_Professional__c = false;
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
        org.MSD_CORE_Is_Active__c = true;
        organizationlst.add(org);
        org.MSD_CORE_Eligibility__c = testEligibility.Id;
        org.MSD_CORE_Email__c = 'test@merck.com';
        org.MSD_CORE_Organization_Type__c = 'Academic institution or academic medical center';
        org.MSD_CORE_Organization__c = organization.Id;
        org.MSD_CORE_Is_Active__c = false;
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
        String result = MSD_CORE_SettingsController.submitEligibility(testUser.Id, wrapDataJson);
        Test.stopTest();

        MSD_CORE_Eligibility__c eligibility = [SELECT Id, MSD_CORE_Account__c, MSD_CORE_Organization__c, MSD_CORE_Role__c, MSD_CORE_Status__c, MSD_CORE_Stage__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c = :testUser.Id];

        List<MSD_CORE_Related_Organizations__c> relatedOrgs = [SELECT Id, MSD_CORE_Eligibility__c, MSD_CORE_Organization__c FROM MSD_CORE_Related_Organizations__c WHERE MSD_CORE_Eligibility__c = :eligibility.Id AND MSD_CORE_Is_Active__c=true];
    }
    
     @isTest
    static void testsubmitEligibility2() {    
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'merckruser@example.com',
            Username = 'merckruser@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        MSD_CORE_Eligibility__c testEligibility = new MSD_CORE_Eligibility__c();
        testEligibility.MSD_CORE_Payor__c = testUser.Id;
        //testEligibility.MSD_CORE_Account__c = testAccount.Id;
        testEligibility.MSD_CORE_Role__c = 'Clinician / Physician';
        testEligibility.MSD_CORE_P_T_Process__c = true;
        testEligibility.MSD_CORE_Status__c = 'Approved';
        testEligibility.MSD_CORE_Stage__c  = 'Eligibility';
        testEligibility.MSD_CORE_Organization_Street_1__c = 'Street-1';
        testEligibility.MSD_CORE_Organization_Street_2__c = 'Street-2';
        testEligibility.MSD_CORE_Organization_City__c = 'NY';
        testEligibility.MSD_CORE_Organization_ZIP__c = '12121212';
        testEligibility.MSD_CORE_Organization_Phone__c = '9123456780';
        testEligibility.MSD_CORE_Organization_Extension__c = '123';
        testEligibility.MS_CORE_Organization_State_Code__c = 'AE ';
        testEligibility.MSD_CORE_Other_Role__c = 'Dr.';
        testEligibility.MSD_CORE_Healthcare_Professional__c = true;
        //testEligibility.MSD_CORE_Account__r.PersonEmail = testAccount.PersonEmail;
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
        org.MSD_CORE_Is_Active__c = false;
        organizationlst.add(org);

        Map<String,Object> wrapData = new Map<String,Object>();
        wrapData.put('role', testEligibility.MSD_CORE_Role__c);
        wrapData.put('pt', testEligibility.Id);
        wrapData.put('relatedOrg', organizationlst);
        wrapData.put('orgname', 'Test Org Name');
        wrapData.put('orgId', organization.Id);
        wrapData.put('diffemail',false );
        wrapData.put('myemail',true);
        wrapData.put('healthdecisionmaker',true);

        String wrapDataJson = JSON.serialize(wrapData);

        Test.startTest();
        String result = MSD_CORE_SettingsController.submitEligibility(testUser.Id, wrapDataJson);
        Test.stopTest();

        MSD_CORE_Eligibility__c eligibility = [SELECT Id, MSD_CORE_Account__c,MSD_CORE_Account__r.PersonEmail, MSD_CORE_Organization__c, MSD_CORE_Role__c, MSD_CORE_Status__c, MSD_CORE_Stage__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c = :testUser.Id];

        List<MSD_CORE_Related_Organizations__c> relatedOrgs = [SELECT Id, MSD_CORE_Eligibility__c, MSD_CORE_Organization__c FROM MSD_CORE_Related_Organizations__c WHERE MSD_CORE_Eligibility__c = :eligibility.Id];
    }

    @isTest
    static void testGetPriorDaysExpireList() {
        
        Test.startTest();
            List<MSD_CORE_SettingsController.PicklistOption> options = MSD_CORE_SettingsController.getPriorDaysExpireList();
        Test.stopTest();
    }

    // Test PicklistOption class separately if necessary
    @isTest
    static void testPicklistOptionClass() {
        MSD_CORE_SettingsController.PicklistOption option = new MSD_CORE_SettingsController.PicklistOption('10 days', '10');
        System.assertEquals('10 days', option.label);
        System.assertEquals('10', option.value);
    }
}