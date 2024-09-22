/**
 * Component Name:      MSD_CORE_HEQ_Utility
 * Created By:          Ravi Modi (Focal CXM)
 * Created Date:        12th July 2024
 * @description:        Utility class for HEQ portal
 * Test Class:          
 */

public with sharing class MSD_CORE_HEQ_Utility {
    
    /**
     * Retrieves all field values of custom metadata records for the given custom metadata type,
     * optionally filtered by a WHERE clause.
     * @param customMetadataTypeName The API name of the custom metadata type.
     * @param whereclause The WHERE clause to filter records.
     * @return A list of maps, where each map contains field API names as keys and field values as values.
     */
    @AuraEnabled
    public static List<Map<String, Object>> getAllFieldValues(String customMetadataTypeName, String whereclause) {
        
        List<Map<String, Object>> recordsWithValues = new List<Map<String, Object>>();
        
        try {
            // Describe the custom metadata type
            Schema.SObjectType customMetadataType = Schema.getGlobalDescribe().get(customMetadataTypeName);
            if (customMetadataType == null) {
                throw new IllegalArgumentException('Custom metadata type not found: ' + customMetadataTypeName);
            }

            // Describe fields of the custom metadata type
            Map<String, Schema.SObjectField> fieldMap = customMetadataType.getDescribe().fields.getMap();

            // Construct the SOQL query
            String query = 'SELECT ';
            List<String> fieldNames = new List<String>(fieldMap.keySet());
            query += String.join(fieldNames, ',');
            query += ' FROM ' + customMetadataTypeName;
            if (whereclause != null) {
                query += ' ' + whereclause;
            }

            List<SObject> customMetadataRecords = Database.query(query);

            // Process each custom metadata record
            for (SObject record : customMetadataRecords) {
                Map<String, Object> fieldValues = new Map<String, Object>();
                for (String fieldName : fieldNames) {
                    fieldValues.put(fieldName, record.get(fieldName));
                }
                recordsWithValues.add(fieldValues);
            }

            return recordsWithValues;
        } catch (Exception e) {
            System.debug('Error>>'+e.getMessage() +'---' +e.getLineNumber( ) );
            return recordsWithValues;
        }

    }

    @AuraEnabled
    public static List<SObject> runQuery(String soqlQuery) {
        try {
            return Database.query(soqlQuery);
        } catch (Exception e) {
            throw new AuraHandledException('Error running query: ' + e.getMessage());
        }
    }
    
}