public with sharing class VeevaEmEventTemplateService {
    public class EventTemplateResponse {
        @AuraEnabled
        public Boolean hasAccess;
        @AuraEnabled
        public Boolean hasChildEventPermissions;
        @AuraEnabled
        public String eventRecordTypeId;
        @AuraEnabled
        public String eventRecordTypeDeveloperName;
        @AuraEnabled
        public List<String> noFLSEventFields;
        @AuraEnabled
        public List<String> noFLSRelatedFields;
        @AuraEnabled
        public List<String> noAccessRelatedObjects;
        @AuraEnabled
        public List<String> noAccessRelatedRecordTypes;
        @AuraEnabled
        public Map<String, String> defaultFieldValues;
    }

    public class MissingPermissionsException extends Exception {
    }

    @AuraEnabled
    public static EventTemplateResponse processNewChildEventRequest(String parentEventId) {
        EventTemplateResponse response = new EventTemplateResponse();
        try {
            EM_Event_vod__c parentEvent = getParentEvent(parentEventId);
            EM_Event_Rule_vod__c childEventRule = getChildEventRule(parentEvent);

            if (childEventRule == null) {
                response.hasAccess = true;
                return response;
            }

            checkChildEventRulePermissions(response);
            checkChildEventRecordType(response, childEventRule);

            List<Child_Event_Rule_Config_vod__c> childEventRuleConfigs = getChildEventRuleConfigs(childEventRule.Id);

            checkCopiedEventFieldPermissions(response, parentEvent, childEventRuleConfigs);
            checkRelatedListPermissions(response, childEventRuleConfigs, parentEvent.Id);
            response.hasAccess = true;
        } catch (MissingPermissionsException e) {
            response.hasAccess = false;
        }
        return response;
    }

    private static void checkChildEventRulePermissions(EventTemplateResponse response) {
        response.hasChildEventPermissions =
            Schema.sObjectType.EM_Event_Rule_vod__c.fields.Child_Event_Record_Type_vod__c.isAccessible() &&
            Schema.sObjectType.Child_Event_Rule_Config_vod__c.isAccessible() &&
            Schema.sObjectType.Child_Event_Rule_Config_vod__c.fields.Parent_Event_Field_vod__c.isAccessible() &&
            Schema.sObjectType.Child_Event_Rule_Config_vod__c.fields.Parent_Event_Related_List_vod__c.isAccessible();

        if (!response.hasChildEventPermissions) {
            throw new MissingPermissionsException();
        }
    }

    private static void checkChildEventRecordType(EventTemplateResponse response, EM_Event_Rule_vod__c childEventRule) {
        if (String.isNotEmpty(childEventRule.Child_Event_Record_Type_vod__c)) {
            Schema.RecordTypeInfo recordTypeInfo = Schema.sObjectType.EM_Event_vod__c.getRecordTypeInfosByDeveloperName()
                .get(childEventRule.Child_Event_Record_Type_vod__c);
            if (recordTypeInfo == null || !recordTypeInfo.isActive() || !recordTypeInfo.isAvailable()) {
                response.hasChildEventPermissions = false;
                throw new MissingPermissionsException();
            }
            response.eventRecordTypeId = recordTypeInfo.getRecordTypeId();
            response.eventRecordTypeDeveloperName = recordTypeInfo.getDeveloperName();
        }
    }

    private static void checkCopiedEventFieldPermissions(
        EventTemplateResponse response,
        EM_Event_vod__c parentEvent,
        List<Child_Event_Rule_Config_vod__c> childEventRuleConfigs
    ) {
        Map<String, String> defaultFieldValues = new Map<String, String>();
        List<String> noFLSEventFields = new List<String>();
        Map<String, Schema.SObjectField> eventFieldMap = Schema.SObjectType.EM_Event_vod__c.fields.getMap();
        for (Child_Event_Rule_Config_vod__c childEventRuleConfig : childEventRuleConfigs) {
            if (childEventRuleConfig.RecordType.DeveloperName == 'Child_Event_Rule_Field_vod') {
                String parentEventField = childEventRuleConfig.Parent_Event_Field_vod__c;
                if (
                    !eventFieldMap.containsKey(parentEventField) ||
                    !eventFieldMap.get(parentEventField).getDescribe().isAccessible() ||
                    !eventFieldMap.get(parentEventField).getDescribe().isCreateable()
                ) {
                    noFLSEventFields.add(parentEventField);
                } else if (parentEvent.get(parentEventField) != null) {
                    String value;
                    if (parentEvent.get(parentEventField) instanceof Datetime) {
                        value = ((Datetime) parentEvent.get(parentEventField)).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                    } else {
                        value = String.valueOf(parentEvent.get(parentEventField));
                    }
                    defaultFieldValues.put(parentEventField, value);
                }
            }
        }
        if (!noFLSEventFields.isEmpty()) {
            response.noFLSEventFields = noFLSEventFields;
            throw new MissingPermissionsException();
        }
        response.defaultFieldValues = defaultFieldValues;
    }

    private static void checkRelatedListPermissions(
        EventTemplateResponse response,
        List<Child_Event_Rule_Config_vod__c> childEventRuleConfigs,
        String parentEventId
    ) {
        Map<String, List<String>> objectToFieldsMap = new Map<String, List<String>>();
        for (Child_Event_Rule_Config_vod__c childEventRuleConfig : childEventRuleConfigs) {
            if (childEventRuleConfig.RecordType.DeveloperName == 'Child_Event_Rule_Related_List_vod') {
                String parentEventRelatedList = childEventRuleConfig.Parent_Event_Related_List_vod__c;
                if (!objectToFieldsMap.containsKey(parentEventRelatedList)) {
                    objectToFieldsMap.put(parentEventRelatedList, new List<String>());
                }
                objectToFieldsMap.get(parentEventRelatedList).add(childEventRuleConfig.Parent_Event_Field_vod__c);
            }
        }

        List<String> noAccessRelatedObjects = new List<String>();
        List<String> noFLSRelatedFields = new List<String>();
        for (String objectName : objectToFieldsMap.keySet()) {
            SObjectType sObjectType = ((SObject) Type.forName('Schema', objectName).newInstance()).getSObjectType();
            DescribeSObjectResult describeSObjectResult = sObjectType.getDescribe();
            if (!describeSObjectResult.isAccessible() || !describeSObjectResult.isCreateable()) {
                noAccessRelatedObjects.add(objectName);
            }
            for (String objectField : objectToFieldsMap.get(objectName)) {
                if (
                    !describeSObjectResult.fields.getMap().containsKey(objectField) ||
                    !describeSObjectResult.fields.getMap().get(objectField).getDescribe().isAccessible() ||
                    !describeSObjectResult.fields.getMap().get(objectField).getDescribe().isCreateable()
                ) {
                    noFLSRelatedFields.add(objectName + '.' + objectField);
                }
            }
        }

        List<String> noAccessRelatedRecordTypes = checkRelatedRecordTypeAccess(objectToFieldsMap.keySet(), parentEventId);

        if (!noAccessRelatedObjects.isEmpty() || !noFLSRelatedFields.isEmpty() || !noAccessRelatedRecordTypes.isEmpty()) {
            response.noAccessRelatedObjects = noAccessRelatedObjects;
            response.noFLSRelatedFields = noFLSRelatedFields;
            response.noAccessRelatedRecordTypes = noAccessRelatedRecordTypes;
            throw new MissingPermissionsException();
        }
    }

    private static List<String> checkRelatedRecordTypeAccess(Set<String> relatedObjectsToCopy, String parentEventId) {
        List<String> noAccessRelatedRecordTypes = new List<String>();

        if (relatedObjectsToCopy.isEmpty()) {
            return noAccessRelatedRecordTypes;
        }

        Map<String, String> objectNameToRelationshipMap = new Map<String, String>();
        for (Schema.ChildRelationship childRelationship : Schema.sObjectType.EM_Event_vod__c.getChildRelationships()) {
            objectNameToRelationshipMap.put(String.valueOf(childRelationship.getChildSObject()), childRelationship.getRelationshipName());
        }

        List<String> subQueries = new List<String>();
        for (String relatedObject : new List<String>(relatedObjectsToCopy)) {
            subQueries.add('(SELECT RecordTypeId, RecordType.DeveloperName FROM ' + objectNameToRelationshipMap.get(relatedObject) + ')');
        }
        String query = 'SELECT ' + String.join(subQueries, ',') + ' FROM EM_Event_vod__c WHERE Id = \'' + parentEventId + '\'';
        EM_Event_vod__c parentEvent = Database.query(query);

        Set<String> checkedRecordTypeIds = new Set<String>();
        for (String relatedObject : relatedObjectsToCopy) {
            SObjectType sObjectType = ((SObject) Type.forName('Schema', relatedObject).newInstance()).getSObjectType();
            DescribeSObjectResult describeSObjectResult = sObjectType.getDescribe();
            SObject[] relatedRecords = parentEvent.getSObjects(objectNameToRelationshipMap.get(relatedObject));
            if (relatedRecords != null) {
                for (SObject relatedRecord : relatedRecords) {
                    if (
                        relatedRecord.get('RecordTypeId') != null &&
                        relatedRecord.getSObject('RecordType') != null &&
                        relatedRecord.getSObject('RecordType').get('DeveloperName') != null &&
                        !checkedRecordTypeIds.contains((String) relatedRecord.get('RecordTypeId'))
                    ) {
                        String recordTypeDeveloperName = (String) relatedRecord.getSObject('RecordType').get('DeveloperName');
                        Schema.RecordTypeInfo recordTypeInfo = describeSObjectResult.getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName);
                        if (recordTypeInfo == null || !recordTypeInfo.isAvailable()) {
                            noAccessRelatedRecordTypes.add(relatedObject + '-' + recordTypeDeveloperName);
                        }
                        checkedRecordTypeIds.add((String) relatedRecord.get('RecordTypeId'));
                    }
                }
            }
        }

        return noAccessRelatedRecordTypes;
    }

    private static List<Child_Event_Rule_Config_vod__c> getChildEventRuleConfigs(String childEventRuleId) {
        List<Child_Event_Rule_Config_vod__c> childEventRuleConfigs = [
            SELECT Id, Parent_Event_Field_vod__c, Parent_Event_Related_List_vod__c, RecordType.DeveloperName
            FROM Child_Event_Rule_Config_vod__c
            WHERE
                EM_Event_Rule_vod__c = :childEventRuleId
                AND (RecordType.DeveloperName = 'Child_Event_Rule_Related_List_vod'
                OR RecordType.DeveloperName = 'Child_Event_Rule_Field_vod')
        ];
        return childEventRuleConfigs;
    }

    private static EM_Event_vod__c getParentEvent(String parentEventId) {
        Map<String, Schema.sObjectField> eventFieldMap = Schema.sObjectType.EM_Event_vod__c.fields.getMap();
        return Database.query(
            'SELECT ' +
            String.join(new List<String>(eventFieldMap.keySet()), ',') +
            ' FROM EM_Event_vod__c WHERE Id = :parentEventId'
        );
    }

    private static EM_Event_Rule_vod__c getChildEventRule(EM_Event_vod__c parentEvent) {
        EM_Event_Rule_vod__c childEventRule = null;
        if (parentEvent != null) {
            List<EM_Event_Rule_vod__c> eventRules = [
                SELECT Id, Name, Child_Event_Record_Type_vod__c, Country_Override_vod__c
                FROM EM_Event_Rule_vod__c
                WHERE
                    RecordType.DeveloperName = 'Child_Event_Settings_vod'
                    AND Event_Configuration_vod__c = :parentEvent.Event_Configuration_vod__c
                    AND (Country_Override_vod__c = null
                    OR Country_Override_vod__r.Country_vod__c = :parentEvent.Country_vod__c)
            ];

            for (EM_Event_Rule_vod__c eventRule : eventRules) {
                if (childEventRule == null || eventRule.Country_Override_vod__c != null) {
                    childEventRule = eventRule;
                }
            }
        }
        return childEventRule;
    }
}