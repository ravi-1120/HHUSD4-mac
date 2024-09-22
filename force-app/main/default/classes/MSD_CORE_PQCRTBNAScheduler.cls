global class MSD_CORE_PQCRTBNAScheduler implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_PQCRTBCaseJsonClass.scRTBAEPQCRequestInfo();
        Integer batchSize = Integer.valueof(reqInfo.Batch_Size__c);
        System.debug('reqInfo rakesh NOTES&ATTACHMENTS : '+reqInfo);
        system.debug('@@@@@'+reqInfo.Run_Scheduled_Job__c+'!!!!!!!!'+reqInfo.Batch_Size__c);
        if(reqInfo.Run_Scheduled_Job__c)
        {
            List<String> queryconditions = new List<String>{'NOTES&ATTACHMENTS'};
                database.executeBatch(new MSD_CORE_PQCRTBBatchClass(queryconditions),batchSize);
        }
    }
}