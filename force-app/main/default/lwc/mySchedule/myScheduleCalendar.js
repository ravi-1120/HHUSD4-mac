import FIRSTDAYOFWEEK from '@salesforce/i18n/firstDayOfWeek';
import updateCallTime from '@salesforce/apex/VeevaMyScheduleController.updateCallTime';
import updateCalendarEntryTime from '@salesforce/apex/VeevaMyScheduleController.updateCalendarEntryTime';
import CalendarPopover from 'c/calendarPopover';
import { VeevaDateHelper } from 'c/veevaLocalizationHelper';
import EventDragHandler from 'c/eventDragHandler';
import CalendarSidebarPanel from 'c/calendarSidebarPanel';
import VeevaConfirmationLightningModal from 'c/veevaConfirmationLightningModal';
import CalendarEventStoreManager from 'c/calendarEventStoreManager';
import remoteMeetingInviteAEEnabled from '@salesforce/apex/VeevaMyScheduleController.remoteMeetingInviteAEEnabled';
import isDateOutsideOfCallObjectiveRange from '@salesforce/apex/VeevaMyScheduleController.isDateOutsideOfCallObjectiveRange';
import USER_ID from '@salesforce/user/Id';
import ICON_PATH from '@salesforce/resourceUrl/calendarIcons';
import CreateCallDataFormatter from 'c/createCallDataFormatter';
import CalendarEventIconManager from './calendarEventIconManager';
import CalendarLocaleManager from './calendarLocaleManager';
import CallConflictManager from './callConflictManager';
import ResourceStore from './resourceStore';

export default class MyScheduleCalendar {
    static MS_IN_MINUTE = 60 * 1000;
    static MIN_DURATION = 30;

    ctrl;
    element;
    messageService;
    clm;
    translatedLabels;
    settings;
    calendarObjectInfos;
    nonWorkingDays;
    calendar;
    eventStoreManager;
    callConflictManager;
    externalCalendarSetting;
    externalCalendarInfos;
    sessionService;
    eventIconManager;
    inConsoleMode;
    dragRecordBefore;
    calendarSidebarPanel;

    removeFromSchedulerPaneEvents;

    get myScheduleComponent() {
        return this.calendar.element.closest('c-my-schedule');
    }
    
    get accountSearchModal() {
        return this.element.closest('c-my-schedule').accountSearchModal;
    }

    static getInitialCalendar(temporarySchedule, modes, curView, curDate) {
        // eslint-disable-next-line no-undef
        const calendar = new bryntum.calendar.Calendar({
            appendTo: temporarySchedule.element,
            date : curDate,
            mode : curView,
            modes,
            weekStartDay: FIRSTDAYOFWEEK-1,
            nonWorkingDays: temporarySchedule.nonWorkingDays, 
            autoCreate: false,
            features : {
                drag : {
                    creatable : false,
                },
                eventEdit : null,
                eventMenu : null,
            },
            tbar: {
                items: {
                    toggleSideBar: {
                        icon: '',
                        cls: 'icon-button b-raised b-cal-nav-item',
                        html: `<img src="${ICON_PATH}/rows.svg" class="button-icon sidebar-toggle" alt="toggle sidebar"></img>`
                    },
                    todayButton: {
                        icon: '',
                        cls: 'icon-button b-raised b-cal-nav-item',
                        html: `<img src="${ICON_PATH}/calendarIconBlue.svg" class="button-icon" alt="calendarIcon"></img>`
                    },
                    prevButton: {
                        cls: 'b-raised b-cal-nav-item'
                    },
                    nextButton: {
                        cls: 'b-raised b-cal-nav-item'
                    },
                    settings:  {
                        type: 'slideToggle',
                        cls: 'calendar-toggle',
                        color: '#747474',
                        label: ' ',
                        labelPosition: 'before',
                        weight: 600,
                        checked : false
                    }
                }
            },
            sidebar: {
                items: {
                    eventFilter: null
                }
            }
        });
        temporarySchedule.clm.translateCalendar(CalendarLocaleManager.getBlankLabels(), calendar);
        return calendar;
    }

    constructor({ element, messageService, settings, calendarObjectInfos, eventStoreManager, translatedLabels, callConflictManager, calendarLocaleManager, externalCalendarInfo, sessionService, inConsoleMode, createCallService }) {
        this.element = element;
        this.messageService = messageService;
        this.settings = settings;
        this.calendarObjectInfos = calendarObjectInfos;
        this.eventStoreManager = eventStoreManager;        
        this.translatedLabels = { ...translatedLabels, userIdentifierLabel: this.calendarObjectInfos?.User?.fields?.User_Identifier_vod__c?.label };
        this.callConflictManager = callConflictManager;
        this.clm = calendarLocaleManager;
        this.externalCalendarInfos = externalCalendarInfo?.externalCalendars;
        this.externalCalendarSetting = externalCalendarInfo?.externalCalendarSetting;
        this.inConsoleMode = inConsoleMode;
        this.createCallService = createCallService;
        this.subordinatesInfo = externalCalendarInfo?.subordinatesInfo;

        this.nonWorkingDays = {};
        this.nonWorkingDays[this.clm.weekendDays[0]] = true;
        this.nonWorkingDays[this.clm.weekendDays[1]] = true;
        this.calendarSidebarPanel = new CalendarSidebarPanel(this.translatedLabels, externalCalendarInfo, this.settings, sessionService, this.eventStoreManager);        
        if (this.eventStoreManager) {
            this.eventStoreManager.shouldFetchExternalEvents = (this.externalCalendarSetting === 'showExtCalendar' && this.calendarSidebarPanel.getSelectedResourcesOnPageLoad().length > 0);
        }
    }

