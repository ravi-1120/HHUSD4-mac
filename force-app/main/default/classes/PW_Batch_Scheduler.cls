global class PW_Batch_Scheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        
        PW_BatchEventProcessingAdv processBatch = new PW_BatchEventProcessingAdv();
        processBatch.processBatchOfEvents(ctx);
        
    }
}