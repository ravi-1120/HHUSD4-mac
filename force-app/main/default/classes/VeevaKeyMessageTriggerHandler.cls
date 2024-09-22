public without sharing class VeevaKeyMessageTriggerHandler {

    private static final String OBJECT_NAME = 'Key_Message_vod__c';
     
    public void onAfterInsert(List<Key_Message_vod__c> newKeyMessages)
    {
        VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.INSERT_EVENT_TYPE, newKeyMessages.size());
    }

    public void onAfterUpdate(List<Key_Message_vod__c> updatedKeyMessages, Map<Id, Key_Message_vod__c> oldKeyMessageMap)
    {
        if(VeevaKeyMessagePlatformEventActions.canPublishPlatformEvent(updatedKeyMessages, oldKeyMessageMap)) {
             VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.UPDATE_EVENT_TYPE, updatedKeyMessages.size());
        }
    }

    public void onAfterDelete(List<Key_Message_vod__c> deletedKeyMessages)
    {
        VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.DELETE_EVENT_TYPE, deletedKeyMessages.size());
    }
}