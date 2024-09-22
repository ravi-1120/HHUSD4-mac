public without sharing class VeevaEngageAttendeeService extends VeevaEngageAttendeeBase implements Queueable, Database.AllowsCallouts {
    private static final Set<String> ATTENDEE_QUERY_FIELDS = new Set<String> {
        'Id',
        'Webinar_Participant_URL_vod__c',
        'Event_vod__c',
        'Attendee_Name_vod__c',
        'Account_vod__c',
        'User_vod__c',
        'Contact_vod__c',
        'First_Name_vod__c',
        'Last_Name_vod__c',
        'Event_vod__r.Assigned_Host_vod__c',
        'Event_vod__r.Parent_Event_vod__c'
    };

    Set<Id> attendeeIds = new Set<Id>();
    boolean isDelete;
    boolean isUpdate;

    public VeevaEngageAttendeeService(Set<Id> attendeeIds, boolean isDelete, boolean isUpdate) {
        this.attendeeIds = attendeeIds;
        this.isDelete = isDelete;
        this.isUpdate = isUpdate;
    }

    public void execute(QueueableContext context) {
        if (!virtualEventFieldsAccessible() || !virtualEventAttendeeFieldsAccessible()) {
            return;
        }
        if (isUpdate) {
            List<sObject> attendees = Database.query(createUpdatedAttendeesSOQL());
            sendToEngage(POST_METHOD, INSERT_ACTION, attendees);
            setEngageGroupProvisioningStatus(attendees, '');
        } else if (isDelete) {
            List<sObject> attendees = Database.query(createDeletedAttendeesSOQL());
            removeAttendeesSharedAcrossParentChildEvents(attendees);
            sendToEngage(POST_METHOD, DELETE_ACTION, attendees);
        } else {
            List<sObject> attendees = Database.query(createInsertedAttendeesSOQL());
            sendToEngage(POST_METHOD, INSERT_ACTION, attendees);
        }
    }

    private String createInsertedAttendeesSOQL() {
        return createAttendeesSOQL('Webinar_Participant_URL_vod__c = null');
    }

    private String createDeletedAttendeesSOQL() {
        return createAttendeesSOQL('Webinar_Participant_URL_vod__c != null AND IsDeleted = true ALL ROWS');
    }

    private String createUpdatedAttendeesSOQL() {
        return createAttendeesSOQL('Webinar_Participant_URL_vod__c = null AND Engage_Provisioning_Status_vod__c = \'Retry_Request_vod\'');
    }

    private String createAttendeesSOQL(String additionalWhereExpression) {
        String soql = 'SELECT ' + createSelectFieldsExpression(ATTENDEE_QUERY_FIELDS) +
            ' FROM EM_Attendee_vod__c WHERE ' + BASE_WHERE_EXPRESSION;
        if (additionalWhereExpression != null) {
            soql += ' AND ' + additionalWhereExpression;
        }
        return soql;
    }

    public void removeAttendeesSharedAcrossParentChildEvents(List<sObject> attendees) {
        Set<String> engageUrlSet = new Set<String>();
        for(sObject attendee : attendees) {
            engageUrlSet.add(((EM_Attendee_vod__c)attendee).Webinar_Participant_URL_vod__c);
        }
        Set<String> duplicateEngageUrlSet = new Set<String>();
        for (EM_Attendee_vod__c record : [Select Id, Webinar_Participant_URL_vod__c FROM EM_Attendee_vod__c WHERE Webinar_Participant_URL_vod__c in :engageUrlSet AND IsDeleted = false])
        {
            duplicateEngageUrlSet.add(record.Webinar_Participant_URL_vod__c);
        }
        if(!duplicateEngageUrlSet.isEmpty()) {
            for (Integer i = (attendees.size()-1) ; i>= 0 ; i--){
                String engageUrl = ((EM_Attendee_vod__c)attendees[i]).Webinar_Participant_URL_vod__c;
                if(duplicateEngageUrlSet.contains(engageUrl)){
                    attendees.remove(i);
                }
            }
        }
    }

}