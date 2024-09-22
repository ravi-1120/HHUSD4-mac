/* eslint-disable @locker/locker/distorted-html-element-blocked-properties */
import ICON_PATH from '@salesforce/resourceUrl/calendarIcons';
import USER_ID from '@salesforce/user/Id';

export default class CalendarSidebarPanel {
    USER_CALENDAR_ID = 'veevacalendarresourceid';

    translatedLabels;
    sessionService;
    selectedResources;
    constructor(translatedLabels, externalCalendarInfo, settings, sessionService, eventStoreManager) {
        this.translatedLabels = translatedLabels;
        this.sessionService = sessionService;
        this.externalCalendarInfos = externalCalendarInfo?.externalCalendars;
        this.externalCalendarSetting = externalCalendarInfo?.externalCalendarSetting;
        this.shouldFetchExternalEvents = (this.externalCalendarSetting === 'showExtCalendar' && this.getSelectedResourcesOnPageLoad().length > 0);        
        this.settings = settings;
        this.eventStoreManager = eventStoreManager;
    }

    getSidebarPanelItems(subordinatesInfo){
        this.subordinateMap = this.getSubordinatesMap(subordinatesInfo);
        this.isManager = this.subordinateMap !== null && this.subordinateMap?.length > 0;
        const resourceFilterCmp = this.getResourceFilterComponent();
        return { 
            eventFilter: null,
            datePicker : {
                weight: 100
            },
            msOutlookTitle: this.getCalendarSectionTitle(),
            myCalendarCheckbox: this.getMyCalendarCheckboxCmp(),
            externalCalendarCmp: this.getExternalCalendarCmp(),
            resourceFilter: resourceFilterCmp
        }
    }

    getMyCalendarCheckboxCmp() {
        return (this.externalCalendarSetting !== 'showExtCalendar' && this.isManager) ?
        // eslint-disable-next-line no-undef
        new bryntum.calendar.Checkbox({
            text     : `${this.settings.userName} (${this.translatedLabels.myCalendarMeLabel})`,
            weight : 300,
            checked: true,
            cls : 'veeva-calendar-checkbox', 
            listeners : {
                beforeChange : () => false,
            }
        }) : null;
    }

    getExternalCalendarCmp() {
        if (this.externalCalendarSetting === 'showAddCalendarBtn'){
            return this.getAddCalendarBtnCmp();
        } 
        if (this.externalCalendarSetting === 'loadingMsg'){
            return this.getLoadingMsgComponent();
        }
        return null;
    }

    getCalendarSectionTitle(){
        const calendarSectionTitle = this.externalCalendarSetting !== 'showExtCalendar' ? this.getTitleTextForInternalCals() : this.getTitleTextForExternalCals();
        return {
            type: 'panel',
            title : (this.externalCalendarSetting !== 'showExtCalendar') ? this.getTitleTextForInternalCals() : this.getTitleTextForExternalCals() ,
            weight: calendarSectionTitle ? 200 : 600,
            cls: !calendarSectionTitle ? 'empty-title-section' :  '' 
        }
    }

    getTitleTextForInternalCals(){
        if (this.isManager) {
            return this.translatedLabels.myCalendarsLabel;
        }
        return !this.externalCalendarSetting ? '' : this.translatedLabels.msOutlookTranslatedRtLabel;
    }

    getTitleTextForExternalCals(){
        return this.isManager ? '' : this.translatedLabels.msOutlookTranslatedRtLabel;
    }

    getResourceFilterComponent(){
        let externalCalendarComponent = {
            weight: 500
        };
        if (this.isManager || this.externalCalendarSetting === 'showExtCalendar'){
            externalCalendarComponent = this.getResourceFilterCmp();
        }
        return externalCalendarComponent;
    }

    getLoadingMsgComponent(){
        return {
            style : 'white-space: normal; text-align: left; text-transform: none',
            weight : 400,
            type   : 'label',
            text  : this.translatedLabels.loadingCalendarsMsg,
        };
    }

