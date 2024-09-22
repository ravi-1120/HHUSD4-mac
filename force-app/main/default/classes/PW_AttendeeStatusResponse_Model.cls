public class PW_AttendeeStatusResponse_Model {

    public Integer MessageId{get;set;}
    public string Message{get;set;}
    public string Status{get;set;}
    public  list<PW_Attendee_ID_Map_Model> eventAttendeeVeevaAndRowIds{get; set;}
    
    
    public PW_AttendeeStatusResponse_Model (Integer msgId,string messageContent,string msgStatus,list<PW_Attendee_ID_Map_Model> lstofAttendeeVeevaAndRowIds){
        MessageId = msgId;
        Message = messageContent;
        Status = msgStatus;
        eventAttendeeVeevaAndRowIds = lstofAttendeeVeevaAndRowIds;
    }
}