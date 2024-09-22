public class PW_QueueableUpdateEstimates implements Queueable {
    public PW_Estimates_Rest_API_Model EstimatesFromTp{get;set;}
    public void execute(QueueableContext context){
        
        try
        {
        
            if(EstimatesFromTp!=null){
                PW_Update_Expense_Estimates_from_Tp.Update_Expense_Estimates_Of_Veeva(EstimatesFromTp); //Update veeva event
              }
             else{
                 Throw new Jsonexception('No estimates has been passed, estimates Json not found');//throw exception in case no event has been passed
             }
             
            PW_QueueableEstimatesCallout  estimatesCallOut = new PW_QueueableEstimatesCallout ();
            estimatesCallOut.Message = 'Successfully updated Estimates.';
            estimatesCallOut.Status='Success';
            estimatesCallOut.MessageId=EstimatesFromTp.Message_Id;
            estimatesCallOut.EventId = EstimatesFromTp.Event_Id;
            System.enqueueJob(estimatesCallOut);
             
        }
        catch(exception ex){
                     
            PW_QueueableEstimatesCallout  estimatesCallOut= new PW_QueueableEstimatesCallout ();
            estimatesCallOut.Message = ex.getMessage();
            estimatesCallOut.Status='Fail';
            estimatesCallOut.MessageId=EstimatesFromTp.Message_Id;
            estimatesCallOut.EventId = EstimatesFromTp.Event_Id;
            PW_Log_Into_CustomLogger.Log(ex.getStackTraceString(),ex.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
            System.enqueueJob(estimatesCallOut);
            
        }
    }
}