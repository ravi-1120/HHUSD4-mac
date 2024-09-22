import getCallDataInRange from '@salesforce/apex/VeevaMyScheduleController.getCallDataInRange';
import getTimeOffTerritoryDataInRange from '@salesforce/apex/VeevaMyScheduleController.getTimeOffTerritoryDataInRange';
import getMedicalEventDataInRange from '@salesforce/apex/VeevaMyScheduleController.getMedicalEventDataInRange';
import getCalendarEntryDataInRange from '@salesforce/apex/VeevaMyScheduleController.getCalendarEntryDataInRange';
import getUnassignedPresentationDataInRange from '@salesforce/apex/VeevaMyScheduleController.getUnassignedPresentationDataInRange';
import getUnavailableTimeDataInRange from '@salesforce/apex/VeevaMyScheduleController.getUnavailableTimeDataInRange';
import getMeetingRequestDataInRange from '@salesforce/apex/VeevaMyScheduleController.getMeetingRequestDataInRange';
import getExternalEventDataInRange from '@salesforce/apex/VeevaMyScheduleController.getExternalEventDataInRange';
import getCalendarEvents from '@salesforce/apex/VeevaMyScheduleController.getCalendarEvents';
import USER_ID from '@salesforce/user/Id';
import getEventModel from './eventModel';


export default class CalendarEventStore {
    constructor({weekendDays=[6,0], shouldFetchExternalEvents=false, callsUpdateable=true, eventsUpdateable=true, eventStore=null, initialRange}) {
        this.weekendDays = weekendDays;
        this.shouldFetchExternalEvents = shouldFetchExternalEvents;
        this.callsUpdateable = callsUpdateable;
        this.eventsUpdateable = eventsUpdateable;

        if (eventStore) {
            this.eventStore = eventStore;
        } else {
            const eventModel = getEventModel();
            // eslint-disable-next-line no-undef
            this.eventStore = new bryntum.calendar.EventStore({
                modelClass: eventModel,
            });
            this.getScheduleDataByType(initialRange.startDate, initialRange.endDate);
        }
        this.eventStore.reapplyFilterOnAdd = true;
    }

    getScheduleDataByType(startDate, endDate, backendId = USER_ID) {
        if (!this.eventStore) {
            return;
        }
        const dateRange = { 'start' : CalendarEventStore.formatParseableDatetime(startDate), 'end' : CalendarEventStore.formatParseableDatetime(endDate) };
        this.getScheduleDataForEventType({ fn: getCallDataInRange, dateRange, eventType: "calls", userId: backendId });
        this.getScheduleDataForEventType({ fn: getTimeOffTerritoryDataInRange, dateRange, eventType: "time off territories", userId: backendId });
        this.getScheduleDataForEventType({ fn: getMedicalEventDataInRange, dateRange, eventType: "medical events", userId: backendId });
        this.getScheduleDataForEventType({ fn: getCalendarEntryDataInRange, dateRange, eventType: "calendar entries", userId: backendId });
        this.getScheduleDataForEventType({ fn: getUnassignedPresentationDataInRange, dateRange, eventType: "unassigned presentations", userId: backendId });
        this.getScheduleDataForEventType({ fn: getUnavailableTimeDataInRange, dateRange, eventType: "unavailable times", userId: backendId });
        this.getScheduleDataForEventType({ fn: getMeetingRequestDataInRange, dateRange, eventType: "meeting requests", userId: backendId });
        if ((this.shouldFetchExternalEvents && USER_ID === backendId) || (USER_ID !== backendId && this.displayExternalCalendarsForManagers === 1)) {
            this.getScheduleDataForEventType({ fn: getExternalEventDataInRange, dateRange, eventType: "external events", userId: backendId });
        }
    }

    _getUniqueEvents(eventData, dateRange) {
        const {objectType} = eventData[0];
    
        const start = new Date(dateRange.start);
        const end = new Date(dateRange.end);
        let presentIds = this.eventStore.map(e=>e).filter(e => e.startDate < end && e.endDate >= start && e.objectType === objectType).map(e => e.id);
        if (objectType === 'External_Calendar_Event_vod__c') {
            const externalEventIds = this.eventStore.resourceStore?.assignmentStore.records.filter(x => x.event?.eventType === 'external-event')?.map(x => x.event?.id) || [];
            presentIds = presentIds.concat(externalEventIds);
        }
        return eventData.filter(e => !presentIds.includes(e.id));
    }

