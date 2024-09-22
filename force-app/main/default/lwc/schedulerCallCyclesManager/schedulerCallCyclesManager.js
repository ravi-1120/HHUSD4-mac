import getCallCycleInfo from '@salesforce/apex/VeevaMyScheduleController.getCallCycleInfo';
import SchedulerManagerBase from 'c/schedulerManagerBase';

export default class SchedulerCallCyclesManager extends SchedulerManagerBase{
    static DAY_NAMES = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    DAY_BUTTON_TRANSLATIONS;

    calendarMode;
    cycleView;
    showWeekends;
    weekendDays;
    weekStartDay;
    daySourceButtons;
    footerButtons;
    callCyclePanel;
    dayWeekToggle;
    onSelectionListenerAdded = false;
    
    _selectedDay;
    _selectedTargetDay;


    static locateSettingWithDefault(settingName, defaultValue) {
        const res = sessionStorage.getItem(settingName);
        if (res) {
            return res === "true" || res === "false" ? String(res) === "true" : res;
        }
        return defaultValue;
    }

    _setDayButtonTranslations() {
        const mostRecentSunday = new Date();
        mostRecentSunday.setDate(mostRecentSunday.getDate() - mostRecentSunday.getDay());
        // eslint-disable-next-line no-undef
        this.DAY_BUTTON_TRANSLATIONS = Array.from(Array(7)).map((_, i) => bryntum.calendar.DateHelper.format(new Date(mostRecentSunday.getFullYear(), mostRecentSunday.getMonth(), mostRecentSunday.getDate() + i), 'd1'));
    }
    
    constructor(translatedLabels, calendarObjectInfos, settings, weekendDays, weekStartDay, currentDate) {
        super(translatedLabels, calendarObjectInfos, settings);
        this._setDayButtonTranslations();

        this.cycleView = 'week';
        this.weekendDays = weekendDays;
        this.weekStartDay = weekStartDay;
        this._selectedDay = parseInt(SchedulerCallCyclesManager.locateSettingWithDefault('selectedDay', new Date(currentDate).getDay()), 10);
        this._selectedTargetDay = parseInt(SchedulerCallCyclesManager.locateSettingWithDefault('targetDay', new Date(currentDate).getDay()), 10);
        this.emptyText = this._getEmptyText();
    }

    shouldUpdateOnViewChange() {
        return true;
    }

    getPreviewCallCycleText() {
        return this.calendarMode === 'month' ? '' : this.translatedLabels.previewCallCycleMsgLabel;
    }

    getCallCycleHeaderPanelText() {
        return this.calendarMode === 'month' ? '' : this.translatedLabels.applyCallCycleLabel;
    }

    getDisableCallCycleText() {
        return this.calendarMode === 'month' ? this.translatedLabels.disableCallCyclesMonthLabel : '';
    }

    getTabPanel() {
        // eslint-disable-next-line no-undef
        this.optionalDisableCallCyclePanel = new bryntum.calendar.Panel({
            html: this.getDisableCallCycleText()
        });
        
        // eslint-disable-next-line no-undef
        this.optionalManageCallCyclePanel = new bryntum.calendar.Panel({
            items: [this.getManageCallCycleButton()],
            cls: 'manage-call-cycle-button-panel'
        });

        // eslint-disable-next-line no-undef
        this.callCycleHeaderPanel = new bryntum.calendar.Panel({
            html: this.getCallCycleHeaderPanelText(),
            cls: 'call-cycle-panel-header'
        });
        // eslint-disable-next-line no-undef
        this.callCycleMsgPanel = new bryntum.calendar.Panel({
            html: this.getPreviewCallCycleText(),
            cls: `call-cycle-panel-message ${this.calendarMode}-view`
        });
        // eslint-disable-next-line no-undef
        this.dayWeekToggle = new bryntum.calendar.ButtonGroup({
            cls         : 'b-raised call-cycle-type-toggle',
            toggleGroup : true,
            items       : this.getDayWeekToggleItems(),
            listeners: {
                change : ((value) => this.changeCallCycleView(value))
            }
        });
        
        // eslint-disable-next-line no-undef
        return new bryntum.calendar.Panel({  
            items: [ this.optionalManageCallCyclePanel, this.optionalDisableCallCyclePanel, this.callCycleHeaderPanel, this.callCycleMsgPanel, this.dayWeekToggle, this.getDayButtonsPanel()],
            cls: 'call-cycle-tab-panel',
            layoutStyle: {
                flexDirection: 'column',
                justifyContent: 'unset'
            }
        });
    }

