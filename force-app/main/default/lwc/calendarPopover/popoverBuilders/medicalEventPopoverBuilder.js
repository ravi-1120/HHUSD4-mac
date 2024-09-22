import CURRENT_USER_ID from '@salesforce/user/Id'
import PopoverBuilderHandler from "./popoverBuilderHandler";

export default class medicalEventPopoverBuilder extends PopoverBuilderHandler {

    displayEditButton() {
        return super.displayEditButton() && (this.popoverType !== 'EM_Event_vod__c') && (CURRENT_USER_ID === this.popoverInfo.ownerId);
    }

    build() {
        this.addSection("popover-event-title", this.fieldLabels.Medical_Event_vod__c.Name, this.popoverInfo.name);
        this.addSection("popover-event-time", this.popoverMessages.dateLabel, this.popoverInfo.eventDateTime);

        if (this.popoverInfo.programType) {
            this.addSection("popover-program-type", this.fieldLabels.Medical_Event_vod__c.Program_Type_vod__c, this.popoverInfo.programType);
        } else if (this.popoverInfo.medicalEventType) {
            this.addSection("popover-medical-event-type", this.fieldLabels.Medical_Event_vod__c.Event_Type__c, this.popoverInfo.medicalEventType);
        }
        const ownerRow = this.addSection("popover-me-owner", this.popoverMessages.ownerLabel, this.popoverInfo.owner && this.popoverInfo.ownerUrl ? ' ' : null);
        if (this.popoverInfo.owner && this.popoverInfo.ownerUrl) {
            if (this.inConsoleMode) {
                this.addLinkForConsoleMode(ownerRow, this.popoverInfo.owner, this.popoverInfo.ownerId, 'User');
            } else {
                this.addLinkToSection(ownerRow, this.popoverInfo.owner, this.popoverInfo.ownerUrl);
            }
        }
        this.addSection("popover-location", this.fieldLabels.Medical_Event_vod__c.Location__c, this.popoverInfo.location);
        this.addSection("popover-status", this.fieldLabels.EM_Event_vod__c?.Status_vod__c, this.popoverInfo.status);
        
        if (this.popoverType === 'EM_Event_vod__c') {
            const eventChildren = this.popoverInfo.childrenEvents;
            if (eventChildren && eventChildren.length > 0) {
                this._addListRow(eventChildren, 'attendee', this.objectLabels.EM_Speaker_vod__c?.labelPlural, true);
            }
        }

        return this.popoverDiv;
    }

    get popoverRedirectRecordId() {
        return this.popoverInfo.emEventId || this.popoverInfo.id;
    }
}