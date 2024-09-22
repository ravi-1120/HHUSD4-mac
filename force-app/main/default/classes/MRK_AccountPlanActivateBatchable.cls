global class MRK_AccountPlanActivateBatchable implements Database.Batchable<sObject>{

    /*
       KRB - REL 5.0 4/2/2014 - Batch Apex class sets Account_Plan_vod__c.Active_vod__c to 
                                true when Start_Date_MRK__c <= Today and 
                                Status__c == 'Approved' and Plan is not active. 
    */
    
   global final String Query;

   global MRK_AccountPlanActivateBatchable(String q){
      System.debug('MRK_AccountPlanActivateBatchable:Debug: ' + q);
      Query=q;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
      
      List<Account_Plan_vod__c> accountPlansUpdateList = new List<Account_Plan_vod__c>();
       
      for (sObject sObj : scope){
         Account_Plan_vod__c acctPlan = (Account_Plan_vod__c)sObj;
         acctPlan.Active_vod__c = true;
         accountPlansUpdateList.add(acctPlan);
      }
       
      update accountPlansUpdateList;
   } 
       

   global void finish(Database.BatchableContext BC){
   }
}