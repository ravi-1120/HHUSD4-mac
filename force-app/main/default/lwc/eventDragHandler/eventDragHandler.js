import CreateCallDataFormatter from 'c/createCallDataFormatter';

export default class EventDragHandler {
    static MS_IN_MINUTE = 60 * 1000;
    static MIN_DURATION = 30;

    static updateEventStoreRecord(dragEvent, eventStore, dragRecordBefore) {
        const { eventRecord: { data } } = dragEvent;

        data.duration = Math.max(data.duration, EventDragHandler.MIN_DURATION);
        let duration = Math.max(((data.endDate - data.startDate) / EventDragHandler.MS_IN_MINUTE), EventDragHandler.MIN_DURATION);
        if (dragEvent.type === 'dragmoveend' && dragRecordBefore?.duration < EventDragHandler.MIN_DURATION) { // handle events that were originally < 30 minutes long before moved
            duration = dragRecordBefore.duration;
            data.duration = duration;
        }
        data.endDate = new Date(data.startDate);
        data.endDate.setMinutes(data.startDate.getMinutes() + duration);

        const { recordId } = data;
        const record = eventStore.findRecord("id", recordId);
        return {record, duration};
    }

    static passesDragValidationsNoModal(eventRecord, drag, calendarMode, isResize, dragRecordBefore) {
        if (isResize && (!CreateCallDataFormatter.datesAreSameDay(dragRecordBefore.startDate, dragRecordBefore.endDate) || !CreateCallDataFormatter.datesAreSameDay(eventRecord.startDate, dragRecordBefore.startDate) || !CreateCallDataFormatter.datesAreSameDay(eventRecord.endDate, dragRecordBefore.startDate))) {
            return false; // disable resizing events across days
        }
        if (EventDragHandler.isCallCycleRecord(eventRecord)){
            return false;
        }
        if (!eventRecord || !drag || drag.targetElement.classList.contains("b-day-name-day") || drag.targetElement.classList.contains("b-day-name-date") || drag.targetElement.classList.contains("b-datepicker-cell-inner")) {
            return false; // prevent dragging to day labels/dates and the datepicker cells, which is allowed by default
        }
        if (eventRecord.fromSchedulerPane && (drag.targetElement.classList.contains("b-cal-event-bar-container") || drag.targetElement.classList.contains("b-cal-event") || drag.targetElement.classList.contains("b-event-name") || drag.targetElement.classList.contains("event-icon")) && calendarMode !== 'month') {
            return false; // prevent dragging to the all day header from scheduler pane
        }
        if ((drag.initialConfig?.itemElement && drag.targetElement && drag.initialConfig?.itemElement?.classList.contains("b-allday") !== (drag.targetElement?.classList.contains("b-cal-event-bar-container") || 
            drag.targetElement?.classList.contains("b-cal-cell-header"))) && calendarMode !== 'month') {
            return false; // do not allow calls to move to or from all day header
        }
        return true;
    }

    static checkBackDateLimitOnDrag( eventRecord, backdateLimit, dragRecordBefore) {
        const backdate = new Date();
        backdate.setDate(backdate.getDate() - backdateLimit);
        backdate.setHours(0, 0, 0, 0);

        if (eventRecord.objectType !== 'Event' && !CreateCallDataFormatter.datesAreSameDay(dragRecordBefore.startDate, eventRecord.startDate) && backdateLimit > -1 && eventRecord.startDate < backdate) {
            return false;
        }
        return true;
    }

    static revertEvent(updatedRecord, oldRecord, eventStore) {
        // revert event
        if (oldRecord?.id) {
            eventStore.remove(updatedRecord);
            eventStore.add(oldRecord);
        } 
    }

    static isCallCycleRecord(eventRecord) {
        return eventRecord?.data?.eventType === 'call-cycle-entry'; // disable dragging cce's on my schedule calendar, not manage calendar
    }
}