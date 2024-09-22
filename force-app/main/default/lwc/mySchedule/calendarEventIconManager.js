import ICON_PATH from '@salesforce/resourceUrl/calendarIcons';
import CreateCallDataFormatter from 'c/createCallDataFormatter';
import CallConflictManager from './callConflictManager';

export default class CalendarEventIconManager {
    static ICON_MAP = {
        "warning": "warningIcon",
        "Face_to_face_vod": "peopleIcon",
        "Video_vod": "videoIcon",
        "Phone_vod": "callIcon",
        "Message_vod": "chatIcon",
        "Email_vod": "emailIcon",
        "Other_vod": "promptIcon"
    };
    ICON_WIDTH = 15;
    ONE_ICON_MAX_SCREEN_WIDTH_THRESHOLD = 1024;
    TWO_ICONS_MAX_SCREEN_WIDTH_THRESHOLD = 1366;

    calendar;
    callConflictManager;
    groupCallAttendeesEnabled;
    fontSize;
    
    constructor(calendar, callConflictManager, groupCallAttendeesEnabled) {
        this.calendar = calendar;
        this.callConflictManager = callConflictManager;
        this.groupCallAttendeesEnabled = groupCallAttendeesEnabled;
    }

    static addIconElt(container, iconType, className = "icon-container") {
        const imageName = CalendarEventIconManager.ICON_MAP[iconType];
        if (!container || !iconType || !imageName) {
            return null;
        }
        const elt = document.createElement('div');
        elt.className = className;
        const imgElt = document.createElement('img');
        imgElt.className = 'event-icon';
        imgElt.alt = imageName;
        imgElt.src = `${ICON_PATH}/${imageName}.svg`;

        elt.appendChild(imgElt);
        if (container.getElementsByClassName("warning").length) { // if a warning icon exists, all other icons should be placed before it
            container.insertBefore(elt, container.lastChild)
        } else {
            container.appendChild(elt);
        }
        return elt;
    }

    static addAttendeeCountElt(container, eventRecord, groupCallAttendeesEnabled, className = "event-icon event-child-count") {
        if (!container || !groupCallAttendeesEnabled || !eventRecord.childCallNumber || eventRecord.objectType !== 'Call2_vod__c') {
            return null;
        }
        const elt = document.createElement('div');
        elt.className = className;
        elt.textContent = ` +${eventRecord.childCallNumber} `;
        container.insertBefore(elt, container.firstChild);
        return elt;
    }

    getVisibleCalls() {
        return this.getVisibleEvents().filter(eventData => eventData.objectType === 'Call2_vod__c');
    }

    getVisibleEvents() {
        return this.calendar.events.map(event => event.data).filter(eventData =>
            eventData.startDate <= this.calendar.activeView.endDate && eventData.endDate >= this.calendar.activeView.startDate);
    }

    getFontSizeInPixels(element) {
        if (!this.fontSize) {
            const sizeStr = window.getComputedStyle(element, null).getPropertyValue('font-size');
            this.fontSize = parseInt(sizeStr.split('px')[0].trim(), 10) || 15;
        }
        return this.fontSize;
    }

    handleAdditionalCallContent(fromResizeEvent = false) {
        if (!this.calendar.events || this.calendar.events.length < 1) {
            return;
        }
        // map of call id -> number of events during call duration
        this.overlappingEvents = fromResizeEvent && this.overlappingEvents && Object.keys(this.overlappingEvents).length > 0 ? this.overlappingEvents : this._tallyOverlappingEvents();
        this.getVisibleCalls().forEach(eventData => {
            const endContent = this.calendar.getEventElt(eventData.id, "event-end-content");
            const nameElt = this.calendar.getEventElt(eventData.id, "b-event-name");
            if (!endContent || !nameElt) {
                return; // event not visible, nothing to handle
            }
            if (!fromResizeEvent) {
                if (this.callConflictManager.needsConflictIcon(eventData)) {
                    CallConflictManager.addCallConflictElement(endContent);
                } else if (endContent.getElementsByClassName("warning").length > 0) {
                    endContent.getElementsByClassName("warning")[0].parentElement.remove();
                }
            }
            
            if (this.calendar.activeView.modeName !== 'agenda') {
                if (this.calendar.activeView.modeName === 'week') {
                    this._addIcons(endContent, eventData); // if rescheduling calls from UI and there is no longer overlap, need to re-add
                    this._removeIcons(this.overlappingEvents[eventData.id], endContent);
                } else {
                    this._addIcons(endContent, eventData);
                }
                nameElt.style.paddingRight = `${this._calculateCallIconsPadding(eventData.id)}px`; 

                if (!fromResizeEvent) {
                    const callAddress = this.calendar.getEventElt(eventData.id, "call-address");
                    if (callAddress) {
                        const addressMaxHeight = this.calendar.getEventElt(eventData.id, 'b-cal-event-body').offsetHeight - (this.calendar.getEventElt(eventData.id, 'b-event-name').offsetHeight + 10);
                        callAddress.style.lineClamp = parseInt(addressMaxHeight / 12, 10);
                        callAddress.style.cssText = `-webkit-line-clamp: ${parseInt(addressMaxHeight / 12, 10)}`;
                    }
                }
            }
        });
    }

