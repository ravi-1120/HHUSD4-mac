export default class CalendarEventType {
    translatedLabels;
    eventRecord;
    constructor(eventRecord, translatedLabels) {
        this.eventRecord = eventRecord;
        this.translatedLabels = translatedLabels;
    }
    getEventName() {
        let eventName = this.eventRecord.name;
        
        if (this.eventRecord.eventType === 'unassigned-presentation') {
            eventName = this.translatedLabels.unassignedPresentationLabel;
        } else if (this.eventRecord.eventType === 'unavailable-time') {
            eventName = this.translatedLabels.unavailableTimeLabel;
        } 
        return eventName;
    }
}