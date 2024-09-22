/** 
 * Batch Apex Name : MSD_CORE_Product_Country_Code
 * This Batch Apex Class update the country code field on Detail, Detail Topic & Detail Group.
 */
 
global class MSD_CORE_Product_Country_Code implements Database.Batchable<sObject> {
global Date myDate = date.today();

    global Database.QueryLocator start(Database.BatchableContext BC) {
       String query = 'SELECT Id,MSD_CORE_Country_Code__c FROM Product_vod__c WHERE Active_MRK__c = true and MSD_CORE_Country_Code__c = null';       
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Product_vod__c> scope) {
   
     Set<Id> ProductIds = new Set<Id>();
        
          //Add Product Ids to the set
         for(PRODUCT_VOD__C Prod: Scope){
         if(Prod.MSD_CORE_Country_Code__c == null) {
            ProductIds.add(Prod.Id);
           }
         }

//List to update the Product Catalog where Country Code is null.
List <Product_vod__c> Products = new List <Product_vod__c>();
for(Product_vod__c P : [SELECT Id,MSD_CORE_Country_Code__c FROM Product_vod__c WHERE Id in :ProductIds])
{
   P.MSD_CORE_Country_Code__c = 'US';
   Products.add(P);
}
Update(Products);     
}
    
       
    global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
 
//mail.setToAddresses(new String[] {email});
String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
mail.setToAddresses(toAddresses);
mail.setReplyTo('ankur.mehrotra2@merck.com');
mail.setSenderDisplayName('Product Country Code Batch Processing');
mail.setSubject('Product Country Code Batch Process Completed');
mail.setPlainTextBody('Product Country Batch Process has been completed');
 
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}