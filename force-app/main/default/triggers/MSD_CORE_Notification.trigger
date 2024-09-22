trigger MSD_CORE_Notification on MSD_CORE_Notification__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    MSD_CORE_NotificationTriggerHandler handler = new MSD_CORE_NotificationTriggerHandler(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.isInsert,trigger.isUpdate, trigger.isDelete, trigger.isUndelete);
    if(trigger.isBefore){
        if(trigger.isInsert){
            handler.beforeInsertEvent();
        }else if(trigger.isUpdate){
            handler.beforeUpdateEvent();
        }else if(trigger.isDelete){
            handler.beforeDeleteEvent();
        }
    }else if(trigger.isAfter){
        if(trigger.isInsert){
            handler.afterInsertEvent();
        }else if(trigger.isUpdate){
            handler.afterUpdateEvent();
        }else if(trigger.isDelete){
            handler.afterDeleteEvent();
        }else if(trigger.isUndelete){
            handler.afterUndeleteEvent();
        }
    }
}