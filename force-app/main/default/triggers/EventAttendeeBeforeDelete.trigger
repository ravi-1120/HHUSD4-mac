trigger EventAttendeeBeforeDelete on Event_Attendee_vod__c (before delete) {


    //Create a set of unique eventAttendee Ids being deleted.
    Set<Id> eventAttendeeIds = Trigger.oldMap.keySet();
    
    //Create a set of Medical Event Ids associated to the Event Attendee being deleted.
    Set<Id> medicalEventIds = new Set<Id>();
    
    for (Event_Attendee_vod__c ea : Trigger.old){
        medicalEventIds.add(ea.Medical_Event_vod__c);
    }
        
    //Create a List of associated Medical_Events that are related to the Event Expenses being deleted and have a status of submitted.
    List<Medical_Event_vod__c> submittedMedicalEvents = [select Id, Status_MRK__c 
                                                from Medical_Event_vod__c 
                                                where Id IN :medicalEventIds 
                                                and Status_MRK__c = 'Submitted' ];
    
    
    for (Event_Attendee_vod__c ea : Trigger.old){
        
       for (Medical_Event_vod__c medEvent : submittedMedicalEvents) {
         
         if (medEvent.Id == ea.Medical_Event_vod__c){
            ea.addError('Cannot delete an Attendee of a Submitted RFM.');
         }
       
       }
        
    }

}