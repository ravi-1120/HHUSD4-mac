import ICON_PATH from '@salesforce/resourceUrl/calendarIcons';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import EventDragHandler from 'c/eventDragHandler';
import { VeevaDateHelper } from 'c/veevaLocalizationHelper';
import CallCycleCalendarWeekPane from './callCycleCalendarWeekPane';
import CallCycleCalendarResourceStore from './callCycleCalendarResourceStore';
import { getCallCycleEventStore, updateCallCycleFrontEndProperties, addCallCycleEventToStore } from './callCycleCalendarEventStore';

export default class CallCycleCalendar {
    static DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    selectedWeekPane = 1;

    recordsToDelete = [];

    constructor({ element, schedulerEventStore, translatedLabels, disableWeekends, nonWorkingDays, calendarObjectInfos, settings, calendarLocaleManager }) {
        this.element = element;
        this.schedulerEventStore = schedulerEventStore;
        this.translatedLabels = translatedLabels;
        this.disableWeekends = disableWeekends;
        this.nonWorkingDays = nonWorkingDays;
        this.calendarObjectInfos = calendarObjectInfos;
        this.settings = settings;
        this.clm = calendarLocaleManager;
    }
    
    async getManageCallCycleCalendar() {

        this.headerContainer = this.getHeaderContainer();

        this.calendarContainer = await this.getCalendarContainer();

        this.callCycleCalendarWeekPane.resourceFilter.on('change', (e) => this.onWeekChange(e));
        
        return this.calendar;
    }

    getHeaderContainer() {
        // eslint-disable-next-line no-undef
        const headerPanel = new bryntum.calendar.Panel(this.getHeaderPanelConfig());

        // eslint-disable-next-line no-undef
        return new bryntum.calendar.Container({
            appendTo: this.element,
            items: [headerPanel],
            width: '100%',
        });
    }

    async getCalendarContainer() {
        this.eventStore = await getCallCycleEventStore(this.schedulerEventStore, CallCycleCalendar.DAYS);

        this.resourceStore = CallCycleCalendarResourceStore.getResourceStore(this.translatedLabels.weekXLabel);

        // eslint-disable-next-line no-undef
        this.calendar = new bryntum.calendar.Calendar(this.getCalendarConfig());        
        this._addCalendarListeners();
        this.clm.translateCalendar(this.translatedLabels, this.calendar);
        this.callCycleCalendarWeekPane = new CallCycleCalendarWeekPane({calendar: this.calendar, resourceStore: this.resourceStore, translatedLabels: this.translatedLabels, callObjectInfos: this.calendarObjectInfos.Call2_vod__c, selected: this.selectedWeekPane});
        this.weekPane = this.callCycleCalendarWeekPane.getCallCycleCalendarWeekPane();

        // eslint-disable-next-line no-new,no-undef
        return new bryntum.calendar.Container({
            appendTo: this.headerContainer.element,
            items: [this.weekPane, this.calendar],
            width: '100%',
            height: '100%',
            layout : {
                type : 'box'
            }
        });
    }

    getHeaderPanelConfig() {
        return {
            html: `<div class='manage-call-cycle-header'>${this.translatedLabels.manageCallCyclesLabel}</div>`,
            style: 'border-bottom: 1px solid #ddd',
            items : [
                {
                    type : 'button',
                    dock: 'right',
                    cls: 'manage-call-cycle-done',
                    text: this.translatedLabels.doneLabel,
                    onClick: async () =>{
                        await this.updateEventStore();
                        this.getMySchedule().toggleToMyScheduleCalendar();
                    }
                }
             ],
             height: '64px',
             width: '100%',
        }
    }

    getCalendarConfig() {
        return {
            date: new Date(),
            modes    : {
                day    : null,
                week   : {
                    visibleStartTime : 7.5,
                    nonWorkingDays: this.nonWorkingDays,
                    hideNonWorkingDays: this.disableWeekends,
                    hourHeight : 70,
                    shortEventDuration : null,
                    shortEventCls: null,
                    increment : '30 minutes',
                    showTime : false,
                    hourHeightBreakpoints: [],
                    descriptionRenderer: () => this.descriptionRenderer(),
                    eventRenderer: ({eventRecord}) => this._renderEvent(eventRecord),
                    dayHeaderRenderer: this._dayHeaderRenderer
                },
                month  : null,
                year   : null,
                agenda : null
            },
            cls: 'manage-call-cycle-calendar',
            eventStore: this.eventStore,
            resourceStore: this.resourceStore,
            sidebar: null,
            autoCreate: {gesture: null},
            features: {
                eventEdit : null,
                eventMenu : null,
                eventTooltip : null,
                drag : {
                    creatable : false,
                    validateMoveFn : moveInfo => this.validateCalendarDrag(moveInfo, false),
                    validateResizeFn : dragInfo => this.validateCalendarDrag(dragInfo, true)
                },
                scheduleMenu : {
                    items : {
                        addEvent : null,
                        createCall : {
                            icon : 'b-fa-plus',
                            text : this.translatedLabels.addObjectTypeLabel.replace('{0}', this.calendarObjectInfos.Call_Cycle_Entry_vod__c.label),
                            onItem : clickInfo => this.handleCreateCallCycleEntry(clickInfo),
                            weight: 50
                        },
                    },
                    processItems(event) {
                        return event.domEvent.type === 'click' && !(event.date.getHours() === 0 && event.date.getMinutes() === 0 && event.date.getSeconds() === 0);
                    }
                }
            },
            scrollable: true,
            tbar: {
                cls: 'manage-call-cycle-calendar-toolbar',
                items: {
                    todayButton: null,
                    spacer: null,
                    prevButton: null,
                    nextButton: null,
                    modeSelector: null
                }
            }
        }
    }

