@isTest
private class PDS_PortalAuthControllerTest {
    
   @isTest
static void testUserAuth_ValidUser() {
    // Test data
    String conId = '';
    String validUserEmail = 'pdstestuser@pds.com';
    String validPassword = 'password123';
    
    System.runAs(createUser()) {
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        insert vsc;
        
        Account acc = new Account(Name = 'TestAccount');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'User', AccountId = acc.Id, Email = validUserEmail);
        insert con;
        
        conId = con.Id;
    }

    Profile pdsProfile = [SELECT Id FROM Profile WHERE Name = 'PDS Taskforce' LIMIT 1];
    if (pdsProfile == null) {
        System.debug('PDS Taskforce profile not found'); 
    }
   
    User testUser = new User(
        FirstName = 'Portal',
        LastName = 'User',
        Email = validUserEmail,
        Username = validUserEmail,
        Alias = 'pdsuser',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = pdsProfile.Id,
        TimeZoneSidKey = 'America/New_York',
        IsActive = true,
        ContactId = conId
    );
    insert testUser;
    
    System.runAs(testUser) {
        Test.startTest();
        try {
            String validResult = PDS_PortalAuthController.userAuth(validUserEmail, validPassword);
            System.assertNotEquals('', validResult, 'Authentication Successful');
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        Test.stopTest();
    }
}

    
    @isTest
    static void testUserAuth_InvalidUser() {
        // Test data
        String invalidUserEmail = 'invaliduser@pds.com';
        String invalidPassword = 'invalidpassword';
        
          Test.startTest();
    try {
        String invalidResult = PDS_PortalAuthController.userAuth(invalidUserEmail, invalidPassword);
        System.assertEquals('Failed', invalidResult, 'Authentication Failed');
    } catch (Exception e) {
        System.debug('Exception occurred: ' + e.getMessage());
    }
    Test.stopTest();
    }
    
    public static User createUser() {
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
        return user;
    }

    @IsTest
    static void testGeneratePasswordResetURL() {
        Test.startTest();
        String url = PDS_PortalAuthController.generatePasswordResetURL(UserInfo.getUserId(), 24, false);
        Test.stopTest();

        System.assert(url.startsWith(System.label.PDS_Portal_URL), 'Expected URL to start with the portal URL');
    }
    
     @IsTest
    static void testDecryptToken() {
        Test.startTest();
        String encryptedToken = PDS_PortalAuthController.generatePasswordResetURL(UserInfo.getUserId(), 24, false);
        Map<String, String> resultMap = PDS_PortalAuthController.decryptToken(encryptedToken);
        Test.stopTest();
    }

    @IsTest
    static void testChangeUserPassword() {
        Test.startTest();
        String encryptedToken = PDS_PortalAuthController.generatePasswordResetURL(UserInfo.getUserId(), 24, false);
        String result = PDS_PortalAuthController.changeUserPassword(encryptedToken, 'newpassword');
        Test.stopTest();
    }
    
    @isTest
    static void testSetUserPasswordSuccess() {
       
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser12345678910@example.com'
        );
        insert testUser;
        
        
        String newPassword = 'TestPassword123';

        
        Test.startTest();
        String result = PDS_PortalAuthController.setUserPassword(testUser.Id, newPassword);
        Test.stopTest();
    }
    
    @isTest
    static void testSetUserPasswordFailure() {
        
        String invalidUserId = 'invalid_user_id';
        String newPassword = 'TestPassword123';

        Test.startTest();
        String result = PDS_PortalAuthController.setUserPassword(invalidUserId, newPassword);
        Test.stopTest();
    }
    
    public static User getCommunityUser(String accName, String confirstname, String conlastname, Boolean vscbool) {
        String conId = '';
        System.runAs(createUser()) {
            if(vscbool) {
                Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
                insert vsc;
            }
            Account acc = new Account(Name = accName);
            insert acc;
            Contact con = new Contact(FirstName = confirstname, LastName = conlastname, AccountId = acc.Id, Email = 'Test'+confirstname+'@merck.com', MSD_CORE_Health_Care_Decision_Maker__c = true);
            insert con;
            conId = con.Id;
        }
        User userr = new User(
            FirstName='Test',
            LastName = 'User1234',
            Alias = 'ndebe',
            Email = 'test1234@merck.com',
            Username = 'test'+String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','')+'@merck.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'MRK_Payor_Exec'].Id,
            TimeZoneSidKey = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US',
            ContactId = conId
        );
        insert userr;
        return userr;
    }
    
     @isTest
    public static void testforgotPassword() {
        String password = 'test@12345';
        User usr = getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        System.runAs(usr) {
            System.setPassword(usr.Id, password);
        }
        Test.startTest();
        String useremail = 'test1234@merck.com';
        
        String Messag = PDS_PortalAuthController.forgotPassword(useremail);
        PDS_PortalAuthController.forgotPassword('');
        Test.stopTest();
        System.assertEquals(true, (usr.ContactId != null), 'Community Profile User');
    }

    static Id getStandardProfileId() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return standardProfile.Id;
    }

    @isTest
    static void testResendWelcomeEmail_ValidUser() {
        Id standardProfileId = getStandardProfileId();

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuserRed@example.com',
            Username = 'testusergreen@example.com',
            Alias = 'testuser',
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfileId 
        );
        insert testUser;

        Test.startTest();
        PDS_PortalAuthController.resendWelcomeEmail(testUser.Id, true); 
        Test.stopTest();

    }


    @isTest
    static void testResendWelcomeEmail_Exception() {
        Test.startTest();
        try {
            PDS_PortalAuthController.resendWelcomeEmail(null, false); 
            System.assert(false, 'Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testForgotPasswordMail() {
        // Test data
        String testUserEmail = 'testuser@example.com';
        String testUserFirstName = 'Test';
        String testUserId = UserInfo.getUserId(); 
        
        PDS_Application_Setting__mdt[] pdsSettings = new List<PDS_Application_Setting__mdt>{
            new PDS_Application_Setting__mdt(
                DeveloperName = 'MDP_Flow_Settings',
                PDS_OrgWideEmailAddress__c = 'test@example.com'
            )
        };

        OrgWideEmailAddress[] orgWideEmails = new List<OrgWideEmailAddress>{
            new OrgWideEmailAddress(Address = 'test@example.com')
        };

        Test.startTest();
        PDS_PortalAuthController.forgotPasswordMail(testUserEmail, testUserFirstName, testUserId);
        Test.stopTest();
    }
    
    
    
}