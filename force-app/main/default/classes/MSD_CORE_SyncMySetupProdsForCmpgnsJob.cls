global class MSD_CORE_SyncMySetupProdsForCmpgnsJob extends MSD_CORE_JobQueueItemImpl {
    public virtual override Map<String,String> execute(Map<String,String> opts) {

        super.execute(opts);

        Map<String,String> result = MSD_CORE_MySetupProductsServices.syncMySetupProductsForProductMetricCampaigns(opts);
        Map<String,Object> jobGroup = MSD_CORE_MySetupProductsServices.createSyncMySetupProductsForProductMetricCampaignsJobGroup(opts);
        return super.processResult(opts, result, jobGroup);

    }

}