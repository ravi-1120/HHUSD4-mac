global class MSD_CORE_CreateSrvTgtsFromListApplctnJob extends MSD_CORE_JobQueueItemImpl {
    public virtual override Map<String,String> execute(Map<String,String> opts) {

        super.execute(opts);

        Map<String,String> result = MSD_CORE_ListServices.createSurveyTargetsFromListApplication(opts);
        Map<String,Object> jobGroup = MSD_CORE_ListServices.createCreateSurveyTargetsFromListApplicationJobGroup(opts.get('listApplicationId'));
        return super.processResult(opts, result, jobGroup);
    }

}