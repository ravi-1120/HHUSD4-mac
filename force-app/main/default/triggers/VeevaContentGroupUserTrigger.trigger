trigger VeevaContentGroupUserTrigger on Content_Group_User_vod__c (before insert, after insert, before update, after update, after delete) {
    VeevaContentGroupUserTriggerHandler handler = new VeevaContentGroupUserTriggerHandler();
    handler.handleTrigger();
}