    getManageCallCycleButton() {
        // eslint-disable-next-line no-undef
        this.manageCallCycleButton = new bryntum.calendar.Button({
            cls: 'manage-call-cycle-button b-transparent ',
            text: this.translatedLabels.manageCallCyclesLabel,
            onClick: () => {
                if (!this.callCycleInfo) {
                    return;
                }
                const mySchedule = this.schedulerGrid?.element?.closest('c-my-schedule');
                mySchedule.toggleToManageCallCycleCalendar(this.callCycleInfo);
            }
        });
        return this.manageCallCycleButton;
    }

    async loadData(schedulerGrid) {
        this.showSpinner();
        this.schedulerGrid = schedulerGrid;
        if (!this.onSelectionListenerAdded) {
            this.schedulerGrid.on('selectionChange', (e) => this.onSelection(e));
            this.onSelectionListenerAdded = true;
        }
        this.callCycleInfo = await getCallCycleInfo();
        if (this.schedulerGrid) {
            this.loadCallCycles();
        }
        this.loadInPreviousData();
        this.hideSpinner();
    }

    changeCallCycleView() {
        if (this.byDayButton.pressed) {
            this.cycleView = 'day';
        } else if (this.byWeekButton.pressed) {
            this.cycleView = 'week';
        }

        sessionStorage.setItem('cycleTabView', this.cycleView);
        this.handleViewUpdate(this.calendarMode, this.showWeekends);
    }

    getDayWeekToggleItems() {
        return this.calendarMode === 'month' ? [] : 
        [
            { text : this.translatedLabels.callCycleByWeekLabel, pressed : this.byWeekButton?.pressed },
            { text : this.translatedLabels.callCycleByDayLabel, pressed: this.byDayButton?.pressed }
        ];
    }
        
    getDayButtonsPanel(){
        // eslint-disable-next-line no-undef
        this.daySourceButtons = new bryntum.calendar.ButtonGroup({
            appendTo: this.element,
            cls: 'b-raised day-button-container',
            toggleGroup: true,
            items    : this._getDayButtonItems(this._selectedDay),
            callOnFunctions : true,
            onClick: (event) => {
                // selected day is updated
                this._selectedDay = event.source?.dayNum ?? this.firstVisibleDayOfWeek;
                sessionStorage.setItem('selectedDay', this._selectedDay);
                this.updateSchedulerPane();
            }
        });

        // eslint-disable-next-line no-undef 
        this.callCyclePanel = new bryntum.calendar.Panel({
            title: this.calendarMode === 'week' ? this.translatedLabels.callCyclePreviewLabel : this.translatedLabels.callCyclePreviewByDayLabel, 
            items: [this.daySourceButtons],
            cls : this.getCallCyclePanelCls()
        });
        return this.callCyclePanel;
    }

    getCallCyclePanelCls() {
        return this.byDayButton?.pressed ? 'call-cycle-button-panel call-cycle-source-day-button-panel' : 'display-none';
    }

    _getDayButtonItems(selectedDay) {
        if (this.cycleView !== 'day' || this.calendarMode === 'month') {
            return [];
        }
        const buttons = [];
        let startingDay = parseInt(this.weekStartDay, 10);
        for (let i = 0; i < 7; i++) {
            const currentDay = (startingDay++) % 7;
            buttons.push({ text : this.DAY_BUTTON_TRANSLATIONS[currentDay], cls: 'b-raised day-button', dayNum: currentDay });
        }

        const filteredButtons =  !this.showWeekends ? buttons.filter(btn => !this.weekendDays.includes(btn.dayNum)) : buttons;
        return filteredButtons.map(btn => ({...btn, pressed: btn.dayNum === selectedDay}));
    }

