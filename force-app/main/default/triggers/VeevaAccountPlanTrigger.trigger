trigger VeevaAccountPlanTrigger on Account_Plan_vod__c(before insert, before update, before delete) {
    VeevaTriggerHandler handler = new VeevaAccountPlanTriggerHandler();
    handler.handleTrigger();
}