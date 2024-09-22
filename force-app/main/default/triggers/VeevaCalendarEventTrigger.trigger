trigger VeevaCalendarEventTrigger on Calendar_Event_vod__c(before insert, before update) {
    VeevaTriggerHandler handler = new VeevaCalendarEventTriggerHandler();
    handler.handleTrigger();
}