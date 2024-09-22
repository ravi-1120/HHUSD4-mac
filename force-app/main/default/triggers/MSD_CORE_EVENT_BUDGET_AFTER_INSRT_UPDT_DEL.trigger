/* 
 * Trigger: MSD_CORE_EVENT_BUDGET_AFTER_INSRT_UPDT_DEL
 * 
 * Trigger created to handle events on EM_Event_Budget_vod__c
 * 
 * Author: Kevin Brace
 * 
 * Change Log: 
 * KRB 6/13/2019 - Initial Version - added Logic to process Event Budget Counts on the Event Object. 
*/

trigger MSD_CORE_EVENT_BUDGET_AFTER_INSRT_UPDT_DEL on EM_Event_Budget_vod__c (after insert,after update,after unDelete,after delete) {
   
   //Process Event Budget Count for the Parent Event Record
   MSD_CORE_EventBudgetCountHandler evBudgetCountHandler = new MSD_CORE_EventBudgetCountHandler();
   
   if(Trigger.isInsert||Trigger.isUnDelete && Trigger.isAfter){
      evBudgetCountHandler.processEventBudgetRecordCounts(Trigger.new);     
   }
    
   if(Trigger.isDelete && Trigger.isAfter){
      evBudgetCountHandler.processEventBudgetRecordCounts(Trigger.old);     
   }
    
   if(Trigger.isUpdate && Trigger.isAfter){
      evBudgetCountHandler.processEventBudgetRecordCounts(Trigger.old, Trigger.oldMap, Trigger.new, Trigger.newMap);     
   }
    

}