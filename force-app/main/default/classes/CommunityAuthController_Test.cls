/**
 * Component Name:      CommunityAuthController
 * Created By:          (Focal CXM)
 * Description:         Test class of CommunityAuthController Apex
 * @description CommunityAuthController_Test
 */
@isTest
public class CommunityAuthController_Test {
    /**
     * @description testdoLogin
    */
    @isTest
    public static void testdoLogin() {
        String password = 'test@12345';
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        System.debug('UUU-->'+usr);
        System.runAs(usr) {
            System.setPassword(usr.Id, password);
        }
        Test.startTest();
        System.debug('usr-->'+usr);
        String startUrl = 'https://test.merckformularyresources.com/';
        CommunityAuthController cac = new CommunityAuthController();
        //String pageurl = CommunityAuthController.doLogin(usr.Email, password,startUrl);
        //CommunityAuthController.doLogin(usr.Email, password,null);
        try{
            String pageurl = CommunityAuthController.doLogin(usr.Email, password,startUrl);
            String pageurl1 = CommunityAuthController.doLoginMHEE(usr.Email, password, '');
        } catch (exception e) {
            
           
        }
        Test.stopTest();
        System.assertEquals(true, (usr.ContactId != null), 'Community Profile User');
    }
    
    @isTest
    public static void testdoLoginMHEE() {
        String password = 'test@12345';
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        
        System.runAs(usr) {
            System.setPassword(usr.Id, password);
            MSD_CORE_Eligibility__c elig2 = eligrec(usr);
        }
        
        Test.startTest();
        String startUrl = 'https://test.merckmedicalandhealth.com/';
        CommunityAuthController cac = new CommunityAuthController();
        try{
            String pageurl = CommunityAuthController.doLoginMHEE(usr.Email, password, startUrl);
            //String pageurl1 = CommunityAuthController.doLoginMHEE(usr.Email, password, null);
        } catch (exception e) {
            
           
        }
        
        Test.stopTest();
        System.assertEquals(true, (usr.ContactId != null), 'Community Profile User');
    }
    
    @isTest
    public static void testdoLoginMHEE1() {
        String password = 'test@12345';
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        
        System.runAs(usr) {
            System.setPassword(usr.Id, password);
            MSD_CORE_Eligibility__c elig2 = eligrec(usr);
        }
        
        Test.startTest();
        String startUrl = 'https://test.merckmedicalandhealth.com/';
        CommunityAuthController cac = new CommunityAuthController();
        try{
          //String pageurl = CommunityAuthController.doLoginMHEE(usr.Email, password, startUrl);
         // String pageurl1 = CommunityAuthController.doLoginMHEE(usr.Email, password, null);
            String pageurl1 = CommunityAuthController.doLoginMHEE('',password, '');
          //String pageurl2= CommunityAuthController.doLoginMHEE(usr.Email,password, '');
        } catch (exception e) {
            
           
        }
        
        Test.stopTest();
        System.assertEquals(true, (usr.ContactId != null), 'Community Profile User');
    }

 /**
     * @description MSD_CORE_Eligibility__c
    */
    public static MSD_CORE_Eligibility__c eligrec(user usr) {
       
       Date newDate = Date.today().addDays(-2);
        
        MSD_CORE_Eligibility__c eligb = new MSD_CORE_Eligibility__c();
        
        eligb.MSD_CORE_Next_Review_Date__c = newDate;
        //eligb.MSD_CORE_Eligibility_Expired__c = true;
        system.debug('newdate' + newDate);
        eligb.MSD_CORE_Payor__c = usr.id;
        insert eligb;
        return eligb;
       
    }
        
    
    /**
     * @description testdoLoginSite
    */
    @isTest
    public static void testdoLoginSite() {
        String password = 'test@12345';
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        System.runAs(usr) {
            System.setPassword(usr.Id, password);
        }
        Test.startTest();
        String startUrl = 'https://test.merckmedicalandhealth.com/';
        CommunityAuthController cac = new CommunityAuthController();
        String pageurl = CommunityAuthController.doLoginSite(usr.Username, password, startUrl);
        CommunityAuthController.doLoginSite('', '','');
        Test.stopTest();
        System.assertEquals(true, (usr.ContactId != null), 'Community Profile User');
    }

     /**
     * @description testdoForgotPasswordSite
    */
    @isTest
    public static void testdoForgotPasswordSite() {
        String password = 'test@12345';
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        System.runAs(usr) {
            System.setPassword(usr.Id, password);
        }
        Test.startTest();
        String useremail = 'test1234@merck.com';
        
        String Messag = CommunityAuthController.forgotPassword(useremail);
        CommunityAuthController.forgotPassword('');
        Test.stopTest();
        System.assertEquals(true, (usr.ContactId != null), 'Community Profile User');
    }

    private static User createUser1() {
    Profile firstProfile = [SELECT Id FROM Profile Limit 1];
    User user1 = new User(LastName = 'Userton',
                       FirstName='User',
                       Alias = 'usus',
                       Email = 'user.user@merck.com',
                       Username = Math.random() + '@' + Math.random(),
                       ProfileId = firstProfile.Id,
                       TimeZoneSidKey = 'GMT',
                       LanguageLocaleKey = 'en_US',
                       EmailEncodingKey = 'UTF-8',
                       LocaleSidKey = 'en_US'
                
    );
    insert user1;
    return user1;
  }

