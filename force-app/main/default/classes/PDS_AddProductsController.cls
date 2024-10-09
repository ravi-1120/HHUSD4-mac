/*
* Class: PDS_AddProductsController
* Test Class: PDS_AddProductsControllerTest
* Description: Handles creation of related products and attaching them to the proposal.
* Author: Gopi Chintamaneni
* Created On: 03/14/2024
* Last Modified: 03/20/2024
* Version: Initial
*/
public with sharing class PDS_AddProductsController {
    
    @AuraEnabled(cacheable=true)
    public static List<PDS_Proposal__c> getProposal(String recId) {
        return [SELECT Id, PDS_Donation_Type__c FROM PDS_Proposal__c WHERE Id =: recId];
    }

    // Method to fetch all active products
    @AuraEnabled
    public static List<PDS_Product__c> fetchActiveProducts(Id relatedId, string donationType) {
        if(donationType == 'Excess Product Donation'){
            return [SELECT Id, PDS_Is_Active__c, Name, PDS_Description__c, PDS_Product_Number__c, PDS_Actual_Product_Cost__c, PDS_Product_Type__c, PDS_Actual_Unit_Sale_Price__c, PDS_Product_Size__c 
                    FROM PDS_Product__c WHERE PDS_Is_Active__c = true];
        }else{
            return [SELECT Id, PDS_Is_Active__c, Name, PDS_Description__c, PDS_Product_Number__c, PDS_Actual_Product_Cost__c, PDS_Product_Type__c, PDS_Actual_Unit_Sale_Price__c, PDS_Product_Size__c 
                    FROM PDS_Product__c WHERE PDS_Is_Active__c = true AND Id NOT IN (SELECT PDS_Product__c FROM PDS_Related_Product__c WHERE PDS_Proposal__c = :relatedId)];
        }
        /*List<ProductWrapper> activeProducts = new List<ProductWrapper>();
        
        try {
            // Fetch products with isActive true
            
            // Populate wrapper class with product data
            for (PDS_Product__c prod : products) {
                ProductWrapper productsList = new ProductWrapper();
                productsList.Id = prod.Id;
                productsList.name = prod.Name;
                productsList.productNumber = prod.PDS_Product_Number__c ?? '';
                productsList.description = prod.PDS_Description__c ?? '';
                productsList.productCost = prod.PDS_Actual_Product_Cost__c ?? 0;
                productsList.productType = prod.PDS_Product_Type__c ?? '';
                productsList.productSize = prod.PDS_Product_Size__c ?? '';
                productsList.unitSalePrice = prod.PDS_Actual_Unit_Sale_Price__c ?? 0;
            
                activeProducts.add(productsList);
            }
        } catch (Exception e) {
            System.debug('An error occurred while fetching products: ' + e.getMessage());
        }
        
        return activeProducts;*/
    }

    //Fetches fields schema
    @AuraEnabled(cacheable=true)
    public static List<FieldWrapper> getFields(String productField) {
        List<FieldWrapper> fieldList = new List<FieldWrapper>();
        Set<String> reqFields;
        Map<String, Schema.SObjectField> fieldMap;

        if(productField == 'Product'){
            fieldMap = Schema.SObjectType.PDS_Product__c.fields.getMap();
            reqFields = new Set<String>{'Name','PDS_Product_Size__c','PDS_Product_Type__c','PDS_Product_Number__c', 'PDS_Description__c','PDS_SAP_Code__c','PDS_NDC_Number__c','PDS_Actual_Product_Cost__c','PDS_Actual_Unit_Sale_Price__c'};
        } else if (productField == 'RelatedProduct'){
            fieldMap = Schema.SObjectType.PDS_Related_Product__c.fields.getMap();
            reqFields = new Set<String>{'PDS_Available_Quantity__c', 'PDS_Batch_Number__c', 'PDS_Expiration_Date__c'};
        }
        
        for (String fieldName : reqFields) {
            if (fieldMap.containsKey(fieldName)) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                
                // Create a wrapper class for each field and populate it with necessary information
                FieldWrapper fieldWrapper = new FieldWrapper();
                fieldWrapper.fieldName = fieldName;
                fieldWrapper.label = fieldDescribe.getLabel();
                fieldWrapper.type = String.valueOf(fieldDescribe.getType());
                
                fieldList.add(fieldWrapper);
            }
        }
        
        return fieldList;
    }

	
    //Adds related products to a proposal
    @AuraEnabled
    public static String createRelatedProducts(List<PDS_Related_Product__c> records, String recId) {
        System.debug('@@@records : '+records);
        // List<Id> insertedRecordIds = new List<Id>();
        try {
            List<PDS_Related_Product__c> existingRecords = [SELECT Id, PDS_Product__c, PDS_Batch_Number__c FROM PDS_Related_Product__c WHERE PDS_Proposal__c = :recId];
            
            Map<String, List<PDS_Related_Product__c>> existingRecordMap = new Map<String, List<PDS_Related_Product__c>>();
            for(PDS_Related_Product__c existingRecord : existingRecords) {
                List<PDS_Related_Product__c> temp = existingRecordMap.get(existingRecord.PDS_Product__c);
                if(temp == null){
                    temp = new List<PDS_Related_Product__c>();
                }
                temp.add(existingRecord);
                existingRecordMap.put(existingRecord.PDS_Product__c, temp);
            }

            Boolean hasDuplicate = false;

            for(Integer i = 0 ; i < records.size() ; i++) {
                for(Integer j = 0 ; j < records.size() ; j++) {
                    if(i != j){
                        if(records[i].PDS_Product__c == records[j].PDS_Product__c && records[i].PDS_Batch_Number__c == records[j].PDS_Batch_Number__c){
                            hasDuplicate = true;
                        }
                    }
                }
            }

            List<PDS_Related_Product__c> recordsToInsert = new List<PDS_Related_Product__c>();
            for(PDS_Related_Product__c record : records) {
                if(existingRecordMap.containsKey(record.PDS_Product__c)) {
                    for(PDS_Related_Product__c rec : existingRecordMap.get(record.PDS_Product__c)){
                        if(rec.PDS_Batch_Number__c == record.PDS_Batch_Number__c){
                            hasDuplicate = true;
                            continue;
                        }
                    }
                }
                recordsToInsert.add(record);
            }

            System.debug('#### recordsToInsert : '+recordsToInsert);
            if(!hasDuplicate && !recordsToInsert.isEmpty()) {
                insert recordsToInsert;
                return 'success';
            }else{
                return 'duplicate product';
            }
        } catch (DmlException e) {
            System.debug('DML Exception: ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            throw new AuraHandledException('Error occurred while creating records: ' + e.getMessage());
        }
    }

    /*public class ProductWrapper {
        @AuraEnabled
        public String Id { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String productNumber { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public Decimal productCost { get; set; }
        @AuraEnabled
        public String productType { get; set; }
        @AuraEnabled
        public String productSize { get; set; }
        @AuraEnabled
        public Decimal unitSalePrice { get; set; }
    }*/
    public class FieldWrapper {
        @AuraEnabled
        public String fieldName { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String type { get; set; }
    }
}