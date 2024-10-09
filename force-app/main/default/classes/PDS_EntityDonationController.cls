/**
* @File Name : PDS_EntityDonationController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 8, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 8, 2024 |   | Initial Version
**/

public class PDS_EntityDonationController {

    @AuraEnabled(cacheable=true)
    public static List<String> getProductNames() {
        List<PDS_Product__c> products = [SELECT Id,Name FROM PDS_Product__c where PDS_Is_Active__c = true];
        List<String> productNames = new List<String>();
        
        // Extract the product names into a list
        for (PDS_Product__c product : products) {
            productNames.add(product.Name);
        }
        return productNames;
    }
}