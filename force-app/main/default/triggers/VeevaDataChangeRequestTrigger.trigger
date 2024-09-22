trigger VeevaDataChangeRequestTrigger on Data_Change_Request_vod__c (after insert, after update) {
    VeevaTriggerHandler handler = new VeevaDataChangeRequestTriggerHandler();
    handler.handleTrigger();
}