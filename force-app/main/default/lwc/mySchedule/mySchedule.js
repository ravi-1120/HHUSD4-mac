import FIRSTDAYOFWEEK from '@salesforce/i18n/firstDayOfWeek';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import TOT_LAST_MODIFIED_FIELD from '@salesforce/schema/Time_Off_Territory_vod__c.LastModifiedDate';
import ME_LAST_MODIFIED_FIELD from '@salesforce/schema/Medical_Event_vod__c.LastModifiedDate';
import UT_LAST_MODIFIED_FIELD from '@salesforce/schema/Unavailable_Time_vod__c.LastModifiedDate';
import EVENT_LAST_MODIFIED_FIELD from '@salesforce/schema/Event.LastModifiedDate';
import ECE_LAST_MODIFIED_FIELD from '@salesforce/schema/External_Calendar_Event_vod__c.LastModifiedDate';
import { track, wire, api} from 'lwc';
import {getObjectInfos} from 'lightning/uiObjectInfoApi';
import { getRecord } from "lightning/uiRecordApi";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import CAL from '@salesforce/resourceUrl/calendar';
import VOD_THEME from '@salesforce/resourceUrl/vodtheme';
import CreateCallService from 'c/createCallService';
import VeevaToastEvent from "c/veevaToastEvent";
import VeevaMainPage from "c/veevaMainPage";
import { VeevaAccountSearchController } from 'c/veevaAccountSearch';
import MyScheduleSearchController from 'c/myScheduleSearchController';
import CallCycleCalendar from 'c/callCycleCalendar';
import { getService } from "c/veevaServiceFactory";
import VeevaLegacyDataService from 'c/veevaLegacyDataService';
import SchedulerPane from 'c/schedulerPane';
import CallCycleEntryService from 'c/callCycleEntryService';
import CalendarEventStoreManager from 'c/calendarEventStoreManager';
import getVeevaSettings from '@salesforce/apex/VeevaMyScheduleController.getVeevaSettings';
import getVeevaCommonSettings from '@salesforce/apex/VeevaMyScheduleController.getVeevaCommonSettings';
import getEventObjectThemeInfo from '@salesforce/apex/VeevaMyScheduleController.getEventObjectThemeInfo';
import getExternalCalendarInfos from '@salesforce/apex/VeevaMyScheduleController.getExternalCalendarInfos';
import getCalendarEvents from '@salesforce/apex/VeevaMyScheduleController.getCalendarEvents';
import discardUnassignedPresentation from '@salesforce/apex/VeevaMyScheduleController.discardUnassignedPresentation';
import userHasExternalEvents from '@salesforce/apex/VeevaMyScheduleController.userHasExternalEvents';
import getSubordinatesInfo from '@salesforce/apex/VeevaMyScheduleController.getSubordinatesInfo';
import { APPLICATION_SCOPE, subscribe, MessageContext, unsubscribe } from 'lightning/messageService';
import myScheduleCalendarEventChannel from '@salesforce/messageChannel/MySchedule_Calendar_Event__c';
import componentRefreshMessage from '@salesforce/messageChannel/Component_Refresh_Message__c';
import UserId from "@salesforce/user/Id";
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import LOGIN_USER_NAME_FIELD from '@salesforce/schema/User.Username';
import ENABLE_MS_OUTLOOK_CALENDAR_FIELD from '@salesforce/schema/User.Enable_MS_Outlook_Calendar_vod__c';
import getCallCycleInfo from '@salesforce/apex/VeevaMyScheduleController.getCallCycleInfo';
import CreateCallDataFormatter  from 'c/createCallDataFormatter';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import MyScheduleCalendar from './myScheduleCalendar';
import CalendarModeManager from './calendarModeManager';
import CalendarLocaleManager from './calendarLocaleManager';
import CallConflictManager from './callConflictManager';

export default class MySchedule extends NavigationMixin(VeevaMainPage) {
    CALENDAR_VIEWS = ['day', 'week', 'month'];
    MY_SCHEDULE_SOBJECTS = ['Call2_vod__c', 'Time_Off_Territory_vod__c', 'Medical_Event_vod__c', 'EM_Event_vod__c', 'Unavailable_Time_vod__c', 'Meeting_Request_vod__c', 'Multichannel_Activity_vod__c', 'Event', 'Account', 'External_Calendar_vod__c', 'External_Calendar_Event_vod__c', 'User', 'View_vod__c', 'Account_List_vod__c', 'Address_vod__c', 'TSF_vod__c', 'EM_Speaker_vod__c', 'Call_Cycle_Entry_vod__c' ];
    componentName = 'LexMySchedule';
    pageCtrl = new MyScheduleSearchController(new VeevaLegacyDataService(getService('sessionSvc')), getService('userInterfaceSvc'), getService('messageSvc'), getService('metaStore'), getService('applicationMetricsSvc'));
    
    static MS_IN_MINUTE = 60 * 1000;
    static OBJECT_VF_PAGE_MAP = {
        Call2_vod__c : {
            edit : 'Call_Edit_vod',
            view : 'Call_View_vod'
        }
    };
    EXTERNAL_CAL_FIELD_VALIDATION = new Map([
        ['External_Calendar_vod__c',
            ['External_Calendar_ID_vod__c', 'Is_Default_Calendar_vod__c', 'Title_vod__c']
        ],
        ['External_Calendar_Event_vod__c',
            ['Is_All_Day_vod__c', 'Start_Datetime_vod__c', 'Start_TimeZone_vod__c', 'End_Datetime_vod__c', 'End_TimeZone_vod__c', 'Original_Start_TimeZone_vod__c', 'Original_End_TimeZone_vod__c',
             'Series_Master_ID_vod__c', 'Event_Created_Datetime_vod__c', 'External_Calendar_Event_ID_vod__c', 'Sensitivity_vod__c']
        ]
    ]);

    SCHEDULER_PANE_PERMISSION_CHECKS = new Map([
        ['Account', ['Formatted_Name_vod__c', 'Primary_Parent_vod__c' ]],
        ['Address_vod__c', ['Name', 'City_vod__c', 'State_vod__c', 'Zip_vod__c' ]],
        ['TSF_vod__c', [] ]
    ]);
    
    USER_OBJ_FIELDS = [ USER_NAME_FIELD, LOGIN_USER_NAME_FIELD ];
    USER_OPTIONAL_FIELDS = [ ENABLE_MS_OUTLOOK_CALENDAR_FIELD ];

    myScheduleCalendar;
    renderedBryntumCalendar;
    temporaryCalendarPromise;
    eventStore;
    currentlyOpenedRecordId;
    currentlyOpenedRecordObject;
    calendarInitialized = false;
    messageService;
    sessionService;
    settings = {};
    calendarObjectInfos = {};
    inConsoleMode;
    tempInConsoleModePromise;

    showErrorModal;
    errorModalMessage;
    minimizeWidth;
    
    subscription;
    refreshSubscription;
    @wire(MessageContext) messageContext;
    
    @api ctrl;