    async getCalendar(modes, eventStore, gridId) {
        const disableWeekends = MyScheduleCalendar.locateSettingWithDefault('disableWeekends', true);
        const currentDate = MyScheduleCalendar.locateSettingWithDefault('currentDate', new Date());
        const currentMode = MyScheduleCalendar.locateSettingWithDefault('currentView', 'week');
        const sidebarPanelItems = this.calendarSidebarPanel.getSidebarPanelItems(this.subordinatesInfo);
        if (eventStore && this.eventStoreManager.shouldFetchExternalEvents) {
            this.eventStoreManager.refreshEventType('External_Calendar_Event_vod__c');
        }
        const contextMenuWeights = this._sortContextMenuItems();

        // eslint-disable-next-line no-undef
        this.calendar = new bryntum.calendar.Calendar({
            appendTo: this.element,
            date : currentDate,
            mode : currentMode,
            modes,
            weekStartDay: FIRSTDAYOFWEEK-1,
            nonWorkingDays: this.nonWorkingDays,
            enableDeleteKey: false,
            autoCreate: {gesture: 'drag'},
            eventStore,
            resourceStore: ResourceStore.getResourceStore(this.externalCalendarInfos, this.calendarSidebarPanel.subordinates, this.settings.userName, this.translatedLabels),
            features : {
                externalEventSource : {
                    grid : gridId,
                },
                drag : {
                    creatable : false,
                    validateMoveFn : async moveInfo => this.validateCalendarDrag(moveInfo, false),
                    validateResizeFn : async dragInfo => this.validateCalendarDrag(dragInfo, true)
                },
                eventEdit : null,
                eventMenu : null,
                eventTooltip : {
                    align : 'l50-r50',
                    constrainTo : this.element,
                    tooltip : {
                        tools : {
                            delete : null,
                            edit : null
                        },
                        minWidth: 400,
                        maxWidth: 400,
                        maxHeight: 600
                    },
                    closable : false,
                    titleRenderer : null,
                    renderer : eventData => this._renderPopover(eventData)
                },
                scheduleMenu : {
                    items : {
                        addEvent : null,
                        createCall : this.calendarObjectInfos.Call2_vod__c?.createable ?
                            {
                                icon : 'b-fa-plus',
                                text : this.translatedLabels.addObjectTypeLabel.replace('{0}', this.calendarObjectInfos.Call2_vod__c.label),
                                onItem : clickInfo => this.handleCreateCallClick(clickInfo),
                                weight: 50
                            } : null,
                        createTot : this.calendarObjectInfos.Time_Off_Territory_vod__c?.createable ?
                            {
                                icon : 'b-fa-plus',
                                text : this.translatedLabels.addObjectTypeLabel.replace('{0}', this.calendarObjectInfos.Time_Off_Territory_vod__c.label),
                                weight: (contextMenuWeights.findIndex(item => item[0] === 'Time_Off_Territory_vod__c') + 1) * 100,
                                onItem : (clickInfo) => this._handleCreateTotClick(clickInfo)
                            } : null,
                        createUt : this.calendarObjectInfos.Unavailable_Time_vod__c?.createable ?
                            {
                                icon : 'b-fa-plus',
                                text : this.translatedLabels.addObjectTypeLabel.replace('{0}', this.calendarObjectInfos.Unavailable_Time_vod__c.label),
                                weight: (contextMenuWeights.findIndex(item => item[0] === 'Unavailable_Time_vod__c') + 1) * 100,
                                onItem : () => this.myScheduleComponent.openNewRecordModal('Unavailable_Time_vod__c')
                            } : null
                    },
                    processItems( {date, view, type} ) {
                        return type === 'scheduleclick' && !(date.getHours() === 0 && date.getMinutes() === 0 && date.getSeconds() === 0 && !view?.modeName);
                    }
                }
            },
            tbar: {
                items: {
                    toggleSideBar: {
                        icon: '',
                        cls: 'icon-button b-raised b-cal-nav-item',
                        html: `<img src="${ICON_PATH}/rows.svg" class="button-icon sidebar-toggle" alt="toggle sidebar"></img>`,
                        listeners: {
                            click: ({ source }) => {
                                if (source.element.classList.contains('toggled')) {
                                    source.element.classList.remove('toggled');
                                } else {
                                    source.element.classList.add('toggled');
                                }
                            }
                        }
                    },
                    todayButton: {
                        icon: '',
                        cls: 'icon-button b-raised b-cal-nav-item',
                        html: `<img src="${ICON_PATH}/calendarIconBlue.svg" class="button-icon" alt="calendarIcon"></img>`
                    },
                    prevButton: {
                        cls: 'b-raised b-cal-nav-item'
                    },
                    nextButton: {
                        cls: 'b-raised b-cal-nav-item'
                    },
                    settings:  {
                        type: 'slideToggle',
                        cls: 'calendar-toggle',
                        color: '#747474',
                        label: this.translatedLabels.weekendLabel,
                        labelPosition: 'before',
                        weight: 600,
                        checked : false,
                        listeners: {
                            change: (event)=> {
                                this._updateWeekendSetting(!event.checked);
                                this._addSettingsToStorage();
                            }
                        }
                    }
                }
            },
            sidebar: {
                items: sidebarPanelItems,
                maxWidth: '16.5em'
            },
            getEventElt(eventId, eltClass) {
                const eventElt = this.activeView.currentElement.querySelector(`div[data-event-id="${eventId}"`);
                return eventElt?.getElementsByClassName(eltClass)[0];
            }
        });
        this.eventIconManager = new CalendarEventIconManager(this.calendar, this.callConflictManager, this.settings.groupCallAttendeesEnabled);
        try {
            if (!disableWeekends) {
                this.calendar.element.querySelector('.calendar-toggle input').click();
            }
            this._updateWeekendSetting(disableWeekends);
        } catch (error) { // Suppress Brytnum error (that has a chance of occuring for locales with different weekends) as it does not affect the rendering of the page
            // eslint-disable-next-line no-console
            console.error(`Error applying initial show-weekend setting. Original Bryntum Calendar error here: ${error}`);
        }
        this.clm.translateCalendar(this.translatedLabels, this.calendar);
        this._addCalendarListeners(this.calendar);
        this.element.addEventListener('contextmenu', () => false, false); // Swallow right click behavior

        if (this.externalCalendarSetting === 'showExtCalendar' || this.calendarSidebarPanel.isManager){
            this._addExternalEventStyleSheet();
            eventStore.on('filter', () => { // set delay to allow subordinate events to render before displaying their icons
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => {
                    this.eventIconManager.handleAdditionalCallContent();
                }, 1000);
            });
        }
        // track which subordinate was previously selected if any
        const presentSubordinateUserId = this.calendarSidebarPanel.subordinates?.map(user => user.id)?.find(userId => this.calendarSidebarPanel.selectedResources?.includes(userId));
        if (presentSubordinateUserId) {
            this.eventStoreManager.setSubordinateUserId(presentSubordinateUserId);
        }

