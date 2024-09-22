public inherited sharing class VeevaCalendarEventFactory {

    public static VeevaCalendarEvent createCallEvent(Call2_vod__c call, List<String> children, String callOwnerName, String location, String parentAccountName, Set<String> childAccountAccessibleFields, List<String> accessibleFields, Boolean enableChildAccount, Boolean enableSamplesOnSave, VeevaRemoteMeetingData remoteMeetingInfo, Boolean hasCallDatetime, String medicalIdentifier) {
        Map<String, SObjectField> callFields = Schema.SObjectType.Call2_vod__c.fields.getMap();
        String objectLabel = Call2_vod__c.SObjectType.getDescribe().getLabel();
        String recordType = call.RecordType.Name == null ? objectLabel : call.RecordType.Name;
        String locationTextField = getFieldValueForOptionalField(accessibleFields, 'Location_Text_vod__c', call);
        String remoteMeetingId = getFieldValueForOptionalField(accessibleFields, 'Remote_Meeting_vod__c', call);
        String callChannel = getFieldValueForOptionalField(accessibleFields, 'Call_Channel_vod__c', call);
        Boolean isChildAccountCall = enableChildAccount && childAccountAccessibleFields.contains('Parent_Child_Name_vod__c') && call.Child_Account_vod__r.Parent_Child_Name_vod__c != null;
        String callName = isChildAccountCall ? call.Child_Account_vod__r.Parent_Child_Name_vod__c : call.Entity_Display_Name_vod__c;
        String accountIdentifier = enableChildAccount && childAccountAccessibleFields.contains('Child_Account_Identifier_vod__c') && call.Child_Account_vod__r.Child_Account_Identifier_vod__c != null ? call.Child_Account_vod__r.Child_Account_Identifier_vod__c : getIdentifierForCall(medicalIdentifier, accessibleFields, call);

        return new VeevaCalendarEventBuilder(callName, call.Id, recordType, 'Call2_vod__c')
            .parentAccount(parentAccountName)
            .owner(callOwnerName)
            .children(children)
            .accountIdentifier(accountIdentifier)
            .accountId(call.Account_vod__c)
            .accountUrl(isChildAccountCall ? null : call.Account_vod__c)
            .callChannel(callChannel)
            .callChannelLabel(!String.isBlank(callChannel) ? (String) call.get('callChannelLabel') : '')
            .status(call.Status_vod__c)
            .statusLabel((String) call.get('statusLabel'))
            .isSigned(accessibleFields.contains('Signature_Date_vod__c') ? call.Signature_Date_vod__c : null)
            .hasSampleCard(getFieldValueForOptionalField(accessibleFields, 'Sample_Card_vod__c', call), getFieldValueForOptionalField(accessibleFields, 'Sample_Send_Card_vod__c', call))
            .hasUnscheduledRemoteMeeting(remoteMeetingId, remoteMeetingId != null ? call.Remote_Meeting_vod__r.Scheduled_vod__c : false)
            .address(getFieldValueForOptionalField(accessibleFields, 'Address_vod__c', call))
            .remoteAttendees(remoteMeetingInfo)
            .eventTimes(call, callFields)
            .location(location != null ? location : locationTextField, isChildAccountCall)
            .eventType(!String.isBlank(callOwnerName) ? 'attendee-call' : 'call')
            .childAccountId(isChildAccountCall ? getFieldValueForOptionalField(accessibleFields, 'Child_Account_vod__c', call) : null)
            .unavailable(accessibleFields.contains('Unavailable_for_Scheduling_vod__c') ? (Boolean) call.get('Unavailable_for_Scheduling_vod__c') : null)
            .resizable(enableSamplesOnSave, hasCallDatetime, accessibleFields.contains('Call_Datetime_vod__c'))
            .build();
    }

    public static VeevaCalendarEvent createTimeOffTerritoryEvent(Time_Off_Territory_vod__c tot, Integer weekendStart, Integer weekendEnd, List<String> accessibleFields) {
        Map<String, SObjectField> totFields = Schema.SObjectType.Time_Off_Territory_vod__c.fields.getMap();
        String reason = getFieldValueForOptionalField(accessibleFields, 'Reason_vod__c', tot);
        String totRecordType = Time_Off_Territory_vod__c.SObjectType.getDescribe().getLabel();

        return new VeevaCalendarEventBuilder(String.isNotBlank(reason) ? reason : totRecordType, tot.Id, totRecordType, 'Time_Off_Territory_vod__c')
            .status(getFieldValueForOptionalField(accessibleFields, 'Status_vod__c', tot))
            .statusLabel((String) tot.get('statusLabel'))
            .unavailable(accessibleFields.contains('Unavailable_for_Engage_Scheduling_vod__c') ? (Boolean) tot.get('Unavailable_for_Engage_Scheduling_vod__c') : null)
            .eventTimes(tot, totFields, weekendStart, weekendEnd)
            .eventType('time-off-territory')
            .build();
    }

    public static VeevaCalendarEvent createMedicalEventEvent(Medical_Event_vod__c me, List<String> accessibleFields, List<String> speakers) {
        Map<String, SObjectField> meFields = Schema.SObjectType.Medical_Event_vod__c.fields.getMap();
        String objectLabel = Medical_Event_vod__c.SObjectType.getDescribe().getLabel();
        String recordType = me.RecordType.Name == null ? objectLabel : me.RecordType.Name;
        String meOwner = me.Owner == null ? null : me.Owner.Name;
        Boolean isEmEvent = accessibleFields.contains('EM_Event_vod__c') && me.EM_Event_vod__c != null;
        speakers?.sort();

        String medicalEventType = getFieldValueForOptionalField(accessibleFields, 'Event_Type__c', me);

        return new VeevaCalendarEventBuilder(me.Name, me.Id, recordType, isEmEvent ? 'EM_Event_vod__c' : 'Medical_Event_vod__c')
            .owner(meOwner)
            .ownerUrl(me.OwnerId)
            .ownerId(me.OwnerId)
            .status(getFieldValueForOptionalField(accessibleFields, 'EM_Event_vod__r.Status_vod__c', me))
            .eventTimes(me, meFields)
            .location(getFieldValueForOptionalField(accessibleFields, 'Location__c', me))
            .medicalEventType(medicalEventType)
            .programType(getFieldValueForOptionalField(accessibleFields, 'EM_Event_vod__r.Program_Type_vod__c', me))
            .emEventId(getFieldValueForOptionalField(accessibleFields, 'EM_Event_vod__c', me))
            .eventType('medical-event')
            .children(speakers)
            .build();
    }

    public static VeevaCalendarEvent createUnavailableTimeEvent(Unavailable_Time_vod__c ut) {
        Map<String, SObjectField> utFields = Schema.SObjectType.Unavailable_Time_vod__c.fields.getMap();
        String objectLabel = Unavailable_Time_vod__c.SObjectType.getDescribe().getLabel();
        String recordType = ut.RecordType.Name == null ? objectLabel : ut.RecordType.Name;

        return new VeevaCalendarEventBuilder(objectLabel, ut.Id, recordType, 'Unavailable_Time_vod__c')
            .eventTimes(ut, utFields)
            .eventType('unavailable-time')
            .build();
    }

    public static VeevaCalendarEvent createCalendarEntry(Event e, List<String> accessibleFields) {
        Map<String, SObjectField> eFields = Schema.SObjectType.Event.fields.getMap();
        String objectLabel = Event.SObjectType.getDescribe().getLabel();
        String recordType = e.RecordType.Name == null ? objectLabel : e.RecordType.Name;
        
        return new VeevaCalendarEventBuilder(e.Subject, e.Id, recordType, 'Event')
            .eventTimes(e, eFields)
            .eventType('calendar-entry')
            .resizable()
            .build();
    }

    public static VeevaCalendarEvent createUnassignedPresentationEvent(Multichannel_Activity_vod__c up, Boolean hasKeyMessageDescriptionFls, Boolean hasViewOrderFls) {
        Map<String, SObjectField> upFields = Schema.SObjectType.Multichannel_Activity_vod__c.fields.getMap();
        String objectLabel = Multichannel_Activity_vod__c.SObjectType.getDescribe().getLabel();
        String recordType = up.RecordType.Name == null ? objectLabel : up.RecordType.Name;

        return new VeevaCalendarEventBuilder(objectLabel, up.Id, recordType, 'Multichannel_Activity_vod__c')
            .eventTimes(up, upFields)
            .eventType('unassigned-presentation')
            .viewedSlides(hasKeyMessageDescriptionFls ? up.Multichannel_Activity_Lines_vod__r : null, hasViewOrderFls)
            .hasKeyMessageDescriptionFls(hasKeyMessageDescriptionFls)
            .hasCall(up.Call_vod__c != null)
            .build();
    }

    public static VeevaCalendarEvent createMeetingRequestEvent(Meeting_Request_vod__c mr, List<String> accessibleFields) {
        Map<String, SObjectField> mrFields = Schema.SObjectType.Meeting_Request_vod__c.fields.getMap();
        String objectLabel = Meeting_Request_vod__c.SObjectType.getDescribe().getLabel();
        String recordType = mr.RecordType.Name == null ? objectLabel : mr.RecordType.Name;
        String meetingType = getFieldValueForOptionalField(accessibleFields, 'Meeting_Type_vod__c', mr);
        String mrStatus = getFieldValueForOptionalField(accessibleFields, 'Status_vod__c', mr);

        return new VeevaCalendarEventBuilder(mr.Invitee_Display_Name_vod__c, mr.Id, recordType, 'Meeting_Request_vod__c')
            .eventTimes(mr, mrFields)
            .eventType('meeting-request')
            .accountId(mr.Account_vod__c)
            .accountDoNotCall(mr.Account_vod__r?.Do_Not_Call_vod__c == 'Yes_vod')
            .accountRecordType(mr.Account_vod__r?.RecordType?.Name)
            .meetingTypeLabel(!String.isBlank(meetingType) ? (String) mr.get('meetingTypeLabel') : '')
            .meetingType(meetingType)
            .phone(getFieldValueForOptionalField(accessibleFields, 'Phone_vod__c', mr))
            .status(mrStatus)
            .statusLabel(!String.isBlank(mrStatus) ? (String) mr.get('statusLabel') : '')
            .build();
    }

    public static VeevaCalendarEvent createExternalEventEvent(External_Calendar_Event_vod__c ee, List<String> accessibleFields) {
        Map<String, SObjectField> eeFields = Schema.SObjectType.External_Calendar_Event_vod__c.fields.getMap();
        String objectLabel = External_Calendar_Event_vod__c.SObjectType.getDescribe().getLabel(); 
        String recordType = ee.RecordType.DeveloperName == null ? objectLabel : ee.RecordType.Name;
        String recordTypeDevName = ee.RecordType.DeveloperName == null ? objectLabel : ee.RecordType.DeveloperName;
        String title = '';
        if (accessibleFields.contains('Title_vod__c')) {
            title = String.isBlank((String) ee.get('Title_vod__c')) && recordTypeDevName == 'Microsoft_Outlook_vod' ? '' : (String) ee.get('Title_vod__c');
        }

        return new VeevaCalendarEventBuilder(title, ee.Id, recordType, 'External_Calendar_Event_vod__c')
            .eventTimes(ee, eeFields)
            .eventType('external-event')
            .externalCalendarId(ee.External_Calendar_vod__c)
            .sensitivity(ee.Sensitivity_vod__c)
            .unavailable(accessibleFields.contains('Unavailable_for_Engage_Scheduling_vod__c') ? (Boolean) ee.get('Unavailable_for_Engage_Scheduling_vod__c') : null)
            .build();
    }
    
    private static String getFieldValueForOptionalField(List<String> accessibleFields, String fieldName, SObject obj) {
        String nameOnly = fieldName.startsWithIgnoreCase('toLabel(') ? fieldName.removeStartIgnoreCase('toLabel(').substringBefore(')') : fieldName;
        if (accessibleFields.contains(nameOnly) || accessibleFields.contains('toLabel(' + nameOnly + ')')) {
            if (nameOnly.contains('__r.')) {
                SObject relationship = obj.getSobject(nameOnly.substringBefore('.'));
                return relationship != null ? (String) relationship.get(nameOnly.substringAfter('.')) : null;
            }
            return (String) obj.get(nameOnly);
        }   
        return null;
    }

    private static String getIdentifierForCall(String medicalIdentifier, List<String> accessibleFields, Call2_vod__c call) {
        if (medicalIdentifier == 'Medical_Identifier_vod__c') {
            return getFieldValueForOptionalField(accessibleFields, 'Account_vod__r.Medical_Identifier_vod__c', call);
        }
        return getFieldValueForOptionalField(accessibleFields, 'Account_vod__r.Account_Identifier_vod__c', call);
    }
}