    getColumnConfig() {
        return [{
            flex       : 1,
            field      : 'callCycleInfo',
            htmlEncode : false,
            htmlEncodeHeaderText: false,
            renderer   : ({record, size}) => {
                size.height = 50;
                // // eslint-disable-next-line @lwc/lwc/no-inner-html
                const accountInfoHTML = `<div class="scheduler-pane-call-cycle-record">${record.data.text}</div>`;
                return accountInfoHTML
            }
        }];
    }
    
    loadCallCycles() {
        this.emptyText = this._getEmptyText();
        this.schedulerGrid.emptyText = this.emptyText;

        const selectedRow = parseInt(SchedulerCallCyclesManager.locateSettingWithDefault('selectedRow', null), 10);
        if (this.calendarMode === 'month' || !this.callCycleInfo) {
            this.schedulerGrid.store.removeAll();
            sessionStorage.setItem('selectedRow', selectedRow);
            return;
        }
        const sortedCallCycles = this.cycleView === 'day' ? this.processCallCycleInfoForDayView() : this.processCallCycleInfoForWeekView();

        this.schedulerGrid.store.removeAll(true);
        this.schedulerGrid.store.add(sortedCallCycles);

        if (selectedRow) {
            this.selectRowByWeekNum(selectedRow);
        }
    }

    processCallCycleInfoForDayView() {
        const curDayName = SchedulerCallCyclesManager.DAY_NAMES[this._selectedDay];
        return Object.entries(this.callCycleInfo).flatMap(([weekNum, cycleInfoByDay]) => 
            Object.entries(cycleInfoByDay).filter(([dayName]) => dayName === curDayName) // only display call cycle entries for given day
            .map(([dayName, weekDayCycleInfo]) => {
                const callLabel = weekDayCycleInfo.entries?.length === 1 ? this.calendarObjectInfos.Call2_vod__c.label : this.calendarObjectInfos.Call2_vod__c.labelPlural;
                const weekText = this.translatedLabels.weekXLabel.replace('{0}', weekNum);
                return {
                    text : `<b>${weekText}, ${weekDayCycleInfo.label}</b> (${weekDayCycleInfo.entries?.length} ${callLabel.toLowerCase()})`, 
                    calls : weekDayCycleInfo.entries,
                    cls : 'call-cycle-temp-event',
                    weekNum,
                    dayName
                };
            })
        );
    }

    processCallCycleInfoForWeekView() {
        return Object.entries(this.callCycleInfo).map(([weekNum, cycleInfoByDay]) => {
            const callNum = Object.values(cycleInfoByDay).reduce((prevNum, weekDayCycleInfo) => prevNum + (weekDayCycleInfo.entries?.length ?? 0), 0);
            const callLabel = callNum === 1 ? this.calendarObjectInfos.Call2_vod__c.label : this.calendarObjectInfos.Call2_vod__c.labelPlural;
            const weekText = this.translatedLabels.weekXLabel.replace('{0}', weekNum);
            return {
                text : `<b>${weekText}</b> (${callNum} ${callLabel.toLowerCase()})`,
                calls: Object.values(cycleInfoByDay).flatMap(weekDayCycleInfo => weekDayCycleInfo.entries),
                cls : 'call-cycle-temp-event',
                weekNum
            }
        });
    }

    selectRowByWeekNum(weekNum) {
        this.schedulerGrid.selectRow({ record: this.schedulerGrid.data.find(e => parseInt(e.data?.weekNum, 10) === weekNum), addToSelection: true });
        sessionStorage.setItem('selectedRow', weekNum);
    }

    loadInPreviousData() {
        const prevSelectedRow =  parseInt(SchedulerCallCyclesManager.locateSettingWithDefault('selectedRow', null), 10);
        const prevSelectedDay = parseInt(SchedulerCallCyclesManager.locateSettingWithDefault('selectedDay', this._selectedDay), 10);
        const prevTargetDay = parseInt(SchedulerCallCyclesManager.locateSettingWithDefault('targetDay', this._selectedTargetDay), 10);

        this._selectedDay = prevSelectedDay;
        this._selectedTargetDay = prevTargetDay;
        
        if (prevSelectedRow) {
            this.selectRowByWeekNum(prevSelectedRow);
        }
    }

