public without sharing class VeevaProductGroupTriggerHandler {
    public VeevaProductGroupTriggerHandler() { }

    private static final String OBJECT_NAME = 'Product_Group_vod__c';

    public void onAfterInsert(List<Product_Group_vod__c> newProductGroups)
    {
        VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.INSERT_EVENT_TYPE, newProductGroups.size());
    }

    public void OnBeforeUpdate(List<Product_Group_vod__c> oldProductGroups, Map<ID, Product_Group_vod__c> newProductGroupMap)
    {
       VeevaProductGroupActions.validateValuesBeforeUpdate(oldProductGroups, newProductGroupMap);
    }

    public void onAfterUpdate(List<Product_Group_vod__c> updatedProductGroups)
    {
        VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.UPDATE_EVENT_TYPE, updatedProductGroups.size());
    }

    public void OnBeforeDelete(List<Product_Group_vod__c> oldProductGroups)
    {
        VeevaProductGroupActions.validateValuesBeforeDelete(oldProductGroups);
    }

    public void onAfterDelete(List<Product_Group_vod__c> deletedProductGroups)
    {
        VeevaBackgroundSyncPlatformEventActions.publishPlatformEvent(OBJECT_NAME, VeevaBackgroundSyncPlatformEventActions.DELETE_EVENT_TYPE, deletedProductGroups.size());
    }
}