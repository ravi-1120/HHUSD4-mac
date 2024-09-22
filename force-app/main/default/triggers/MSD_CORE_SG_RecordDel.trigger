trigger MSD_CORE_SG_RecordDel on MSD_CORE_Strategic_Goals__c (after delete) {

MSD_CORE_RecordsOperationServices.postDeletedRecordsForTracking(Trigger.old);

}