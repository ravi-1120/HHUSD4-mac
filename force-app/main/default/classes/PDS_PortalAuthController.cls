/*
* Class: PDS_PortalAuthController
* Test Class: PDS_PortalAuthControllerTest
* Description: Handles PDS portal user authentication activities.
* Author: Gopi Chintamaneni
* Created On: 03/28/2024
* Last Modified: 05/31/2024
* Version: Initial
*/
public without sharing class PDS_PortalAuthController {
    
    @AuraEnabled
    public static String userAuth(String useremail, String password){
        String result = '';
        try {
            if (useremail != null && password != null) {
                // Query User to get the Id based on the username
                User user = [SELECT Id, Username FROM User WHERE Email = :useremail AND Profile.Name = 'PDS Taskforce' ORDER BY CreatedDate ASC LIMIT 1];
                if (user != null) {
                    // Query UserLogin to check if the user is active
                    UserLogin login = [SELECT Id, IsPasswordLocked FROM UserLogin WHERE UserId = :user.Id LIMIT 1];
                    if (login != null && login.IsPasswordLocked == false) {
                        // User is active
                        ApexPages.PageReference userLogin = Site.login(user.Username, password, '');
                        result = (userLogin != null) ? userLogin.getUrl() : System.Label.PDS_Login_Error;
                    } else {
                        // User password locked
                        result = System.Label.PDS_Portal_User_Locked;
                    }
                } else {
                    // User not found
                    result = System.Label.PDS_Login_Error;
                }
            } else {
                // Null check failed
                result = System.Label.PDS_Login_Error;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled
    public static String forgotPassword(String useremail){
        String returnval = '';
        try {
            List<User> userlst = [SELECT Id, FirstName, Email, Profile.Name FROM User WHERE Email =: useremail AND Profile.Name = 'PDS Taskforce' ORDER BY CreatedDate ASC LIMIT 1];
            if (userlst.size()>0) {
                //System.resetPassword(userlst[0].Id, false);
                PDS_PortalAuthController.forgotPasswordMail(userlst[0].Email, userlst[0].FirstName, userlst[0].Id);
                returnval = 'Reset Password Link Sent';
            } else {
                returnval = 'Please enter a valid email address that is associated with your account';
            }
            
        } catch (Exception e) {returnval = e.getMessage() +'---' +e.getLineNumber();
                              }
        return returnval;
    }   
    
    public static void forgotPasswordMail(String useremail, String userfirstname, String userid){
        try {
            String changepw = generatePasswordResetURL(userid, 24, false);
            PDS_Application_Setting__mdt[] pdsSettings = [select id,PDS_OrgWideEmailAddress__c,DeveloperName from PDS_Application_Setting__mdt where DeveloperName='MDP_Flow_Settings'];
            String orgwideadd = pdsSettings[0].PDS_OrgWideEmailAddress__c;
            OrgWideEmailAddress[] owea = [Select Id from OrgWideEmailAddress where Address =:orgwideadd];
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            string[] to = new string[] {useremail};
            email.setToAddresses(to);
            System.debug('to'+to);
            String emailHeader = System.Label.PDS_Forgot_EmailHeader;
            String emailBody = System.Label.PDS_Forgot_EmailBody;
            String emailFooter = System.Label.PDS_Forgot_EmailFooter;
            String emailFooterImg = System.Label.PDSMSDLogo;
            String emailHeaderImg  = System.Label.PDSMEDSLogo;
            System.debug('emailBody'+emailBody);
            emailHeader = emailHeader.replace('{medsUrl}',emailHeaderImg);
            emailHeader = emailHeader.replace('{0}', userfirstname);
			emailHeader = emailHeader.replace('{1}', changepw);
            emailFooter = emailFooter.replace('{imgURL}',emailFooterImg);
            String emailAll = emailHeader+emailBody+emailFooter;
            email.setHtmlBody(emailAll);
            //email.setHtmlBody('<html>Dear ' + userfirstname + ',<br/>' +'<p>We have received a request to change your PDS portal password. If you made this request, click the button below to reset your password.</p><br><a href="' + changepw + '" style="font-size:15px;font-family:Arial;width:180px;height:250px;color:#fff;border-color:#00857C;background:linear-gradient(#00857C, #00857C);text-decoration:none;padding:8px;border-radius:8px;background-color:#00857C;position:relative !important;bottom:8px;">Reset Password</a></html>');
            email.setSubject('Password Reset Request');
            if ( owea.size() > 0 ) {
                email.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            System.debug('useremail'+useremail);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('email'+email);
        } catch (Exception e) {
            System.debug(e.getMessage() +'---' +e.getLineNumber());
        }
    }

    @AuraEnabled
    public static String generatePasswordResetURL(String userId, Integer hours, Boolean newUser) {
        try {
            Datetime expirationDatetime = Datetime.now().addHours(hours);
            String token = String.valueOf(Crypto.getRandomInteger());
            
            // Construct the token string without the checksum
            String tokenStringWithoutChecksum = userId + '|' + expirationDatetime.format('yyyy-MM-dd HH:mm:ss') + '|' + token + '|' + newUser;
            
            // Calculate checksum for the token string
            String checksum = calculateChecksum(Blob.valueOf(tokenStringWithoutChecksum));
            
            String tokenString = tokenStringWithoutChecksum + '|' + checksum;
            
            // Encrypt the token
            Blob key = Blob.valueOf('OHXgkcYAK4Es8prsIVIaOkiyQdJxjtkg');
            Blob encryptedToken = Crypto.encryptWithManagedIV('AES256', key, Blob.valueOf(tokenString));
            
            // Convert the encrypted token to Base64 string
            String encryptedTokenBase64 = EncodingUtil.base64Encode(encryptedToken);
            
            // Construct the password reset URL with the encrypted token as a parameter
            String passwordResetURL = System.label.PDS_Portal_URL+'/change-password?token=' + EncodingUtil.urlEncode(encryptedTokenBase64, 'UTF-8');
            return passwordResetURL;
        } catch (Exception e) {
            throw new AuraHandledException('Error generating password reset URL: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, String> decryptToken(String encryptedToken) {
        Map<String, String> resultMap = new Map<String, String>();
        String status = 'Invalid';
        String userId;
        String newUser;

        try {
            // Decrypt the token
            Blob key = Blob.valueOf('OHXgkcYAK4Es8prsIVIaOkiyQdJxjtkg');
            String decodedToken = EncodingUtil.urlDecode(encryptedToken, 'UTF-8');
            Blob decryptedBlob = Crypto.decryptWithManagedIV('AES256', key, EncodingUtil.base64Decode(decodedToken.replace(' ', '+')));
            String decryptedToken = decryptedBlob.toString();

            System.debug('Decrypted token: ' + decryptedToken);

            // Split decrypted token and checksum
            List<String> tokenParts = decryptedToken.split('\\|');
            // if (tokenParts.size() != 5) {
            //     throw new IllegalArgumentException('Invalid token format');
            // }

            // Extract token components
            userId = tokenParts[0];
            String expirationDateString = tokenParts[1];
            String token = tokenParts[2];
            newUser = tokenParts[3];
            String providedChecksum = tokenParts[4];

            System.debug('userId: ' + userId);
            System.debug('expirationDateString: ' + expirationDateString);
            System.debug('token: ' + token);
            System.debug('providedChecksum: ' + providedChecksum);
            System.debug('newUser: ' + newUser);

            // Calculate checksum for the token components
            String tokenString = userId + '|' + expirationDateString + '|' + token + '|' + newUser;
            String calculatedChecksum = calculateChecksum(Blob.valueOf(tokenString));

            System.debug('calculatedChecksum: ' + calculatedChecksum);

            // Verify checksum
            if (!providedChecksum.equals(calculatedChecksum)) {
                System.debug('Checksum does not match.');
                status = 'Invalid';
            } else {
                // Check expiration date
                Datetime expirationDate = Datetime.valueOf(expirationDateString);
                System.debug('Parsed expirationDate: ' + expirationDate);

                Integer hoursToAdd = newUser.toLowerCase() == 'true' ? 72 : 24;
                System.debug('hoursToAdd based on newUser: ' + hoursToAdd);

               // Datetime expirationThreshold = Datetime.now().addHours(hoursToAdd);
                System.debug('Current datetime: ' + expirationDate);
                //System.debug('Expiration threshold: ' + expirationThreshold);

                if (expirationDate > Datetime.now()) {
                    if(newUser == 'true'){
                        status = 'Valid New User';
                    }else{
                        status = 'Valid';
                    }
                } else {
                    System.debug('Token is expired.');
                }
            }

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }

        resultMap.put('status', status);
        resultMap.put('userId', userId);
        resultMap.put('newUser', newUser);
        
        return resultMap;
    }


    @AuraEnabled
    public static String changeUserPassword(String encryptedToken, String newPassword) {
        String resetStatus;
        String userId;
        try {
            // Decrypt the token
            Blob key = Blob.valueOf('OHXgkcYAK4Es8prsIVIaOkiyQdJxjtkg');
            String decodedToken = EncodingUtil.urlDecode(encryptedToken, 'UTF-8');
            Blob decryptedBlob = Crypto.decryptWithManagedIV('AES256', key, EncodingUtil.base64Decode(decodedToken.replace(' ', '+')));
            String decryptedToken = decryptedBlob.toString();
            
            // Split decrypted token and checksum
            List<String> tokenParts = decryptedToken.split('\\|');
            
            // Extract token components
            userId = tokenParts[0];
            String expirationDateString = tokenParts[1];
            resetStatus = PDS_PortalAuthController.setUserPassword(userId,newPassword);

        } catch (Exception e) {
            System.debug('Resetting Password Error: ' + e.getMessage());
            resetStatus = 'Failed';
        }
        return resetStatus;
    }

    @AuraEnabled
    public static String setUserPassword(String userId, String newPassword) {
        String resetStatus;
        try{
            System.setPassword(userId, newPassword);
            resetStatus = 'Reset Success';
        }catch(Exception e){
            System.debug('Resetting Password Error: ' + e.getMessage());
            resetStatus = e.getMessage();
        }
        return resetStatus;
    }

    // Method to calculate checksum using SHA-256
    private static String calculateChecksum(Blob data) {
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', data));
    }

    @InvocableMethod(label = 'Generate and send MEDs Welcome Email'
                     description = 'Sends activation link to new MEDs user')
    public static void generateWelcomeEmail(List < EmailProperties > emailPropertiesList) {

        EmailTemplate emailTemplate = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate  WHERE DeveloperName = 'PDS_Welcome_Email' LIMIT 1];
        PDS_Application_Setting__mdt[] pdsSettings = [select id,PDS_OrgWideEmailAddress__c,DeveloperName from PDS_Application_Setting__mdt where DeveloperName='MDP_Flow_Settings'];
        String orgwideadd = pdsSettings[0].PDS_OrgWideEmailAddress__c;
        
        OrgWideEmailAddress[] owea = [Select Id from OrgWideEmailAddress where Address =:orgwideadd];

        if (emailTemplate == null) {
            System.debug('Email Template not found!');
        }

        // Generate the dynamic link
        String encryptedLink = generatePasswordResetURL(emailPropertiesList[0].recordId, 72, true);

        String emailBody = emailTemplate.HtmlValue
        .replace('{activationLink}', '<a href="' + encryptedLink + '" style="display: inline-block; color: #FFFFFF; text-decoration: none; font-size: 14px; font-weight: 700; line-height: 20px; text-align: center; background-color: #00857C; padding: 8px 16px; border-radius: 5px; font-family: Arial, sans-serif;">Activate</a>')
        .replace('{managerEmail}', System.Label.PDS_Manager_Email)
        .replace('{userName}', emailPropertiesList[0].recordUserName);


        // Create the email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(emailPropertiesList[0].recordId);
        email.setTemplateId(emailTemplate.Id);
        email.setSaveAsActivity(false);
        email.setHtmlBody(emailBody);
        email.setSubject(emailTemplate.Subject);

        if ( owea.size() > 0 ) {
            email.setOrgWideEmailAddressId(owea.get(0).Id);
        }

        email.setToAddresses(new String[] { emailPropertiesList[0].userEmail });

        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        if (results[0].isSuccess()) {
            System.debug('Email sent successfully.');
        } else {
            System.debug('Failed to send email: ' + results[0].getErrors()[0].getMessage());
        }
    }

    @AuraEnabled
    public static void resendWelcomeEmail(Id userId, Boolean isNewUser) {
        try {
            User user = [SELECT Id, FirstName, Email FROM User WHERE Id = :userId LIMIT 1];
            if (user == null) {
                throw new AuraHandledException('User not found');
            }

            List<PDS_PortalAuthController.EmailProperties> emailPropertiesList = new List<PDS_PortalAuthController.EmailProperties>();
            PDS_PortalAuthController.EmailProperties emailProps = new PDS_PortalAuthController.EmailProperties();
            emailProps.recordId = user.Id;
            emailProps.userEmail = user.Email;
            emailProps.recordUserName = user.FirstName;
            emailPropertiesList.add(emailProps);

            if(isNewUser == true){
                PDS_PortalAuthController.generateWelcomeEmail(emailPropertiesList);
            }else{
                PDS_PortalAuthController.forgotPasswordMail(user.Email, user.FirstName, userId);
            }
            

        } catch (Exception e) {
            throw new AuraHandledException('Failed to send welcome email: ' + e.getMessage());
        }
    }

    public class EmailProperties {
        @InvocableVariable(label = 'RecordId'
                           description = 'Id of the User'
                           required = true)
        public String recordId;
        @InvocableVariable(label = 'UserEmail'
                        description = 'Email address of the User'
                        required = true)
        public String userEmail;
        @InvocableVariable(label = 'UserName'
                       description = 'Name of the User'
                       required = false)
        public String recordUserName;
    }
}