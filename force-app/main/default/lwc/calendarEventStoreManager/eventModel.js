let eventModel;

export default function getEventModel() {
    // eslint-disable-next-line no-undef
    eventModel = class MyScheduleEventModel extends bryntum.calendar.EventModel {
        static get fields() {
            return [
                {name: 'eventType', type: 'string'},
                {name: 'accountUrl', type: 'string'},
                {name: 'accountId', type: 'string'},
                {name: 'address', type: 'string'},
                {name: 'status', type: 'string'},
                {name: 'statusLabel', type: 'string'},
                {name: 'acctIdentifier', type: 'string'},
                {name: 'callChannel', type: 'string'},
                {name: 'callChannelLabel', type: 'string'},
                {name: 'popoverCallChannelText', type: 'string'},
                {name: 'recordType', type: 'string'},
                {name: 'objectType', type: 'string'},
                {name: 'programType', type: 'string'},
                {name: 'medicalEventType', type: 'string'},
                {name: 'location', type: 'string'},
                {name: 'parentAccount', type: 'string'},
                {name: 'owner', type: 'string'},
                {name: 'ownerUrl', type: 'string'},
                {name: 'ownerId', type: 'string'},
                {name: 'duration', type: 'number'},
                {name: 'childCallNumber', type: 'number'},
                {name: 'isSigned', type: 'boolean'},
                {name: 'hasSampleCard', type: 'boolean'},
                {name: 'hasUnscheduledRemoteMeeting', type: 'boolean'},
                {name: 'uninvitedRemoteAttendeeNumber', type: 'number'},
                {name: 'remoteAttendeeNumber', type: 'number'},
                {name: 'datesConflict', type: 'boolean'},
                {name: 'childrenEvents', type: 'array'},
                {name: 'eventDateTime', type: 'string'},
                {name: 'viewedSlides', type: 'array'},
                {name: 'meetingTypeLabel', type: 'string'},
                {name: 'meetingType', type: 'string'},
                {name: 'phone', type: 'string'},
                {name: 'emEventId', type: 'string'},
                {name: 'unavailable', type: 'boolean'},
                {name: 'externalCalendarId', type: 'string'},
                {name: 'childAccountId', type: 'string'},
                {name: 'draggable', type: 'boolean'},
                {name: 'resizable', type: 'boolean'},
                {name: 'durationUnit', type: 'string'},
                {name: 'fromSchedulerPane', type: 'boolean'},
                {name: 'callCycleId', type: 'string'},
                {name: 'recordId', type: 'string'}, // at the moment this field is only used for rescheduling; any event that is placed in the calendar should be refered to by its "id" field
            ]
        }

        static get defaults() {
            return {
                draggable : false,
                resizable: false,
                durationUnit: 'm'
            };
        }
    }
    return eventModel;
}