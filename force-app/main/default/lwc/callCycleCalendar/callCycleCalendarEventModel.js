let callCycleCalendarEventModel;
export default function getCallCycleCalendarEventModel() {
    // eslint-disable-next-line no-undef
    callCycleCalendarEventModel = class CallCycleCalendarEventModel extends bryntum.calendar.EventModel {
        static get fields() {
            return [
                {name: 'week', type: 'number'},
                {name: 'duration', type: 'number'},
                {name: 'account', type: 'string'},
                {name: 'callCycleId', type: 'string'},
                {name: 'day', type: 'string'},
                {name: 'dayTitle', type: 'string'},
                {name: 'accountId', type: 'string'},
                {name: 'startTimeStr', type: 'string'},
                {name: 'startDate', type: 'date'},
                {name: 'recordId', type: 'string'},
                {name: 'eventType', type: 'string'},
                {name: 'deleted', type: 'boolean'},
            ]
        }

        static get defaults() {
            return {
                durationUnit: 'm',
                deleted: false
            };
        }
    }
    return callCycleCalendarEventModel;
}