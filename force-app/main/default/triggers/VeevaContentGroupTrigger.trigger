trigger VeevaContentGroupTrigger on Content_Group_vod__c (before insert, after insert, before update, after update, after delete) {
    VeevaContentGroupTriggerHandler handler = new VeevaContentGroupTriggerHandler();
    handler.handleTrigger();
}