/**
* @File Name : MSD_CORE_HEQ_AuthController.cls
* @Description : This class is responsible for managing customer invitation workflows, including sending registration invites, handling user registration, and managing login processes.
* @Author : Gopi Chintamaneni (Focal CXM)
* @Last Modified By : Gopi Chintamaneni
* @Last Modified On : August 24, 2024
**/

public without sharing class MSD_CORE_HEQ_AuthController {

    @AuraEnabled
    public static String sendRegistrationInvite(String accountId) {
        try {
            User aeUser;
            System.debug('AccountId>>>>: ' + accountId);

            /* Fetch Account and User data */
            Account userAccount = [SELECT Id, Name, PersonEmail FROM Account WHERE Id = :accountId LIMIT 1];
            if (userAccount == null || String.isBlank(userAccount.PersonEmail)) {
                return 'Account not found or missing email address.';
            }

            /* Fetch or create User Preference */
            MSD_CORE_HEQ_UserPreference__c userPreference;
            Boolean registrationStatus = false;
            List<MSD_CORE_HEQ_UserPreference__c> userPreferenceList = [SELECT Id, MSD_CORE_Is_Invited__c, MSD_CORE_Invited_By__c
                                                                        FROM MSD_CORE_HEQ_UserPreference__c 
                                                                        WHERE MSD_CORE_Account__c = :accountId AND MSD_CORE_Is_Active__c = true
                                                                        LIMIT 1];

            if (userPreferenceList.isEmpty()) {
                userPreference = new MSD_CORE_HEQ_UserPreference__c();
                userPreference.MSD_CORE_Account__c = accountId;
                userPreference.MSD_CORE_Invited_By__c = UserInfo.getUserId();
                userPreference.MSD_CORE_Invited_Date__c = System.now();
                userPreference.MSD_CORE_Is_Active__c = true;
                aeUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
            } else {
                userPreference = userPreferenceList[0];
                registrationStatus = userPreference.MSD_CORE_Is_Invited__c;
                aeUser = [SELECT Id, Name FROM User WHERE Id = :userPreference.MSD_CORE_Invited_By__c];
            }

            /* Fetch Health EQ Application Settings */
            MSD_CORE_HEQ_Portal_Setting__mdt[] heqSettings = [select id, MSD_CORE_HEQ_ORG_Wide_Address__c, DeveloperName from MSD_CORE_HEQ_Portal_Setting__mdt where DeveloperName='MSD_CORE_Health_EQ_Portal'];
            String orgwideadd = heqSettings[0].MSD_CORE_HEQ_ORG_Wide_Address__c;

            /* Fetch Email Template */
            String templateName = registrationStatus ? 'MSD_CORE_HEQ_Invitation_Reminder_Customer' : 'MSD_CORE_HEQ_Invite_Customer';
            EmailTemplate emailTemplate = [SELECT Id, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1];
            if (emailTemplate == null) {
                return 'Email template not found.';
            }

            /* Customize Email Body and Subject */
            String emailBody = emailTemplate.HtmlValue
                .replace('{aeName}', aeUser.Name)
                .replace('{registerBtn}', '<a href="' + System.Label.MSD_CORE_HEQ_RegisterLink + '" style="display: inline-block; color: #FFFFFF; text-decoration: none; font-size: 14px; font-weight: 700; line-height: 20px; text-align: center; background-color: #00857C; padding: 8px 16px; border-radius: 5px; font-family: Arial, sans-serif;">REGISTER</a>')
                .replace('{privacyLink}', '<a href="' + System.Label.MSD_CORE_HEQ_PrivacyLink + '"> Merck Privacy Statement. </a>');

            String formattedSubject = emailTemplate.Subject.replace('{aeName}', aeUser.Name);

            /* Send the email */
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {userAccount.PersonEmail});
            email.setSubject(formattedSubject);
            email.setHtmlBody(emailBody);
            email.setSaveAsActivity(false);

            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :orgwideadd LIMIT 1];
            if (!owea.isEmpty()) {
                email.setOrgWideEmailAddressId(owea[0].Id);
            }

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});

            /* Update or create User Preference */
            userPreference.MSD_CORE_Is_Invited__c = true;
            userPreference.MSD_CORE_Invited_Date__c =  System.now();
            if (userPreference.Id == null) {
                insert userPreference;
            } else {
                update userPreference;
            }

            return 'Success';
        } catch (Exception e) {
            return 'Error sending email: ' + e.getMessage();
        }
    }

    @InvocableMethod(label = 'HEQ Customer Invitation Reminder'
                     description = 'Sends reminder email to customer')
    public static void sendReminderInvite(List < EmailProperties > emailPropertiesList) {
        try{
            MSD_CORE_HEQ_UserPreference__c userPreferenceList = [SELECT Id, MSD_CORE_Account__c FROM MSD_CORE_HEQ_UserPreference__c
                                                                        WHERE Id = :emailPropertiesList[0].recordId AND MSD_CORE_Is_Active__c = true
                                                                        LIMIT 1];
            MSD_CORE_HEQ_AuthController.sendRegistrationInvite(userPreferenceList.MSD_CORE_Account__c);
        } catch(Exception e){
            System.debug('Error sending reminder Invitation: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id createCustomerPortalUser(String email, String firstName, String lastName, String uuid) {
        try {
            List<Account> accounts = [SELECT Id, PersonEmail FROM Account WHERE PersonEmail = :email AND IsPersonAccount = TRUE LIMIT 1];
            String password;
            String accountId;
            Id newUserId;
            User newUser = new User();

            if (!accounts.isEmpty()) {
                accountId = accounts[0].Id;
                String accountEmail = accounts[0].PersonEmail;

                List<User> existingUsers = [SELECT Id FROM User WHERE Email = :accountEmail AND Profile.Name = 'HEQ Customer' AND IsActive = true LIMIT 1];

                if (existingUsers.isEmpty()) {
                    Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'HEQ Customer' LIMIT 1];

                    password = MSD_CORE_HEQ_AuthController.generateRandomPassword(10);

                    newUser.Email = accountEmail;
                    newUser.Username = accountEmail+'.heqPortal';
                    newUser.FirstName = firstName;
                    newUser.LastName = lastName;
                    newUser.CommunityNickname = 'user'+String.valueOf(Datetime.now());
                    newUser.ProfileId = userProfile.Id;

                    /* Create customer user for the given account */
                    newUserId = Site.createExternalUser(newUser, accountId, password, false);

                    /* Create DIH Mapping record for current user */
                    MSD_CORE_HEQ_DIH_Mapping__c userMappingRecord = new MSD_CORE_HEQ_DIH_Mapping__c();
                    userMappingRecord.Name = firstName + ' ' + lastName;
                    userMappingRecord.MSD_CORE_Username__c = newUser.Username;
                    userMappingRecord.MSD_CORE_Password__c = MSD_CORE_HEQ_AuthController.aesEncryption(password);
                    userMappingRecord.MSD_CORE_UUID__c = uuid;
                    userMappingRecord.MSD_CORE_User__c = newUserId;
                    insert userMappingRecord;

                    /* Set user invitation status to registered */
                    MSD_CORE_HEQ_UserPreference__c userPreferenceList = [SELECT Id, MSD_CORE_Account__c FROM MSD_CORE_HEQ_UserPreference__c
                                                                        WHERE MSD_CORE_Account__c = :accountId AND MSD_CORE_Is_Active__c = true
                                                                        LIMIT 1];
                    if(userPreferenceList != null){
                        userPreferenceList.MSD_CORE_Invited_Date__c = null;
                        update userPreferenceList;
                    }
                }else{
                    newUserId = '005cW000001cnn7QAA'; // added for testing can be removed
                }
            }
            return newUserId;
        } catch (Site.ExternalUserCreateException e) {
            System.debug('User creation failed: ' + e.getMessage());
            throw e;
        }
    }

    public static String aesEncryption(String token) {
        String encryptedToken = null;

        try {
            Blob key = Blob.valueOf(System.Label.MSD_CORE_HEQ_Encryption_Key);//rethink if this can be stored in custom metadata instead.
            Blob tokenBlob = Blob.valueOf(token);

            Blob encryptedBlob = Crypto.encryptWithManagedIV('AES256', key, tokenBlob);

            encryptedToken = EncodingUtil.base64Encode(encryptedBlob);
        } catch (Exception e) {
            System.debug('aesEncryption failed: ' + e.getMessage());
        }

        return encryptedToken;
    }

    public static String aesDecryption(String encryptedToken) {
        String decryptedToken = null;

        try {
            Blob key = Blob.valueOf(System.Label.MSD_CORE_HEQ_Encryption_Key);
            Blob encryptedBlob = EncodingUtil.base64Decode(encryptedToken);

            Blob decryptedBlob = Crypto.decryptWithManagedIV('AES256', key, encryptedBlob);

            decryptedToken = decryptedBlob.toString();
        } catch (Exception e) {
            System.debug('aesDecryption failed: ' + e.getMessage());
        }

        return decryptedToken;
    }

    public static String generateRandomPassword(Integer length) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz@#$^&*()_!';
        String randStr = '';
        while (randStr.length() < length) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr+'@Aa12'; 
    }

    @AuraEnabled
    public static String dihUserLogin(String email, String firstName, String lastName, String uuid){
        String result = '';
        try {

            Id userReg = MSD_CORE_HEQ_AuthController.createCustomerPortalUser(email, firstName, lastName, uuid);

            if(userReg != null){
                List<MSD_CORE_HEQ_DIH_Mapping__c> userMapping = [SELECT Id, MSD_CORE_Username__c, MSD_CORE_Password__c FROM MSD_CORE_HEQ_DIH_Mapping__c WHERE MSD_CORE_UUID__c = :uuid LIMIT 1];

                if (!userMapping.isEmpty()) {
                    MSD_CORE_HEQ_DIH_Mapping__c mapping = userMapping[0];
                    String username = mapping.MSD_CORE_Username__c;
                    String password = mapping.MSD_CORE_Password__c;
                
                    if (username != null && password != null) {
                        try {
                            password = MSD_CORE_HEQ_AuthController.aesDecryption(password);
                            ApexPages.PageReference userLogin = Site.login(username, password, '');
                            result = (userLogin != null) ? userLogin.getUrl() : 'Error';
                        } catch (Exception e) {
                            System.debug('Login failed: ' + e.getMessage());
                        }
                    } else {
                        System.debug('Username or Password is null.');
                        result = 'Username or Password is null';
                    }
                } else {
                    System.debug('No mapping found for the given UUID.');
                    result = 'No mapping found for the given UUID.';
                }
            }else{
                result = 'User registration failed';
            }

        } catch (Exception e) {
            throw e;
        }
        return result;
    }

    public class EmailProperties {
        @InvocableVariable(label = 'RecordId'
                           description = 'Id of the triggering record'
                           required = true)
        public String recordId;
    }

}