    getAddCalendarBtnCmp(){
        return {
            weight : 400,
            style : 'text-transform: none',
            type   : 'button',
            text   : this.translatedLabels.addCalendarLabel,
            icon   : 'b-fa b-fa-plus',
            listeners : {
                click : () => this.handleAddCalendarClick(),
                args : [undefined]
            }
        };
    }

    getResourceFilterCmp(){
        this.selectedResources = this.getSelectedResourcesOnPageLoad();
        const myCalendarLabel = this.translatedLabels?.myCalendarsLabel;
        const otherCalendarLabel = this.translatedLabels?.otherCalendarsLabel;
        const sortDirection = myCalendarLabel?.localeCompare(otherCalendarLabel) === -1;

        return {
            selected: {
                values: this.getSelectedResourcesOnPageLoad()
            },
            weight: 500,
            store : {
                groupers: 
                this.isManager ? [{ field: 'calendarTypeLabel', ascending: sortDirection }] : [],
                sorters : [],
            },
            collapsibleGroups : true,
            itemTpl : (record) => {
                if (record?.data?.calendarType === 'Other Calendars') {
                    const userIdentifierInfo = this.translatedLabels.userIdentifierLabel && record.data?.userIdentifier ? `<b>${this.translatedLabels.userIdentifierLabel ?? ''}</b><br/>${record.data?.userIdentifier}<br/><br/>` : '';
                    const userTerritoryInfo = record.data?.territoryObjLabel ? `<b>${record.data?.territoryObjLabel}</b><br/>${record.data?.territories}` : '';
                    const iconSrc = `${ICON_PATH}/info.svg`;
                    return `<div class="subordinate-cal-info">${record.name}</div> <img class="subordinate-info-icon" src="${iconSrc}" data-btip="${userIdentifierInfo}${userTerritoryInfo}" data-btip-align="l-r"></img>`;
                }
                return record.name;
            },
            allowGroupSelect : false,
            listeners : {
                change : (event) => this.changeSelection(event),
            },
            cls : 'myschedule-resource-filter'
        };
    }

    changeSelection(event) {
        // get a reference to the resource filter
        const resourceFilter = window.calendar.sidebar.items.find(item => item.cls?.contains('myschedule-resource-filter'));
        resourceFilter.collapsibleGroups = true;
        // Ensure that the user's veeva calendar is always selected
        if (!event?.value?.find(selResource => selResource.id === this.USER_CALENDAR_ID)){
            resourceFilter.select(this.USER_CALENDAR_ID);
        }
        if (this.selectedResources?.length > 0) {
            // Ensure only one sudordinate calendar is selected
            const currSubCalIds = event.value?.filter(r => r.calendarType === 'Other Calendars')?.map(r => r.id);            
            if (currSubCalIds?.length > 1) {
                const prevCalId = this.selectedResources.includes(currSubCalIds[0]) ? currSubCalIds[0] : currSubCalIds[1];
                resourceFilter.deselect(prevCalId);
                this.eventStoreManager.setSubordinateUserId(currSubCalIds.find(id => id !== prevCalId));
            } else {
                this.eventStoreManager.setSubordinateUserId(currSubCalIds?.length === 1 ? currSubCalIds[0] : null);
            }
        }
        this.selectedResources = event.value?.map(r => r.id);
    }