    handleEventSelection(event) {
        const eventData = event.eventRecord.data;
        const endContent = this.calendar.getEventElt(eventData.id, "event-end-content");
        const nameElt = this.calendar.getEventElt(eventData.id, "b-event-name");
        if (eventData.objectType !== 'Call2_vod__c' || this.calendar.activeView.modeName !== 'week' || !endContent || !nameElt) {
            return; // event does not have any hidden icons or it is not visible 
        }
        this._addIcons(endContent, eventData);
        if (this.callConflictManager.needsConflictIcon(eventData)) {
            CallConflictManager.addCallConflictElement(endContent);
        } 

        nameElt.style.paddingRight = `${this._calculateCallIconsPadding(eventData.id)}px`;
    }

    handleEventDeSelection(eventData) {
        if (!eventData) {
            return;
        }
        const endContent = this.calendar.getEventElt(eventData.id, "event-end-content");
        const nameElt = this.calendar.getEventElt(eventData.id, "b-event-name");
        if (eventData?.objectType !== 'Call2_vod__c' || this.calendar.activeView.modeName !== 'week' || !endContent || !nameElt) {
            return; // event does not have any hidden icons or it is not visible 
        }
        if (!this.callConflictManager.needsConflictIcon(eventData) && endContent.getElementsByClassName("warning").length > 0) {
            endContent.getElementsByClassName("warning")[0].parentElement.remove();
        }
        this.overlappingEvents = this._tallyOverlappingEvents();
        this._removeIcons(this.overlappingEvents[eventData.id], endContent);

        nameElt.style.paddingRight = `${this._calculateCallIconsPadding(eventData.id)}px`;
    }

    _calculateCallIconsPadding(eventId) {
        const endContent = this.calendar.getEventElt(eventId, "event-end-content");
        const nonAttendeesIconCount = endContent.getElementsByClassName("icon-container").length;
        const attendeeElt = endContent.getElementsByClassName('event-child-count')[0];
        const attendeeIconWidth = attendeeElt ? this.getFontSizeInPixels(attendeeElt) * attendeeElt.textContent.length / 2 : 0;
        return 5 + attendeeIconWidth + (nonAttendeesIconCount * (this.ICON_WIDTH + 2));
    }

    _removeIcons(numOverlappingCalls, endContent) { 
        const calendarWidth = this.calendar.width - this.calendar.sidebar.width;
        const channelIcon = endContent.querySelector('.call-channel');
        if ((calendarWidth < this.TWO_ICONS_MAX_SCREEN_WIDTH_THRESHOLD && numOverlappingCalls >= 2) || (numOverlappingCalls >= 3)) {
            endContent.getElementsByClassName('event-child-count')[0]?.remove();
        }
        if ((calendarWidth < this.ONE_ICON_MAX_SCREEN_WIDTH_THRESHOLD && numOverlappingCalls >= 2) || (calendarWidth < this.TWO_ICONS_MAX_SCREEN_WIDTH_THRESHOLD && numOverlappingCalls >= 3) || (numOverlappingCalls > 3)) {
            if (channelIcon && endContent.querySelector('.warning')) {
                channelIcon.remove();
            }
        }
    }

    _addIcons(endContent, eventRecord) {
        const attendeeCount = endContent.getElementsByClassName('event-child-count')[0];
        if (!attendeeCount && eventRecord.childCallNumber) {
            CalendarEventIconManager.addAttendeeCountElt(endContent, eventRecord, this.groupCallAttendeesEnabled);
        }
        const callChannelIcon = endContent.getElementsByClassName('call-channel')[0];
        if (!callChannelIcon && eventRecord.callChannel) {
            CalendarEventIconManager.addIconElt(endContent, eventRecord.callChannel, 'icon-container call-channel');
        }
    }

    _tallyOverlappingEvents() { 
        if (this.calendar.activeView.modeName === 'agenda') {
            return {};
        }
        const weekGridViewEvents = this.getVisibleEvents().filter(eventData => !eventData.allDay && CreateCallDataFormatter.datesAreSameDay(eventData.startDate, eventData.endDate)).sort((event1, event2) => event1.startDate - event2.startDate)
        const overlappingEvents = {};
        weekGridViewEvents.forEach((eventData1, i) => {
            let numOverlaps = 1;
            let j = i - 1;
            // check previous neighbors
            while (j >= 0 && this._eventsOverlap(weekGridViewEvents[j], eventData1)) {
                numOverlaps++;
                j--;
            }
            let k = i + 1;
            // check next neighbors
            while (k < weekGridViewEvents.length && this._eventsOverlap(weekGridViewEvents[k], eventData1)) {
                numOverlaps++;
                k++;
            }
            overlappingEvents[eventData1.id] = numOverlaps;
        });
        return overlappingEvents; 
    }

    _eventsOverlap(event1, event2) {
        return (event1.startDate < event2.startDate && event2.startDate < event1.endDate) ||
            (event2.startDate < event1.endDate && event1.startDate < event2.endDate) ||
            (event1.startDate < event2.startDate && event1.endDate > event2.endDate) ||
            (event2.startDate < event1.startDate && event2.endDate > event1.endDate);
    }

}