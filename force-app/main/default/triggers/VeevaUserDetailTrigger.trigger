trigger VeevaUserDetailTrigger on User_Detail_vod__c (before insert, before update, before delete, after insert, after update) {
    VeevaTriggerHandler handler = new VeevaUserDetailTriggerHandler();
    handler.handleTrigger();
}