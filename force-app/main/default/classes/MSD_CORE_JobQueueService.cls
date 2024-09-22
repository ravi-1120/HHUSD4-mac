global class MSD_CORE_JobQueueService {
    private static List<MSD_CORE_Job_Queue_Group__c> jobGroupList;

    public static Map<String,Object> getJobItemTemplate(String jobItemName) {
        String key = 'jobItemTemplates.' + jobItemName;

        Map<String,Object> result =  (Map<String,Object>)MSD_CORE_Setting.getObject('LIST_MANAGER', key);

        return result;
    }

    public static Map<String,String> getJobItemParamsTemplate(String jobItemName) {
        Map<String,Object> jobItemTemplate = getJobItemTemplate(jobItemName);
        String paramsString = (String)jobItemTemplate.get('params');
        return (Map<String,String>)JSON.deserialize(paramsString, Map<String,String>.class);
    }

    public static Map<String,Object> addJobGroup(Map<String,Object> opts) {

        List<MSD_CORE_Job_Queue_Group__c> sequenceJobGroupList = [select Id, MSD_CORE_Sequence__c from MSD_CORE_Job_Queue_Group__c order by MSD_CORE_Sequence__c desc];
        MSD_CORE_Job_Queue_Group__c grp = new MSD_CORE_Job_Queue_Group__c(
            MSD_CORE_Name__c=(String)opts.get('name'),
            MSD_CORE_Status__c='ready',
            MSD_CORE_Sequence__c=(sequenceJobGroupList.size() > 0) ? (sequenceJobGroupList[0].MSD_CORE_Sequence__c + 1) : 0
        );

        // TODO: error handling
        Database.SaveResult sr = Database.insert(grp);
        if (!sr.isSuccess()) {
            //return halt(opts);
        }


        List<Map<String,String>> jobItemList = (List<Map<String,String>>)opts.get('jobItemList');
        List<MSD_CORE_Job_Queue_Item__c> jobQueueItemList = new List<MSD_CORE_Job_Queue_Item__c>();
        Integer sequence = 0;
        for (Map<String,String> jobItem : jobItemList) {
            MSD_CORE_Job_Queue_Item__c item = new MSD_CORE_Job_Queue_Item__c(
                MSD_CORE_Job_Queue_Group__c = sr.getId(),
                MSD_CORE_Params__c = jobItem.get('params'),
                MSD_CORE_Class_Name__c = jobItem.get('className'),
                MSD_CORE_Status__c='ready',
                MSD_CORE_Sequence__c = sequence++
            );
            jobQueueItemList.add(item);
        }

        Database.SaveResult[] srList = Database.insert(jobQueueItemList);
        // TODO: error handling

        return opts;
    }

    public static Map<String,String> addJob(Map<String,String> opts) {
        String type = (String)opts.get('type');

        if (type == 'singleItem') {
            MSD_CORE_Job_Queue_Group__c grp = new MSD_CORE_Job_Queue_Group__c(
                MSD_CORE_Name__c=(String)opts.get('name'),
                MSD_CORE_Status__c='ready',
                MSD_CORE_Sequence__c=1
            );

            // TODO: more error handling
            Database.SaveResult sr = Database.insert(grp);
            if (!sr.isSuccess()) {
                //return halt(opts);
            }

            MSD_CORE_Job_Queue_Item__c item = new MSD_CORE_Job_Queue_Item__c(
                MSD_CORE_Job_Queue_Group__c = sr.getId(),
                MSD_CORE_Params__c = (String)opts.get('params'),
                MSD_CORE_Class_Name__c = (String)opts.get('className'),
                MSD_CORE_Status__c='ready',
                MSD_CORE_Sequence__c = 1
            );

            sr = Database.insert(item);
            // TODO: more error handling
        }

        return opts;
    }

    public static Map<String,String> addJobToJobGroup(Map<String,String> jobItem, String jobGroupId) {
        MSD_CORE_Logger.loggingEnabled = true;

        MSD_CORE_Logger.debug('MSD_CORE_JobQueueService.addJobToJobGroup(' + JSON.serializePretty(jobItem) + ', jobGroupId=' + jobGroupId);
        MSD_CORE_Logger.flush();

        List<MSD_CORE_Job_Queue_Item__c> jobItemList = [select Id, MSD_CORE_Sequence__c from MSD_CORE_Job_Queue_Item__c where MSD_CORE_Job_Queue_Group__c = :jobGroupId order by MSD_CORE_Sequence__c desc];

        Decimal sequence = (jobItemList.size() > 0) ? (jobItemList[0].MSD_CORE_Sequence__c + 1) : 0;

        MSD_CORE_Job_Queue_Item__c item = new MSD_CORE_Job_Queue_Item__c(
            MSD_CORE_Job_Queue_Group__c = jobGroupId,
            MSD_CORE_Params__c = jobItem.get('params'),
            MSD_CORE_Class_Name__c = jobItem.get('className'),
            MSD_CORE_Status__c='ready',
            MSD_CORE_Sequence__c = sequence
        );

        Database.SaveResult sr = Database.insert(item);
        if (!sr.isSuccess()) {
                //return halt(opts);
        }

        return jobItem;
    }

    public static void run() {
        MSD_CORE_Logger.loggingEnabled = true;

        try {

            jobGroupList = [select CreatedById, CreatedDate, MSD_CORE_Description__c, MSD_CORE_End_DateTime__c, MSD_CORE_Exec_Elapsed_Time_In_Secs__c, Id, MSD_CORE_Job_Queue_Item_Count__c, LastModifiedById, LastModifiedDate, Name, MSD_CORE_Name__c, OwnerId, MSD_CORE_Sequence__c, MSD_CORE_Start_DateTime__c, MSD_CORE_Status__c, SystemModstamp, (select MSD_CORE_Class_Name__c, CreatedById, CreatedDate, MSD_CORE_Enqueued_Start_DateTime__c, MSD_CORE_Enq_Elapsed_Time_In_Secs__c, MSD_CORE_Errors__c, MSD_CORE_Exec_Elapsed_Time_In_Secs__c, MSD_CORE_Execution_End_DateTime__c, MSD_CORE_Execution_Start_DateTime__c, Id, MSD_CORE_Job_Queue_Group__c, MSD_CORE_JobID__c, LastModifiedById, LastModifiedDate, MSD_CORE_Limits__c, Name, OwnerId, MSD_CORE_Params__c, MSD_CORE_Sequence__c, MSD_CORE_Status__c, MSD_CORE_Submit_Start_DateTime__c from Job_Queue_Items__r order by MSD_CORE_Sequence__c asc) from MSD_CORE_Job_Queue_Group__c where MSD_CORE_Status__c IN ('ready', 'enqueued', 'executing') order by MSD_CORE_Sequence__c asc];


            List<MSD_CORE_Job_Queue_Group__c> readyJobGroupList = new List<MSD_CORE_Job_Queue_Group__c>();
            List<MSD_CORE_Job_Queue_Group__c> enqueuedJobGroupList = new List<MSD_CORE_Job_Queue_Group__c>();
            List<MSD_CORE_Job_Queue_Group__c> executingJobGroupList = new List<MSD_CORE_Job_Queue_Group__c>();

            for (MSD_CORE_Job_Queue_Group__c jobGroup : jobGroupList) {
                if (jobGroup.MSD_CORE_Status__c == 'ready') {
                    readyJobGroupList.add(jobGroup);
                }

                if (jobGroup.MSD_CORE_Status__c == 'enqueued') {
                    enqueuedJobGroupList.add(jobGroup);
                }

                if (jobGroup.MSD_CORE_Status__c == 'executing') {
                    executingJobGroupList.add(jobGroup);
                }
            }

            MSD_CORE_Logger.debug('MSD_CORE_JobQueueService.run: ' + readyJobGroupList.size() + ' Job Group Ready, ' + executingJobGroupList.size() + ' Job Group(s) Executing');
            if ( (readyJobGroupList.size() == 0) && (executingJobGroupList.size() == 0) ){
                MSD_CORE_Logger.debug('MSD_CORE_JobQueueService.run called:  no Job Group is ready or has Job Queue Items left to execute.  exiting.');
                MSD_CORE_Logger.flush();
                return;
            }

            // executing jobs to priority over 'ready' Job Queue Groups
            if (executingJobGroupList.size() > 0) {
                readyJobGroupList.clear();
                readyJobGroupList.addAll(executingJobGroupList);
            }

            MSD_CORE_Job_Queue_Item__c nextJobItem = null;
            List<MSD_CORE_Job_Queue_Item__c> readJobItemList = new List<MSD_CORE_Job_Queue_Item__c>();
            List<MSD_CORE_Job_Queue_Item__c> nonReadyStatusJobItemList = new List<MSD_CORE_Job_Queue_Item__c>();
            MSD_CORE_Job_Queue_Group__c jobGroup = null;
            if (readyJobGroupList.size() > 0) {
                jobGroup = readyJobGroupList[0];

                for (MSD_CORE_Job_Queue_Item__c jobItem : jobGroup.Job_Queue_Items__r) {
                    if (jobItem.MSD_CORE_Status__c == 'ready') {
                        readJobItemList.add(jobItem);
                    } else {
                        nonReadyStatusJobItemList.add(jobItem);
                    }


                }
            }

            if (readJobItemList.size() == 0) {
                MSD_CORE_Logger.debug('MSD_CORE_JobQueueService.run:  no Job Queue Items to process.  exiting.');
                MSD_CORE_Logger.flush();
                return;
            }

            nextJobItem = readJobItemList[0];

            Map<String,String> opts = (Map<String,String>)JSON.deserialize(nextJobItem.MSD_CORE_Params__c, Map<String,String>.class);
            opts.put('MSD_CORE_Job_Queue_Item__c', nextJobItem.Id + '');
            opts.put('MSD_CORE_Job_Queue_Group__c', jobGroup.Id);
            opts.put('isLastJobItemInGroup', ( readJobItemList.size() == 1 ) ? 'true' : 'false');
            MSD_CORE_JobRunnerQueueable jobRunner = new MSD_CORE_JobRunnerQueueable(nextJobItem.MSD_CORE_Class_Name__c, opts);

            ID jobId = System.enqueueJob(jobRunner);

            // TODO: dynamic update with saveresult and check for errors
            nextJobItem.MSD_CORE_Status__c = 'enqueued';
            nextJobItem.MSD_CORE_Enqueued_Start_DateTime__c = DateTime.now();
            //nextJobItem.Submit_Start_DateTime__c = DateTime.now();
            nextJobItem.MSD_CORE_JobID__c = jobId;
            nextJobItem.MSD_CORE_Enqueued_Start_DateTime__c = DateTime.now();
            Database.SaveResult sr = Database.update(nextJobItem);

            if (nonReadyStatusJobItemList.size() == 0) {
                jobGroup.MSD_CORE_Status__c = 'executing';
                jobGroup.MSD_CORE_Start_DateTime__c = DateTime.now();
                jobGroup.MSD_CORE_Job_Queue_Item_Count__c = readJobItemList.size();
                // TODO: dynamic update with saveresult and check for errors
                update jobGroup;
            }


            // TODO: store jobId in jobQueueRecord.
            // jobQueueRecord.MSD_CORE_jobID = jobID
            // jobQueueRecord.MSD_CORE_status = 'enqueued';

        } catch (Exception e) {
          String errString = e + ', line #:' + e.getLineNumber() + '\nStack Trace:\n' + e.getStackTraceString();
          MSD_CORE_Logger.error(errString);
        } finally {
            MSD_CORE_Logger.flush();
        }

    }

    public static void test() {
        // grab "most recent" group
        MSD_CORE_Job_Queue_Group__c jobQueueGroup = [select CreatedById, CreatedDate, MSD_CORE_Description__c, MSD_CORE_End_DateTime__c, MSD_CORE_Exec_Elapsed_Time_In_Secs__c, Id, IsDeleted, IsLocked, MSD_CORE_Job_Queue_Item_Count__c, LastActivityDate, LastModifiedById, LastModifiedDate, Name, MSD_CORE_Name__c, OwnerId, MSD_CORE_Sequence__c, MSD_CORE_Start_DateTime__c, MSD_CORE_Status__c, SystemModstamp from MSD_CORE_Job_Queue_Group__c order by LastModifiedDate desc limit 1];

        // "reset" field values
        jobQueueGroup.MSD_CORE_Status__c = 'ready';
        jobQueueGroup.MSD_CORE_Start_DateTime__c = null;
        jobQueueGroup.MSD_CORE_End_DateTime__c = null;
        jobQueueGroup.MSD_CORE_Exec_Elapsed_Time_In_Secs__c = null;
        jobQueueGroup.MSD_CORE_Job_Queue_Item_Count__c = null;
        jobQueueGroup.MSD_CORE_Sequence__c = 1;
        update jobQueueGroup;

        // fetch job queue items for group
        List<MSD_CORE_Job_Queue_Item__c> jobQueueItemList = [select MSD_CORE_Class_Name__c, CreatedById, CreatedDate, MSD_CORE_Enqueued_Start_DateTime__c, MSD_CORE_Enq_Elapsed_Time_In_Secs__c, MSD_CORE_Errors__c, MSD_CORE_Exec_Elapsed_Time_In_Secs__c, MSD_CORE_Execution_End_DateTime__c, MSD_CORE_Execution_Start_DateTime__c, Id, IsDeleted, IsLocked, MSD_CORE_Job_Queue_Group__c, MSD_CORE_JobID__c, LastModifiedById, LastModifiedDate, MSD_CORE_Limits__c, Name, OwnerId, MSD_CORE_Params__c, MSD_CORE_Sequence__c, MSD_CORE_Status__c, MSD_CORE_Submit_Start_DateTime__c, SystemModstamp from MSD_CORE_Job_Queue_Item__c where MSD_CORE_Job_Queue_Group__c = :jobQueueGroup.Id ];
        for (MSD_CORE_Job_Queue_Item__c jobQueueItem : jobQueueItemList) {
            // "reset" field values
            jobQueueItem.MSD_CORE_Status__c = 'ready';
            jobQueueItem.MSD_CORE_Enqueued_Start_DateTime__c = null;
            jobQueueItem.MSD_CORE_Enq_Elapsed_Time_In_Secs__c = null;
            jobQueueItem.MSD_CORE_Errors__c = null;
            jobQueueItem.MSD_CORE_Exec_Elapsed_Time_In_Secs__c = null;
            jobQueueItem.MSD_CORE_Execution_End_DateTime__c = null;
            jobQueueItem.MSD_CORE_Execution_Start_DateTime__c = null;
            jobQueueItem.MSD_CORE_JobID__c = null;
            jobQueueItem.MSD_CORE_Limits__c = null;
            jobQueueItem.MSD_CORE_Submit_Start_DateTime__c = null;
        }

        update jobQueueItemList;

        run();
    }

}