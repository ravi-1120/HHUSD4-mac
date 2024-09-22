public with sharing class VeevaLayoutService {
    @AuraEnabled
    public static Boolean isFieldOnEditLayout(String objectApiName, String fieldName, String recordTypeId) {
        if (recordTypeId != null) {
            Map<String, String> layoutResponse = getEditLayout(objectApiName, recordTypeId);
            if (layoutResponse.containsKey('data')) {
                return layoutResponse.get('data').contains(fieldName);
            }
        }
        return false;
    }
    
    public Boolean checkLayoutForField(String objectApiName, String fieldName, String recordTypeName) {
        Id recordTypeId = getIdFromRecordTypeName(objectApiName, recordTypeName);
        return isFieldOnEditLayout(objectApiName, fieldName, recordTypeId);
    }
    
    public static Id getIdFromRecordTypeName(String objectApiName, String recordTypeName) {
        Map<String, Schema.RecordTypeInfo> recordTypeInfos = Schema.describeSObjects(new List<String>{objectApiName})[0].getRecordTypeInfosByDeveloperName();
        if (recordTypeInfos != null && !recordTypeInfos.isEmpty()) {
            Schema.RecordTypeInfo recordType = recordTypeInfos.get(recordTypeName);
            if (recordType != null && recordType.isAvailable() && recordType.isActive()) {
                return recordType.getRecordTypeId();
            }
        }
        return null;
    }

    public static List<String> retrieveFieldsFromLayout(String objectApiName, String recordTypeId, String layoutType) {

        Map<String, String> layoutResponse;
        switch on (layoutType) {
            when 'View' {
                layoutResponse = getViewLayout(objectApiName, recordTypeId);
            }
            when 'Edit' {
                layoutResponse = getEditLayout(objectApiName, recordTypeId);
            }
            when else {	
                throw new AuraHandledException('Invalid layoutType passed to VeevaLayoutService::retrieveFieldsFromLayout');
            }
        }
        
        return parseFieldsFromLayout(layoutResponse);
    }

    @TestVisible
    private static List<String> parseFieldsFromLayout(Map<String, String> layoutResponse) {
        List<String> fields = new List<String>();
        String dataString = layoutResponse?.get('data');
        if (String.isBlank(dataString)) {
            return fields;
        }

        try {
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(dataString);
            List<Object> sections = (List<Object>) jsonMap.get('sections');
            for (Object section : sections) {
                List<Object> layoutRows = (List<Object>) ((Map<String, Object>) section).get('layoutRows');
                for (Object layoutRow : layoutRows) {
                    List<Object> layoutItems = (List<Object>) ((Map<String, Object>) layoutRow).get('layoutItems');
                    for (Object layoutItem : layoutItems) {
                        List<Object> layoutComponents = (List<Object>) ((Map<String, Object>) layoutItem).get('layoutComponents');
                        for (Object layoutComponent : layoutComponents) {
                            Object nullableApiName = ((Map<String, Object>) layoutComponent).get('apiName');
                            if (nullableApiName != null) {
                                fields.add((String) nullableApiName);
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to parse layout in VeevaLayoutService::retrieveFieldsFromLayout');
            return fields;
        }
    
        return fields;
    }

    public static Map<String, String> getEditLayout(String objectApiName, String recordTypeId){
        String url = '/ui-api/layout/' + objectApiName + '?mode=Edit&recordTypeId=' + recordTypeId;
        return VeevaUserInterfaceAPI.getInfo(url);
    }

    public static Map<String, String> getViewLayout(String objectApiName, String recordTypeId){
        String url = '/ui-api/layout/' + objectApiName + '?mode=View&recordTypeId=' + recordTypeId;
        return VeevaUserInterfaceAPI.getInfo(url);
    }
}