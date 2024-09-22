public without sharing class VeevaContentGroupUserTriggerHandler extends VeevaTriggerHandler {
    private static final Map<Id, Schema.RecordTypeInfo> RECORD_TYPE_ID_MAP = Schema.SObjectType.Content_Group_User_vod__c.getRecordTypeInfosById();
    private static final Map<String, Schema.RecordTypeInfo> RECORD_TYPE_NAME_MAP = Schema.SObjectType.Content_Group_User_vod__c.getRecordTypeInfosByDeveloperName();

    private List<Content_Group_User_vod__c> newContentGroupUsers = new List<Content_Group_User_vod__c>();
    private List<Content_Group_User_vod__c> oldContentGroupUsers = new List<Content_Group_User_vod__c>();
    private Map<ID, Content_Group_User_vod__c> newContentGroupUsersMap = new Map<ID, Content_Group_User_vod__c>();
    private Map<ID, Content_Group_User_vod__c> oldContentGroupUsersMap = new Map<ID, Content_Group_User_vod__c>();


    private static Map<Id, Content_Group_vod__c> associatedContentGroupsMap = new Map<Id, Content_Group_vod__c>();
    private static Map<String, GroupMember> associatedGroupMembersMap = new Map<String, GroupMember>();

    private VeevaSetupObjectHandler setupObjectHandler = new VeevaSetupObjectHandler();

    @TestVisible
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, 
                                       Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newContentGroupUsers = (List<Content_Group_User_vod__c>) triggerNew;
        this.oldContentGroupUsers = (List<Content_Group_User_vod__c>) triggerOld;
        this.newContentGroupUsersMap = (Map<ID, Content_Group_User_vod__c>) triggerNewMap;
        this.oldContentGroupUsersMap = (Map<ID, Content_Group_User_vod__c>) triggerOldMap;
    }
    
    protected override String sObjectType() {
        return 'Content_Group_User_vod__c';
    }

    protected override Boolean doRecursionCheck() {
        return true;
    }

    @TestVisible
    protected override void beforeInsert() {
        retrieveAssociatedObjects(this.newContentGroupUsers);
        handleBeforeUpsert();
    }

    @TestVisible
    protected override void beforeUpdate() {
        retrieveAssociatedObjects(this.newContentGroupUsers);
        handleBeforeUpsert();
    }

    @TestVisible
    protected override void afterInsert() {
        handleMissingGroupMembers();
    }

    @TestVisible
    protected override void afterUpdate() {
        handleMissingGroupMembers();
    }

    @TestVisible
    protected override void afterDelete() {
        retrieveAssociatedObjects(this.oldContentGroupUsers);
        List<Id> groupMemberIds = (List<Id>)mapFieldValues(associatedGroupMembersMap.values(), 'Id');
        setupObjectHandler.deleteRecords(groupMemberIds);
    }

    private void retrieveAssociatedObjects(List<Content_Group_User_vod__c> contentGroupContentUsers) {
        List<Id> contentGroupIds = (List<Id>)mapFieldValues(contentGroupContentUsers, 'Content_Group_vod__c');
        if (!contentGroupIds.isEmpty()) {
            associatedContentGroupsMap.putAll( [select Id, Group_vod__c from Content_Group_vod__c where Id in :contentGroupIds] );
        }

        List<Id> groupIds = (List<Id>)mapFieldValues(associatedContentGroupsMap.values(), 'Group_vod__c');
        List<Id> userIds = (List<Id>)mapFieldValues(contentGroupContentUsers, 'User_vod__c');
        if (!groupIds.isEmpty() && !userIds.isEmpty()) {
            for (GroupMember groupMember: [select Id, GroupId, UserOrGroupId from GroupMember where GroupId in :groupIds and UserOrGroupId in :userIds]) {
                associatedGroupMembersMap.put(constructGroupMemberKey(groupMember.GroupId, groupMember.UserOrGroupId), groupMember);
            }
        }
    }

    private void handleBeforeUpsert() {
        for (Content_Group_User_vod__c newContentGroupUser: newContentGroupUsers) {
            if (newContentGroupUser.User_vod__c == null) {
                newContentGroupUser.addError('User_vod__c',  'Field is required.');
            }

            if (isValueChanged(newContentGroupUser, 'User_vod__c')) {
                newContentGroupUser.addError('User_vod__c', 'Field cannot be changed. Please delete this Content Group User and create a new one.');
            } 

            newContentGroupUser.VExternal_Id_vod__c = constructGroupMemberKey(newContentGroupUser.Content_Group_vod__c, newContentGroupUser.User_vod__c);
        }
    }

    private Boolean isValueChanged(Content_Group_User_vod__c newContentGroupUser, String fieldName) {
        Content_Group_User_vod__c oldContentGroupUser = oldContentGroupUsersMap.get(newContentGroupUser.Id);

        Object oldValue = oldContentGroupUser == null? null: oldContentGroupUser.get(fieldName);
        Object newValue = newContentGroupUser.get(fieldName);
        return newValue != null && oldValue != null && oldValue != newValue;
    }

    private void handleMissingGroupMembers() {
        List<Content_Group_User_vod__c> contentGroupUsers = new List<Content_Group_User_vod__c>();
        for (Content_Group_User_vod__c newContentGroupUser: this.newContentGroupUsers) {
            Content_Group_vod__c contentGroup = associatedContentGroupsMap.get(newContentGroupUser.Content_Group_vod__c);
            String groupMemberKey = constructGroupMemberKey(contentGroup.Group_vod__c, newContentGroupUser.User_vod__c);
            GroupMember groupMember = associatedGroupMembersMap.get(groupMemberKey);
            if (groupMember == null) {
                contentGroupUsers.add(newContentGroupUser);
            }
        }
        
        if (!contentGroupUsers.isEmpty()) {
            createGroupMembers(contentGroupUsers);
        }
    }


    private void createGroupMembers(List<Content_Group_User_vod__c> contentGroupUsers) {
        List<GroupMember> newGroupMembers = new List<GroupMember>();
        for (Content_Group_User_vod__c contentGroupUser: contentGroupUsers) {
            Content_Group_vod__c contentGroup = associatedContentGroupsMap.get( Id.valueOf(contentGroupUser.Content_Group_vod__c) );
            if (contentGroup.Group_vod__c != null) {
                newGroupMembers.add( new GroupMember(GroupId = contentGroup.Group_vod__c, UserOrGroupId = contentGroupUser.User_vod__c) );
            }
        }

        setupObjectHandler.createRecords(newGroupMembers);
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

    private String constructGroupMemberKey(Id groupId, Id userId) {
        return groupId + '_' + userId;
    }
}