/* 
 * Class: MSD_CORE_EventBudgetCountHandler
 * 
 * Handler Class for processing logic on EM_Event_Budget_vod__c to true up Budget Counts on the EM_Event_vod Object
 * 
 * Author: Kevin Brace
 * 
 * Change Log: 
 * KRB 6/13/2019 - Initial Version - method: processEventBudgetRecordCounts 
*/

public with sharing class MSD_CORE_EventBudgetCountHandler {
    
    public void processEventBudgetRecordCounts(List<EM_Event_Budget_vod__c> eventBudgetRecordsList){
       Set<Id> eventIdsSet = new Set<Id>();
        for(EM_Event_Budget_vod__c eb : eventBudgetRecordsList){
            if(eb.Event_vod__c != null){
              eventIdsSet.add(eb.Event_vod__c);
            }
        }
        
        if(!eventIdsSet.isEmpty()){
           updateEventBudgetCount(eventIdsSet);    
        }
       
    }
    
    public void processEventBudgetRecordCounts(List<EM_Event_Budget_vod__c> oldEventBudgetRecordsList, 
                                               Map<ID, EM_Event_Budget_vod__c> oldEventBudgetRecordsMap,
                                               List<EM_Event_Budget_vod__c> newEventBudgetRecordsList, 
                                               Map<ID, EM_Event_Budget_vod__c> newEventBudgetRecordsMap
                                              ){
    
       //NOTE: On a Record Update, the Event assigned to the Budget could have changed! Following Logic Handles this. 
       Set<Id> eventIdsSet = new Set<Id>();     
          
       for(Id eventBudgetId : newEventBudgetRecordsMap.keySet() ){
          if(oldEventBudgetRecordsMap.get( eventBudgetId ).Event_vod__c != newEventBudgetRecordsMap.get( eventBudgetId ).Event_vod__c ){
             eventIdsSet.add(oldEventBudgetRecordsMap.get( eventBudgetId ).Event_vod__c);
             eventIdsSet.add(newEventBudgetRecordsMap.get( eventBudgetId ).Event_vod__c);
          }
       }                                           

        if(!eventIdsSet.isEmpty()){
           updateEventBudgetCount(eventIdsSet);    
        }
    
    }
   
    
    private void updateEventBudgetCount(Set<Id> eventIdSet) {
        
       map<id,EM_Event_vod__c> eventUpdateMap =new map<id,EM_Event_vod__c>(); 
        
       List<AggregateResult> AggregateResultList = 
            [SELECT   Event_vod__c, COUNT(id) ct 
             FROM     EM_Event_Budget_vod__c 
             WHERE    Event_vod__c in:eventIdSet 
             GROUP BY Event_vod__c]; 
    
       if(AggregateResultList != null && AggregateResultList.size() > 0){ 
          for(AggregateResult aggr:AggregateResultList){             
             EM_Event_vod__c emEvent=new EM_Event_vod__c(); 
             emEvent.Id=(id)aggr.get('Event_vod__c'); 
             emEvent.MSD_CORE_Budget_Count__c=(decimal)aggr.get('ct'); 
             eventUpdateMap.put(emEvent.Id, emEvent); 
          } 
       }else { 
          for(id idSet:eventIdSet){ 
             EM_Event_vod__c emEvent=new EM_Event_vod__c(); 
             emEvent.Id=idSet; 
             emEvent.MSD_CORE_Budget_Count__c=0; 
             eventUpdateMap.put(emEvent.Id, emEvent); 
          } 
       } 
    
        if(!eventUpdateMap.isEmpty()){
            update eventUpdateMap.values();
        }
    }
    
    
}