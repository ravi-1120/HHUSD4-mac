import ICON_PATH from '@salesforce/resourceUrl/calendarIcons';
import PopoverBuilderFactory from "./popoverBuilderFactory";

export default class CalendarPopover {
    DEFAULT_ICON_URL = `${ICON_PATH}/calendarIcon.svg`;
    DEFAULT_ICON_COLOR = 'eb7093';
    popoverType;
    popoverMessages = {};
    fieldLabels;
    objectLabels;
    objectInfos;
    popoverElt;
    popoverInfo;
    calendar;
    inConsoleMode;
    currentlyOpen;
    createCallService;

    static instance;

    static getInstance(popoverMessages, calendarObjectInfos, inConsoleMode, createCallService) {
        if (!CalendarPopover.instance) {
            CalendarPopover.instance = new CalendarPopover(popoverMessages, calendarObjectInfos, inConsoleMode, createCallService);
        }
        return CalendarPopover.instance;
    }

    constructor(popoverMessages, calendarObjectInfos, inConsoleMode, createCallService) {
        this.popoverMessages = popoverMessages;
        this.objectInfos = calendarObjectInfos;
        this.inConsoleMode = inConsoleMode;
        this.fieldLabels = this._getFieldLabelsByObject();
        this.objectLabels = this._getObjectLabels();
        this.createCallService = createCallService;
    }

    _getObjectLabels() {
        const objectLabelsMap = {};
        Object.entries(this.objectInfos).forEach(entry => {
            const objectLabels = {
                label: this.objectInfos[entry[0]].label,
                labelPlural: this.objectInfos[entry[0]].labelPlural
            };
            objectLabelsMap[this.objectInfos[entry[0]].apiName] = objectLabels;
        });
        return objectLabelsMap;
    }

    _getFieldLabelsByObject() {
        return Object.fromEntries(
            Object.entries(this._getPropertyByObject(this.objectInfos, 'fields'))
                .map(fieldEntry => [ fieldEntry[0], this._getPropertyByObject(fieldEntry[1], 'label') ]
            )
        );
    }

    _getPropertyByObject(objectInfos, property) {
        return Object.fromEntries(Object.entries(objectInfos).map(entry => [entry[0], entry[1][property]]));
    }

    _setEventIconInfo(objectInfo) {
        // set tab info - if no theme is present, default to the standard Event object's theme info, with a static resource as a final backup if event object info query fails
        this.popoverInfo.iconUrl = objectInfo.themeInfo?.iconUrl || this.objectInfos.Event?.themeInfo?.iconUrl || this.DEFAULT_ICON_URL;
        this.popoverInfo.iconColor = objectInfo.themeInfo?.iconUrl && objectInfo.themeInfo?.color ? 
            objectInfo.themeInfo?.color : this.objectInfos.Event?.themeInfo?.color || this.DEFAULT_ICON_COLOR;
    }

    static convertHtmlEltToDomConfigObj(htmlElt) {
        return { // Bryntum Calendar's renderer method expects a config object, not an HTMLElement
            className : htmlElt.className,
            html : '',
            parent : htmlElt.parentElement,
            children : htmlElt.children
        }
    }

    populate(data, settings, calendar) {
        this.currentlyOpen = true;
        const objectInfo = data.objectType === 'Meeting_Request_vod__c' ?  {'Meeting_Request_vod__c': this.objectInfos.Meeting_Request_vod__c, 'Call2_vod__c': this.objectInfos.Call2_vod__c} : this.objectInfos[data.objectType];
        this.calendar = calendar;
        this.popoverInfo = {...data};
        
        this.popoverInfo.isAttendee = data.cls ? Object.keys(data.cls)[0].includes('attendee') : false;
        this.popoverInfo.attendeesEnabled = settings.groupCallAttendeesEnabled;
        this.popoverInfo.enableAccountParentDisplay = settings.enableAccountParentDisplay;
        this.popoverInfo.enableChildAccount = settings.enableChildAccount;
        this.popoverInfo.enableCrmDesktop = settings.enableCrmDesktop;
        this.popoverInfo.allowedCallRecordTypes = settings.allowedCallRecordTypes;
        this.popoverInfo.callBackdateLimit = settings.callBackdateLimit;
        this._setEventIconInfo(objectInfo);
        this.popoverElt = PopoverBuilderFactory.getPopover(this.popoverInfo, this.popoverMessages, objectInfo, this.fieldLabels, this.objectLabels, this.calendar, this.inConsoleMode, this.createCallService).build();
        this.popoverElt.classList.add('slds-hide');
        // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
        setTimeout(()=> { this.popoverElt.classList.remove('slds-hide') }, 1);
        this.popoverElt.classList.add('event-popover');
        this.popoverElt.classList.add(`${this.popoverInfo.id}-popover`);
        return CalendarPopover.convertHtmlEltToDomConfigObj(this.popoverElt.parentElement);
    }
}