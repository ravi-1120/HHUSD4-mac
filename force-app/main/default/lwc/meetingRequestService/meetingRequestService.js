import { updateRecord } from 'lightning/uiRecordApi';
import { getService } from 'c/veevaServiceFactory';
import { publish } from 'lightning/messageService';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import myScheduleCalendarEventChannel from '@salesforce/messageChannel/MySchedule_Calendar_Event__c';

export default class MeetingRequestService {
    messageContext;
    currentMeetingRequest;

    constructor(currentMeetingRequest, messageContext) {
        this.currentMeetingRequest = currentMeetingRequest;
        this.messageContext = messageContext;
        this.sessionService = getService('sessionSvc');
        this.dataSvc = getService('dataSvc');
    }

    static hasAcceptMeetingRequestPermissions(calendarObjectInfos) {
        const MEETING_REQUEST_ACCEPT_FLS_VALIDATION = ['Status_vod__c', 'Account_vod__c', 'Status_Last_Modified_DateTime_vod__c', 'Call2_vod__c'];
        const meetingRequestFieldValid = this._fieldsHaveUpdateFLS(MEETING_REQUEST_ACCEPT_FLS_VALIDATION, calendarObjectInfos);
        const callMeetingRequestObjectValid = calendarObjectInfos?.Call2_vod__c?.fields?.Meeting_Request_vod__c?.updateable;
        return meetingRequestFieldValid && callMeetingRequestObjectValid;
    }

    static hasRemoveMeetingRequestPermissions(calendarObjectInfos) {
        const MEETING_REQUEST_REMOVE_FLS_VALIDATION = ['Is_Hidden_vod__c', 'Decline_Reason_vod__c'];
        return this._fieldsHaveUpdateFLS(MEETING_REQUEST_REMOVE_FLS_VALIDATION, calendarObjectInfos);
    }

    static hasDeclineMeetingRequestPermissions(calendarObjectInfos) {
        const MEETING_REQUEST_DECLINE_FLS_VALIDATION = ['Status_vod__c', 'Status_Last_Modified_DateTime_vod__c', 'Decline_Reason_vod__c'];

        return this._fieldsHaveUpdateFLS(MEETING_REQUEST_DECLINE_FLS_VALIDATION, calendarObjectInfos);
    }

    static _fieldsHaveUpdateFLS(fields, calendarObjectInfos) {
        return fields.every(fieldName =>
            calendarObjectInfos?.Meeting_Request_vod__c?.fields?.[fieldName] && calendarObjectInfos?.Meeting_Request_vod__c?.fields?.[fieldName]?.updateable
        );
    }

    async updateAcceptMeetingRequest(call) {
        if (call?.event?.id) {
            // eslint-disable-next-line no-undef
            const statusLastModifiedDate = bryntum.calendar.TimeZoneHelper.fromTimeZone(new Date(), TIME_ZONE);
            // update meeting request
            await updateRecord({
                fields: {
                    Id: this.currentMeetingRequest.id,
                    Status_vod__c: 'Accepted_vod',
                    Call2_vod__c: call.event.id,
                    Status_Last_Modified_DateTime_vod__c: statusLastModifiedDate
                }
            });
            // update call
            await updateRecord({
                fields: {
                    Id: call.event.id,
                    Meeting_Request_vod__c: this.currentMeetingRequest.id,
                    Call_Channel_vod__c: this.currentMeetingRequest.meetingType,
                    Phone_vod__c: this.currentMeetingRequest.phone
                }
            });
            
            this.sendAcceptEmail();
        } else {
            const eventMsg = {event: {id: this.currentMeetingRequest.id, objectType: 'Meeting_Request_vod__c'}, isTemporary: false, needsQueried: true};
            publish(this.messageContext, myScheduleCalendarEventChannel, eventMsg);
        }
    }

    async updateRemoveMeetingRequest(reason) {
        const updateFields = {
            Id: this.currentMeetingRequest.id,
            Is_Hidden_vod__c: true,
            Decline_Reason_vod__c: reason
        };
        await updateRecord({
            fields: updateFields
        });

        // remove meeting from my schedule
        publish(this.messageContext, myScheduleCalendarEventChannel, {isTemporary: false, temporaryEventId: this.currentMeetingRequest.id});
    }

    async updateDeclineMeetingRequest(reason) {
        // eslint-disable-next-line no-undef
        const statusLastModifiedDate = bryntum.calendar.TimeZoneHelper.fromTimeZone(new Date(), TIME_ZONE);
        const updateFields = {
            Id: this.currentMeetingRequest.id,
            Status_vod__c: 'Declined_vod',
            Status_Last_Modified_DateTime_vod__c: statusLastModifiedDate,
            Decline_Reason_vod__c: reason
        };
        await updateRecord({
            fields: updateFields
        });

        // update meeting request styling  in my schedule
        const eventMsg = {event: {id: this.currentMeetingRequest.id, objectType: 'Meeting_Request_vod__c'}, isTemporary: false, needsQueried: true};
        publish(this.messageContext, myScheduleCalendarEventChannel, eventMsg);
    }

    async sendAcceptEmail() {
        const request = {};
        const vodInfo = await this.sessionService.getVodInfo();
        request.url = vodInfo.veevaServer;
        request.url += `/api/v1/syncapis/remote-meeting-email?meetingRequestId=${this.currentMeetingRequest.id}`;
        request.headers = { sfSession: vodInfo.sfSession, sfEndpoint: vodInfo.sfEndpoint};
        request.method = "POST";
        await this.dataSvc.request(request);
    }
}