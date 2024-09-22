global class MSD_CORE_ListAttachmentJob extends MSD_CORE_JobQueueItemImpl {

    public virtual override Map<String,String> execute(Map<String,String> opts) {
        super.execute(opts);
        Map<String,String> result = MSD_CORE_ListServices.unpackListAttachment(opts);

        result.put('MSD_CORE_Job_Queue_Group__c', opts.get('MSD_CORE_Job_Queue_Group__c'));
        result.put('MSD_CORE_Job_Queue_Item__c', opts.get('MSD_CORE_Job_Queue_Item__c'));


        Map<String,Object> jobGroup = MSD_CORE_ListServices.createUnpackListAttachmentJobGroup(result.get('listAttachmentId'));
        return super.processResult(opts, result, jobGroup);
    }


}