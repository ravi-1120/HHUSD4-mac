import PopoverBuilderHandler from "./popoverBuilderHandler";

export default class TotPopoverBuilder extends PopoverBuilderHandler {

    build() {
        this.addSection("popover-tot-time", this.fieldLabels.Time_Off_Territory_vod__c.Date_vod__c, this.popoverInfo.eventDateTime);
        if (this.popoverInfo.unavailable && this.fieldLabels.Time_Off_Territory_vod__c?.Unavailable_for_Engage_Scheduling_vod__c) {
            this.addUnavailableForScheduling(this.fieldLabels.Time_Off_Territory_vod__c.Unavailable_for_Engage_Scheduling_vod__c);
        }
        return this.popoverDiv;
    }

    get popoverHeaderText() {
        return this.popoverInfo.name;
    }
}