public with sharing class MSD_CORE_ResourceController {
    // @AuraEnabled(cacheable=true)
    // public static List<String> getVisibleFields(String profileName) {
    //     List<MSD_CORE_Resource_Configs__mdt> configs = [
    //         SELECT MSD_CORE_Resource_Fields__c
    //         FROM MSD_CORE_Resource_Configs__mdt
    //         WHERE MSD_CORE_Profile__c = :profileName
    //     ];

    //     List<String> fieldNames = new List<String>();

    //     if (!configs.isEmpty()) {
    //         // Split the comma-separated field names
    //         fieldNames = configs[0].MSD_CORE_Resource_Fields__c.split(',\\s*');
    //     }

    //     return fieldNames;
    // }
    // 
    @AuraEnabled(cacheable=true)
   public static List<ContentVersion> FileDetails(String recordId) {
        try {
            String profilename = [SELECT Profile.Name FROM User WHERE Id =: Userinfo.getUserId()].Profile.Name;

            String whereClause = 'WHERE MSD_CORE_Profile__c = \'' + profilename + '\'';
            List<Map<String, Object>> metadata = HEQ_Utility.getAllFieldValues('MSD_CORE_Resource_Configs__mdt', whereClause);
            String resourcefields = '';

            for (Map<String, Object> record : metadata) {
                if (record.containsKey('msd_core_resource_fields__c')) {
                    Object fieldValue = record.get('msd_core_resource_fields__c');
                    if (fieldValue != null) {
                        resourcefields += fieldValue.toString() + ', ';
                    }
                }
            }

            if (resourcefields.endsWith(', ')) {
                resourcefields = resourcefields.substring(0, resourcefields.length() - 2);
            }

            String query = 'SELECT Id, ' + resourcefields;
            query += ' FROM ContentVersion WHERE Id =: recordId';
            List<ContentVersion> contentVersions = Database.query(query);
            return contentVersions;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching topic details: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getResourceDetails(String metadataType, String recordApiName, List<String> fieldNames) {
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
}