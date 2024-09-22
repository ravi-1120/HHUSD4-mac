global class MSD_CORE_PQCRTBBatchClass implements Database.Batchable<MSD_CORE_PQCRequest.ServiceCloudSafetyCase>, Database.AllowsCallouts{
    public List<String> queryConditions;
    public DateTime currentJobRunDateTime;
    public static final MSD_CORE_SC_RTB_Request_Info__mdt  reqInfo = MSD_CORE_PQCRTBCaseJsonClass.scRTBAEPQCRequestInfo();
    
    public MSD_CORE_PQCRTBBatchClass(List<String> conditions)
    { system.debug('conditions are : '+ conditions);
        List<CronJobDetail> cronDetail = [SELECT Id FROM CronJobDetail WHERE Name= 'MSD_CORE_PQCRTBRetryScheduler' LIMIT 1];
        
        if(cronDetail.size() > 0)
        {system.debug('Inside cronDetail: '+ cronDetail);
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
    global Iterable<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> start(Database.BatchableContext bc) {
        system.debug('Inside start batch');
        Iterable<MSD_CORE_PQCRequest.ServiceCloudSafetyCase> recData = new MSD_CORE_PQCRTBCustomIterable(queryConditions,currentJobRunDateTime);
        return  recData; 
    }
    
    global void execute( Database.BatchableContext BC, List<object> scope ) {
        List<MSD_CORE_PIR_Request__c> aeRequests = new List<MSD_CORE_PIR_Request__c>();
         System.debug('PQC list  is :' + aeRequests);

        MSD_CORE_PQCRTBCaseJsonClass.submitPqcToRtb(scope, currentJobRunDateTime,reqInfo,aeRequests);
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
                
                MSD_CORE_PQCRTBRetryScheduler s = new MSD_CORE_PQCRTBRetryScheduler(); 
                System.schedule('MSD_CORE_PQCRTBRetryScheduler', nextFireTime, s);
            }
            catch (Exception e)
            {
                System.debug('This was the error ::: ' + e.getMessage());
            }
        
        
    }
    
}