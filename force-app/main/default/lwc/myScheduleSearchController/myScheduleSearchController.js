import VeevaPageController from 'c/veevaPageController';

export default class MyScheduleSearchController extends VeevaPageController {

    async createCall(call, eventInfo) {
        const eventView = MyScheduleSearchController.getEventView(eventInfo.view.type);
        const allDay = this._getAllDay();
        const body = {
            oType: eventView,
            event: 'new',
            ids: call.id,
            start: eventInfo.date.toISOString(),
            allDay,
            hastime: true
        }

        return this.dataSvc.sendRequest('POST', undefined, undefined, body, undefined);
    }

    async applyCallCycle(cycleIds, calendarMode, applyByWeek, clickDate) {
        const eventView = MyScheduleSearchController.getEventView(calendarMode);
        const allDay = this._getAllDay();
        const hasTime = allDay ? false : MyScheduleSearchController.hasTime(calendarMode);
        const body = {
            oType: eventView,
            event: 'new',
            cycleIds,
            start: clickDate.toISOString(),
            allDay,
            hastime: hasTime,
            srchAllCycles: applyByWeek,
            returnSuccessAndErrorInfo: true
        }

        return this.dataSvc.sendRequest('POST', undefined, undefined, body, undefined);
    }

    _getAllDay() {
        if(this.objectInfo.getFieldInfo('Call_Datetime_vod__c') && this.objectInfo.getFieldInfo('Call_Datetime_vod__c').createable) {
            return false;
        }
        return true;
    }

    static getEventView(type) {
        let eventView;
        if(type && type === 'month') {
            eventView = 'month';
        } else if(type && type === 'week') {
            eventView = 'agendaWeek';
        } else {
            eventView = 'agendaWeek';
        }
        return eventView;
    }

    static hasTime(type) {
        if(type && type === 'month') {
            return false;
        }
        return true;
    }
}