    msgWarning;
    msgCancel;
    msgOk;

    @track confirmationModalConfig = {
        show: false,
        title: null,
        messages: [],
        confirmLabel: null,
        cancelLabel: null
    };
    
    msgError;
    showError;
    errorMessage;

    @track display = true;
    @track calendarLabel;
    @track specifiedDate;
    userId;
    loginUserName;
    @track calendarFullyLoaded = false;
    showNewRecordModal = false;
    showRecordTypeModal = false;
    showReason = false;
    stateParameters = null;
    selectedRtId;
    newRecordObject;

    async handleNewRecordModalClose(event) {
        this.closeHelpText();
        const recordId = event.detail?.recordId;
        const saveAndNew = event.detail?.saveAndNew;
        
        this.showRecordTypeModal = MySchedule.parseBoolean(saveAndNew);
        this.showNewRecordModal = false;
        if (typeof recordId === "string") { // ensure we received an id and that it is a string
            const newEvents = await getCalendarEvents({ recordIds: [recordId], objectType : this.newRecordObject, weekendDays : this.myScheduleCalendar.clm.weekendDays });
            this.handleCalendarEvent({ event : newEvents[0] });
        }
    }

    @wire(CurrentPageReference)     
    async getStateParameters(currentPageReference) {
        this.resetBryntumStylesheet();
        if (!currentPageReference) {
            return;
        }
        window.history.replaceState(currentPageReference?.state, '', window.location.pathname);
        // handle scenario if user switches to a different tab and comes back to my schedule tab after being navigated to my schedule with state 
        // parameters, we do not want to refocus record that has already been handled
        if (currentPageReference?.state?.c__focusedRecordId === this.stateParameters?.c__focusedRecordId) {
            return;
        }
        this.stateParameters = Object.keys(currentPageReference?.state).length ? currentPageReference?.state : null;
        // handle scenario if user selects notification while currently in my schedule tab
        if (this.calendarFullyLoaded && this.stateParameters) {
            this.handleStateParameters();
        }
    }

    async handleStateParameters() {
        if (this.stateParameters?.c__objectType === 'Meeting_Request_vod__c') {
            return this._handleMeetingRequestStateParameters();
        }
        if (this.stateParameters?.c__focusedRecordId === 'multiple') {
            return this._handleCyclePlanCallStateParameters();
        }
        return this._handleCallSuggestionStateParameters();
    }

    async _handleMeetingRequestStateParameters() {
        const meetingRequest = await this.pageCtrl.uiApi.getRecord(this.stateParameters?.c__focusedRecordId, [
            'Meeting_Request_vod__c.Is_Hidden_vod__c',
            'Meeting_Request_vod__c.Call2_vod__c',
            'Meeting_Request_vod__c.Call2_vod__r.Call_DateTime_vod__c',
            'Meeting_Request_vod__c.Call2_vod__r.Call_Date_vod__c'
        ]);
        if (meetingRequest?.fields?.Call2_vod__c?.value) {
            const callDateTime = meetingRequest.fields.Call2_vod__r.value.fields?.Call_Datetime_vod__c?.value;
            if (callDateTime) {
                MyScheduleCalendar.setFocusDate(callDateTime.substring(0, callDateTime.indexOf('T')));
            } else {
                MyScheduleCalendar.setFocusDate(meetingRequest.fields.Call2_vod__r.value.fields?.Call_Date_vod__c?.value);
            }
            this.handleFocusNewEvent(meetingRequest.fields.Call2_vod__c.value, 'Call2_vod__c', true, false);
        } else {
            MyScheduleCalendar.setFocusDate(this.stateParameters?.c__myScheduleDate);
            this.handleFocusNewEvent(this.stateParameters?.c__focusedRecordId, 'Meeting_Request_vod__c', false, meetingRequest.fields.Is_Hidden_vod__c.value);
        }
    }

    async _handleCallSuggestionStateParameters() {
        if (this.stateParameters?.c__myScheduleDate) {
            MyScheduleCalendar.setFocusDate(this.stateParameters?.c__myScheduleDate);
        }
        if (this.stateParameters?.c__focusedRecordId) {
            this.handleFocusNewEvent(this.stateParameters?.c__focusedRecordId, 'Call2_vod__c', false, false);
        }
    }

    _handleCyclePlanCallStateParameters() {
        if (!this.stateParameters?.c__myScheduleDate) {
            return;
        }
        MyScheduleCalendar.setFocusDate(this.stateParameters.c__myScheduleDate);
        this.navigateCalendarToCurrentDate();
    }

    _addObjectLabelsToTranslatedLabels(translatedLabels) {
        if (this.calendarObjectInfos.Call2_vod__c) {
            translatedLabels.Call2_vod__c = {labelPlural: this.calendarObjectInfos.Call2_vod__c.labelPlural, label: this.calendarObjectInfos.Call2_vod__c.label};
        }
        if (this.calendarObjectInfos.Meeting_Request_vod__c) {
            translatedLabels.Meeting_Request_vod__c = {label: this.calendarObjectInfos.Meeting_Request_vod__c.label};
        }
    }

    async handleEventFocusNewEvent(event) {
        this.handleFocusNewEvent(event.detail.id, 'Call2_vod__c', false, false);
    }

    async handleFocusNewEvent(focusedRecordId, objectType, accepted, hidden) {
        this.navigateCalendarToCurrentDate();
        if (hidden) {
            this.dispatchEvent(new ShowToastEvent({
                  variant: 'warning',
                  message: this.translatedLabels.toastRemoveLabel.replace('{0}', this.calendarObjectInfos.Meeting_Request_vod__c.label)
                })
              );
            return;
        }

        this.myScheduleCalendar.focusedRecordId = focusedRecordId;
        const event = this.eventStore.findRecord('id', focusedRecordId);
        if (!event) {
            const newEvents = await getCalendarEvents({ recordIds : [focusedRecordId], objectType, weekendDays : this.myScheduleCalendar.clm.weekendDays });
            this.handleCalendarEvent({event: newEvents[0], needsQueried: true});
        } else {
            this.myScheduleCalendar._openEventPopover(event);
        }
        
        if (accepted) {
            this.dispatchEvent(new ShowToastEvent({
                  variant: 'warning',
                  message: this.translatedLabels.toastAcceptLabel.replace('{0}', this.calendarObjectInfos.Call2_vod__c.label).replace('{1}', this.calendarObjectInfos.Meeting_Request_vod__c.label)
                })
              );
        }
    }

    navigateCalendarToCurrentDate() {
        const currentDate = new Date(MyScheduleCalendar.locateSettingWithDefault('currentDate', new Date()));
        this.myScheduleCalendar.calendar.date = currentDate;
        this.myScheduleCalendar.calendar.mode = 'week';
        sessionStorage.setItem('currentView', 'week');
        
        // fetch events for current date range if eventStore does not already have events from this range on page load
        this.myScheduleCalendar.handleDateChange({date: currentDate, title: 'week'});
    }

