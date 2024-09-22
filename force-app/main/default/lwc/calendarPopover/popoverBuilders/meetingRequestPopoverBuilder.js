import CreateCallDataFormatter from "c/createCallDataFormatter";
import { publish, createMessageContext } from 'lightning/messageService';
import myScheduleCalendarEventChannel from '@salesforce/messageChannel/MySchedule_Calendar_Event__c';
import MeetingRequestService from "c/meetingRequestService";
import PopoverBuilderHandler from "./popoverBuilderHandler";

export default class MeetingRequestPopoverBuilder extends PopoverBuilderHandler {
    constructor(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode, createCallService) {
        super(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode, createCallService);
        this.messageContext = createMessageContext();
        this.meetingRequestService = new MeetingRequestService(this.popoverInfo, this.messageContext);
    }

    build() {
        this._addWarningSection();
        this.addSection("popover-invitee", this.popoverMessages.inviteeLabel, this.popoverInfo.name);
        this.addSection("popover-event-time", this.popoverMessages.dateLabel, this.popoverInfo.eventDateTime);
        if (this.popoverInfo.meetingType) {
            this._addRowWithIcon("meeting-type", this.fieldLabels.Meeting_Request_vod__c.Meeting_Type_vod__c, this.popoverInfo.meetingTypeLabel, this.popoverInfo.meetingType)
        }
        if (this.popoverInfo.phone) {
            this.addSection("popover-phone", this.fieldLabels.Meeting_Request_vod__c.Phone_vod__c, this.popoverInfo.phone);
        }

        this.addStatusRow(this.popoverInfo.startDate < new Date() ? 'pastMeetingRequest' : 'meetingRequest');

        return this.popoverDiv;
    }

    get popoverHeaderText() {
        return this.objectLabels.Meeting_Request_vod__c?.label;
    }

    _getStatusString() {
        let statusString;
        if (this.popoverInfo.status === 'Declined_vod' || (this.popoverInfo.status === 'Requested_vod' && this.popoverInfo.startDate >= new Date())) {
            statusString = this.popoverInfo.statusLabel;
        } else {
            statusString = this.popoverMessages.pastRequestLabel;
        }
        return statusString;
    }

    _addStatusIcon(status, date, parent, colorKey = null) {
        const colorCode = colorKey ? this.COLOR_HEX_MAP[colorKey] : this._getStatusColor(status, date);
        const elt = document.createElement("div");
        elt.className = "icon-container popover-icon status-icon";

        const svgElt = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        svgElt.setAttribute('viewbox', "0 0 16 16");
        svgElt.setAttribute('xmlspace', "preserve");

        const pathElt = document.createElementNS("http://www.w3.org/2000/svg", 'circle');
        pathElt.setAttribute('stroke', `#${colorCode}`);
        pathElt.setAttribute('fill-opacity', '0');
        pathElt.setAttribute('cx', '8');
        pathElt.setAttribute('cy', '8');
        pathElt.setAttribute('r', '6');
        if (this.popoverInfo.status === 'Declined_vod') {
            const lineElt = document.createElementNS("http://www.w3.org/2000/svg", 'line');
            lineElt.setAttribute('stroke', `#${colorCode}`);
            lineElt.setAttribute('x1', '0');
            lineElt.setAttribute('x2', '16');
            lineElt.setAttribute('y1', '8');
            lineElt.setAttribute('y2', '8');
            svgElt.appendChild(lineElt);
        }
        
        svgElt.appendChild(pathElt);
        elt.appendChild(svgElt);
        parent.appendChild(elt);
        return elt;
    }

    get popoverFooter() {
        if (this.popoverInfo.isSubordinateEvent) {
            return document.createElement("div"); // do not display any buttons in the footer for events that we don't own
        }
        const footer = document.createElement("footer");
        footer.className = "slds-popover__footer";
        const footerLinks = PopoverBuilderHandler.addElement('span', "popover-footer-buttons", "", footer);
        const remove = PopoverBuilderHandler.addElement('span', "", "", footerLinks);

        if (this._canRemoveMeetingRequest()) {
            const removeLink = PopoverBuilderHandler.addElement('a', "more-details-link", this.popoverMessages.removeLabel, remove);
            removeLink.addEventListener('click', this._handleRemoveButtonClick.bind(this));
        }

        const meetingRequestGroupContainer = PopoverBuilderHandler.addElement('span', "popover-footer-button-container", "", footerLinks);
        const meetingRequestButtonGroup = PopoverBuilderHandler.addElement('lightning-button-group', "popover-buttons slds-button-group-row", "", meetingRequestGroupContainer);
        const meetingRequestButtonContainer = PopoverBuilderHandler.addElement('lightning-button', "", "", meetingRequestButtonGroup);

        if (this._canDeclineMeetingRequest()) {
            const declineButton = PopoverBuilderHandler.addElement('button', "slds-button-group-item slds-button slds-button_neutral popover-edit-button popover-button-element", this.popoverMessages.declineLabel, meetingRequestButtonContainer);
            declineButton.addEventListener('click', this._handleDeclineButtonClick.bind(this));
        }
       
        if (this._canAcceptMeetingRequest()) {
            const acceptButton = PopoverBuilderHandler.addElement('button', "slds-button-group-item slds-button slds-button_brand popover-edit-button popover-button-element", this.popoverMessages.acceptLabel, meetingRequestButtonContainer);
            acceptButton.addEventListener('click', this._handleAcceptButtonClick.bind(this));
        }

        return footer;
    }

