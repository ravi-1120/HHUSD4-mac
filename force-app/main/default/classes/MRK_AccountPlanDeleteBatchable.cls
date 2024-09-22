global class MRK_AccountPlanDeleteBatchable implements Database.Batchable<sObject>{

    /*
       KRB - REL 5.0 4/2/2014 - Batch Apex class to delete Unapproved, greater than 90 day old,
                                Account Plans. 
    */
    
   global final String Query;

   global MRK_AccountPlanDeleteBatchable(String q){
      System.debug('MRK_AccountPlanDeleteBatchable:Debug: ' + q);
      Query=q;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
 
      List<Account_Plan_vod__c> accountPlansList = new List<Account_Plan_vod__c>();
       
      for (sObject sObj : scope){
         Account_Plan_vod__c acctPlan = (Account_Plan_vod__c)sObj;
         System.debug('Account Plan being Deleted: ' + acctPlan.Id + ' ' + acctPlan.Name);
         accountPlansList.add(acctPlan);
       }

       delete accountPlansList;
   } 
       

   global void finish(Database.BatchableContext BC){
   }
}