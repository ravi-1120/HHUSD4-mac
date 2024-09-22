trigger MSD_CORE_AttachmentTriggerHandler on Attachment (after delete, after insert, after update, before delete, before insert, before update) {
    MSD_CORE_TriggerFactory.process(Attachment.sObjectType);
}