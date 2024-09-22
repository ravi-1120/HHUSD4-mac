trigger VeevaExternalCalendarTrigger on External_Calendar_vod__c (after update, before delete, after delete) {
    VeevaExternalCalendarTriggerHandler handler = new VeevaExternalCalendarTriggerHandler();
    handler.handleTrigger();
}