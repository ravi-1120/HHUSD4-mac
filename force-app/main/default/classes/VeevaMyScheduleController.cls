public with sharing class VeevaMyScheduleController {
    private final static List<String> MY_SCHEDULE_SETTINGS = new List<String>{'ALLOWED_CALL_RECORD_TYPES_vod__c', 'Enable_Group_Call_Attendee_Display_vod__c', 'Call_ScheduleConflict_Threshold_vod__c', 'DISABLE_TOT_WEEKENDS_vod__c', 'ENABLE_ACCOUNT_PARENT_DISPLAY_vod__c', 'ENABLE_SCHEDULE_MEDICAL_EVENT_vod__c', 'Enable_Child_Account_vod__c', 'Enable_CRM_Desktop_vod__c', 'CALL_BACKDATE_LIMIT_vod__c', 'PREVENT_TOT_WEEKEND_vod__c', 'Enable_Samples_On_Save_vod__c', 'DISPLAY_EXTERNAL_CALENDARS_TO_MGRS_vod__c', 'ENABLE_CYCLE_PLANS_REMAINING_vod__c', 'ENABLE_ADV_CYCPLN_SCHEDULING_vod__c'};
    private final static List<String> MY_SCHEDULE_COMMON_SETTINGS = new List<String>{'Engage_Url_Prefix_vod__c', 'Microsoft_Authorization_Server_URL_vod__c'};

    @AuraEnabled
    public static List<VeevaCalendarEvent> getCallDataInRange(String currentStart, String currentEnd, List<Integer> weekendDays, Id userId) {
        return getCallDataInRange(currentStart, currentEnd, weekendDays, new VeevaLayoutService(), userId);
    }

    public static List<VeevaCalendarEvent> getCallDataInRange(String currentStart, String currentEnd, List<Integer> weekendDays, VeevaLayoutService layoutService, Id userId) {
        return new VeevaCalendarCallData(Date.valueOf(currentStart), Date.valueOf(currentEnd), layoutService, userId).getEvents();
    }

    @AuraEnabled
    public static List<VeevaCalendarEvent> getTimeOffTerritoryDataInRange(String currentStart, String currentEnd, List<Integer> weekendDays, Id userId) {
        VeevaCalendarTimeOffTerritoryData totData = new VeevaCalendarTimeOffTerritoryData(Date.valueOf(currentStart), Date.valueOf(currentEnd), userId);
        if (weekendDays != null && !weekendDays.isEmpty()) {
            totData.setWeekends(weekendDays[0], weekendDays[1]);
        }
        return totData.getEvents();
    }

    @AuraEnabled
    public static List<VeevaCalendarEvent> getUnavailableTimeDataInRange(String currentStart, String currentEnd, List<Integer> weekendDays, Id userId) {
        return new VeevaCalendarUnavailableTimeData(Datetime.valueOf(currentStart), Datetime.valueOf(currentEnd), userId).getEvents();
    }
    
    @AuraEnabled
    public static List<VeevaCalendarEvent> getMedicalEventDataInRange(String currentStart, String currentEnd, List<Integer> weekendDays, Id userId){
        return new VeevaCalendarMedicalEventData(Datetime.valueOf(currentStart), Datetime.valueOf(currentEnd), userId).getEvents();
    }

    @AuraEnabled
    public static List<VeevaCalendarEvent> getCalendarEntryDataInRange(String currentStart, String currentEnd, List<Integer> weekendDays, Id userId){
        return new VeevaCalendarEntryEventData(Datetime.valueOf(currentStart), Datetime.valueOf(currentEnd), userId).getEvents();
    }

    @AuraEnabled
    public static List<VeevaCalendarEvent> getUnassignedPresentationDataInRange(String currentStart, String currentEnd, List<Integer> weekendDays, Id userId) {
        return new VeevaCalendarUnassignedPresentationData(Date.valueOf(currentStart), Date.valueOf(currentEnd), userId).getEvents();
    }

    @AuraEnabled
    public static List<VeevaCalendarEvent> getMeetingRequestDataInRange(String currentStart, String currentEnd, List<Integer> weekendDays, Id userId){
        return new VeevaCalendarMeetingRequestData(Date.valueOf(currentStart), Date.valueOf(currentEnd), userId).getEvents();
    }

    @AuraEnabled
    public static Boolean userHasExternalEvents(){
        return VeevaCalendarExternalEventData.userHasExternalEvents();
    }

    @AuraEnabled
    public static List<VeevaCalendarEvent> getExternalEventDataInRange(String currentStart, String currentEnd, List<Integer> weekendDays, Id userId){
        return new VeevaCalendarExternalEventData(Datetime.valueOf(currentStart), Datetime.valueOf(currentEnd), userId).getEvents();
    }

    @AuraEnabled
    public static Map<String, Map<String, Date>> getRelatedAccountDataInRange(String currentStart, String currentEnd, List<String> accountIds, List<String> callIds){
        return getRelatedAccountDataInRange(currentStart, currentEnd, accountIds, callIds, new VeevaLayoutService());
    }

    public static Map<String, Map<String, Date>> getRelatedAccountDataInRange(String currentStart, String currentEnd, List<String> accountIds, List<String> callIds, VeevaLayoutService layoutService){
        return new VeevaCalendarCallData(Date.valueOf(currentStart), Date.valueOf(currentEnd), layoutService).getRelatedAccountEvents(accountIds, callIds);
    }

    @AuraEnabled
    public static Map<String, String> discardUnassignedPresentation(Id recordId) {
        return VeevaCalendarUnassignedPresentationData.discardEvent(recordId);
    }

    @AuraEnabled
    public static List<VeevaCalendarEvent> getCalendarEvents(List<Id> recordIds, String objectType, List<Integer> weekendDays) {
        Date startDate = Date.today();
        Date endDate = Date.today();
        VeevaCalendarData cd;
        switch on objectType {
            when 'Call2_vod__c' {
                cd = new VeevaCalendarCallData(startDate, endDate, new VeevaLayoutService());
            } when 'Medical_Event_vod__c' {
                cd = new VeevaCalendarMedicalEventData(startDate, endDate);
            } when 'Event' {
                cd = new VeevaCalendarEntryEventData(startDate, endDate);
            } when 'Meeting_Request_vod__c' {
                cd = new VeevaCalendarMeetingRequestData(startDate, endDate);
            } when 'Multichannel_Activity_vod__c' {
                cd = new VeevaCalendarUnassignedPresentationData(startDate, endDate);
            } when 'Unavailable_Time_vod__c' {
                cd = new VeevaCalendarUnavailableTimeData(startDate, endDate);
            } when 'Time_Off_Territory_vod__c' {
                VeevaCalendarTimeOffTerritoryData totData = new VeevaCalendarTimeOffTerritoryData(startDate, endDate);
                if (weekendDays != null && !weekendDays.isEmpty()) {
                    totData.setWeekends(weekendDays[0], weekendDays[1]);
                }
                return totData.getEventsForRecordIds(recordIds);
            } when 'External_Calendar_Event_vod__c'{
                cd = new VeevaCalendarExternalEventData(startDate, endDate);
            } when else {
                return null;
            }
        }
        return cd.getEventsForRecordIds(recordIds);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getVeevaSettings() {
        return VeevaCustomSettingsService.getVeevaSettings(MY_SCHEDULE_SETTINGS);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getVeevaCommonSettings() {
        return VeevaCustomSettingsService.getCustomSettings('Veeva_Common_vod__c', MY_SCHEDULE_COMMON_SETTINGS);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, String>> getObjectIcons(List<String> desiredObjects) {
        return VeevaCalendarObjectThemeInfoHelper.getObjectIcons(desiredObjects);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getEventObjectThemeInfo() {
        return VeevaCalendarObjectThemeInfoHelper.getEventObjectThemeInfo();
    }

    @AuraEnabled
    public static List<External_Calendar_vod__c> getExternalCalendarInfos() {
        Id userId = UserInfo.getUserId();
        return [SELECT Id, Title_vod__c, Is_Default_Calendar_vod__c, Hex_Color_vod__c, RecordType.name FROM External_Calendar_vod__c WHERE RecordType.name = 'Microsoft_Outlook_vod' and OwnerId = :userId];
    }

    @AuraEnabled
    public static Map<String, String> updateCallTime(Id recordId, Datetime startDate, Integer duration, Boolean allDay, Boolean hasDateTimePermission, Boolean updateRemoteMeeting) {
        return VeevaCalendarUpdateCallService.updateCallTime(recordId, startDate, duration, allDay, hasDateTimePermission, updateRemoteMeeting);
    }

    @AuraEnabled
    public static boolean remoteMeetingInviteAEEnabled() {
        return VeevaCalendarApprovedEmailHelper.remoteMeetingInviteAEEnabled();
    }

    @AuraEnabled
    public static Id getSchedulerUserPreferences() {
        return VeevaCalendarSchedulerPaneService.getSchedulerUserPreferences();
    }

    @AuraEnabled
    public static void setLastSchedulerAccountList(Id accountListId){
        VeevaCalendarSchedulerPaneService.setLastSchedulerAccountList(accountListId);
    }
    
    @AuraEnabled
    public static Map<String, String> updateCalendarEntryTime(Id recordId, Datetime startDate, Datetime endDate) {
        Map<String, String> result = new Map<String, String>();
        Datetime currentDate = Datetime.now();
        Event updatedEvent = [SELECT Id, Subject, StartDateTime, EndDateTime, IsAllDayEvent, DurationInMinutes, IsRecurrence2, Recurrence2PatternStartDate FROM Event WHERE Id = :recordId];
        
        Integer duration = Integer.valueOf((endDate.getTime() - startDate.getTime()) / (1000 * 60));
        Datetime originalStart = updatedEvent.StartDateTime;
        Long startTimeChange = startDate.getTime() - originalStart.getTime();

        if (updatedEvent.IsRecurrence2 && !startDate.dateGMT().isSameDay(originalStart.dateGMT())) {
            result.put('error', VeevaMessageController.getMsgWithDefault('CALENDAR_ENTRY_SERIES_UPDATE_ERROR', 'Scheduler', 'To edit the start date of your series, delete this series and recreate it with a new start date.'));
            return result; // prevent rescheduling recurring event to another day
        }

        String err = VeevaCalendarEntryEventData.updateSingleEvent(updatedEvent, startTimeChange, duration);
        result.put('error', err);

        if (updatedEvent.IsRecurrence2 && originalStart > currentDate && result.get('error') == null) {
            VeevaCalendarEntryEventData.updateEventSeries(updatedEvent, startTimeChange, duration);
        } 
        String updatedEventDateTime = updatedEvent.IsAllDayEvent ? VeevaCalendarEvent.formatAllDay(Date.valueOf(startDate), duration - 1) : VeevaCalendarEvent.formatHourly(startDate, duration);
        result.put('data', updatedEventDateTime);

        return result;
    }

    @AuraEnabled
    public static Map<String, Map<String, Map<String, Object>>> getCallCycleInfo() {
        return VeevaCalendarCallCycleDataService.getCallCycleEntryInfo();
    }

    @AuraEnabled
    public static Boolean isDateOutsideOfCallObjectiveRange(Id callId, String newDate) {
        List<Call_Objective_vod__c> callObjectives = VeevaCalendarCallData.getCallObjectivesOutOfRange(callId, Date.valueOf(newDate));
        return !callObjectives.isEmpty();
    }

    @AuraEnabled
    public static String getIdentifierString() {
        return VeevaMedicalIdentifierHandler.getIdentifierString();
    }

    @AuraEnabled
    public static Map<Id, Map<String, String>> getSubordinatesInfo() {
        return VeevaCalendarManagerViewService.getSubordinatesInfo();
    }

    @AuraEnabled
    public static List<VeevaMyAccountsTerritory> getUserTerritories() {
        return new VeevaMyScheduleAccountsService().getUserTerritories();
    }

    @AuraEnabled
    public static List<VeevaMyAccountsViewItem> getViews(){
        return new VeevaMyScheduleAccountsService().getViews();
    }

    @AuraEnabled
    public static VeevaMyAccountsBaseView getViewDefinition(Id viewId) {
        return new VeevaMyScheduleAccountsService().getViewDefinition(viewId);
    }

    @AuraEnabled
    public static List<Cycle_Plan_vod__c> getCyclePlans(){
        return new VeevaMyScheduleAccountsService().getCyclePlans();
    }

    @AuraEnabled
    public static List<Cycle_Plan_Target_vod__c> getCyclePlanTargets(Id cyclePlanId){
        return new VeevaMyScheduleAccountsService().getCyclePlanTargets(cyclePlanId);
    }
}