    async getScheduleDataForEventType({fn, dateRange, eventType = '', uniqueOnly = true, userId = USER_ID}) {
        try {
            const eventData = await fn({ currentStart: dateRange.start, currentEnd: dateRange.end, weekendDays: this.weekendDays, userId });
            if (eventData?.length > 0 && uniqueOnly) {
                // check if our query obtained an event that's already present in our calendar - this has the potential to "confuse" the calendar and mess up spacing for events.
                const newCalendarEvents = this._getUniqueEvents(eventData, dateRange);
                CalendarEventStore.addFrontEndProperties(newCalendarEvents, this.callsUpdateable, this.eventsUpdateable, userId);
                this.eventStore.add(newCalendarEvents);
            } else if (eventData?.length > 0) {
                CalendarEventStore.addFrontEndProperties(eventData, this.callsUpdateable, this.eventsUpdateable, userId);
                this.eventStore.remove(eventData.map(event => event.id));
                this.eventStore.add(eventData);
            }
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error(`Failed to receive records for ${eventType} with the following error: ${e?.body?.message || e}`);
        }
    }

    async updateScheduleDataForEvent(recordId, objectType) {
        try {
            const eventData = await getCalendarEvents({ recordIds: [recordId], objectType, weekendDays: this.weekendDays });
            CalendarEventStore.addFrontEndProperties(eventData, this.callsUpdateable, this.eventsUpdateable);
            this.eventStore.remove(eventData.map(event => event.id));
            this.eventStore.add(eventData);
        } catch (e) {
            // eslint-disable-next-line no-console
            console.error(`Failed to receive record for ${recordId} with the following error: ${e?.body?.message || e}`);
        }
    }    

    async refreshEventType(objectApiName, start, end) {
        switch (objectApiName) {
            case 'Call2_vod__c':
                return this.getScheduleDataForEventType({ fn: getCallDataInRange, dateRange: {start, end}, eventType: "calls", uniqueOnly: false });
            case 'Event':
                return this.getScheduleDataForEventType({ fn: getCalendarEntryDataInRange, dateRange: {start, end}, eventType: "calendar entries", uniqueOnly: false });
            case 'External_Calendar_Event_vod__c':
                return this.getScheduleDataForEventType({ fn: getExternalEventDataInRange, dateRange: {start, end}, eventType: "external events" });
            default:
                return null;
        }
    }


    static formatParseableDatetime(dateTime) {
        return new Date(dateTime).toISOString().replace('T', ' ').replace( /\.\d\d\dZ/,"");
    }

    static addFrontEndProperties(data, callsUpdateable, eventsUpdateable, userId=USER_ID) {
        const isSubordinateCalendar = userId !== USER_ID;
        const canDragAndDrop = !isSubordinateCalendar && ((data[0]?.objectType === 'Event' && eventsUpdateable) || (data[0]?.objectType === 'Call2_vod__c' && callsUpdateable));
        data.forEach((event) => {
            const eventDate = event.startDate instanceof Date ? event.startDate : Date.parse(event.startDate.replaceAll('-', '/'));
            const plannedFor = eventDate < Date.now() ? 'past' : 'future';
            const status = event.status ? event.status.replaceAll(' ', '-').toLowerCase() : '';
            // eslint-disable-next-line no-undef
            const eventClassList = new bryntum.calendar.DomClassList();
            eventClassList.add(status.concat('-', plannedFor, '-', event.eventType));
            eventClassList.add(status.concat('-', event.eventType));
            eventClassList.add(event.eventType);
            if (!event.resourceId) {
                event.resourceId = userId;
            }
            if (isSubordinateCalendar) {
                eventClassList.add('separate-user-calendar-event');
            } else if (event.eventType === 'external-event') {
                event.resourceId = event.externalCalendarId;
                eventClassList.add(`${event.externalCalendarId  }-event`);
            }
            event.cls = eventClassList;

            if (!canDragAndDrop) {
                event.draggable = false;
                event.resizable = false;
            } else {
                event.recordId = event.id; // assign id to a separate field that bryntum will never modify
            }
        });
    }

    static getEmptyEventStore() {
        const eventModel = getEventModel();
        // eslint-disable-next-line no-undef
        const eventStore = new bryntum.calendar.EventStore({
            modelClass: eventModel,
        });
        eventStore.reapplyFilterOnAdd = true; // workaround for most cases where Bryntum does not respect resource filter on page load
        return eventStore;
    }

}