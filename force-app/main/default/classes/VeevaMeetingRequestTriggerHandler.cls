public without sharing class VeevaMeetingRequestTriggerHandler extends VeevaTriggerHandler {
    private static String FORMAT_DOES_NOT_EXIST = 'FORMAT_DOES_NOT_EXIST';
    private Map<String, Map<String, String>> messageMapByLanguage = new Map<String, Map<String, String>>();
    private Map<ID, User> userMap = new Map<ID, User>();
    private Map<ID, String> userDateFormatMap = new Map<ID, String>();
    private Map<ID, Sent_Email_vod__c> sentEmailMap = new Map<ID, Sent_Email_vod__c>();
    private String customNotificationTypeId = getCustomNotificationTypeId();
    private List<Meeting_Request_vod__c> oldRequests = new List<Meeting_Request_vod__c>();
    private List<Meeting_Request_vod__c> newRequests = new List<Meeting_Request_vod__c>();
    private Map<ID, Meeting_Request_vod__c> oldRequestsMap = new Map<ID, Meeting_Request_vod__c>();
    private Map<ID, Meeting_Request_vod__c> newRequestsMap = new Map<ID, Meeting_Request_vod__c>();
    private static Map<Id, Schema.RecordTypeInfo> RECORD_TYPE_ID_MAP = Schema.SObjectType.Meeting_Request_vod__c.getRecordTypeInfosById();
    private static Map<String, Schema.RecordTypeInfo> RECORD_TYPE_NAME_MAP = Schema.SObjectType.Meeting_Request_vod__c.getRecordTypeInfosByDeveloperName();

    protected override void preTrigger(List<SObject> triggerNew, List<SObject> triggerOld, Map<ID, SObject> triggerNewMap, Map<ID, SObject> triggerOldMap) {
        this.newRequests = (List<Meeting_Request_vod__c>) triggerNew;
        this.oldRequests = (List<Meeting_Request_vod__c>) triggerOld;
        this.newRequestsMap = (Map<ID, Meeting_Request_vod__c>) triggerNewMap;
        this.oldRequestsMap = (Map<ID, Meeting_Request_vod__c>) triggerOldMap;
    }
    
    protected override String sObjectType() {
        return 'Meeting_Request_vod__c';
    }

    protected override void beforeInsert() {
        vodMeetingRequestBeforeInsert();
    }

    protected override void beforeUpdate() {
        vodMeetingRequestBeforeUpdate();
    }

	protected override void afterInsert() {
        processMeetingRequests();
    }

    private void vodMeetingRequestBeforeInsert() {
        for (Meeting_Request_vod__c mr : newRequests) {
            String recordTypeName = mr.Record_Type_Name_vod__c;
            String recordTypeId = mr.RecordTypeId;
            if (String.isNotBlank(recordTypeName)) {
                setMeetingRequestRecordTypeByName(mr, recordTypeName);
            } else if (String.isNotBlank(recordTypeId)) {
                setMeetingRequestRecordTypeById(mr, recordTypeId);
            }
        }
    }

    private void vodMeetingRequestBeforeUpdate() {
        for (Meeting_Request_vod__c mr : newRequests) {
            String recordTypeName = mr.Record_Type_Name_vod__c;
            String recordTypeId = mr.RecordTypeId;
            Meeting_Request_vod__c oldMR = oldRequestsMap.get(mr.Id);
            if (recordTypeName != oldMR.Record_Type_Name_vod__c) {
                setMeetingRequestRecordTypeByName(mr, recordTypeName);
            } else if (recordTypeId != oldMR.RecordTypeId) {
                setMeetingRequestRecordTypeById(mr, recordTypeId);
            }
        }
    }

    private void setMeetingRequestRecordTypeByName(Meeting_Request_vod__c mr, String recordTypeName) {
        RecordTypeInfo recordType = RECORD_TYPE_NAME_MAP.get(recordTypeName);
        if (recordType != null) {
            mr.RecordTypeId = recordType.getRecordTypeId();
        }
    }

    private void setMeetingRequestRecordTypeById(Meeting_Request_vod__c mr, String recordTypeId) {
        RecordTypeInfo recordType = RECORD_TYPE_ID_MAP.get(recordTypeId);
        if (recordType != null) {
            mr.Record_Type_Name_vod__c = recordType.getDeveloperName();
        }
    }
    
    private void processMeetingRequests() {
        List<ID> requestsToProcess = new List<ID>();
        for (Meeting_Request_vod__c request : newRequests) {
            if (shouldCreateNotifications(request, oldRequestsMap.get(request.Id))) {
                requestsToProcess.add(request.Id);
			}
        }
        
        createNotifications(requestsToProcess);
    }
    
    private boolean shouldCreateNotifications(Meeting_Request_vod__c newRequest, Meeting_Request_vod__c oldRequest) {
        return newRequest.Status_vod__c == 'Requested_vod' && 
            (oldRequest == null || oldRequest.Status_vod__c != 'Requested_vod__c');
    }
    
    private Map<String, String> getVeevaMessages(String language) {
        Map<String, String> messageMap = messageMapByLanguage.get(language);
        if (messageMap == null) {
            Map<String, String> vms = populateVeevaMessagesForLanguage(language);
            messageMapByLanguage.put(language, vms);
            messageMap = vms;
        }
        return messageMap;
    }
    
    private Map<String, String> populateVeevaMessagesForLanguage(String language) {
        Map<String, String> messageMap = new Map<String, String>();
        for (Message_vod__c m : [SELECT Text_vod__c, Name 
                                 FROM Message_vod__c 
                                 WHERE Language_vod__c = :language AND Active_vod__c = true
                                  AND ((Category_vod__c = 'SCHEDULER' AND Name IN ('ALERT_TITLE', 'ALERT_TEXT'))
                                   OR (Category_vod__c = 'COMMON' AND Name IN ('MIN', 'IN_PERSON', 'VIDEO', 'PHONE')))]) {
        	messageMap.put(m.Name, m.Text_vod__c);                                
        }
        return messageMap;
    }
    
    private String getVeevaMessageWithDefault(String language, String name, String defaultVal) {
        Map<String, String> messages = getVeevaMessages(language);
        String message = messages.get(name);
        if (String.isBlank(message)) {
            if (language != 'en_US') {
                message = getVeevaMessageWithDefault('en_US', name, defaultVal);
            } else {
                message = defaultVal;
            }
        }
        return message;
    }
    
    private String getDateFormatForUser(String userId) {
        String userDateFormat = userDateFormatMap.get(userId);
        if (userDateFormat == null) {
            Veeva_Settings_vod__c veevaSettings = Veeva_Settings_vod__c.getInstance(userId);
            userDateFormat = veevaSettings.DATETIME_PATTERN_DISPLAY_vod__c;
            if (userDateFormat == null) {
                //prevent reprocessing of user that does not have a Datetime Format String
                userDateFormat = FORMAT_DOES_NOT_EXIST;
            }
            userDateFormatMap.put(userId, userDateFormat);
        }
        return userDateFormat;
    }
    
    private User getUserInfo(ID userId) {
        User user = userMap.get(userId);
        if (user == null) {
            User u = [SELECT LanguageLocaleKey, TimeZoneSidKey 
                      FROM User 
                      WHERE Id = :userId 
                      LIMIT 1];
            if (u != null) {
                userMap.put(userId, u);
                user = u;
			}
        }
        return user;
	}
    
    private String getInviteeName(Meeting_Request_vod__c mr) {
        return mr.Invitee_Display_Name_vod__c;
    }
    
    @TestVisible private String formatDateTime(DateTime dt, String timezone, String dateFormatString) {
        String defaultFormatString = 'yyyy-MM-dd HH:mm z';
        String formatString = dateFormatString;
        String formattedDate = '';
        if (dateFormatString == null || dateFormatString == FORMAT_DOES_NOT_EXIST) {
            formatString = defaultFormatString;
        }
        try {
            formattedDate = dt.format(formatString, timezone);
        } catch (System.StringException ex) {
            //if invalid format, use default
            formattedDate = dt.format(defaultFormatString, timezone);
        }
        
        return formattedDate;
    }
    
    
    @TestVisible private String createNotificationTitle(User user, String inviteeName) {
        String title = getVeevaMessageWithDefault(user.LanguageLocaleKey, 'ALERT_TITLE', 
                                                           '[Action Required] {0} has submitted a new Meeting Request');
        if (String.isNotBlank(inviteeName)) {
            title = title.replace('{0}', inviteeName);
        }
        return title;
	}
    
    @TestVisible private String createNotificationBody(User user, Meeting_Request_vod__c mr, String inviteeName, String dateFormatString) {
        String language = user.LanguageLocaleKey;
        String body = getVeevaMessageWithDefault(language, 'ALERT_TEXT', 
                                                 '{0} has requested a {1} {2} {3} meeting.\n\nDate and Time: {4}\n\nSchedule and respond as soon as possible');
        if (String.isNotBlank(inviteeName)) {
            body = body.replace('{0}', inviteeName);
        }
        if (mr.Duration_vod__c != null) {
            body = body.replace('{1}', mr.Duration_vod__c.format());
        } else {
            body = body.replace('{1}', '30');
        }
        
        body = body.replace('{2}', getVeevaMessageWithDefault(language, 'MIN', 'min'));
        
        String meetingTypeString = '';
        if (mr.Meeting_Type_vod__c == 'Face_to_face_vod') {
            meetingTypeString = getVeevaMessageWithDefault(language, 'IN_PERSON', 'In-Person');
        } else if (mr.Meeting_Type_vod__c == 'Phone_vod') {
            meetingTypeString = getVeevaMessageWithDefault(language, 'PHONE', 'Phone');
        } else if (mr.Meeting_Type_vod__c == 'Video_vod') {
            meetingTypeString = getVeevaMessageWithDefault(language, 'VIDEO', 'Video');
        } 
        
        if (meetingTypeString.equals('')) {
            //attempt to remove leading or trailing whitespace characters for better formatting with empty string
            //if target string is not found, then replace will happen with this priority
            body = body.replace(' {3}', meetingTypeString);
            body = body.replace('{3} ', meetingTypeString);
            body = body.replace('{3}', meetingTypeString);
        } else {
            body = body.replace('{3}', meetingTypeString);
        }
        
        if (mr.Start_Datetime_vod__c != null) {
            body = body.replace('{4}', formatDateTime(mr.Start_Datetime_vod__c, user.TimeZoneSidKey, dateFormatString));
        }
        
        return body;
	}
    
    private String getCustomNotificationTypeId() {
        String meetingRequestNotificationTypeId = '';
        for (CustomNotificationType c : [
                SELECT Id 
                FROM CustomNotificationType 
                WHERE DeveloperName='Meeting_Request_vod'
                LIMIT 1]) {
        	meetingRequestNotificationTypeId = c.Id;
        }
        return meetingRequestNotificationTypeId;
    }
    
    private void sendLightningNotification(String title, String body, Meeting_Request_vod__c mr, User notificationRecipient) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        
        notification.setTitle(title);
        notification.setBody(body);
        notification.setNotificationTypeId(customNotificationTypeId);
        String pageRef = '{type: \'standard__navItemPage\', attributes: {apiName: \'My_Schedule_vod\'}, state: {c__myScheduleDate: \'' + mr.Start_Datetime_vod__c + '\', c__focusedRecordId: \'' + mr.Id + '\', c__objectType: \'' + 'Meeting_Request_vod__c' + '\'}}';
        notification.setTargetPageRef(pageRef);

        try {
            notification.send(new Set<String>{notificationRecipient.Id});
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
    
    private void createNotifications(List<ID> meetingRequests) {
        if (String.isEmpty(customNotificationTypeId)) {
            //if there is no custom notification, then notification cannot be created
            return;
        }
		for (ID requestId : meetingRequests) {
			Meeting_Request_vod__c mr = newRequestsMap.get(requestId);
            
            User user;
            String dateFormatString;
            if (mr.Assignee_vod__c != null) {
                user = getUserInfo(mr.Assignee_vod__c);
                dateFormatString = getDateFormatForUser(mr.Assignee_vod__c);
            } else {
                user = getUserInfo(mr.OwnerId);
                dateFormatString = getDateFormatForUser(mr.OwnerId);
            }
            
            String inviteeName = getInviteeName(mr);
            String notificationTitle = createNotificationTitle(user, inviteeName);
            String notificationBody = createNotificationBody(user, mr, inviteeName, dateFormatString);
            sendLightningNotification(notificationTitle, notificationBody, mr, user);
        }
    }
}