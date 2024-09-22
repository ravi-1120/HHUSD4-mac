global class MSD_CORE_ProcessUpdtsToListAttachmentJob extends MSD_CORE_JobQueueItemImpl {
    public virtual override Map<String,String> execute(Map<String,String> opts) {

        super.execute(opts);

        Map<String,String> result = MSD_CORE_ListServices.processUpdatesToListAttachment(opts);
        Map<String,Object> jobGroup = MSD_CORE_ListServices.createProcessUpdatesToListAttachmentJobGroup(opts.get('listAttachmentId'));
        return super.processResult(opts, result, jobGroup);
    }

}