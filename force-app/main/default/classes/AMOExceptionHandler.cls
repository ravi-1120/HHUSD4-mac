public class AMOExceptionHandler {

    public static void logException(Exception ex,String className,String methodName,String recordId,String logType){
        List<Log__c> amologExpList = new List<Log__c>();
        Log__c amologExp = new Log__c ();
        if (String.isNotBlank(recordId)){
            amologExp.Record_Id__c = recordId;
        }
        if (String.isNotBlank(className) && String.isNotBlank(methodName)) {
            amologExp.Source__c = className+' '+methodName;
        }
        if (String.isNotBlank(logType)){
          amologExp.Log_Type__c = logType;
        }
        amologExp.Payload__c = String.valueOf(ex);
        amologExp.Message__c = exceptionInfo(ex);
        amologExpList.add(amologExp);
        Database.insert(amologExpList);
    }

   public static String exceptionInfo(Exception exp){  
        return   'ExceptionInfo: [ TYPE - ' + exp.getTypeName() + '\n' +' Line No - ' + exp.getLineNumber() + '\n' +
                ' MESSAGE - ' + exp.getMessage() + '\n' +' STACKTRACE - ' + exp.getStackTraceString() + ' ]';        
    }
     public static void logRequestResponse(String request,String response,String url,String className,String methodName,String recordId,String logType){
        List<Log__c> amologExpList = new List<Log__c>();
        Log__c amologExp = new Log__c ();
        if (String.isNotBlank(recordId)){
            amologExp.Record_Id__c = recordId;
        }
        if (String.isNotBlank(className) && String.isNotBlank(methodName)) {
            amologExp.Source__c = className+' '+methodName;
        }
        if (String.isNotBlank(logType)){
          amologExp.Log_Type__c = logType;
        }
        amologExp.Payload__c = request;
        amologExp.Message__c = response;
        amologExp.End_Point__c= url;
        amologExpList.add(amologExp);
        Database.insert(amologExpList);
    }
}