public class PW_Log_Into_BatchLogger
{
    
        
    public static void LogBatch(string Call_Stack, string Error_messsage, String Log_Type, String User_name, Id Batch_Event_Id,String SchedulerName, String SchedulerID, String QueuableJobID  )
    {
        try
        {
            PW_Batch_Logger__c log= new PW_Batch_Logger__c();
            log.Call_Stack__c = Call_Stack;
            log.Log_Type__c = Log_Type;
            log.Error_messsage__c = Error_messsage;
            log.User_name__c = User_name;
            log.Batch_Event__c =  Batch_Event_Id;
            log.Scheduler_Name__c=  SchedulerName;
            log.Scheduler_ID__c =  SchedulerID;
            log.Queuable_Job_ID__c =  QueuableJobID ;
            insert log;
        }
        Catch(Exception ex)
        {
            System.Debug(ex.getMessage());
        }
            
        
    }
    
}