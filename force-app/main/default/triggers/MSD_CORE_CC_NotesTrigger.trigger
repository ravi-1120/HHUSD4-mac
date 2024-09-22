trigger MSD_CORE_CC_NotesTrigger on Task (before insert, before update, before delete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert || Trigger.isUpdate){
            MSD_CORE_CC_NotesTriggerHandler.restrictInsertOnClosedCases(Trigger.New);
        }
        if(Trigger.isDelete){
            MSD_CORE_CC_NotesTriggerHandler.restrictDeleteOnClosedCases(Trigger.Old);
        }
    }
}