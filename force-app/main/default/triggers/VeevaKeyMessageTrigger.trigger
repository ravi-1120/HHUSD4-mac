trigger VeevaKeyMessageTrigger on Key_Message_vod__c(after insert, after update, after delete) {

    VeevaKeyMessageTriggerHandler handler = new VeevaKeyMessageTriggerHandler();
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
             handler.onAfterUpdate(Trigger.New, Trigger.OldMap);
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