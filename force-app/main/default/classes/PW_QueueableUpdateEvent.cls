public class PW_QueueableUpdateEvent implements Queueable {
    public PW_Event_Model EventFromTp{get;set;}
    public void execute(QueueableContext context){
        
        try
        {
        
            if(EventFromTp !=null){
                PW_Update_Veeva_Event_From_Tp.Update_Event_Speaker_TeamMembers_Of_Veeva(EventFromTp); //Update veeva event
              }
             else{
                 Throw new JsonException('No event has been passed, Event Json not found');//throw exception in case no event has been passed
             }
             
            PW_QueueableEventCallout eventCallOut = new PW_QueueableEventCallout();
            eventCallOut.Message = 'Successfully updated Event.';
            eventCallOut.Status='Success';
            eventCallOut.MessageId=EventFromTp.Message_Id;
            eventCallOut.EventId = EventFromTp.Id;
            System.enqueueJob(eventCallOut);
             
        }
        catch(exception ex){
            
            PW_Log_Into_CustomLogger.Log(ex.getStackTraceString(),ex.getMessage(), Pw_Logger_Constants.GENERAL_EXCEPTION,'', 0 , UserInfo.getUserName(), 'NA', 'NA');
            PW_QueueableEventCallout eventCallOut= new PW_QueueableEventCallout();
            eventCallOut.Message = ex.getMessage();
            eventCallOut.Status='Fail';
            eventCallOut.MessageId=EventFromTp.Message_Id;
            eventCallOut.EventId = EventFromTp.Id;
            System.enqueueJob(eventCallOut);
            
        }
    }
}