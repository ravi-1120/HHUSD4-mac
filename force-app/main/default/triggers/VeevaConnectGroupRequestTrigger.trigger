trigger VeevaConnectGroupRequestTrigger on Engage_Connect_Group_Request_vod__c (before insert, before update, after insert, after update) {
    VeevaTriggerHandler handler = new VeevaConnectGroupRequestTriggerHandler();
    handler.handleTrigger();
}