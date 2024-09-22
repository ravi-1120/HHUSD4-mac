public without sharing class VeevaMySetupProductsPEActions {


    public static boolean canPublishPlatformEvent(List<My_Setup_Products_vod__c> newList, Map<Id, My_Setup_Products_vod__c> oldMap) {
        for(My_Setup_Products_vod__c mySetupProduct : newList) {
            boolean hasChange = compareFields(mySetupProduct, oldMap.get(mySetupProduct.Id));

            if(hasChange) {
                return true;
            }
        }
        return false;
    }

    private static boolean compareFields(My_Setup_Products_vod__c mySetupProduct, My_Setup_Products_vod__c oldMySetupProduct) {
        if(mySetupProduct.OwnerId != oldMySetupProduct.OwnerId ||
           mySetupProduct.Product_vod__c != oldMySetupProduct.Product_vod__c ||
           mySetupProduct.Favorite_vod__c != oldMySetupProduct.Favorite_vod__c) {
                return true;
        }
        return false;
    }
}