    _getCallCyclePanelTitle() {
        if (this.cycleView !== 'day' || this.calendarMode === 'month') {
            return "";
        }
        return this.calendarMode === 'week' ? this.translatedLabels.callCyclePreviewLabel : this.translatedLabels.callCyclePreviewByDayLabel;
    }

    updateSchedulerPane() {
        if (!this.showWeekends && this.weekendDays.includes(this._selectedDay)) {
            this._selectedDay = this.firstVisibleDayOfWeek;
        }
        if (!this.showWeekends && this.weekendDays.includes(this._selectedTargetDay)) {
            this._selectedTargetDay = this.firstVisibleDayOfWeek;
        }
        this.daySourceButtons.items = this._getDayButtonItems(this._selectedDay);
        if (this.footerButtons) {
            this.footerButtons.items = this.calendarMode === 'week' ? this._getDayButtonItems(this._selectedTargetDay) : [];
        }
        this.optionalDisableCallCyclePanel.html = this.getDisableCallCycleText();
        this.optionalDisableCallCyclePanel.cls = this.calendarMode === 'month' ? 'disable-call-cycle-warning' : 'display-none';

        this.callCycleMsgPanel.html = this.getPreviewCallCycleText(); 
        this.callCycleMsgPanel.cls = `call-cycle-panel-message ${this.calendarMode}-view`;

        this.callCycleHeaderPanel.html = this.getCallCycleHeaderPanelText(); 
        this.callCyclePanel.title = this._getCallCyclePanelTitle();
        this.callCyclePanel.cls = this.getCallCyclePanelCls();
        this.updateViewButtons();

        if (this.schedulerGrid) {
            this.loadCallCycles(); // reorganize call cycle info based on view
        }
    }

    handleViewUpdate(view, showWeekends, newTargetDay = null) {
        this.calendarMode = view;
        this.showWeekends = showWeekends;
        if (newTargetDay) {
            this._selectedTargetDay = newTargetDay;
            sessionStorage.setItem('targetDay', this._selectedTargetDay);
        }
        this.updateViewButtons();
        this.callCyclePanel.title = this._getCallCyclePanelTitle();

        if (this.callCycleFooterPanel) {
            this.callCycleFooterPanel.title = this.cycleView === 'day' && this.calendarMode === 'week' ? this.translatedLabels.callCycleApplyLabel : "";
        }
        this.updateSchedulerPane();
        this.updateFooter();
        this.loadInPreviousData();
    }

    _noViewSelected() {
        return !this.dayWeekToggle?.items.find(btn => btn.pressed);
    }

    updateViewButtons() {
        if (this.calendarMode === 'month' || this.dayWeekToggle.items.length < 1) {
            this.dayWeekToggle.items = this.getDayWeekToggleItems();
        }
        if (this.calendarMode === 'day') {
            this.byDayButton?.enable();
            this.byWeekButton?.disable();
            if (this.byDayButton) {
                this.byDayButton.pressed = true;
            }
        } else if (this.calendarMode === 'week') {            
            this.byWeekButton?.enable();
            this.byDayButton?.enable();
            
            if (this._noViewSelected() && this.byWeekButton) {
                this.byWeekButton.pressed = true;
                this.cycleView = 'week';
            }
        }
    }

    getSchedulerTabFooter() {
        // eslint-disable-next-line no-undef
        this.footerButtons = new bryntum.calendar.ButtonGroup({
            appendTo: this.element,
            cls: 'b-raised day-button-container',
            toggleGroup: true,
            items    : this.calendarMode === 'week' ? this._getDayButtonItems(this._selectedTargetDay) : [],
            callOnFunctions : true,
            onClick: (event) => {
                this._selectedTargetDay = event.source?.dayNum ?? this.firstVisibleDayOfWeek;
                sessionStorage.setItem('targetDay', this._selectedTargetDay);
                this.handlePreviewDaySelection();
            }
        });

        // eslint-disable-next-line no-undef
        const applyCallCycleButton = new bryntum.calendar.Button({
            appendTo: this.element,
            cls: 'b-raised apply-call-cycle-btn',
            text: this.translatedLabels.applyCallCycleLabel,
            layoutStyle: {
                flexDirection: 'column'
            },
            onClick: (event) => this.applyCallCycle(event)
        });
        applyCallCycleButton.disable(); 

        // eslint-disable-next-line no-undef 
        this.callCycleFooterPanel = new bryntum.calendar.Panel({
            title: this.cycleView === 'day' && this.calendarMode === 'week' ? this.translatedLabels.callCycleApplyLabel : "",
            items: [this.footerButtons, applyCallCycleButton],
            cls : 'call-cycle-button-panel call-cycle-panel-footer'
        });
        return this.callCycleFooterPanel;
    }

