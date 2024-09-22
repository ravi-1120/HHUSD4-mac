trigger MSD_CORE_JobQueueGroupTriggerHandler on MSD_CORE_Job_Queue_Group__c (after delete, after insert, after update, before delete, before insert, before update) {
    MSD_CORE_TriggerFactory.process(MSD_CORE_Job_Queue_Group__c.sObjectType);
}