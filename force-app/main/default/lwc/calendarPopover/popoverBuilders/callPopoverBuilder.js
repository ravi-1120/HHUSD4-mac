import VeevaMedicalIdentifierHelper from "c/veevaMedicalIdentifierHelper";
import PopoverBuilderHandler from "./popoverBuilderHandler";

export default class CallPopoverBuilder extends PopoverBuilderHandler {

    displayEditButton() {
        return super.displayEditButton() && (this.popoverInfo.status === 'Saved_vod' || this.popoverInfo.status === 'Planned_vod') && this.popoverInfo.eventType !== 'attendee-call';
    }

    _getStatusString() {
        return this.popoverInfo.statusLabel || this.popoverInfo.recordType;
    }

    _addWarningSection() {
        if (!this.popoverInfo.datesConflict && !this.popoverInfo.hasUnscheduledRemoteMeeting && !this.popoverInfo.uninvitedRemoteAttendeeNumber) {
            return;
        }
        const warningSection = PopoverBuilderHandler.addElement("div", "popover-warning-section", '', this.getPopoverWarningHeader());

        this._addWarningRow(warningSection, this.popoverInfo.datesConflict, this.popoverMessages.callConflictLabel);
        this._addWarningRow(warningSection, this.popoverInfo.hasUnscheduledRemoteMeeting, this.popoverMessages.remoteNotScheduledLabel);

        if (this.popoverInfo.uninvitedRemoteAttendeeNumber && this.popoverInfo.remoteAttendeeNumber) {
            let uninvitedAttendeesString  = this.popoverMessages.attendeesNotInvitedLabel.replace('{0}', this.popoverInfo.uninvitedRemoteAttendeeNumber);
            uninvitedAttendeesString = uninvitedAttendeesString.replace('{1}', this.popoverInfo.remoteAttendeeNumber);
            this._addWarningRow(warningSection, this.popoverInfo.uninvitedRemoteAttendeeNumber, uninvitedAttendeesString);
        }
    }

    _getIdentifierLabel() {
        if (VeevaMedicalIdentifierHelper.getIdentifierApiName() === "Medical_Identifier_vod__c") {
            return this.fieldLabels.Account.Medical_Identifier_vod__c;
        }
        return this.fieldLabels.Account.Account_Identifier_vod__c;
    }

    build() {
        this._addWarningSection();
        this.addSection("popover-call-time", this.fieldLabels.Call2_vod__c.Call_Date_vod__c, this.popoverInfo.eventDateTime);
        if (this.popoverInfo.accountId) {
            const nameContent = this.popoverInfo.name;
            const acctRow = this.addSection("popover-account-name", this.fieldLabels.Call2_vod__c.Account_vod__c, this.popoverInfo.accountUrl ? ' ' : nameContent);
            if (this.popoverInfo.accountUrl) {
                if (this.inConsoleMode) {
                    this.addLinkForConsoleMode(acctRow, nameContent, this.popoverInfo.accountId, 'Account');
                } else {
                    this.addLinkToSection(acctRow, nameContent, this.popoverInfo.accountUrl);
                }
            }
        }

        this.addSection("popover-account-identifier", this._getIdentifierLabel(), this.popoverInfo.acctIdentifier);
        
        if (this.popoverInfo.enableAccountParentDisplay && !this.popoverInfo.location && !this.popoverInfo.enableChildAccount) {
            this.addSection("popover-parent-account", this.fieldLabels.Account.Primary_Parent_vod__c, this.popoverInfo.parentAccount);
        }
        this.addSection("popover-call-owner", this.popoverMessages.ownerLabel, this.popoverInfo.owner); 
        this.addSection('popover-location', this.fieldLabels.Call2_vod__c.Location_Text_vod__c, this.popoverInfo.location);
        if (this.popoverInfo.callChannel) {
            this._addRowWithIcon("call-channel", this.fieldLabels.Call2_vod__c.Call_Channel_vod__c, this.popoverInfo.callChannelLabel, this.popoverInfo.callChannel);
        }
        this.addSection("popover-address", this.fieldLabels.Call2_vod__c.Address_vod__c, this.popoverInfo.address);
        if (!this.popoverInfo.accountUrl && !this.popoverInfo.childAccountId) {
            this.addSection("popover-event-name", this.fieldLabels.Medical_Event_vod__c?.Name, this.popoverInfo.name);
        }
        this.addStatusRow();
        if (this.popoverInfo.unavailable && this.fieldLabels.Call2_vod__c?.Unavailable_for_Scheduling_vod__c) {
            this.addUnavailableForScheduling(this.fieldLabels.Call2_vod__c?.Unavailable_for_Scheduling_vod__c);
        }
        
        const eventChildren = this.popoverInfo.childrenEvents;
        if (eventChildren && eventChildren.length > 0 && this.popoverInfo.attendeesEnabled) {
            eventChildren.sort((a, b) => a.localeCompare(b));
            this._addListRow(eventChildren, 'attendee', this.fieldLabels.Call2_vod__c.Attendees_vod__c, true);
        }
        return this.popoverDiv;
    }
}