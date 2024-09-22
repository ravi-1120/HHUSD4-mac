trigger VeevaEmailActivityTrigger on Email_Activity_vod__c (after insert) {
    VeevaTriggerHandler handler = new EmailActivityTriggerHandler();
    handler.handleTrigger();
}