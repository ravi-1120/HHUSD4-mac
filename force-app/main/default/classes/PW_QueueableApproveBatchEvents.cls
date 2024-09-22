public class PW_QueueableApproveBatchEvents implements Queueable
{
    public List<PW_ApproveBatchEvent> events{get;set;}
    
    public PW_QueueableApproveBatchEvents()
    {
        events = new List<PW_ApproveBatchEvent>();
    }
    
    public void execute(QueueableContext context){
    
        for(PW_ApproveBatchEvent evt : events)
        {
            evt.execute(context);
        }
    
    }
}