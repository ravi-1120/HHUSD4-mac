import ICON_PATH from '@salesforce/resourceUrl/calendarIcons';
import CreateCallDataFormatter from 'c/createCallDataFormatter';
import CalendarEventIconManager from './calendarEventIconManager';
import CalendarLocaleManager from "./calendarLocaleManager";
import CallConflictManager from "./callConflictManager";
import CalendarEventTypeFactory from './calendarEventTypes/calendarEventTypeFactory';

export default class CalendarModeManager {
    static MODE_TYPES = ['day', 'week', 'month', 'year', 'agenda'];

    localeManager;
    groupCallAttendeesEnabled;
    translatedLabels;
    callConflictManager;
    initialAgendaRange;
    calendarEventType;
    constructor(calendar, initialAgendaRange = null) {
        this.localeManager = calendar.clm;
        this.groupCallAttendeesEnabled = calendar.settings.groupCallAttendeesEnabled;
        this.translatedLabels = calendar.translatedLabels;
        this.callConflictManager = calendar.callConflictManager;
        this.initialAgendaRange = initialAgendaRange;
    }

    getCalendarMode(desiredModeName) {
        return this.getCalendarModes([desiredModeName])[desiredModeName];
    }

    getCalendarModes(desiredModes) {
        const result = {};
        const modeNames = new Set(desiredModes);
        const modeArray = CalendarModeManager.MODE_TYPES.map(modeName => {
            if (!modeNames.has(modeName)) {
                return { name : modeName, config : null }
            }
            return { name : modeName, config : this.getModeConfig(modeName) };
        });
        modeArray.forEach((modeObj) => {
            result[modeObj.name] = modeObj.config;
        });
        return result;
    }

    getModeConfig(modeName) {
        switch (modeName) {
            case 'day':
                return this.getWeekViewConfig();
            case 'week':
                return this.getWeekViewConfig();
            case 'month':
                return this.getMonthViewConfig();
            case 'agenda':
                return this.getAgendaViewConfig();
            default:
                return null;
        }
    }

    getWeekViewConfig() {
        return {
            allDayEvents : {
                autoHeight : true,
                sortEvents: (events) => events.sort(CalendarModeManager.allDayEventComparator)
            },
            descriptionRenderer : this._calendarViewDescriptionRenderer,
            eventRenderer : ({eventRecord}) => this._renderWeekEvent(eventRecord),
            sortEvents : (events) => events.sort(CalendarModeManager.eventComparator),
            showTime : false,
            timeFormat : this.localeManager.getLocaleTimeFormatString(),
            visibleStartTime : 7.5,
            hourHeight : 70,
            shortEventDuration : null,
            shortEventCls: null,
            increment : '30 minutes',
            hourHeightBreakpoints: [] // disable half hour tick marks
        }
    }

    getMonthViewConfig() {
        return {
            eventRenderer : ({eventRecord}) => this._renderMonthEvent(eventRecord),
            sortEvents: (events) => events.sort(CalendarModeManager.eventComparator),
            overflowPopup : {
                dateFormat : this.localeManager.getLocaleDateString(),
                eventSorter : CalendarModeManager.eventComparator,
                eventRenderer : eventData => this.renderOverflowPopover(eventData),
                maxHeight : 600,
                floating : true,
                listeners : {
                    beforeclose: this.closeEventPopover
                }
            }
        }
    }

    getAgendaViewConfig() {
        return {
            allDayEvents : {
                autoHeight : true,
                sortEvents: (events) => events.sort(CalendarModeManager.allDayEventComparator)
            },
            descriptionRenderer : this._calendarViewDescriptionRenderer,
            eventRenderer : ({eventRecord}) => this._renderMonthEvent(eventRecord),
            sortEvents : (events) => events.sort(CalendarModeManager.eventComparator),
            eventTimeRenderer : (eventRecord) => {
                const {allDay} = eventRecord.data;
                const startDateTimeString = allDay ? CalendarLocaleManager.getFormattedDate(eventRecord.data.startDate) : CalendarLocaleManager.getFormattedTime(eventRecord.data.startDate);
                const endDateTimeString = allDay ? CalendarLocaleManager.getFormattedDate(eventRecord.data.endDate) : CalendarLocaleManager.getFormattedTime(eventRecord.data.endDate);
                return startDateTimeString === endDateTimeString ? startDateTimeString : `${startDateTimeString} - ${endDateTimeString}`;
            },
            range: this.initialAgendaRange
        }
    }

    _calendarViewDescriptionRenderer(view) {
        const endDate = new Date(view.endDate.getTime() - 1);
        return CalendarLocaleManager.getFormattedDateRange(view.startDate, endDate);
    }

