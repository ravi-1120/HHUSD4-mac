global class MSD_CORE_PQCRTBRetryScheduler implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_PQCRTBCaseJsonClass.scRTBAEPQCRequestInfo();
        Integer batchSize = Integer.valueof(reqInfo.Batch_Size__c);
        if(reqInfo.Run_Scheduled_Job__c)
        {
            //List<String> queryconditions = new List<String>{'NOTES&ATTACHMENTS'};
            database.executeBatch(new MSD_CORE_PQCRTBRetryBatchClass(),batchSize);
        }
        String cronid = sc.getTriggerId();
        
        CronTrigger scheduledjob=new CronTrigger(Id=cronid);
        string value=[Select CronExpression From CronTrigger where id=:cronid limit 1].CronExpression;
        List <string> value1 =value.split(' ');
        
        system.abortJob(scheduledjob.Id); //abort scheduled job
        
        Integer addMin = Integer.valueOf(reqInfo.Request_Retry_Delay__c);
        Integer minute=integer.valueof(value1[1]);
        minute=minute+addMin;
        if(minute >= 59)
        {
            minute= minute - 59;
        }
        
        //parse to cron expression
        String nextFireTime = System.now().second() + ' ' + minute + ' ' + '0-23' + ' * * ?';
        
        MSD_CORE_PQCRTBRetryScheduler s = new MSD_CORE_PQCRTBRetryScheduler(); 
        System.schedule('MSD_CORE_PQCRTBRetryScheduler', nextFireTime, s);
        
    }
}