public with sharing class HEQ_Addmore {
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPicklist(String metadataType, String recordApiName, List<String> fieldNames) {
        Map<String, String> fieldValues = new Map<String, String>();
        String query = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + metadataType + ' WHERE MasterLabel = :recordApiName';
        System.debug('Query is: ' + query);
        List<SObject> records = Database.query(query);
        if (!records.isEmpty()) {
            SObject record = records[0];
            for (String fieldName : fieldNames) {
                fieldValues.put(fieldName, (String) record.get(fieldName));
            }
        }
        return fieldValues;
    }


    @AuraEnabled(cacheable=true)
    public static Map<String, String> getIconMappings() {
        Map<String, String> iconMappings = new Map<String, String>();
        for (HEQ_Images__mdt img : [SELECT MasterLabel, HEQ_URL__c FROM HEQ_Images__mdt]) {
            iconMappings.put(img.MasterLabel, img.HEQ_URL__c);
        }
        return iconMappings;
    }

    @AuraEnabled
public static void saveUserPreferences(String userId, List<String> selectedCategories) {
    String categories = String.join(selectedCategories, ',');

    try {
        MSD_Core_UserPreference__c userPreference = [
            SELECT Id, MSD_CORE_Categories__c
            FROM MSD_Core_UserPreference__c
            WHERE MSD_CORE_Account__c = :userId
            LIMIT 1
        ];
        userPreference.MSD_CORE_Categories__c = categories;
        update userPreference;
    } catch (QueryException e) {
        MSD_Core_UserPreference__c newUserPreference = new MSD_Core_UserPreference__c(
            MSD_CORE_Account__c = userId,
            MSD_CORE_Categories__c = categories
        );
        insert newUserPreference;
    } catch (Exception e) {
        throw new AuraHandledException('Failed to save user preferences: ' + e.getMessage());
    }
}
    
    @AuraEnabled(cacheable=true)
    public static String getUserPreferences(String userId) {
       MSD_Core_UserPreference__c userPreference = [
           SELECT MSD_CORE_Categories__c
           FROM MSD_Core_UserPreference__c
           WHERE MSD_CORE_Account__c = :userId
           LIMIT 1
    ];
    return userPreference != null ? userPreference.MSD_CORE_Categories__c : null;
}

}