    updateFooter() {
        if (this.calendarMode === 'month' && this.schedulerPaneFooter) {
            this.schedulerPaneFooter.items = [];
            return;
        }
        super.updateFooter();
    }

    onSelection(event) {
        if (event.action === 'select') {
            const rowVal = event.selected ? event.selected[0]?.data?.weekNum : null;
            sessionStorage.setItem('selectedRow', rowVal);
        } else {
            this.applyCallCycleButton?.disable();
            this.clearPreviewedCallCycles();
            this.selected = '';
            sessionStorage.setItem('selectedRow', null);
            return;
        }
        [this.selected] = event.selected;
        sessionStorage.setItem('selectedRow', parseInt(this.selected?.data?.weekNum, 10));
        if (this._canCreateCalls()) {
            this.applyCallCycleButton.enable();
        }
        this.previewSelectedCallCycles(event.selected[0]?.data?.calls);
    }

    async applyCallCycle() {
        this.applyCallCycleButton.disable();
        this.manageCallCycleButton.disable();
        await this.schedulerGrid.element.closest('c-my-schedule').applyCallCycle(this.byWeekButton.pressed);
        this.schedulerGrid.deselectAll();
        this.manageCallCycleButton.enable();
    }

    get applyCallCycleButton() {
        return this.callCycleFooterPanel?.items[1];
    }

    get byWeekButton() {
        return this.dayWeekToggle?.items[0];
    }

    get byDayButton() {
        return this.dayWeekToggle?.items[1];
    }

    get firstVisibleDayOfWeek() {
        let firstDay = this.weekStartDay;
        while (this.showWeekends === false && this.weekendDays.includes(firstDay)) {
            firstDay++;
        }
        return firstDay;
    }

    handlePreviewDaySelection(){
        if (this.schedulerGrid.selectedRecord){
            this.previewSelectedCallCycles(this.schedulerGrid.selectedRecord?.data?.calls);
        }
    }

    previewSelectedCallCycles(selectedCallCycles){
        selectedCallCycles.forEach(callCycle => {
            this.addEventAttributesToCallCycles(callCycle);
        });
        this.schedulerGrid.element.closest('c-my-schedule')?.previewCallCycles(selectedCallCycles, this.byDayButton?.pressed ? this._selectedTargetDay : '');
    }

    clearPreviewedCallCycles(){
        this.schedulerGrid.element.closest('c-my-schedule')?.clearCallCycles();
    }

    addEventAttributesToCallCycles(callCycle){
        callCycle.dayOfWeek = SchedulerCallCyclesManager.DAY_NAMES.indexOf(callCycle.Day_of_Week_vod__c);
        callCycle.callCycleId = callCycle.Id;
        callCycle.accountId = callCycle.Account_vod__c;
        callCycle.allDay = false;
        callCycle.duration = callCycle.Duration_vod__c;
        callCycle.durationUnit = 'm';
        callCycle.name = callCycle?.Account_vod__r?.Formatted_Name_vod__c;
        callCycle.eventType = 'call-cycle-entry';
        callCycle.cls = 'call-cycle-entry';
        callCycle.draggable = false;
        callCycle.resizable = false;
    }

    _canCreateCalls() {
        return this.calendarObjectInfos.Call2_vod__c?.createable;
    }

    _getEmptyText() {
        return this.calendarMode === 'month' ? '' : `<div class='empty-text-cls'>${this.translatedLabels.noCallCyclesLabel}</div>`;
    }
}