    descriptionRenderer() {
        const week = this.callCycleCalendarWeekPane.resourceFilter?.selected?.values[0]?.id;
        return `<div class='call-cycle-calendar-week-selected-header'>${this.translatedLabels.weekXLabel.replace('{0}', week)}</div>`;
    }

    _dayHeaderRenderer(headerDomConfig, cellData) {
        const day = CallCycleCalendar.DAYS[cellData.day];
        headerDomConfig.className.add('manage-call-cycle-calendar-day-header');
        headerDomConfig.children[0].className = 'call-cycle-calendar-day-of-week';
        headerDomConfig.children[1].className = 'call-cycle-calendar-day-of-week call-cycle-calendar-day-of-week-count';
        headerDomConfig.children[1].text = `\u00A0(${this.calendar.events.filter(event => event.day === day && !event.deleted).length})`;
    }

    onWeekChange() {
        this.updateEventStore();
        this.calendar.refresh();
    }

    async updateEventStore() {
        if (this.recordsToDelete.length > 0) {
            const deletePromises = this.recordsToDelete.map(recordId => deleteRecord(recordId));
            await Promise.all(deletePromises);
            
            this.eventStore.remove(this.recordsToDelete);
            this.recordsToDelete = [];
        }
        this.weekPane.items[0].refresh();
    }

    async onDelete(event) {
        const entryElt = event.currentTarget;
        const cycleId = entryElt.getAttribute('data-id');
        
        const cycleEntryContainerElt = this.calendar.getElementFromEventRecord(cycleId);
        const eventDeleted = this.calendar.resolveEventRecord(cycleEntryContainerElt);
        eventDeleted.deleted = true;

        if (!this.recordsToDelete.includes(cycleId)) {
            this.recordsToDelete.push(cycleId);
        }
        entryElt.parentElement.appendChild(this._createCallCycleEntryDeleteButton(cycleId, true));
        entryElt.parentElement.removeChild(entryElt);
        cycleEntryContainerElt.classList.add('deleted-entry');
        this._updateCallCycleEntryCounts();
    }

    async onUndoDelete(event) {
        const entryElt = event.currentTarget;
        const cycleId = entryElt.getAttribute('data-id');
        const cycleEntryContainerElt = this.calendar.getElementFromEventRecord(cycleId);
        
        const index = this.recordsToDelete.indexOf(cycleId);
        if (index > - 1) {
            this.recordsToDelete.splice(index, 1);
        }
        
        entryElt.parentElement.appendChild(this._createCallCycleEntryDeleteButton(cycleId, false));
        entryElt.parentElement.removeChild(entryElt);
        cycleEntryContainerElt.classList.remove('deleted-entry');

        const eventDeleted = this.calendar.eventStore.findRecord('recordId', cycleId);
        eventDeleted.deleted = false;

        this._updateCallCycleEntryCounts();
    }

    _updateCallCycleEntryCounts() {
        // refreshing the below components would update weekpane and header counts
        this.weekPane.items[0].refresh();
        this.calendar.updateViewDescription();
        this.calendar.refresh();
    }

    _renderEvent(record) {
        const endContent = document.createElement("div");
        endContent.className = "event-end-content";
        const iconContainer = document.createElement("div");
        iconContainer.className = "icon-container";
        iconContainer.appendChild(this._createCallCycleEntryDeleteButton(record.id, record.deleted));
        endContent.appendChild(iconContainer);
        
        const eventContent = document.createElement("div");
        eventContent.className = "call-cycle-event one-line-truncation";
        eventContent.textContent = record.account;
        eventContent.appendChild(endContent);

        const container = document.createElement("div");
        container.appendChild(eventContent);
        document.createElement("div").appendChild(container);
        return container;
    }

