import VisitedRange from './visitedRange';

export default class VisitedDatesTracker { // need to load in events for the day our view is on, not the current day
    WEEK_LENGTH = 7;
    WEEKS_DISPLAYED_IN_MONTH_VIEW = 6;

    loadedEvents;
    currentView;
    dayOffset;
    firstDayOfWeek;
    currentDate;
    constructor(currentView = 'month', currentDate = new Date(), dayOffset = 1, firstDayOfWeek = 0, agendaRange = null) {
        this.loadedEvents = [];
        this.currentView = currentView !== 'agenda' ? currentView : agendaRange;
        this.dayOffset = dayOffset;
        this.firstDayOfWeek = firstDayOfWeek;
        this.currentDate = currentDate;
        this.addRangeForDate(currentDate);
    }

    createRangeFromDate(newDate) {
        const firstDay = this._getFirstVisibleDateOfView(newDate);
        const beginning = new Date(firstDay);
        const end = new Date(firstDay);
        if (this.currentView === 'week' || this.currentView === 'day') {
            beginning.setDate(firstDay.getDate() - this.dayOffset);
            end.setDate(firstDay.getDate() + this.WEEK_LENGTH + this.dayOffset);
        } else if (this.currentView === 'month') {
            beginning.setDate(firstDay.getDate() - this.dayOffset);
            end.setDate(firstDay.getDate() + (this.WEEKS_DISPLAYED_IN_MONTH_VIEW * this.WEEK_LENGTH) + this.dayOffset);
        } else if (this.currentView === 'year') {
            beginning.setMonth(0);
            beginning.setDate(1 - this.dayOffset);
            end.setMonth(11);
            end.setDate(31 + this.dayOffset);
        }
        return new VisitedRange(beginning, end);
    }

    isDateWithinLoadedRange(newDate) {
        const beginning = new Date(newDate);
        beginning.setDate(newDate.getDate() - this.dayOffset);
        const end = new Date(newDate);
        end.setDate(newDate.getDate() + this.dayOffset);
        const newRange = new VisitedRange(beginning, end)

        return this.loadedEvents.filter(range => range.isDateWithinRange(newRange.startDate) && range.isDateWithinRange(newRange.endDate)).length > 0;
    }

    userHasUnloadedEvents(newDate, agendaTitle) {
        return this._currentViewHasWeekRangeNotLoaded(newDate) || this._currentViewHasMonthRangeNotLoaded(newDate, agendaTitle) || this._agendaViewYearRangeNotLoaded(newDate, agendaTitle);
    }

    _currentViewHasWeekRangeNotLoaded(newDate) {
        const curDate = this._getFirstVisibleDateOfView(newDate, 'week');
        for (let i = 0; i < this.WEEK_LENGTH; i++) {
            if (!this.isDateWithinLoadedRange(curDate)) {
                return true;
            }
            curDate.setDate(curDate.getDate() + 1);
        }
        return false;
    }

    _currentViewHasMonthRangeNotLoaded(newDate, agendaTitle) {
        return (this.currentView === 'month' || (this.currentView === 'agenda' && agendaTitle === 'month')) && this.monthHasUnloadedEvents(newDate);
    }
    
    _agendaViewYearRangeNotLoaded(newDate, agendaTitle) {
        return this.currentView === 'agenda' && agendaTitle === 'year' && this.yearHasUnloadedEvents(newDate);
    }

    monthHasUnloadedEvents(selectedDate) {
        const curDate = this._getFirstVisibleDateOfView(selectedDate, 'month');
        for (let i = 0; i < this.WEEKS_DISPLAYED_IN_MONTH_VIEW; i++) {
            if (!this.isDateWithinLoadedRange(curDate)) {
                return true;
            }
            curDate.setDate(curDate.getDate() + this.WEEK_LENGTH);
        }
        return false;
    }

    yearHasUnloadedEvents(selectedDate) {
        const year = new Date(selectedDate).getFullYear();
        const firstDay = (year, 0, 1);
        const lastDay = (year, 11, 31);
        return !this.loadedEvents.find(range => range.isDateWithinRange(firstDay) && range.isDateWithinRange(lastDay));
    }

    getCurrentRange() {
        return this.loadedEvents.find(range => range.isDateWithinRange(this.currentDate));
    }

    addRangeForDate(newDate) {
        this.currentDate = new Date(newDate);
        const newRange = this.createRangeFromDate(newDate);
        let rangePlacement = 0;
        for (let index = 0; index < this.loadedEvents.length; index++) {
            const range = this.loadedEvents[index];
            if (range.isDateWithinRange(newRange.startDate) || range.isDateWithinRange(newRange.endDate)) {
                range.updateRange(newRange);
                this._mergeOverlappingNeighbors(index);
                return newRange;
            }
            if (newRange.startDate > range.startDate) {
                rangePlacement = index+1;
            }
        }
        // splice here is used to insert elements into the loadedEvents array at the specified index rangePlacement 
        // so that the resulting array of date ranges is sorted
        this.loadedEvents.splice(rangePlacement, 0, newRange);
        return newRange;
    }

    _mergeOverlappingNeighbors(index) {
        const currentRange = this.loadedEvents[index];      
        const beforeRange = this.loadedEvents[index-1];
        const afterRange = this.loadedEvents[index+1];
        let curIndex = index;

        // if increasing our current date range spills into another range, we combine the two
        if (curIndex > 0 && beforeRange.endDate >= currentRange.startDate) {
            currentRange.updateRange(beforeRange);
            this.loadedEvents.splice(curIndex-1, 1);
            curIndex -= 1;
        }
        if (curIndex < this.loadedEvents.length - 1 && afterRange.startDate <= currentRange.endDate) {
            currentRange.updateRange(afterRange);
            this.loadedEvents.splice(curIndex+1, 1);
        }
    }

    _getFirstVisibleDateOfView(newDate, currentView = this.currentView) {
        const resultDate = new Date(newDate);
        if (currentView === 'month') {
            resultDate.setDate(1);
        }
        const firstDayDiff = Math.abs(resultDate.getDay() - this.firstDayOfWeek);
        const firstDayOffset = resultDate.getDay() >= this.firstDayOfWeek ? 0 - firstDayDiff : firstDayDiff - 7;
        resultDate.setDate(resultDate.getDate() + firstDayOffset);
        return resultDate;
    }
}