/** 
 * Batch Apex Name : MSD_CORE_Delete_Expired_Campaign_List
 * This Batch Apex Class Deletes all the Product Metrics records for the Campaign which is expired.  
 * @version        1.1
 * @author         Ankur Mehrotra 
 */

global class MSD_CORE_Delete_Expired_Campaign_List implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
       String status = 'expired';
       Set<String> CampaignName = new Set<String>();
       
        //Add Campaign Names to the set
        for(MSD_CORE_List__c Lst : [SELECT Id,Name,MSD_CORE_Name__c,MSD_CORE_Short_Name__c,MSD_CORE_Start_Date__c,MSD_CORE_End_Date__c FROM MSD_CORE_List__c Where MSD_Core_Status__c =:status]){
         if(Lst.MSD_CORE_Name__c != null) {
           CampaignName.add(Lst.MSD_CORE_Name__c);
          }
         }
         
        List<Product_vod__c> CampaignProd = [Select Id from Product_vod__c where Name in :CampaignName];

       String query = 'Select Id from Product_Metrics_vod__c where Products_vod__c in :CampaignProd';       
        return Database.getQueryLocator(query);
        
    }
   
    global void execute(Database.BatchableContext BC, List<Product_Metrics_vod__c> scope) {
             delete scope;
       }   
    
        
    global void finish(Database.BatchableContext BC) {
/*
*    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
* 
* //mail.setToAddresses(new String[] {email});
* String[] toAddresses = new String[] {'ankur.mehrotra2@merck.com'};
* mail.setToAddresses(toAddresses);
* mail.setReplyTo('ankur.mehrotra2@merck.com');
* mail.setSenderDisplayName('MRK Apex Batch Processing');
* mail.setSubject('Batch Process Completed');
* mail.setPlainTextBody('Batch Processing to Delete Product Metrics records for the expired campaign has been completed');
*  
* Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
*/
    }
}