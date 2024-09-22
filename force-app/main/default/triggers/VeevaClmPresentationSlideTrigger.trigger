trigger VeevaClmPresentationSlideTrigger on Clm_Presentation_Slide_vod__c(after insert, after update, after delete) {

    VeevaClmPresentationSlideTriggerHandler handler = new VeevaClmPresentationSlideTriggerHandler();
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