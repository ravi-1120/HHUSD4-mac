public with sharing class VeevaMedicalIdentifierHandler {

    private static boolean showMedicalIdentifier() {
        String userType = [select User_Type_vod__c from User where id = :Userinfo.getUserId() LIMIT 1].User_Type_vod__c;
        return (userType == 'Medical_vod' && Schema.SObjectType.Account.fields.Medical_Identifier_vod__c.isAccessible());
    }

    @AuraEnabled(cacheable=true)
    public static String getIdentifierString() {
        if (showMedicalIdentifier()) {
            return 'Medical_Identifier_vod__c';
        }
        return 'Account_Identifier_vod__c';
    }
}