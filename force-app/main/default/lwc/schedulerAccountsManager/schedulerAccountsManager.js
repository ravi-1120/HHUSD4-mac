import getViews from '@salesforce/apex/VeevaMyScheduleController.getViews';
import getSchedulerUserPreferences from '@salesforce/apex/VeevaMyScheduleController.getSchedulerUserPreferences';
import setLastSchedulerAccountList from '@salesforce/apex/VeevaMyScheduleController.setLastSchedulerAccountList';
import getUserTerritories from '@salesforce/apex/VeevaMyScheduleController.getUserTerritories';
import getViewDefinition from '@salesforce/apex/VeevaMyScheduleController.getViewDefinition';
import getCyclePlans from '@salesforce/apex/VeevaMyScheduleController.getCyclePlans'; 
import getCyclePlanTargets from '@salesforce/apex/VeevaMyScheduleController.getCyclePlanTargets'; 
import ICON_PATH from '@salesforce/resourceUrl/calendarIcons';
import MyAccountsDataService from 'c/myAccountsDataService';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import AccountRecTypeIconService from 'c/accountRecTypeIconService';
import SchedulerManagerBase from 'c/schedulerManagerBase';
import LOCALE from '@salesforce/i18n/locale';
import USER_ID from '@salesforce/user/Id'
import VeevaMedicalIdentifierHelper from "c/veevaMedicalIdentifierHelper";
import SchedulerViewDefnConfig from './schedulerViewDefnConfig';

export default class SchedulerAccountsManager extends SchedulerManagerBase {
    static CYCLE_PLAN_ATTAINMENT_LABEL = "%";
    static CYCLE_PLAN_TARGET_METRICS_DELIMITER = "/";

    selectedView;
    accountDataService;
    defaultViews = [];
    viewTypeMap;
    
    constructor(translatedLabels, calendarObjectInfos, settings){
        super(translatedLabels, calendarObjectInfos, settings);
        this.accountDataService = new MyAccountsDataService(getService(SERVICES.DATA));
        const accountRecTypeIconService = new AccountRecTypeIconService(this.translatedLabels.recordTypeIconMapString);
        this.recordTypeIconMap = accountRecTypeIconService.getRecTypeIconMap();
        this.createViewTypeMap();

        this.defaultViews.push(this.translatedLabels.allAccountsLabel);
        this.defaultViews.push(this.translatedLabels.allBusinessAccountsLabel);
        this.defaultViews.push(this.translatedLabels.allPersonAccountsLabel);
        this.defaultViews.push(this.translatedLabels.allChildAccountsLabel);

        this.emptyText = this.translatedLabels.noAccountsMsg;
    }

    async getTabPanel(){
        this.viewsAndLists = await this.getViewsAndLists();
        await this.getInitialSelectedViewOrList(this.viewsAndLists);
        const viewAndListsCombo = this.getViewsAndListsDropdown(this.viewsAndLists);
        const accountTabIcon = this.getAccountTabIcon();
        // eslint-disable-next-line no-undef 
        const viewsDropdownPanel = new bryntum.calendar.Panel({
            items: [accountTabIcon, viewAndListsCombo],
            cls : 'view-dropdown-container'
        });
        return viewsDropdownPanel;
    }

    async getViewsAndLists() {
        // these are not View_vod record so they don't have an ID
        let allViewsAndLists = [{ id: this.translatedLabels.allPersonAccountsLabel, name: this.translatedLabels.allPersonAccountsLabel, type: 'VIEW'},
                                { id: this.translatedLabels.allBusinessAccountsLabel, name: this.translatedLabels.allBusinessAccountsLabel, type: 'VIEW'}];
        if (this.settings.enableChildAccount) {
            allViewsAndLists.push({ id: this.translatedLabels.allChildAccountsLabel, name: this.translatedLabels.allChildAccountsLabel, type: 'LOCATION_CHILD_ACCOUNT_VIEW'});
        } else {
            allViewsAndLists.splice(0, 0, { id: this.translatedLabels.allAccountsLabel, name: this.translatedLabels.allAccountsLabel, type: 'VIEW'});
        }
        const [viewsAndLists, cyclePlanObjs] = await Promise.all([getViews(), getCyclePlans()]);

        const cyclePlans = cyclePlanObjs.map(plan => ({
            id: plan.Id,
            name: plan.Name,
            type: 'CYCLE_PLAN'
        }));
        allViewsAndLists.push(...viewsAndLists);
        allViewsAndLists.push(...cyclePlans);

        if (!this.settings.enableChildAccount) {
            allViewsAndLists = allViewsAndLists.filter(viewOrList => viewOrList.source !== 'LOCATION');
        }
        const modified = [];
        allViewsAndLists.forEach(viewOrList => {
            const copy = {...viewOrList};
            copy.type = copy.source === 'LOCATION' ? 'LOCATION_CHILD_ACCOUNT_VIEW' : copy.type
            modified.push(copy);
        });
        return modified;
    }

