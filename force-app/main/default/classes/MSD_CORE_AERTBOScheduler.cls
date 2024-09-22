global class MSD_CORE_AERTBOScheduler implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_AERTBCaseJsonClass.scRTBAEPQCRequestInfo();
        Integer batchSize = Integer.valueof(reqInfo.Batch_Size__c);
        system.debug('@@@@@'+reqInfo.Run_Scheduled_Job__c+'!!!!!!!!'+reqInfo.Batch_Size__c);
        if(reqInfo.Run_Scheduled_Job__c)
        {
            List<String> queryconditions = new List<String>{'OPEN'};
                database.executeBatch(new MSD_CORE_AERTBBatchClass(queryconditions),batchSize);
        }
    }
}