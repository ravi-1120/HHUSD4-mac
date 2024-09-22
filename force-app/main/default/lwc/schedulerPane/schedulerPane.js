import SchedulerCallCyclesManager from "c/schedulerCallCyclesManager";
import setUpDragHelper from './schedulerPaneDragHelper';
import SchedulerPaneTabManager from './schedulerPaneTabManager';

export default class SchedulerPane {
    static defaultSchedulerPaneWidth = 470; // accommodates max width of dropdown + scheduler pane margins 
    
    calendarRootElement;
    schedulerGrid;
    calendarObjectInfos;
    selectedView;
    translatedLabels;
    eventStore;
    settings;
    viewTypeMap;

    currentTabLabel;
    currentTabManager;
    calendarMode;
    showWeekends;

    id;
    tabChangePromise;

    static getSchedulerPaneGrid(translatedLabels) {
        // eslint-disable-next-line no-undef
        return new bryntum.calendar.Grid({
            cls: 'scheduler-pane',
            title       : translatedLabels.schedulerLabel,
            collapsible : true,
            collapsed   : true,
            width       : `${SchedulerPane.defaultSchedulerPaneWidth}px`,
            ui          : 'calendar-banner',
            emptyText   : translatedLabels.noAccountsMsg,
            store   : { data: []},
            responsiveLevels: {
                small: '*',
                normal: '*',
                large: '*'
            },
            selectionMode: {
                cell: true,
                multiSelect: false
            },
            tbar: {
                items : [ /* tabPanel */ ],
                cls : 'block-display',
            },
            features : {
                cellMenu: false,
                headerMenu: false,
                stripe   : true,
                cellEdit : false,
                group    : false,
                sort     : false,
            },
            rowHeight: 100,
        });
    }

    constructor({ element, calendarObjectInfos, translatedLabels, eventStore, settings, weekendDays, weekStartDay, calendarMode, showWeekends, currentDate }) {
        this.calendarRootElement = element;
        this.calendarObjectInfos = calendarObjectInfos;
        this.translatedLabels = translatedLabels;
        this.eventStore = eventStore;
        this.settings = settings;
        this.calendarMode = calendarMode;
        this.showWeekends = showWeekends;
        this.schedulerGrid = SchedulerPane.getSchedulerPaneGrid(translatedLabels);
        this.id = this.schedulerGrid?.id;

        // set up tab info
        this.tabManagerInfoPromise = (new SchedulerPaneTabManager()).getSchedulerTabs(translatedLabels, calendarObjectInfos, settings, weekendDays, weekStartDay, currentDate);
    }

    async appendScheduler(calendar) {
        this.appendSplitter();
        await this.appendSchedulerPane(calendar);
    }

    reRenderSchedulerPane(calendar) {
        this.appendSplitter();
        this.calendarRootElement.appendChild(this.schedulerGrid.element);
        this._addDragHelper(calendar);
    }

    async appendSchedulerPane(calendar){  
        this.tabManagerInfo = await this.tabManagerInfoPromise; 
        this.currentTabLabel = this.tabManagerInfo[0].label;
        this.currentTabManager = this.tabManagerInfo[0].tabManager;
        const tabPanel = await this.getSchedulerTabPanel();
        const gridColumns = this.currentTabManager.getColumnConfig();
                
        tabPanel.on('tabChange', async (event) => {            
            await this.tabChangePromise;
            this.tabChangePromise = this.handleTabChange(event);
        });

        // configure grid component based on async info we now have
        this.schedulerGrid.appendTo = this.calendarRootElement;
        this.schedulerGrid.project = calendar.project; // Calendar's stores are contained by a project, pass it to the grid to allow it to access them
        this.schedulerGrid.columns = gridColumns;
        this.schedulerGrid.tbar.items = [ tabPanel ];

        this._attachFooter();
        
        this.schedulerGrid.on('collapse', this.handleCollapse.bind(this));
        this.schedulerGrid.on('expand', this.handleExpand.bind(this));

        this.loadDataPromise = this.loadData();
        this._addDragHelper(calendar);
    }

    _addDragHelper(calendar) {
        // define dragging behavior, reset the drag handler to remove any reference to calendars/grids that no longer exist
        if (this.dragHelper) {
            this.dragHelper.destroy();
        }
        this.dragHelper = setUpDragHelper(this.schedulerGrid, calendar, this.eventStore, this.settings);
    }

    _attachFooter() {
        // eslint-disable-next-line no-undef
        this.schedulerPaneFooter = new bryntum.calendar.Container({
            appendTo: this.schedulerGrid.element,  // .querySelector('.b-panel-ui-calendar-banner'),
            cls : 'block-display scheduler-pane-tab-panel scheduler-pane-footer',
            items: []
        });
        this.tabManagerInfo.forEach(manager => {
            manager.tabManager.schedulerPaneFooter = this.schedulerPaneFooter;
        });
    }

    handleCollapse() {
        const paneClasses = this.schedulerPaneFooter.cls.split(' ');
        paneClasses.push('collapsed-footer');
        this.schedulerPaneFooter.cls = paneClasses.join(' ');

        sessionStorage.setItem('schedulerPaneExpanded', false);
    }