    _createCallCycleEntryDeleteButton(id, isUndo = false) {
        const btnContainer = document.createElement("button");
        btnContainer.className = "slds-button slds-button_icon slds-float_right";
        btnContainer.setAttribute('data-ref', isUndo ? "undo" : "delete");
        btnContainer.setAttribute('data-id', id);
        btnContainer.addEventListener('click', isUndo ? this.onUndoDelete.bind(this) : this.onDelete.bind(this));

        const btnIcon = document.createElement("img");
        btnIcon.className = "call-cycle-icon";
        btnIcon.src = `${ICON_PATH}/${isUndo ? "undelete" : "delete"}.svg`;
        btnIcon.alt = isUndo ? "undelete" : "delete";
        
        btnContainer.appendChild(btnIcon);
        return btnContainer;
    }

    async reRenderCalendar(disableWeekends, schedulerEventStore) {
        this.schedulerEventStore = schedulerEventStore;
        this.selectedWeekPane = this.callCycleCalendarWeekPane.resourceFilter?.selected?.values[0]?.id;
        this.disableWeekends = disableWeekends;
        this.calendar = await this.getManageCallCycleCalendar();
        return this.calendar;
    }

    getMySchedule() {
        return this.element?.closest('c-my-schedule');
    }
    
    _addCalendarListeners() {
        this.calendar.on('scheduleClick', info => this.calendar.features.scheduleMenu.showContextMenu(info));
        this.calendar.on('dragMoveEnd', async dragEvent => this._updateEventOnDrag(dragEvent));
        this.calendar.on('dragResizeEnd', async dragEvent => this._updateEventOnDrag(dragEvent));
    }

    async _updateEventOnDrag(dragEvent) {
        const { eventRecord: { data } } = dragEvent;
        const {record, duration} = EventDragHandler.updateEventStoreRecord(dragEvent, this.calendar.eventStore, this.dragRecordBefore);
        updateCallCycleFrontEndProperties([record]);
        record.day = data.startDate.toLocaleDateString('en-US', {weekday:'long'});

        try {
            // uses en-US because Call_Cycle_Entry_vod fields expect day/time values in this format
            await updateRecord({
                fields: {
                    Id: record.id,
                    Duration_vod__c: duration,
                    Day_of_Week_vod__c: record.day,
                    Start_Time_vod__c: data.startDate.toLocaleString('en-US', {hour: 'numeric', minute: 'numeric'})
                }
            })
        } catch (e) {
            this.getMySchedule().openErrorModal(e.body?.output?.errors[0]?.message);
            EventDragHandler.revertEvent(record, this.dragRecordBefore, this.calendar.eventStore);
        };
    }

    validateCalendarDrag({ eventRecord, drag }, isResize = false) {
        if (this.recordsToDelete.includes(eventRecord.recordId)) {
            return false;
        }
        this.dragRecordBefore = {...drag.data?.get('eventRecord')?.data};
        const passesDragValidationsNoModal = EventDragHandler.passesDragValidationsNoModal(eventRecord, drag, this.calendar.activeView.modeName, isResize, this.dragRecordBefore);
        if (passesDragValidationsNoModal) {
            return true;
        }
        return false;
    }

    handleCreateCallCycleEntry(info){
        const eventData = this.addAttributesForEventCreation(info.date, false);
        this.addCallCycleEventAttributes(eventData);
        this.accountSearchModal.showAccountSearchModal(eventData);
    }

    getView() {
        return this.calendar.mode.modeName || this.calendar.mode;
    }
    

    addAttributesForEventCreation(startDate, allDay) {
        const eventInfo = {
            view: this.getView(),
            allowedCallRecordTypeSettings: this.settings.allowedCallRecordTypes,
            backdateLimit: this.settings.callBackdateLimit,
            orgTimeZone: TIME_ZONE,
            date: startDate,
            dateStr: startDate.toGMTString(),
            allDay,
            eventType: 'call-cycle-calendar-entry'
        }
        return eventInfo;
    }

    addCallCycleEventAttributes(eventData){
        const week = this.callCycleCalendarWeekPane.resourceFilter?.selected?.values[0]?.id;
        const dayOfWeek = CallCycleCalendar.DAYS[eventData.date.getDay()];

        eventData.week = week;
        eventData.resourceId = week;
        eventData.day = dayOfWeek;
        eventData.duration = '30';
    }

    addCallCycleEventToCalendar(event){
        addCallCycleEventToStore(event, this.calendar.eventStore, CallCycleCalendar.DAYS);
        this._updateCallCycleEntryCounts();
    }

    getEventDate(callCycleEntry, days) {
        const index = days.indexOf(callCycleEntry.day);
        const resultDate = VeevaDateHelper.getDateForWeekDay(new Date(), index);
        return new Date(resultDate.toDateString().concat(" ", callCycleEntry.startTime));
    }

    get accountSearchModal() {
        return this.element.closest('c-my-schedule').accountSearchModal;
    }
}