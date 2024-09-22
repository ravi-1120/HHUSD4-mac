trigger EventExpenseBeforeDelete on Event_Expense_MRK__c (before delete) {
      
    //Create a set of unique eventExpense Ids being deleted.
    Set<Id> eventExpenseIds = Trigger.oldMap.keySet();
    
    //Create a set of Medical Event Ids associated to the Event Expenses being deleted.
    Set<Id> medicalEventIds = new Set<Id>();
    
    for (Event_Expense_MRK__c  ee : Trigger.old){
        medicalEventIds.add(ee.Medical_Event_MRK__c);
    }
        
    //Create a List of associated Medical_Events that are related to the Event Expenses being deleted and have a status of submitted.
    List<Medical_Event_vod__c> submittedMedicalEvents = [select Id, Status_MRK__c 
                                                from Medical_Event_vod__c 
                                                where Id IN :medicalEventIds 
                                                and Status_MRK__c = 'Submitted' ];
    
    
    for (Event_Expense_MRK__c  ee : Trigger.old){
        
       for (Medical_Event_vod__c medEvent : submittedMedicalEvents) {
         
         if (medEvent.Id == ee.Medical_Event_MRK__c){
            ee.addError('Cannot delete an Expense of a Submitted RFM.');
         }
       
       }
        
    }

}