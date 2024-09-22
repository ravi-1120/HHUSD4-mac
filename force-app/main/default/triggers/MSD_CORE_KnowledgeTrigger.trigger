trigger MSD_CORE_KnowledgeTrigger on Knowledge__kav (before insert, after insert, after update, before update) {
    
    if(trigger.isbefore && trigger.isinsert)
    {
       // MSD_CORE_KnowledgeTriggerHandler.copyFromTemplate(trigger.new);
        MSD_CORE_KnowledgeTriggerHandler.updateApprovalStatus(trigger.new);
    }
    
    if(trigger.isafter && trigger.isinsert)
        MSD_CORE_KnowledgeTriggerHandler.assingOldVersionToCase(trigger.new);
    
    if(trigger.isUpdate)
    {  
        MSD_CORE_KnowledgeTriggerHandler.alertTemplateChange(trigger.new, trigger.oldmap);
        //MSD_CORE_KnowledgeTriggerHandler.assingOldVersionToCase(trigger.new, trigger.oldmap);
    }
    
    if(Trigger.isUpdate && Trigger.isBefore)
    {
        MSD_CORE_KnowledgeTriggerHandler.createComments(trigger.new);  
       
    }
    
    if(trigger.isBefore){
        MSD_CORE_KnowledgeTriggerHandler.updateAssignedTo(trigger.new, trigger.oldmap);
    
        }
}