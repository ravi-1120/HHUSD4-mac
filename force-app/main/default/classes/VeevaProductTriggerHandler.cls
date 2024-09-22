public without sharing class VeevaProductTriggerHandler {
    
    private static final String OBJECT_NAME = 'Product_vod__c'; 

    public void onAfterInsert(List<Product_vod__c> newProducts)
    {
        VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.INSERT_EVENT_TYPE, newProducts.size());
    }

    public void onAfterUpdate(List<Product_vod__c> updatedProducts)
    {
        VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.UPDATE_EVENT_TYPE, updatedProducts.size());
    }

    public void onAfterDelete(List<Product_vod__c> deletedProducts)
    {
        VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.DELETE_EVENT_TYPE, deletedProducts.size());
    }
}