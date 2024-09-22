public with sharing class VeevaCalendarEventTriggerHandler extends VeevaTriggerHandler {
    private List<Calendar_Event_vod__c> newCalendarEvents;
    private List<Calendar_Event_vod__c> oldCalendarEvents;
    private Map<ID, Calendar_Event_vod__c> newCalendarEventsMap;
    private Map<ID, Calendar_Event_vod__c> oldCalendarEventsMap;

    protected override String sObjectType() {
        return 'Calendar_Event_vod__c ';
    }

    protected override void preTrigger(
        List<SObject> triggerNew,
        List<SObject> triggerOld,
        Map<ID, SObject> triggerNewMap,
        Map<ID, SObject> triggerOldMap
    ) {
        newCalendarEvents = (List<Calendar_Event_vod__c>) triggerNew;
        oldCalendarEvents = (List<Calendar_Event_vod__c>) triggerOld;
        newCalendarEventsMap = (Map<ID, Calendar_Event_vod__c>) triggerNewMap;
        oldCalendarEventsMap = (Map<ID, Calendar_Event_vod__c>) triggerOldMap;
    }

    protected override void beforeInsert() {
        validateCalendarEvents();
    }

    protected override void beforeUpdate() {
        validateCalendarEvents();
    }

    private void validateCalendarEvents() {
        for (Calendar_Event_vod__c newCalendarEvent : newCalendarEvents) {
            validateDatesAndTimes(newCalendarEvent);
        }
    }

    private void validateDatesAndTimes(Calendar_Event_vod__c calendarEvent) {
        Date startDate = calendarEvent.Start_Date_vod__c;
        Time startTime = calendarEvent.Start_Time_Local_vod__c;
        Date endDate = calendarEvent.End_Date_vod__c;
        Time endTime = calendarEvent.End_Time_Local_vod__c;

        if (!VeevaDateValidationHelper.areStartDateTimeAndEndDateTimePopulatedOrNull(startDate, startTime, endDate, endTime)) {
            // We do not allow just some of the four fields to be set
            calendarEvent.addError(
                VeevaMessageController.getMsgWithDefault(
                    'CALENDAR_EVENT_START_END_DATE_TIME_VALIDATION',
                    'Common',
                    'Start Date, Start Time, End Date, and End Time are required.'
                )
            );
        } else if (!VeevaDateValidationHelper.areStartDateTimeAndEndDateTimeValid(startDate, startTime, endDate, endTime)) {
            // If all four are populated, then start date + start time cannot be on or after the end date + end time
            calendarEvent.addError(
                VeevaMessageController.getMsgWithDefault(
                    'CALENDAR_EVENT_START_DATE_CANNOT_BE_GREATER',
                    'Common',
                    'Start Datetime cannot be greater than or equal to the End Datetime.'
                )
            );
        }
    }
}