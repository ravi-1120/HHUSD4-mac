trigger VeevaClmPresentationTrigger on Clm_Presentation_vod__c(before insert, after insert, before update, after update, before delete, after delete) {

    VeevaClmPresentationTriggerHandler handler = new VeevaClmPresentationTriggerHandler();
     if(Trigger.isInsert)
     {
         if (Trigger.isAfter)
         {
             handler.onAfterInsert(Trigger.New);
         } else {
             handler.onBeforeInsert(Trigger.New);
         }
     }
     else if(Trigger.isUpdate)
     {
         if (Trigger.isAfter)
         {
             handler.onAfterUpdate(Trigger.New, Trigger.OldMap);
         } else {
             handler.onBeforeUpdate(Trigger.NewMap);
         }
     }
     else if(Trigger.isDelete)
     {
         if (Trigger.isAfter)
         {
             handler.onAfterDelete(Trigger.Old);
         } else {
             handler.onBeforeDelete(Trigger.OldMap);
         }
     }
 }