public inherited sharing class VeevaCalendarUpdateCallService {
    public static Map<String, String> updateCallTime(Id recordId, Datetime startDate, Integer duration, Boolean allDay, Boolean hasDateTimePermission, Boolean updateRemoteMeeting) {
        return VeevaCalendarUpdateCallService.updateCallTime(recordId, startDate, duration, allDay, hasDateTimePermission, updateRemoteMeeting, new VeevaMSTeamsService(), new VeevaEngageService());
    }

    @TestVisible
    private static Map<String, String> updateCallTime(Id recordId, Datetime startDate, Integer duration, Boolean allDay, Boolean hasDateTimePermission, Boolean updateRemoteMeeting, VeevaMSTeamsService msTeamsService, VeevaEngageService engageService) {
        // if user does not have FLS for the Call Datetime field, we return a date string without the time component via formatAllDay
        String updatedEventDateTime = hasDateTimePermission && !allDay ? VeevaCalendarEvent.formatHourly(startDate, duration) : VeevaCalendarEvent.formatAllDay(Date.valueOf(startDate), duration);
        Boolean canUpdateRemoteMeetingOnReschedule =  canUpdateRemoteMeetingOnReschedule();
        Boolean canUpdateMSTeamsRemoteMeetingOnReschedule = canUpdateMSTeamsRemoteMeetingOnReschedule();

        Map<String, String> result = new Map<String, String>();
        List<Id> msTeamsRemoteMeetingIds = new List<Id>();
        result.put('data', updatedEventDateTime);

        try {
            Id remoteMeetingId;
            Boolean engageUpdateResponseStatus = false;
            String remoteMeetingType;
            List<Call2_vod__c> toUpdateCalls = [SELECT Id, Call_Datetime_vod__c, Remote_Meeting_vod__c, Remote_Meeting_Type_vod__c, MS_Teams_Remote_Meeting_vod__c, Call_Date_vod__c, Duration_vod__c FROM Call2_vod__c WHERE Id = :recordId or Parent_Call_vod__c = :recordId];            
            for (Call2_vod__c call : toUpdateCalls) {
                if (!hasDateTimePermission && call.Call_Datetime_vod__c != null) {
                    result.put('error', 'Can not update calls with populated Call_Datetime_vod__c and missing Call_Datetime_vod__c permissions');
                    return result;
                }
                if (canUpdateRemoteMeetingOnReschedule && String.isNotBlank(call.Remote_Meeting_vod__c) && remoteMeetingId == null) {
                    remoteMeetingId = call.Remote_Meeting_vod__c;
                }
                if (canUpdateMSTeamsRemoteMeetingOnReschedule && call.MS_Teams_Remote_Meeting_vod__c != null) {
                    msTeamsRemoteMeetingIds.add(call.MS_Teams_Remote_Meeting_vod__c);
                }
                remoteMeetingType = call.Remote_Meeting_Type_vod__c;
            }
            result.put('remoteMeetingType', remoteMeetingType);
            if (updateRemoteMeeting && remoteMeetingId != null) {
                engageUpdateResponseStatus = engageService.updateEngageMeetingTimes(remoteMeetingId, startDate, duration);
            }
            updateMsTeamsRemoteMeetingRecords(msTeamsRemoteMeetingIds, startDate, duration, msTeamsService, result);
            if (updateRemoteMeeting && remoteMeetingId != null) {
                engageService.updateEngageRemoteMeeting(remoteMeetingId, engageUpdateResponseStatus, result);
            }
            updateCallRecordDatetime(recordId, startDate, duration, hasDateTimePermission, toUpdateCalls);
            updateCallObjectives(recordId, startDate.date());
        } catch (DmlException e) {
            result.put('error', e.getDmlMessage(0));
        }
        return result;
    }

    private static void updateCallObjectives(Id recordId, Date startDate) {
        List<Call_Objective_vod__c> callObjectives = VeevaCalendarCallData.getCallObjectivesOutOfRange(recordId, startDate);
        if (!callObjectives.isEmpty()) {
            for (Call_Objective_vod__c objective : callObjectives) {
                objective.Call2_vod__c = null;
            }
            update callObjectives;
        }
    }

    private static void updateCallRecordDatetime(Id recordId, Datetime startDate, Integer duration, Boolean hasDateTimePermission, List<Call2_vod__c> updatedCalls) {
        for (Call2_vod__c call : updatedCalls) {
            if (hasDateTimePermission && call.Call_Datetime_vod__c != null) {
                call.Call_Datetime_vod__c = startDate;
            }
            call.Call_Date_vod__c = Date.valueOf(startDate);
            call.Duration_vod__c = duration;
        }
        update updatedCalls;
    }

    @TestVisible
    private static void updateMSTeamsRemoteMeetingRecords(List<Id> msTeamsRemoteMeetingIds, Datetime startDate, Integer duration, VeevaMSTeamsService msTeamsService, Map<String, String> result) {
        if (!msTeamsRemoteMeetingIds.isEmpty()) {
            List<Remote_Meeting_vod__c> remoteMeetings = [SELECT Id, Scheduled_DateTime_vod__c, Scheduled_vod__c, VExternal_id_vod__c, Meeting_Name_vod__c from Remote_Meeting_vod__c WHERE Id IN :msTeamsRemoteMeetingIds];
            for (Remote_Meeting_vod__c remoteMeeting : remoteMeetings) {
                if (msTeamsService.updateMSTeamsRemoteMeeting(remoteMeeting, startDate, duration)) {
                    remoteMeeting.Scheduled_DateTime_vod__c = Datetime.now();
                    remoteMeeting.Scheduled_vod__c = true;
                    result.put('msTeamsRemoteMeeting', 'success');
                } else {
                    remoteMeeting.Scheduled_DateTime_vod__c = null;
                    remoteMeeting.Scheduled_vod__c = false;
                    result.put('msTeamsRemoteMeeting', 'error');
                }
            }
            update remoteMeetings;
        }
    }

    private static Boolean canUpdateMSTeamsRemoteMeetingOnReschedule() {
        Boolean hasRemoteCallDescObj = Schema.SObjectType.Call2_vod__c.fields?.getMap()?.get('MS_Teams_Remote_Meeting_vod__c')?.getDescribe()?.isUpdateable();
        Boolean hasRemoteCallTypeDescObj = Schema.SObjectType.Call2_vod__c.fields?.getMap()?.get('Remote_Meeting_Type_vod__c')?.getDescribe() != null;
        Boolean meetingNameAccessible = VeevaBaseObject.create('Remote_Meeting_vod__c')?.getAccessibleField('Meeting_Name_vod__c', false, false) != null;

        Boolean hasRemoteScheduledDateDescObj = Schema.SObjectType.Remote_Meeting_vod__c.fields?.getMap()?.get('Scheduled_DateTime_vod__c')?.getDescribe()?.isUpdateable();
        Boolean hasRemoteScheduledDescObj = Schema.SObjectType.Remote_Meeting_vod__c.fields?.getMap()?.get('Scheduled_vod__c')?.getDescribe()?.isUpdateable();
        return hasRemoteCallDescObj && hasRemoteCallTypeDescObj && meetingNameAccessible && hasRemoteScheduledDateDescObj && hasRemoteScheduledDescObj;
    }

    private static Boolean canUpdateRemoteMeetingOnReschedule() {
        Boolean hasRemoteCallDescObj = Schema.SObjectType.Call2_vod__c.fields?.getMap()?.get('Remote_Meeting_vod__c')?.getDescribe()?.isUpdateable();
        Boolean hasRemoteScheduledDateDescObj = Schema.SObjectType.Remote_Meeting_vod__c.fields?.getMap()?.get('Scheduled_DateTime_vod__c')?.getDescribe()?.isUpdateable();
        Boolean hasRemoteScheduledDescObj = Schema.SObjectType.Remote_Meeting_vod__c.fields?.getMap()?.get('Scheduled_vod__c')?.getDescribe()?.isUpdateable();
        return hasRemoteCallDescObj && hasRemoteScheduledDateDescObj && hasRemoteScheduledDescObj;
    }
}