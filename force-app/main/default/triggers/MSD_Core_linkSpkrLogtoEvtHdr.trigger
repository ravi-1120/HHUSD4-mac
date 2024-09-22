trigger MSD_Core_linkSpkrLogtoEvtHdr on MSD_Speaker_Publisher_Log__c (before insert) {

    Set<ID> EventId = new Set<Id>();
    List<MSD_Virtual_Event_Publisher_Log__c> vEventLogList = new List<MSD_Virtual_Event_Publisher_Log__c>();
    for(MSD_Speaker_Publisher_Log__c spkr:trigger.new){
        EventId.add(spkr.Related_Event__c);
    }
    MSD_Core_VeevaGwetIntegrationLogHelper getvEventLogDetail = new MSD_Core_VeevaGwetIntegrationLogHelper();
    vEventLogList = getvEventLogDetail.getvEventLogDetails(EventId);
    
    for(MSD_Speaker_Publisher_Log__c spkrToUpd:trigger.new){
        for(MSD_Virtual_Event_Publisher_Log__c vEventLog:vEventLogList){
            if(spkrToUpd.Related_Event__c == vEventLog.EventId__c){
                spkrToUpd.MSD_Virtual_Event_Publisher_Log__c = vEventLog.Id; 
                break;
            }
        }
    }
}