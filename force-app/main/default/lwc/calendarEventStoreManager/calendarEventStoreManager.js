import USER_ID from '@salesforce/user/Id';
import FIRSTDAYOFWEEK from '@salesforce/i18n/firstDayOfWeek';
import VisitedDatesTracker from 'c/visitedDatesTracker';
import CalendarEventStore from './calendarEventStore';


export default class CalendarEventStoreManager {
    visitedDatesByUser;
    currentlyDisplayedUserId;
    subordinateUserId;
    _callScheduleConflictThreshold;

    constructor({weekendDays, shouldFetchExternalEvents, callsUpdateable, eventsUpdateable, callScheduleConflictThreshold=2, eventStore}) {
        this.currentlyDisplayedUserId = USER_ID;
        this._callScheduleConflictThreshold = callScheduleConflictThreshold;
        this._initializeVisitedDatesByUser();
        this.calendarEventStore = new CalendarEventStore({weekendDays, shouldFetchExternalEvents, callsUpdateable, eventsUpdateable, eventStore, initialRange: this.ownerVisitedDatesTracker.getCurrentRange()});
    }

    async loadCalendarDataForDate(date, agendaTitle='') {
        const newDate = new Date(date);
        const dataRequestPromises = [];
        
        if (this.visitedDatesByUser[this.currentlyDisplayedUserId].userHasUnloadedEvents(newDate, agendaTitle)) {
            const newRange = this.ownerVisitedDatesTracker.addRangeForDate(newDate);
            dataRequestPromises.push(this.calendarEventStore.getScheduleDataByType(newRange.startDate, newRange.endDate, this.currentlyDisplayedUserId));
        }
        if (this.subordinateUserId && this.visitedDatesByUser[this.subordinateUserId].userHasUnloadedEvents(newDate, agendaTitle)) {
            const secondaryUserNewRange = this.currentSubordinateVisitedDatesTracker.addRangeForDate(newDate);
            dataRequestPromises.push(this.calendarEventStore.getScheduleDataByType(secondaryUserNewRange.startDate, secondaryUserNewRange.endDate, this.subordinateUserId));
        }
        Promise.all(dataRequestPromises);
    }
    
    setSubordinateUserId(userId) {
        this.subordinateUserId = userId;
        if (!userId) {
            return;
        }
        
        if (Object.keys(this.visitedDatesByUser).includes(userId)) {
            this.loadCalendarDataForDate(this.currentDate);
            return;
        }
        // if we do not have a visited dates tracker instance for the user, create it and load in data for its initial range
        this.visitedDatesByUser[userId] = new VisitedDatesTracker(this.ownerVisitedDatesTracker.currentView, this.currentDate, this.ownerVisitedDatesTracker.dayOffset, this.ownerVisitedDatesTracker.firstDayOfWeek, null);
        const secondaryUserNewRange = this.currentSubordinateVisitedDatesTracker.getCurrentRange();
        this.calendarEventStore.getScheduleDataByType(secondaryUserNewRange.startDate, secondaryUserNewRange.endDate, this.subordinateUserId);
    }
    
    updateDateTrackerView(newView) {
        this.ownerVisitedDatesTracker.currentView = newView;
        if (this.currentSubordinateVisitedDatesTracker) {
            this.currentSubordinateVisitedDatesTracker.currentView = newView;
        }
        this.loadCalendarDataForDate(this.ownerVisitedDatesTracker.currentDate);
    }

    updateScheduleDataForEvent(recordId, objectApiName) {
        this.calendarEventStore.updateScheduleDataForEvent(recordId, objectApiName);
    }

    refreshEventType(objectApiName) {
        const currentRange = this.ownerVisitedDatesTracker.getCurrentRange();
        const start = CalendarEventStore.formatParseableDatetime(currentRange.startDate);
        const end = CalendarEventStore.formatParseableDatetime(currentRange.endDate);
        this.calendarEventStore.refreshEventType(objectApiName, start, end);
    }

    getFormattedCurrentDateRange() {
        const range = this.currentRange;
        return { startDate: CalendarEventStore.formatParseableDatetime(range.startDate), endDate: CalendarEventStore.formatParseableDatetime(range.endDate) };
    }

    resetEventStore(records) {
        const newEventStore = CalendarEventStore.getEmptyEventStore();
        newEventStore.add(records);
        this.calendarEventStore.eventStore = newEventStore;
    }

    _initializeVisitedDatesByUser() {
        const curView = sessionStorage.getItem('currentView') || 'week';
        const curDate = new Date(sessionStorage.getItem('currentDate') || Date.now());
        const curAgendaRange = sessionStorage.getItem('agendaRange') || 'month';

        this.visitedDatesByUser = {};
        this.visitedDatesByUser[this.currentlyDisplayedUserId] = new VisitedDatesTracker(curView, curDate, Math.max(this.callScheduleConflictThreshold, 0), FIRSTDAYOFWEEK-1, curAgendaRange);
        this.ownerVisitedDatesTracker.currentDate = curDate;
    }
            
    get ownerVisitedDatesTracker() {
        return this.visitedDatesByUser[this.currentlyDisplayedUserId];
    }

    get currentSubordinateVisitedDatesTracker() {
        return this.visitedDatesByUser[this.subordinateUserId];
    }

    get eventStore() {
        return this.calendarEventStore?.eventStore;
    }

    get currentDate() {
        return this.ownerVisitedDatesTracker.currentDate;
    }

    get currentRange() {
        return this.ownerVisitedDatesTracker.getCurrentRange();
    }

    get callScheduleConflictThreshold() {
        return this._callScheduleConflictThreshold;
    }

    set callScheduleConflictThreshold(threshold) {
        this._callScheduleConflictThreshold = threshold;
        Object.values(this.visitedDatesByUser).forEach(datesTracker => {
            datesTracker.dayOffset = threshold;
        });
    }

    get displayExternalCalendarsForManagers() {
        return this.calendarEventStore?.displayExternalCalendarsForManagers;
    }

    set displayExternalCalendarsForManagers(displayCalendars) {
        if (!this.calendarEventStore?.displayExternalCalendarsForManagers) {
            this.calendarEventStore.displayExternalCalendarsForManagers = displayCalendars;
        }
    }

    get shouldFetchExternalEvents() {
        return this.calendarEventStore.shouldFetchExternalEvents;
    }

    set shouldFetchExternalEvents(shouldFetch) {
        this.calendarEventStore.shouldFetchExternalEvents = shouldFetch;
    }

    static addFrontEndProperties = CalendarEventStore.addFrontEndProperties;
}