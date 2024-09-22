public class VeevaQueuedCreatedRecordsQueueable implements Queueable{

    List<SObject> records = new List<SObject>();

    private VeevaSetupObjectHandler setupObjectHandler;
    public VeevaQueuedCreatedRecordsQueueable(List<SObject> records){
            this.setupObjectHandler = new VeevaSetupObjectHandler();
            this.records = records;
    }

    public void execute(QueueableContext context) {
        setupObjectHandler.createRecords(records);
    }
}