trigger MSD_Core_linkAttendLogtoEvtHdr on MSD_Attendee_Publisher_Log__c (before insert) {

    Set<ID> EventId = new Set<Id>();
    List<MSD_Virtual_Event_Publisher_Log__c> vEventLogList = new List<MSD_Virtual_Event_Publisher_Log__c>();
    for(MSD_Attendee_Publisher_Log__c atten:trigger.new){
        EventId.add(atten.Event__c);
    }
    MSD_Core_VeevaGwetIntegrationLogHelper getvEventLogDetail = new MSD_Core_VeevaGwetIntegrationLogHelper();
    vEventLogList = getvEventLogDetail.getvEventLogDetails(EventId);
    
    for(MSD_Attendee_Publisher_Log__c attdToUpd:trigger.new){
        for(MSD_Virtual_Event_Publisher_Log__c vEventLog:vEventLogList){
            if(attdToUpd.Event__c == vEventLog.EventId__c){
                attdToUpd.MSD_Virtual_Event_Publisher_Log__c = vEventLog.Id; 
                break;
            }
        }
    }
}