trigger VeevaContentGroupContentTrigger on Content_Group_Content_vod__c (before insert, after insert, before update, after update, after delete) {
    VeevaContentGroupContentTriggerHandler handler = new VeevaContentGroupContentTriggerHandler();
    handler.handleTrigger();
}