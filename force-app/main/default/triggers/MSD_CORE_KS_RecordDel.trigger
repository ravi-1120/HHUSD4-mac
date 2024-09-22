trigger MSD_CORE_KS_RecordDel on Key_Stakeholder_vod__c (after delete) {

MSD_CORE_RecordsOperationServices.postDeletedRecordsForTracking(Trigger.old);


}