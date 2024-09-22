public class VeevaCreateRecordsQueueable implements Queueable{

    List<SObject> records = new List<SObject>();

    public VeevaCreateRecordsQueueable(List<SObject> records){
            this.records = records;
    }

    public void execute(QueueableContext context) {
        insert records;
    }
}