trigger VeevaProductTrigger on Product_vod__c(after insert, after update, after delete) {

    VeevaProductTriggerHandler handler = new VeevaProductTriggerHandler();
    if(Trigger.isInsert) 
    {
        if (Trigger.isAfter)
        {
            handler.onAfterInsert(Trigger.New);
        }
    }
    else if(Trigger.isUpdate)
    {
        if (Trigger.isAfter)
        {
            handler.onAfterUpdate(Trigger.New);
        }
    }
    else if(Trigger.isDelete)
    {
        if (Trigger.isAfter)
        {
            handler.onAfterDelete(Trigger.Old);
        }
    } 
}