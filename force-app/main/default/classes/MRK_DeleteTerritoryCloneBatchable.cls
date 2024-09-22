global class MRK_DeleteTerritoryCloneBatchable implements Database.Batchable<sObject>{

    /*
       KRB - 3/21/2014 - Batch Apex class to delete the entire Territory Clone Table.
    */
    
   global final String Query;

   global MRK_DeleteTerritoryCloneBatchable(String q){
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
        
     /* Get the ID of the AsyncApexJob representing this batch job
        from Database.BatchableContext.
        Query the AsyncApexJob object to retrieve the current job's information.
     */
       
     AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
     TotalJobItems, CreatedBy.Email
     FROM AsyncApexJob WHERE Id =
     :BC.getJobId()]; 
       
     System.debug('The batch Apex job, MRK_DeleteTerritoryCloneBatchable, processed ' + a.TotalJobItems +
      ' batches with '+ a.NumberOfErrors + ' failures.');  
     
   }
}