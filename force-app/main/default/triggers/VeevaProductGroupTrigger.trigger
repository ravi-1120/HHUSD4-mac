trigger VeevaProductGroupTrigger on Product_Group_vod__c(before update, before delete, after insert, after update, after delete) {

    VeevaProductGroupTriggerHandler handler = new VeevaProductGroupTriggerHandler();
    if(Trigger.isInsert)
    {
        if (Trigger.isAfter)
        {
            handler.onAfterInsert(Trigger.New);
        }
    }
    else if(Trigger.isUpdate)
    {
        if (Trigger.isBefore)
        {
            handler.OnBeforeUpdate(Trigger.Old, Trigger.NewMap);
        }else {
            handler.onAfterUpdate(Trigger.New);
        }
    }
    else if(Trigger.isDelete)
    {
        if (Trigger.isBefore)
        {
            handler.OnBeforeDelete(Trigger.Old);
        }else {

            handler.onAfterDelete(Trigger.Old);
        }
    }
}