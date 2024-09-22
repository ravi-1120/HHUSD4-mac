/**  
* This is used when an exception occurs in other parts of your code,
* Call the logException method from MSD_CORE_ExceptionLogs to log the exception details in the MSD_CORE_ExceptionLogs__c custom object.
*/
public class MSD_CORE_ExceptionLogs {
    public static void logException(Exception ex,String className,String methodName,String recordId,String logType){
        List<MSD_CORE_ExceptionLogs__c> bulletinexcepList = new List<MSD_CORE_ExceptionLogs__c>();
        MSD_CORE_ExceptionLogs__c bulletinexcep = new MSD_CORE_ExceptionLogs__c ();
        if (String.isNotBlank(recordId)){
            bulletinexcep.Record_Id__c = recordId;
        }
        if (String.isNotBlank(className) && String.isNotBlank(methodName)) {
            bulletinexcep.Source__c = className + ' ' + methodName;
        }
        if (String.isNotBlank(logType)){
          bulletinexcep.Log_Type__c = logType;
        }
        bulletinexcep.Message__c = exceptionInfo(ex);
        bulletinexcepList.add(bulletinexcep);
        Database.insert(bulletinexcepList);
    }

   public static String exceptionInfo(Exception exp){  
        return   'ExceptionInfo: [ TYPE - ' + exp.getTypeName() + '\n' +' Line No - ' + exp.getLineNumber() + '\n' +
                ' MESSAGE - ' + exp.getMessage() + '\n' +' STACKTRACE - ' + exp.getStackTraceString() + ' ]';        
    }
}