/**
 * Component Name:      CommunityAuthController
 * Created By:          (Focal CXM)
 * Description:         Used for login into the community portal
 * Test Class:          CommunityAuthController_Test
 * @description CommunityAuthController
 */
public without Sharing class CommunityAuthController {
    /**
     * @description doLogin
     * @return null
     * @param username
     * @param password
    */
    @AuraEnabled
    public static String doLogin(String username, String password, String startURLval){
        try {
            String usernm;

            if (username != null) {
                System.debug('username-->'+username);
                User usr = new User();
                usr = [SELECT Id, Name, Username, Email FROM User WHERE Email =: username AND Profile.Name = 'MRK_Payor_Exec' ORDER BY LastmodifiedDate DESC LIMIT 1];
                usernm = usr.Username;
                List<MSD_CORE_Eligibility__c> elig = new List<MSD_CORE_Eligibility__c>();
                elig = [Select Id,MSD_CORE_Eligibility_Expired__c From  MSD_CORE_Eligibility__c WHERE  MSD_CORE_Payor__c =:usr.Id];
                startURLval = (elig.size() > 0 && elig[0].MSD_CORE_Eligibility_Expired__c == true) ? System.label.MSD_CORE_Domain_URL+'/settings'+'?tab=2' : null;
            } else {
                return 'Email dose not exist!';
            }

            if (startURLval == null) {
                startURLval = System.label.MSD_CORE_Domain_URL + '/dashboard';
            }

            ApexPages.PageReference pageRef = Site.login(usernm, password,startURLval);
            if(pageRef != null){ 
                return pageRef.getUrl();
            }else{
                return null;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    /**
     * @description doLoginMHEE
     * @return null
     * @param username
     * @param password
    */
    @AuraEnabled
    public static String doLoginMHEE(String username, String password, String startUrl){
        try {
            String usernm;
            if (username != null) {
                User usr = new User();
                usr = [SELECT Id, Name, Username, Email FROM User WHERE Email =: username AND Profile.Name = 'MRK_Payor_Exec' ORDER BY LastmodifiedDate DESC LIMIT 1];
                usernm = usr.Username;
                List<MSD_CORE_Eligibility__c> elig = new List<MSD_CORE_Eligibility__c>();
                elig = [Select Id,MSD_CORE_Eligibility_Expired__c From  MSD_CORE_Eligibility__c WHERE  MSD_CORE_Payor__c =:usr.Id];
               // startUrl = (elig.size() > 0 && elig[0].MSD_CORE_Eligibility_Expired__c == true) ? System.label.MSD_CORE_Domain_URL+'/settings'+'?tab=2' :  null;
                if(elig.size() > 0 && elig[0].MSD_CORE_Eligibility_Expired__c == true){
                    return 'Account Locked';
                }
            } 
            else {
                return 'Email does not exist!';
            }

            if (startUrl == null) {
                startUrl = System.label.MSD_CORE_HealthEconomicEvidence;
            }
            //String startUrl = System.label.MSD_CORE_HealthEconomicEvidence;
            ApexPages.PageReference pageRef = Site.login(usernm, password,startUrl);
            if(pageRef != null){ 
                return pageRef.getUrl();
            }else{
                return null;
            }

        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * @description doLoginSite
     * @return null
     * @param username
     * @param password
     * @param url
    */
    @AuraEnabled
    public static String doLoginSite(String username, String password, String url){
        try {
            String startUrl = url;
            ApexPages.PageReference pageRef = Site.login(username, password,startUrl);
            if(pageRef != null){ return pageRef.getUrl();
            }else{
                return null;
            }

        } catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description forgotPassword
     * @return String
     * @param useremail
    */
    @AuraEnabled
    public static String forgotPassword(String useremail){
        String returnval = '';
        try {
            List<User> userlst = [SELECT Id, FirstName, Email, Profile.Name FROM User WHERE Email =: useremail AND Profile.Name = 'MRK_Payor_Exec' ORDER BY CreatedDate ASC LIMIT 1];
            if (userlst.size()>0) {
                // System.resetPasswordWithEmailTemplate(userlst[0].Id, true, 'MSD_CORE_Forgot_Password');
                MSD_CORE_OTP__c otp = new MSD_CORE_OTP__c();
                otp.MSD_CORE_Payor__c = userlst[0].Id;
                otp.MSD_CORE_Type__c = 'Password Reset';
                otp.MSD_CORE_Expiration_DateTime__c = System.now().addHours(48);
                otp.MSD_CORE_Status__c = 'New';
                otp.MSD_CORE_Token__c = String.valueOf(Math.round((Math.random() * (900000) + 100000)));
                insert otp;

                System.resetPassword(userlst[0].Id, false);
                CommunityAuthController.resetPasswordMail(userlst[0].Email, userlst[0].FirstName, userlst[0].Id, otp.MSD_CORE_Token__c);
                returnval = 'Reset Password Link Sent successfully!';
            } else {
                returnval = 'Please enter a valid email address that is associated with your account';
            }

        } catch (Exception e) {returnval = e.getMessage() +'---' +e.getLineNumber();
        }
        return returnval;
    }

    

    /**
     * @description resetPasswordMail
     * @return String
     * @param useremail
     * @param userfirstname
     * @param userid
     * @param otpval
    */
    public static void resetPasswordMail(String useremail, String userfirstname, String userid, String otpval){
        try {
            
            String changepw = System.label.MSD_CORE_Domain_URL +'/changepassword?recordId='+userid+'&token='+otpval+'&utm_source=sfmc&utm_medium=email&utm_campaign=us_cross-brands_login_na_password-reset&utm_content=us-non-14018_reset-password';
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'mfr.noreply@merck.com'];
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            string[] to = new string[] {useremail};
            if(userfirstname == null){
                userfirstname = '';
            }    
            /* Updated Email Template - Sabari */   
            email.setHtmlBody('<html> <head> <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"> <meta name="viewport" content="width=device-width,initialscale=1"> <meta http-equiv="X-UA-Compatible" content="IE=edge"> <style type="text/css">@media screen and (max-width:480px){slot[style]{margin-right:0!important}.columnDiv{margin-right:0!important}}@media screen and (min-width:480px){slot[style]{margin-bottom:0!important}.columnDiv{margin-bottom:0!important}}</style> <style type="text/css">@media screen and (max-width:480px){.contentbuilderBaseColumnRow .columnCell{display:inline-block;width:100%}}</style> <style type="text/css">.contentpageDefaultEmailTemplatePageTemplate .contentRoot{width:600px}@media only screen and (max-width:480px){.contentpageDefaultEmailTemplatePageTemplate .contentRoot{width:320px}}</style> </head> <body> <table class="contentpageDefaultEmailTemplatePageTemplate" style="background-color:#e9eaec" role="presentation" id="contentpage_emailTemplateBodyContent" width="100%" cellpadding="0" cellspacing="0"> <tr> <td width="100%" align="center"> <table class="contentRoot" style="background-color:#fff" role="presentation" width="600" cellpadding="0" cellspacing="0"> <tr> <td style="padding-top:10px;padding-bottom:10px;padding-left:10px;padding-right:10px"> <table cellpadding="0" cellspacing="0" class="contentbuilderBaseColumnRow" style="align-items:flex-start;width:100%" width="100%"> <tr valign="top"> <td class="columnCell" style="vertical-align:top;display:inline-block;float:left" width="100%"> <table cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;word-break:break-word"> <tr> <td> <table cellpadding="0" cellspacing="0" id="contentRegion" style="width:100%;border-collapse:collapse;word-break:break-word"> <tr> <td align="Center"><img alt="" src="https://msdlogin--hhusportal.sandbox.file.force.com/file-asset-public/Header_1?oid=00D5C00000093k2" style="width:100%;display:block;border:none;max-width:100%;object-fit:fill" width="600"></td> </tr> </table> </td> </tr> </table> </td> </tr> </table> <table cellpadding="0" cellspacing="0" class="contentbuilderBaseColumnRow" style="align-items:flex-start;width:100%" width="100%"> <tr valign="top"> <td class="columnCell" style="vertical-align:top;display:inline-block;float:left" width="100%"> <table cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;word-break:break-word"> <tr> <td> <table cellpadding="0" cellspacing="0" id="contentregion" style="font-size:14px;width:100%;border-collapse:collapse;word-break:break-word"> <tr> <td class="contentbuilder-html" style="padding:0"> <p style="margin-top:32px;max-width:636px;min-height:36px;font-family:Arial!important;font-style:normal;font-weight:700;font-size:24px;line-height:36px;color:#333;flex:none;order:0;align-self:stretch;flex-grow:0;margin-left:24px;margin-right:24px">Reset your password.</p> <div style="font-family:Arial!important;font-style:normal;font-weight:400;font-size:16px;max-width:: 636px;min-height:132px"> <p style="font-family:Arial!important;font-size:16px;margin-left:24px;margin-right:24px;margin-Top:24px;margin-bottom:24px">Dear '+userfirstname+',</p> <p style="font-family:Arial!important;margin-left:24px;margin-right:24px;margin-bottom:24px;font-weight:400;font-size:16px;line-height:24px;color:#333">We have received a request to change your Merck Formulary Resources portal password. If you made this request, click the button below to reset your password.</p> </div> <table border="0" cellpadding="0" cellspacing="0" style="Margin-left:24px;margin-top:24px;border-radius:5px" width="100%"> <tr style="border-radius:5px"> <td align="left" style="border-radius:5px"> <table border="0" cellpadding="0" cellspacing="0" style="border-radius:5px" width="131"> <tr style="border-radius:5px"> <td style="background-color:#00857c;text-align:center;border-radius:5px;"> <!--[if mso]> <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="'+changepw+'" style="height:60px;v-textanchor:middle;width:200px;" arcsize="10%" stroke="f" fillcolor="#00857c"> <w:anchorlock/> <center><a href="'+changepw+'" style="width:200px;font-family:Arial;text-align:center;font-weight:700;color:#fff;text-decoration:none;font-size:14px;line-height:40px;">Reset password</a></center> </v:roundrect> <![endif]--> <!--[if !mso]><!--><a href="'+changepw+'" style="width:100%;padding:11px 3px;border:solid 1px #00857c;border-radius:5px;font-family:Arial;text-align:center;font-weight:700;letter-spacing:.861539px;color:#fff;text-decoration:none;font-size:14px;line-height:18px;font-weight:700;letter-spacing:.861539px;background-color:#00857c;color:#fff;display:inline-block">Reset password</a><![endif]--> </td> </table> </td> </tr> </table> <p style="font-family:Arial;font-style:normal;font-weight:400;font-size:14px;line-height:21px;color:#333;flex:none;order:1;align-self:stretch;flex-grow:0;max-width:636px;min-height:63px;margin-bottom:45px;margin-left:24px;margin-right:24px;align-self:stretch;margin-top:45px">If you did not recently attempt to register for a Merck login, you may disregard this email. If you have any questions, please call our technical support service at<br>1-800-489-5119 (Monday–Friday, 8 AM–7 PM ET).</p> <p style="max-width:636px;min-height:63px;font-weight:400;font-size:12px;line-height:18px;text-align:center;font-size:12px;font-family:Arial;font-weight:400;margin-left:24px;margin-right:24px;font-weight:400;font-size:12px;line-height:18px">This message was distributed from an email account used for sending messages only.<br>Please do not reply to this message.</p> <p style="max-width:636px;min-height:63px;margin-left:24px;margin-right:24px;margin-bottom:45px;font-weight:400;font-family:Arial;font-size:12px;line-height:18px;text-align:center;flex:none;order:1;align-self:stretch;flex-grow:0">Copyright © 2023 Merck &amp; Co., Inc., Rahway, NJ, USA and its affiliates.<br>All rights reserved.<br><br>US-NON-14018 08/23</p> </td> </tr> </table> </td> </tr> </table> </td> </tr> </table> </td> </tr> </table> </td> </tr> </table> </body> </html>');
            email.setToAddresses(to);
            email.setSubject('Reset your password');
            if ( owea.size() > 0 ) {
                email.setOrgWideEmailAddressId(owea.get(0).Id);
            }
  
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception e) {System.debug(e.getMessage() +'---' +e.getLineNumber());
        }
    }

    

    /**
     * @description checkOTP
     * @return String
     * @param userId
     * @param token
    */
    @AuraEnabled(cacheable=true)
    public static string checkOTP(String userId, String token){
        
        String returnval = '';
        try {
            List<MSD_CORE_OTP__c> otllst = [SELECT Id, MSD_CORE_Token__c, MSD_CORE_Payor__c, MSD_CORE_Status__c, MSD_CORE_Expiration_DateTime__c FROM MSD_CORE_OTP__c WHERE MSD_CORE_Token__c  =: token AND MSD_CORE_Payor__c =: userId];
            if (otllst.size()>0) {
                if(otllst[0].MSD_CORE_Status__c == 'Used' || System.now() > otllst[0].MSD_CORE_Expiration_DateTime__c) {
                    returnval = System.label.MSD_CORE_OTPExpired;
                } else {
                    returnval = 'Valid OTP';
                }
            } else {
                returnval = 'Invalid OTP';
            }
        } catch (Exception e) {
            returnval = System.label.MFRGeneralErrorMessage;    
        }
        return returnval;
    }


    /**
     * @description resetPassword
     * @return String
     * @param userId
     * @param newPassword
    */
    @AuraEnabled
    public static string resetPassword(String userId, String newPassword, String token){
        
        String returnval = '';
        try {
            System.debug('UserId-->'+userId);
            System.debug('newPassword-->'+newPassword);
            System.debug('token-->'+token);
            List<MSD_CORE_OTP__c> otllst = [SELECT Id, MSD_CORE_Token__c, MSD_CORE_Payor__c, MSD_CORE_Status__c FROM MSD_CORE_OTP__c WHERE MSD_CORE_Token__c  =: token AND MSD_CORE_Payor__c =: userId];
            System.debug('otllst-->'+otllst.size());
            if (otllst.size()>0) {
                otllst[0].MSD_CORE_Status__c = 'Used';
                System.setPassword(userId,newPassword);
                update otllst; 
                User usr = [SELECT Id, Name, FirstName, Email FROM User WHERE Id =: userId LIMIT 1];
                updatePasswordMail(usr.Email , usr.FirstName);
                System.debug('Success');
                returnval = 'Success!';
            }
        } catch (Exception e) {
            System.debug('Error->>'+e.getMessage());
            if (e.getMessage() == 'UNKNOWN_EXCEPTION: invalid repeated password') {
                returnval = System.label.MSD_CORE_OldPasswordNotUse;
            } else {
                returnval = System.label.MFRGeneralErrorMessage;    
            }
        }
        return returnval;
    }

    
    /**
     * @description resetPassword
     * @return String
     * @param accountID
     * @param newPassword
    */

    @AuraEnabled
    public static string updatePassword(String accountID, String newPassword){
        
        String returnval = '';
        List<User> userData;  
        try { 
            if (accountID != null && accountID != '') {
                userData = [SELECT Id,name,Email,AccountId,Contact.name,Contact.FirstName,CreatedDate FROM User WHERE AccountId  != null AND AccountId =: accountID LIMIT 1];   
            }else if (accountID != '') {
                userData = [SELECT Id,name,Email,AccountId,Contact.name,Contact.FirstName,CreatedDate FROM User WHERE Id =: UserInfo.getUserId()  LIMIT 1];        
            }
            
            
            
            System.debug('userData--->'+ userData);
            if (userData.size() > 0) {
                System.setPassword(userData[0].Id,newPassword);
                updatePasswordMail(userData[0].Email , userData[0].Contact.FirstName);
                returnval = 'Success!';
                return returnval;
            }else if(userData.size() == 0){
                returnval = 'Not found any user';
                return returnval;
            }
            
        } catch (Exception e) {
            
            if (e.getMessage() == 'UNKNOWN_EXCEPTION: invalid repeated password') {
                returnval = System.label.MSD_CORE_OldPasswordNotUse;
            } else {
                returnval = System.label.MFRGeneralErrorMessage;    
            }
        }
        return returnval;
    }

     /**
     * @description resetPasswordMail
     * @return String
     * @param useremail
     * @param userfirstname
    */
    public static void updatePasswordMail(String useremail, String userfirstname){
        try {
            String headerURL = System.label.mSD_CORE_EmailHeader;
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'mfr.noreply@merck.com'];
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            string[] to = new string[] {useremail};
            email.setToAddresses(to);
            email.setSubject('Reset your password');
            /* Updated Email Template - Sabari MFRUS-136*/
            email.setHtmlBody('<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"><meta name="viewport" content="width=device-width,initialscale=1"><meta http-equiv="X-UA-Compatible" content="IE=edge"><style type="text/css">@media screen and (max-width:480px){slot[style]{margin-right:0!important}.columnDiv{margin-right:0!important}}@media screen and (min-width:480px){slot[style]{margin-bottom:0!important}.columnDiv{margin-bottom:0!important}}</style><style type="text/css">@media screen and (max-width:480px){.contentbuilderBaseColumnRow .columnCell{display:inline-block;width:100%}}</style><style type="text/css">.contentpageDefaultEmailTemplatePageTemplate .contentRoot{width:600px}@media only screen and (max-width:480px){.contentpageDefaultEmailTemplatePageTemplate .contentRoot{width:320px}}</style></head><body><table class="contentpageDefaultEmailTemplatePageTemplate" style="background-color:#e9eaec" role="presentation" id="contentpage_emailTemplateBodyContent" width="100%" cellpadding="0" cellspacing="0"><tr><td width="100%" align="center"><table class="contentRoot" style="background-color:#fff" role="presentation" width="600" cellpadding="0" cellspacing="0"><tr><td style="padding-top:10px;padding-bottom:10px;padding-left:10px;padding-right:10px"><table cellpadding="0" cellspacing="0" class="contentbuilderBaseColumnRow" style="align-items:flex-start;width:100%" width="100%"><tr valign="top"><td class="columnCell" style="vertical-align:top;display:inline-block;float:left" width="100%"><table cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;word-break:break-word"><tr><td><table cellpadding="0" cellspacing="0" id="contentRegion" style="width:100%;border-collapse:collapse;word-break:break-word"><tr><td align="Center"><img alt="" src="https://msdlogin--hhusportal.sandbox.file.force.com/file-asset-public/Header_1?oid=00D5C00000093k2" style="width:100%;display:block;border:none;max-width:100%;object-fit:fill" width="600"></td></tr></table></td></tr></table></td></tr></table><table cellpadding="0" cellspacing="0" class="contentbuilderBaseColumnRow" style="align-items:flex-start;width:100%" width="100%"><tr valign="top"><td class="columnCell" style="vertical-align:top;display:inline-block;float:left" width="100%"><table cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;word-break:break-word"><tr><td><table cellpadding="0" cellspacing="0" id="contentregion" style="font-size:14px;width:100%;border-collapse:collapse;word-break:break-word"><tr><td class="contentbuilder-html" style="padding:0"><p style="margin-top:32px;max-width:636px;min-height:36px;font-family:Arial!important;font-style:normal;font-weight:700;font-size:24px;line-height:36px;color:#333;flex:none;order:0;align-self:stretch;flex-grow:0;margin-left:24px;margin-right:24px">Your password has been updated.</p><div style="font-family:Arial!important;font-style:normal;font-weight:400;font-size:16px;max-width:: 636px;min-height:132px"><p style="font-family:Arial!important;font-size:16px;margin-left:24px;margin-right:24px;margin-Top:24px;margin-bottom:24px">Dear '+userfirstname+',</p><p style="font-family:Arial!important;margin-left:24px;margin-right:24px;margin-bottom:24px;font-weight:400;font-size:16px;line-height:24px;color:#333">Your password has been changed.</p><p style="font-family:Arial!important;margin-left:24px;margin-right:24px;margin-bottom:24px;font-weight:400;font-size:16px;line-height:24px;color:#333">If you did not request a password change, please contact technical support.</p></div><table border="0" cellpadding="0" cellspacing="0" style="Margin-left:24px;margin-top:24px;border-radius:5px" width="100%"><tr style="border-radius:5px"><td align="left" style="border-radius:5px"><table border="0" cellpadding="0" cellspacing="0" style="border-radius:5px" width="131"><tr style="border-radius:5px"><td style="background-color:#00857c;text-align:center;border-radius:5px;"><!--[if mso]><v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="'+System.label.MSD_CORE_Domain_URL+'/my-contacts/?utm_source=sfmc&utm_medium=email&utm_campaign=us_cross-brands_login_na_password-updated" style="height:60px;v-textanchor:middle;width:200px;" arcsize="10%" stroke="f" fillcolor="#00857c"><w:anchorlock/><center><a href="'+System.label.MSD_CORE_Domain_URL+'/my-contacts/?utm_source=sfmc&utm_medium=email&utm_campaign=us_cross-brands_login_na_password-updated" style="width:200px;font-family:Arial;text-align:center;font-weight:700;color:#fff;text-decoration:none;font-size:14px;line-height:40px;">Contact support</a></center></v:roundrect><![endif]--><!--[if !mso]><!--><a href="'+System.label.MSD_CORE_Domain_URL+'/my-contacts/?utm_source=sfmc&utm_medium=email&utm_campaign=us_cross-brands_login_na_password-updated" style="width:100%;padding:11px 3px;border:solid 1px #00857c;border-radius:5px;font-family:Arial;text-align:center;font-weight:700;letter-spacing:.861539px;color:#fff;text-decoration:none;font-size:14px;line-height:18px;font-weight:700;letter-spacing:.861539px;background-color:#00857c;color:#fff;display:inline-block">Contact support</a><![endif]--></td></table></td></tr></table><p style="font-family:Arial;font-style:normal;font-weight:400;font-size:14px;line-height:21px;color:#333;flex:none;order:1;align-self:stretch;flex-grow:0;max-width:636px;min-height:63px;margin-bottom:45px;margin-left:24px;margin-right:24px;align-self:stretch;margin-top:45px">If you did not recently attempt to register for a Merck login, you may disregard this email. If you have any questions, please call our technical support service at<br>1-800-489-5119 (Monday–Friday, 8 AM–7 PM ET).</p><p style="max-width:636px;min-height:63px;font-weight:400;font-size:12px;line-height:18px;text-align:center;font-size:12px;font-family:Arial;font-weight:400;margin-left:24px;margin-right:24px;font-weight:400;font-size:12px;line-height:18px">This message was distributed from an email account used for sending messages only.<br>Please do not reply to this message.</p><p style="max-width:636px;min-height:63px;margin-left:24px;margin-right:24px;margin-bottom:45px;font-weight:400;font-family:Arial;font-size:12px;line-height:18px;text-align:center;flex:none;order:1;align-self:stretch;flex-grow:0">Copyright © 2023 Merck &amp; Co., Inc., Rahway, NJ, USA and its affiliates.<br>All rights reserved.<br><br>US-NON-14018 08/23</p></td></tr></table></td></tr></table></td></tr></table></td></tr></table></td></tr></table></body></html>');
            if ( owea.size() > 0 ) {
                email.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception e) {
            System.debug(e.getMessage() +'---' +e.getLineNumber());
        }
    }

   

    /*** organic registration methods starts from here***/
    
    //for login of user
    @AuraEnabled(cacheable=true)
    public static string loginverification(string emailval, string passval, string remberval, String brandId){
        try {
            String usernam;
            String startURLval;
            if (emailval != null) {
                User usr = new User();
                usr = [SELECT Id, Name, Username, Email FROM User WHERE Email =: emailval AND Profile.Name = 'MRK_Payor_Exec' ORDER BY LastmodifiedDate DESC LIMIT 1];
                usernam = usr.Username;
                List<MSD_CORE_Eligibility__c> elig = new List<MSD_CORE_Eligibility__c>();
                elig = [Select Id,MSD_CORE_Eligibility_Expired__c From  MSD_CORE_Eligibility__c WHERE  MSD_CORE_Payor__c =:usr.Id];
                startURLval = (elig.size() > 0 && elig[0].MSD_CORE_Eligibility_Expired__c == true) ? System.label.MSD_CORE_Domain_URL+'/settings'+'?tab=2' : null;
            } else {
                return 'Email dose not exist!';
            }
            
            if(String.isNotBlank(brandId)) {
                startURLval = System.label.MSD_CORE_Domain_URL + '/product/productdetail?recordId='+brandId;
            }

            if (startURLval == null) {
                startURLval = System.label.MSD_CORE_Domain_URL + '/dashboard';
            }

            ApexPages.PageReference pageRef = Site.login(usernam, passval, startURLval);
            if(pageRef != null){ 
                return pageRef.getUrl();
            }else{
                return null;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    // for forgot password 
    @AuraEnabled
    public static string forgotpasswordverify(string emailval){
         String returnval = '';
        try {
            List<User> userlst = [SELECT Id, FirstName, Email, Profile.Name FROM User WHERE Email =: emailval AND Profile.Name = 'MRK_Payor_Exec' ORDER BY CreatedDate ASC LIMIT 1];
            if (userlst.size()>0) {
                // System.resetPasswordWithEmailTemplate(userlst[0].Id, true, 'MSD_CORE_Forgot_Password');
                MSD_CORE_OTP__c otp = new MSD_CORE_OTP__c();
                otp.MSD_CORE_Payor__c = userlst[0].Id;
                otp.MSD_CORE_Type__c = 'Password Reset';
                otp.MSD_CORE_Expiration_DateTime__c = System.now().addHours(48);
                otp.MSD_CORE_Status__c = 'New';
                otp.MSD_CORE_Token__c = String.valueOf(Math.round((Math.random() * (900000) + 100000)));
                insert otp;

                System.resetPassword(userlst[0].Id, false);
                CommunityAuthController.orgresetPasswordMail(userlst[0].Email, userlst[0].FirstName, userlst[0].Id, otp.MSD_CORE_Token__c);
                returnval = 'Reset Password Link Sent successfully!';
            } else {
                returnval = 'Please enter a valid email address that is associated with your account';
            }

        } catch (Exception e) {returnval = e.getMessage() +'---' +e.getLineNumber();
        }
        return returnval;
    }

    //to send email for forgot password notificaion
    public static void orgresetPasswordMail(String useremail, String userfirstname, String userid, String otpval){
        try {
            
            String changepw = System.label.MSD_CORE_Domain_URL +'/organic-reset-password?recordId='+userid+'&token='+otpval+'&utm_source=sfmc&utm_medium=email&utm_campaign=us_cross-brands_login_na_password-reset&utm_content=us-non-14018_reset-password';
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'mfr.noreply@merck.com'];
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            string[] to = new string[] {useremail};
            if(userfirstname == null){
                userfirstname = '';
            }    
            /* Updated Email Template - Sabari */   
            email.setHtmlBody('<html> <head> <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"> <meta name="viewport" content="width=device-width,initialscale=1"> <meta http-equiv="X-UA-Compatible" content="IE=edge"> <style type="text/css">@media screen and (max-width:480px){slot[style]{margin-right:0!important}.columnDiv{margin-right:0!important}}@media screen and (min-width:480px){slot[style]{margin-bottom:0!important}.columnDiv{margin-bottom:0!important}}</style> <style type="text/css">@media screen and (max-width:480px){.contentbuilderBaseColumnRow .columnCell{display:inline-block;width:100%}}</style> <style type="text/css">.contentpageDefaultEmailTemplatePageTemplate .contentRoot{width:600px}@media only screen and (max-width:480px){.contentpageDefaultEmailTemplatePageTemplate .contentRoot{width:320px}}</style> </head> <body> <table class="contentpageDefaultEmailTemplatePageTemplate" style="background-color:#e9eaec" role="presentation" id="contentpage_emailTemplateBodyContent" width="100%" cellpadding="0" cellspacing="0"> <tr> <td width="100%" align="center"> <table class="contentRoot" style="background-color:#fff" role="presentation" width="600" cellpadding="0" cellspacing="0"> <tr> <td style="padding-top:10px;padding-bottom:10px;padding-left:10px;padding-right:10px"> <table cellpadding="0" cellspacing="0" class="contentbuilderBaseColumnRow" style="align-items:flex-start;width:100%" width="100%"> <tr valign="top"> <td class="columnCell" style="vertical-align:top;display:inline-block;float:left" width="100%"> <table cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;word-break:break-word"> <tr> <td> <table cellpadding="0" cellspacing="0" id="contentRegion" style="width:100%;border-collapse:collapse;word-break:break-word"> <tr> <td align="Center"><img alt="" src="https://msdlogin--hhusportal.sandbox.file.force.com/file-asset-public/Header_1?oid=00D5C00000093k2" style="width:100%;display:block;border:none;max-width:100%;object-fit:fill" width="600"></td> </tr> </table> </td> </tr> </table> </td> </tr> </table> <table cellpadding="0" cellspacing="0" class="contentbuilderBaseColumnRow" style="align-items:flex-start;width:100%" width="100%"> <tr valign="top"> <td class="columnCell" style="vertical-align:top;display:inline-block;float:left" width="100%"> <table cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;word-break:break-word"> <tr> <td> <table cellpadding="0" cellspacing="0" id="contentregion" style="font-size:14px;width:100%;border-collapse:collapse;word-break:break-word"> <tr> <td class="contentbuilder-html" style="padding:0"> <p style="margin-top:32px;max-width:636px;min-height:36px;font-family:Arial!important;font-style:normal;font-weight:700;font-size:24px;line-height:36px;color:#333;flex:none;order:0;align-self:stretch;flex-grow:0;margin-left:24px;margin-right:24px">Reset your password.</p> <div style="font-family:Arial!important;font-style:normal;font-weight:400;font-size:16px;max-width:: 636px;min-height:132px"> <p style="font-family:Arial!important;font-size:16px;margin-left:24px;margin-right:24px;margin-Top:24px;margin-bottom:24px">Dear '+userfirstname+',</p> <p style="font-family:Arial!important;margin-left:24px;margin-right:24px;margin-bottom:24px;font-weight:400;font-size:16px;line-height:24px;color:#333">We have received a request to change your Merck Formulary Resources portal password. If you made this request, click the button below to reset your password.</p> </div> <table border="0" cellpadding="0" cellspacing="0" style="Margin-left:24px;margin-top:24px;border-radius:5px" width="100%"> <tr style="border-radius:5px"> <td align="left" style="border-radius:5px"> <table border="0" cellpadding="0" cellspacing="0" style="border-radius:5px" width="131"> <tr style="border-radius:5px"> <td style="background-color:#00857c;text-align:center;border-radius:5px;"> <!--[if mso]> <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="'+changepw+'" style="height:60px;v-textanchor:middle;width:200px;" arcsize="10%" stroke="f" fillcolor="#00857c"> <w:anchorlock/> <center><a href="'+changepw+'" style="width:200px;font-family:Arial;text-align:center;font-weight:700;color:#fff;text-decoration:none;font-size:14px;line-height:40px;">Reset password</a></center> </v:roundrect> <![endif]--> <!--[if !mso]><!--><a href="'+changepw+'" style="width:100%;padding:11px 3px;border:solid 1px #00857c;border-radius:5px;font-family:Arial;text-align:center;font-weight:700;letter-spacing:.861539px;color:#fff;text-decoration:none;font-size:14px;line-height:18px;font-weight:700;letter-spacing:.861539px;background-color:#00857c;color:#fff;display:inline-block">Reset password</a><![endif]--> </td> </table> </td> </tr> </table> <p style="font-family:Arial;font-style:normal;font-weight:400;font-size:14px;line-height:21px;color:#333;flex:none;order:1;align-self:stretch;flex-grow:0;max-width:636px;min-height:63px;margin-bottom:45px;margin-left:24px;margin-right:24px;align-self:stretch;margin-top:45px">If you did not recently attempt to register for a Merck login, you may disregard this email. If you have any questions, please call our technical support service at<br>1-800-489-5119 (Monday–Friday, 8 AM–7 PM ET).</p> <p style="max-width:636px;min-height:63px;font-weight:400;font-size:12px;line-height:18px;text-align:center;font-size:12px;font-family:Arial;font-weight:400;margin-left:24px;margin-right:24px;font-weight:400;font-size:12px;line-height:18px">This message was distributed from an email account used for sending messages only.<br>Please do not reply to this message.</p> <p style="max-width:636px;min-height:63px;margin-left:24px;margin-right:24px;margin-bottom:45px;font-weight:400;font-family:Arial;font-size:12px;line-height:18px;text-align:center;flex:none;order:1;align-self:stretch;flex-grow:0">Copyright © 2023 Merck &amp; Co., Inc., Rahway, NJ, USA and its affiliates.<br>All rights reserved.<br><br>US-NON-14018 08/23</p> </td> </tr> </table> </td> </tr> </table> </td> </tr> </table> </td> </tr> </table> </td> </tr> </table> </body> </html>');
            email.setToAddresses(to);
            email.setSubject('Reset your password');
            if ( owea.size() > 0 ) {
                email.setOrgWideEmailAddressId(owea.get(0).Id);
            }
  
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception e) {System.debug(e.getMessage() +'---' +e.getLineNumber());
        }
    }

    // used for reset password
    @AuraEnabled
    public static string orgresetPassword(String userId, String newPassword, String token){
        
        String returnval = '';
        try {
            System.debug('UserId-->'+userId);
            System.debug('newPassword-->'+newPassword);
            System.debug('token-->'+token);
            List<MSD_CORE_OTP__c> otllst = [SELECT Id, MSD_CORE_Token__c, MSD_CORE_Payor__c, MSD_CORE_Status__c FROM MSD_CORE_OTP__c WHERE MSD_CORE_Token__c  =: token AND MSD_CORE_Payor__c =: userId];
            System.debug('otllst-->'+otllst.size());
            if (otllst.size()>0) {
                otllst[0].MSD_CORE_Status__c = 'Used';
                System.setPassword(userId,newPassword);
                update otllst; 
                User usr = [SELECT Id, Name, FirstName, Email FROM User WHERE Id =: userId LIMIT 1];
                orgupdatePasswordMail(usr.Email , usr.FirstName);
                System.debug('Success');
                returnval = 'Success!';
            }
        } catch (Exception e) {
            System.debug('Error->>'+e.getMessage());
            if (e.getMessage() == 'UNKNOWN_EXCEPTION: invalid repeated password') {
                returnval = System.label.MSD_CORE_OldPasswordNotUse;
            } else {
                returnval = System.label.MFRGeneralErrorMessage;    
            }
        }
        return returnval;
    }

    // to send the reset password email
    public static void orgupdatePasswordMail(String useremail, String userfirstname){
        try {
            String headerURL = System.label.mSD_CORE_EmailHeader;
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'mfr.noreply@merck.com'];
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            string[] to = new string[] {useremail};
            email.setToAddresses(to);
            email.setSubject('Reset your password');
            /* Updated Email Template - Sabari MFRUS-136*/
            email.setHtmlBody('<html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"><meta name="viewport" content="width=device-width,initialscale=1"><meta http-equiv="X-UA-Compatible" content="IE=edge"><style type="text/css">@media screen and (max-width:480px){slot[style]{margin-right:0!important}.columnDiv{margin-right:0!important}}@media screen and (min-width:480px){slot[style]{margin-bottom:0!important}.columnDiv{margin-bottom:0!important}}</style><style type="text/css">@media screen and (max-width:480px){.contentbuilderBaseColumnRow .columnCell{display:inline-block;width:100%}}</style><style type="text/css">.contentpageDefaultEmailTemplatePageTemplate .contentRoot{width:600px}@media only screen and (max-width:480px){.contentpageDefaultEmailTemplatePageTemplate .contentRoot{width:320px}}</style></head><body><table class="contentpageDefaultEmailTemplatePageTemplate" style="background-color:#e9eaec" role="presentation" id="contentpage_emailTemplateBodyContent" width="100%" cellpadding="0" cellspacing="0"><tr><td width="100%" align="center"><table class="contentRoot" style="background-color:#fff" role="presentation" width="600" cellpadding="0" cellspacing="0"><tr><td style="padding-top:10px;padding-bottom:10px;padding-left:10px;padding-right:10px"><table cellpadding="0" cellspacing="0" class="contentbuilderBaseColumnRow" style="align-items:flex-start;width:100%" width="100%"><tr valign="top"><td class="columnCell" style="vertical-align:top;display:inline-block;float:left" width="100%"><table cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;word-break:break-word"><tr><td><table cellpadding="0" cellspacing="0" id="contentRegion" style="width:100%;border-collapse:collapse;word-break:break-word"><tr><td align="Center"><img alt="" src="https://msdlogin--hhusportal.sandbox.file.force.com/file-asset-public/Header_1?oid=00D5C00000093k2" style="width:100%;display:block;border:none;max-width:100%;object-fit:fill" width="600"></td></tr></table></td></tr></table></td></tr></table><table cellpadding="0" cellspacing="0" class="contentbuilderBaseColumnRow" style="align-items:flex-start;width:100%" width="100%"><tr valign="top"><td class="columnCell" style="vertical-align:top;display:inline-block;float:left" width="100%"><table cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;word-break:break-word"><tr><td><table cellpadding="0" cellspacing="0" id="contentregion" style="font-size:14px;width:100%;border-collapse:collapse;word-break:break-word"><tr><td class="contentbuilder-html" style="padding:0"><p style="margin-top:32px;max-width:636px;min-height:36px;font-family:Arial!important;font-style:normal;font-weight:700;font-size:24px;line-height:36px;color:#333;flex:none;order:0;align-self:stretch;flex-grow:0;margin-left:24px;margin-right:24px">Your password has been updated.</p><div style="font-family:Arial!important;font-style:normal;font-weight:400;font-size:16px;max-width:: 636px;min-height:132px"><p style="font-family:Arial!important;font-size:16px;margin-left:24px;margin-right:24px;margin-Top:24px;margin-bottom:24px">Dear '+userfirstname+',</p><p style="font-family:Arial!important;margin-left:24px;margin-right:24px;margin-bottom:24px;font-weight:400;font-size:16px;line-height:24px;color:#333">Your password has been changed.</p><p style="font-family:Arial!important;margin-left:24px;margin-right:24px;margin-bottom:24px;font-weight:400;font-size:16px;line-height:24px;color:#333">If you did not request a password change, please contact technical support.</p></div><table border="0" cellpadding="0" cellspacing="0" style="Margin-left:24px;margin-top:24px;border-radius:5px" width="100%"><tr style="border-radius:5px"><td align="left" style="border-radius:5px"><table border="0" cellpadding="0" cellspacing="0" style="border-radius:5px" width="131"><tr style="border-radius:5px"><td style="background-color:#00857c;text-align:center;border-radius:5px;"><!--[if mso]><v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="'+System.label.MSD_CORE_Domain_URL+'/my-contacts/?utm_source=sfmc&utm_medium=email&utm_campaign=us_cross-brands_login_na_password-updated" style="height:60px;v-textanchor:middle;width:200px;" arcsize="10%" stroke="f" fillcolor="#00857c"><w:anchorlock/><center><a href="'+System.label.MSD_CORE_Domain_URL+'/my-contacts/?utm_source=sfmc&utm_medium=email&utm_campaign=us_cross-brands_login_na_password-updated" style="width:200px;font-family:Arial;text-align:center;font-weight:700;color:#fff;text-decoration:none;font-size:14px;line-height:40px;">Contact support</a></center></v:roundrect><![endif]--><!--[if !mso]><!--><a href="'+System.label.MSD_CORE_Domain_URL+'/my-contacts/?utm_source=sfmc&utm_medium=email&utm_campaign=us_cross-brands_login_na_password-updated" style="width:100%;padding:11px 3px;border:solid 1px #00857c;border-radius:5px;font-family:Arial;text-align:center;font-weight:700;letter-spacing:.861539px;color:#fff;text-decoration:none;font-size:14px;line-height:18px;font-weight:700;letter-spacing:.861539px;background-color:#00857c;color:#fff;display:inline-block">Contact support</a><![endif]--></td></table></td></tr></table><p style="font-family:Arial;font-style:normal;font-weight:400;font-size:14px;line-height:21px;color:#333;flex:none;order:1;align-self:stretch;flex-grow:0;max-width:636px;min-height:63px;margin-bottom:45px;margin-left:24px;margin-right:24px;align-self:stretch;margin-top:45px">If you did not recently attempt to register for a Merck login, you may disregard this email. If you have any questions, please call our technical support service at<br>1-800-489-5119 (Monday–Friday, 8 AM–7 PM ET).</p><p style="max-width:636px;min-height:63px;font-weight:400;font-size:12px;line-height:18px;text-align:center;font-size:12px;font-family:Arial;font-weight:400;margin-left:24px;margin-right:24px;font-weight:400;font-size:12px;line-height:18px">This message was distributed from an email account used for sending messages only.<br>Please do not reply to this message.</p><p style="max-width:636px;min-height:63px;margin-left:24px;margin-right:24px;margin-bottom:45px;font-weight:400;font-family:Arial;font-size:12px;line-height:18px;text-align:center;flex:none;order:1;align-self:stretch;flex-grow:0">Copyright © 2023 Merck &amp; Co., Inc., Rahway, NJ, USA and its affiliates.<br>All rights reserved.<br><br>US-NON-14018 08/23</p></td></tr></table></td></tr></table></td></tr></table></td></tr></table></td></tr></table></body></html>');
            if ( owea.size() > 0 ) {
                email.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception e) {
            System.debug(e.getMessage() +'---' +e.getLineNumber());
        }
    }

}