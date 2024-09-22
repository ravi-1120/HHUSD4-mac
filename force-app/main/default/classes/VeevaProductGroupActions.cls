public without sharing class VeevaProductGroupActions {

    @testVisible static Date today = Date.today();
    private static String activeMonitoringRuleDefaultMessage = 'An active Approved Notes Monitoring Rule references this product grouping record. Please inactivate the Monitoring Rule before attempting to update or delete this relationship.';

    public static void validateValuesBeforeUpdate(List<Product_Group_vod__c> oldProductGroups, Map<ID, Product_Group_vod__c> newProductGroupMap)
    {
       Map<String, List<String>> mapOfProductDetailGroupId = getProductsOfActiveMonitoringRules();
       List<Product_Group_vod__c> productGroupsToWarn = getProductGroupsToWarn(oldProductGroups, newProductGroupMap, mapOfProductDetailGroupId);
       addErrorMessage(productGroupsToWarn);
    }
    
    public static void validateValuesBeforeDelete(List<Product_Group_vod__c> oldProductGroups)
    {
        Map<String, List<String>> mapOfProductDetailGroupId = getProductsOfActiveMonitoringRules();
        List<Product_Group_vod__c> productGroupsToWarn = getProductGroupsToWarn(oldProductGroups, null, mapOfProductDetailGroupId);
        addErrorMessage(productGroupsToWarn);
    }
    
    private static Map<String, List<String>> getProductsOfActiveMonitoringRules()
    {
        Map<String, List<String>> mapOfProductDetailGroupId = new Map<String, List<String>>();

        List<Monitoring_Rule_vod__c> mRulesWithProductAndDetailGroup = [select id,Product_vod__c,Detail_Group_vod__c from Monitoring_Rule_vod__c where Product_vod__c !=null and Detail_Group_vod__c != null and  start_date_vod__c<=today and (End_Date_vod__c = null or End_Date_vod__c >= today)];

        for (Monitoring_Rule_vod__c mRule : mRulesWithProductAndDetailGroup) {
            String productId =  mRule.Product_vod__c;
            String detailGroupId = mRule.Detail_Group_vod__c;

            List<String> detailGroups = mapOfProductDetailGroupId.get(productId);
            if (detailGroups == null) {
                detailGroups = new List<String>();
            }
            detailGroups.add(detailGroupId);
            mapOfProductDetailGroupId.put(productId,detailGroups);
        }
        return mapOfProductDetailGroupId;
    }
    
    private static List<Product_Group_vod__c> getProductGroupsToWarn(List<Product_Group_vod__c> oldProductGroups, Map<ID, Product_Group_vod__c> newProductGroupMap, Map<String, List<String>> mapOfProductDetailGroupId)
    {
         List<Product_Group_vod__c> productGroupsToWarn = new List<Product_Group_vod__c>();
                                            
            for (Product_Group_vod__c productGroup : oldProductGroups) {
                String oldProduct = productGroup.Product_vod__c;
                String oldDetailGroup = productGroup.Product_Catalog_vod__c;

                // newProductGroupMap will be not null only for update usecase, for delete usecase it will be null
                if (newProductGroupMap != null && !newProductGroupMap.isEmpty()) {
                    String newProduct = newProductGroupMap.get(productGroup.Id).Product_vod__c;
                    String newDetailGroup = newProductGroupMap.get(productGroup.Id).Product_Catalog_vod__c;
                    if (oldProduct.equals(newProduct) && oldDetailGroup.equals(newDetailGroup)) {
                        continue;
                    }
                }

                if (mapOfProductDetailGroupId.containsKey(oldProduct)) {
                    if (mapOfProductDetailGroupId.get(oldProduct).contains(oldDetailGroup)) {
                        if (newProductGroupMap == null) {
                            productGroupsToWarn.add(productGroup);
                        }else {
                            productGroupsToWarn.add(newProductGroupMap.get(productGroup.Id));
                        }
                    }
                }
            }
        return productGroupsToWarn;
   }
   
   private static void addErrorMessage(List<Product_Group_vod__c> productGroupsToWarn)
   {
        String activeMonitoringRuleMessage = VOD_VEEVA_MESSAGE.getMsgWithDefault('APPROVED_NOTES_PRODUCT_GROUP_DELETE_ERROR', 'ApprovedNotes', activeMonitoringRuleDefaultMessage);
        if (!productGroupsToWarn.isEmpty())
        {
            for (Product_Group_vod__c productGroup : productGroupsToWarn)
            {
                productGroup.addError(activeMonitoringRuleMessage);
            }
        }
   }

}