    _getEventEndContent(eventRecord) {
        const optionalClockIcon = (eventRecord.status !== 'Declined_vod' && eventRecord.eventType=== 'meeting-request') ? '<i class="fas b-fa-clock"></i>' : '';
        const optionalAttendeeCount = eventRecord.objectType === 'Call2_vod__c' ? CalendarModeManager.getAttendeeCountHtml(eventRecord.childCallNumber, this.groupCallAttendeesEnabled) : '';
        const callChannel = eventRecord.remoteAttendeeNumber ? CalendarModeManager.getIconHtml('Video_vod', 'call-channel') : CalendarModeManager.getIconHtml(eventRecord.callChannel, 'call-channel icon-container');
        return `<div class="event-end-content">${optionalAttendeeCount}${callChannel}${optionalClockIcon}</div>`;
    }

    closeEventPopover() {
        window.calendar.features.eventTooltip.tooltip.close();
    }
    
    _renderWeekEvent(eventRecord) {
        this.calendarEventType = CalendarEventTypeFactory.getEventType(eventRecord.data, this.translatedLabels);
        let eventName = this.calendarEventType.getEventName();
        // eslint-disable-next-line no-undef
        eventName = eventRecord.eventType === 'meeting-request' ? this._modifyMrEventNameStyling(eventRecord) : bryntum.calendar.StringHelper.encodeHtml(eventName);
        const shouldTruncateOneLine = eventRecord.eventType === 'meeting-request' && eventRecord.duration < 45;
        const startAndEndSameDay = CreateCallDataFormatter.datesAreSameDay(eventRecord.startDate, eventRecord.endDate);
        const shouldTruncateTwoLines = !eventRecord.allDay && startAndEndSameDay && !shouldTruncateOneLine;
        const optionalCallAddressDiv = eventRecord.duration >= 45 && eventRecord.objectType === 'Call2_vod__c' && eventRecord.address && startAndEndSameDay && !eventRecord.allDay ? `<div class="call-address">${eventRecord.address}</div>` : '';
        
        let headerText;
        if (eventRecord.startDate >= new Date()) {
            headerText = eventRecord.meetingTypeLabel ? this.translatedLabels.meetingTypeRequestLabel.replace('{0}', eventRecord.meetingTypeLabel) : (this.translatedLabels.Meeting_Request_vod__c?.label || '');
        } else {
            headerText = this.translatedLabels.pastRequestLabel;
        }
        const optionalMeetingRequestHeader = eventRecord.eventType === 'meeting-request' ? `<div class="meeting-request-header">${headerText}</div>` : '';
        
        return `${optionalMeetingRequestHeader}
            <div class="b-event-name ${shouldTruncateTwoLines ? 'two-line-truncation' : ''} ${shouldTruncateOneLine ? 'one-line-truncation' : ''}">${eventName}</div>
            ${optionalCallAddressDiv}
            ${this._getEventEndContent(eventRecord)}`;
    }

    _renderMonthEvent(eventRecord) {
        this.calendarEventType = CalendarEventTypeFactory.getEventType(eventRecord.data, this.translatedLabels);
        let eventName = this.calendarEventType.getEventName();
        // eslint-disable-next-line no-undef
        eventName = eventRecord.eventType === 'meeting-request' ? this._modifyMrEventNameStyling(eventRecord) : bryntum.calendar.StringHelper.encodeHtml(eventName);
        const optionalStartTime = !eventRecord.allDay ? CalendarLocaleManager.getFormattedTime(eventRecord.startDate) : '';
        return `<div class="b-event-name">${optionalStartTime} ${eventName}</div>
            ${this._getEventEndContent(eventRecord)}`;
    }

    _modifyMrEventNameStyling(eventRecord) {
        // eslint-disable-next-line no-undef
        let styledEventName = `<b><em>${bryntum.calendar.StringHelper.encodeHtml(eventRecord.name)}</em></b>`;
        if (eventRecord.status === 'Declined_vod') {
            styledEventName = `<s>${styledEventName}</s>`;
        }
        return styledEventName;
    }
    
