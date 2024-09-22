trigger VeevaAttachmentTrigger on Attachment (before delete, before update) {
    new VeevaAttachmentTriggerHandler().handleTrigger();
}