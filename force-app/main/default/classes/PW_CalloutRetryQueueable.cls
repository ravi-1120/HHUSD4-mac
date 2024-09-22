public class PW_CalloutRetryQueueable implements Queueable, Database.AllowsCallouts {
    public integer noofcalloutcount;
    public integer maxcalloutcount;
    public integer callinseconds;
    public string jsonbody;
    public string modalName;
    public string modalId;

    public void execute(QueueableContext context) {
    if(noofcalloutcount<=maxcalloutcount)
    {
               Pw_Call_Service_Bus_API.callAPIFromQueuable(jsonbody,noofcalloutcount,maxcalloutcount, callinseconds, ModalName,ModalId);     
        
    }
   }

}