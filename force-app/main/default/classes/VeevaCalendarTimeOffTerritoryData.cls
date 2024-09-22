public with sharing class VeevaCalendarTimeOffTerritoryData extends VeevaCalendarData {
    public static final Integer TOT_MAX_DURATION_NOT_INCLUDING_START_DATE = 4;
    private Integer weekendStart;
    private Integer weekendEnd;

    public VeevaCalendarTimeOffTerritoryData(Datetime startDateTime, Datetime endDateTime) {
        this(startDateTime, endDateTime, UserInfo.getUserId());
    }

    public VeevaCalendarTimeOffTerritoryData(Datetime startDateTime, Datetime endDateTime, Id userId) {
        super(
            new Set<String> {'Date_vod__c', 'Hours_vod__c', 'Hours_off_vod__c', 'OwnerId', 'CreatedById', 'Time_vod__c', 'Start_Time_vod__c', 'Status_vod__c', 'toLabel(Status_vod__c) statusLabel', 'Id', 'Name', 'toLabel(Reason_vod__c)', 'Territory_vod__c', 'Unavailable_for_Engage_Scheduling_vod__c'}, 
            userId, 
            'Time_Off_Territory_vod__c',
            startDateTime,
            endDateTime
        );
        this.adjustStartDate(getStartDateAdjustment());
        Map<String, SObjectField> descr = Time_Off_Territory_vod__c.SObjectType.getDescribe().fields.getMap();
        this.fields = filterFields(descr, this.getQueryFields());
    }
    
    public void setWeekends(Integer weekendStart, Integer weekendEnd) {
        this.weekendStart = weekendStart;
        this.weekendEnd = weekendEnd;
    }

    private static Boolean adjustTotEndDate() {
        Object weekendSetting = VeevaCustomSettingsService.getVeevaSettings(new List<String>{'DISABLE_TOT_WEEKENDS_vod__c'}).get('DISABLE_TOT_WEEKENDS_vod__c');
        return weekendSetting != null ? !Boolean.valueOf(weekendSetting) : false;
    }

    private static Integer getStartDateAdjustment() {
        Integer adjustment = -TOT_MAX_DURATION_NOT_INCLUDING_START_DATE;
        if (adjustTotEndDate()) {
            adjustment -= 2;
        }
        return adjustment;
    }

    protected override List<SObject> fetchData() {
        String userId = this.getCalendarOwnerId();
        if (this.fields.size() > 0) {
			String stmt = 'Select ' + String.join(this.fields, ',') + ' from Time_Off_Territory_vod__c ' + 'where OwnerId = :userId and ' + 
                '(Date_vod__c >= :startDate and Date_vod__c < :endDate)';
			return Database.query(stmt);
		}
		return new List<Time_Off_Territory_vod__c>();
    }

    @TestVisible
    protected override List<VeevaCalendarEvent> convertToEvents(List<SObject> objectList) {    
        List<Time_Off_Territory_vod__c> totList = (List<Time_Off_Territory_vod__c>) objectList;    
        List<VeevaCalendarEvent> result = new List<VeevaCalendarEvent>();

        for (Time_Off_Territory_vod__c tot : totList) {
            result.add(VeevaCalendarEventFactory.createTimeOffTerritoryEvent(tot, this.weekendStart, this.weekendEnd, this.fields));
        }
        return result;
    }
}