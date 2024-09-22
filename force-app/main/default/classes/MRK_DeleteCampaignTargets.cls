global class MRK_DeleteCampaignTargets implements Database.Batchable<sObject>{

    /*
       KRB - 3/28/2013 - Batch Apex class to delete Campaign Target Records and
                         there associated Campaign records.
    */
    
   global final String Query;

   global MRK_DeleteCampaignTargets(String q){
      Query=q;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
      delete scope;
      DataBase.emptyRecycleBin(scope);
   }

   global void finish(Database.BatchableContext BC){
       
     // TODO: Delete "Deleted" flagged Campaign Records. 
       
     List<Campaign_vod__c> campaignsToDelete =  [Select Id 
                            From   Campaign_vod__c 
                            where  Delete_MRK__c = true];  
     
      delete campaignsToDelete; 
       
     /* Get the ID of the AsyncApexJob representing this batch job
        from Database.BatchableContext.
        Query the AsyncApexJob object to retrieve the current job's information.
     */
     AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
     TotalJobItems, CreatedBy.Email
     FROM AsyncApexJob WHERE Id =
     :BC.getJobId()]; 
       
     System.debug('The batch Apex job processed ' + a.TotalJobItems +
      ' batches with '+ a.NumberOfErrors + ' failures.');  
     
     /*  
     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
     String[] toAddresses = new String[] {'kevin_brace@Merck.com'};
     mail.setToAddresses(toAddresses);
     mail.setSubject('DeleteCampaignTargets - Apex Batch Job is done');
     mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +
      ' batches with '+ a.NumberOfErrors + ' failures.');
     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
     */
  }
}