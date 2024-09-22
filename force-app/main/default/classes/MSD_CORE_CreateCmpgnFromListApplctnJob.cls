global class MSD_CORE_CreateCmpgnFromListApplctnJob extends MSD_CORE_JobQueueItemImpl {
    public virtual override Map<String,String> execute(Map<String,String> opts) {

        super.execute(opts);

        String op = opts.get('op');

        Map<String,String> result;
        Map<String,Object> jobGroup;

        if (op == 'createCampaign' || op == 'createCampaignTargets') {
            result = MSD_CORE_ListServices.createCampaignFromListApplication(opts);
            jobGroup = MSD_CORE_ListServices.createCreateCampaignFromListApplicationJobGroup(opts.get('listApplicationId'));
        }

        if (op == 'inactivateCampaign') {
            result = MSD_CORE_ListServices.createCampaignFromListApplication(opts);
            jobGroup = MSD_CORE_ListServices.createInactivateCampaignFromListApplicationJobGroup(opts.get('listApplicationId'));
        }

        return super.processResult(opts, result, jobGroup);

    }

}