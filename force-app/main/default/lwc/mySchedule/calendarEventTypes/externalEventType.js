import CalendarEventType from "./calendarEventType";

export default class ExternalEventType extends CalendarEventType {
    getEventName() {
        let eventName = this.eventRecord.name;
        
        if (this.eventRecord.eventType === 'external-event') {
            const {sensitivity} = this.eventRecord;
            if (sensitivity === 'PRIVATE') {
                eventName = this.translatedLabels.privateLabel;
            } else if (eventName === '') {
                eventName = this.translatedLabels.noSubjectLabel;
            }
        }
        return eventName;
    }
}