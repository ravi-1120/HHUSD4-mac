public without sharing class VeevaEngageEventSpeakerService extends VeevaEngageAttendeeBase implements Queueable, Database.AllowsCallouts {
    private static final Set<String> EVENT_SPEAKER_QUERY_FIELDS = new Set<String> {
        'Id',
        'Webinar_Panelist_URL_vod__c',
        'Event_vod__c',
        'Speaker_Name_vod__c',
        'Account_vod__c',
        'Speaker_vod__c',
        'Speaker_vod__r.Account_vod__r.FirstName',
        'Speaker_vod__r.Account_vod__r.LastName',
        'Speaker_vod__r.Account_vod__r.PersonEmail',
        'First_Name_vod__c',
        'Last_Name_vod__c',
        'Speaker_Formatted_Name_vod__c',
        'Event_vod__r.Engage_Webinar_vod__r.RecordType.DeveloperName',
        'Event_vod__r.Assigned_Host_vod__c',
        'Event_vod__r.Parent_Event_vod__c'
    };

    Set<Id> attendeeIds = new Set<Id>();
    boolean isDelete;
    boolean isUpdate;

    public VeevaEngageEventSpeakerService(Set<Id> attendeeIds, boolean isDelete, boolean isUpdate) {
        this.attendeeIds = attendeeIds;
        this.isDelete = isDelete;
        this.isUpdate = isUpdate;
    }

    public void execute(QueueableContext context) {
        if (!virtualEventFieldsAccessible() || !virtualEventSpeakerFieldsAccessible()) {
            return;
        }
        if (isUpdate) {
            List<sObject> attendees = Database.query(createUpdatedSpeakersSOQL());
            sendToEngage(POST_METHOD, INSERT_ACTION, attendees);
            setEngageGroupProvisioningStatus(attendees, '');
        } else if (isDelete) {
            List<sObject> attendees = Database.query(createDeletedSpeakersSOQL());
            removeAttendeesSharedAcrossParentChildEvents(attendees);
            sendToEngage(POST_METHOD, DELETE_ACTION, attendees);
        } else {
            List<sObject> attendees = Database.query(createInsertedSpeakersSOQL());
            sendToEngage(POST_METHOD, INSERT_ACTION, attendees);
        }
    }

    private String createInsertedSpeakersSOQL() {
        return createSpeakersSOQL('Webinar_Panelist_URL_vod__c = null');
    }

    private String createDeletedSpeakersSOQL() {
        return createSpeakersSOQL('Webinar_Panelist_URL_vod__c != null AND IsDeleted = true ALL ROWS');
    }

    private String createUpdatedSpeakersSOQL() {
        return createSpeakersSOQL('Webinar_Panelist_URL_vod__c = null AND Engage_Provisioning_Status_vod__c = \'Retry_Request_vod\'');
    }

    private String createSpeakersSOQL(String additionalWhereExpression) {
        String soql = 'SELECT ' + createSelectFieldsExpression(EVENT_SPEAKER_QUERY_FIELDS) +
            ' FROM EM_Event_Speaker_vod__c WHERE ' + BASE_WHERE_EXPRESSION;
        if (additionalWhereExpression != null) {
            soql += ' AND ' + additionalWhereExpression;
        }
        return soql;
    }

    public void removeAttendeesSharedAcrossParentChildEvents(List<sObject> attendees) {
        Set<String> engageUrlSet = new Set<String>();
        for(sObject attendee : attendees) {
            engageUrlSet.add(((EM_Event_Speaker_vod__c)attendee).Webinar_Panelist_URL_vod__c);
        }
        Set<String> duplicateEngageUrlSet = new Set<String>();
        for (EM_Event_Speaker_vod__c record : [Select Id, Webinar_Panelist_URL_vod__c FROM EM_Event_Speaker_vod__c WHERE Webinar_Panelist_URL_vod__c in :engageUrlSet AND IsDeleted = false])
        {
            duplicateEngageUrlSet.add(record.Webinar_Panelist_URL_vod__c);
        }
        if(!duplicateEngageUrlSet.isEmpty()) {
            for (Integer i = (attendees.size()-1) ; i>= 0 ; i--){
                String engageUrl = ((EM_Event_Speaker_vod__c)attendees[i]).Webinar_Panelist_URL_vod__c;
                if(duplicateEngageUrlSet.contains(engageUrl)){
                    attendees.remove(i);
                }
            }
        }
    }

    public String getMeetingType(sObject attendee) {
        return getChildValue(attendee, new String[]{'Event_vod__r', 'Engage_Webinar_vod__r', 'RecordType', 'DeveloperName'}, true);
    }

    public override void createAttendeePayload(JSONGenerator json, sObject attendee) {
        String engageMeetingId = findV2EngageMeetingId(attendee);
        if (engageMeetingId == null) {
            engageMeetingId = findEngageScheduledEventId(attendee);
        }

        json.writeStartObject();
        json.writeStringField('meetingRole', 'SPEAKER');
        json.writeStringField('salesforceId', findParticipantId(attendee));
        json.writeStringField('salesforceUpsertId', (String)attendee.Id);
        json.writeStringField('firstName', findFirstName(attendee));
        json.writeStringField('lastName', findLastName(attendee));
        json.writeStringField('meetingId', engageMeetingId);
        if(attendee.get('Speaker_Name_vod__c') != null) {
            json.writeObjectField('name', attendee.get('Speaker_Name_vod__c'));
            json.writeObjectField('speakerName', attendee.get('Speaker_Name_vod__c'));
        }
        if(attendee.get('Speaker_Formatted_Name_vod__c') != null) {
            json.writeObjectField('formattedName', attendee.get('Speaker_Formatted_Name_vod__c'));
        }
        String email = getChildValue(attendee, new String[]{'Speaker_vod__r', 'Account_vod__r', 'PersonEmail'}, true);
        if(String.isNotBlank(email)) {
            json.writeStringField('email', email);
        }
        json.writeEndObject();
    }

    public override String findParticipantId(sObject attendee) {
        String participantId = '';
        if(attendee.get('Account_vod__c') != null) {
            participantId = (String)attendee.get('Account_vod__c');
        } else if(attendee.get('Speaker_vod__c') != null && 'Event_vod' == getMeetingType(attendee)) {
            participantId = (String)attendee.get('Speaker_vod__c');
        }
        return participantId;
    }

    public override String findFirstName(sObject attendee) {
        String firstName = '';
        if('Event_vod' == getMeetingType(attendee)) {
            firstName = getChildValue(attendee, new String[]{'Speaker_vod__r', 'Account_vod__r', 'FirstName'}, true);
        }
        if (attendee.get('First_Name_vod__c') != null && String.isBlank(firstName)) {
            firstName = (String)attendee.get('First_Name_vod__c');
        }
        return firstName;
    }

    public override String findLastName(sObject attendee) {
        String lastName = '';
        if('Event_vod' == getMeetingType(attendee)) {
            lastName = getChildValue(attendee, new String[]{'Speaker_vod__r', 'Account_vod__r', 'LastName'}, true);
        }
        if (attendee.get('Last_Name_vod__c') != null && String.isBlank(lastName)) {
            lastName = (String)attendee.get('Last_Name_vod__c');
        }
        return lastName;
    }
}