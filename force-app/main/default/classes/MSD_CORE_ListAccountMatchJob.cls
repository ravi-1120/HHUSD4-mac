global class MSD_CORE_ListAccountMatchJob extends MSD_CORE_JobQueueItemImpl {
    public virtual override Map<String,String> execute(Map<String,String> opts) {
        super.execute(opts);
        Map<String,String> result = MSD_CORE_ListServices.accountMatch(opts);
        Map<String,Object> jobGroup = MSD_CORE_ListServices.createAccountMatchJobGroup(opts.get('listAttachmentId'));
        return super.processResult(opts, result, jobGroup);
    }

}