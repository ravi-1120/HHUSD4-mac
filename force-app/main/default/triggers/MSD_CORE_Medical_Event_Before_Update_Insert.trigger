trigger MSD_CORE_Medical_Event_Before_Update_Insert on Medical_Event_vod__c (before insert, before update) {

/*
 * Change Log: 
 * KalyanV 9/20/2019 - Added code to move Location Type value from EM Events Object to Medical Events Object for FFM Events only.
*/ 
    List<Id> eventIds = new List<Id>();
    Map<Id, Medical_Event_vod__c> medEventsMap = new Map<Id,Medical_Event_vod__c>();
    List<EM_Event_vod__c> medEventUpdates = new List<EM_Event_vod__c>();
    String medEventRtDevName;
    
    for(Medical_Event_vod__c em: trigger.new){
        eventIds.add(em.EM_Event_vod__c);
    }
    if(!eventIds.isEmpty()) {
        Map<Id, EM_Event_vod__c> medicalEvents = new Map<Id,EM_Event_vod__c>([SELECT Id, RecordTypeId, Account_vod__c, Address_vod__c, PW_LOCATION_TYPE__c FROM EM_Event_vod__c WHERE Id IN: eventIds]);
        Map<ID, Schema.RecordTypeInfo> medEventRtMap = Schema.SObjectType.Medical_Event_vod__c.getRecordTypeInfosById();
        
        if(!medicalEvents.isEmpty()){
        
            for(Medical_Event_vod__c em: trigger.new){
                EM_Event_vod__c event = medicalEvents.get(em.EM_Event_vod__c);
                
                medEventRtDevName = medEventRtMap.get(em.RecordTypeId).getDeveloperName();               
               
                                 
                if(medEventRtDevName == 'MSD_CORE_Events_Without_Speakers'){
                    em.Account_vod__c = event.Account_vod__c;
                    em.Address_vod__c = event.Address_vod__c;
                    em.Location_Type_MRK__c = event.PW_LOCATION_TYPE__c;  
                     
                }
            }    
        }
        
        
    }
    
}