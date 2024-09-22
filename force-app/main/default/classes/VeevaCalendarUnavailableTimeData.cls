public with sharing class VeevaCalendarUnavailableTimeData extends VeevaCalendarData {

    public VeevaCalendarUnavailableTimeData(Datetime startDateTime, Datetime endDateTime) {
        this(startDateTime, endDateTime, UserInfo.getUserId());
    }

    public VeevaCalendarUnavailableTimeData(Datetime startDateTime, Datetime endDateTime, Id userId) {
        super(
            new Set<String>{'OwnerId', 'CreatedById', 'Start_Datetime_vod__c', 'End_Datetime_vod__c', 'toLabel(RecordType.Name)', 'Time_Off_Territory_vod__c', 'External_Calendar_Event_vod__c', 'Call2_vod__c'},
                userId, 
                'Unavailable_Time_vod__c',
                startDateTime,
                endDateTime
        );
        Map<String, SObjectField> descr = Unavailable_Time_vod__c.SObjectType.getDescribe().fields.getMap();
        this.fields = filterFields(descr, this.getQueryFields());

    }

    protected override List<SObject> fetchData() {

        if (this.fields.size() == 0 || !this.isFieldAccessible('Start_Datetime_vod__c') || !this.isFieldAccessible('End_Datetime_vod__c')) {
            return new List<Unavailable_Time_vod__c>();
        }

        String userId = this.getCalendarOwnerId();
        String totCondition = this.fields.contains('Time_Off_Territory_vod__c') ? 'Time_Off_Territory_vod__c = null and ' : '';
        String externalCalendarEventCondition = this.fields.contains('External_Calendar_Event_vod__c') ? 'External_Calendar_Event_vod__c = null and ' : '';
        String callCondition = this.fields.contains('Call2_vod__c') ? 'Call2_vod__c = null and ' : '';

        String stmt = 'Select ' + String.join(this.fields, ',') + ' from Unavailable_Time_vod__c ' + 'where OwnerId = :userId and ' + totCondition + externalCalendarEventCondition + callCondition +
                '((Start_Datetime_vod__c >= :startDateTime and Start_Datetime_vod__c < :endDateTime) or (End_Datetime_vod__c >= :startDateTime and Start_Datetime_vod__c < :endDateTime))';
        return Database.query(stmt);
    }    

    protected override List<VeevaCalendarEvent> convertToEvents(List<SObject> objectList) {
        List<Unavailable_Time_vod__c> utList = (List<Unavailable_Time_vod__c>) objectList;    
        List<VeevaCalendarEvent> result = new List<VeevaCalendarEvent>();

        for (Unavailable_Time_vod__c ut : utList) {
            result.add(VeevaCalendarEventFactory.createUnavailableTimeEvent(ut));
        }

        return result;
    }
}