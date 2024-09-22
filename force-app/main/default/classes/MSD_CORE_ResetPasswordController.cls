public without sharing class MSD_CORE_ResetPasswordController {
   
    @AuraEnabled
    public static string resetPassword(String userId, String newPassword){
        
        String returnval = '';
        try {

            System.setPassword(userId,newPassword);
            returnval = 'Password Set Successfully!';
        } catch (Exception e) {
            System.debug('Error in ResetPassword-->'+e.getMessage());
            returnval = e.getMessage() + '----' +e.getLineNumber();
        }
        return returnval;
    }

    @AuraEnabled
    public static string createPassword(String accountID, String newPassword) {
        try {
            String returnval = '';
            List<User> userData;
            if (accountID != null && accountID != '') {
                userData = [SELECT Id, Name, Email, AccountId, Contact.Name, Contact.FirstName, CreatedDate FROM User WHERE AccountId != null AND AccountId = :accountID LIMIT 1];
            } else if (accountID != '') {
                userData = [SELECT Id, Name, Email, AccountId, Contact.Name, Contact.FirstName, CreatedDate FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            }

            if (userData != null && !userData.isEmpty()) {
                System.setPassword(userData[0].Id, newPassword);
                returnval = 'Success!';
            } else {
                returnval = 'No user found';
            }
            return returnval;
        } catch (Exception e) {
            if (e.getMessage().equals('UNKNOWN_EXCEPTION: invalid repeated password')) {
                return System.label.MSD_CORE_OldPasswordNotUse;
            } else {
                return System.label.MFRGeneralErrorMessage;
            }
        }
    }

    @AuraEnabled
    public static String doLogin(String accountID, String password, String startURLval, String brandId) {
        try {
            String usernm;

            List<User> userData;
            if (accountID != null && accountID != '') {
                userData = [SELECT Id, Name, Email, AccountId, Contact.Name, Contact.FirstName, CreatedDate FROM User WHERE AccountId != null AND AccountId = :accountID LIMIT 1];
            } else if (accountID != '') {
                userData = [SELECT Id, Name, Email, AccountId, Contact.Name, Contact.FirstName, CreatedDate FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            }

            if (userData[0] != null) {
                System.debug('userData[0].Email-->' + userData[0].Email);
                User usr = [SELECT Id, Name, Username, Email FROM User WHERE Email = :userData[0].Email AND Profile.Name = 'MRK_Payor_Exec' ORDER BY LastmodifiedDate DESC LIMIT 1];
                usernm = usr.Username;
                List<MSD_CORE_Eligibility__c> elig = [SELECT Id, MSD_CORE_Eligibility_Expired__c FROM MSD_CORE_Eligibility__c WHERE MSD_CORE_Payor__c = :usr.Id];
                startURLval = (elig.size() > 0 && elig[0].MSD_CORE_Eligibility_Expired__c) ? System.label.MSD_CORE_Domain_URL + '/settings?tab=2' : null;
            } else {
                return 'Email does not exist!';
            }

            if(String.isNotBlank(brandId) && brandId != 'undefined') {
                startURLval = System.label.MSD_CORE_Domain_URL + '/product/productdetail?recordId='+brandId;
            }

            if (startURLval == null) {
                startURLval = System.label.MSD_CORE_Domain_URL + '/dashboard';
            }

            ApexPages.PageReference pageRef = Site.login(usernm, password, startURLval);
            return (pageRef != null) ? pageRef.getUrl() : null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}