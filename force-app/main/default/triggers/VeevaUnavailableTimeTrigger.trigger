trigger VeevaUnavailableTimeTrigger on Unavailable_Time_vod__c (before insert, before update) {
    VeevaTriggerHandler handler = new VeevaUnavailableTimeTriggerHandler();
    handler.handleTrigger();
}