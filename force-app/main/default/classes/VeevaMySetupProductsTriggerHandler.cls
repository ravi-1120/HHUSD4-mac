public without sharing class VeevaMySetupProductsTriggerHandler {

    private static final String OBJECT_NAME = 'My_Setup_Products_vod__c'; 

    public void onAfterInsert(List<My_Setup_Products_vod__c> newMySetupProducts)
    {
        VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.INSERT_EVENT_TYPE, newMySetupProducts.size());
    }

    public void onAfterUpdate(List<My_Setup_Products_vod__c> updatedMySetupProducts, Map<Id, My_Setup_Products_vod__c> oldMySetupProductMap)
    {
        if(VeevaMySetupProductsPEActions.canPublishPlatformEvent(updatedMySetupProducts, oldMySetupProductMap)) {
            VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.UPDATE_EVENT_TYPE, updatedMySetupProducts.size());
        }
    }

    public void onAfterDelete(List<My_Setup_Products_vod__c> deletedMySetupProducts)
    {
        VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.DELETE_EVENT_TYPE, deletedMySetupProducts.size());
    }
}