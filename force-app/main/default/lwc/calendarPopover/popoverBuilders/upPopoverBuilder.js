import PopoverBuilderHandler from "./popoverBuilderHandler";

export default class UpPopoverBuilder extends PopoverBuilderHandler {
      
    build() {
        this.addSection("popover-up-time", this.fieldLabels.Multichannel_Activity_vod__c.Start_DateTime_vod__c, this.popoverInfo.eventDateTime?.split('-')[0]?.trim());
        const viewedSlides = this.popoverInfo.viewedSlides?.map(viewedSlide => [viewedSlide[0] || this.popoverMessages.noDescriptionLabel, viewedSlide[1]]);
        if (viewedSlides?.length > 0) {
            this._addListRow(viewedSlides.sort(([, viewOrder1], [, viewOrder2]) => parseInt(viewOrder1, 10) < parseInt(viewOrder2, 10) ? -1 : 1)
                                        .map(viewedSlide => viewedSlide[0]), 'viewed-slides', this.popoverMessages.viewedSlidesLabel, false);
        } else if (!this.popoverInfo.hasKeyMessageDescriptionFls) {
            this.addSection("popover-viewed-slides", this.popoverMessages.viewedSlidesLabel, this.popoverMessages.slideInfoNotAvailableLabel);
        }
        return this.popoverDiv;
    }

    get popoverHeaderText() {
        return this.popoverMessages.unassignedPresentationLabel;
    }

    _handleConvertToCallButtonClick() {
        this.calendar.element.closest('c-my-schedule').openConvertToCallModal(this.popoverRedirectRecordId);
    }

    _handleDiscardButtonClick() {
        this.calendar.element.closest('c-my-schedule').handleDiscardUnassignedPresentation(this.popoverRedirectRecordId);
    }

    get popoverFooter() {
        if (this.popoverInfo.isSubordinateEvent) {
            return document.createElement("div"); // do not display any buttons in the footer for events that we don't own
        }
        const footer = document.createElement("footer");
        footer.className = "slds-popover__footer";

        const footerLinks = PopoverBuilderHandler.addElement('span', "popover-footer-buttons", "", footer);

        const discardGroupContainer = PopoverBuilderHandler.addElement('span', "popover-footer-button-container", "", footerLinks);
        const discardButtonGroup = PopoverBuilderHandler.addElement('lightning-button-group', "popover-buttons slds-button-group", "", discardGroupContainer);
        const discardButtonContainer = PopoverBuilderHandler.addElement('lightning-button', "", "", discardButtonGroup);
        const discardButton = PopoverBuilderHandler.addElement('button', "slds-button slds-button_neutral popover-edit-button popover-button-element", this.popoverMessages.discardLabel, discardButtonContainer);
        discardButton.addEventListener('click', this._handleDiscardButtonClick.bind(this));

        const convertToCallGroupContainer = PopoverBuilderHandler.addElement('span', "popover-footer-button-container", "", footerLinks);
        const convertToCallButtonGroup = PopoverBuilderHandler.addElement('lightning-button-group', "popover-buttons slds-button-group", "", convertToCallGroupContainer);
        const convertToCallButtonContainer = PopoverBuilderHandler.addElement('lightning-button', "", "", convertToCallButtonGroup);
        if (!this.popoverInfo.hasCall) {
            const convertToCallButton = PopoverBuilderHandler.addElement('button', "slds-button slds-button_brand popover-edit-button popover-button-element", this.popoverMessages.convertToCallLabel, convertToCallButtonContainer);
            convertToCallButton.addEventListener('click', this._handleConvertToCallButtonClick.bind(this));
        }
        
        return footer;
    }
}