public without sharing class VeevaEmIntegrationAdminService {
    @AuraEnabled
    public static List<Connection_vod__c> getConnection(String type) {
        try {
            return [
                SELECT Id, Connection_URL_vod__c, toLabel(Last_Sync_Status_vod__c), Last_Sync_Date_vod__c, Type_vod__c, Sync_Settings_vod__c
                FROM Connection_vod__c
                WHERE Type_vod__c = :type
                WITH SECURITY_ENFORCED
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void createSystemMappings(String connection) {
        try {
            List<Connection_Field_Mapping_Default_vod__mdt> fieldMappingMdts = [
                SELECT
                    Id,
                    CRM_Object_vod__r.DeveloperName,
                    Connection_Field_vod__c,
                    CRM_Field_vod__r.DeveloperName,
                    External_ID_vod__c,
                    (SELECT CRM_Value_vod__c, Connection_Value_vod__c FROM Connection_Value_Mappings__r)
                FROM Connection_Field_Mapping_Default_vod__mdt
            ];

            List<Connection_Field_Mapping_vod__c> fieldMappingList = new List<Connection_Field_Mapping_vod__c>();
            List<Connection_Value_Mapping_vod__c> valueMappingList = new List<Connection_Value_Mapping_vod__c>();
            for (Connection_Field_Mapping_Default_vod__mdt fieldMappingMdt : fieldMappingMdts) {
                Connection_Field_Mapping_vod__c fieldMappingReference = new Connection_Field_Mapping_vod__c(
                    External_ID_vod__c = fieldMappingMdt.External_ID_vod__c + '_' + connection
                );
                Connection_Field_Mapping_vod__c fieldMapping = new Connection_Field_Mapping_vod__c(
                    External_ID_vod__c = fieldMappingMdt.External_ID_vod__c + '_' + connection,
                    Connection_vod__c = connection,
                    CRM_Object_vod__c = fieldMappingMdt.CRM_Object_vod__r.DeveloperName,
                    CRM_Field_vod__c = 'RecordType' == fieldMappingMdt.CRM_Field_vod__r.DeveloperName
                        ? fieldMappingMdt.CRM_Field_vod__r.DeveloperName
                        : fieldMappingMdt.CRM_Field_vod__r.DeveloperName + '__c',
                    Connection_Field_vod__c = fieldMappingMdt.Connection_Field_vod__c,
                    System_Mapping_vod__c = true,
                    RecordTypeId = getRecordTypeId('Connection_Field_Mapping_vod__c', 'Field_Mapping_vod'),
                    Status_vod__c = 'Active_vod '
                );
                fieldMappingList.add(fieldMapping);
                for (Connection_Value_Mapping_Default_vod__mdt valueMappingMdt : fieldMappingMdt.Connection_Value_Mappings__r) {
                    Connection_Value_Mapping_vod__c valueMapping = new Connection_Value_Mapping_vod__c(
                        CRM_Value_vod__c = valueMappingMdt.CRM_Value_vod__c,
                        Connection_Value_vod__c = valueMappingMdt.Connection_Value_vod__c,
                        RecordTypeId = getRecordTypeId('Connection_Value_Mapping_vod__c', 'Value_Mapping_vod')
                    );
                    valueMapping.Connection_Field_Mapping_vod__r = fieldMappingReference;
                    valueMappingList.add(valueMapping);
                }
            }
            SObject[] sobjList = new List<SObject>();
            sobjList.addAll(fieldMappingList);
            sobjList.addAll(valueMappingList);
            Database.SaveResult[] results = Database.insert(sobjList, true);
            List<String> saveErrors = new List<String>();
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        saveErrors.add(err.getMessage());
                    }
                }
            }
            if(!saveErrors.isEmpty()) {
                throw new AuraHandledException('fail to create system mappings: ' + String.join(saveErrors, ','));
            }
        } catch (Exception e) {
            throw new AuraHandledException('fail to create system mappings: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Connection_Field_Mapping_vod__c> getConnectionFieldMapping(String connection) {
        try {
            return [ SELECT Id, Connection_Field_vod__c, CRM_Field_vod__c, Status_vod__c, System_Mapping_vod__c, Connection_vod__c FROM Connection_Field_Mapping_vod__c WHERE Connection_vod__c = :connection WITH SECURITY_ENFORCED ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Connection_Value_Mapping_vod__c> getConnectionValueMapping(String fieldMapping) {
        try {
            return [ SELECT Id, Connection_Field_Mapping_vod__c, CRM_Value_vod__c, Connection_Value_vod__c  FROM Connection_Value_Mapping_vod__c WHERE Connection_Field_Mapping_vod__c = :fieldMapping WITH SECURITY_ENFORCED ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String getRecordTypeId(String objectName, String recordTypeName) {
        RecordTypeInfo info = ((SObject)Type.forName('Schema', objectName).newInstance())
        .getSObjectType()
        .getDescribe()
        .getRecordTypeInfosByDeveloperName()
        .get(recordTypeName);
        if (info != null && info.isAvailable()) {
			return info.getRecordTypeId();
		}
		return null;
    }
}