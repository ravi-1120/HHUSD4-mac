import CalendarEventType from './calendarEventType';
import ExternalEventType from './externalEventType';

export default class CalendarEventTypeFactory {
    static getEventType(eventRecord, translatedLabels) {
        switch (eventRecord.objectType) {
            case 'External_Calendar_Event_vod__c': 
                return new ExternalEventType(eventRecord, translatedLabels);
            default:
                return new CalendarEventType(eventRecord, translatedLabels);
        }
    }
}