    async getInitialSelectedViewOrList(viewsAndLists) {
        this.selectedView = sessionStorage.getItem(`selectedViewOrList;${USER_ID}`);
        if (this.selectedView && !this.defaultViews.includes(this.selectedView)) {
            // update preferences record with last view cached locally
            setLastSchedulerAccountList({ accountListId: this.selectedView });
        }
        if (!this.selectedView || this.selectedView === 'undefined') {
            this.selectedView = await getSchedulerUserPreferences();
        }
        if (!this.selectedView || !viewsAndLists.find(viewOrList => viewOrList.id === this.selectedView)) {
            this.selectedView = this.settings.enableChildAccount ? this.translatedLabels.allChildAccountsLabel : this.translatedLabels.allAccountsLabel;
        }
    }

    getViewsAndListsDropdown(viewsAndLists) {
        const maxDropdownWidth = 398;
        const defaultNumAccounts = 0;
        
        // eslint-disable-next-line no-undef
        return new bryntum.calendar.Container({
            items : {
                viewSelectorHeader  : { type : 'panel', title : `${this.translatedLabels.accountsNumParenLabel.replace('{0}', Intl.NumberFormat(LOCALE).format(defaultNumAccounts))}`, cls: 'view-selector-header' },
                cyclePlanTargetRsTotal: { type: 'container', html: this.translatedLabels.totalRsLabel.replace('{0}', Intl.NumberFormat(LOCALE).format(defaultNumAccounts)), cls: 'cycle-plan-target-rs-total', style: 'display: none' },
                viewSelector : {
                    type: 'combo',
                    displayField     : 'name',
                    valueField       : 'id',
                    listCls: 'view-list-dropdown-menu',
                    style: 'padding-left: 5px',
                    height: '1.8em',
                    width: '98%',
                    picker : {
                        minHeight: 440,
                        maxWidth: maxDropdownWidth,
                        width: 'auto',
                        allowGroupSelect : false,
                        // Show text based on group name
                        groupHeaderTpl   : (record, groupName) => this.getDropdownHeaderName(groupName)
                    },
                    value : this.selectedView,
                    store : {
                        fields : [ 'type', 'name' ],
                        groupers : [{ 
                            field : 'type', 
                            ascending : false,
                        }],
                        data : viewsAndLists,
                    },
                    editable : false,
                    contentElementCls: 'view-picker',
                    onSelect: ({record}) => { this.updateSelectedViewOrList(record)},
                    listItemTpl : (record) => this.styleDropdownItems(record)
                }
            },
            width: '100%',
            style: 'padding-left: 5px; flex-direction: column'
        });
    }

    styleDropdownItems(record) {
        const listItemContainer = document.createElement('div');
        listItemContainer.classList.add('selected-view-list-item');
        if (record.data.id === this.selectedView) {
            const selectedIcon = document.createElement('i')
            selectedIcon.classList.add('fas', 'b-fa-check', 'selected-view-list-icon');
            listItemContainer.appendChild(selectedIcon);
        }
        const itemName = document.createElement('div');
        itemName.classList.add('view-list-name', 'one-line-truncation');
        itemName.appendChild(document.createTextNode(record.name));
        listItemContainer.appendChild(itemName);
        if (record.type === 'ACCOUNT_LIST'){
            listItemContainer.appendChild(this._createAccountListIcon(record.data?.color, 'dropdown-account-list-icon'));
        }
        // eslint-disable-next-line @lwc/lwc/no-inner-html
        return listItemContainer.outerHTML;
    }

