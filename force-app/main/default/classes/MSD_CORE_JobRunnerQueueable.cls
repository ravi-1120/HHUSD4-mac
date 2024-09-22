public class MSD_CORE_JobRunnerQueueable implements Queueable {
    private String className;
    private Map<String,String> opts;
    public MSD_CORE_JobRunnerQueueable(String className, Map<String,String> opts) {
        this.className = className;
        this.opts = opts;
    }

    public void execute(QueueableContext context) {
        MSD_CORE_Logger.loggingEnabled = true;
        try {
            Type t = Type.forName(this.className);
            MSD_CORE_JobQueueItemInterface jq = (MSD_CORE_JobQueueItemInterface)t.newInstance();
            jq.execute(this.opts);
        } catch (Exception e) {
          String errString = e + ', line #:' + e.getLineNumber() + '\nStack Trace:\n' + e.getStackTraceString();
          MSD_CORE_Logger.error(errString);

            String jobQueueItemId = opts.get('MSD_CORE_Job_Queue_Item__c');
            MSD_CORE_Job_Queue_Item__c jobQueueItem = [select Id, MSD_CORE_Status__c from MSD_CORE_Job_Queue_Item__c where Id = :jobQueueItemId];
            jobQueueItem.MSD_CORE_Status__c = 'completed with errors';
            jobQueueItem.MSD_CORE_Errors__c = errString;
            update jobQueueItem;

            String jobQueueGroupId = opts.get('MSD_CORE_Job_Queue_Group__c');
            MSD_CORE_Job_Queue_Group__c jobQueueGroup = [select Id, MSD_CORE_Status__c from MSD_CORE_Job_Queue_Group__c where Id = :jobQueueGroupId];
            jobQueueGroup.MSD_CORE_Status__c = 'completed with errors';
            update jobQueueGroup;

        } finally {
            MSD_CORE_Logger.flush();
        }
    }
}