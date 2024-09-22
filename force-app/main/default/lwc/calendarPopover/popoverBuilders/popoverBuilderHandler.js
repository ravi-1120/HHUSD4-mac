import ICON_PATH from '@salesforce/resourceUrl/calendarIcons';

export default class PopoverBuilderHandler {
    popoverDiv;
    date;
    popoverMessages;
    popoverInfo;
    objectInfo;
    fieldLabels;
    objectLabels;
    popoverType;
    calendar;
    inConsoleMode;
    createCallService;
    COLOR_HEX_MAP = {
        plannedFuture: "C3EFE9",
        plannedPast: "FCCECA",
        savedFuture: "4CA1A5",
        savedPast: "F85446",
        submitted: "C8F4D0",
        plannedAttendee: "E87540",
        savedAttendee: "d04a13",
        timeOffTerritory: "C2E4F4",
        medicalEvent: "C1BEF0",
        calendarEntry: "FEDCA9",
        meetingRequest: "00d1b8",
        pastMeetingRequest: "e40c00",
        defaultIconColor: "A09D9B"
    };
    ICON_MAP = {
        "warning": "warningIcon",
        "warningPopover": "warningPopoverIcon",
        "close": "closePopoverIcon",
        "Face_to_face_vod": "peopleIcon",
        "Video_vod": "videoIcon",
        "Phone_vod": "callIcon",
        "Message_vod": "chatIcon",
        "Email_vod": "emailIcon",
        "Other_vod": "promptIcon"
    };

    constructor(popoverInfo, popoverMessages, objectInfo, fieldLabels, objectLabels, calendar, inConsoleMode, createCallService=null) {
        this.fieldLabels = fieldLabels;
        this.objectLabels = objectLabels;
        this.popoverInfo = popoverInfo;
        this.popoverMessages = popoverMessages;
        this.objectInfo = objectInfo;
        this.date = popoverInfo.startDate;
        this.popoverType = popoverInfo.objectType;
        this.calendar = calendar;
        this.inConsoleMode = inConsoleMode;
        this.createCallService = createCallService;
        this.popoverDiv = this.getNewPopoverElt();
    }

    get popoverRedirectRecordId() {
        return this.popoverInfo.id;
    }

    get popoverHeaderText() {
        return this.popoverInfo.recordType;
    }

    get popoverFooter() {
        const footer = document.createElement("footer");
        footer.className = "slds-popover__footer";

        const footerLinks = PopoverBuilderHandler.addElement('span', "popover-footer-buttons", "", footer);
        const moreDetails = PopoverBuilderHandler.addElement('span', "", "", footerLinks);
        if (this.displayMoreDetails()) {
            const detailsLink = PopoverBuilderHandler.addElement('a', "more-details-link", this.popoverMessages.moreDetailsLabel, moreDetails);
            detailsLink.addEventListener('click', this.handleMoreDetailsButtonClick.bind(this));
            detailsLink.addEventListener('click', () => this.calendar.features.eventTooltip.tooltip.close());
        }

        const buttonGroupContainer = PopoverBuilderHandler.addElement('span', "popover-footer-button-container", "", footerLinks);
        const buttonGroup = PopoverBuilderHandler.addElement('lightning-button-group', "popover-buttons slds-button-group", "", buttonGroupContainer);
        if (this.popoverInfo.childAccountId) {
            const childAcctButtonContainer = PopoverBuilderHandler.addElement('lightning-button', "", "", buttonGroup);
            const childAccountButton = PopoverBuilderHandler.addElement('button', "slds-button slds-button_neutral slds-button_first popover-child-account-button popover-button-element", this.popoverMessages.childAccountLabel, childAcctButtonContainer);
            childAccountButton.addEventListener('click', this.handleChildAccountButtonClick.bind(this));
        }
        if (this.displayEditButton()) {
            const editButtonContainer = PopoverBuilderHandler.addElement('lightning-button', "", "", buttonGroup);
            const editButton = PopoverBuilderHandler.addElement('button', "slds-button slds-button_neutral popover-edit-button popover-button-element", this.popoverMessages.editLabel, editButtonContainer);
            if (this.popoverInfo.childAccountId) {
                editButton.classList.add("slds-button_last");
            }
            editButton.addEventListener('click', this.handleEditButtonClick.bind(this));
            editButton.addEventListener('click', () => this.calendar.features.eventTooltip.tooltip.close());
        }

        return footer;
    }

    getNewPopoverElt() {
        const popoverDiv = document.createElement("div");
        popoverDiv.className = "popover-content slds-popover slds-popover_medium";
        const body = this._createPopoverBody();
        popoverDiv.appendChild(body);

        if (this.hasFooter()) {
            const footer = this.popoverFooter;
            popoverDiv.appendChild(footer);
        } else {
            body.classList.add('no-footer');
        }

        
        document.createElement("div").appendChild(popoverDiv);
        return popoverDiv;
    }

    hasFooter() {
        return (this.displayEditButton() || this.displayMoreDetails());
    }

