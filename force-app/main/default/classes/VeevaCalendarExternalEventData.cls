public with sharing class VeevaCalendarExternalEventData extends VeevaCalendarData {

    public VeevaCalendarExternalEventData(Datetime startDateTime, Datetime endDateTime) {
        this(startDateTime, endDateTime, UserInfo.getUserId());
    }

    public VeevaCalendarExternalEventData(Datetime startDateTime, Datetime endDateTime, Id userId) {
        super(
            new Set<String>{'Id', 'Start_Datetime_vod__c', 'End_Datetime_vod__c', 'Title_vod__c', 'External_Calendar_vod__c', 'External_Calendar_vod__r.Title_vod__c', 'toLabel(RecordType.Name)', 'RecordType.DeveloperName', 
                'Is_All_Day_vod__c', 'Unavailable_for_Engage_Scheduling_vod__c', 'Sensitivity_vod__c'},
            userId, 
            'External_Calendar_Event_vod__c',
            startDateTime,
            endDateTime
        );
        Map<String, SObjectField> descr = External_Calendar_Event_vod__c.SObjectType.getDescribe().fields.getMap();
        this.fields = filterFields(descr, this.getQueryFields());
    }

    protected override List<SObject> fetchData() {
        String userId = this.getCalendarOwnerId();
        if (this.fields.size() > 0) {
			String stmt = 'Select ' + String.join(this.fields, ',') + ' from External_Calendar_Event_vod__c where ' +
                '(End_Datetime_vod__c >= :startDateTime and Start_Datetime_vod__c < :endDateTime) and RecordType.name = \'Microsoft_Outlook_vod\'' + 
                'and External_Calendar_vod__r.OwnerId = :userId and Start_Datetime_vod__c != null and End_Datetime_vod__c != null';
			return Database.query(stmt);
		}
		return new List<External_Calendar_Event_vod__c>();
    }

    @TestVisible
    protected override List<VeevaCalendarEvent> convertToEvents(List<SObject> objectList) {    
        List<External_Calendar_Event_vod__c> eventList = (List<External_Calendar_Event_vod__c>) objectList;    
        List<VeevaCalendarEvent> result = new List<VeevaCalendarEvent>();
        for (External_Calendar_Event_vod__c ee : eventList) {
            result.add(VeevaCalendarEventFactory.createExternalEventEvent(ee, this.fields));
        }
        return result;
    }

    public static Boolean userHasExternalEvents() {
        try {
            List<SObject> res = [SELECT Id FROM External_Calendar_Event_vod__c WHERE RecordType.name = 'Microsoft_Outlook_vod' and External_Calendar_vod__r.OwnerId = :UserInfo.getUserId()];
            return res != null ? res.size() > 0 : false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}