global class MSD_CORE_AERTBBatchClass implements Database.Batchable<MSD_CORE_AERequest.ServiceCloudSafetyCase>, Database.AllowsCallouts{
    public List<String> queryConditions;
    public DateTime currentJobRunDateTime;
    public static final MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_AERTBCaseJsonClass.scRTBAEPQCRequestInfo();
    
    public MSD_CORE_AERTBBatchClass(List<String> conditions)
    {
        List<CronJobDetail> cronDetail = [SELECT Id FROM CronJobDetail WHERE Name= 'MSD_CORE_AERTBRetryScheduler' LIMIT 1];
        
        if(cronDetail.size() > 0)
        {
            List<CronTrigger> cronTriggers = [SELECT Id FROM CronTrigger WHERE 
                                              CronJobDetailId = :cronDetail[0].Id];
            
            if(cronTriggers.size() > 0)
            {
                try
                {
                    //Aborts the job current setup for this scheduled class
                    System.abortJob(cronTriggers[0].Id);
                    
                }
                catch (Exception e)
                {
                    System.debug('This was the error ::: ' + e.getMessage());
                }
            }
        }
        this.queryConditions =  conditions; 
        this.currentJobRunDateTime = system.now();
    }
    global Iterable<MSD_CORE_AERequest.ServiceCloudSafetyCase> start(Database.BatchableContext bc) {
        Iterable<MSD_CORE_AERequest.ServiceCloudSafetyCase> recData = new MSD_CORE_AERTBCustomIterable(queryConditions,currentJobRunDateTime);
        return  recData; 
    }
    
    global void execute( Database.BatchableContext BC, List<object> scope ) {
        List<MSD_CORE_PIR_Request__c> aeRequests = new List<MSD_CORE_PIR_Request__c>();
        MSD_CORE_AERTBCaseJsonClass.submitAeToPv(scope, currentJobRunDateTime,reqInfo,aeRequests);
    }   
    
    global void finish( Database.BatchableContext BC ) {
            try
            {
                Integer addMin = Integer.valueOf(reqInfo.Request_Retry_Delay__c);
                Integer minute = Integer.valueOf(Datetime.now().minute()); 
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
            catch (Exception e)
            {
                System.debug('This was the error ::: ' + e.getMessage());
            }
        
        
    }
    
}