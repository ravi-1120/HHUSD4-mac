global class MSD_CORE_RecordsOperationJob extends MSD_CORE_JobQueueItemImpl {
    public virtual override Map<String,String> execute(Map<String,String> opts) {

        super.execute(opts);

        Map<String,String> result = MSD_CORE_RecordsOperationServices.execute(opts);
        Map<String,Object> jobGroup = MSD_CORE_RecordsOperationServices.createRecordsOperationJobGroup(opts);
        return super.processResult(opts, result, jobGroup);

        /*
        String done = (String)ret.get('done');
        if (done == 'false') {
            Map<String,String> nextOpts = (Map<String,String>)MSD_CORE_Setting.getStringToStringMap('LIST_MANAGER', 'updateRecordsOperationJobOptions');
            nextOpts.put('params', JSON.serializePretty(ret));
            MSD_CORE_JobQueueService.addJob(nextOpts);
        }

        opts.put('results', JSON.serializePretty(ret));
        super.done(opts);

        return ret;
        */
    }

}