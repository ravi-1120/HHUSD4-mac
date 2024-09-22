public with sharing class VeevaCalendarMeetingRequestData extends VeevaCalendarData {

    public VeevaCalendarMeetingRequestData(Datetime startDateTime, Datetime endDateTime) {
        this(startDateTime, endDateTime, UserInfo.getUserId());
    }

    public VeevaCalendarMeetingRequestData(Datetime startDateTime, Datetime endDateTime, Id userId) {
        super(
            new Set<String>{'Invitee_Display_Name_vod__c','Assignee_vod__c','Meeting_Type_vod__c','toLabel(Meeting_Type_vod__c) meetingTypeLabel','Start_DateTime_vod__c','Status_vod__c','toLabel(Status_vod__c) statusLabel','Account_vod__c', 'Account_vod__r.Do_Not_Call_vod__c','Account_vod__r.RecordType.Name','Duration_vod__c', 'Phone_vod__c', 'toLabel(RecordType.Name)', 'Is_Hidden_vod__c'},
            userId,
            'Meeting_Request_vod__c',
            startDateTime,
            endDateTime
        );
        Map<String, SObjectField> descr = Meeting_Request_vod__c.SObjectType.getDescribe().fields.getMap();
        this.fields = filterFields(descr, this.getQueryFields());
    }

    protected override List<SObject> fetchData() {
        String userId = this.getCalendarOwnerId();
        if (this.fields.size() > 0 && isFieldAccessible('Start_DateTime_vod__c') && isFieldAccessible('Invitee_Display_Name_vod__c') && isFieldAccessible('Assignee_vod__c') && isFieldAccessible('Status_vod__c')) {
			String stmt = 'Select ' + String.join(this.fields, ',') + ' from Meeting_Request_vod__c where ' +
                '(Start_DateTime_vod__c >= :startDateTime and Start_DateTime_vod__c < :endDateTime) and Invitee_Display_Name_vod__c != null and Assignee_vod__c = :userId and ' +
                'Start_DateTime_vod__c != null and Status_vod__c in (\'Requested_vod\', \'Declined_vod\') and Is_Hidden_vod__c = false';
			return Database.query(stmt);
		}
		return new List<Meeting_Request_vod__c>();
    }

    @TestVisible
    protected override List<VeevaCalendarEvent> convertToEvents(List<SObject> objectList) {    
        List<Meeting_Request_vod__c> mrList = (List<Meeting_Request_vod__c>) objectList;    
        List<VeevaCalendarEvent> result = new List<VeevaCalendarEvent>();

        for (Meeting_Request_vod__c mr : mrList) {
            result.add(VeevaCalendarEventFactory.createMeetingRequestEvent(mr, this.fields));
        }
        return result;
    }
}