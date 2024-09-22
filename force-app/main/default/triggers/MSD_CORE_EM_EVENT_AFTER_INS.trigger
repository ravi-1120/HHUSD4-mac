trigger MSD_CORE_EM_EVENT_AFTER_INS on EM_Event_vod__c (after insert) {
    
    List<EM_Budget_vod__c> budget = new List<EM_Budget_vod__c>([SELECT Id FROM EM_Budget_vod__c WHERE Name='MMF']);
    List<EM_Event_Budget_vod__c> eventBudgetList = new List<EM_Event_Budget_vod__c>();
    if(!budget.isEmpty()){
        Map<ID, Schema.RecordTypeInfo> eventRtMap = Schema.SObjectType.EM_Event_vod__c.getRecordTypeInfosById();
        for(EM_Event_vod__c e : Trigger.New){
            String recType = eventRtMap.get(e.RecordTypeId).getDeveloperName();
            if(recType == 'MSD_CORE_Child_Home_Office_Event' || recType == 'MSD_CORE_Events_with_Speakers' || recType == 'MSD_CORE_Home_Office_Event'){
                EM_Event_Budget_vod__c eventBudget = new EM_Event_Budget_vod__c();
                eventBudget.Budget_vod__c = budget.get(0).Id;
                eventBudget.Event_vod__c = e.Id;
                eventBudgetList.add(eventBudget);
            }
        }
        
        Database.SaveResult[] srs=Database.insert(eventBudgetList, true);
        for(Database.SaveResult sr : srs){
            if(!sr.isSuccess()){
                for(Database.Error err:sr.getErrors()){
                    System.debug(err.getStatusCode() + ': ' + err.getMessage()); 
                }
            }
        }  
    }
}