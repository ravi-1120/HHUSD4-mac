public without sharing class VeevaContentGroupContentTriggerHandler extends VeevaTriggerHandler {
    private static final Map<Id, Schema.RecordTypeInfo> RECORD_TYPE_ID_MAP = Schema.SObjectType.Content_Group_Content_vod__c.getRecordTypeInfosById();
    private static final Map<String, Schema.RecordTypeInfo> RECORD_TYPE_NAME_MAP = Schema.SObjectType.Content_Group_Content_vod__c.getRecordTypeInfosByDeveloperName();
    
    private static final String ROW_CAUSE = 'Veeva_Alignment__c';
    
    private static final List<String> NO_CHANGE_FIELDS = new List<String> {'Record_Type_Name_vod__c', 'VExternal_Id_vod__c', 'RecordTypeId'};
    
    private static final Map<String, String> CONTENT_FIELD_NAME_MAP = new Map<String, String>{
        'Approved_Document_vod' => 'Approved_Document_vod__c',
        'CLM_Presentation_vod' => 'Clm_Presentation_vod__c',
        'Key_Message_vod' => 'Key_Message_vod__c'
    };

    private static final Map<String, String> SHARE_OBJECT_NAME_MAP = new Map<String, String>{
        'Approved_Document_vod' => 'Approved_Document_vod__Share',
        'CLM_Presentation_vod' => 'Clm_Presentation_vod__Share',
        'Key_Message_vod' => 'Key_Message_vod__Share'
    };

    protected List<Content_Group_Content_vod__c> newContentGroupContents = new List<Content_Group_Content_vod__c>();
    protected List<Content_Group_Content_vod__c> oldContentGroupContents = new List<Content_Group_Content_vod__c>();
    protected Map<ID, Content_Group_Content_vod__c> newContentGroupContentsMap = new Map<ID, Content_Group_Content_vod__c>();
    protected Map<ID, Content_Group_Content_vod__c> oldContentGroupContentsMap = new Map<ID, Content_Group_Content_vod__c>();

    private static Map<Id, Content_Group_vod__c> contentGroupsMap = new Map<Id, Content_Group_vod__c>();
    private static Map<String, SObject> contentSharesMap = new Map<String, SObject>();

    private VeevaSetupObjectHandler setupObjectHandler = new VeevaSetupObjectHandler();

    @TestVisible
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, 
                                       Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newContentGroupContents = (List<Content_Group_Content_vod__c>) triggerNew;
        this.oldContentGroupContents = (List<Content_Group_Content_vod__c>) triggerOld;
        this.newContentGroupContentsMap = (Map<ID, Content_Group_Content_vod__c>) triggerNewMap;
        this.oldContentGroupContentsMap = (Map<ID, Content_Group_Content_vod__c>) triggerOldMap;
    }
    
    protected override String sObjectType() {
        return 'Content_Group_Content_vod__c';
    }

    @TestVisible
    protected override void beforeInsert() {
        handleBeforeUpsert();
    }

    @TestVisible
    protected override void beforeUpdate() {
        handleBeforeUpsert();

    }

    @TestVisible
    protected override void afterInsert() {
        createMissingContentShares();
    }
	
    @TestVisible
    protected override void afterUpdate() {
        createMissingContentShares();
    }
	
    @TestVisible
    protected override void afterDelete() {
        deleteExistingContentShares();
    }

    private void handleBeforeUpsert() {
        queryContentGroups(this.newContentGroupContents);
        for (Content_Group_Content_vod__c newContentGroupContent: this.newContentGroupContents) {
            validateUpsertRecord(newContentGroupContent);
        }
    }

    private void queryContentGroups(List<Content_Group_Content_vod__c> contentGroupContents) {
        List<Id> contentGroupIds = (List<Id>)mapFieldValues(contentGroupContents, 'Content_Group_vod__c');
        if (!contentGroupIds.isEmpty()) {
            contentGroupsMap.putAll( [select Id, Group_vod__c, Status_vod__c from Content_Group_vod__c where Id in :contentGroupIds] );
        }
    }

    private void validateUpsertRecord(Content_Group_Content_vod__c contentGroupContent) {
        Schema.RecordTypeInfo recordTypeInfo = RECORD_TYPE_NAME_MAP.get(contentGroupContent.Record_Type_Name_vod__c);
        if (recordTypeInfo == null) {
            contentGroupContent.addError('Record_Type_Name_vod__c', 'Referenced to non-existing record type.');
        } else {
            String contentFieldName = getContentFieldName(contentGroupContent);
            if (contentGroupContent.get(contentFieldName) == null || isValueChanged(contentGroupContent, contentFieldName)) {
                contentGroupContent.addError(contentFieldName, 'Field is required and cannot be changed.');
            }

            Content_Group_vod__c contentGroup = contentGroupsMap.get(contentGroupContent.Content_Group_vod__c);
            if (contentGroup == null) {
                contentGroupContent.addError('Content_Group_vod__c', 'Referenced to non-existing Content_Group_vod__c record.');
            }

            checkNoChangeFields(contentGroupContent);

            contentGroupContent.VExternal_Id_vod__c = constructContentShareKey(contentGroupContent.Content_Group_vod__c, (Id)contentGroupContent.get(contentFieldName));
            contentGroupContent.RecordTypeId = recordTypeInfo.getRecordTypeId();
        }
    }

    private void checkNoChangeFields(Content_Group_Content_vod__c newContentGroupContent) {
        for (String fieldName: NO_CHANGE_FIELDS) {
            if (isValueChanged(newContentGroupContent,  fieldName)) {
                newContentGroupContent.addError(fieldName + ' cannot be changed. Please delete this Content Group Content and create a new one.');
            }
        }
    }

    private Boolean isValueChanged(Content_Group_Content_vod__c newContentGroupContent, String fieldName) {
        Content_Group_Content_vod__c oldContentGroupContent = oldContentGroupContentsMap.get(newContentGroupContent.Id);
        Object oldValue = oldContentGroupContent == null? null: oldContentGroupContent.get(fieldName);
        Object newValue = newContentGroupContent.get(fieldName);

        return newValue != null && oldValue != null && oldValue != newValue;
    }

    private void createMissingContentShares() {
        queryContentShares(this.newContentGroupContents);
        List<Content_Group_Content_vod__c> contentGroupContents = new List<Content_Group_Content_vod__c>();
        for (Content_Group_Content_vod__c newContentGroupContent: this.newContentGroupContents) {
            Content_Group_vod__c contentGroup = contentGroupsMap.get(newContentGroupContent.Content_Group_vod__c);
            if (contentGroup != null && contentGroup.Status_vod__c == 'Active_vod') {
                String contentShareKey = constructContentShareKey(newContentGroupContent);
                if (!contentSharesMap.containsKey(contentShareKey)) {
                    contentGroupContents.add(newContentGroupContent);
                }
            }
        }
        
        if (!contentGroupContents.isEmpty()) {
            createContentShares(contentGroupContents);
        }
    }

    private void queryContentShares(List<Content_Group_Content_vod__c> contentGroupContents) {
        List<Id> groupIds = (List<Id>)mapFieldValues(contentGroupsMap.values(), 'Group_vod__c');
        Map<String, List<Id>> contentIdsMap = mapContentIds(contentGroupContents);
        for (String recordTypeName: contentIdsMap.keySet()) {
            List<Id> contentIds = contentIdsMap.get(recordTypeName);
            queryContentShares(groupIds, contentIds, SHARE_OBJECT_NAME_MAP.get(recordTypeName));
        }
    }

    private Map<String, List<Id>> mapContentIds(List<Content_Group_Content_vod__c> contentGroupContents) {
        Map<String, List<Id>> contentIdsMap = new  Map<String, List<Id>>();
        for (Content_Group_Content_vod__c contentGroupContent: contentGroupContents) {
            List<Id> contentIds = contentIdsMap.get(contentGroupContent.Record_Type_Name_vod__c);
            if (contentIds == null) {
                contentIds = new List<Id>();
                contentIdsMap.put(contentGroupContent.Record_Type_Name_vod__c, contentIds);
            }
            contentIds.add(getContentId(contentGroupContent));
        }

        return contentIdsMap;
    }

    private void queryContentShares(List<Id> groupIds, List<Id> contentIds, String shareObjectName) {
        if (contentIds != null && !contentIds.isEmpty()) {
            String contentShareQuery = 'select Id, ParentId, UserOrGroupId from ' + shareObjectName + ' where RowCause = :ROW_CAUSE and ParentId in :contentIds and UserOrGroupId in :groupIds';
            for (SObject contentShare: Database.query(contentShareQuery)) {
                String contentShareKey = constructContentShareKey((Id)contentShare.get('UserOrGroupId'), (Id)contentShare.get('ParentId'));
                contentSharesMap.put(contentShareKey, contentShare);
            }
        }
    }

    private void createContentShares(List<Content_Group_Content_vod__c> contentGroupContents) {
        List<SObject> newContentShares = new List<SObject>();
        for (Content_Group_Content_vod__c contentGroupContent: contentGroupContents) {
            Schema.SObjectType contentShareType = getObjectType(contentGroupContent.Record_Type_Name_vod__c);

            if (contentShareType != null) {
                SObject contentShare = contentShareType.newSObject();
                contentShare.put('ParentID', getContentId(contentGroupContent));
                contentShare.put('UserOrGroupId', getGroupId(contentGroupContent));
                contentShare.put('AccessLevel', 'Edit');
                contentShare.put('RowCause', ROW_CAUSE);
                newContentShares.add(contentShare);
            }
        }

        setupObjectHandler.createRecords(newContentShares);
    }

    private void deleteExistingContentShares() {
        queryContentGroups(this.oldContentGroupContents);
        queryContentShares(this.oldContentGroupContents);
        List<SObject> existingContentShares = findExistingContentShares();

        setupObjectHandler.deleteRecords(existingContentShares);
    }

    private List<SObject> findExistingContentShares() {
        List<SObject> contentShares = new List<SObject>();
        for (Content_Group_Content_vod__c contentGroupContent: this.oldContentGroupContents) {
            String contentShareKey = constructContentShareKey(contentGroupContent);
            SObject contentShare = contentSharesMap.get(contentShareKey);
            if (contentShare != null) {
                contentShares.add(contentShare);
            }
        }

        return contentShares;
    }

    private List<Object> mapFieldValues(List<SObject> objects, String fieldName) {
        List<Object> fieldValues = new List<Id>();
        for (SObject anObject: objects) {
            Object fieldValue = anObject.get(fieldName);
            if (fieldValue != null) {
                fieldValues.add(fieldValue);
            }
        }

        return fieldValues;
    }

    private String constructContentShareKey(Content_Group_Content_vod__c contentGroupContent) {
        return constructContentShareKey(getGroupId(contentGroupContent), getContentId(contentGroupContent));
    }

    private String constructContentShareKey(Id groupId, Id contentId) {
        return groupId + '_' + contentId;
    }

    private String getContentFieldName(Content_Group_Content_vod__c contentGroupContent) {
        return CONTENT_FIELD_NAME_MAP.get(contentGroupContent.Record_Type_Name_vod__c);
    }

    private Id getContentId(Content_Group_Content_vod__c contentGroupContent) {
        return (Id)contentGroupContent.get(getContentFieldName(contentGroupContent));
    }

    private Id getGroupId(Content_Group_Content_vod__c contentGroupContent) {
        return contentGroupsMap.get(contentGroupContent.Content_Group_vod__c).Group_vod__c;
    }

    private Schema.SObjectType getObjectType(String recordTypeName) {
        return Schema.getGlobalDescribe().get( SHARE_OBJECT_NAME_MAP.get(recordTypeName) );
    }
}