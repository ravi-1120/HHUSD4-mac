public class PW_Log_Into_CustomLogger
{
    
    
    public static void Log(string Call_Stack, string Error_messsage, String Log_Type, String Payload,Integer Retry_count,String User_name, string Modal_Id, string Modal_Name)
    {
        try
        {
            PW_Custom_Logger__c log= new PW_Custom_Logger__c();
            log.Call_Stack__c = Call_Stack;
            log.Type__c = Log_Type;
            log.Log_Date_Time__c = DateTime.Now();
            log.Error_messsage__c = Error_messsage;
            log.Modal_Id__c = Modal_Id;
            log.Modal_Name__c = Modal_Name;
            log.Payload__c = Payload;
            log.User_name__c = User_name;
            log.Retry_count__c = Retry_count;
            insert log;
        }
        Catch(Exception ex)
        {
            System.Debug(ex.getMessage());
        }
            
        
    }
    
    
}