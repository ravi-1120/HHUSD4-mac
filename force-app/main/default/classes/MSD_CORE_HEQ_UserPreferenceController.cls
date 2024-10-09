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
        
        List<MSD_CORE_HEQ_UserPreference__c> userPreferenceList = [
        SELECT Id, MSD_CORE_Accepted_T_C__c, MSD_CORE_Accepted_T_C_Date__c
        FROM MSD_CORE_HEQ_UserPreference__c 
        WHERE MSD_CORE_User__c = :userId
        LIMIT 1
    ];

        MSD_CORE_HEQ_UserPreference__c userPreference;
        if (userPreferenceList.isEmpty()) {
        userPreference = new MSD_CORE_HEQ_UserPreference__c(
            MSD_CORE_User__c = userId,
            MSD_CORE_Accepted_T_C__c = acceptedTC,
            MSD_CORE_Accepted_T_C_Date__c = acceptedTC ? System.today() : null
        );
        insert userPreference;
    } else {
        userPreference = userPreferenceList[0];
        userPreference.MSD_CORE_Accepted_T_C__c = acceptedTC;
        userPreference.MSD_CORE_Accepted_T_C_Date__c = acceptedTC ? System.today() : null;
        update userPreference;
    }
    }

    @AuraEnabled
public static MSD_CORE_HEQ_Terms_and_Condition__c getTermsAndConditions() {
    return [
        SELECT MSD_CORE_Header__c, MSD_CORE_Content__c, MSD_CORE_Footer__c 
        FROM MSD_CORE_HEQ_Terms_and_Condition__c 
        LIMIT 1
    ];
}

}