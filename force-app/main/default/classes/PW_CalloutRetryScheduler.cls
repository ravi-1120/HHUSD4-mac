public class PW_CalloutRetryScheduler implements Schedulable{
    public integer noofcalloutcount;
    public integer maxcalloutcount;
    public integer callinseconds;
    public string jsonbody;
    public string modalName;
    public string modalId;
    
    public void execute(SchedulableContext SC) {
    
    PW_CalloutRetryQueueable quable= new PW_CalloutRetryQueueable();
    quable.noofcalloutcount=noofcalloutcount;
    quable.maxcalloutcount=maxcalloutcount;
    quable.jsonbody=jsonbody;
    quable.modalName=modalName;
    quable.modalId=modalId;
    quable.callinseconds = callinseconds;    
    System.enqueueJob(quable);
    System.abortJob(SC.getTriggerID());
   }

}