    _createAccountListIcon(color, cls) {
        const listImg = document.createElement('i');
        listImg.classList.add('fas', 'b-fa-circle', cls);
        listImg.style.color = `var(--veeva-vod-theme-${color})`;
        return listImg;
    }

    async updateSelectedViewOrList(viewOrList) {
        this.updatedSelectedAccountListIcon(viewOrList);

        this.showSpinner();
        if (!this.defaultViews.includes(viewOrList.id)){
            setLastSchedulerAccountList({ accountListId: viewOrList.id });
        }
        this.selectedView = viewOrList.id; 
        this.updateListPromise = this.loadAccountsForSelectedView();
        await this.updateListPromise;
        this.hideSpinner();
        sessionStorage.setItem(`selectedViewOrList;${USER_ID}`, this.selectedView);

    }

    updatedSelectedAccountListIcon(viewOrList) {
        if (!this.schedulerGrid) {
            return;
        }
        const accountListIcon = this.schedulerGrid.element.querySelector('.selected-account-list-icon');
        if (viewOrList?.type === 'ACCOUNT_LIST') {
            const color = viewOrList.color || viewOrList.data?.color;
            if (accountListIcon) {
                accountListIcon.style.color = `var(--veeva-vod-theme-${color})`;
            } else {
                const dropdownEl = this.schedulerGrid.element.querySelector('[data-ref="viewSelector"] input');
                dropdownEl.parentElement.insertBefore(this._createAccountListIcon(color, 'selected-account-list-icon'), dropdownEl);
            }
        } else {
            accountListIcon?.remove();
        }
    }

    getAccountTabIcon() {
        const defaultColor = "A09D9B";
        const defaultIcon = `${ICON_PATH}/account.svg`;

        const iconContainer = 
        `<div class="account-tab-icon-container" style="background-color: #${this.calendarObjectInfos.Account.themeInfo.color || defaultColor}">
            <img src="${this.calendarObjectInfos.Account?.themeInfo?.iconUrl || defaultIcon}" class="account-tab-icon" alt="Account">
        </div>`;

        // eslint-disable-next-line no-undef
        return new bryntum.calendar.Panel({
            maxHeight   : '50px',
            maxWidth    : '50px',
            cls: 'scheduler-pane-icon-container',
            html: iconContainer
        });
    }

    getColumnConfig() {
        return [{
            text       : `<div class="scheduler-pane-column-header">${this.calendarObjectInfos.Account.labelPlural}<br><div class="drag-drop-suggestion">${this.translatedLabels.dragAndDropSuggestionLabel}</div></div>`,
            flex       : 1,
            field      : 'Account-Formatted_Name_vod__c',
            htmlEncode : false,
            htmlEncodeHeaderText: false,
            renderer   : ({ record, size }) => {
                const schedulerPaneAccountDetails = this.createAccountDetailsDiv(record);
                
                // eslint-disable-next-line @lwc/lwc/no-inner-html
                const accountInfoHTML = `<div class="scheduler-pane-account-record accounts-row"><img class="scheduler-pane-account-icon" src=${record.data.veevaIconUrl}>${schedulerPaneAccountDetails.outerHTML}</div>`;

                const textPercentWidthOfPane = .6;

                // pane is collapsed on page load, so temp cell div will be narrow and tall. if grid is collapsed, use default pane width to render temp cell and calculate cell height
                schedulerPaneAccountDetails.style.width = `${(this.schedulerGrid.collapsed ? this.defaultSchedulerPaneWidth : this.schedulerGrid.width) * textPercentWidthOfPane}px`;
                document.body.appendChild(schedulerPaneAccountDetails);

                const computedStyle = window.getComputedStyle(schedulerPaneAccountDetails)
                const topAndBottomPadding = 20 * 2;
                const elemHeight = computedStyle?.getPropertyValue('height') ? parseInt(computedStyle?.getPropertyValue('height'), 10) + topAndBottomPadding : 0;
                size.height = elemHeight > 80 ? elemHeight : 80;
                document.body.removeChild(schedulerPaneAccountDetails);

                return accountInfoHTML;
            }
        }];
    }

