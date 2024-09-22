public class PW_ActualStatusResponse_Model {

    public Integer MessageId{get;set;}
    public string Message{get;set;}
    public string Status{get;set;}
    
    public PW_ActualStatusResponse_Model(Integer msgId,string messageContent,string msgStatus){
        MessageId = msgId;
        Message = messageContent;
        Status = msgStatus;
    }
}