/*
 * Trigger: MSD_CORE_EXP_HDR_UPDATE_AMT
 * Description: Updated Expense amounts for MSD_CORE_Planned_Meal_Cost, MSD_CORE_Actual_Meal_Cost From the header rollup fields on Event record
 * when there is an insert/update/delete to the expense header. 
 * Author: Ramesh Elapakurthi
*/

trigger MSD_CORE_EXP_HDR_UPDATE_AMT on Expense_Header_vod__c (after insert, after update, after delete) {
    
    
    List<Id> eventIds = new List<Id>();
    Map<Id, Decimal> eventPlannedCostMap = new Map<Id, Decimal>();
    Map<Id, Decimal> eventActualCostMap = new Map<Id, Decimal>();
    
    Map<Id, EM_Event_vod__c> emEvents = new Map<Id,EM_Event_vod__c>();
    
    for(Expense_Header_vod__c exp : (trigger.isDelete ? trigger.old : trigger.new)){
        if(exp.Event_vod__c != null) eventIds.add(exp.Event_vod__c);
    }
    
    for(AggregateResult Aggregatr : [SELECT Event_vod__c, Sum(MSD_CORE_Planned_Meal_Cost__c) PlannedMealCost, Sum(MSD_CORE_Actual_Meal_Cost__c) ActualMealCost from Expense_Header_vod__c WHERE Event_vod__c IN : eventIds GROUP BY Event_vod__c])
    {
        eventPlannedCostMap.put((Id)Aggregatr.get('Event_vod__c'),(Decimal)Aggregatr.get('PlannedMealCost'));
        eventActualCostMap.put((Id)Aggregatr.get('Event_vod__c'),(Decimal)Aggregatr.get('ActualMealCost'));
        System.debug((Id)Aggregatr.get('Event_vod__c')+ ' Planned Cost' + (Decimal)Aggregatr.get('PlannedMealCost'));
    }
    List<EM_Event_vod__c> eventsToUpd = new List<EM_Event_vod__c>();
    
    for(EM_Event_vod__c event: [SELECT Id, MSD_CORE_Planned_Meal_Cost__c, MSD_CORE_Actual_Meal_Cost__c FROM EM_Event_vod__c WHERE Id IN :eventIds ] ){
        
        Decimal expPlannedCost = eventPlannedCostMap.get(event.Id);
        Decimal expActualCost = eventActualCostMap.get(event.Id);
        
        event.MSD_CORE_Planned_Meal_Cost__c = expPlannedCost;
        event.MSD_CORE_Actual_Meal_Cost__c = expActualCost;
        
        eventsToUpd.add(event);
        emEvents.put(event.Id,event);
    }
     
    Database.SaveResult[] srs=Database.update(eventsToUpd, true);
    for(Database.SaveResult sr : srs){
        if(!sr.isSuccess()){
            if(emEvents.containsKey(sr.getId())){
                for(Database.Error err:sr.getErrors()){
                    emEvents.get(sr.getId()).addError(err.getMessage());
                }
            }
        }
    }  
    

}