    async loadData(schedulerGrid) {
        this.schedulerGrid = schedulerGrid;

        this.showSpinner();
        await this.loadAccountsForSelectedView();
        this.updatedSelectedAccountListIcon(this.viewsAndLists.find(viewOrList => viewOrList.id === this.selectedView));
        this.hideSpinner();
    }

    async getAccounts(viewId){
        let data = [];
        if (this._viewIsACyclePlan(viewId)) {
            data = await getCyclePlanTargets({cyclePlanId: viewId});
        } else if (viewId){
            const selectedViewDefn = await this.getViewDefinition(viewId);
            selectedViewDefn.columns = SchedulerViewDefnConfig.schedulerViewDefnColumns(this.calendarObjectInfos?.TSF_vod__c, this.calendarObjectInfos?.Address_vod__c, this.isChildAccountView(viewId, this.viewsAndLists));
            selectedViewDefn.baseQuery = '';
            selectedViewDefn.addresses = 'MINE';
            let userTerritories = await getUserTerritories();
            userTerritories = userTerritories.map(territory => ({ id: territory.id, name: territory.name }));
            const defaultTerritory = userTerritories[0];
            if (selectedViewDefn.criteria?.find((criteria) => criteria.field?.objectName === 'ChildAccount_TSF_vod__c')) {
                data = await this.accountDataService.getViewData(selectedViewDefn, userTerritories, [], null, defaultTerritory);
            } else {
                data = await this.accountDataService.getViewData(selectedViewDefn, userTerritories.length === 1 ? userTerritories : [defaultTerritory], [], defaultTerritory, defaultTerritory);
            }
        }
        return data;
    }

    _viewIsACyclePlan(viewId) {
        return this.viewsAndLists.find(view => view.id === viewId)?.type === 'CYCLE_PLAN';
    }

    setRecTypeIconUrls(accountsList, isChildAccountView){
        accountsList.forEach(account => { 
            account.veevaIconUrl = this.getVeevaIconUrl(SchedulerAccountsManager._getAccountRecordType(account, isChildAccountView), SchedulerAccountsManager._isPersonAccount(account, isChildAccountView));
        });
    }

    getVeevaIconUrl(recordType, isPersonAccount){
        let veevaIconUrl = this.recordTypeIconMap[recordType];
        if (!veevaIconUrl) {
            veevaIconUrl = isPersonAccount ? this.recordTypeIconMap.defaultPersonAccount : this.recordTypeIconMap.defaultNonPersonAccount;
        }
        return veevaIconUrl;
    }

    processAccountsDataForGridStore(rawAccountsList, isChildAccountView) {
        return rawAccountsList.map(account => ({
             ...account, 
             accountId: SchedulerAccountsManager._getAccountId(account, isChildAccountView),
             name: SchedulerAccountsManager._getAccountName(account, isChildAccountView),
             fromSchedulerPane: true, 
             resourceId: '', 
            }));
    }

    sortAccounts(accountsList, isChildAccountView){
        if (isChildAccountView) {
            accountsList.sort((a, b) => a['Child_Account_vod__c-Parent_Child_Furigana_vod__c']?.localeCompare(b['Child_Account_vod__c-Parent_Child_Furigana_vod__c'])
                || a['Child_Account_vod__c-Parent_Child_Name_vod__c']?.localeCompare(b['Child_Account_vod__c-Parent_Child_Name_vod__c']));
        } else {
            accountsList.sort((a, b) => {
                const formattedNameA = a['Account-Formatted_Name_vod__c'] || a.Cycle_Plan_Account_vod__r?.Formatted_Name_vod__c;
                const formattedNameB = b['Account-Formatted_Name_vod__c'] || b.Cycle_Plan_Account_vod__r?.Formatted_Name_vod__c;

                if (formattedNameA == null && formattedNameB == null) {
                    return 0;
                }
                if (formattedNameA != null && formattedNameB == null) {
                    return 1;                    
                }
                if (formattedNameA == null && formattedNameB != null) {
                    return -1;
                }
                return formattedNameA.localeCompare(formattedNameB);
            });
        }
    }