    async handleAddCalendarClick() {
        const vodInfo = await this.sessionService.getVodInfo();
        let baseAuthUrl = this.settings.microsoftAuthServerURL;
        if (baseAuthUrl){
            this.updatePanel();

            const isProd = vodInfo.isSandbox === 'false';
            const responseJson = await this.preAuthorizeUser(`${baseAuthUrl}/pre-authorize`, { sfSession: vodInfo.sfSession, isProduction: isProd });

            const {addCalendarSuccessMsg} = this.translatedLabels;
            const {addCalendarFailureMsg} = this.translatedLabels;
            const baseParamJson = {
                "successMsg": addCalendarSuccessMsg,
                "failureMsg": addCalendarFailureMsg,
                "activationType": "OUTLOOK",
            }
            baseAuthUrl += '/authorize';

            let fullAuthUrl;
            if (responseJson.data?.nonce) {
                fullAuthUrl = this.getAuthUrlWithNonce(baseAuthUrl, baseParamJson, responseJson.data.nonce);
            } else {
                // If pre-authorization fails, we will fallback to the "plaintext" token msauth endpoint for as long as it's available
                fullAuthUrl = this.getAuthUrlFallback(baseAuthUrl, baseParamJson, {
                    "orgId": vodInfo.orgId,
                    "userId": this.settings.userId,
                    "userName": this.settings.loginUserName,
                    "endpointUrl": window.location.protocol.concat("//").concat(new URL(vodInfo.sfEndpoint).hostname),
                    "isProduction": isProd,    
                });
            }

            window.open(fullAuthUrl, "_blank", "width=800, height=500");
        }
    }

    async preAuthorizeUser(preAuthorizeURL, paramJson) {
        const requestInit = {
            method: 'POST',
        };
        requestInit.headers = {
            'Content-Type': 'application/json',
            'X-Source-Global-Tag': this._sourceGlobalTag,
        };
        requestInit.body = JSON.stringify(paramJson);
        const response = await fetch(preAuthorizeURL, requestInit);
        return response.json();
    }

    getAuthUrlWithNonce(baseAuthUrl, baseParamJson, nonce) {
        const token = this.encodeJson(baseParamJson);
        return `${baseAuthUrl}?token=${token}&nonce=${encodeURIComponent(nonce)}`;
    }

    getAuthUrlFallback(baseAuthUrl, baseParamJson, userInfo) {
        const token = this.encodeJson({
            ...userInfo,
            ...baseParamJson,
        });
        return `${baseAuthUrl}?token=${token}&redirect`;
    }

    encodeJson(json) {
        let encoded = new TextEncoder().encode(JSON.stringify(json))
        encoded = Array.from(encoded, (x) => String.fromCodePoint(x)).join("");
        return encodeURIComponent(btoa(encoded));
    }

   updatePanel() {
        const addCalendarItem = window.calendar.sidebar.items?.find(item => item.text === this.translatedLabels.addCalendarLabel);
        window.calendar.sidebar.remove(addCalendarItem);
    }

    getSelectedResourcesOnPageLoad() {
        const defaultResources = [this.USER_CALENDAR_ID];
        const resources = (!sessionStorage.getItem(`selectedExternalCalendars;${USER_ID}`) || sessionStorage.getItem(`selectedExternalCalendars;${USER_ID}`) === 'undefined') ?
                    [this.externalCalendarInfos.find(externalCalendar => externalCalendar.Is_Default_Calendar_vod__c === true)?.Id] :
                    JSON.parse(sessionStorage.getItem(`selectedExternalCalendars;${USER_ID}`));
                    
        if (!resources || resources.length < 1 || !resources[0]) {
            return defaultResources;
        } 
        return resources.includes(this.USER_CALENDAR_ID) ? resources : [this.USER_CALENDAR_ID, ...resources];
    }

    getSubordinatesMap(subordinatesInfo) {
        let subordinateMap = [];
        if (subordinatesInfo) {
            subordinateMap = Object.keys(subordinatesInfo).map((k) => ( {
                'id': k, 'name': subordinatesInfo[k].name,
                'territories' : subordinatesInfo[k].territories,
                'territoryObjLabel' : subordinatesInfo[k].territoryObjLabel,
                'userIdentifier': subordinatesInfo[k].userIdentifier } ));
        }
        return subordinateMap;
    }

    get subordinates() {
        return this.subordinateMap;
    }
}