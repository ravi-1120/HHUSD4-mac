public virtual with sharing class VeevaCalendarCallData extends VeevaCalendarData {
    @TestVisible Map<String, Boolean> dateTimeUsageByRecordType = new Map<String, Boolean>();
    private Set<String> childAccountAccessibleFields = getChildAccountAccessibleFields();
    private String userIdentifier = VeevaMedicalIdentifierHandler.getIdentifierString();
    private final Map<Id, Schema.RecordTypeInfo> recordTypeInfoMap;
    private String withinCallRangeStmtStr;
    private VeevaLayoutService layoutService;
    private Boolean enableChildAccount;
    private Boolean enableSamplesOnSave;

    public VeevaCalendarCallData(Datetime startDateTime, Datetime endDateTime, VeevaLayoutService layoutService) {
        this(startDateTime, endDateTime, layoutService, UserInfo.getUserId());
    }
    
    public VeevaCalendarCallData(Datetime startDateTime, Datetime endDateTime, VeevaLayoutService layoutService, Id userId) {
        super(
            new Set<String> {'Attendee_Type_vod__c', 'Account_vod__r.Formatted_Name_vod__c', 'Account_vod__r.Account_Identifier_vod__c', 'Account_vod__r.Medical_Identifier_vod__c', 'Account_vod__r.Primary_Parent_vod__r.Formatted_Name_vod__c', 'Entity_Display_Name_vod__c', 'Contact_vod__r.Name', 'User_vod__r.Name', 'Address_vod__c', 'Duration_vod__c', 'OwnerId', 'Call_Datetime_vod__c', 'Call_Date_vod__c', 'Status_vod__c', 'toLabel(Status_vod__c) statusLabel', 'Id', 'Parent_Call_vod__c', 'Call_Channel_vod__c', 'toLabel(Call_Channel_vod__c) callChannelLabel', 'Medical_Event_vod__r.Name', 'Location_Text_vod__c', 'User_vod__c', 'Signature_Date_vod__c', 'Sample_Card_vod__c', 'Sample_Send_Card_vod__c', 'Remote_Meeting_vod__c', 'Remote_Meeting_vod__r.Scheduled_vod__c', 'Remote_Meeting_vod__r.Scheduled_DateTime_vod__c', 'RecordTypeId', 'toLabel(RecordType.Name)', 'Child_Account_vod__c', 'Child_Account_vod__r.Child_Account_Identifier_vod__c', 'Child_Account_vod__r.Parent_Child_Name_vod__c', 'Parent_Call_vod__r.Remote_Meeting_vod__c', 'Cobrowse_URL_Participant_vod__c', 'Contact_vod__c', 'Unavailable_for_Scheduling_vod__c'},
            userId, 
            'Call2_vod__c',
            startDateTime,
            endDateTime
        );
        Map<String, SObjectField> descr = Call2_vod__c.SObjectType.getDescribe().fields.getMap();
        Map<String, Object> settings = VeevaMyScheduleController.getVeevaSettings();
        this.enableChildAccount = Boolean.valueOf(settings.get('Enable_Child_Account_vod__c'));
        this.enableSamplesOnSave = Boolean.valueOf(settings.get('Enable_Samples_On_Save_vod__c'));
        this.recordTypeInfoMap = Schema.SObjectType.Call2_vod__c.getRecordTypeInfosById();
        this.fields = filterFields(descr, this.getQueryFields());
        this.withinCallRangeStmtStr = this.getCallRangeStatementString();
        this.layoutService = layoutService;
    }

    private String getCallRangeStatementString() {
        if (this.isFieldAccessible('Call_Datetime_vod__c')) {
            return '((Call_Datetime_vod__c >= :startDateTime and Call_Datetime_vod__c < :endDateTime) or (Call_Date_vod__c >= :startDate and Call_Date_vod__c < :endDate))';
        } else {
            return '(Call_Date_vod__c >= :startDate and Call_Date_vod__c < :endDate)';
        }
    }

    private List<Call2_vod__c> fetchCallsByField(String field, List<String> fieldIds) {
        return this.fetchCallsByField(field, fieldIds, '');
    }

    private List<Call2_vod__c> fetchCallsByField(String field, List<String> fieldIds, String additionalConditions) {
        if (this.fields.size() > 0) {
			String stmt = 'Select ' + String.join(this.fields, ',') + ' from Call2_vod__c where ' + field + ' in :fieldIds ' + additionalConditions + ' and ' + withinCallRangeStmtStr;
			return Database.query(stmt);
		}
		return new List<Call2_vod__c>();
    }

    protected override List<SObject> fetchData() {
        String userId = this.getCalendarOwnerId();
        List<String> queryFields = this.fields.clone();
        if (!queryFields.contains('Call_Datetime_vod__c')) {
            queryFields.add('Call_Datetime_vod__c');
        }
        if (this.fields.size() > 0) {
			String stmt = 'Select ' + String.join(queryFields, ',') + ' from Call2_vod__c where (OwnerId = :userId or User_vod__c = :userId) and ' + withinCallRangeStmtStr;
            return Database.query(stmt);
		}
		return new List<Call2_vod__c>();
    }

    private Call2_vod__c getCallWithId(List<Call2_vod__c> callList, Id idStr) {
        for (Call2_vod__c call : callList) {
            if (call.Id == idStr) {
                return call;
            }
        }
        return new Call2_vod__c();
    }

    private void getAttendeeAccountNamesForCalls(List<Call2_vod__c> callList, Map<String, List<String>> attendeeMap, Set<Id> processedAttendees, Map<String, String> groupCallLocations, Map<String, Boolean> parentIdsSigned) {
        Set<String> signedCallsQueried = new Set<String>();
        for (Call2_vod__c call : callList) {
            String parentId = call.Parent_Call_vod__c;
            Call2_vod__c parentCall = getCallWithId(callList, parentId);
            Boolean parentIsChildAccountCall = parentCall.Id == parentId && enableChildAccount && childAccountAccessibleFields.contains('Parent_Child_Name_vod__c') && parentCall.Child_Account_vod__r.Parent_Child_Name_vod__c != null;
            String acctName = parentIsChildAccountCall && call.User_vod__c == null && call.Contact_vod__c == null ? call.Child_Account_vod__r.Parent_Child_Name_vod__c : call.Entity_Display_Name_vod__c;

            if (!String.isBlank(parentId) && acctName != null) {
                // attendees of the type 'Group_Account_vod' are actually locations (we'll only have 1 max), all other types are regular attendees

                if (call.Attendee_Type_vod__c == 'Group_Account_vod'){
                    if(groupCallLocations != null && !groupCallLocations.containsKey(parentId)) {
                        groupCallLocations.put(parentId, acctName);
                    }
                } else {
                    List<String> attendeeNames = attendeeMap.get(parentId);
                    if (attendeeNames == null) {
                        attendeeMap.put(parentId, new List<String>{acctName});
                        processedAttendees.add(call.Id);
                    } else if (!processedAttendees.contains(call.Id)) {
                        attendeeNames.add(acctName);
                        processedAttendees.add(call.Id);
                    }

                    if (this.fields.contains('Signature_Date_vod__c') && call.Signature_Date_vod__c != null && parentIdsSigned.get(parentId) == null) {
                        parentIdsSigned.put(parentId, parentIsChildAccountCall);
                    }

                }
            }
        }
    }

    private static Boolean parentIsRemoteCall(Call2_vod__c call) {
        return String.isNotBlank(call.Parent_Call_vod__c) && String.isNotBlank(call.Parent_Call_vod__r.Remote_Meeting_vod__c);
    }

    private static String getRemoteMeetingCallId(Call2_vod__c call) {
        if (String.isNotBlank(call.Remote_Meeting_vod__c)) {
            return parentIsRemoteCall(call) ? call.Parent_Call_vod__c : call.Id;
        }
        return null;
    }

    private static String getRemoteMeetingCallId(Sent_Email_vod__c email) {
        return String.isNotBlank(email.Call2_vod__r.Parent_Call_vod__c) ? email.Call2_vod__r.Parent_Call_vod__c : email.Call2_vod__c;
    }

    private void updateRemoteMeetingInfoMap(Map<Id, VeevaRemoteMeetingData> remoteMeetingInfoMap, List<Call2_vod__c> callList) {
        if (!this.canUpdateRemoteMeetingMap()) {
            return;
        }

        Set<Id> callIds = new Set<Id>();
        Map<Id, Remote_Meeting_vod__c> remoteMeetingMap = new Map<Id, Remote_Meeting_vod__c>();
        for (Call2_vod__c call : callList) {
            Id remoteCallId = getRemoteMeetingCallId(call);
            Id remoteAccountAttendee = this.getRemoteAttendeeAccountField(call);
            if (remoteCallId != null && call.Status_vod__c != 'Submitted_vod' && remoteAccountAttendee != null && call.Cobrowse_URL_Participant_vod__c != null) {
                VeevaRemoteMeetingData callWithRemoteMeeting = remoteMeetingInfoMap.get(remoteCallId);

                // remote call id to remote Meeting data object map
                if (callWithRemoteMeeting == null) {
                    callWithRemoteMeeting = new VeevaRemoteMeetingData();
                    remoteMeetingInfoMap.put(remoteCallId, callWithRemoteMeeting);
                }
                callWithRemoteMeeting.accountInviteStatus.put(remoteAccountAttendee, false);

                // call id to remote meeting map
                if (remoteMeetingMap.get(call.Id) == null) {
                    remoteMeetingMap.put(call.Id, call.Remote_Meeting_vod__r);
                }

                callIds.add(call.Id);
            }
        }
        if (callIds.isEmpty()) {
            return;
        }

        Set<String> statusCodes = VeevaRemoteMeetingData.statusCodes;
        List<Sent_Email_vod__c> sentEmails = [SELECT Call2_vod__c, Call2_vod__r.Account_vod__c, Call2_vod__r.User_vod__c, Call2_vod__r.Contact_vod__c, Call2_vod__r.Parent_Call_vod__c, CreatedDate, Status_vod__c FROM Sent_Email_vod__c WHERE RecordType.DeveloperName = 'Remote_Meeting_vod' AND Call2_vod__c in :callIds AND Status_vod__c IN :statusCodes];

        for (Sent_Email_vod__c email : sentEmails) {
            // check that the call has an invited status and the Scheduled_DateTime_vod__c for Remote meeting is before the CreatedDate for the sent email
            if (email.Call2_vod__c != null && VeevaRemoteMeetingData.invitedStatusCodes.contains(email.Status_vod__c)
                && remoteMeetingMap.get(email.Call2_vod__c)?.Scheduled_DateTime_vod__c != null && remoteMeetingMap.get(email.Call2_vod__c)?.Scheduled_DateTime_vod__c < email.CreatedDate) {

                Id remoteAccountAttendee = this.getRemoteAttendeeAccountField(email.Call2_vod__r);

                VeevaRemoteMeetingData remoteMeetingCall = remoteMeetingInfoMap.get(getRemoteMeetingCallId(email));
                if (remoteMeetingCall == null) {
                    remoteMeetingCall = new VeevaRemoteMeetingData();
                    remoteMeetingInfoMap.put(email.Call2_vod__c, remoteMeetingCall);
                }
                remoteMeetingCall.accountInviteStatus.put(remoteAccountAttendee, true);
            }
        }
    }

    private Id getRemoteAttendeeAccountField(Call2_vod__c call) {
        if (call.Account_vod__c != null) {
            return call.Account_vod__c;
        } else if (call.User_vod__c != null) {
            return call.User_vod__c;
        } else if (call.Contact_vod__c != null) {
            return call.Contact_vod__c;
        }
        return null;
    }

    private boolean canUpdateRemoteMeetingMap() {
        Set<String> desiredFields = new Set<String>{'Call2_vod__c', 'Status_vod__c', 'CreatedDate'};
        Map<String, SObjectField> descr = Sent_Email_vod__c.SObjectType.getDescribe().fields.getMap();
        List<String> sentEmailFilteredFields = filterFields(descr, desiredFields);
        Boolean hasRemoteScheduledDateDescObj = Schema.sObjectType.Remote_Meeting_vod__c.fields?.Scheduled_DateTime_vod__c?.isAccessible();
        return sentEmailFilteredFields.size() == desiredFields.size() && this.isFieldAccessible('Remote_Meeting_vod__c') && hasRemoteScheduledDateDescObj;
    }

    @TestVisible
    private Map<Call2_vod__c, String> getParentCallInformationForAttendees(List<Call2_vod__c> callList, Map<String, List<String>> attendeeMap, Set<Id> processedAttendees, Map<Id, VeevaRemoteMeetingData> remoteMeetingInfoMap, Map<String, Boolean> parentIdsSigned) {
        List<String> parentIds = new List<String>();
        Set<String> ownerIds = new Set<String>();

        Set<Id> callIds = new Map<Id, Call2_vod__c>(callList).keySet();
        for (String parentId : attendeeMap.keySet()) {
            if (!callIds.contains(parentId)) {
                parentIds.add(parentId);
            }
        } // get every call that wasn't originally fetched, but whose children were
        List<Call2_vod__c> parentCallsForAttendees = this.fetchCallsByField('Id', parentIds);
        String userId = this.getCalendarOwnerId();
        for (Call2_vod__c call : parentCallsForAttendees) {
            if (!call.OwnerId.equals(userId) && !ownerIds.contains(call.OwnerId)) {
                ownerIds.add(call.OwnerId);
            }
        }

        // obtain other attendees for parent calls
        List<Call2_vod__c> attendeeCallsForParentCalls = this.fetchCallsByField('Parent_Call_vod__c', parentIds, 'AND User_vod__c != \'' + userId + '\' ');
        this.getAttendeeAccountNamesForCalls(attendeeCallsForParentCalls, attendeeMap, processedAttendees, null, parentIdsSigned);

        Map<Id, User> callOwners = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id in :ownerIds]);
        Map<Call2_vod__c, String> result = new Map<Call2_vod__c, String>();
        // find owner name for each attendee call
        for (Call2_vod__c call : parentCallsForAttendees) {
            if (ownerIds.contains(call.OwnerId)) {
                result.put(call, callOwners.get(call.OwnerId).Name);
            } else {
                result.put(call, null);
            }
        }
        // check all potential attendees of a remote meeting to calculate invited-attendee count
        List<Call2_vod__c> potentialAttendeeCallsForRemoteMeetings = new List<Call2_vod__c>(callList);
        potentialAttendeeCallsForRemoteMeetings.addAll(attendeeCallsForParentCalls);
        updateRemoteMeetingInfoMap(remoteMeetingInfoMap, potentialAttendeeCallsForRemoteMeetings);

        return result;
    }

    private void updateParentCallSignatures(List<Call2_vod__c> callList) {
        Map<Id, Call2_vod__c> callListMap = new Map<Id, Call2_vod__c>(callList);
        Set<Id> updatedParents = new Set<Id>();
        for (Call2_vod__c call : callList) {
            if (call.Parent_Call_vod__c == null || updatedParents.contains(call.Parent_Call_vod__c)) {
                continue;
            }
            // if call is a child and is signed, we need to ensure its parent call is also showing there is a signature
            Call2_vod__c parentCall = callListMap.get(call.Parent_Call_vod__c);
            if (parentCall != null && this.fields.contains('Signature_Date_vod__c') && call.Signature_Date_vod__c != null && parentCall.Signature_Date_vod__c == null) {
                parentCall.Signature_Date_vod__c = call.Signature_Date_vod__c;
                updatedParents.add(call.Parent_Call_vod__c);
            }
        }
    }

    private static void convertToAllDayCall(Call2_vod__c call) {
        if (call.Call_Date_vod__c == null) {
            call.Call_Date_vod__c = call.Call_Datetime_vod__c.date();
        }
        call.Call_Datetime_vod__c = null;
    }

    private static Set<String> getChildAccountAccessibleFields() {
        Boolean hasChildAccountFLS = VeevaBaseObject.create('Call2_vod__c').getAccessibleField('Child_Account_vod__c', false, false) != null;
        Set<String> childAccountAccessibleFields = new Set<String>();
        VeevaBaseObject childAccountObj = VeevaBaseObject.create('Child_Account_vod__c');

        if (hasChildAccountFLS && childAccountObj != null) {
            childAccountAccessibleFields.addAll(
                childAccountObj.getAccessibleFields(new Set<String>{
                    'Child_Account_Identifier_vod__c', 'Parent_Child_Name_vod__c'
                })
            );
        }
        return childAccountAccessibleFields;
    }

    @TestVisible
    private Boolean recordTypeUsesDatetime(Call2_vod__c call) {
        Boolean useDateTime = false;
        if (!this.dateTimeUsageByRecordType.containsKey(call.RecordTypeId)) {
            String recordTypeDevName = this.recordTypeInfoMap.get(call.RecordTypeId).getDeveloperName();
            useDateTime = this.layoutService.checkLayoutForField('Call2_vod__c', 'Call_Datetime_vod__c', recordTypeDevName);
            this.dateTimeUsageByRecordType.put(call.RecordTypeId, useDateTime);
        } else {
            useDateTime = this.dateTimeUsageByRecordType.get(call.RecordTypeId);
        }
        return useDateTime;
    }

    @TestVisible
    protected override List<VeevaCalendarEvent> convertToEvents(List<SObject> objectList) {
        List<Call2_vod__c> callList = (List<Call2_vod__c>) objectList;
        Map<String, Boolean> parentIdsSigned = new Map<String, Boolean>();
        Map<Id, VeevaRemoteMeetingData> remoteMeetingInfoMap = new Map<Id, VeevaRemoteMeetingData>();
        Map<String, List<String>> callToAttendeesNameMap = new Map<String, List<String>>();
        Map<String, String> groupCallLocations = new Map<String, String>();
        List<VeevaCalendarEvent> result = new List<VeevaCalendarEvent>();
        Set<Id> processedAttendees = new Set<Id>();

        this.getAttendeeAccountNamesForCalls(callList, callToAttendeesNameMap, processedAttendees, groupCallLocations, parentIdsSigned);
        Map<Call2_vod__c, String> parentCallInfo = this.getParentCallInformationForAttendees(callList, callToAttendeesNameMap, processedAttendees, remoteMeetingInfoMap, parentIdsSigned);
        callList.addAll(parentCallInfo.keySet());

        this.updateParentCallSignatures(callList);

        this.updateAttendeeListForSignedCalls(callToAttendeesNameMap, processedAttendees, parentIdsSigned);

        for (Call2_vod__c call: callList) {
            if (String.isBlank(call.Parent_Call_vod__c)) {
                String callOwnerName = parentCallInfo.get(call);
                Boolean hasCallDatetime = call.Call_Datetime_vod__c != null;
                if (!this.recordTypeUsesDatetime(call)) {
                    convertToAllDayCall(call);
                }
                VeevaRemoteMeetingData remoteMeetingInfo = remoteMeetingInfoMap.get(call.Id);
                String parentAccountName = call.Attendee_Type_vod__c != 'Group_Account_vod' ? call.Account_vod__r.Primary_Parent_vod__r.Formatted_Name_vod__c : null;
                result.add(VeevaCalendarEventFactory.createCallEvent(call, callToAttendeesNameMap.get(call.Id), callOwnerName, groupCallLocations.get(call.Id), parentAccountName, childAccountAccessibleFields, this.fields, enableChildAccount, enableSamplesOnSave, remoteMeetingInfo, hasCallDatetime, userIdentifier));
            }
        }
        return result;
    }

    private void updateAttendeeListForSignedCalls(Map<String, List<String>> callToAttendeesNameMap, Set<Id> processedAttendees, Map<String, Boolean> parentIdsSigned) {
        if (parentIdsSigned.isEmpty()) {
            return;
        }
        Set<String> parentIds = parentIdsSigned.keySet();
        String queryStmt = 'Select User_vod__c, Contact_vod__c, Parent_Call_vod__c, Child_Account_vod__r.Parent_Child_Name_vod__c, Entity_Display_Name_vod__c' + ' from Call2_vod__c' + ' where Parent_Call_vod__c in :parentIds and Attendee_Type_vod__c != \'Group_Account_vod\'';
        List<Call2_vod__c> allChildCalls = Database.query(queryStmt);

        for (Call2_vod__c childCall: allChildCalls) {
            String parentId = childCall.Parent_Call_vod__c;
            List<String> attendeeNames = callToAttendeesNameMap.get(parentId);
            Boolean parentIsChildAccountCall = parentIdsSigned.get(parentId);

            String childAcctName = parentIsChildAccountCall && childCall.User_vod__c == null && childCall.Contact_vod__c == null ? childCall.Child_Account_vod__r.Parent_Child_Name_vod__c : childCall.Entity_Display_Name_vod__c;
            if (!processedAttendees.contains(childCall.Id)) {
                attendeeNames.add(childAcctName);
                processedAttendees.add(childCall.Id);
            }
        }
    }

    private static void addCallToMap(Map<String, Map<String, Date>> accountCalls, String callId, Date callDate, String accountId) {
        Map<String, Date> calls = accountCalls.get(accountId);
        if (calls == null) {
            calls = new Map<String, Date>();
            accountCalls.put(accountId, calls);
        }
        calls.put(callId, callDate);
    }

    public Map<String, Map<String, Date>> getRelatedAccountEvents(List<String> accountIds, List<String> callIds) {
        Map<String, Map<String, Date>> result = new Map<String, Map<String, Date>>();
        String userId = this.getCalendarOwnerId();

        if (this.fields.size() > 0) {
			String stmt = 'Select ' + String.join(this.fields, ',') + ' from Call2_vod__c where Account_vod__c in :accountIds AND Id not in :callIds AND OwnerId != \'' + userId + '\' AND User_vod__c != \'' + userId + '\' AND Parent_Call_vod__c = null and ' + withinCallRangeStmtStr;
			List<Call2_vod__c> callList = Database.query(stmt);
            for (Call2_vod__c call : callList) {
                convertToAllDayCall(call);
                addCallToMap(result, call.Id, call.Call_Date_vod__c, call.Account_vod__c);
            }
		}

        return result;
    }

    public override List<VeevaCalendarEvent> getEventsForRecordIds(List<Id> recordIds) {
        List<String> queryFields = this.fields.clone();
        if (!queryFields.contains('Call_Datetime_vod__c')) {
            queryFields.add('Call_Datetime_vod__c');
        }
        String queryStmt = 'Select ' + String.join(queryFields, ',') + ' from Call2_vod__c' + ' where Id IN :recordIds OR Parent_Call_vod__c IN :recordIds';
        return this.convertToEvents(Database.query(queryStmt));
    }

    public static List<Call_Objective_vod__c> getCallObjectivesOutOfRange(Id callId, Date newDate) {
        // get/check permissions
        VeevaBaseObject callObjectiveObj = VeevaBaseObject.create('Call_Objective_vod__c');
        Set<String> fields = new Set<String>{'From_Date_vod__c', 'To_Date_vod__c', 'Call2_vod__c'};
        if (callObjectiveObj == null || callObjectiveObj.getAccessibleFields(fields).size() != fields.size()) {
            return new List<Call_Objective_vod__c>();
        }
        // check if newDate is outside the range of any of the queried call objectives
        return [SELECT From_Date_vod__c, To_Date_vod__c, Call2_vod__c FROM Call_Objective_vod__c WHERE Call2_vod__c = :callId AND (To_Date_vod__c < :newDate OR From_Date_vod__c > :newDate) AND Completed_Flag_vod__c != true];
    }
}