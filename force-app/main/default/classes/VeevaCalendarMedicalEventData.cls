public with sharing class VeevaCalendarMedicalEventData extends VeevaCalendarData {
    private Set<String> emEventDesiredFields = new Set<String>();
    private Map<String, SObjectField> eventAttendeeDescr = new Map<String, SObjectField>();
    List<String> emEventAttendeefields = new List<String>();

    public VeevaCalendarMedicalEventData(Datetime startDateTime, Datetime endDateTime) {
        this(startDateTime, endDateTime, UserInfo.getUserId());
    }

    public VeevaCalendarMedicalEventData(Datetime startDateTime, Datetime endDateTime, Id userId) {
        super(
            new Set<String>{'Active_vod__c', 'Location__c', 'End_Date_vod__c', 'End_Time_vod__c', 'Name', 'toLabel(Event_Type__c)', 'Start_Date_vod__c', 'Start_Time_vod__c', 'OwnerId', 'Owner.Name', 'Status_vod__c', 'EM_Event_vod__c', 'toLabel(EM_Event_vod__r.Status_vod__c)', 'toLabel(EM_Event_vod__r.Program_Type_vod__c)', 'toLabel(RecordType.Name)'},
            userId, 
            'Medical_Event_vod__c',
            startDateTime,
            endDateTime
        );
        Map<String, SObjectField> descr = Medical_Event_vod__c.SObjectType.getDescribe().fields.getMap();
        this.fields = filterFields(descr, this.getQueryFields());
        this.filterEMFields();

        this.emEventDesiredFields = new Set<String>{'EM_Event_Team_Member_vod__c', 'Role_vod__c', 'Group_Name_vod__c'};
        this.eventAttendeeDescr = Event_Attendee_vod__c.SObjectType.getDescribe().fields.getMap();
        this.emEventAttendeefields = filterFields(eventAttendeeDescr, emEventDesiredFields);
    }

    private void filterEMFields() {
        Set<String> emFields = new Set<String>();
        for (String fieldName : this.fields) {
            if (fieldName.contains('EM_Event_vod__r')) {
                emFields.add(fieldName.removeStartIgnoreCase('toLabel(').removeStartIgnoreCase('EM_Event_vod__r.').substringBefore(')'));
            }
        }
        if (!emFields.isEmpty()) {
            List<String> accessibleFields = filterFields(EM_Event_vod__c.SObjectType.getDescribe().fields.getMap(), emFields);
            for (String fieldName : emFields) {
                if (!accessibleFields.contains(fieldName)) {
                    Integer index = this.fields.indexOf('EM_Event_vod__r.' + fieldName);
                    if (index < 0) {
                        index = this.fields.indexOf('toLabel(EM_Event_vod__r.' + fieldName + ')');
                    }
                    if (index >= 0) {
                        this.fields.remove(index);
                    }
                }
            }
        }
    }

    private String getCallRangeStatementString() {
        if (this.isFieldAccessible('Start_Time_vod__c') && this.isFieldAccessible('End_Time_vod__c')) {
            return '((Start_Date_vod__c >= :startDate and Start_Date_vod__c < :endDate) or (Start_Time_vod__c >= :startDateTime and Start_Time_vod__c < :endDateTime) ' + 
            'or (End_Date_vod__c >= :startDate and Start_Date_vod__c < :endDate) or (End_Time_vod__c >= :startDateTime and Start_Time_vod__c < :endDateTime))';
        } else {
            return '((Start_Date_vod__c >= :startDate and Start_Date_vod__c < :endDate) or (End_Date_vod__c >= :startDate and Start_Date_vod__c < :endDate))';
        }
    }

    protected override List<SObject> fetchData() {
        Object enableMedEvents = VeevaCustomSettingsService.getVeevaSettings(new List<String>{'ENABLE_SCHEDULE_MEDICAL_EVENT_vod__c'}).get('ENABLE_SCHEDULE_MEDICAL_EVENT_vod__c');
        if (this.fields.size() <= 0 || enableMedEvents == null || !Boolean.valueOf(enableMedEvents)) {
            return new List<Medical_Event_vod__c>();
        }
        
        String userId = this.getCalendarOwnerId();

        String medicalEventStatement = 'Select ' + String.join(fields, ',') + ' from Medical_Event_vod__c ' + 'where ' +
            getCallRangeStatementString() + ' and Status_vod__c != \'Rejected\' AND Status_vod__c != \'Canceled_vod\' AND OwnerId = :userId';

        String eventAttendeeStatement = 'SELECT ' + String.join(fields, ',')
            +' FROM Medical_Event_vod__c WHERE ' +getCallRangeStatementString()
            +' AND OwnerId != :userId AND Status_vod__c != \'Canceled_vod\' AND Id IN (SELECT Medical_Event_vod__c FROM Event_Attendee_vod__c WHERE Status_vod__c != \'Rejected\'';

        if (!emEventAttendeefields.contains('EM_Event_Team_Member_vod__c') || !emEventAttendeefields.contains('Role_vod__c') || !emEventAttendeefields.contains('Group_Name_vod__c')) {
            
            eventAttendeeStatement += ' AND User_vod__c = :userId)';

        } else {
            // get exclude roles setting
            Object emSetting = VeevaCustomSettingsService.getCustomSettings('Events_Management_Settings_vod__c', new List<String>{'Exclude_Team_Member_Roles_vod__c'}).get('Exclude_Team_Member_Roles_vod__c');
            List<String> excludeRoles = emSetting != null ? emSetting.toString().split(',') : new List<String>();

            // get group names
            List<GroupMember> groups = [SELECT Group.DeveloperName FROM GroupMember where UserOrGroupId = :userId];
            List<String> groupNames = new List<String>();
            for (GroupMember result : groups) {
                groupNames.add(result.Group.DeveloperName);
            }
            
            String attendeeOnlySelect = '((User_vod__c =:userId) AND (EM_Event_Team_Member_vod__c = null OR EM_Event_Team_Member_vod__c = \'\'))';
            String teamMemberSelect = '((EM_Event_Team_Member_vod__c != null AND EM_Event_Team_Member_vod__c != \'\') AND Role_vod__c NOT IN :excludeRoles AND (User_vod__c = :userId OR Group_Name_vod__c IN :groupNames))';
            eventAttendeeStatement += ' AND (' + attendeeOnlySelect + ' OR ' + teamMemberSelect + ' ))';
        }
        
        List<SObject> results = new List<SObject>();
        results.addAll(Database.query(medicalEventStatement));
        results.addAll(Database.query(eventAttendeeStatement));

        return results;
    }

    @TestVisible
    private Map<String, List<String>> getSpeakerNames(List<Medical_Event_vod__c> meList) {
        Map<String, List<String>> speakerListMap = new Map<String, List<String>>();

        if (!hasSpeakerNamesPermissions()) {
            return speakerListMap;
        }

        String speakerStatement = 'SELECT Medical_Event_vod__c, Attendee_vod__c FROM Event_Attendee_vod__c WHERE Medical_Event_vod__c IN :meList AND EM_Event_Speaker_vod__c != null'
                    +' AND Attendee_vod__c != null AND Medical_Event_vod__c != null AND CreatedDate != null AND EM_Event_Speaker_vod__r.Status_vod__c != \'Rejected_vod\'';
        
        List<Event_Attendee_vod__c> results = Database.query(speakerStatement);
        for (Event_Attendee_vod__c result: results) {
            List<String> speakerNames = speakerListMap.get(String.valueOf(result.Medical_Event_vod__c));

            if (speakerNames == null) {
                speakerListMap.put(String.valueOf(result.Medical_Event_vod__c), new List<String>{result.Attendee_vod__c});
            } else {
                speakerNames.add(String.valueOf(result.Attendee_vod__c));
            }
        }
        
        return speakerListMap;
    }

    private Boolean hasSpeakerNamesPermissions() {
        Boolean hasSpeakerPerm = VeevaBaseObject.create('EM_Speaker_vod__c') != null;
        Boolean hasEventSpeakerPerm = VeevaBaseObject.create('EM_Event_Speaker_vod__c') != null;
        Boolean hasAttendeeEventAttendeePerm = VeevaBaseObject.create('Event_Attendee_vod__c')?.getAccessibleField('Attendee_vod__c', false, false) != null;
        Boolean hasAttendeeEventSpeakerPerm = VeevaBaseObject.create('Event_Attendee_vod__c')?.getAccessibleField('EM_Event_Speaker_vod__c', false, false) != null;

        return hasSpeakerPerm && hasEventSpeakerPerm && hasAttendeeEventAttendeePerm && hasAttendeeEventSpeakerPerm;
    }

    @TestVisible
    protected override List<VeevaCalendarEvent> convertToEvents(List<SObject> objectList) {
        List<Medical_Event_vod__c> meList = (List<Medical_Event_vod__c>) objectList;    
        List<VeevaCalendarEvent> result = new List<VeevaCalendarEvent>();
        Map<String, List<String>> speakerMap = getSpeakerNames(meList);

        for (Medical_Event_vod__c me : meList) {
            result.add(VeevaCalendarEventFactory.createMedicalEventEvent(me, this.fields, speakerMap.get(me.Id)));
        }
        return result;
    }
}