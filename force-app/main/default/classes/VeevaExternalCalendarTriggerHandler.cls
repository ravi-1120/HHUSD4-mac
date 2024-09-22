public without sharing class VeevaExternalCalendarTriggerHandler extends VeevaTriggerHandler {
    private List<External_Calendar_vod__c> newExternalCalendars = new List<External_Calendar_vod__c>();
    private List<External_Calendar_vod__c> oldExternalCalendars = new List<External_Calendar_vod__c>();
    private Map<ID, External_Calendar_vod__c> newExternalCalendarsMap = new Map<ID, External_Calendar_vod__c>();
    private Map<ID, External_Calendar_vod__c> oldExternalCalendarsMap = new Map<ID, External_Calendar_vod__c>();

    @TestVisible
    private static Integer UNAVAILABLE_TIMES_CLEANUP_LIMIT = 49900;
    @TestVisible
    private static List<Id> unavailableTimesToBeDeleted = new List<Id>(); // static so that the state persists from before → after
        
    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newExternalCalendars = (List<External_Calendar_vod__c>) triggerNew;
        this.oldExternalCalendars = (List<External_Calendar_vod__c>) triggerOld;
        this.newExternalCalendarsMap = (Map<ID, External_Calendar_vod__c>) triggerNewMap;
        this.oldExternalCalendarsMap = (Map<ID, External_Calendar_vod__c>) triggerOldMap;
    }
    
    protected override String sObjectType() {
        return 'External_Calendar_vod__c';
    }

    protected override void afterUpdate() {
        List<ID> externalCalendarIds = new List<ID>();
        for (External_Calendar_vod__c currentExternalCalendar : this.newExternalCalendars) {
            External_Calendar_vod__c previousExternalCalendar = this.oldExternalCalendarsMap.get(currentExternalCalendar.Id);
            if (currentExternalCalendar.OwnerId != previousExternalCalendar.OwnerId) {
                externalCalendarIds.add(currentExternalCalendar.Id);
            } 
        }
        if (!externalCalendarIds.isEmpty()) {
            updateCorrespondingUnavailableTimes(externalCalendarIds);
        }
    }

    // while the trigger on External_Calendar_Event_vod__c does delete the required Unavailable_Time_vod__c,
    // when the master of a master detail relationship is deleted, the child's triggers do not fire
    // because of that we need to handle the Unavailable_Time_vod__c clean up here as well
    // also note that by the time the afterDelete() fires the Unavailable_Time_vod__c records no longer point to the External_Calendar_Event_vod__c
    protected override void beforeDelete() {
        List<External_Calendar_vod__c> filteredExternalCalendars = filterForMicrosoftExternalCalendars(oldExternalCalendars);
        Integer unavailableTimesDeleteCount = findNumberOfUnavaibleTimesThatNeedToBeDeleted(filteredExternalCalendars);

        if (unavailableTimesDeleteCount > UNAVAILABLE_TIMES_CLEANUP_LIMIT) {
            if (filteredExternalCalendars.size() == 1) {
                filteredExternalCalendars.get(0).addError('Unable to delete an External_Calendar_vod__c with > ~50k related Unavailable_Time_vod__c, found ' + unavailableTimesDeleteCount);
            } else {
                for (External_Calendar_vod__c filteredExternalCalendar : filteredExternalCalendars) {
                    filteredExternalCalendar.addError('Please reduce batch size of External_Calendar_vod__c deletion');
                }
            }

            return;
        }

        List<Id> filteredExternalCalendarIds = getExternalCalendarIds(filteredExternalCalendars);
        // store for processing in the afterDelete step
        Set<Id> correspondingUnavailableTimeIds = getCorrespondingUnavailableTimeIds(filteredExternalCalendarIds);
        addAllUnavailableTimesToBeDeleted(correspondingUnavailableTimeIds);
    }

    protected override void afterDelete() {
        List<Id> unavailableTimesToNowDelete = getAndClearUnavailableTimesToBeDeleted();
        if (unavailableTimesToNowDelete != null && !unavailableTimesToNowDelete.isEmpty()) {
            VeevaExternalCalendarUTDeleteBatch unavailableTimeBatch = new VeevaExternalCalendarUTDeleteBatch(unavailableTimesToNowDelete);
            // Database.executeBatch could throw either a System.AsyncException or System.LimitException
            // in this case we just let the exception propagate, we want the entire trigger transaction to roll back 
            // as the user should just try again when less jobs are in the apex flex queue
            Database.executeBatch(unavailableTimeBatch);
        }
    }

    private List<External_Calendar_vod__c> filterForMicrosoftExternalCalendars(List<External_Calendar_vod__c> externalCalendars) {
        // the object that comes through the trigger has RecordTypeId but not other record type information
        VeevaBaseObject externalCalendarBaseObject = VeevaBaseObject.create('External_Calendar_vod__c');
        Map<Id, Schema.RecordTypeInfo> externalCalendarRecordTypeInfos = externalCalendarBaseObject.getDescribe().getRecordTypeInfosById();

        List<External_Calendar_vod__c> filteredExternalCalendars = new List<External_Calendar_vod__c>();
        for (External_Calendar_vod__c externalCalendar : externalCalendars) {
            Schema.RecordTypeInfo relevantRecordType = externalCalendarRecordTypeInfos.get(externalCalendar.RecordTypeId);
            if (relevantRecordType != null && relevantRecordType.getDeveloperName() == 'Microsoft_Outlook_vod') {
                filteredExternalCalendars.add(externalCalendar);
            }
        }
        return filteredExternalCalendars;
    }

    private Integer findNumberOfUnavaibleTimesThatNeedToBeDeleted(List<External_Calendar_vod__c> externalCalendars) {
        return [SELECT COUNT() FROM Unavailable_Time_vod__c WHERE External_Calendar_Event_vod__r.Unavailable_for_Engage_Scheduling_vod__c = TRUE AND External_Calendar_Event_vod__r.External_Calendar_vod__c IN: externalCalendars];
    }

    private List<Id> getExternalCalendarIds(List<External_Calendar_vod__c> externalCalendars) {
        List<Id> externalCalendarIds = new List<Id>();
        for (External_Calendar_vod__c externalCalendar : externalCalendars) {
            externalCalendarIds.add(externalCalendar.Id);
        }
        return externalCalendarIds;
    }

    private static List<Id> getAndClearUnavailableTimesToBeDeleted() {
        // create a copy of the static list, and then clear, we don't want to double process anything
        List<Id> takenForDeleteProcessing = new List<Id>();
        takenForDeleteProcessing.addAll(unavailableTimesToBeDeleted);
        unavailableTimesToBeDeleted.clear();
        return takenForDeleteProcessing;
    }

    private static void addAllUnavailableTimesToBeDeleted(Set<Id> unavailableTimesForDeleteProcessing) {
        unavailableTimesToBeDeleted.addAll(unavailableTimesForDeleteProcessing);
    }

    private Set<Id> getCorrespondingUnavailableTimeIds(List<ID> externalCalendarIds) {
        return new Map<Id, Unavailable_Time_vod__c>([
            SELECT 
                Id
            FROM 
                Unavailable_Time_vod__c
            WHERE 
                External_Calendar_Event_vod__r.Unavailable_for_Engage_Scheduling_vod__c = TRUE AND 
                External_Calendar_Event_vod__r.External_Calendar_vod__c IN :externalCalendarIds
        ]).keySet();
    }
    
    private List<Unavailable_Time_vod__c> getCorrespondingUnavailableTimes(List<ID> externalCalendarIds) {
        return [SELECT Id, External_Calendar_Event_vod__r.External_Calendar_vod__c
        FROM Unavailable_Time_vod__c
        WHERE External_Calendar_Event_vod__r.Unavailable_for_Engage_Scheduling_vod__c = TRUE AND External_Calendar_Event_vod__r.External_Calendar_vod__c IN: externalCalendarIds];
    }

    private void updateCorrespondingUnavailableTimes(List<ID> externalCalendarIds) {
        List<Unavailable_Time_vod__c> toUpdate = new List<Unavailable_Time_vod__c>();
        for (Unavailable_Time_vod__c unavailableTime: getCorrespondingUnavailableTimes(externalCalendarIds)) {
            ID ownerId = this.newExternalCalendarsMap.get(unavailableTime.External_Calendar_Event_vod__r.External_Calendar_vod__c).OwnerId;
            toUpdate.add(new Unavailable_Time_vod__c(
                Id = unavailableTime.Id,
                OwnerId = ownerId
            ));
        }
        handleUnavailableTimeUpsert(toUpdate);
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
                    this.newExternalCalendarsMap.get(targetRecordId).addError(msg);
                }
            }
        }
    }
}