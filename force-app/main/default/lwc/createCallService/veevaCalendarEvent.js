export default class VeevaCalendarEvent {
    id;
    name;
    eventType;
    startDate;
    endDate;
    allDay;
    accountId;
    address;
    status;
    objectType;
    recordType;
    duration;
    eventDateTime;
    cls;

    durationUnit;
    draggable;
    resizable;

    constructor(classicEvent, eventType = 'call') {
        this.id = classicEvent.id;
        this.name = classicEvent.title;
        this.allDay = classicEvent.allDay;
        this.accountId = classicEvent.acctid;
        this.objectType = classicEvent.objType;
        this.eventType = eventType;
        if(classicEvent.address) {
            this.address = decodeURIComponent(classicEvent.address.replace(/\+/g, ' '));
        }
        this.status = classicEvent.planned ? 'Planned_vod' : 'Saved_vod';
        this.duration = parseInt(classicEvent['fld.Duration_vod__c'], 10) || 30;

        this.recordType = ' ';
        this.durationUnit = 'm';
        this.draggable = false; 
        this.resizable = false; 

        this._setEventTimes(classicEvent);
        this._setClassNames();
    }

    _setEventTimes(event) {
        const callDateTime = event['fld.Call_Datetime_vod__c'];
        const callDate = `${event['fld.Call_Date_vod__c']}T00:00:00`;

        const startTimestamp = Date.parse(callDateTime || callDate);
        const startDate = new Date(startTimestamp);
        const endDate = new Date(startDate.getTime());
        endDate.setMinutes(endDate.getMinutes() + this.duration);

        this.startDate = startDate;
        this.endDate = endDate;
    }

    _setClassNames() {
        const plannedFor = this.startDate < Date.now() ? 'past' : 'future';
        const status = this.status ? this.status.replaceAll(' ', '-').toLowerCase() : '';
        const eventClassList = new bryntum.calendar.DomClassList(); // eslint-disable-line no-undef
        eventClassList.add(status.concat('-', plannedFor, '-', this.eventType));
        eventClassList.add(status.concat('-', this.eventType));
        eventClassList.add(this.eventType);
        this.cls = eventClassList;
    }

    static getTempCallEvent(startDate, eventName, duration) {
        const endDate = new Date(startDate.getTime());
        endDate.setMinutes(endDate.getMinutes() + duration);

        const eventData = {
            name : eventName,
            startDate,
            endDate,
            allDay : false,
            duration,
            durationUnit : 'm',
            id : `_generatedt_${Math.random()}`, // must start with _generatedt_ for styling and disabling popovers
            objectType : 'Call2_vod__c',
            cls : ["temporary-event"],
            status : 'Planned_vod',
            recordType : ' ',
            draggable : false,
            resizable : false
        }
        return eventData
    }
}