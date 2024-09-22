import TIME_ZONE from '@salesforce/i18n/timeZone';

export default class CreateCallDataFormatter {
    static MS_IN_MIN = 60000;
    static CALENDAR_INCREMENT = 15;
    static CALL_CREATION_MIN_INCREMENT = 30;

    static _getMinutesToNextIncrement(newCallStartDate, existingCallStartDate, existingCallDuration) {
        const endDateTime = new Date(existingCallStartDate.getTime() + ((existingCallDuration ?? CreateCallDataFormatter.CALL_CREATION_MIN_INCREMENT) * CreateCallDataFormatter.MS_IN_MIN));
        if (newCallStartDate.getTime() === existingCallStartDate.getTime() || (newCallStartDate > existingCallStartDate && newCallStartDate < endDateTime)) {
            const callTimeDiff = Math.floor((endDateTime.getTime() - newCallStartDate.getTime()) / CreateCallDataFormatter.MS_IN_MIN);
            const numIncrements = Math.floor(callTimeDiff / CreateCallDataFormatter.CALL_CREATION_MIN_INCREMENT);
            const additionalIncrements = callTimeDiff % CreateCallDataFormatter.CALL_CREATION_MIN_INCREMENT === 0 ? 0 : 1; // if min difference is not 0 or 30, add additional 30min to new call start
            return (numIncrements + additionalIncrements) * CreateCallDataFormatter.CALL_CREATION_MIN_INCREMENT;
        }
        return 0;
    }
    static adjustStartTime(info, adjustTimeZone = true) {
        // eslint-disable-next-line no-undef
        let adjustedDate = bryntum.calendar.TimeZoneHelper.toTimeZone(info.date, info.orgTimeZone);
        const difference = info.date.getTime() - adjustedDate.getTime();
        if(info.view === 'month' || info.allDay) {
            adjustedDate.setHours(8);
            if (info.dayCellEvents.length > 0) {
                info.dayCellEvents.filter(event => event.eventType === 'call' && CreateCallDataFormatter.datesAreSameDay(event.startDate, new Date(event.startDate.getTime() + event.duration * this.MS_IN_MIN))).forEach(event => {                    
                    const timeChange = CreateCallDataFormatter._getMinutesToNextIncrement(adjustedDate, event.startDate, event.duration);
                    adjustedDate = new Date(adjustedDate.getTime() + (timeChange * CreateCallDataFormatter.MS_IN_MIN));
                });
            }
        } else if ((info.view === 'week' || info.view === 'day') && 
            adjustedDate.getMinutes() % CreateCallDataFormatter.CALL_CREATION_MIN_INCREMENT === CreateCallDataFormatter.CALENDAR_INCREMENT) {
            adjustedDate.setMinutes(adjustedDate.getMinutes() - CreateCallDataFormatter.CALENDAR_INCREMENT);
        }

        if (!adjustTimeZone) { 
            adjustedDate = new Date(adjustedDate.getTime() + difference);
        }
        return adjustedDate.toISOString();
    }

    static datesAreSameDay(d1, d2) {
        return d1 != null && d2 != null && d1.getDate() === d2.getDate() && d1.getMonth() === d2.getMonth() && d1.getFullYear() === d2.getFullYear();
    }

    static processDataForCreateCall(startDate, sameDayEvents, allDay, duration, view, allowedCallRecordTypes, callBackdateLimit, callCycleId = '') {
        // eslint-disable-next-line no-undef
        const adjustedDate = bryntum.calendar.TimeZoneHelper.fromTimeZone(startDate, TIME_ZONE);
        
        const callInfo = {
            view,
            allowedCallRecordTypeSettings: allowedCallRecordTypes,
            backdateLimit: callBackdateLimit,
            orgTimeZone: TIME_ZONE,
            date: adjustedDate,
            dateStr: adjustedDate.toGMTString(),
            dayCellEvents: sameDayEvents,
            allDay,
            callCycleId,
            duration
        }
        return callInfo;
    }
}