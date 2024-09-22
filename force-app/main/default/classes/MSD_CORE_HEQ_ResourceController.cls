public with sharing class MSD_CORE_HEQ_ResourceController {
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
   public static List<Map<String, Object>> FileDetails(String recordId) {
        try {
            // String profilename = [SELECT Profile.Name FROM User WHERE Id =: Userinfo.getUserId()].Profile.Name;

            // String whereClause = 'WHERE msd_core_profile__c = \'' + profilename + '\' AND msd_core_isactive__c = true ORDER BY msd_core_order__c ASC';
            // List<Map<String, Object>> metadata = MSD_CORE_HEQ_Utility.getAllFieldValues('MSD_CORE_HEQ_Resource_Configs__mdt', whereClause);
            // System.debug('metadata>>'+metadata);
            // List<String> fieldAPINames = new List<String>();
            // Map<String, String> fieldLabelMap = new Map<String, String>();
            
            // for (Map<String, Object> fieldMetadata : metadata) {
            //     String apiName = (String) fieldMetadata.get('msd_core_field_apiname__c');
            //     String fieldLabel = (String) fieldMetadata.get('label');
            //     if (!fieldAPINames.contains(apiName)) {
            //         fieldAPINames.add(apiName);
            //     }
            //     fieldLabelMap.put(apiName, fieldLabel);
            // }

            // String soqlQuery = 'SELECT ' + String.join(fieldAPINames, ', ') + ' FROM ContentVersion  WHERE Id =: recordId';

            // List<ContentVersion> contentVersionRecords = Database.query(soqlQuery);
            // System.debug('contentVersionRecords::>>'+contentVersionRecords);
            
            // List<Map<String, Object>> resultList = new List<Map<String, Object>>();

            // for (ContentVersion content : contentVersionRecords) {
            //     Map<String, Object> recordMap = new Map<String, Object>();

            //     for (String fieldName : fieldAPINames) {
            //         Object fieldValue = content.get(fieldName);
            //         // recordMap.put(fieldLabelMap.get(fieldName), content.get(fieldName));
            //         recordMap.put(fieldLabelMap.get(fieldName), fieldValue != null ? fieldValue : 'N/A');
            //     }
            //     resultList.add(recordMap);
            // }
            // return resultList;


            String profilename = [SELECT Profile.Name FROM User WHERE Id =: Userinfo.getUserId()].Profile.Name;

            String whereClause = 'WHERE msd_core_profile__c = \'' + profilename + '\' AND msd_core_isactive__c = true ORDER BY msd_core_order__c ASC';
            List<Map<String, Object>> metadata = MSD_CORE_HEQ_Utility.getAllFieldValues('MSD_CORE_HEQ_Resource_Configs__mdt', whereClause);
            System.debug('metadata>>' + metadata);

            // Using a list to store unique API Names and an ordered map to manage label-API name relationships
            List<String> fieldAPINames = new List<String>();
            List<Map<String, String>> apiNameLabelMappings = new List<Map<String, String>>();

            for (Map<String, Object> fieldMetadata : metadata) {
                String apiName = (String) fieldMetadata.get('msd_core_field_apiname__c');
                String fieldLabel = (String) fieldMetadata.get('label');
                
                // Add unique API Name to the query list
                if (!fieldAPINames.contains(apiName)) {
                    fieldAPINames.add(apiName);
                }

                // Store the mapping for both duplicate field API names and different labels
                Map<String, String> apiLabelMap = new Map<String, String>();
                apiLabelMap.put('apiName', apiName);
                apiLabelMap.put('label', fieldLabel);
                apiNameLabelMappings.add(apiLabelMap);
            }

            // Construct SOQL query with unique field API Names
            String soqlQuery = 'SELECT ' + String.join(fieldAPINames, ', ') + ' FROM ContentVersion WHERE Id =: recordId';
            List<ContentVersion> contentVersionRecords = Database.query(soqlQuery);
            System.debug('contentVersionRecords::>>' + contentVersionRecords);

            List<Map<String, Object>> resultList = new List<Map<String, Object>>();

            // Iterate through the contentVersionRecords and populate the resultList with field values and associated labels
            for (ContentVersion content : contentVersionRecords) {
                Map<String, Object> recordMap = new Map<String, Object>();

                for (Map<String, String> apiLabelMapping : apiNameLabelMappings) {
                    String apiName = apiLabelMapping.get('apiName');
                    String label = apiLabelMapping.get('label');

                    Object fieldValue = content.get(apiName);
                    recordMap.put(label, fieldValue != null ? fieldValue : 'N/A');
                }
                
                resultList.add(recordMap);
            }

            return resultList;

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