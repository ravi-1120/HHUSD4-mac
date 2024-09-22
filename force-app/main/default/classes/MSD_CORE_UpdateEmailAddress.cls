public without Sharing class MSD_CORE_UpdateEmailAddress {
    @AuraEnabled
    public static string doAuthorize(String userId, String email, string newEmail){
        string returnVal = '';
        try {
            List<User> userlst = [SELECT Id, FirstName, Email, Profile.Name FROM User WHERE Id =: userId  AND Profile.Name = 'MRK_Payor_Exec' ORDER BY CreatedDate ASC LIMIT 1];
            List<MFR_Config__mdt> config = [select Id, MasterLabel, MSD_CORE_Duration__c from MFR_Config__mdt WHERE DeveloperName = 'OTP_Expiration_Duration'];
            if (userlst.size()>0) {
                MSD_CORE_OTP__c otp = new MSD_CORE_OTP__c();
                otp.MSD_CORE_Payor__c = userlst[0].Id;
                otp.MSD_CORE_Type__c = 'Email Change';
                system.debug('Duration is '+config[0].MSD_CORE_Duration__c);
                otp.MSD_CORE_Expiration_DateTime__c = System.now().addMinutes(Integer.valueOf(config[0].MSD_CORE_Duration__c));
                otp.MSD_CORE_New_Email__c = newEmail;
                otp.MSD_CORE_Status__c = 'New';
                otp.MSD_CORE_Token__c = String.valueOf(Math.round((Math.random() * (900000) + 100000)));
                insert otp;
                returnVal = 'success';
            } else{
                returnVal = '';
            }
            
        } catch (Exception e){
            system.debug('Exception is '+e);
        }
        return returnVal;
    }
    
    @AuraEnabled
    public static string doValidateOTP(String userId, String isUsed, String enteredOTP, String emailId){
        system.debug('email received to update is '+emailId);
        string returnVal = '';
        try{
            list<MSD_CORE_OTP__c> otpcheck = [select Id, Name, MSD_CORE_Payor__c, MSD_CORE_Token__c, MSD_CORE_Status__c, MSD_CORE_Expired__c from MSD_CORE_OTP__c where MSD_CORE_Token__c =: string.valueOf(enteredOTP) AND MSD_CORE_Payor__c =: userId AND MSD_CORE_Status__c =: isUsed AND MSD_CORE_Expired__c = false LIMIT 1];  
            if(otpcheck.size()>0){
                otpcheck[0].MSD_CORE_Status__c = 'Used';
                update otpcheck;
                returnVal = 'success';
                system.debug(emailId);
                doUpdateEligibility(userId, emailId);
            } else {
                returnVal = 'invalidOTP';
            }
        }catch(Exception e){
            system.debug('Exception is '+e);
        }
        return returnVal;
    }
    
    public static void doUpdateEligibility(string userId, string emailId){
        List<MSD_CORE_Eligibility__c> eligibility = [SELECT Id, MSD_CORE_Email__c, MSD_CORE_Payor__c 
                                                     FROM MSD_CORE_Eligibility__c WHERE  MSD_CORE_Payor__c =: userId LIMIT 1];
        if(eligibility.size() > 0){
            eligibility[0].MSD_CORE_Email__c = emailId;
            //Bypass MRK_User_Validation
            Bypass_Validation__c setting = Bypass_Validation__c.getOrgDefaults();
            setting.MRK_User_Validation__c = true;
            upsert setting;
            //Update Email on Eligibility
            update eligibility;
            
            //Update Email on Payor User
            User payorUser = new User(Id = eligibility[0].MSD_CORE_Payor__c, Email = emailId);
            update payorUser;
            
            //Reset Bypass_Validation__c.MRK_User_Validation
            setting.MRK_User_Validation__c = false;
            upsert setting;
            // doUpdateRelated(eligibility[0].Id, emailId);
        }
    }
    
    public static void doUpdateRelated(string eligibilityId, string emailId){
        List<MSD_CORE_Related_Organizations__c> updatero = new  List<MSD_CORE_Related_Organizations__c>();
        List<MSD_CORE_Related_Organizations__c> ro = [select Id, Name, MSD_CORE_Email__c, MSD_CORE_Is_Active__c, MSD_CORE_Eligibility__c from MSD_CORE_Related_Organizations__c where MSD_CORE_Eligibility__c =: eligibilityId AND MSD_CORE_Is_Active__c = true LIMIT 200];
        for(MSD_CORE_Related_Organizations__c cro : ro){
            cro.MSD_CORE_Email__c = emailId;
            updatero.add(cro);
        }
        update updatero;
    }
    
    @AuraEnabled
    public static string doExpire(String userId){
        list<MSD_CORE_OTP__c> otps = new list<MSD_CORE_OTP__c>();
        string returnVal = '';
        try{
            list<MSD_CORE_OTP__c> otpcheck = [select Id, Name, MSD_CORE_Payor__c, MSD_CORE_Token__c, MSD_CORE_Status__c, MSD_CORE_Expired__c from MSD_CORE_OTP__c WHERE MSD_CORE_Type__c ='Email Change' AND MSD_CORE_Payor__c =: userId AND MSD_CORE_Status__c = 'New' AND MSD_CORE_Expired__c = false LIMIT 1];  
            if(otpcheck.size()>0){
                for(MSD_CORE_OTP__c otpChecked : otpcheck){
                    otpChecked.MSD_CORE_Status__c = 'Used';
                    otps.add(otpChecked);}
                update otps;
            }}catch (Exception e){
                system.debug('Exception is '+e);}
        return returnVal;
    }   
}