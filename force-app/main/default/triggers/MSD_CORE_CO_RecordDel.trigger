trigger MSD_CORE_CO_RecordDel on Call_Objective_vod__c (after delete) {

MSD_CORE_RecordsOperationServices.postDeletedRecordsForTracking(Trigger.old);

}