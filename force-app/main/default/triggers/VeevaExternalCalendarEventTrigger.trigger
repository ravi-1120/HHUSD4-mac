trigger VeevaExternalCalendarEventTrigger on External_Calendar_Event_vod__c (after insert, after update, before delete) {
    VeevaExternalCalendarEventTriggerHandler handler = new VeevaExternalCalendarEventTriggerHandler();
    handler.handleTrigger();
}