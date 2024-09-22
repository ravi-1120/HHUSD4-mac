import { VeevaDateHelper } from 'c/veevaLocalizationHelper';
import getCallCycleCalendarEventModel from './callCycleCalendarEventModel';

async function getCallCycleEventStore(store, days) {
    // eslint-disable-next-line no-undef
    const eventStore = new bryntum.calendar.EventStore({
        modelClass: getCallCycleCalendarEventModel(),
    });
    if (store) {
        Object.values(store).forEach((day) => {
            Object.values(day).forEach((dayValues) => {
                Object.values(dayValues?.entries).forEach((dayEntryValues) => {
                    const event = {};
                    event.resourceId = dayEntryValues?.Week_vod__c;
                    event.week = dayEntryValues?.Week_vod__c;
                    event.day = dayEntryValues?.Day_of_Week_vod__c;
                    event.dayTitle = dayEntryValues?.Day_Title_vod__c;
                    event.account = dayEntryValues?.Account_vod__r?.Formatted_Name_vod__c;
                    event.accountId = dayEntryValues?.Account_vod__r?.Id;
                    event.startTimeStr = dayEntryValues?.Start_Time_vod__c;
                    event.duration = dayEntryValues?.Duration_vod__c;
                    event.callCycleId = dayEntryValues?.Id;
                    event.id = dayEntryValues?.Id;
                    event.recordId = dayEntryValues?.Id;
                    event.startDate = getEventDate(dayEntryValues, days);
                    event.cls = 'call-cycle-calendar-entry';
                    event.eventType = 'call-cycle-calendar-entry';
                    eventStore.add(event);
    
                });
            });
        });
    }
    
    return eventStore;
}

function updateCallCycleFrontEndProperties(data) { 
    data.forEach((event) => {
        // eslint-disable-next-line no-undef
        const eventClassList = new bryntum.calendar.DomClassList();
        eventClassList.add('call-cycle-calendar-entry');
        event.cls = eventClassList;

        event.draggable = true;
        event.resizable = true;
    });
}

function getEventDate(callCycleEntry, days) {
    const index = days.indexOf(callCycleEntry?.Day_of_Week_vod__c);
    const resultDate  = VeevaDateHelper.getDateForWeekDay(new Date(), index, '');
    return new Date(resultDate.toDateString().concat(" ", callCycleEntry?.Start_Time_vod__c));
}

function addCallCycleEventToStore(event, store, days) {
    const callCycleEvent = JSON.parse(JSON.stringify(event));
    callCycleEvent.startTime = new Date(callCycleEvent.date).toLocaleTimeString([], {timeStyle: 'short'});
    const eventDate = VeevaDateHelper.getDateForWeekDay(new Date(), days.indexOf(callCycleEvent.day));
    callCycleEvent.startDate = new Date(eventDate.toDateString().concat(" ", callCycleEvent.startTime));
    updateCallCycleFrontEndProperties([callCycleEvent]);
    store.add(callCycleEvent);
}

export { getCallCycleEventStore, updateCallCycleFrontEndProperties, addCallCycleEventToStore }