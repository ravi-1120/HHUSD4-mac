public without sharing class VeevaExternalCalendarEventTriggerHandler extends VeevaTriggerHandler {
    private List<External_Calendar_Event_vod__c> newExternalCalendarEvents = new List<External_Calendar_Event_vod__c>();
    private List<External_Calendar_Event_vod__c> oldExternalCalendarEvents = new List<External_Calendar_Event_vod__c>();
    private Map<ID, External_Calendar_Event_vod__c> newExternalCalendarEventsMap = new Map<ID, External_Calendar_Event_vod__c>();
    private Map<ID, External_Calendar_Event_vod__c> oldExternalCalendarEventsMap = new Map<ID, External_Calendar_Event_vod__c>();
        
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newExternalCalendarEvents = (List<External_Calendar_Event_vod__c>) triggerNew;
        this.oldExternalCalendarEvents = (List<External_Calendar_Event_vod__c>) triggerOld;
        this.newExternalCalendarEventsMap = (Map<ID, External_Calendar_Event_vod__c>) triggerNewMap;
        this.oldExternalCalendarEventsMap = (Map<ID, External_Calendar_Event_vod__c>) triggerOldMap;
    }
    
    protected override String sObjectType() {
        return 'External_Calendar_Event_vod__c';
    }

    protected override void afterInsert() {
        List<External_Calendar_Event_vod__c> unavailableExternalCalendarEvents = new List<External_Calendar_Event_vod__c>();
        for (External_Calendar_Event_vod__c externalCalendarEvent: this.newExternalCalendarEvents) {
            if (externalCalendarEvent.Unavailable_for_Engage_Scheduling_vod__c) {
                unavailableExternalCalendarEvents.add(externalCalendarEvent);
            }
        }
        if (!unavailableExternalCalendarEvents.isEmpty()) {
            createUnavailableTimes(unavailableExternalCalendarEvents);
        }
    }

    protected override void afterUpdate() {
        List<External_Calendar_Event_vod__c> unavailableExternalCalendarEvents = new List<External_Calendar_Event_vod__c>();
        List<ID> dateTimeChangeExternalCalendarEventIds = new List<ID>();
        List<ID> availableExternalCalendarEventIds = new List<ID>();
        for (External_Calendar_Event_vod__c currentExternalCalendarEvent: this.newExternalCalendarEvents) {
            External_Calendar_Event_vod__c previousExternalCalendarEvent = this.oldExternalCalendarEventsMap.get(currentExternalCalendarEvent.Id);
            if (currentExternalCalendarEvent.Unavailable_for_Engage_Scheduling_vod__c != previousExternalCalendarEvent.Unavailable_for_Engage_Scheduling_vod__c) {
                if (currentExternalCalendarEvent.Unavailable_for_Engage_Scheduling_vod__c) {
                    unavailableExternalCalendarEvents.add(currentExternalCalendarEvent);
                } else {
                    availableExternalCalendarEventIds.add(currentExternalCalendarEvent.Id);
                }
            } else if (currentExternalCalendarEvent.Unavailable_for_Engage_Scheduling_vod__c && startOrEndDateTimeChanged(currentExternalCalendarEvent, previousExternalCalendarEvent)) {
                dateTimeChangeExternalCalendarEventIds.add(currentExternalCalendarEvent.Id);
            }
        }
        if (!unavailableExternalCalendarEvents.isEmpty()) {
            createUnavailableTimes(unavailableExternalCalendarEvents);
        }

        if (!dateTimeChangeExternalCalendarEventIds.isEmpty()) {
            updateUnavailableTimesDateTime(dateTimeChangeExternalCalendarEventIds);
        }

        if (!availableExternalCalendarEventIds.isEmpty()) {
            deleteCorrespondingUnavailableTimes(availableExternalCalendarEventIds);
        }
    }

    protected override void beforeDelete() {
        List<ID> unavailableExternalCalendarEventIds = new List<ID>();
        for (External_Calendar_Event_vod__c externalCalendarEvent: this.oldExternalCalendarEvents) {
            if (externalCalendarEvent.Unavailable_for_Engage_Scheduling_vod__c) {
                unavailableExternalCalendarEventIds.add(externalCalendarEvent.Id);
            }
        }
        deleteCorrespondingUnavailableTimes(unavailableExternalCalendarEventIds);
    }

    private void deleteCorrespondingUnavailableTimes(List<ID> externalCalendEventIds) {
        List<Unavailable_Time_vod__c> toDelete = new List<Unavailable_Time_vod__c>();
        if (!externalCalendEventIds.isEmpty()) {
            toDelete.addAll([SELECT Id FROM Unavailable_Time_vod__c WHERE External_Calendar_Event_vod__c IN :externalCalendEventIds]);
            handleUnavailableTimeDelete(toDelete);
        }
    }

    private void createUnavailableTimes(List<External_Calendar_Event_vod__c> unavailableExternalCalendarEvents) {
        Map<Id, External_Calendar_vod__c> externalCalendars = getRelatedExernalCalendarMap(unavailableExternalCalendarEvents);
        List<Unavailable_Time_vod__c> toCreate = new List<Unavailable_Time_vod__c>();
        for (External_Calendar_Event_vod__c externalCalendarEvent: unavailableExternalCalendarEvents) {
            DateTime startDateTime;
            Datetime endDateTime;
            if (externalCalendarEvent.Is_All_Day_vod__c) {
                startDateTime = adjustGmtToLocalDateTime(externalCalendarEvent.Start_Datetime_vod__c);
                endDateTime = adjustGmtToLocalDateTime(externalCalendarEvent.End_DateTime_vod__c);
            } else {
                startDateTime = externalCalendarEvent.Start_DateTime_vod__c;
                endDateTime = externalCalendarEvent.End_DateTime_vod__c;
            }
            Unavailable_Time_vod__c unavailableTime = new Unavailable_Time_vod__c(
                External_Calendar_Event_vod__c = externalCalendarEvent.Id,
                Start_DateTime_vod__c = startDateTime,
                End_DateTime_vod__c = endDateTime,
                OwnerId = externalCalendars.get(externalCalendarEvent.External_Calendar_vod__c).OwnerId
            );
            toCreate.add(unavailableTime);
        }
        handleUnavailableTimeUpsert(toCreate);
    }

    private void updateUnavailableTimesDateTime(List<ID> dateTimeChangeExternalCalendarEventIds) {
        List<Unavailable_Time_vod__c> toUpdate = new List<Unavailable_Time_vod__c>();
        List<Unavailable_Time_vod__c> unavailableTimes = [
            SELECT Id, External_Calendar_Event_vod__c
            FROM Unavailable_Time_vod__c 
            WHERE External_Calendar_Event_vod__c IN :dateTimeChangeExternalCalendarEventIds];
        for (Unavailable_Time_vod__c unavailableTime: unavailableTimes) {
            External_Calendar_Event_vod__c currentExternalCalendarEvent = this.newExternalCalendarEventsMap.get(unavailableTime.External_Calendar_Event_vod__c);
            External_Calendar_Event_vod__c previousExternalCalendarEvent = this.oldExternalCalendarEventsMap.get(unavailableTime.External_Calendar_Event_vod__c);
            Unavailable_Time_vod__c updatedUnavailableTime = new Unavailable_Time_vod__c(Id = unavailableTime.Id);

            if (currentExternalCalendarEvent.Start_DateTime_vod__c != previousExternalCalendarEvent.Start_DateTime_vod__c) {
                if (currentExternalCalendarEvent.Is_All_Day_vod__c) {
                    updatedUnavailableTime.Start_DateTime_vod__c = adjustGmtToLocalDateTime(currentExternalCalendarEvent.Start_DateTime_vod__c);
                } else {
                    updatedUnavailableTime.Start_DateTime_vod__c = currentExternalCalendarEvent.Start_DateTime_vod__c;
                }
            }

            if (currentExternalCalendarEvent.End_DateTime_vod__c != previousExternalCalendarEvent.End_DateTime_vod__c) {
                if (currentExternalCalendarEvent.Is_All_Day_vod__c) {
                    updatedUnavailableTime.End_DateTime_vod__c = adjustGmtToLocalDateTime(currentExternalCalendarEvent.End_DateTime_vod__c);
                } else {
                    updatedUnavailableTime.End_DateTime_vod__c = currentExternalCalendarEvent.End_DateTime_vod__c;
                }
            }
            
            toUpdate.add(updatedUnavailableTime);
        }
        handleUnavailableTimeUpsert(toUpdate);
    }

    private Map<Id, External_Calendar_vod__c> getRelatedExernalCalendarMap(List<External_Calendar_Event_vod__c> externalCalendarEvents) {
        List<Id> externalCalendarIds = new List<Id>();
        for (External_Calendar_Event_vod__c externalCalendarEvent: externalCalendarEvents) {
            externalCalendarIds.add(externalCalendarEvent.External_Calendar_vod__c);
        }
        return new Map<Id, External_Calendar_vod__c>(
            [SELECT Id, OwnerId FROM External_Calendar_vod__c WHERE Id in :externalCalendarIds]);
    }

    private void handleUnavailableTimeUpsert(List<Unavailable_Time_vod__c> toUpsert) {
        if (!toUpsert.isEmpty()) {
            Database.UpsertResult[] upsertResults = Database.upsert(toUpsert, false);
            for (Integer i = 0; i < upsertResults.size(); i++) {
                Database.UpsertResult result = upsertResults.get(i);
                if (!result.isSuccess()){
                    Id targetRecordId = toUpsert.get(i).External_Calendar_Event_vod__c;
                    Database.Error[] errors = result.getErrors();
                    
                    String msg = '';
                    for (Database.Error e : errors) {
                        msg += e.getStatusCode() + ': ' + e.getMessage() + ' ';                 
                    }
                    this.newExternalCalendarEventsMap.get(targetRecordId).addError(msg);
                }
            }
        }
    }

    private void handleUnavailableTimeDelete(List<Unavailable_Time_vod__c> toDelete) {
        if (!toDelete.isEmpty()) {
            Database.DeleteResult[] deletionResults = Database.delete(toDelete, false);
            for (Integer i = 0; i < deletionResults.size(); i++) {
                Database.DeleteResult result = deletionResults.get(i);
                if (!result.isSuccess()){
                    Id targetTotRecord = toDelete.get(i).External_Calendar_Event_vod__c;
                    Database.Error[] errors = result.getErrors();
                    
                    String msg = '';
                    for (Database.Error e : errors) {
                        msg += e.getStatusCode() + ': ' + e.getMessage() + ' ';                 
                    }
                    this.oldExternalCalendarEventsMap.get(targetTotRecord).addError(msg);
                }
            }
        }
    }

    private Boolean startOrEndDateTimeChanged(External_Calendar_Event_vod__c current, External_Calendar_Event_vod__c previous) {
        return current.Start_DateTime_vod__c != previous.Start_DateTime_vod__c || current.End_DateTime_vod__c != previous.End_DateTime_vod__c;
    }

    private Datetime adjustGmtToLocalDateTime(Datetime gmtDatetime) {
        Date gmtDate = gmtDatetime.dateGmt();
        Time gmtTime = gmtDatetime.timeGmt();
        return Datetime.newInstance(gmtDate, gmtTime);
    }
}