    _handleAcceptButtonClick() {
        this.calendar.features.eventTooltip.tooltip.close();
        const view = this.calendar.mode.modeName || this.calendar.mode;
        const callData = CreateCallDataFormatter.processDataForCreateCall(this.popoverInfo.startDate, [], this.popoverInfo.allDay, this.popoverInfo.duration, 
            view, this.popoverInfo.allowedCallRecordTypes, this.popoverInfo.callBackdateLimit, '');

        if (this.popoverInfo.accountId) {
            // remove meeting request event from calendar
            publish(this.meetingRequestService.messageContext, myScheduleCalendarEventChannel, {isTemporary: false, temporaryEventId: this.popoverInfo.id});

            const accountInfo = {
                id: this.popoverInfo.accountId,
                displayedName: this.popoverInfo.name
            }
            this.calendar.element.closest('c-my-schedule').createCall(callData, accountInfo, false, this.meetingRequestService.updateAcceptMeetingRequest.bind(this.meetingRequestService));
        } else {
            callData.eventType = 'meeting-request';
            callData.meetingRequestId = this.popoverInfo.id;
            this.calendar.element.closest('c-my-schedule').accountSearchModal.showAccountSearchModalMeetingRequest(callData, this.meetingRequestService.updateAcceptMeetingRequest.bind(this.meetingRequestService));
        }
    }

    async _handleRemoveButtonClick() {
        if (this.popoverInfo.status === 'Requested_vod') {
            this.calendar.element.closest('c-my-schedule').showReasonModal(this.popoverMessages.removeReasonLabel, false, this.meetingRequestService.updateRemoveMeetingRequest.bind(this.meetingRequestService), Object.values(this.objectInfo.Meeting_Request_vod__c.recordTypeInfos).find(entry => entry.name === this.popoverInfo.recordType).recordTypeId);
        } else {
            this.meetingRequestService.updateRemoveMeetingRequest();
        }
        this.calendar.features.eventTooltip.tooltip.close();
    }

    async _handleDeclineButtonClick() {
        this.calendar.element.closest('c-my-schedule').showReasonModal(this.fieldLabels.Meeting_Request_vod__c.Decline_Reason_vod__c, true, this.meetingRequestService.updateDeclineMeetingRequest.bind(this.meetingRequestService), Object.values(this.objectInfo.Meeting_Request_vod__c.recordTypeInfos).find(entry => entry.name === this.popoverInfo.recordType).recordTypeId);
        this.calendar.features.eventTooltip.tooltip.close();
    }

    _canAcceptMeetingRequest() {
        this.accountRestriction = true;
        // validate account record type if account populated
        if (this.popoverInfo.accountRecordType) {
            this.createCallService.populateValidationLists(this.popoverInfo.allowedCallRecordTypes);
            this.accountRestriction = this.createCallService.validAccount(this.popoverInfo.accountRecordType);
        }
        return MeetingRequestService.hasAcceptMeetingRequestPermissions(this.objectInfo) && this.popoverInfo.startDate > new Date() && !this.popoverInfo.accountDoNotCall && this.accountRestriction;
    }

    _canRemoveMeetingRequest() {
        return (this.popoverInfo.status === 'Requested_vod' || this.popoverInfo.status === 'Declined_vod') 
            && MeetingRequestService.hasRemoveMeetingRequestPermissions(this.objectInfo);
    }

    _canDeclineMeetingRequest() {
        return this.popoverInfo.status === 'Requested_vod' && this.popoverInfo.startDate > new Date() && MeetingRequestService.hasDeclineMeetingRequestPermissions(this.objectInfo);
    }

    _addWarningSection() {
        if (!this.popoverInfo.accountId || this.popoverInfo.isSubordinateEvent) {
            return;
        }
        if (this.popoverInfo.accountDoNotCall || !this.accountRestriction) {
            const warningSection = PopoverBuilderHandler.addElement("div", "popover-warning-section", '', this.getPopoverWarningHeader());
            this._addWarningRow(warningSection, this.popoverInfo.accountDoNotCall, this.popoverMessages.msgAccountNotValidated);
            this._addWarningRow(warningSection, !this.accountRestriction, this.popoverMessages.msgAccountRestriction);
        }   
    }
}