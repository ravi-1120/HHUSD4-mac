trigger CaseDocTrigger on Case_Document_MVN__c (after insert, before delete) {
    
    if(Trigger.isAfter && Trigger.isInsert)
    {
        //CaseDocTriggerHandler.updateAlertLegalOnCase(Trigger.New);    
        //CaseDocTriggerHandler.updateCaseCategory(Trigger.New); 
    }
    
    if(Trigger.isBefore && Trigger.isDelete){
       //CaseDocTriggerHandler.deleteCaseCategory(Trigger.Old);
    }
}