    handleExpand() {
        if (this.schedulerPaneFooter.cls.contains('collapsed-footer')) {
            this.schedulerPaneFooter.cls = this.schedulerPaneFooter.cls.toString().replace('collapsed-footer', '').trim();
        }
        sessionStorage.setItem('schedulerPaneExpanded', true);
    }
    
    getSchedulerTabPanel(){
        const tabItems = [];        
        this.tabManagerInfo.forEach( async (tabInfo) => {
            tabItems.push({'title' : tabInfo.label, items : [ tabInfo.tabItems ], cls: 'scheduler-pane-tab' } );
        });
        // eslint-disable-next-line no-undef
        return new bryntum.calendar.TabPanel({
            cls : 'scheduler-pane-tab-panel',
            items : tabItems
        });

    }

    async loadData(){
        await this.currentTabManager.loadData(this.schedulerGrid);
    }

    appendSplitter(){
        // eslint-disable-next-line no-new,no-undef
        new bryntum.calendar.Splitter({
            appendTo : this.calendarRootElement
        });
    }

    appendSchedulerStyleSheet() {
        // must append at run time for styling to be respected, pins Scheduler title to top of grid when collapsed
        const style = document.createElement('style');
        let styling = '';
        styling += `
        .b-panel-header.b-dock-left {
            flex-flow: column nowrap;
        }
        
        .b-panel-header.b-dock-left .b-header-title {
            transform: none;
        }
        
        div[data-column="Account-Formatted_Name_vod__c"] {
            white-space: normal;
        }
        
        .b-gridbase:not(.b-moving-splitter) .b-grid-subgrid:not(.b-timeaxissubgrid) .b-grid-row:not(.b-group-row) .b-grid-cell.b-hover,
        .b-gridbase:not(.b-moving-splitter) .b-grid-subgrid:not(.b-timeaxissubgrid) .b-grid-row:not(.b-group-row) .b-grid-cell.b-hover.b-selected {
            background-color: transparent;
        }
        
        .drag-proxy {
            width: 250px;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            line-clamp: 2;
            -webkit-box-orient: vertical;
        }`;
        const styleStr = document.createTextNode(styling);
        style.appendChild(styleStr);
        // eslint-disable-next-line @lwc/lwc/no-document-query
        document.getElementsByTagName('head')[0].appendChild(style);
    }

    _updateSchedulerGridConfig(activeIndex) {
        // accounts tab is index 0, call cycles tab is index 1
        this.schedulerGrid.store.data = [];
        this.schedulerGrid.columns = this.currentTabManager.getColumnConfig();
        this.schedulerGrid.selectionMode.cell = activeIndex === 0;
        this.schedulerGrid.emptyText = this.currentTabManager.emptyText;
        this.schedulerGrid.selectionMode.checkbox = activeIndex === 1;
        this.schedulerGrid.selectionMode.rowCheckboxSelection = activeIndex === 1;
        this.schedulerGrid.headerContainer.style.display = activeIndex === 1 ? 'none' : '';
    }

    async handleTabChange(event){
        // before switching to new tab
        const prevTabIsCallCycles = event.prevActiveIndex === 1;
        const tabIndex = event.activeIndex;

        if (prevTabIsCallCycles) {
            // remove onSelection event listener from call cycles panel
            this.currentTabManager.schedulerGrid.removeAllListeners();
            this.currentTabManager.onSelectionListenerAdded = false;
            this.currentTabManager?.clearPreviewedCallCycles();
        }

        // start switching to new tab
        sessionStorage.setItem('schedulerPaneTab', tabIndex);
        
        const curView = this.calendarMode;

        this.currentTabLabel = this.tabManagerInfo[tabIndex].label;
        this.currentTabManager = this.tabManagerInfo[tabIndex].tabManager;

        if (this.loadDataPromise) {
            await this.loadDataPromise;
        }
        if (this.tabManagerInfo[0].tabManager.updateListPromise) {
            await this.tabManagerInfo[0].tabManager.updateListPromise;
        }
        this._updateSchedulerGridConfig(tabIndex);
        this.loadDataPromise = this.loadData();

        if (this.currentTabManager.shouldUpdateOnViewChange() && this.currentTabManager.byDayButton) {
            const prevCycleView =  SchedulerCallCyclesManager.locateSettingWithDefault('cycleTabView', 'week');
            this.currentTabManager.byDayButton.pressed = curView === 'week' && prevCycleView === 'day';
        }
        this.updateView({});
    }

    updateView({ view, showWeekends, targetDay }) {
        const isDayToWeek = this.calendarMode === 'day' && view === 'week';
        if (view) {
            this.calendarMode = view;
        }
        if (showWeekends !== undefined && showWeekends !== null) {
            this.showWeekends = showWeekends;   
        }

        if (this.currentTabManager.shouldUpdateOnViewChange()) {
            this.currentTabManager.handleViewUpdate(this.calendarMode, this.showWeekends, isDayToWeek ? targetDay : null);
        } else {
            this.currentTabManager.schedulerPaneFooter.items = [];
        }
    }
}