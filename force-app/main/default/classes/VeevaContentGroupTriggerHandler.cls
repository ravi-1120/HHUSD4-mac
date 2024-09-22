public without sharing class VeevaContentGroupTriggerHandler extends VeevaTriggerHandler {
    private static final Map<Id, Schema.RecordTypeInfo> RECORD_TYPE_ID_MAP = Schema.SObjectType.Content_Group_vod__c.getRecordTypeInfosById();
    private static final Map<String, Schema.RecordTypeInfo> RECORD_TYPE_NAME_MAP = Schema.SObjectType.Content_Group_vod__c.getRecordTypeInfosByDeveloperName();

    private List<Content_Group_vod__c> newContentGroups = new List<Content_Group_vod__c>();
    private List<Content_Group_vod__c> oldContentGroups = new List<Content_Group_vod__c>();
    private Map<ID, Content_Group_vod__c> newContentGroupsMap = new Map<ID, Content_Group_vod__c>();
    private Map<ID, Content_Group_vod__c> oldContentGroupsMap = new Map<ID, Content_Group_vod__c>();

    private static final String VEEVA_CONTENT_GROUP_NAME_PREFIX = 'Veeva CG ';
    private static final String ACTIVE = 'Active_vod';
    private static final String INACTIVE = 'Inactive_vod';
    private static final String ROW_CAUSE = 'Veeva_Alignment__c';
    private static final List<String> REQUIRED_FIELDS = new List<String>{'Name', 'Status_vod__c'};

    private static final Integer GROUP_NAME_MAX_LENGTH = 40 - VEEVA_CONTENT_GROUP_NAME_PREFIX.length();

    private static Map<Id, Group> newAssociatedGroupsMap = new Map<Id, Group>();

    private static Map<Id, Content_Group_vod__c> contentGroupsNeedsReshareMap = new Map<Id, Content_Group_vod__c>();
    private static List<Content_Group_vod__c> contentGroupsWithNewName = new List<Content_Group_vod__c>();

    private VeevaSetupObjectHandler setupObjectHandler = new VeevaSetupObjectHandler();

    protected override String sObjectType() {
        return 'Content_Group_vod__c';
    }

    protected override Boolean doRecursionCheck() {
        return true;
    }

    @TestVisible
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, 
                                       Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newContentGroups = (List<Content_Group_vod__c>) triggerNew;
        this.oldContentGroups = (List<Content_Group_vod__c>) triggerOld;
        this.newContentGroupsMap = (Map<ID, Content_Group_vod__c>) triggerNewMap;
        this.oldContentGroupsMap = (Map<ID, Content_Group_vod__c>) triggerOldMap;          
    }
    
    @TestVisible
    protected override void beforeInsert() {
        retrieveNewAssociatedGroups();
        handleBeforeUpsert();
    }


    @TestVisible
    protected override void beforeUpdate() {
        retrieveNewAssociatedGroups();
        handleBeforeUpsert();
    }

    @TestVisible
    protected override void afterUpdate() {
        handleGroupNameChanges();
        reshareContents();
        handleInactivation();
    }

    @TestVisible
    protected override void afterDelete() {
        deleteGroups(this.oldContentGroups);
    }

    private void retrieveNewAssociatedGroups() {
        newAssociatedGroupsMap.putAll( retrieveAssociatedGroups(newContentGroups) );
    }

    private Map<Id, Group> retrieveAssociatedGroups(List<Content_Group_vod__c> contentGroups) {
        List<Id> groupIds = new List<Id>();
        for (Content_Group_vod__c contentGroup: contentGroups) {
            if (contentGroup.Group_vod__c != null) {
                groupIds.add( Id.valueOf(contentGroup.Group_vod__c) );
            }
        }

        return new Map<Id, Group>( [select Id, Name from Group where Id in :groupIds] );
    }

    private void handleBeforeUpsert() {
        List<Content_Group_vod__c> contentGroupsMissingGroup = new List<Content_Group_vod__c>();
        for (Content_Group_vod__c newContentGroup: newContentGroups) {
            checkRequiredFields(newContentGroup, REQUIRED_FIELDS);

            if (isGroupChangedToInvalidGroup(newContentGroup)) {
                newContentGroup.addError('Group_vod__c', 'Referenced to non-existing Group record or the Name does not match.');
            } else if (hasInvalidName(newContentGroup)) {
                newContentGroup.addError(
                    'Name',
                    VeevaMessageController.getMsgWithDefault(
                        'CONTENT_GROUP_NAME_LIMIT_ERROR_MESSAGE',
                        'Multichannel',
                        'Content Group Name should be 31 characters or fewer'
                    )
                );
            } else { 
                if (isStatusChangedToActive(newContentGroup)) {
                    contentGroupsNeedsReshareMap.put(newContentGroup.Id, newContentGroup);
                }

                if (isNameChangedAndGroupNotChanged(newContentGroup)) {
                    contentGroupsWithNewName.add(newContentGroup);
                } else if (hasInvalidGroup(newContentGroup)) {
                    contentGroupsMissingGroup.add(newContentGroup);
                }
            }
        }

        createGroups(contentGroupsMissingGroup);
    }

    private void checkRequiredFields(Content_Group_vod__c contentGroup, List<String> requiredFieldNames) {
        for (String fieldName: requiredFieldNames) {
            if (contentGroup.get(fieldName) == null) {
                contentGroup.addError(fieldName, 'Field is required.');
            }
        }
    }

    private Boolean hasInvalidName(Content_Group_vod__c contentGroup) {
        return contentGroup.Name.length() > GROUP_NAME_MAX_LENGTH;
    }

    private Boolean isGroupChangedToInvalidGroup(Content_Group_vod__c newContentGroup) {
        return isGroupChanged(newContentGroup) && hasInvalidGroup(newContentGroup);
    }

    private Boolean isStatusChangedToActive(Content_Group_vod__c newContentGroup) {
        return isValueChanged(newContentGroup, 'Status_vod__c') && newContentGroup.Status_vod__c == 'Active_vod';
    }

    private Boolean isNameChangedAndGroupNotChanged(Content_Group_vod__c newContentGroup) {
        return isNameChanged(newContentGroup) && !isGroupChanged(newContentGroup);
    }

    private void handleInactivation() {
        List<Content_Group_vod__c> inactiveContentGroups = new List<Content_Group_vod__c>();
        for (Content_Group_vod__c newContentGroup: this.newContentGroups) {
            if (INACTIVE == newContentGroup.Status_vod__c && newContentGroup.getErrors().isEmpty()) {
                inactiveContentGroups.add(newContentGroup);
            }
        }

        if (!inactiveContentGroups.isEmpty()) {
            deleteShares(inactiveContentGroups);
        }
    }

    private Boolean isNameChanged(Content_Group_vod__c newContentGroup) {
        return isValueChanged(newContentGroup, 'Name');
    }

    private Boolean isGroupChanged(Content_Group_vod__c newContentGroup) {
        return isValueChanged(newContentGroup, 'Group_vod__c');
    }

    private Boolean isValueChanged(Content_Group_vod__c newContentGroup, String fieldName) {
        Content_Group_vod__c oldContentGroup = oldContentGroupsMap.get(newContentGroup.Id);
        Object oldValue = oldContentGroup == null? null: oldContentGroup.get(fieldName);
        Object newValue = newContentGroup.get(fieldName);

        return oldValue != null && newValue != null && oldValue != newValue;
    }

    /**
     * Content_Group_vod__c.Group_vod__c is text(18) field. When the Content_Group_vod__c record is created, it createed a Group record with 
     * the Name value same as the Content_Group_vod__c record Name, with prefix 'Veeva CG', then stamp the Group record id in the Group_vod__c field.
     * If for some reason, the Group record is deleted, or the Group Name is changed, The Group_vod__c field is not valid any more.
     */
    private Boolean hasInvalidGroup(Content_Group_vod__c contentGroup) {
        if (contentGroup.Group_vod__c == null) {
            return true;
        }

        // We only need to examine the newAssociatedGroupsMap. If the Group_vod__c field is not changed, the old value is same as the new value.
        // If the Group_vod__c field is changed, we don't care about the old value any more. 
        Group associatedGroup = newAssociatedGroupsMap.get(Id.valueOf(contentGroup.Group_vod__c));
        return associatedGroup == null || constructGroupName(contentGroup) != associatedGroup.Name;
    }

    private void createGroups(List<Content_Group_vod__c> contentGroups) {
        List<Group> publicGroups = new List<Group>();
        for (Content_Group_vod__c contentGroup: contentGroups) {
            publicGroups.add( new Group(Name = constructGroupName(contentGroup)) );
        }

        if (!publicGroups.isEmpty()) {
            insert publicGroups;

            for (Integer i = 0; i < publicGroups.size(); i++) {
                Content_Group_vod__c contentGroup = contentGroups.get(i);
                Group associatedGroup = publicGroups.get(i);
                if (associatedGroup.Id != null) {
                    contentGroup.Group_vod__c = associatedGroup.Id;
                    contentGroupsNeedsReshareMap.put(contentGroup.Id, contentGroup);
                } else {
                    addErrors(contentGroup, associatedGroup.getErrors());
                } 
            }
        }
    }

    private String constructGroupName(Content_Group_vod__c contentGroup) {
        return VEEVA_CONTENT_GROUP_NAME_PREFIX + contentGroup.Name;
    }

    private List<String> constructGroupNames(List<Content_Group_vod__c> contentGroups) {
        List<String> groupNames = new List<String>();
        for (Content_Group_vod__c contentGroup: contentGroups) {
            groupNames.add(constructGroupName(contentGroup));
        }
        return groupNames;
    }

    private void addErrors(SObject obj, List<Database.Error> errors) {
        for (Database.Error err: errors) {
            String[] fields = err.getFields();
            String fieldName = fields.isEmpty()? '': fields[0];
            obj.addError(fieldName + ' ' + err.getMessage());
        }
    }

    private void handleGroupNameChanges() {
        List<Content_Group_vod__c> contentGroups = new List<Content_Group_vod__c>();
        List<Group> associatedGroups = new List<Group>();
        for (Content_Group_vod__c contentGroup: contentGroupsWithNewName) {
            Group associatedGroup = newAssociatedGroupsMap.get(Id.valueOf(contentGroup.Group_vod__c));
            if (newAssociatedGroupsMap.containsKey(contentGroup.Group_vod__c)) {
                associatedGroups.add(new Group(Id=contentGroup.Group_vod__c, Name = constructGroupName(contentGroup)));
                contentGroups.add(contentGroup);
            }
        }

        if (!associatedGroups.isEmpty()) {
            update associatedGroups;

            for (Integer i = 0; i < associatedGroups.size(); i++) {
                Group associatedGroup = associatedGroups.get(i);
                if (!associatedGroup.getErrors().isEmpty()) {
                    addErrors(contentGroups.get(i), associatedGroup.getErrors());
                }
            }
        }
    }

    private void deleteShares(List<Content_Group_vod__c> contentGroups) {
        List<Id> groupIds = new List<Id>();
        for (Content_Group_vod__c contentGroup: contentGroups) {
            Content_Group_vod__c oldContentGroup = oldContentGroupsMap.get(Id.valueOf(contentGroup.Id));
            if (oldContentGroup != null && String.isNotBlank(oldContentGroup.Group_vod__c)) {
                groupIds.add(oldContentGroup.Group_vod__c);
            }
        }

        if (!groupIds.isEmpty()) {
            List<Id> shareRecords = new List<Id>();
            shareRecords.addAll( retrieveExistingShares(groupIds, 'Approved_Document_vod__Share') );
            shareRecords.addAll( retrieveExistingShares(groupIds, 'Clm_Presentation_vod__Share') );
            shareRecords.addAll( retrieveExistingShares(groupIds, 'Key_Message_vod__Share') );

            setupObjectHandler.deleteRecords(shareRecords);
        }
    }

    private void deleteGroups(List<Content_Group_vod__c> oldContentGroups) {
        List<Id> groupIds = new List<Id>();
        for (Content_Group_vod__c oldContentGroup: oldContentGroups) {
            if (oldContentGroup.Group_vod__c != null) {
                groupIds.add(oldContentGroup.Group_vod__c);
            }
        }

        setupObjectHandler.deleteRecords(groupIds);
    }

    private void reshareContents() {
        Set<Id> contentGroupIds = contentGroupsNeedsReshareMap.keySet();
        List<Content_Group_Content_vod__c> existingContentGroupContents = [select Id from Content_Group_Content_vod__c where Content_Group_vod__c in :contentGroupIds];
        if (!existingContentGroupContents.isEmpty()) {
            update existingContentGroupContents; // Content_Group_Content_vod trigger will create missing sharing records on update. 
        }
    }

    private Set<Id> retrieveExistingShares(List<Id> groupIds, String shareObjectName) {
        List<SObject> shareRecords = new List<SObject>();
        if (Schema.getGlobalDescribe().containsKey(shareObjectName)) {
            String shareObjectQuery = 'select Id from ' + shareObjectName + ' where RowCause = :ROW_CAUSE and UserOrGroupId in :groupIds';
            shareRecords.addAll( Database.query(shareObjectQuery) );
        }

        return new Map<Id, SObject>(shareRecords).keySet();
    }
}