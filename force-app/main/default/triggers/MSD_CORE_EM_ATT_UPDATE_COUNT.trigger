/*
 * Trigger: MSD_CORE_EM_ATT_UPDATE_COUNT
 * Description: Updated Attendee count on Event record when there is an insert/update/delete happens.
 * Author: Ramesh Elapakurthi
 * Change: Removed the after Udpate operation 5-20-2019
*/
trigger MSD_CORE_EM_ATT_UPDATE_COUNT on EM_Attendee_vod__c (after insert, after delete) {
    
    List<Id> eventIds = new List<Id>();
    Map<Id, Integer> eventCountMap = new Map<Id, Integer>();
    Map<Id, EM_Event_vod__c> emEvents = new Map<Id,EM_Event_vod__c>();
    
    for(EM_Attendee_vod__c att : (trigger.isDelete ? trigger.old : trigger.new)){
        if(att.Event_vod__c != null) eventIds.add(att.Event_vod__c);
    }
    
    for(AggregateResult Aggregatr : [SELECT Event_vod__c, COUNT(Id) AttendeeCount from EM_Attendee_vod__c WHERE Event_vod__c IN : eventIds GROUP BY Event_vod__c])
    {
        eventCountMap.put((Id)Aggregatr.get('Event_vod__c'),(Integer)Aggregatr.get('AttendeeCount'));
    }
    List<EM_Event_vod__c> eventsToUpd = new List<EM_Event_vod__c>();
    
    for(EM_Event_vod__c event: [SELECT Id, MSD_CORE_Attendee_Count__c FROM EM_Event_vod__c WHERE Id IN :eventIds ] ){
        
        Integer eCount = eventCountMap.get(event.Id);
        event.MSD_CORE_Attendee_Count__c = eCount;
        
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