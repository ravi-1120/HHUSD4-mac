public class PW_QueueableActualCallout implements Queueable, Database.AllowsCallouts {
    public Integer MessageId{get;set;}
    public string Message{get;set;}
    public string Status{get;set;}
    public Id EventId{get;set;}
    
    public void execute(QueueableContext context){
        
        Pw_Call_Service_Bus_API.MakeCallOutSuccessFailureMessage(MessageId,Message,Status,EventId);
    }
}