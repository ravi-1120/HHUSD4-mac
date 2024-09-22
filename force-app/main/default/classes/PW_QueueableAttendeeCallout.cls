public class PW_QueueableAttendeeCallout implements Queueable, Database.AllowsCallouts {
    public Integer MessageId{get;set;}
    public string Message{get;set;}
    public string Status{get;set;}
    public Id EventId{get;set;}
    public list<PW_Attendee_ID_Map_Model> eventAttendeeVeevaAndRowIds{get; set;}
    
    public void execute(QueueableContext context){
        
        Pw_Call_Service_Bus_API.MakeCallOutSuccessFailureMessageForAttendee(MessageId,Message,Status,EventId,eventAttendeeVeevaAndRowIds);
    }
}