    async handleNewRecordType(event) {
        this.selectedRtId = event.detail?.recordTypeId;
        this.showRecordTypeModal = false;
        this.showNewRecordModal = true;
    }

    @api
    get accountSearchModal() {
        return this.template.querySelector('c-account-search-modal');
    }

    get confirmationModal() {
        return this.template.querySelector('c-veeva-confirmation-modal');
    }

    get convertToCallFlow() {
        return this.template.querySelector('c-convert-to-call');
    }

    @api
    showReasonModal(title, skipButton, callBackFn, recordType) {
        this.reasonConfig = {
            title,
            skipButton,
            callBackFn,
            recordType
        }
        this.showReason = true;
    }

    closeReasonModal() {
        this.showReason = false;
    }

    @wire(getObjectInfos, {objectApiNames: '$MY_SCHEDULE_SOBJECTS'})
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.calendarObjectInfos = Object.fromEntries(data.results.filter(e => e.result.apiName).map(e=> [e.result.apiName, e.result]));

            if (this.calendarObjectInfos.Call2_vod__c) {
                this.pageCtrl.objectInfo = this.calendarObjectInfos.Call2_vod__c;
                const page = { requests: [] };
                this.pageCtrl.page = page;
                this.ctrl = new VeevaAccountSearchController(this.pageCtrl, "Call2_vod__c");
            }
            this.setExternalCalendarPermissions();
            this.initializeCalendar();
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error(`Failed to fully load My Schedule with the following error: ${error?.body?.message || error}`);
        }
    }

    @wire(getRecord, { recordId: '$userId', fields: '$USER_OBJ_FIELDS', optionalFields: '$USER_OPTIONAL_FIELDS' })
    async wiredUserRecordInfo({ error, data }) {
        if (data) {
            const result = JSON.parse(JSON.stringify(data));
            this.loginUserName = result?.fields?.Username?.value;
            this.userName = result?.fields?.Name?.value;
            const hasExternalCalendarEvents = await userHasExternalEvents();
            if (result.fields?.Enable_MS_Outlook_Calendar_vod__c?.value) {
                this.externalCalendarSetting = hasExternalCalendarEvents ?  'showExtCalendar' : 'showAddCalendarBtn';
            } else {
                this.externalCalendarSetting = '';
            }

            this.userObjectFieldsSet = true;
            this.initializeCalendar();
        }
        else if (error) {
            this.showExternalCalendarSection = false;
            this.userObjectFieldsSet = true;
            this.initializeCalendar();
        }
    }

    @wire(getRecord, { recordId : '$currentlyOpenedRecordId', fields: '$recordFields', modes: ['View'] })
    wiredRecordInfo({ error, data }) {
        if (data) {
            const modifiedDate = new Date(data.lastModifiedDate);
            if (new Date().getTime() - modifiedDate.getTime() > (MyScheduleCalendar.MS_IN_MINUTE)) {
                return; // if event hasn't been modified recently, we don't need to replace it in the calendar
            }
            this._handleEditModalClose();
        } else if (error) {
            this.myScheduleCalendar.element.addEventListener('pointerover', async () => {
                await this._handleEditModalClose();
                this.currentlyOpenedRecordId = null;
                this.currentlyOpenedRecordObject = null;
            }, {once : true});
        }
    }

    async _handleEditModalClose() {
        if (!this.myScheduleCalendar) {
            return;
        }
        this.closeHelpText();
        const newEvents = await getCalendarEvents({ recordIds : [this.currentlyOpenedRecordId], objectType : this.currentlyOpenedRecordObject, weekendDays : this.myScheduleCalendar.clm.weekendDays });
        const newEvent = newEvents[0];
        this.updateFrontEndAttributes(newEvent);
        const eventMsg = { event : newEvent, isTemporary: false, oldEventId: this.currentlyOpenedRecordId };
        this.handleCalendarEvent(eventMsg);

        this.myScheduleCalendar._handlePopoverClose(); // reenable scrolling after edit modal closes
    }

    resetBryntumStylesheet() {
        let display;
        if (this.calendarElt) {
            display = this.calendarElt.style.display;
            // hide page ui issues while switching bryntum styling sheets
            this.calendarElt.style.display = 'none'; 
        }
        // eslint-disable-next-line @lwc/lwc/no-document-query
        const calendarStyleSheet = document.querySelector('link[href*="calendar/calendar"][rel="stylesheet"]');
        // eslint-disable-next-line @lwc/lwc/no-document-query
        const schedulerStyleSheet = document.querySelector('link[href*="schedulerpro"][rel="stylesheet"]');

        if (calendarStyleSheet) {
            calendarStyleSheet.disabled = false;
        }
        if (schedulerStyleSheet) {
            schedulerStyleSheet.disabled = true;
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
        setTimeout(() => {
            if (this.calendarElt) {
                this.calendarElt.style.display = display;
            }
        }, 100)
    }
    
    async renderInitialCalendar() {
        const [weekendDays] = await Promise.all([
            CalendarLocaleManager.getWeekendDays(), // weekends loaded in first as well as they affect the visual look of calendar
            loadScript(this, `${CAL}/calendar.lwc.module.min.js`),
            loadStyle(this, `${CAL}/calendar.stockholm.min.css`),
            loadStyle(this, VOD_THEME)
        ]);
        this._setMyScheduleSettings(); // settings are given default values
        const curView = MyScheduleCalendar.locateSettingWithDefault('currentView', 'week');
        const curDate = MyScheduleCalendar.locateSettingWithDefault('currentDate', new Date());
        const curAgendaRange = MyScheduleCalendar.locateSettingWithDefault('agendaRange', 'month');

        const temporarySchedule = new MyScheduleCalendar({
            element : this.calendarElt, 
            settings : this.settings, 
            calendarLocaleManager : new CalendarLocaleManager(weekendDays)
        });
        this.calendarModes = new CalendarModeManager(temporarySchedule, curAgendaRange);
        if (!MyScheduleCalendar.locateSettingWithDefault('manageView', false)) {
            window.calendar = MyScheduleCalendar.getInitialCalendar(temporarySchedule, this.calendarModes.getCalendarModes(this.CALENDAR_VIEWS), curView, curDate);
        }
        return temporarySchedule;
    }

    connectedCallback() {
        super.connectedCallback();
        this.userId = UserId;
        this.temporaryCalendarPromise = Promise.resolve(this.renderInitialCalendar());
    }

    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
            const apiEvent = new CustomEvent("internalapievent", {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    category: "workspaceAPI",
                    methodName,
                    methodArgs,
                    callback(err, response) {
                        if (err) {
                            return reject(err);
                        }
                        return resolve(response);
                    }
                }
            });
            window.dispatchEvent(apiEvent);
        });
    }

    async initializeCalendar() {
        this.messageService = getService('messageSvc');
        this.sessionService = getService('sessionSvc');
        this.subscribeToMessageChannel();

        if(this.calendarInitialized || !this.userObjectFieldsSet || !this.externalCalendarPermissionsSet) {
            return;
        }
        this.calendarInitialized = true;
        
        this.tempInConsoleModePromise = this.invokeWorkspaceAPI('isConsoleNavigation');

        try {
            this.myScheduleCalendar = await this.temporaryCalendarPromise;
            
            const [eventObjInfo, eventThemeInfo] = await Promise.all([this.pageCtrl.uiApi.getObjectInfoFromRestApi('Event'), getEventObjectThemeInfo()]);
            this.calendarObjectInfos.Event = eventObjInfo;
            if (this.calendarObjectInfos.Event) {
                this.calendarObjectInfos.Event.themeInfo = eventThemeInfo;
            }
            // dont load in external events initially until external event permissions logic operates later, assume maximum conflict threshold until we recieve the proper setting value
            const eventStoreManager = new CalendarEventStoreManager({ weekendDays: this.myScheduleCalendar.clm.weekendDays, shouldFetchExternalEvents: false, callsUpdateable: this.calendarObjectInfos.Call2_vod__c?.updateable, eventsUpdateable: this.calendarObjectInfos.Event?.updateable, callScheduleConflictThreshold: 2 });
            
            const [settings, commonSettings, translatedLabels, subordinatesInfo, inConsoleMode] = await Promise.all([
                getVeevaSettings(),
                getVeevaCommonSettings(),
                CalendarLocaleManager.loadTranslatedLabels(this.messageService),
                getSubordinatesInfo(),
                this.tempInConsoleModePromise
            ].map(p => p.catch(e => e)));
                
            this.translatedLabels = translatedLabels;
            this.inConsoleMode = !!inConsoleMode;
            
            this.msgError = translatedLabels.errorLabel;
            this.msgOk = translatedLabels.okLabel;
            this.msgCancel = translatedLabels.cancelLabel;
            
            this._setMyScheduleSettings(settings, commonSettings);
            eventStoreManager.callScheduleConflictThreshold = this.settings.callScheduleConflictThreshold;
            eventStoreManager.displayExternalCalendarsForManagers = this.settings.displayExternalCalendarsForManagers;
            this.eventStore = eventStoreManager.calendarEventStore.eventStore;

            this._addObjectLabelsToTranslatedLabels(translatedLabels);
            this.createCallService = new CreateCallService({
                translatedLabels,
                ctrl: this.ctrl,
                messageService: this.ctrl.pageCtrl.messageSvc
            });

            let externalCalendarSetting = '';
            let externalCalendars = [];
            if (this.showExternalCalendarSection){
                const filteredExtCalRecTypes = await this.checkExtCalRecTypes();
                const msOutlookTranslatedRtLabel = filteredExtCalRecTypes?.find(rc => this.calendarObjectInfos?.External_Calendar_vod__c?.recordTypeInfos?.[rc?.id])?.fields?.Name?.displayValue || 'Microsoft Outlook';
                translatedLabels.msOutlookTranslatedRtLabel = msOutlookTranslatedRtLabel;
                translatedLabels.loadingCalendarsMsg = translatedLabels.loadingCalendarsMsg.replace('{0}', msOutlookTranslatedRtLabel);
                const hasExternalCalRecTypeAccess = (filteredExtCalRecTypes?.length === 2);
                externalCalendarSetting = hasExternalCalRecTypeAccess ? this.externalCalendarSetting : '';
                externalCalendars = [];
                if (externalCalendarSetting === 'showExtCalendar'){
                    externalCalendars = await getExternalCalendarInfos();
                    if (externalCalendars?.length === 0){
                        externalCalendarSetting = 'loadingMsg';
                    }
                }
            }
            const externalCalendarInfo = { externalCalendarSetting, externalCalendars, subordinatesInfo };

            this.myScheduleCalendar = new MyScheduleCalendar({
                element : this.calendarElt,
                settings : this.settings,
                calendarObjectInfos : this.calendarObjectInfos,
                eventStoreManager,
                translatedLabels,
                callConflictManager : new CallConflictManager(this.settings.callScheduleConflictThreshold, this.calendarObjectInfos?.Call2_vod__c),
                calendarLocaleManager : this.myScheduleCalendar.clm,
                externalCalendarInfo,
                sessionService : this.sessionService,
                inConsoleMode: this.inConsoleMode,
                createCallService: this.createCallService
            });

            this.myScheduleCalendar.focusedRecordId = this.stateParameters?.c__focusedRecordId;
            const curAgendaRange = MyScheduleCalendar.locateSettingWithDefault('agendaRange', 'month');
            this.calendarModes = new CalendarModeManager(this.myScheduleCalendar, curAgendaRange);

            this.calendarElt.firstChild?.remove();
            if (this.hasSchedulerPanePermissions(this.calendarObjectInfos?.Account, this.calendarObjectInfos?.Address_vod__c, this.calendarObjectInfos?.TSF_vod__c)) {
                this.schedulerPane = new SchedulerPane(this._getSchedulerConfig(translatedLabels, this.eventStore));
            }

            if (MyScheduleCalendar.locateSettingWithDefault('manageView', false)) {
                const callCycleInfo = await getCallCycleInfo();
                this.toggleToManageCallCycleCalendar(callCycleInfo);
            } else {
                window.calendar = await this.myScheduleCalendar.getCalendar(this.calendarModes.getCalendarModes(this.CALENDAR_VIEWS), this.eventStore, this.schedulerPane?.id);
                await this._attachSchedulerPaneToCalendar();
                // handling state parameters after having the calendar available to have access to translations and event store
                if (this.stateParameters) {
                    this.handleStateParameters();
                }
                this.eventStore = this.myScheduleCalendar?.calendar?.eventStore;
            }

            this.calendarFullyLoaded = true;
            this.calendarElt.dispatchEvent(
                new CustomEvent('pageready', { bubbles: true }
            ));
        } catch(error) {
            this.dispatchEvent(VeevaToastEvent.error({message: 'My Schedule failed to load.'}));
        }
    }

    closeHelpText(){
        const helpText = document.body.getElementsByTagName('lightning-primitive-bubble');
        if (helpText.length){
            helpText[0].dispatchEvent(new MouseEvent('mouseleave'));
        }
        document.body.querySelector('div.viewport')?.removeEventListener('mouseenter', this.closeHelpText);
    }
    
    async _attachSchedulerPaneToCalendar() {
        if (this.hasSchedulerPanePermissions(this.calendarObjectInfos?.Account, this.calendarObjectInfos?.Address_vod__c, this.calendarObjectInfos?.TSF_vod__c)) {
            await this.schedulerPane.appendScheduler(window.calendar);
            this.schedulerPane.appendSchedulerStyleSheet();

            const schedulerPaneAlreadyExpanded = MyScheduleCalendar.locateSettingWithDefault('schedulerPaneExpanded', false);
            if (schedulerPaneAlreadyExpanded) {
                this.schedulerPane.schedulerGrid.expand();
                this.schedulerPane.schedulerGrid.tbar.items[0].activeTab = MyScheduleCalendar.locateSettingWithDefault('schedulerPaneTab', 0);
            }
        }
    }

    _getSchedulerConfig(translatedLabels, eventStore) {
        const curView = MyScheduleCalendar.locateSettingWithDefault('currentView', 'week');
        const disableWeekends = MyScheduleCalendar.locateSettingWithDefault('disableWeekends', true);
        const currentDate = MyScheduleCalendar.locateSettingWithDefault('currentDate', new Date());

        return {element : this.calendarElt, calendarObjectInfos: this.calendarObjectInfos, translatedLabels, eventStore, settings: this.settings, weekendDays : this.myScheduleCalendar.clm.weekendDays, weekStartDay : FIRSTDAYOFWEEK-1, calendarMode: curView, showWeekends: !disableWeekends, currentDate };
    }

    @api
    async toggleToManageCallCycleCalendar(callCycleInfo) {
        const disableWeekends = MyScheduleCalendar.locateSettingWithDefault('disableWeekends', true);
        // remove myschedule calendar, splitter, and scheduler
        while (this.calendarElt.hasChildNodes()) {
            this.calendarElt.firstChild.remove();
        }
        sessionStorage.setItem('manageView', true);
        if (this.myScheduleCalendar?.calendar) {
            this.renderedBryntumCalendar = this.myScheduleCalendar.calendar;
        }
        
        this.currentEventStoreRecords = this.eventStore?.records;

        if (this.manageCallCycleCalendar?.calendar) {
            window.calendar = await this.manageCallCycleCalendar.reRenderCalendar(disableWeekends, callCycleInfo);
        } else {
            const { nonWorkingDays, clm } = this.myScheduleCalendar;
            this.manageCallCycleCalendar = new CallCycleCalendar({
                element: this.calendarElt,
                schedulerEventStore: callCycleInfo,
                translatedLabels: this.translatedLabels,
                disableWeekends,
                nonWorkingDays,
                calendarObjectInfos: this.calendarObjectInfos,
                settings: this.settings,
                calendarLocaleManager: clm
            });
            window.calendar = await this.manageCallCycleCalendar.getManageCallCycleCalendar();
        }
    }

    @api
    async toggleToMyScheduleCalendar() {
        // remove call cycle header container and calendar
        while (this.calendarElt.hasChildNodes()) {
            this.calendarElt.firstChild.remove();
        }
        sessionStorage.setItem('manageView', false);

        if (this.myScheduleCalendar?.calendar) {
             // reset event store data to avoid issues after toggling
            this.myScheduleCalendar.resetCalendarEventStore(this.currentEventStoreRecords || this.eventStore.records);

            if (this.renderedBryntumCalendar) {
                this.myScheduleCalendar.element.appendChild(this.renderedBryntumCalendar.element);
                window.calendar = this.renderedBryntumCalendar;
            } else {
                window.calendar = await this.myScheduleCalendar.getCalendar(this.calendarModes.getCalendarModes(this.CALENDAR_VIEWS), this.myScheduleCalendar.eventStoreManager.eventStore, this.schedulerPane?.id);
            }
            this.eventStore = window.calendar?.eventStore;
            this.myScheduleCalendar.eventIconManager.handleAdditionalCallContent(); // add back in event icons
            
            if (this.hasSchedulerPanePermissions(this.calendarObjectInfos?.Account, this.calendarObjectInfos?.Address_vod__c, this.calendarObjectInfos?.TSF_vod__c)) {
                this.schedulerPane.reRenderSchedulerPane(this.myScheduleCalendar.calendar);
                this.schedulerPane.loadData(); // reload data since call cycle info could have changed in the "manage call cycles" view
            }
        } else {
            window.calendar = await this.myScheduleCalendar.getCalendar(this.calendarModes.getCalendarModes(this.CALENDAR_VIEWS), this.eventStore, this.schedulerPane?.id);
            this.eventStore = window.calendar?.eventStore;
            await this._attachSchedulerPaneToCalendar();
        }
        // scroll to 7:30 AM
        window.calendar.element.querySelectorAll('.b-dayview-timeaxis-time.b-dayview-timeaxis-time-08 .b-dayview-tick-level-1').forEach(el => el.scrollIntoView());
    }

    @api
    updateSchedulerView(viewUpdates) {
        if (!this.schedulerPane?.currentTabManager) {
            return;
        }
        this.schedulerPane.updateView(viewUpdates);
    }

    @api 
    openEditModal(recordId, objectApiName) {
        document.body.querySelector('div.viewport')?.addEventListener('mouseenter', this.closeHelpText);
        const vfPageName = MySchedule.OBJECT_VF_PAGE_MAP[objectApiName]?.edit;
        if (vfPageName) {
            this.navigateToVFPage(recordId, vfPageName);
            return;
        }
        const navigationArgs = {
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName,
                actionName: 'edit'
            },
            state: {
                nooverride: '1'
            }
        };
        this.currentlyOpenedRecordObject = objectApiName;
        this.currentlyOpenedRecordId = recordId;
        this[NavigationMixin.Navigate](navigationArgs);
    }

    @api 
    openNewRecordModal(objectApiName) {
        this.handleErrorModalClose();
        this.newRecordObject = objectApiName;
        if (objectApiName !== 'Call2_vod__c') {
            this.showRecordTypeModal = true;
            return;
        }

        const navigationArgs = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName,
                actionName: 'new'
            },
            state: {
                nooverride: '1',
                useRecordTypeCheck : '1',
                navigationLocation: 'RELATED_LIST' // prevent from navigating away from my schedule on record creation
            }
        };
        this.currentlyOpenedRecordObject = objectApiName;
        this[NavigationMixin.Navigate](navigationArgs);
    }

    @api
    openRecordPage(recordId, objectApiName) {
        if (objectApiName === 'User') {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `/${recordId}`
                }
            });
            return;
        }

        const vfPageName = MySchedule.OBJECT_VF_PAGE_MAP[objectApiName]?.view;
        if (vfPageName) {
            this.navigateToVFPage(recordId, vfPageName);
            return;
        }
        this[this.inConsoleMode ? NavigationMixin.Navigate : NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId,
                objectApiName,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    @api
    openCallOnDesktop(recordId) {
        const params = new URLSearchParams();
        params.append('objectType','Call2_vod__c');
        params.append('Action','Edit')
        params.append('CallId', recordId)
        params.append('uid', UserId)
        window.open(`${this.settings.engageUrlPrefix}/d.html?${params.toString()}`, '_blank')
    }

    @api 
    openConvertToCallModal(recordId) {
        this.convertToCallFlow.showConvertToCallModal(recordId, this.inConsoleMode);
    }

    @api
    openErrorModal(errorMessage, title = null, minimizeWidth = false) {
        this.minimizeWidth = minimizeWidth;
        this.msgError = title || this.translatedLabels.errorLabel;
        this.errorMessage = Array.isArray(errorMessage) ? errorMessage : [errorMessage];
        this.showError = true;
    }

    @api
    async handleDiscardUnassignedPresentation(id) {
        const result = await this._openConfirmationModal({
            size: 'small',
            title: this.myScheduleCalendar.translatedLabels.discardEventMsg,
            message: this.myScheduleCalendar.translatedLabels.discardConfirmationMsg,
            cancelLabel: this.myScheduleCalendar.translatedLabels.cancelLabel,
            confirmLabel: this.myScheduleCalendar.translatedLabels.okLabel
          });
          if (result) {
            const discardResult = await discardUnassignedPresentation({recordId: id});
            if (discardResult.error) {
                this.openErrorModal(discardResult.error);
            } else {
                this.handleCalendarEvent({isTemporary: false, temporaryEventId: id});
            }
          }
    }

    @api
    async handleSendRemoteMeetingInvite(id) {
        const result = await this._openConfirmationModal({
            size: 'veeva-small',
            title: this.myScheduleCalendar.translatedLabels.warningLabel,
            message: this.myScheduleCalendar.translatedLabels.remoteMeetingInviteLabel,
            cancelLabel: this.myScheduleCalendar.translatedLabels.noLabel,
            confirmLabel: this.myScheduleCalendar.translatedLabels.yesLabel
          });
          if (result) {
            const vfPageName = MySchedule.OBJECT_VF_PAGE_MAP.Call2_vod__c?.edit;
            const hcpr = this.settings.enableCrmDesktop?.find(item => item === 'Call2_vod__c') && vfPageName === 'Call_Edit_vod';
            
            if (hcpr) {
                this.openCallOnDesktop(id);
            } else {
                const url = `/apex/${vfPageName}?id=${id}&sfdc.override=1&participantsInfo`;
                this[this.inConsoleMode ? NavigationMixin.Navigate : NavigationMixin.GenerateUrl]({
                    type: 'standard__webPage',
                    attributes: { url }
                }).then(page => {
                    window.open(page, "_blank"); // open page in new tab
                });
            }   
        }
    }

    async _openConfirmationModal({ size, title, message, cancelLabel, confirmLabel }) {
        return new Promise(resolve => {
          const handleConfirm = () => {
            this.confirmationModal.removeEventListener(handleConfirm);
            this.confirmationModalConfig.show = false;
            resolve(true);
          };
    
          const handleCancel = () => {
            this.confirmationModal.removeEventListener(handleCancel);
            this.confirmationModalConfig.show = false;
            resolve(false);
          };
    
          this.confirmationModal.addEventListener('confirm', handleConfirm);
          this.confirmationModal.addEventListener('cancel', handleCancel);
          this.confirmationModalConfig.show = true;
          this.confirmationModalConfig.size = size;
          this.confirmationModalConfig.title = title;
          this.confirmationModalConfig.messages = [message];
          this.confirmationModalConfig.cancelLabel = cancelLabel;
          this.confirmationModalConfig.confirmLabel = confirmLabel;
        });
    }

    navigateToVFPage(recordId, vfPageName) {
        const url = `/apex/${vfPageName}?id=${recordId}&queryParams=${encodeURIComponent(`hideMyScheduleLink=true`)}`;
        this[this.inConsoleMode ? NavigationMixin.Navigate : NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: { url }
        })?.then(page => {
            if (this.settings.enableCrmDesktop?.find(item => item === 'Call2_vod__c') && vfPageName === 'Call_Edit_vod') {
                window.open(page, "_parent"); // prevent from opening extra blank vf call edit page if HPCR is enabled
            } else { 
                window.open(page, "_blank"); // open page in new tab
            }
        });
    }

    disconnectedCallback() {
        unsubscribe(this.subscription); 
        unsubscribe(this.refreshSubscription);
        this.subscription = null;
        this.refreshSubscription = null;
    }

    subscribeToMessageChannel() {
        if(!this.subscription) {
            this.subscription = subscribe(this.messageContext, myScheduleCalendarEventChannel, (message) => this.handleCalendarEvent(message));
        }
        if(!this.refreshSubscription) {
            this.refreshSubscription = subscribe(this.messageContext, componentRefreshMessage, (message) => this.handleRefresh(message), { scope: APPLICATION_SCOPE });
        }
    }

    @api
    handleCreateCallError(data) {
        const message = data.detail || data;
        if (message.isModal) {
            this.openErrorModal(message.errorMessage);
        } else if (message.forwardToRecord) {
            this.openRecordPage(message.recordId, 'Account_vod__c'); 
        } else {
            this.dispatchEvent(VeevaToastEvent.error({message: message.errorMessage})); 
        }
    }

    async handleRefresh(message) {
        if(message?.type === 'refreshCalls') {
            this.myScheduleCalendar.eventStoreManager?.refreshEventType('Call2_vod__c');
        }
    }

    @api
    handleCalendarEvent(data) {
        const message = data.detail || data;
        if (message.needsQueried) {
            getCalendarEvents({ recordIds : [message.event.id], objectType : message.event.objectType, weekendDays : this.myScheduleCalendar.clm.weekendDays })
                .then(events => this.handleCalendarEvent({ event: events[0], temporaryEventId: message.temporaryEventId }));
        } else {
            if (!message.isTemporary && message.event?.id && this.eventStore.findRecord("id", message.event.id)) {
                this.updateFrontEndAttributes(message.event);
                const updatedEvents = this.myScheduleCalendar.calendar.events.map(eventData => eventData.data);
                const updatedEventIndex = updatedEvents.map(e=>e.id).indexOf(message.event.id);
                updatedEvents.splice(updatedEventIndex, 1, message.event);
                
                this.eventStore.removeAll();
                this.eventStore.add(updatedEvents);
                return;
            }
            if (!message.isTemporary) {
                this.eventStore.remove(this.eventStore.findRecord("id", message.temporaryEventId || message.oldEventId) || []);
            }
            if (message.event) {
                if (!message.isTemporary && !message.event?.cls){
                    this.updateFrontEndAttributes(message.event);
                }
                const event = JSON.parse(JSON.stringify(message.event));
                const updatedEvents = this.myScheduleCalendar.calendar.events.map(eventData => eventData.data);
                updatedEvents.push(event)
                
                this.eventStore.removeAll();

                if (message.fromSchedulerPane) {
                    // replaces temp event from scheduler pane with temp call event, fixes delay between drop and temp event appearing
                    const dummyEventIndex = updatedEvents.findIndex(updatedEvent => updatedEvent.fromSchedulerPane);
                    if (dummyEventIndex !== -1) {
                        updatedEvents.splice(dummyEventIndex, 1);
                    }
                }
                this.eventStore.add(updatedEvents);
            } else if (message.fromSchedulerPane) {
                const temporaryEventId = this.myScheduleCalendar.calendar.events.find(e => e.fromSchedulerPane)?.id;
                if (!temporaryEventId) {
                    // sometimes Bryntum temp events from dragging accounts from scheduler pane aren't in event store by the time we try to remove it, add flag to remove them later
                    this.myScheduleCalendar.removeFromSchedulerPaneEvents = true; 
                }
                this.eventStore.remove(this.eventStore.findRecord("id", temporaryEventId) ?? []);
            }
        }
    }

    updateFrontEndAttributes(event) {
        const events = Array.isArray(event) ? event : [event];
        CalendarEventStoreManager.addFrontEndProperties(events, this.calendarObjectInfos.Call2_vod__c?.updateable, this.calendarObjectInfos.Event?.updateable);
    }

    get recordFields() {
        switch (this.currentlyOpenedRecordObject) {
            case 'Event':
                return [EVENT_LAST_MODIFIED_FIELD];
            case 'Time_Off_Territory_vod__c':
                return [TOT_LAST_MODIFIED_FIELD];
            case 'Medical_Event_vod__c':
                return [ME_LAST_MODIFIED_FIELD];
            case 'Unavailable_Time_vod__c':
                return [UT_LAST_MODIFIED_FIELD];
            case 'External_Calendar_Event_vod__c':
                return [ECE_LAST_MODIFIED_FIELD];
            default:
                return [];
        }
    }

    get calendarElt() {
        return this.template.querySelector('div.calendar');
    }

    static parseBoolean(x) {
        return x === "true" || x === true;
    }

    _setMyScheduleSettings(settings, commonSettings) {
        this.settings.callScheduleConflictThreshold = parseInt(settings?.Call_ScheduleConflict_Threshold_vod__c, 10);
        this.settings.callBackdateLimit = parseInt(settings?.CALL_BACKDATE_LIMIT_vod__c, 10);
        this.settings.groupCallAttendeesEnabled = MySchedule.parseBoolean(settings?.Enable_Group_Call_Attendee_Display_vod__c);
        this.settings.enableAccountParentDisplay = MySchedule.parseBoolean(settings?.ENABLE_ACCOUNT_PARENT_DISPLAY_vod__c);
        this.settings.displayMedicalEvents = MySchedule.parseBoolean(settings?.ENABLE_SCHEDULE_MEDICAL_EVENT_vod__c);
        this.settings.enableChildAccount = MySchedule.parseBoolean(settings?.Enable_Child_Account_vod__c);
        this.settings.enableCyclePlansRemaining = MySchedule.parseBoolean(settings?.ENABLE_CYCLE_PLANS_REMAINING_vod__c);
        this.settings.enableAdvancedCyclePlanMetrics = MySchedule.parseBoolean(settings?.ENABLE_ADV_CYCPLN_SCHEDULING_vod__c);
        this.settings.enableCrmDesktop = settings?.Enable_CRM_Desktop_vod__c?.split(',')?.map(objName => objName.trim());
        this.settings.allowedCallRecordTypes = settings?.ALLOWED_CALL_RECORD_TYPES_vod__c;
        this.settings.preventTotWeekend = settings?.PREVENT_TOT_WEEKEND_vod__c;
        this.settings.enableSamplesOnSignSave = settings?.Enable_Samples_On_Save_vod__c;
        this.settings.displayExternalCalendarsForManagers = parseInt(settings?.DISPLAY_EXTERNAL_CALENDARS_TO_MGRS_vod__c, 10);
        this.settings.engageUrlPrefix = commonSettings?.Engage_Url_Prefix_vod__c;
        this.settings.microsoftAuthServerURL = commonSettings?.Microsoft_Authorization_Server_URL_vod__c;
        this.settings.loginUserName = this.loginUserName;
        this.settings.userName = this.userName;
        this.settings.userId = this.userId;
    }

    setExternalCalendarPermissions(){
        const hasObjAndFldPermissionsOnExternalCals = this.checkObjectAndFieldPermissions(this.calendarObjectInfos?.External_Calendar_vod__c)
            && this.checkObjectAndFieldPermissions(this.calendarObjectInfos?.External_Calendar_Event_vod__c)
            && this.hasUserFLSForExternalCalendar();
        if (hasObjAndFldPermissionsOnExternalCals){
            this.showExternalCalendarSection = true;
        }
        this.externalCalendarPermissionsSet = true;
    }

    hasUserFLSForExternalCalendar() {
        const userFieldsWithRequiredUpdateFLS = [
          'MS_Graph_API_Authorized_vod__c',
          'MS_Outlook_Last_Pull_Activity_vod__c',
          'MS_Outlook_Last_Push_Activity_vod__c',
        ];
        const userObjectInfo = this.calendarObjectInfos?.User;
        return (
          userObjectInfo?.fields.Enable_MS_Outlook_Calendar_vod__c &&
          userFieldsWithRequiredUpdateFLS.every(field => userObjectInfo?.fields[field]?.updateable)
        );
    }

    checkObjectAndFieldPermissions(objectInfo){
        let hasPermissions = false;
        if (objectInfo?.createable && objectInfo?.updateable && objectInfo?.deletable) {
            const fieldsToCheck = this.EXTERNAL_CAL_FIELD_VALIDATION.get(objectInfo.apiName);
            const missingFLS = fieldsToCheck.find(field => !objectInfo?.fields[field]
                || (!objectInfo?.fields[field].updateable && objectInfo?.fields[field].dataType !== 'Reference')
                || (!objectInfo?.fields[field].createable && objectInfo?.fields[field].dataType === 'Reference'));
            if (!missingFLS){
                hasPermissions = true;
            }
        }
        return hasPermissions;
    }

    async checkExtCalRecTypes(){
        let filteredRecTypes = [];
        if (this.calendarObjectInfos?.External_Calendar_vod__c?.recordTypeInfos && this?.calendarObjectInfos?.External_Calendar_Event_vod__c?.recordTypeInfos){
            const extCalendarEventRecTypes = [...Object.keys(this.calendarObjectInfos?.External_Calendar_vod__c?.recordTypeInfos),
                ...Object.keys(this?.calendarObjectInfos?.External_Calendar_Event_vod__c?.recordTypeInfos)];
            const externalCalendarRecordTypeInfos = await this.ctrl.pageCtrl.uiApi.getBatchRecords(extCalendarEventRecTypes, ['RecordType.Name', 'RecordType.DeveloperName'], true);
            filteredRecTypes = externalCalendarRecordTypeInfos?.filter(recType =>
                recType?.fields?.DeveloperName?.value === 'Microsoft_Outlook_vod'
                && (this._isRecordTypeAvailable(this.calendarObjectInfos.External_Calendar_vod__c, recType.id)
                || this._isRecordTypeAvailable(this.calendarObjectInfos.External_Calendar_Event_vod__c, recType.id)));
        }
        return filteredRecTypes;
    }

    _isRecordTypeAvailable(objectInfo, recTypeId){
        return objectInfo.recordTypeInfos[recTypeId]?.available;
    }

    handleErrorModalClose() {
        this.showError = false;

        // disable account search modal okay button
        this.myScheduleCalendar.accountSearchModal.disableOkButton();
    }

    hasSchedulerPanePermissions(accountObjInfo, addressObjInfo, tsfObjInfo){
        if (!accountObjInfo || !addressObjInfo || !tsfObjInfo){
            return false;
        }
        return [accountObjInfo, addressObjInfo, tsfObjInfo].every(objInfo => {
            const fieldsToCheck = this.SCHEDULER_PANE_PERMISSION_CHECKS.get(objInfo?.apiName);
            if (objInfo?.apiName === 'Account') {
                return fieldsToCheck.every(field => objInfo?.fields[field]) && ['Account_Identifier_vod__c', 'Medical_Identifier_vod__c'].some(field => objInfo?.fields[field])
            }
            return fieldsToCheck.every(field => objInfo?.fields[field]);
        });
    }

    @api
    async createCalls(callCycleEntries, callInfos, clickDate, byWeek) {
        const preCreateCallErrors = [];
        const createCallErrors = [];
        const toCreateCalls = [];
        const accounts = callCycleEntries.map((callCycle) => callCycle.Account_vod__c);
        await this.createCallService.fetchAccountsInfoForValidation(accounts);
        // populate the lists used for call validation prior to creating temporary events to avoid unexpected validation errors caused by async processing
        await this.createCallService.populateValidationLists(this.settings.allowedCallRecordTypes);
        const tempEventResults = await Promise.all(callCycleEntries.map((callCycle) => {
            const accountInfo = {
                id: callCycle.accountId,
                displayedName: callCycle.name
            };
            return this.createCallService.getTempEvent(callInfos.find(info => info.callCycleId === callCycle.callCycleId), accountInfo, false);
        }));
        // remove previewed events
        const nonPreviewedEvents = this.myScheduleCalendar.calendar.events.map(eventData => eventData.data).filter(event => event.eventType !== 'call-cycle-entry');
        this.eventStore.removeAll();
        this.eventStore.add(nonPreviewedEvents);

        tempEventResults.forEach((tempEventRes) => {
            if (tempEventRes.error) {
                preCreateCallErrors.push(tempEventRes.errorMessage);
            } else {
                this.handleCalendarEvent(tempEventRes);
                toCreateCalls.push(callCycleEntries.find(entry => entry.callCycleId === tempEventRes.callCycleId));
            }
        });
        if (toCreateCalls.length > 0) { 
            const res = await this.createCallService.applyCallCycle(toCreateCalls.map(call => call.callCycleId).join(','), this.myScheduleCalendar.getView(), byWeek, clickDate);
            
            if (res.error) {
                const errors = res.error.split('\n');
                errors.pop();
                createCallErrors.push(errors);
            }

            let createdCalls = await getCalendarEvents({ recordIds : res.events?.map(ev => ev.id), objectType : 'Call2_vod__c', weekendDays : this.myScheduleCalendar.clm.weekendDays })
            const events = this.myScheduleCalendar.calendar.events.map(eventData => eventData.data);
            createdCalls = createdCalls.filter(call => !events.find(event => event.id === call.id)); // don't add calls that have been added to event store already (via navigation to month, etc.)
            this.updateFrontEndAttributes(createdCalls);
            events.push(...createdCalls);

            tempEventResults.filter(tempEventRes => !tempEventRes.error).forEach(tempEventRes => {
                events.splice(events.findIndex(x => x.id === tempEventRes.event?.id), 1);
            });
            this.eventStore.removeAll();
            this.eventStore.add(events);
        }
        const res = this.createCallService.generateErrorInfo(preCreateCallErrors, createCallErrors.flat(), callCycleEntries.filter(entry => !toCreateCalls.includes(entry)));
        if (res) {
            const {errorDescriptions, errorHeader} = res;
            this.openErrorModal(errorDescriptions, errorHeader, true);
        }
    }

    @api
    async createCall(callInfo, accountInfo, fromSchedulerPane, callBackFn) {
        const tempEventRes = await this.createCallService.getTempEvent(callInfo, accountInfo, fromSchedulerPane);
        if (tempEventRes.error) {
            this.handleCreateCallError(tempEventRes);
            this.handleCalendarEvent(tempEventRes);
            if (callBackFn) {
                callBackFn(tempEventRes);
            }
        } else {
            this.handleCalendarEvent(tempEventRes);
            const createCallRes = await this.createCallService.createCallResult(callInfo, accountInfo, tempEventRes.event?.id);
            if (createCallRes.error) {
                this.handleCreateCallError(createCallRes);
            }
            if (callBackFn) {
                callBackFn(createCallRes);
                this.handleFocusNewEvent(createCallRes.event.id, 'Call2_vod__c', false, false);
            }
            this.handleCalendarEvent(createCallRes);
        }
    }
    
    @api
    previewCallCycles(callCycleEvents, previewOnDay){
        this.myScheduleCalendar.previewCallCycleEvents(callCycleEvents, previewOnDay);
    }

    @api
    async applyCallCycle(applyByWeek) {
        const callCycleEntries = this.eventStore.records.map(event => event.data).filter(event => event.eventType === 'call-cycle-entry');
        const processedCallInfos = callCycleEntries.map(callCycle => CreateCallDataFormatter.processDataForCreateCall(callCycle.startDate, [], callCycle.allDay, callCycle.duration, 
            this.myScheduleCalendar.getView(), this.settings.allowedCallRecordTypes, this.settings.callBackdateLimit, callCycle.callCycleId));
        const date = callCycleEntries.sort((entry1, entry2) => entry1.startDate - entry2.startDate)[0].startDate;
        // eslint-disable-next-line no-undef
        await this.createCalls(callCycleEntries, processedCallInfos, bryntum.calendar.TimeZoneHelper.fromTimeZone(date, TIME_ZONE), applyByWeek);
    }

    @api
    clearCallCycles(callCycleEvents){
        this.myScheduleCalendar?.clearCallCycleEvents(callCycleEvents);
    }

    @api
    async newRecordToast(result) {
        const callId = result.detail.events[0].id;
        const urlPromise = this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: callId,
                actionName: 'view',
            },
        });
        // Calls do not have user-defined names, so we will always have to retrieve the name via uiApi.getRecord
        const namePromise = this.pageCtrl.uiApi.getRecord(callId, ['Call2_vod__c.Name']);            
        const resp = await Promise.all([urlPromise, namePromise]);
        const [url] = resp;
        const name = resp[1]?.fields?.Name?.value;
        this.dispatchEvent(await VeevaToastEvent.recordCreated('Call', name, url));        
    }

    async handleCreateCallCycleEntry(event){
        const { eventInfo } = event.detail;
        this.callCycleService = this.callCycleService || new CallCycleEntryService({ translatedLabels: this.translatedLabels, ctrl: this.ctrl, messageService: this.ctrl.pageCtrl.messageSvc});
        const callCycleCreateResult = await this.callCycleService.createCallCycleEntry(eventInfo, event.detail.accountInfo);
        if (callCycleCreateResult?.error){
            this.handleCreateCallError(callCycleCreateResult);
            this.accountSearchModal.hasClickedOk = false;
        } else {
            eventInfo.callCycleId = callCycleCreateResult.id;
            eventInfo.id = callCycleCreateResult.id;
            eventInfo.recordId = callCycleCreateResult.id;
            this.manageCallCycleCalendar.addCallCycleEventToCalendar(eventInfo);
            this.accountSearchModal.handleCancel();
        }
    }
}