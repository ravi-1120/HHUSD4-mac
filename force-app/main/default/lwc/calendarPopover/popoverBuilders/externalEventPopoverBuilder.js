import PopoverBuilderHandler from "./popoverBuilderHandler";

export default class ExternalEventPopoverBuilder extends PopoverBuilderHandler {

    build() {
        this.addSection("popover-event-time", this.popoverMessages.dateLabel, this.popoverInfo.eventDateTime);
        this.addSection("popover-external-calendar", this.popoverMessages.calendarLabel, this.popoverInfo.recordType);
        if (this.popoverInfo.unavailable &&  this.fieldLabels.External_Calendar_Event_vod__c.Unavailable_for_Engage_Scheduling_vod__c) {
            this.addUnavailableForScheduling(this.fieldLabels.External_Calendar_Event_vod__c.Unavailable_for_Engage_Scheduling_vod__c);
        }

        return this.popoverDiv;
    }

    displayEditButton() {
        return super.displayEditButton() && this.hasUnavailableForEngageSchedulingEditFLS;
    }

    displayMoreDetails() {
        return false;
    }

    get hasUnavailableForEngageSchedulingEditFLS() {
        return this.objectInfo.fields?.Unavailable_for_Engage_Scheduling_vod__c?.updateable;
    }

    get popoverHeaderText() {
        if (this.popoverInfo.sensitivity === 'PRIVATE') {
            return this.popoverMessages.privateLabel;
        } 
            return this.popoverInfo.name === '' ? this.popoverMessages.noSubjectLabel : this.popoverInfo.name;
        
    }
}