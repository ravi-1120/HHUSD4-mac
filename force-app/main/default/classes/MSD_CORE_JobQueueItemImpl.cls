public virtual class MSD_CORE_JobQueueItemImpl implements MSD_CORE_JobQueueItemInterface {
    private MSD_CORE_Job_Queue_Item__c jobQueueItemRecord;
    public virtual Map<String,String> execute(Map<String,String> opts) {
        MSD_CORE_Logger.loggingEnabled = true;

        try {
            Id jobQueueItemId =  (Id)opts.get('MSD_CORE_Job_Queue_Item__c');
            jobQueueItemRecord = [select Id, MSD_CORE_Class_Name__c, MSD_CORE_Params__c, MSD_CORE_Status__c, MSD_CORE_Job_Queue_Group__c, MSD_CORE_Job_Queue_Group__r.MSD_CORE_End_DateTime__c, MSD_CORE_Job_Queue_Group__r.MSD_CORE_Exec_Elapsed_Time_In_Secs__c, MSD_CORE_Job_Queue_Group__r.MSD_CORE_Job_Queue_Item_Count__c, MSD_CORE_Job_Queue_Group__r.LastModifiedDate, MSD_CORE_Job_Queue_Group__r.Name, MSD_CORE_Job_Queue_Group__r.MSD_CORE_Name__c, MSD_CORE_Job_Queue_Group__r.OwnerId, MSD_CORE_Job_Queue_Group__r.MSD_CORE_Sequence__c, MSD_CORE_Job_Queue_Group__r.MSD_CORE_Start_DateTime__c, MSD_CORE_Job_Queue_Group__r.MSD_CORE_Status__c from MSD_CORE_Job_Queue_Item__c where Id = :jobQueueItemId limit 1];
            jobQueueItemRecord.MSD_CORE_Status__c = 'executing';
            jobQueueItemRecord.MSD_CORE_Execution_Start_DateTime__c = DateTime.now();
            update jobQueueItemRecord;
        } catch (Exception e) {
          String errString = e + ', line #:' + e.getLineNumber() + '\nStack Trace:\n' + e.getStackTraceString();
          MSD_CORE_Logger.error(errString);
        } finally {
            MSD_CORE_Logger.flush();
        }
        return opts;
    }

    public virtual Map<String,String> processResult(Map<String,String> opts, Map<String,String> results, Map<String,Object> jobGroup) {

        MSD_CORE_Logger.loggingEnabled = true;
        //MSD_CORE_Logger.debug('MSD_CORE_JobQueueItemImpl.processResult\nopts=\n' + JSON.serializePretty(opts) + '\nresults=\n' + JSON.serializePretty(results) + '\njobGroup=\n' + JSON.serializePretty(jobGroup));
        MSD_CORE_Logger.debug('MSD_CORE_JobQueueItemImpl.processResult\nopts=\n' + JSON.serializePretty(opts));
        MSD_CORE_Logger.flush();

        // check if there is any more work to do
        String done = (String)results.get('done');
        if (done == 'false') {

            // inject params into the only job item
            List<Map<String,String>> jobItemList = (List<Map<String,String>>)jobGroup.get('jobItemList');
            opts.putAll(results);
            jobItemList[0].put('params', JSON.serializePretty(opts));
            jobGroup.put('jobItemList', jobItemList);

            String jobQueueGroupId = opts.get('MSD_CORE_Job_Queue_Group__c');
            if (jobQueueGroupId != null) {
                MSD_CORE_JobQueueService.addJobToJobGroup(jobItemList[0], jobQueueGroupId);
                opts.put('isLastJobItemInGroup', 'false');
            } else {
                MSD_CORE_JobQueueService.addJobGroup(jobGroup);
            }
        }

        opts.put('results', JSON.serializePretty(results));
        return done(opts);

    }

    public virtual Map<String,String> done(Map<String,String> opts) {
        MSD_CORE_Logger.loggingEnabled = true;
        try {
            MSD_CORE_Logger.debug('MSD_CORE_JobQueueItemImpl.done\n' + JSON.serializePretty(opts));
            jobQueueItemRecord.MSD_CORE_Status__c = 'complete';
            jobQueueItemRecord.MSD_CORE_Execution_End_DateTime__c = DateTime.now();
            //jobQueueItemRecord.MSD_CORE_Exec_Elapsed_Time_In_Secs__c = ;

            String isLastJobItemInGroup = (String)opts.get('isLastJobItemInGroup');
            if (isLastJobItemInGroup == 'true') {
                // TODO: update group record with status = 'complete', timestamps, elapsed times, etc.
                jobQueueItemRecord.MSD_CORE_Job_Queue_Group__r.MSD_CORE_Status__c = 'completed';
                jobQueueItemRecord.MSD_CORE_Job_Queue_Group__r.MSD_CORE_End_DateTime__c = DateTime.now();
                //jobQueueItemRecord.Job_Queue_Group_MRK__r.MSD_CORE_Exec_Elapsed_Time_In_Secs__c = ;
            }

            // TODO: dynamic update with saveresult and check for errors
            update jobQueueItemRecord;
            update jobQueueItemRecord.MSD_CORE_Job_Queue_Group__r;

            // check for 'ready' items in the queue
            MSD_CORE_JobQueueService.run();
        } catch (Exception e) {
          String errString = e + ', line #:' + e.getLineNumber() + '\nStack Trace:\n' + e.getStackTraceString();
          MSD_CORE_Logger.error(errString);
        } finally {
            MSD_CORE_Logger.flush();
        }
        return opts;
    }

}