    renderOverflowPopover(overflowData) {
        const eventData = overflowData.eventRecord.data;
        this.calendarEventType = CalendarEventTypeFactory.getEventType(eventData, this.translatedLabels);
        const eventEndContent = document.createElement('div');
        eventEndContent.className = 'event-end-content';

        CalendarEventIconManager.addAttendeeCountElt(eventEndContent, eventData, this.groupCallAttendeesEnabled);
        const callChannel = overflowData.eventRecord.remoteAttendeeNumber ? 'Video_vod' : eventData.callChannel;
        CalendarEventIconManager.addIconElt(eventEndContent, callChannel, 'icon-container call-channel');
        if (this.callConflictManager.needsConflictIcon(eventData)) {
            CallConflictManager.addCallConflictElement(eventEndContent);
        }

        if (overflowData.eventRecord.eventType === 'meeting-request') {
            const clockElt = document.createElement('i');
            clockElt.classList.add('fas');
            clockElt.classList.add('b-fa-clock');
            eventEndContent.appendChild(clockElt);
        }

        const eventNameElt = document.createElement('div');
        eventNameElt.className = "b-event-name";
        const optionalTime = !eventData.allDay ? CalendarLocaleManager.getFormattedTime(eventData.startDate) : '';
        
        if (overflowData.eventRecord.eventType === 'meeting-request') {
            eventNameElt.innerText = `${optionalTime} `;
            const boldElt = document.createElement('b')
            boldElt.innerText = this.calendarEventType.getEventName()
            const italicElt = document.createElement('em');
            italicElt.appendChild(boldElt);
            if (overflowData.eventRecord.status === 'Declined_vod') {
                const strikeElt = document.createElement('s');
                strikeElt.appendChild(italicElt);
                eventNameElt.appendChild(strikeElt);
            } else {
                eventNameElt.appendChild(italicElt);
            }
        } else {
            eventNameElt.innerText = `${optionalTime} ${this.calendarEventType.getEventName()}`
        }
        
        const bryntumContainerElt = document.createElement('div');
        bryntumContainerElt.className = 'b-cal-event-desc b-cal-event-desc-complex';
        bryntumContainerElt.appendChild(eventNameElt);
        bryntumContainerElt.appendChild(eventEndContent);
        return bryntumContainerElt;
    }

    static getIconHtml(iconType, className = "icon-container") {
        if (!iconType) return '';
        const imageName = CalendarEventIconManager.ICON_MAP[iconType];
        return imageName ? `<div class="${className}"><img class="event-icon" alt="${imageName}" src="${ICON_PATH}/${imageName}.svg" /></div>` : '';
    }

    static getAttendeeCountHtml(childCallNumber, groupCallAttendeesEnabled, className = "event-icon event-child-count") {
        return groupCallAttendeesEnabled && childCallNumber > 0 ? `<div class="${className}"> +${childCallNumber} </div>` : '';
    }

    static compareValues(val1, val2) {
        let res = 0;
        if (val1 < val2) {
            res = -1;
        } else if (val1 > val2) {
            res = 1;
        }
        return res;
    }

    static eventComparator(event1, event2) {
        // Handle event wrapping
        const e1 = event1.eventRecord || event1;
        const e2 = event2.eventRecord || event2;

        // all day/multi-day event handling, to start time, to sorted alphabetically
        if (e1.isInterDay || e1.allDay || e2.isInterDay || e2.allDay) {
            return CalendarModeManager.allDayEventComparator(e1, e2);
        }

        return CalendarModeManager.compareValues(e1.externalCalendarId?.toLowerCase() || '', e2.externalCalendarId?.toLowerCase() || '') || 
            CalendarModeManager.compareValues(e1.startDate, e2.startDate) ||
            CalendarModeManager.compareValues(e2.eventType === 'unavailable-time', e1.eventType === 'unavailable-time') || 
            CalendarModeManager.compareValues(e1.name.toLowerCase(), e2.name.toLowerCase());
    }

    static allDayEventComparator(event1, event2) {
        const e1 = event1.eventRecord || event1;
        const e2 = event2.eventRecord || event2;
        const isCompareAllDayEvents = e1.isInterDay && e1.allDay && e2.isInterDay && e2.allDay;
        const isCompareAllDayAndTimedEvents = (e1.isInterDay && !e1.allDay && e2.isInterDay && e2.allDay) || (e1.isInterDay && e1.allDay && e2.isInterDay && !e2.allDay);
        // Check for 1439 minutes duration as well as some event types have duration - 1 to account for midnight times. 
        const isOneSingleDay = (e1.duration <= 1440 && e1.allDay || e2.duration <= 1440 && e2.allDay);

        // longest multiday, to unavailable times, to sorted alphabetically
        if (!CreateCallDataFormatter.datesAreSameDay(new Date(e1.endDate.getTime() - 1), new Date(e2.endDate.getTime() - 1))) { // we don't consider events ending at midnight as occuring on the next day
            return e2.endDate - e1.endDate;
        }
        let dayOrStartDateCheck = CalendarModeManager.compareValues(e2.isInterDay === true, e1.isInterDay === true) || 
                    CalendarModeManager.compareValues(e2.allDay === true, e1.allDay === true);
        if (isOneSingleDay && (isCompareAllDayEvents || isCompareAllDayAndTimedEvents)) {
            dayOrStartDateCheck = e1.startDate - e2.startDate;
        }
        
        return CalendarModeManager.compareValues(e1.externalCalendarId?.toLowerCase() || '', e2.externalCalendarId?.toLowerCase() || '') || 
            dayOrStartDateCheck || 
            CalendarModeManager.compareValues(e2.eventType === 'unavailable-time', e1.eventType === 'unavailable-time') || 
            CalendarModeManager.compareValues(e1.name.toLowerCase(), e2.name.toLowerCase());
    }

}