    _getStatusColor(status, date) {
        let color = "B0ADAB";
        if (this.popoverInfo.isAttendee) {
            color = status === 'Planned_vod' ? this.COLOR_HEX_MAP.plannedAttendee : this.COLOR_HEX_MAP.savedAttendee;
        } else if (status === 'Planned_vod') {
            color = date < Date.now() ? this.COLOR_HEX_MAP.plannedPast : this.COLOR_HEX_MAP.plannedFuture;
        } else if (status === 'Saved_vod') {
            color = date < Date.now() ? this.COLOR_HEX_MAP.savedPast : this.COLOR_HEX_MAP.savedFuture;
        } else if (status === 'Submitted_vod') {
            color = this.COLOR_HEX_MAP.submitted;
        }

        return color
    }

    _addStatusIcon(status, date, parent, colorKey = null) {
        const colorCode = colorKey ? this.COLOR_HEX_MAP[colorKey] : this._getStatusColor(status, date);
        const elt = document.createElement("div");
        elt.className = "icon-container popover-icon status-icon";

        const svgElt = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        svgElt.setAttribute('viewbox', "0 0 16 16");
        svgElt.setAttribute('xmlspace', "preserve");

        const pathElt = document.createElementNS("http://www.w3.org/2000/svg", 'circle');
        pathElt.setAttribute('fill', `#${colorCode}`);
        pathElt.setAttribute('fill-opacity', '1');
        pathElt.setAttribute('cx', '8');
        pathElt.setAttribute('cy', '8');
        pathElt.setAttribute('r', '8');
        
        svgElt.appendChild(pathElt);
        elt.appendChild(svgElt);
        parent.appendChild(elt);
        return elt;
    }

    _addListRow(list, listClassAffix, fieldLabel, includeListSize) {
        const listElement = document.createElement("ul");
        listElement.className = `${listClassAffix}-list`;

        list.forEach((listItem, index) => PopoverBuilderHandler.addElement("li", `${listClassAffix}-${index}`, listItem, listElement));

        const listContainer = document.createElement("div");
        listContainer.className = "slds-size_2-of-3 row-content";
        listContainer.appendChild(listElement);
        
        const listRow = document.createElement("div");
        listRow.className = `popover-${listClassAffix} slds-grid slds-wrap popover-row`;
        const optionalListSize = includeListSize ? ` (${list.length})` : '';
        PopoverBuilderHandler.addElement("div", "slds-size_1-of-3 row-title", `${fieldLabel}${optionalListSize}`, listRow);
        
        listRow.appendChild(listContainer);
        this.getPopoverContentBody().appendChild(listRow);
    }

    _addRowWithIcon(popoverTypeClassName, rowLabel, rowValue, iconType = null, isStatus = false, colorKey = null) {
        const meetingTypeRow = this.addSection(`popover-${popoverTypeClassName}`, rowLabel, ' ');
        const contentElt = meetingTypeRow.querySelector(".row-content");
        if (isStatus) {
            this._addStatusIcon(this.popoverInfo.status, this.date, contentElt, colorKey);
        } else {
            this.addIconElt(iconType, contentElt, `popover-icon ${popoverTypeClassName}`);
        }
        contentElt.appendChild(document.createTextNode(rowValue));
    }

    addStatusRow(colorKey = null) {
        if (!this.popoverInfo.status) {
            return;
        }
        const statusLabel = this.fieldLabels[this.popoverType]?.Status_vod__c || this.popoverMessages.statusLabel;
        const rowContent = this._getStatusString(this.popoverType);
        this._addRowWithIcon("status", statusLabel, rowContent, null, true, colorKey);
    }
    
    _getStatusString() {
        return this.popoverInfo.status;
    }

    static addElement(eltType, className, content, parent) {
        const elt = document.createElement(eltType);
        elt.className = className;
        if (eltType === 'button') {
            const label = document.createElement('span');
            label.className = 'button-label';
            label.innerText = content;
            elt.appendChild(label);
        } else {
            elt.innerText = content;
        }
        parent.appendChild(elt);
        return elt;
    }

    addLinkForConsoleMode(rowElt, content, recordId, objectType) {
        if (!rowElt) {
            return null;
        }
        const link = PopoverBuilderHandler.addElement('a', 'popover-content-link', content, rowElt.querySelector('.row-content'));
        link.addEventListener('click', () => {
            this.calendar.element.closest('c-my-schedule').openRecordPage(recordId, objectType);
        });
        return link;
    }

    addLinkToSection(rowElt, content, url) {
        if (!rowElt || !content || !url) {
            return null;
        }
        const link = PopoverBuilderHandler.addElement('a', 'popover-content-link', content, rowElt.querySelector('.row-content'));
        link.setAttribute('href', url);
        link.setAttribute('target', "_blank");
        link.addEventListener('click', () => this.calendar.features.eventTooltip.tooltip.close());

        return link;
    }

    addSection(className, title, content) {
        if (!title || !content) {
            return null;
        }
        const row = document.createElement("div");
        row.className = `${className} slds-grid slds-wrap popover-row`;
        PopoverBuilderHandler.addElement("div", "slds-size_1-of-3 row-title", title, row);
        PopoverBuilderHandler.addElement("div", "slds-size_2-of-3 row-content", content, row);
        this.getPopoverContentBody()?.appendChild(row);
        return row;
    }

