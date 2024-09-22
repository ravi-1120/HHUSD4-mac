trigger MSD_CORE_AT_RecordDel on Account_Tactic_vod__c (after delete) {

MSD_CORE_RecordsOperationServices.postDeletedRecordsForTracking(Trigger.old);

}