        // handle scenario where events have been loaded in before getCalendar finishes so the calendar was not able to update the call conflict manager
        if (eventStore && Object.keys(this.callConflictManager.callDatesByAccount).length < 1) {
            await this._newCallsHandler(this.calendar.events);
        }
        this._handleTimeFormats({ activeItem: { modeName: this.getView() }, source: this.calendar });

        return this.calendar;
    }
    
    _handleCreateTotClick(info) {
        if (!info.date || this.getView() === 'agenda') {
            return;
        }
        this.myScheduleComponent.openNewRecordModal('Time_Off_Territory_vod__c');
    }

    _sortContextMenuItems() {
        const menuLabels = [
            ['Time_Off_Territory_vod__c', this.translatedLabels.addObjectTypeLabel.replace('{0}', this.calendarObjectInfos.Time_Off_Territory_vod__c?.label)],
            ['Unavailable_Time_vod__c', this.translatedLabels.addObjectTypeLabel.replace('{0}', this.calendarObjectInfos.Unavailable_Time_vod__c?.label)],
            ['Event', this.translatedLabels.addCalendarEntryLabel],
        ];
        menuLabels.sort((label1, label2) => {
            if (label1[1] < label2[1]) {
                return -1;
            }
            if (label1[1] > label2[1]) {
                return 1;
            }
            return 0;
        })
        return menuLabels;
    }

    getPopoverInstance() {
        return CalendarPopover.getInstance(this.translatedLabels, this.calendarObjectInfos, this.inConsoleMode, this.createCallService);
    }

    _addExternalEventStyleSheet() {
        const OUTLOOK_BLUE = '#0072C6';
        const hexColorRegex = /#(?:[0-9a-fA-F]{3}){1,2}\b/;

        const style = document.createElement('style');
        let styling = `ul.b-resourcefilter .b-list-item.b-list-item-group-header.b-active:not(.b-disabled), ul.b-resourcefilter .b-list-item.b-list-item-group-header:focus:not(.b-disabled) {
                        background-color: transparent;
                    }`;
        this.externalCalendarInfos?.forEach(calendar => {
          const hasDefinedExternalCalendarColor = calendar.Hex_Color_vod__c != null && hexColorRegex.test(calendar.Hex_Color_vod__c);
          const externalCalendarColor = hasDefinedExternalCalendarColor ? calendar.Hex_Color_vod__c : OUTLOOK_BLUE;
          styling += `.${calendar.Id}-event.external-event .b-cal-event,
                      .${calendar.Id}-event.external-event.b-cal-event-wrap.b-intraday:not(.b-solid-bar) .b-cal-event:hover,
                      .${calendar.Id}-event.external-event.b-cal-event-wrap:not(.b-solid-bar).b-selected .b-cal-event,
                      .${calendar.Id}-event.external-event.b-cal-event-wrap:not(.b-solid-bar).b-active .b-cal-event {
                          border-color: ${externalCalendarColor};
                      }`;
          if (hasDefinedExternalCalendarColor) { 
            // override the checkbox color in the sidebar
            styling += `li.b-list-item.external-cal-resource.b-selected[data-id="${calendar.Id}"] div.b-selected-icon.b-icon[c-myschedule_myschedule] {
              color: ${externalCalendarColor};
            }`;
            // its not a default available option in outlook, but they could pick a custom color that is really white, add a bit of contrast
            if (this._isHexCloseToWhite(externalCalendarColor)) {
              styling += `li.b-list-item.external-cal-resource.b-selected[data-id="${calendar.Id}"] div.b-selected-icon.b-icon[c-myschedule_myschedule] {
                border: 0.5px solid black;
                border-radius: 2px;
                background-color: black;
              }`;
              styling += `li.b-list-item.external-cal-resource.b-selected[data-id="${calendar.Id}"] div.b-selected-icon.b-icon[c-myschedule_myschedule]:before {
                font-size: 149%;
              }`;
            }
          }
        })
        const styleStr = document.createTextNode(styling);
        style.appendChild(styleStr);
        // eslint-disable-next-line @lwc/lwc/no-document-query
        document.getElementsByTagName('head')[0].appendChild(style);
    }

    _isHexCloseToWhite(hex) {
      // Handle both three-character and six-character hex codes
      const hexx = (hex.length === 4) ? `#${hex[1]}${hex[1]}${hex[2]}${hex[2]}${hex[3]}${hex[3]}` : hex;
    
      const r = parseInt(hexx.substring(1, 3), 16);
      const g = parseInt(hexx.substring(3, 5), 16);
      const b = parseInt(hexx.substring(5, 7), 16);

      const threshold = 20;

      return (255 - r < threshold && 255 - g < threshold && 255 - b < threshold);
    }

    getView() {
        return this.calendar.mode.modeName || this.calendar.mode;
    }
    
    static locateSettingWithDefault(settingName, defaultValue) {
        const res = sessionStorage.getItem(settingName);
        if (res) {
            return res === "true" || res === "false" ? String(res) === "true" : res;
        }
        return defaultValue;
    }

    handleCreateCallClick(info) {
        if (!info.date || this.getView() === 'agenda') {
            return;
        }
        const clickData = CreateCallDataFormatter.processDataForCreateCall(info.date, this._getSameDayEventsFromCellMap(info.source.cellMap, info.date), false, 30,
            this.getView(), this.settings.allowedCallRecordTypes, this.settings.callBackdateLimit);
        this.accountSearchModal.showAccountSearchModal(clickData);
    }

    handleDateChange(info) {
        const newDate = info.date;
        if (!newDate) {
            return;
        }
        // if we navigate to weekend day when weekends are not visible, allow weekends to be visible again
        const showWeekendToggle = this.calendar.tbar.items.find(item => item.initialConfig.label === this.translatedLabels.weekendLabel);
        if (showWeekendToggle && this.clm.dateIsOnWeekend(newDate)) {
            this._updateWeekendSetting(false);
            showWeekendToggle.checked = true;
        }
        this.eventStoreManager.loadCalendarDataForDate(newDate, info.title);

        this.highlightSelectedAndCurrentDates(newDate);
        this.updateCallCyclePreviewEvents(newDate);
    }

    resetCalendarEventStore(records) {
        this.eventStoreManager.resetEventStore(records);
    }

    highlightSelectedAndCurrentDates(newDate) {
        if (!newDate) {
            return;
        }
        const today = CallConflictManager.getDateStr(new Date());
        const todayCell = this.calendar.element.querySelector(`div.b-today[data-date="${today}"][role="gridcell"]`);
        let todayNumElt = null;

        if (this.calendar.mode === 'month') {
            if (todayCell) {
                todayNumElt = this._getTodayElementMonthView(today);
            }
    
            // highlights todays date with orange circle - note class names are reversed
            if (todayNumElt) {
                todayNumElt.classList.add('b-today'); // creates circle
                todayNumElt.classList.add('b-selected'); // colors orange
            }
            
            // highlights the selected date with blue circle (b-today)
            const selectedElt = this._getSelectedElementMonthView(CallConflictManager.getDateStr(newDate));
            if (!selectedElt) {
                return;
            }
    
            const lastSelectedElt = Array.from(this.calendar.element.querySelectorAll('.b-today')).find(x => this._isDateElement(x) && x.dataset.date !== today);
            if (lastSelectedElt) {
                lastSelectedElt.classList.remove('b-today');
            }
            if (selectedElt.dataset.date !== today) {
                selectedElt.classList.add('b-today');
                if (todayNumElt) {
                    todayNumElt.classList.add('b-selected');
                }
            } else if (todayNumElt && selectedElt.dataset.date === today) {
                todayNumElt.classList.remove('b-selected'); // only blue circle appears if todays date is selected
            }
        } else if (this.calendar.mode === 'week' || this.calendar.mode === 'day') {
            if (todayCell) {
                todayNumElt = this._getTodayElementWeekDayView(today);
            }

            // highlights todays date with orange circle
            if (todayNumElt) {
                todayNumElt.classList.add('b-current-date');
            }
            
            // highlights the selected date with blue circle (b-today)
            const selectedElt = this._getSelectedElementWeekDayView(CallConflictManager.getDateStr(newDate));
            if (!selectedElt) {
                return;
            }

            this._removeLastHighlights(today);
    
            if (selectedElt.dataset.headerDate !== today) {
                selectedElt.classList.add('b-today');
                if (todayNumElt) {
                    todayNumElt.classList.remove('b-today');
                    todayNumElt.classList.add('b-current-date');
                }
            } else if (todayNumElt && selectedElt.dataset.headerDate === today) {
                selectedElt.classList.add('b-today');
            }
        }
    }

    // Allows for dates in other months to be highlighted on the sidebar when selected in the main calendar
    _handleDateClick(event) {
        const selectedDate = this.calendar.element.querySelector(`div[data-date="${CallConflictManager.getDateStr(event.date)}"][role="gridcell"]`);
        if (selectedDate) {
            const gridCells = this.calendar.element.querySelectorAll('div[role="gridcell"]');
            Array.from(gridCells).forEach(cell => {
                cell.classList.remove('b-selected-date');
                cell.classList.remove('b-active-date');
            });
            selectedDate.classList.add('b-selected-date');
        }
        this.handleDateChange(event);
    }

    // Adjust highlights upon changing current date range
    _adjustDateHighlights() {
        Promise.resolve().then(() => {
            const selectedDate = this.calendar.element.querySelector(`div.b-selected-date[role="gridcell"]`)?.dataset.date;
            if (!selectedDate) {
                return;
            }

            const today = CallConflictManager.getDateStr(new Date());

            if (this.calendar.mode === 'month') {
                const selectedElt = this._getSelectedElementMonthView(selectedDate);
                if (selectedElt) {
                    selectedElt.classList.add('b-today');
                }

                if (selectedDate === today) {
                    return;
                }

                const todayElt = this._getTodayElementMonthView(today);
                if (todayElt) {
                    todayElt.classList.add('b-selected');
                }
            } else if (this.calendar.mode === 'week' || this.calendar.mode === 'day') {
                this._removeLastHighlights(today);

                const selectedElt = this._getSelectedElementWeekDayView(selectedDate);
                if (selectedElt) {
                    selectedElt.classList.add('b-today');
                }

                if (selectedDate === today) {
                    return;
                }

                const todayElt = this._getTodayElementWeekDayView(today);
                if (todayElt) {
                    todayElt.classList.remove('b-today');
                    todayElt.classList.add('b-current-date');
                }
            }
        });
    }

    // Removes the highlights that currently exist in week and day view
    _removeLastHighlights(todayDate) {
        const lastSelectedEltList = Array.from(this.calendar.element.querySelectorAll('.b-today, .b-current-date'))
            .filter(x => x.getAttribute('role') === 'presentation' && x.dataset.headerDate && x.dataset.headerDate !== todayDate);
        if (lastSelectedEltList) {
            Array.from(lastSelectedEltList).forEach(elt => {
                elt.classList.remove('b-today');
                elt.classList.remove('b-current-date');
            });
        }
    }

    _getSelectedElementMonthView(selectedDate) {
        const selectedEltList = this.calendar.element.querySelectorAll(`[data-date="${selectedDate}"]`);
        return Array.from(selectedEltList).find(x => this._isDateElement(x));
    }

    _getSelectedElementWeekDayView(selectedDate) {
        if (this.calendar.mode === 'week') {
            return Array.from(this.calendar.element.querySelectorAll(`[data-header-date="${selectedDate}"]`)).find(elt => this._isWeekElement(elt));
        }
        return Array.from(this.calendar.element.querySelectorAll(`[data-header-date="${selectedDate}"]`)).find(elt => !this._isWeekElement(elt));
    }

    _getTodayElementMonthView(todayDate) {
        return Array.from(this.calendar.element.querySelectorAll('.b-monthview .b-weeks-container .b-calendar-row .b-calendar-cell .b-day-num'))
        .find(elt => elt.parentElement.parentElement && elt.parentElement.parentElement.dataset.date === todayDate);
    }

    _getTodayElementWeekDayView(todayDate) {
        if (this.calendar.mode === 'week') {
            return Array.from(this.calendar.element.querySelectorAll('.b-cal-cell-header')).find(
                elt => elt.dataset.headerDate === todayDate && this._isDraggableElement(elt) && this._isWeekElement(elt));
        }
        return Array.from(this.calendar.element.querySelectorAll('.b-cal-cell-header')).find(
            elt => elt.dataset.headerDate === todayDate && this._isDraggableElement(elt) && !this._isWeekElement(elt));
    }

    _isDateElement(elt) {
        return elt.getAttribute('role') === 'presentation' && elt.dataset.columnIndex !== undefined;
    }

    _isWeekElement(elt) {
        return elt.parentElement.parentElement.parentElement.parentElement.parentElement.classList.contains('b-weekview-content');
    }

    _isDraggableElement(elt) {
        return elt.parentElement.parentElement.parentElement && Array.from(elt.parentElement.parentElement.parentElement.classList).includes('b-draggable');
    }

    handleEventClick(info) {
        this.eventIconManager.handleEventSelection(info);
    }

    toggleScrollBar() {
        // if we're in week/day view, prevent the user from scrolling only if popover renders
        const eventId = this.calendar?.activeEvent?.id || (this.calendar?.selectedEvents?.length === 1 ? this.calendar?.selectedEvents[0].id : null);
        const overflowVal = this.getPopoverInstance().currentlyOpen && eventId ? 'hidden' : 'auto';
        this.calendar.element.querySelectorAll('.b-dayview-day-content').forEach(elt => {
            elt.style.overflowY = overflowVal;
        });
    }

    _addCalendarListeners(calendar) {
        calendar.on("catchAll", this._addSettingsToStorage.bind(this));
        calendar.on("resize", () => this.eventIconManager.handleAdditionalCallContent(true));
        calendar.on("activeItemChange", this._handleViewChange.bind(this));
        calendar.on('scheduleClick', info => this.calendar.features.scheduleMenu.showContextMenu(info));
        calendar.on('beforedatechange', this.handleDateChange.bind(this));
        calendar.on('eventClick', this.handleEventClick.bind(this));
        calendar.on('dragMoveEnd', this.handleEventDrag.bind(this));
        calendar.on('dragResizeEnd', this.handleEventDrag.bind(this));
        calendar.on('scheduleMenuBeforeShow', this._handleDateClick.bind(this));
        calendar.on('dateRangeRequested', this._adjustDateHighlights.bind(this));
        ["activeItemChange", "dateRangeChange", "show"].forEach(event => {
            // timeout just ensures all event elts are fully loaded in DOM before we manipulate them
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            calendar.on(event, () => setTimeout(() => {
                this.eventIconManager.handleAdditionalCallContent();
            }, 0));
        });
        calendar.features.eventTooltip.tooltip.on('hide', this._handlePopoverClose.bind(this));
        calendar.eventStore.on('beforeRemove', e => this.callConflictManager.updateCallDatesByAccount(null, CallConflictManager.getCallsWithAccount(e.records)));
        calendar.eventStore.on('add', this._handleNewCalls.bind(this));
        
        if (Object.keys(calendar.modes).includes('agenda')) {
            const oldToggle = calendar.modes.agenda.listRangeMenu.onToggle;
            calendar.modes.agenda.listRangeMenu.onToggle = (info) => {
                oldToggle(info);
                if (info.checked) {
                    const range = info.item.text.toLowerCase();
                    this.eventStoreManager.updateDateTrackerView(range);
                    this.handleDateChange({ date : calendar.date, title : range });
                }
            }
        }

        // workaround for Bryntum not respecting resource filter--if there are zero selected resources, then only add external events to calendar once the resources have been clicked once (after that resource filter functions as expected)
        if (this.externalCalendarSetting === 'showExtCalendar' && this.calendarSidebarPanel.getSelectedResourcesOnPageLoad()?.length === 0) {
            this.calendar.element.querySelectorAll('.b-resourcefilter li').forEach(resource => {
                resource.addEventListener("click", () => {
                    this.eventStoreManager.shouldFetchExternalEvents = true;
                    this.eventStoreManager.refreshEventType('External_Calendar_Event_vod__c');
                }, {once: true});
            });
        }
    }

    async validateCalendarDrag({ eventRecord, drag }, isResize = false) {
        if (typeof eventRecord.data.cls === 'string' && eventRecord.data?.cls.includes('call-cycle-temp-event')) {
            return false;
        }
        this.dragRecordBefore = {...drag.data?.get('eventRecord')?.data};

        const passesDragValidationsNoModal = EventDragHandler.passesDragValidationsNoModal(eventRecord, drag, this.calendar.activeView.modeName, isResize, this.dragRecordBefore);
        if (!passesDragValidationsNoModal) {
            return false;
        }
        const valid = EventDragHandler.checkBackDateLimitOnDrag(eventRecord, this.settings.callBackdateLimit, this.dragRecordBefore);
        if (!valid) {
            this.myScheduleComponent.openErrorModal(this.translatedLabels.backdateMsg.replace('{0}', this.settings.callBackdateLimit));
            return false;
        }

        if (eventRecord.objectType === 'Call2_vod__c' && await isDateOutsideOfCallObjectiveRange({ callId : eventRecord.recordId, newDate : CallConflictManager.getDateStr(eventRecord.startDate) })) {
            // open warning modal
            const res = await VeevaConfirmationLightningModal.open({
                title: this.translatedLabels.warningLabel,
                messages: [this.translatedLabels.callObjectiveWarningLabel],
                size: 'small'
            });
            return !!res;
        }
        return true;
    }

    _getSameDayEventsFromCellMap(dayCellInfo, startDate) {
        // eslint-disable-next-line no-undef
        const adjustedDate = bryntum.calendar.TimeZoneHelper.fromTimeZone(startDate, this.clm.orgTimeZone);
        const fullDate = CallConflictManager.getDateStr(adjustedDate);
        let dayInfo = dayCellInfo?.get(fullDate);
        if (dayInfo) {
            dayInfo = dayInfo.events;
            dayInfo = dayInfo.map(e => e.eventRecord?.data || e.data);
        } else {
            dayInfo = [];
        }
        return dayInfo;
    }

    _createCallFromSchedulerPane(dragEvent) {
        const callInfo = CreateCallDataFormatter.processDataForCreateCall(dragEvent.eventRecord.startDate, this._getSameDayEventsFromCellMap(dragEvent.view?.cellMap, dragEvent.eventRecord.startDate), dragEvent.eventRecord.allDay, 30, 
            this.getView(), this.settings.allowedCallRecordTypes, this.settings.callBackdateLimit);
        const accountInfo = {
            id: dragEvent.eventRecord.accountId,
            displayedName: dragEvent.eventRecord.data.name
        }
        this.calendar.element.closest('c-my-schedule').createCall(callInfo, accountInfo, true);
    }
    
    async _updateEventOnDrag(dragEvent) {
        const { eventRecord: { data } } = dragEvent;

        const {record, duration} = EventDragHandler.updateEventStoreRecord(dragEvent, this.calendar.eventStore, this.dragRecordBefore);
        const updateRemoteMeeting = data.eventType === 'call' && data.startDate !== this.dragRecordBefore.startDate;

        // prevent dragging or resizing of record until update operation is complete or current record is replaced in the eventStore
        const { resizable, draggable } =  record;
        record.resizable = false;
        record.draggable = false;

        // eslint-disable-next-line no-undef
        let startDate = bryntum.calendar.TimeZoneHelper.fromTimeZone(data.startDate, this.clm.orgTimeZone);

        let eventDateTimeRes;
        if (data.objectType === 'Call2_vod__c') {
            const hasDateTimePermission = this.calendarObjectInfos.Call2_vod__c?.fields.Call_Datetime_vod__c?.updateable || false;
            eventDateTimeRes = await updateCallTime({ recordId: record.id, startDate, duration, allDay: data.allDay, hasDateTimePermission, updateRemoteMeeting });
        } else if (data.objectType === 'Event') {
            // eslint-disable-next-line no-undef
            let endDate = bryntum.calendar.TimeZoneHelper.fromTimeZone(data.endDate, this.clm.orgTimeZone);
            if (data.allDay) {
                startDate = data.startDate;
                endDate = data.endDate;
            }
            eventDateTimeRes = await updateCalendarEntryTime({ recordId: record.id, startDate, endDate });
        }

        if (this.getPopoverInstance().currentlyOpen) {
            this.calendar.features.eventTooltip.tooltip.close();
        }

        this._handlePopoverClose(undefined, true);
        
        if (eventDateTimeRes.error) {
            // display error
            this.myScheduleComponent.openErrorModal(eventDateTimeRes.error);
            EventDragHandler.revertEvent(record, this.dragRecordBefore, this.calendar.eventStore);
        } else if (eventDateTimeRes.data) {
            record.eventDateTime = eventDateTimeRes.data;
            CalendarEventStoreManager.addFrontEndProperties([record], this.calendarObjectInfos.Call2_vod__c?.updateable, this.calendarObjectInfos.Event?.updateable);
            if (data.objectType === 'Call2_vod__c') {
                if (eventDateTimeRes?.engageRemoteMeeting === 'error'  && eventDateTimeRes?.remoteMeetingType ==='Engage_Meeting_vod') {
                    this.calendar.element.closest('c-my-schedule').openErrorModal(this.translatedLabels.scheduleEngageFailedMsg);
                }
                if (eventDateTimeRes?.msTeamsRemoteMeeting === 'error'  && eventDateTimeRes?.remoteMeetingType ==='MS_Teams_Meeting_vod' ) {
                    this.calendar.element.closest('c-my-schedule').openErrorModal(this.translatedLabels.scheduleMSTeamsFailedMsg);
                }
                this.callConflictManager.updateCallDatesByAccount([record], [this.dragRecordBefore]);

                if (record.remoteAttendeeNumber && updateRemoteMeeting) {
                    if (this.settings.canSendRemoteApprovedEmails === undefined) {
                        this.settings.canSendRemoteApprovedEmails = await remoteMeetingInviteAEEnabled();
                    }
                    if (this.settings.canSendRemoteApprovedEmails && eventDateTimeRes?.remoteMeetingType ==='Engage_Meeting_vod') {
                        this.myScheduleComponent.handleSendRemoteMeetingInvite(record.id);
                        await this.eventStoreManager.updateScheduleDataForEvent(record.id, "Call2_vod__c");
                    }
                }
                this.eventIconManager.handleAdditionalCallContent();

                // set dragging/resizing properties back to original value after record has been fully updated
                record.resizable = resizable;
                record.draggable = draggable;
            } else if (data.objectType === 'Event') {
                this.eventStoreManager.refreshEventType('Event'); // update all events in range to capture changes from recurring event series
            }
        }
        
    }

    async handleEventDrag(dragEvent) {
        if (dragEvent?.eventRecord?.data?.fromSchedulerPane) {
            this._createCallFromSchedulerPane(dragEvent);
        } else {   
            await this._updateEventOnDrag(dragEvent);
        }
    }

    _handlePopoverClose(event = null, isDragOrResizeEvent = false) {
        this.getPopoverInstance().currentlyOpen = false;
        const eventData = this.calendar.activeEvent?.data;

        // If resizing an event, we force the focus back to the resized event to prevent the scrollbar from jumping to focus on the next event
        // Otherwise, focus is only reverted if the current widget has focus
        this.calendar.revertFocus(isDragOrResizeEvent);

        if (event) {
            event.source.hide();
        }
        this.toggleScrollBar();
        this.eventIconManager.handleEventDeSelection(eventData);
    }

    async _handleNewCalls(event) {
        if (event.records[0].fromSchedulerPane && this.removeFromSchedulerPaneEvents) {
            const events = this.calendar.events.filter(e => !e.fromSchedulerPane);
            this.calendar.eventStore.removeAll();
            this.calendar.eventStore.add(events);
            this.removeFromSchedulerPaneEvents = false;
        }
        const eventToFocus = event.records.find(record => record.id === this.focusedRecordId);
        if (eventToFocus) {
            this._openEventPopover(eventToFocus);
        }
        await this._newCallsHandler(event.records.filter(record => record.objectType === 'Call2_vod__c'));
    }

    async _newCallsHandler(events) {
        const newCalls = CallConflictManager.getCallsWithAccount(events);
        this.callConflictManager.updateCallDatesByAccount(newCalls, null);
        
        if (events.length > 0 && events[0].resourceId === USER_ID) {
            await this.callConflictManager.checkForCallsInRelatedAccounts(this.eventStoreManager.getFormattedCurrentDateRange(), [...new Set(newCalls.map(callEvent=>callEvent.accountId))], [...new Set(newCalls.map(callEvent=>callEvent.id))]);
        }
        this.eventIconManager.handleAdditionalCallContent();
    }

    _updateWeekendSetting(hideNonWorkingDays) {
        if (hideNonWorkingDays && this.getView() === 'day' && this.clm.dateIsOnWeekend(this.calendar.date)) {
            const showWeekendToggle = this.calendar.tbar.items.find(item => item.initialConfig.label === this.translatedLabels.weekendLabel);
            showWeekendToggle.checked = true;
            return; // if user is in day view on a weekend, do not allow weekends to be toggled off
        }
        Object.keys(this.calendar.modes).forEach(view => {
            this.calendar.modes[view].hideNonWorkingDays = hideNonWorkingDays;
        });
        this.myScheduleComponent.updateSchedulerView({ showWeekends: !hideNonWorkingDays });
        
        if (!hideNonWorkingDays || this.getView() === 'agenda') { // check for icons when weekend IS visible
            this.eventIconManager.handleAdditionalCallContent();
        }
        
    }

    _openEventPopover(event) {
        // trigger event popover when event is rendered in dom
        // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
        setTimeout(()=> {
            this._scrollToEvent(event);
            const eventToFocus = this.calendar.element.querySelector(`div[data-event-id="${this.focusedRecordId}"]`);
            // first click triggers multiple popovers if they were not previously closed
            eventToFocus?.click();

            // remove extra popovers
            if (this.focusedRecordId) {
                window.calendar.element.parentElement.querySelectorAll(`.b-popup:not(:has(.${this.focusedRecordId}-popover))`).forEach(popover => popover.remove());

                this.getPopoverInstance().currentlyOpen = true;
                this.calendar.select(this.calendar.eventStore.findRecord('id', this.focusedRecordId) || []);
                this.toggleScrollBar();
                this.focusedRecordId = null;
            }
        }, 1000);
    }

    _scrollToEvent(event) {
        let tickNum;
        if (event.startDate.getHours() >= 9) {
            tickNum = event.startDate.getHours() + 1;
        } else {
            tickNum = `0${event.startDate.getHours() + 1}`;
        }
        const tickNumElement = window.calendar.element.querySelector(`.b-weekview-content .b-dayview-timeaxis-time.b-dayview-timeaxis-time-${tickNum}`);
        // eslint-disable-next-line no-undef
        if (!this._inAllDayHeader(event) && !bryntum.calendar.DomHelper.isInView(tickNumElement)) {
            tickNumElement.scrollIntoView();
        }
        if (this._inAllDayHeader(event)) {
            window.calendar.element.querySelector(`[data-event-id="${this.focusedRecordId}"]`)?.scrollIntoView();
        }
    }

    _inAllDayHeader(event) {
        return !CreateCallDataFormatter.datesAreSameDay(event.startDate, event.endDate) || event.allDay;
    }

    _addSettingsToStorage() {
        sessionStorage.setItem('disableWeekends', this.calendar.modes.week.hideNonWorkingDays);
        sessionStorage.setItem('currentView', this.calendar.activeView.modeName);
        sessionStorage.setItem('currentDate', this.calendar.activeView.date); 
        sessionStorage.setItem('agendaRange', this.calendar.modes.agenda?.range.unit); 
        sessionStorage.setItem(`selectedExternalCalendars;${USER_ID}`, JSON.stringify(this.calendar.sidebar.items.find(item => item.initialConfig.ref === 'resourceFilter')?.selected?.values?.map(resource => resource.data?.id)));
    }

    _renderPopover(data) {
        // disable popover for temp calls
        if (data.eventRecord.data.id.toString().startsWith('_generatedt_')) {
            return null;
        }
        if (!data.activeTarget) {
            data.activeTarget = this.calendar.getEventElt(data.eventRecord.data.id, 'b-cal-event');
        }
        const popoverInfo = data.eventRecord.data;
        popoverInfo.isSubordinateEvent = popoverInfo.resourceId && this.calendarSidebarPanel.subordinates?.map(sub => sub.id).includes(popoverInfo.resourceId);

        const domConfigObj = this.getPopoverInstance().populate(popoverInfo, this.settings, this.calendar);
        if (data.activeTarget) {
            this.toggleScrollBar();
        }
        return domConfigObj;

    }
 
    _handleViewChange(event) {
        this.eventStoreManager.updateDateTrackerView(event.activeItem.modeName !== 'agenda' ? event.activeItem.modeName : this.calendar.modes.agenda.range.unit);
        const curDate = new Date(event.activeItem.date);
        this.myScheduleComponent.updateSchedulerView({ view: event.activeItem.modeName, targetDay: curDate.getDay() });
        
        if (event.activeItem.modeName === 'month' || event.activeItem.modeName === 'agenda') {
            this.handleDateChange({'date': curDate, 'title': this.calendar.modes.agenda?.range?.unit});
        } else {
            this._adjustDateHighlights();
            this._handleTimeFormats(event);
        }
    }

    _handleTimeFormats(event) {
        const pmTranslation = this.clm.getMeridiemForUsersLanguage(false);
        if (!pmTranslation || pmTranslation.toLowerCase() === 'pm') {
            return; // Only need to make adjustment in week view for locales using a meridiem in combination with a language that does not use latin characters
        }
        // Need to replace the translated am string for the second half of the day with the correct character(s)
        const amTranslation = this.clm.getMeridiemPlaceHolderForDateFormatString();
        Array.from(new Array(12), (x, i) => i + 12).forEach(timeInt => {
            const axisSelector =  `.b-dayview-timeaxis-time-${timeInt} .b-dayview-hour-tick`;
            const timeAxisElts = event.source.element.querySelectorAll(axisSelector);
            timeAxisElts.forEach((elt) => {
                elt.innerText = elt.innerText.replace(amTranslation, pmTranslation);
            });
        });
    }

    updateCallCyclePreviewEvents(updatedDate) {
        this.setStartDateForCallCycles(updatedDate, this.calendar.events.filter(e => e.data?.eventType === 'call-cycle-entry'), this.previewOnDay);
    }

    previewCallCycleEvents(callCycleEvents, previewOnDay) {
        this.previewOnDay = previewOnDay;
        this.clearCallCycleEvents();
        const callCycles = [];
        callCycleEvents.forEach(callCycle => {
            callCycles.push(JSON.parse(JSON.stringify(callCycle)));
        });
        this.setStartDateForCallCycles(this.calendar.date, callCycles, previewOnDay);
        this.calendar.eventStore.add(callCycles);
    }

    clearCallCycleEvents() {
        const callCycleEvents = this.calendar.events.filter(e => e.data?.eventType === 'call-cycle-entry');
        this.calendar.eventStore.remove(callCycleEvents);
    }

    setStartDateForCallCycles(calendarDate, callCycles, previewOnDay) {
        callCycles?.forEach(callCycle => {
            const callCycleStartDate = this.calendar.activeView.modeName === 'week' ?
                VeevaDateHelper.getDateForWeekDay(calendarDate, callCycle.dayOfWeek === 0 ? 0 : callCycle.dayOfWeek || callCycle.data?.dayOfWeek, previewOnDay) : new Date(calendarDate);
            const timeObj = new Date(`${new Date().toDateString()} ${callCycle.Start_Time_vod__c || callCycle.data?.Start_Time_vod__c}`);
            callCycleStartDate.setHours(timeObj.getHours());
            callCycleStartDate.setMinutes(timeObj.getMinutes());
            callCycle.startDate = callCycleStartDate;
        });
    }

    static setFocusDate(dateStr) {
        const dateParts = dateStr.split(' ')[0].split('-');
        sessionStorage.setItem('currentDate', new Date(dateParts[0], dateParts[1] - 1, dateParts[2]));
    }
}