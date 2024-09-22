public class PW_QueueableDeleteActuals implements Queueable {
    public PW_Expense_Actuals_Rest_Api_Model ActualsFromTp{get;set;}
    public void execute(QueueableContext context){
        
         // Step 1: Load data
         
         // Create a savepoint while     
         Savepoint sp = Database.setSavepoint();
         id EventId=ActualsFromTp.Event_Id;
         List<id>  pw_mapped_Expensetypes= ActualsFromTp.PW_Mapped_Expensetypes; 
         List<Expense_Line_vod__c>  expenselinesList = [select Id ,Expense_Type_vod__c from Expense_Line_vod__c where Expense_Type_vod__c in :PW_Mapped_Expensetypes and Event_vod__c =:EventId];
      
        try
        {
            if(expenselinesList.size()>0)
             {
                    Database.DeleteResult[] drList=database.delete(expenselinesList ,true);
             }
         List<Expense_Header_vod__c> expenseHeaderList=[select Id  from Expense_Header_vod__c where Id not in (select Expense_Header_vod__c from Expense_Line_vod__c ) and Event_vod__c =:EventId];  
             if(expenseHeaderList.size()>0)
             {
                     Database.DeleteResult[] drList=database.delete(expenseHeaderList ,true);
             }


            PW_QueueableInsertActuals insertActualsJob = new PW_QueueableInsertActuals();
            insertActualsJob.ActualsFromTp = ActualsFromTp;
      System.enqueueJob(insertActualsJob);

        }
        catch(exception ex){
              Database.rollback(sp); 
            PW_QueueableActualCallout actualsCallOut = new PW_QueueableActualCallout();
            actualsCallOut.Message = ex.getMessage();
            actualsCallOut.Status='Fail';
            actualsCallOut.MessageId=ActualsFromTp.Message_Id;
            PW_Log_Into_CustomLogger.Log(ex.getStackTraceString(),ex.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
            
            System.enqueueJob(actualsCallOut);
        }
    }
}