global class EmptyRecycleBinSchedulable implements Schedulable {

    @ReadOnly
    global void execute(SchedulableContext sc) {
        Id callBatchProcessID = Database.executeBatch(new EmptyRecycleBinBatchable('Call2_vod__c', 'brian_pfeil@merck.com'));
        Id eventBatchProcessID = Database.executeBatch(new EmptyRecycleBinBatchable('Event', 'brian_pfeil@merck.com'));
        System.debug('callBatchProcessID = ' + callBatchProcessID + ', eventBatchProcessID = ' + eventBatchProcessID);
    }

}