    /**
     * @description testdoResetPasswordSite
    */
    @isTest
    public static void testdoResetPasswordSite() {
        String password = 'test@12345';
        String newPassword = 'test@123';
        
        Veeva_Settings_vod__c vsc = new Veeva_Settings_vod__c();
        vsc.DATA_CHANGE_REQUEST_MODE_vod__c = 2;    
        insert vsc;
        User usr;
        System.runAs(new User(Id = UserInfo.getUserId())){ 
            usr = createUser1();
        }

        
        MSD_CORE_OTP__c otp = new MSD_CORE_OTP__c();
        otp.MSD_CORE_Payor__c = usr.Id;
        otp.MSD_CORE_Type__c = 'Password Reset';
        otp.MSD_CORE_Expiration_DateTime__c = System.now().addHours(48);
        otp.MSD_CORE_Status__c = 'New';
        otp.MSD_CORE_Token__c = String.valueOf(Math.round((Math.random() * (900000) + 100000)));
        insert otp;
        Test.startTest();
        
        String Messag = CommunityAuthController.resetPassword(usr.id, newPassword, otp.MSD_CORE_Token__c);
        Test.stopTest();
    }

    /**
     * @description testResetPasswordMail
    */
    @isTest
    public static void testResetPasswordMail() {
        String password = 'test@12345';
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        System.runAs(usr) {
            System.setPassword(usr.Id, password);
        }
        Test.startTest();
        String startUrl = 'https://test.merckmedicalandhealth.com/';
        String otpval = '123456';
        String useremail = 'test1234@merck.com';
        CommunityAuthController cac = new CommunityAuthController();
        CommunityAuthController.resetPasswordMail(useremail, usr.Username, usr.Id, otpval);
        Test.stopTest();
        System.assertEquals(true, (usr.ContactId != null), 'Community Profile User');
    }

    /**
     * @description testcheckOTP
    */
    @isTest
    public static void testcheckOTP() {
        String password = 'test@12345';
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        String otpval = '123456';
        System.runAs(usr) {
            System.setPassword(usr.Id, password);
            MSD_CORE_OTP__c msdOtp = new MSD_CORE_OTP__c();
               msdOtp.name = 'test msdOtp';
               msdOtp.MSD_CORE_Payor__c = usr.Id;
               msdOtp.MSD_CORE_Token__c = otpval;
               msdOtp.MSD_CORE_Status__c = 'Used';
              insert msdOtp;
        }
        Test.startTest();
        String startUrl = 'https://test.merckmedicalandhealth.com/';
        String useremail = 'test1234@merck.com';
        CommunityAuthController cac = new CommunityAuthController();
        CommunityAuthController.checkOTP(usr.Id, otpval);
        Test.stopTest();
        System.assertEquals(true, (usr.ContactId != null), 'Community Profile User');
    }
    
    /**
     * @description testcheckOTP1
    */
    public static void testcheckOTP1() {
        String password = 'test@12345';
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        String otpval = '123456';
        System.runAs(usr) {
            System.setPassword(usr.Id, password);
            MSD_CORE_OTP__c msdOtp = new MSD_CORE_OTP__c();
               msdOtp.name = 'test msdOtp';
               msdOtp.MSD_CORE_Payor__c = usr.Id;
               msdOtp.MSD_CORE_Token__c = otpval;
               msdOtp.MSD_CORE_Expiration_DateTime__c = System.now().addHours(-2);
               msdOtp.MSD_CORE_Status__c = 'New';
              insert msdOtp;
        }
        Test.startTest();
        String startUrl = 'https://test.merckmedicalandhealth.com/';
        String useremail = 'test1234@merck.com';
        CommunityAuthController cac = new CommunityAuthController();
        CommunityAuthController.checkOTP(usr.Id, otpval);
        Test.stopTest();
        System.assertEquals(true, (usr.ContactId != null), 'Community Profile User');
    }

    /**
     * @description testUpdatePassword
    */
    @isTest
    public static void testUpdatePassword() {
        String newPassword = 'test@1234522';
        String password = 'test@12345';
        User usr = TestDataFactory_MSD_CORE_Notification.getCommunityUser('TestAccount', 'Test', 'Contact123', true);
        System.runAs(usr) {
            System.setPassword(usr.Id, password);
        }
        Test.startTest();
        CommunityAuthController.updatePassword(usr.AccountId, newPassword);
        CommunityAuthController.updatePasswordMail(usr.Email, usr.Username);
        CommunityAuthController.loginverification(usr.Email, usr.Username, null, null);
        CommunityAuthController.forgotpasswordverify(usr.Email);
        CommunityAuthController.orgresetPasswordMail(usr.Email, usr.Username, '', '');
        CommunityAuthController.orgresetPassword(usr.Email, usr.Username, '');
        CommunityAuthController.orgupdatePasswordMail(usr.Email, usr.Username);
        Test.stopTest();
        System.assertEquals(true, (usr.ContactId != null), 'Community Profile User');
    }
    
    @isTest
    static void testUpdatePasswordException() {
        Test.startTest();
    
        try {
            // Test when accountID is null
            String updatePasswordResult = CommunityAuthController.updatePassword(null, 'newpassword');
            System.assertEquals('Something Went Wrong', updatePasswordResult, 'Update Password failed for null accountID');
    
            // Test when user does not exist
            String updatePasswordResult2 = CommunityAuthController.updatePassword('nonexistentaccountID', 'newpassword');
            System.assertEquals('Not found any user', updatePasswordResult2, 'Update Password failed for non-existent user');
    
        } catch (Exception e) {
            System.assert(false, 'An unexpected exception occurred: ' + e.getMessage());
        }
    
        Test.stopTest();
    }

}