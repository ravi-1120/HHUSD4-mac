global class MSD_CORE_ExportToAttachmentJob extends MSD_CORE_JobQueueItemImpl {
    public virtual override Map<String,String> execute(Map<String,String> opts) {

        super.execute(opts);

        Map<String,String> result = MSD_CORE_ExportToAttachmentServices.exportToAttachment(opts);
        Map<String,Object> jobGroup = MSD_CORE_ExportToAttachmentServices.createExportToAttachmentJobGroup(opts);
        return super.processResult(opts, result, jobGroup);

    }

}