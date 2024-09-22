global class MSD_CORE_AERTBRetryScheduler implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_AERTBCaseJsonClass.scRTBAEPQCRequestInfo();
        Integer batchSize = Integer.valueof(reqInfo.Batch_Size__c);
        if(reqInfo.Run_Scheduled_Job__c)
        {
            //List<String> queryconditions = new List<String>{'NOTES&ATTACHMENTS'};
            database.executeBatch(new MSD_CORE_AERTBRetryBatchClass(),batchSize);
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
        
        MSD_CORE_AERTBRetryScheduler s = new MSD_CORE_AERTBRetryScheduler(); 
        System.schedule('MSD_CORE_AERTBRetryScheduler', nextFireTime, s);
        
    }
}