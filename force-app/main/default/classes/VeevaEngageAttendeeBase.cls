public without sharing virtual class VeevaEngageAttendeeBase {
    public static final String POST_METHOD = 'POST';
    public static final String INSERT_ACTION = 'INSERT';
    public static final String DELETE_ACTION = 'DELETE';
    public static final Integer MAX_ENGAGE_ATTENDEE_PER_BATCH = 200;

    public static final String BASE_WHERE_EXPRESSION =
        'ID in :attendeeIds AND ' +
        'Event_vod__r.Engage_Webinar_vod__r.Scheduled_vod__c = true AND ' +
        'Event_vod__r.Status_vod__c NOT IN (\'Closed_vod\', \'Locked_vod\', \'Canceled_vod\') AND ' +
        'Status_vod__c NOT IN (\'Signed_vod\', \'Attended_vod\', \'Rejected_vod\')';

    private static final String CRM_ATTENDEE_TYPE = 'CRM';
    private static final String HCP_ATTENDEE_TYPE = 'HCP';

    public boolean virtualEventFieldsAccessible() {
         return Schema.SObjectType.EM_Event_vod__c.fields.Engage_Webinar_vod__c.isAccessible()
             && Schema.SObjectType.EM_Event_vod__c.fields.Assigned_Host_vod__c.isAccessible()
             && Schema.SObjectType.EM_Event_vod__c.fields.Status_vod__c.isAccessible()
             && Schema.SObjectType.Remote_Meeting_vod__c.fields.Scheduled_vod__c.isAccessible();
     }

     public boolean virtualEventAttendeeFieldsAccessible() {
         return Schema.SObjectType.EM_Attendee_vod__c.fields.Webinar_Participant_URL_vod__c.isAccessible()
            && Schema.SObjectType.EM_Attendee_vod__c.fields.Webinar_Participant_ID_vod__c.isAccessible();
     }

     public boolean virtualEventSpeakerFieldsAccessible() {
         return Schema.SObjectType.EM_Event_Speaker_vod__c.fields.Webinar_Panelist_URL_vod__c.isAccessible()
             && Schema.SObjectType.EM_Event_Speaker_vod__c.fields.Webinar_Panelist_ID_vod__c.isAccessible()
             && Schema.SObjectType.EM_Event_Speaker_vod__c.fields.Speaker_Formatted_Name_vod__c.isAccessible()
             && Schema.SObjectType.EM_Event_Speaker_vod__c.fields.First_Name_vod__c.isAccessible()
             && Schema.SObjectType.EM_Event_Speaker_vod__c.fields.Last_Name_vod__c.isAccessible()
             && Schema.SObjectType.EM_Event_Speaker_vod__c.fields.Speaker_Name_vod__c.isAccessible();
     }

    public String createSelectFieldsExpression(Set<String> originalQueryFields) {
        Set<String> queryFields = new Set<String>(originalQueryFields);
        if (Schema.sObjectType.Remote_Meeting_vod__c.fields.VExternal_Id_vod__c.isAccessible()) {
            queryFields.add('Event_vod__r.Engage_Webinar_vod__r.VExternal_Id_vod__c');
        }
        return String.join(new List<String>(queryFields), ', ');
    }

    public virtual String findFirstName(sObject attendee) {
        String firstName = '';
        if(attendee.get('First_Name_vod__c') == null && attendee.get('Last_Name_vod__c') == null && attendee.get('Attendee_Name_vod__c') != null) {
            firstName = (String)attendee.get('Attendee_Name_vod__c');
        } else if (attendee.get('First_Name_vod__c') != null) {
            firstName = (String)attendee.get('First_Name_vod__c');
        }
        return firstName;
    }

    public virtual String findLastName(sObject attendee) {
        String lastName = '';
        if (attendee.get('Last_Name_vod__c') != null) {
            lastName = (String)attendee.get('Last_Name_vod__c');
        }
        return lastName;
    }

    public virtual String findParticipantId(sObject attendee) {
        String participantId = '';
        if(attendee.get('Account_vod__c') != null) {
            participantId = (String)attendee.get('Account_vod__c');
        } else if(attendee.get('User_vod__c') != null) {
            participantId = (String)attendee.get('User_vod__c');
        } else if(attendee.get('Contact_vod__c') != null) {
            participantId = (String)attendee.get('Contact_vod__c');
        } else {
            participantId = (String)attendee.Id;
        }
        return participantId;
    }

    protected String findV2EngageMeetingId(sObject attendee) {
        sObject event = attendee.getSobject('Event_vod__r');
        if (event != null && Schema.sObjectType.Remote_Meeting_vod__c.fields.VExternal_Id_vod__c.isAccessible()) {
            sObject engageRemoteMeeting = event.getSobject('Engage_Webinar_vod__r');
            if (engageRemoteMeeting != null) {
                return (String)engageRemoteMeeting.get('VExternal_Id_vod__c');
            }
        }
        return null;
    }

    public String findEngageScheduledEventId(sObject attendee) {
        String eventId = '';
        if(attendee.getSobject('Event_vod__r') != null
           && attendee.getSobject('Event_vod__r').get('Assigned_Host_vod__c') == null
           && attendee.getSobject('Event_vod__r').get('Parent_Event_vod__c') != null) {
            eventId = (String)attendee.getSobject('Event_vod__r').get('Parent_Event_vod__c');
        } else if(attendee.get('Event_vod__c') != null) {
            eventId = (String)attendee.get('Event_vod__c');
        }
        return eventId;
    }

    public String createBodyForEngageRequest(List<sObject> attendeesForUpdate, String action) {
        JSONGenerator json = JSON.createGenerator(true);

        json.writeStartObject();
        json.writeStringField('action', action);
        json.writeFieldName('data');
        json.writeStartArray();


        for (sObject attendee : attendeesForUpdate) {
            createAttendeePayload(json, attendee);
        }
        json.writeEndArray();
        json.writeEndObject();

        return json.getAsString();
    }

    public virtual void createAttendeePayload(JSONGenerator json, sObject attendee) {
        String v2EngageMeetingId = findV2EngageMeetingId(attendee);
        String engageMeetingId = v2EngageMeetingId;
        if (engageMeetingId == null) {
            engageMeetingId = findEngageScheduledEventId(attendee);
        }

        json.writeStartObject();
        json.writeStringField('meetingRole', 'PARTICIPANT');
        json.writeStringField('salesforceId', findParticipantId(attendee));
        json.writeStringField('salesforceUpsertId', (String)attendee.Id);
        json.writeStringField('firstName', findFirstName(attendee));
        json.writeStringField('lastName', findLastName(attendee));
        json.writeStringField('meetingId', engageMeetingId);
        if (attendee.get('Attendee_Name_vod__c') != null) {
            json.writeObjectField('name', attendee.get('Attendee_Name_vod__c'));
        }
        if (v2EngageMeetingId != null) {
            json.writeStringField('type', attendee.get('User_vod__c') != null ? CRM_ATTENDEE_TYPE : HCP_ATTENDEE_TYPE);
        }
        json.writeEndObject();
    }

    public void setEngageGroupProvisioningStatus(List<sObject> attendeesForUpdate, String provisioningStatus) {
        String engageProvisioningStatus = (String.isBlank(provisioningStatus)) ? null : provisioningStatus;
        for (sObject attendee: attendeesForUpdate) {
            attendee.put('Engage_Provisioning_Status_vod__c', provisioningStatus);
        }
        update attendeesForUpdate;
    }

    public void sendToEngage(String httpMethod, String action, List<sObject> attendees) {
        Integer index = 0, count = 0;
        List<sObject> tempList = new List<sObject>();
        // engage HA server only accepts 200 per request, partition into 200 records per batch
        while(index < attendees.size()) {
            tempList.add(attendees.get(index++));
            ++count;
            if(count == MAX_ENGAGE_ATTENDEE_PER_BATCH) {
                sendOneBatchToEngage(httpMethod, action, tempList);
                tempList.clear();
                count = 0;
            }
        }
        if(!tempList.isEmpty()) {
            sendOneBatchToEngage(httpMethod, action, tempList);
        }
    }

    private void sendOneBatchToEngage(String httpMethod, String action, List<sObject> attendees) {
        // v1 and v2 attendees will be routed to different destinations, so split up attendees into v1 and v2 lists and
        // send each list.
        List<sObject> v1Attendees = new List<sObject>();
        List<sObject> v2Attendees = new List<sObject>();
        for (sObject attendee : attendees) {
            if (findV2EngageMeetingId(attendee) == null) {
                v1Attendees.add(attendee);
            } else {
                v2Attendees.add(attendee);
            }
        }

        sendHttpRequest(httpMethod, action, 'ATTENDEE', v1Attendees);
        sendHttpRequest(httpMethod, action, 'ATTENDEE_V2', v2Attendees);
    }

    private void sendHttpRequest(String httpMethod, String action, String headerType, List<sObject> attendees) {
        if (attendees.isEmpty()) {
            return;
        }

        String requestBody = createBodyForEngageRequest(attendees, action);

        HttpRequest request = createHttpRequest(httpMethod, headerType, requestBody);
        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() != 200 || response.getStatusCode() != 201) {
            System.debug('unable to send request to engage HA server');
            setEngageGroupProvisioningStatus(attendees, 'Request_Failed_vod');
        }
    }

    private HttpRequest createHttpRequest(String httpMethod, String headerType, String requestBody) {
        Veeva_Common_vod__c settings = Veeva_Common_vod__c.getValues('Main');
        String url = settings.HCP_Server_vod__c + '/api/v1/salesforce-integration/messages';
        String sfSession = VOD_EMBED_CONTROLLER.getSfSession();
        String sfEndpoint = VOD_EMBED_CONTROLLER.getSfEndpoint();

        HttpRequest request = new HttpRequest();
        request.setMethod(httpMethod);
        request.setHeader('sfSession', sfSession);
        request.setHeader('sfEndpoint', sfEndpoint);
        request.setHeader('type', headerType);
        request.setHeader('content-type', 'application/json');
        request.setEndpoint(url);
        request.setBody(requestBody);

        return request;
    }

    public String getChildValue(sObject sObj, String[] names, boolean replaceNullResult) {
        SObject o = sObj;
        String ret = null;
        for (Integer i = 0; i < (names.size() - 1) ; i++){
            o = o.getSObject(names[i]);
            if(o == null ){
                break;
            }
        }
        if(o != null){
            ret = (String)o.get(names[(names.size() - 1)]);
        }
        if(ret == null && replaceNullResult){
            ret = '';
        }
        return ret;
    }

}