    async getViewDefinition(selectedViewId){
        let viewDefinition;
        if (this.defaultViews.includes(selectedViewId)){
            viewDefinition = SchedulerViewDefnConfig.getDefaultViewDefn(this.getDefaultViewType(selectedViewId), this.isChildAccountView(selectedViewId, this.viewsAndLists));
        } else {
            viewDefinition = await getViewDefinition({ viewId: selectedViewId });
        }
        return viewDefinition;
    }

    async loadAccountsForSelectedView(){
        let accountsList = [];
        const isChildAccountView = this.isChildAccountView(this.selectedView, this.viewsAndLists);
        try {
            const rawAccountsList = await this.getAccounts(this.selectedView);
            if (rawAccountsList?.length === 0) {
                this.schedulerGrid.emptyText = this.translatedLabels.noAccountsMsg;
            } else {
                // set veevaIconUrls for each record
                this.setRecTypeIconUrls(rawAccountsList, isChildAccountView);
            }
            accountsList = this.processAccountsDataForGridStore(rawAccountsList, isChildAccountView);

        } catch(e) {
            accountsList = [];
            this.schedulerGrid.emptyText = this.translatedLabels.systemErrMsg;
        }
        const numAccounts = accountsList.length;
        // update record count in scheduler pane header
        if (this.schedulerGrid.tbar?.items?.length > 0){
            this.schedulerPaneHeader.title = `${this.translatedLabels.accountsNumParenLabel.replace('{0}', Intl.NumberFormat(LOCALE).format(numAccounts))}`;
            this._updateCyclePlanTargetRsTotal(accountsList);
        }
        this.sortAccounts(accountsList, isChildAccountView);
        this.schedulerGrid.store.removeAll();
        this.schedulerGrid.store.data = accountsList;
    }

    _updateCyclePlanTargetRsTotal(accountsList) {
        const rsTotalHeader = this.schedulerPaneHeader.nextSibling;
        const rsTotalHeaderStyling = rsTotalHeader.element?.style;

        if (this._viewIsACyclePlan(this.selectedView) && !this.settings.enableAdvancedCyclePlanMetrics) {
            rsTotalHeaderStyling.display = "block";
            
            const rsTotal = accountsList.reduce((curRsTotal, target) => curRsTotal + (target.Remaining_Schedule_vod__c || 0), 0);
            rsTotalHeader.html = this.translatedLabels.totalRsLabel.replace('{0}', Intl.NumberFormat(LOCALE).format(rsTotal));
        } else {
            rsTotalHeaderStyling.display = "none";
        }
    }

    createAccountDetailsDiv(record) {
        const isChildAccountView = record.data['Child_Account_vod__c-Id'];
        const schedulerPaneAccountDetails = document.createElement('div')
        schedulerPaneAccountDetails.classList.add('scheduler-pane-account-details');
        const accountName = document.createElement('strong')
        const cellTitleText = isChildAccountView ? 
            record.data['Child_Account_vod__c-Parent_Child_Name_vod__c'] || '' : 
            record.data['Account-Formatted_Name_vod__c'] || record.data.Cycle_Plan_Account_vod__r?.Formatted_Name_vod__c || '';

        accountName.appendChild(document.createTextNode(cellTitleText));
        const accountNameContainer = document.createElement('div')
        accountNameContainer.appendChild(accountName)

        schedulerPaneAccountDetails.appendChild(accountNameContainer)

        if (isChildAccountView) {
            const accountIdentifier = document.createElement('div');
            accountIdentifier.appendChild(document.createTextNode(record.data['Child_Account_vod__c-Child_Account_Identifier_vod__c'] || ''));

            schedulerPaneAccountDetails.appendChild(accountIdentifier);
        } else if (record.data.Cycle_Plan_Account_vod__r) {
            this.appendCyclePlanTargetDetails(record, schedulerPaneAccountDetails)
        } else {
            this.appendNonChildAccountDetails(record, schedulerPaneAccountDetails);
        }
        return schedulerPaneAccountDetails;
    }

