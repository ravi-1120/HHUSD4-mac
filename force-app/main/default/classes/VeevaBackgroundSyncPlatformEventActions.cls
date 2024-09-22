public without sharing class VeevaBackgroundSyncPlatformEventActions {

    public static final String INSERT_EVENT_TYPE = 'insert';
    public static final String UPDATE_EVENT_TYPE = 'update';
    public static final String DELETE_EVENT_TYPE = 'delete';

    public static void publishPlatformEvent(String objectName, String eventType, Integer recordCount) {
        Background_Sync_Event_vod__e event = new Background_Sync_Event_vod__e();
        event.Object_Name_vod__c = objectName;
        event.Event_Type_vod__c = eventType;
        event.Record_Count_vod__c = recordCount;

        EventBus.publish(event);
    }
}