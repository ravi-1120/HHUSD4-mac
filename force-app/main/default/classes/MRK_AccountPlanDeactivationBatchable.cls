global class MRK_AccountPlanDeactivationBatchable implements Database.Batchable<sObject>{

    /*
       KRB - REL 5.0 4/2/2014 - Batch Apex class to delete Unapproved, greater than 90 day old,
                                Account Plans. 
    */
    
   global final String Query;

   global MRK_AccountPlanDeactivationBatchable(String q){
      System.debug('MRK_AccountPlanDeactivationBatchable:Debug: ' + q);
      Query=q;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
 
      List<Account_Plan_vod__c> accountPlansList = new List<Account_Plan_vod__c>();
       
      for (sObject sObj : scope){
         Account_Plan_vod__c acctPlan = (Account_Plan_vod__c)sObj;
         acctPlan.Active_vod__c = false;
          System.debug('Account Plan being Deactivated: ' + acctPlan.Id );
         accountPlansList.add(acctPlan);
       }

       update accountPlansList;
   } 
       

   global void finish(Database.BatchableContext BC){
   }
}