    appendNonChildAccountDetails(record, schedulerPaneAccountDetails) {
        const parentAccount = document.createElement('div')
        parentAccount.appendChild(document.createTextNode(this.settings.enableAccountParentDisplay && !this.isBusinessProfessionalAccount(record) ? this.getParentAccountToDisplay(record) : ''))
        const accountIdentifier = document.createElement('div');
        accountIdentifier.appendChild(document.createTextNode(record.data[`Account-${VeevaMedicalIdentifierHelper.getIdentifierApiName()}`] || ''));

        const addressLine1 = document.createElement('div');
        addressLine1.appendChild(document.createTextNode(record.data['Address_vod__c-Name'] || ''))
        const addressLine2 = document.createElement('div')
        addressLine2.appendChild(document.createTextNode(record.data['Address_vod__c-Address_line_2_vod__c'] || ''));

        const cityState = document.createElement('div');
        if (record.data['Address_vod__c-City_vod__c'] || record.data['Address_vod__c-State_vod__c'] || record.data['Address_vod__c-Zip_vod__c']) {
            cityState.appendChild(document.createTextNode(`${record.data['Address_vod__c-City_vod__c'] || ''} ${record.data['Address_vod__c-State_vod__c'] || ''} ${record.data['Address_vod__c-Zip_vod__c'] || ''}`))
        }
        
        schedulerPaneAccountDetails.appendChild(parentAccount);
        schedulerPaneAccountDetails.appendChild(accountIdentifier);
        schedulerPaneAccountDetails.appendChild(addressLine1);
        schedulerPaneAccountDetails.appendChild(addressLine2);
        schedulerPaneAccountDetails.appendChild(cityState);
    }

    appendCyclePlanTargetDetails(record, schedulerPaneAccountDetails) {
        const targetIdentifier = document.createElement('div');
        targetIdentifier.className = "cycle-plan-target-identifier";
        const identifier = record.data.Cycle_Plan_Account_vod__r?.[VeevaMedicalIdentifierHelper.getIdentifierApiName()];
        targetIdentifier.appendChild(document.createTextNode(identifier ? `#${identifier}` : ''));
        schedulerPaneAccountDetails.appendChild(targetIdentifier);

        const metricsContainer = document.createElement('div');
        metricsContainer.className = "cycle-plan-target-metrics";
        schedulerPaneAccountDetails.appendChild(metricsContainer);

        this.appendFormattedTargetMetrics(record, metricsContainer);
    }

    appendFormattedTargetMetrics(record, metricsContainer) {
        const { data } = record;

        if (this.settings.enableAdvancedCyclePlanMetrics) {
            this._appendAdvancedCyclePlanTargetMetrics(data, metricsContainer);
        }
        const remainingScheduled = this._formatTargetMetric(this.translatedLabels.remainingScheduledAbbreviationLabel, data.Remaining_Schedule_vod__c);
        metricsContainer.appendChild(document.createTextNode(remainingScheduled));
    }

    _appendAdvancedCyclePlanTargetMetrics(data, metricsContainer) {
        // build up an element with contents formatted as "A: 1 / P: 2 / ..." where the '/' delimiters will be styled uniquely
        const actual = this._formatTargetMetric(this.translatedLabels.actualAbbreviationLabel, data.Actual_Calls_vod__c);
        const planned = this._formatTargetMetric(this.translatedLabels.plannedAbbreviationLabel, data.Planned_Calls_vod__c);
        const scheduled = this._formatTargetMetric(this.translatedLabels.scheduledAbbreviationLabel, data.Scheduled_Calls_vod__c);
        const attainment = this._formatTargetMetric(SchedulerAccountsManager.CYCLE_PLAN_ATTAINMENT_LABEL, data.Attainment_vod__c);
        const remaining = this._formatTargetMetric(this.translatedLabels.remainingAbbreviationLabel, data.Remaining_vod__c);
        
        metricsContainer.appendChild(document.createTextNode(actual));
        metricsContainer.appendChild(this._getMetricDelimiter());

        metricsContainer.appendChild(document.createTextNode(planned));
        metricsContainer.appendChild(this._getMetricDelimiter());

        metricsContainer.appendChild(document.createTextNode(scheduled));
        metricsContainer.appendChild(this._getMetricDelimiter());

        metricsContainer.appendChild(document.createTextNode(this.settings.enableCyclePlansRemaining ? remaining : attainment));
        metricsContainer.appendChild(this._getMetricDelimiter());
    }