    addIconElt(iconType, parent, className = "icon-container") {
        const imageName = this.ICON_MAP[iconType];
        const elt = document.createElement("div");
        elt.className = className;

        if (imageName) {
            const imgElt = document.createElement("img");
            imgElt.src = `${ICON_PATH}/${imageName}.svg`;
            imgElt.className = "event-icon";
            imgElt.alt = imageName;
            elt.appendChild(imgElt);
        }
        parent.appendChild(elt);
        return elt;
    }

    addUnavailableForScheduling(label) {
        const row = document.createElement("div");
        row.className = 'popover-unavailable slds-grid slds-wrap popover-row';
        PopoverBuilderHandler.addElement("div", "row-title", label, row);
        this.getPopoverContentBody()?.appendChild(row);
    }

    getPopoverContentBody() {
        return this.popoverDiv.querySelector('.popover-content');
    }

    getPopoverWarningHeader() {
        return this.popoverDiv.querySelector('.popover-warning-container');
    }

    handleMoreDetailsButtonClick() {
        this.calendar.element.closest('c-my-schedule').openRecordPage(this.popoverRedirectRecordId, this.popoverInfo.objectType);
    }
    
    handleEditButtonClick() {
        const crmDesktopSetting = this.popoverInfo.enableCrmDesktop?.find(objName => objName === 'Call2_vod__c');
        if (crmDesktopSetting && this.popoverInfo.objectType === crmDesktopSetting) {
            this.calendar.element.closest('c-my-schedule').openCallOnDesktop(this.popoverRedirectRecordId);
        } else {
            this.calendar.element.closest('c-my-schedule').openEditModal(this.popoverRedirectRecordId, this.popoverInfo.objectType);
        }
    }

    handleChildAccountButtonClick() {
        this.calendar.element.closest('c-my-schedule').openRecordPage(this.popoverInfo.childAccountId, 'Account');
    }

    displayMoreDetails() {
        return true;
    }

    displayEditButton() {
        return this.objectInfo.updateable && !this.popoverInfo.isSubordinateEvent;
    }

    _createPopoverCloseButton() {
        const btnContainer = document.createElement("button");
        btnContainer.className = "slds-button slds-button_icon slds-button_icon-small slds-float_right slds-popover__close";
        btnContainer.setAttribute('title', "Close");
        btnContainer.setAttribute('data-ref', "close");
        btnContainer.addEventListener('click', () => this.calendar.features.eventTooltip.tooltip.close());
        const iconContainer = PopoverBuilderHandler.addElement('lightning-icon', "slds-icon-utility-close slds-icon_container", '', btnContainer);
        this.addIconElt("close", iconContainer, "close-icon-container");
        return btnContainer;
    }

    _createPopoverBody() {
        const bodyElt = document.createElement("div");
        bodyElt.className = "slds-media__body popover-body";
        this._createPopoverHeader(bodyElt);

        PopoverBuilderHandler.addElement('div', "popover-warning-container", "", bodyElt);
        PopoverBuilderHandler.addElement('div', "slds-text-longform popover-content", "", bodyElt);
        return bodyElt;
    }

    _createPopoverHeader(bodyElt) {
        bodyElt.appendChild(this._createPopoverCloseButton());
        const headerContainer = PopoverBuilderHandler.addElement('header', "slds-popover__header popover-header-container", "", bodyElt);

        const headerTitleContainer = PopoverBuilderHandler.addElement('div', "popover-header-title", '', headerContainer);
        const headerIconContainer = PopoverBuilderHandler.addElement('div', "popover-icon-container", '', headerTitleContainer);
        const headerIcon = PopoverBuilderHandler.addElement('img', "popover-object-icon", '', headerIconContainer);
        if (this.popoverInfo.iconUrl) {
            headerIcon.setAttribute('src', this.popoverInfo.iconUrl);
            headerIcon.setAttribute('alt', this.popoverType);
            headerIconContainer.style.backgroundColor = `#${this.popoverInfo.iconColor || this.COLOR_HEX_MAP.defaultIconColor}`;
        }
        const headerText = PopoverBuilderHandler.addElement('h1', "slds-text-heading_medium popover-header-text", this.popoverHeaderText, headerTitleContainer);
        if (navigator.userAgent.includes("Windows")) {
            headerText.style = "padding-bottom: 1px;"
        }
    }

    _addWarningRow(warningSection, conflictField, conflictLabel) {
        if (!conflictField) {
            return;
        }
        const warningRow = PopoverBuilderHandler.addElement("div", "popover-warning-row slds-scoped-notification slds-media slds-media_center slds-theme_warning", '', warningSection);
        warningRow.setAttribute("role", "status");
        const warningIconContainer = PopoverBuilderHandler.addElement("div", "slds-media__figure", '', warningRow);
        this.addIconElt("warning", warningIconContainer, "popover-icon warning");
        PopoverBuilderHandler.addElement("div", "slds-media__body popover-warning-content", conflictLabel, warningRow);
    }
}