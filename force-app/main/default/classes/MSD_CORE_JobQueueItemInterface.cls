public virtual interface MSD_CORE_JobQueueItemInterface {
    Map<String,String> execute(Map<String,String> opts);
    Map<String,String> processResult(Map<String,String> opts, Map<String,String> results, Map<String,Object> jobGroup);
    Map<String,String> done(Map<String,String> opts);
}