    _getMetricDelimiter() {
        const delimiter = document.createElement('span');
        delimiter.className = "cycle-plan-target-metric-delimiter";
        delimiter.appendChild(document.createTextNode(` ${SchedulerAccountsManager.CYCLE_PLAN_TARGET_METRICS_DELIMITER} `));
        
        return delimiter;
    }

    _formatTargetMetric(label, value) {
        return `${label}: ${value || 0}`;
    }

    getParentAccountToDisplay(record){
        // If CreatedDate is missing, user does not have access to the parent account
        const tsfPreferredAccount = record.data['Account-IsPersonAccount'] && record.data['TSF_vod__c-Preferred_Account_vod__r-CreatedDate'] ? record.data['TSF_vod__c-Preferred_Account_vod__r-Name'] : '';
        const primaryParentAccount = record.data['Account-Primary_Parent_vod__r-CreatedDate'] ? record.data['Account-Primary_Parent_vod__r-Name'] : '';
        return tsfPreferredAccount || primaryParentAccount || '';
    }

    isBusinessProfessionalAccount(record){
        return record.data['Account-RecordType-DeveloperName'] === 'Business_Professional_vod';
    }

    isChildAccountView(viewId, viewsAndLists) {
        return this.settings.enableChildAccount && viewsAndLists.find(viewOrList => viewOrList.id === viewId)?.type === 'LOCATION_CHILD_ACCOUNT_VIEW';
    }

    getDefaultViewType(viewId){
        return this.viewTypeMap.get(viewId);
    }

    createViewTypeMap(){
        this.viewTypeMap = new Map([
            [this.translatedLabels.allAccountsLabel, 'ALL'],
            [this.translatedLabels.allPersonAccountsLabel, 'PERSON'],
            [this.translatedLabels.allBusinessAccountsLabel, 'BUSINESS'],
            [this.translatedLabels.allChildAccountsLabel, 'CHILD'],
        ]);
    }

    getDropdownHeaderName(groupName) {
        let headerName;
        if (groupName === 'ACCOUNT_LIST') { 
            headerName = this.translatedLabels.listsLabel;
        } else if (groupName === 'VIEW') {
            headerName = this.translatedLabels.accountViewLabel;
        } else if (groupName === 'CYCLE_PLAN') {
            headerName = this.translatedLabels.cyclePlansLabel;
        } else {
            headerName = this.translatedLabels.childAccountViewLabel;
        }
        return headerName;
    }

    get schedulerPaneHeader() {
        return this.schedulerGrid.tbar.items[0].items[0].items[0].items[1].items[0];
    }

    static _getAccountRecordType(account, isChildAccountView) {
        if (isChildAccountView) {
            return account['Child_Account_vod__r-Account-RecordType-DeveloperName'];
        }
        return account['Account-RecordType-DeveloperName'] || account.Cycle_Plan_Account_vod__r?.RecordType?.DeveloperName;
    }

    static _isPersonAccount(account, isChildAccountView) {
        if (isChildAccountView) {
            return true;
        }
        return account['Account-IsPersonAccount'] || account.Cycle_Plan_Account_vod__r?.IsPersonAccount;
    }

    static _getAccountId(account, isChildAccountView) {
        if (isChildAccountView) {
            return `${account['Child_Account_vod__c-Child_Account_vod__c']}:${account['Child_Account_vod__c-Parent_Account_vod__c']}:${account['Child_Account_vod__c-Id']}`;
        }
        return account['Account-Id'] || account.Cycle_Plan_Account_vod__r?.Id;
    }

    static _getAccountName(account, isChildAccountView) {
        if (isChildAccountView) {
            return account['Child_Account_vod__c-Parent_Child_Name_vod__c'];
        }
        return account['Account-Formatted_Name_vod__c'] || account.Cycle_Plan_Account_vod__r?.Formatted_Name_vod__c;
    }
}