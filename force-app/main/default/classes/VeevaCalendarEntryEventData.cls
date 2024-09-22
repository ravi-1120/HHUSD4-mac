public with sharing class VeevaCalendarEntryEventData extends VeevaCalendarData {

    public VeevaCalendarEntryEventData(Datetime startDateTime, Datetime endDateTime) {
        this(startDateTime, endDateTime, UserInfo.getUserId());
    }

    public VeevaCalendarEntryEventData(Datetime startDateTime, Datetime endDateTime, Id userId) {
        super(
            new Set<String>{'WhatId', 'IsRecurrence', 'IsAllDayEvent', 'OwnerId', 'DurationInMinutes', 'StartDateTime', 'EndDateTime', 'toLabel(Subject)', 'Location', 'Color_vod__c', 'toLabel(EventSubtype)', 'toLabel(RecordType.Name)'},
            userId, 
            'Event',
            startDateTime,
            endDateTime
        );
        Map<String, SObjectField> descr = Event.SObjectType.getDescribe().fields.getMap();
        this.fields = filterFields(descr, this.getQueryFields());
    }

    public static String updateSingleEvent(Event eventToUpdate, Long startTimeChange, Integer duration) {
        try {
            eventToUpdate.StartDateTime = Datetime.newInstance(eventToUpdate.StartDateTime.getTime() + startTimeChange);
            eventToUpdate.EndDateTime = null; // allow enddatetime to be calculated on update
            eventToUpdate.DurationInMinutes = duration;
            update eventToUpdate;
        } catch (DmlException e) {
            return e.getDmlMessage(0);
        }
        return null;
    }

    public static void updateEventSeries(Event updatedEvent, Long startTimeChange, Integer duration) {
        Datetime currentDate = Datetime.now();
        String name = updatedEvent.Subject;
        Datetime recurrenceStart = updatedEvent.Recurrence2PatternStartDate;
        try {
            List<Event> updatedEventList = [SELECT Id, Subject, StartDateTime, EndDateTime, IsAllDayEvent, DurationInMinutes, IsRecurrence2, Recurrence2PatternStartDate FROM Event 
                WHERE Recurrence2PatternStartDate = :recurrenceStart AND Subject = :name AND StartDateTime >= :currentDate];

            for (Event eventInstance : updatedEventList) {
                if (eventInstance.Id == updatedEvent.Id) {
                    continue;
                }
                eventInstance.StartDateTime = Datetime.newInstance(eventInstance.StartDateTime.getTime() + startTimeChange);
                eventInstance.EndDateTime = null; // allow enddatetime to be calculated on update
                eventInstance.DurationInMinutes = duration;
            }
            update updatedEventList;
        } catch (Exception e) {
            return; // suppress error
        }
    }

    protected override List<SObject> fetchData() {
        String userId = this.getCalendarOwnerId();
        if (this.fields.size() > 0) {
			String stmt = 'Select ' + String.join(this.fields, ',') + ' from Event where OwnerId = :userId and ' + 
                '(EndDateTime >= :startDateTime and StartDateTime < :endDateTime) and ' +
                '(IsRecurrence = null or IsRecurrence = false)';
			return Database.query(stmt);
		}
		return new List<Event>();
    }

    @TestVisible
    protected override List<VeevaCalendarEvent> convertToEvents(List<SObject> objectList) {    
        List<Event> eventList = (List<Event>) objectList;    
        List<VeevaCalendarEvent> result = new List<VeevaCalendarEvent>();

        for (Event e : eventList) {
            String whatId = e.WhatId;
            if (whatId == null || whatId == '' || !whatId.startsWith(Schema.SObjectType.Call2_vod__c?.getKeyPrefix())) {
                result.add(VeevaCalendarEventFactory.createCalendarEntry(e, this.fields));
            }
        }
        return result;
    }
}