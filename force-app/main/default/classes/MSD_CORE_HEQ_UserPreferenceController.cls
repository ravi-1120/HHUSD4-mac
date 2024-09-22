public without sharing class MSD_CORE_HEQ_UserPreferenceController {

    @AuraEnabled
    public static MSD_CORE_HEQ_UserPreference__c getUserPreference() {
        Id userId = UserInfo.getUserId();

        MSD_CORE_HEQ_UserPreference__c returnuserPreference;
        
        List<MSD_CORE_HEQ_UserPreference__c> userPreferencelist = [
            SELECT Id, MSD_CORE_Accepted_T_C__c 
            FROM MSD_CORE_HEQ_UserPreference__c 
            WHERE MSD_CORE_User__c = :userId 
            LIMIT 1
        ];
        
        if (userPreferencelist.size()==0) {
            MSD_CORE_HEQ_UserPreference__c userPreference = new MSD_CORE_HEQ_UserPreference__c(
                MSD_CORE_User__c = userId
            );
            insert userPreference;
            returnuserPreference = userPreference;
        } else {
            returnuserPreference = userPreferencelist[0];
        }
        
        return returnuserPreference;
    }

    @AuraEnabled
    public static void updateUserPreference(Boolean acceptedTC) {
        Id userId = UserInfo.getUserId();
        
        MSD_CORE_HEQ_UserPreference__c userPreference = [
            SELECT Id, MSD_CORE_Accepted_T_C__c 
            FROM MSD_CORE_HEQ_UserPreference__c 
            WHERE MSD_CORE_User__c = :userId 
            LIMIT 1
        ];
        
        if (userPreference == null) {
            userPreference = new MSD_CORE_HEQ_UserPreference__c(
                MSD_CORE_User__c = userId,
                MSD_CORE_Accepted_T_C__c = acceptedTC
            );
            insert userPreference;
        } else {
            userPreference.MSD_CORE_Accepted_T_C__c = acceptedTC;
            update userPreference;
        }
    }

    @AuraEnabled(cacheable=true)
    public static MSD_CORE_HEQ_Terms_and_Condition__c getTermsAndConditions(String profileName) {
        return [
            SELECT MSD_CORE_Header__c, MSD_CORE_Content__c, MSD_CORE_Footer__c 
            FROM MSD_CORE_HEQ_Terms_and_Condition__c 
            WHERE MSD_CORE_Profile__c = :profileName 
            LIMIT 1
        ];

    }
}