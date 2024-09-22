export default class VisitedRange {
    startDate;
    endDate;
    constructor(startDate, endDate) {
        this.startDate = startDate;
        this.endDate = endDate;
    }

    isDateWithinRange(newDate) {
        return newDate >= this.startDate && newDate < this.endDate;
    }

    updateRange(newRange) {
        if (newRange.startDate < this.startDate) {
            this.startDate = newRange.startDate;
        }
        if (newRange.endDate > this.endDate) {
            this.endDate = newRange.endDate;
        }
        return newRange;
    }
}