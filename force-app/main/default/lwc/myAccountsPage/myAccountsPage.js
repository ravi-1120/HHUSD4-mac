import { track, wire } from 'lwc';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { MessageContext, publish } from 'lightning/messageService';
import { loadScript } from 'lightning/platformResourceLoader';

import LOCALE from '@salesforce/i18n/locale';
import TIME_ZONE from '@salesforce/i18n/timeZone';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import MESSAGE_OBJECT from '@salesforce/schema/Message_vod__c';
import PREFERENCES_OBJECT from '@salesforce/schema/Preferences_vod__c';
import VIEW_OBJECT from '@salesforce/schema/View_vod__c';

import getCustomSettings from '@salesforce/apex/VeevaCustomSettingsService.getCustomSettings';
import getVeevaSettings from '@salesforce/apex/VeevaCustomSettingsService.getVeevaSettings';

import componentRefreshMessage from '@salesforce/messageChannel/Component_Refresh_Message__c';

import SHEETJS_RESOURCE_URL from '@salesforce/resourceUrl/veeva_sheetjs';

import VeevaAccountNavigationMixin from 'c/veevaAccountNavigationMixin';
import VeevaMainPage from 'c/veevaMainPage';
import VeevaObjectInfo from 'c/veevaObjectInfo';
import VeevaToastEvent from 'c/veevaToastEvent';
import { SERVICES, getService } from 'c/veevaServiceFactory';

import MyAccountsDataService from 'c/myAccountsDataService';
import { getPageController } from 'c/veevaPageControllerFactory';
import MyAccountsButtonControllerFactory from 'c/myAccountsButtonControllerFactory';
import MyAccountsGrid from 'c/myAccountsGrid';
import MyAccountsScheduleCallModal from 'c/myAccountsScheduleCallModal';

import MyAccountsExporter from './myAccountsExporter';
import MyAccountsFormatterFactory from './myAccountsFormatterFactory';

const REQUIRED_OBJECTS_FOR_PAGE = [
  ACCOUNT_OBJECT.objectApiName,
  MESSAGE_OBJECT.objectApiName,
  PREFERENCES_OBJECT.objectApiName,
  VIEW_OBJECT.objectApiName,
];
const OBJECT_API_NAMES = new Set([...REQUIRED_OBJECTS_FOR_PAGE, ...MyAccountsButtonControllerFactory.getObjectApiNames()]);

const MAX_ACCOUNTS_FOR_LIST = 10000;

export default class MyAccountsPage extends VeevaAccountNavigationMixin(VeevaMainPage) {
  objectApiNames = [...OBJECT_API_NAMES];

  @wire(MessageContext)
  messageContext;

  myAccountsHeaderSubtitle = '';
  labels = {};
  objectInfos = {};
  settings = {};
  navItems = {};
  @track confirmationModalConfig = {
    show: false,
    size: 'tiny',
    title: null,
    messages: [],
    confirmLabel: null,
  };

  loadingMetadata = true;
  loadingData = false;
  loadingInternalResponse = false;
  columns;
  data;
  numberOfAccounts = null;
  sortedColumnName = '';
  sortDirection = '';
  selectedAccounts = [];
  disableClearFilters = true;
  hideExportMenu = true;
  view = {};

  _hasLoadedSheetJS = false;
  _sheetJs;

  _numberOfLists = 0;
  _accountDataService = new MyAccountsDataService(getService(SERVICES.DATA));
  _myAccountsExporter = new MyAccountsExporter();
  pageCtrl = getPageController('pageCtrl');
  // override page name for metric reporting
  componentName = 'MyAccounts';

  get loading() {
    return this.loadingMetadata || this.loadingData || this.loadingInternalResponse;
  }

  get hasObjectInfos() {
    return Object.keys(this.objectInfos).length > 0;
  }

  get hasLoadedControlsInfo() {
    return this.hasObjectInfos && Object.keys(this.labels).length > 0 && Object.keys(this.settings).length > 0;
  }

  get hasLists() {
    return this._numberOfLists > 0;
  }

  get doesNotHavePermission() {
    return this.hasObjectInfos && !this.doesHavePermission;
  }

  get doesHavePermission() {
    return this.hasObjectInfos && REQUIRED_OBJECTS_FOR_PAGE.every(objectApiName => objectApiName in this.objectInfos);
  }

  get grid() {
    return this.template.querySelector('c-my-accounts-grid');
  }

  get header() {
    return this.template.querySelector('c-my-accounts-header');
  }

  get confirmationModal() {
    return this.template.querySelector('c-veeva-confirmation-modal');
  }

  get isPageReady() {
    return !this.loadingMetadata && !this.loadingData;
  }

  @wire(getObjectInfos, { objectApiNames: '$objectApiNames' })
  wiredObjectInfos({ data }) {
    if (data) {
      const objectInfos = data.results;
      // Only store valid objectInfos
      this.objectInfos = objectInfos
        ?.filter(({ result }) => result.apiName)
        .map(({ result }) => new VeevaObjectInfo(result))
        .reduce((map, objectInfo) => {
          map[objectInfo.apiName] = objectInfo;
          return map;
        }, {});
      const accountObjectInfo = objectInfos.map(({ result }) => result).find(objectInfo => objectInfo.apiName === ACCOUNT_OBJECT.objectApiName);
      // Use labelPlural if available otherwise default to label
      this.myAccountsHeaderSubtitle = accountObjectInfo?.labelPlural || accountObjectInfo?.label;
    }
  }

  async connectedCallback() {
    super.connectedCallback();
    await this.loadNavItems();
    await this.loadVeevaMessages();
    await this.loadCustomSettings();
    this.loadingMetadata = false;
  }

  disconnectedCallback() {
    MyAccountsGrid.DATA = [];
  }

  async loadNavItems() {
    const navItems = MyAccountsButtonControllerFactory.getNavItems().join(',');
    const userInterfaceSvc = getService(SERVICES.UI_API);
    this.navItems = await userInterfaceSvc.performRequest('navItems', `/ui-api/nav-items?formFactor=large&navItemNames=${navItems}`);
  }

  async loadVeevaMessages() {
    const messageRequest = MyAccountsButtonControllerFactory.getMessageRequest();
    this.labels = await messageRequest
      .addRequest('TERRITORY', 'MyAccounts', 'Territory', 'territory')
      .addRequest('TOO_MANY_TERRITORIES', 'MyAccounts', 'The choice of displaying accounts from All territories may have resulted in encountering a Salesforce limitation.  Please refine view by selecting a specific territory.', 'tooManyTerritories')
      .addRequest('TOO_MANY_ACCOUNTS','MyAccounts','Too many Accounts. Please select another Territory.','tooManyAccounts')
      .addRequest('ALL_ACCOUNTS', 'MyAccounts', 'All Accounts', 'allAccounts')
      .addRequest('PARENT', 'Common', 'Parent', 'parentLabel')
      .addRequest('CHILD', 'Common', 'Child', 'childLabel')
      .addRequest('ALL_LOCATIONS', 'Common', 'All Locations', 'allLocations')
      .addRequest('ACCOUNT_VIEW', 'Common', 'Account View', 'accountViewLabel')
      .addRequest('CHILD_ACCOUNT_VIEW', 'Common', 'Child Account View', 'childAccountViewLabel')
      .addRequest('LISTS', 'Common', 'Lists', 'accountListsLabel')
      .addRequest('OK', 'Common', 'Okay', 'okayLabel')
      .addRequest('CANCEL', 'Common', 'Cancel', 'cancelLabel')
      .addRequest('CONFIRM_DELETE', 'Common', 'Are you sure?', 'confirmDeleteMessage')
      .addRequest('LIST_CREATED', 'Common', 'List created.', 'listCreatedLabel')
      .addRequest('LIST_UPDATED', 'Common', 'List updated.', 'listUpdatedLabel')
      .addRequest('LIST_DELETED', 'Common', 'List deleted.', 'listDeletedLabel')
      .addRequest('VIEW_DELETED', 'Common', 'View deleted.', 'viewDeletedLabel')
      .addRequest('DELETE', 'Common', 'Delete', 'deleteLabel')
      .addRequest('NO_ACCESS', 'Common', 'No Access', 'noAccessLabel')
      .addRequest('ADD_TO_LIST', 'Common', 'Add to List', 'addToListLabel')
      .addRequest('EDIT_LIST', 'Common', 'Edit List', 'editListLabel')
      .addRequest('CREATE_NEW_LIST', 'Common', 'Create New List', 'createNewListLabel')

      .addRequest('ACTION_ERROR', 'Common', 'The requested action cannot be completed. Please try again or contact your administrator.', 'actionErrorMessage')

      .addRequest(
        'COLOR_ICON_NAME',
        'Common',
        'Red Orange Peach Yellow Green Teal Olive Blue Purple Maroon Steel DarkSteel Gray DarkGray Black DarkRed DarkOrange DarkPeach DarkYellow DarkGreen DarkTeal DarkOlive FavoriteBlue DarkPurple DarkMaroon',
        'colorIconNames'
      )

      .addRequest('CLEAR_FILTERS', 'Common', 'Clear Filters', 'clearFiltersBtn')
      .addRequest('EXPORT', 'MSOfficeExport', 'Export', 'exportBtn')
      .addRequest('SCHEDULE_CALL', 'MyAccounts', 'Schedule Call', 'scheduleCallLabel')
      .addRequest('ACCOUNT_ACTION_LIMIT', 'MyAccounts', 'The requested action cannot be performed with more than {0} accounts selected.', 'accountLimitError')
      .addRequest('CALL', 'MyAccounts', 'Call', 'callLabel')
      .addRequest('CONFIRM_CLICK_TO_DIAL', 'MyAccounts', 'If the phone link is disabled, sign in into your dialer.', 'confirmClickToDialLabel')
      .addRequest('ACTION_ERROR', 'Common', 'The requested action cannot be completed. Please try again or contact your administrator.', 'actionError')
      .addRequest('SCHEDULE', 'TABLET', 'Schedule', 'scheduleBtn')
      .addRequest('SCHEDULE_START_DATE', 'Callplan', 'Date', 'startDateLabel')
      .addRequest('CALLS_PER_DAY', 'Callplan', 'Calls per Day', 'callsPerDayLabel')
      .addRequest('ITEMS_IN_LIST', 'Common', '{0} Items', 'items')
      .addRequest('MAX_ACCOUNT_LIMIT_REACHED', 'Common', '{0} Items (of {1} total) Displayed', 'limitedItems')
      .addRequest('SELECTED_ROWS', 'Common', '{0} Selected', 'selected')
      .addRequest('SORTED_BY', 'Common', 'Sorted by {0}', 'sortedBy')
      .sendRequest();
  }

  async loadCustomSettings() {
    const buttonControlsCustomSettings = MyAccountsButtonControllerFactory.getCustomSettings();

    const veevaSettings = await getVeevaSettings({ settingFieldNames: ['DISABLE_ACCOUNT_DOWNLOAD_CSV_EXCEL_vod__c'] });
    this.hideExportMenu = veevaSettings.DISABLE_ACCOUNT_DOWNLOAD_CSV_EXCEL_vod__c;

    const customSettingsMap = await Promise.all(
      buttonControlsCustomSettings.map(setting => getCustomSettings(setting).then(customSetting => [setting.customSettingObjectName, customSetting]))
    );
    this.settings = customSettingsMap;
  }

  async handleViewOrTerritoryChange(event) {
    this.loadingData = true;
    const viewIdBeforeUpdate = this.view.id;
    const { view, territories, groupIds, selectedTerritory, defaultTerritory } = event.detail;
    this.view = view;
    // Always clear selected accounts when view/territory changes
    this.selectedAccounts = [];
    // clear data prior to request this way no data is visible as the user is switching views
    this.data = [];
    // We need to clear this static array when we clear the data when the view changes as well.
    // MyAccountsGrid.DATA is set to bypass the Proxy object pass via api properties
    // The issues with Proxy objects is always present but much more noticeable when the data volume is above 10,000 records
    MyAccountsGrid.DATA = this.data;
    this.columns = view.columns;
    this.numberOfAccounts = null;
    if (!view.hasErrors) {
      try {
        this.data = await this._accountDataService.getViewData(view, territories, groupIds, selectedTerritory, defaultTerritory);
      } catch (e) {
        if (parseInt(e.message, 10) === 1) {
          this.dispatchEvent(VeevaToastEvent.error({ message: this.labels.tooManyTerritories }));
        } else if (parseInt(e.message, 10) === 2) {
            this.dispatchEvent(VeevaToastEvent.error({ message: this.labels.tooManyAccounts }));
        }
        this.data = [];
      }
    }
    this.numberOfAccounts = this.data?.length ?? 0;
    this.totalAccounts = this._accountDataService.totalMatchingRows ?? this.numberOfAccounts;
    MyAccountsGrid.DATA = this.data;
    if (viewIdBeforeUpdate !== view.id) {
      // We will sort by the first column after changing views
      this.grid.sort({ column: this.columns[0], ascending: true });
      // We will clear any grid filters when view changes
      this.grid.clearFilters();
    }
    this.loadingData = false;
  }

  handleViewCountChange(event) {
    const { lists } = event.detail;
    this._numberOfLists = lists;
  }

  handleAccountSelectionChange(event) {
    const { selected } = event.detail;
    // We will set a shallow copy so we do not need to deal with the Proxy that Lightning framework uses on CustomEvent values
    this.selectedAccounts = [...selected];
  }

  async handleRemoveAccounts(event) {
    this.loadingInternalResponse = true;
    const listItemsRemoved = await this.header.removeAccountListItems(event.detail.accountIds);
    if (listItemsRemoved) {
      this.grid.removeAccountsFromGrid(event.detail.rowIds);
    }
    const rowsRemoved = event.detail.rowIds?.length ?? 0;
    this.numberOfAccounts -= rowsRemoved;
    this.loadingInternalResponse = false;
  }

  async handleScheduleCall() {
    if(this.selectedAccounts.length < 200) {
      const scheduleCallResponse = await MyAccountsScheduleCallModal.open({
        size: 'small',
        labels: this.labels,
        accountIds: new Set(this.selectedAccounts.map(selectedAccount => this._getScheduleCallAccountId(selectedAccount))),
        preferencesId: this._preferencesId,
      });
      if (scheduleCallResponse?.created) {
        this.handleCallCreated();
      }
    } else {
      this.dispatchEvent(VeevaToastEvent.error({ message: this.labels.accountLimitError.replace('{0}', 200) }));
    }
  }

  _getScheduleCallAccountId(selectedAccount) {
    if (this.view.source === 'LOCATION') {
      return [
        selectedAccount['Child_Account_vod__r-Account-Id'],
        selectedAccount['Parent_Account_vod__r-Account-Id'],
        selectedAccount['Child_Account_vod__c-Id'],
      ].join(':');
    }
    return selectedAccount['Account-Id'];
  }

  handleCallCreated() {
    this.selectedAccounts = [];
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
          url: '/lightning/n/My_Schedule_vod',
        },
    });
    publish(this.messageContext, componentRefreshMessage, {type: 'refreshCalls'});
  }

  handlePreferences(event) {
    this._preferencesId = event.detail.preferencesId;
  }

  handleNewAccountButton() {
    this[VeevaAccountNavigationMixin.NavigateToNewAccount]();
  }

  async handleNewOrderButton(event) {
    this._navigateToStandardWebPage(event);
  }

  handleSendEmailButton(event) {
    this._navigateToStandardWebPage(event);
  }

  _navigateToStandardWebPage(event) {
    this[NavigationMixin.Navigate]({
      type: 'standard__webPage',
      attributes: {
        url: event.detail.url,
      },
    });
  }

  async handleDeleteView() {
    const result = await this._openConfirmationModal({
      message: this.labels.confirmDeleteMessage,
      title: this.labels.deleteLabel,
      confirmLabel: this.labels.deleteLabel,
    });
    if (result) {
      this.loadingInternalResponse = true;
      await this.header.deleteCurrentView();
      this.loadingInternalResponse = false;
    }
  }

  async _openConfirmationModal({ message, title, confirmLabel }) {
    return new Promise(resolve => {
      // We will make handleConfirm a lambda so we retain the "this" context
      const handleConfirm = () => {
        this.confirmationModal.removeEventListener(handleConfirm);
        this.confirmationModalConfig.show = false;
        resolve(true);
      };

      // We will make handleCancel a lambda so we retain the "this" context
      const handleCancel = () => {
        this.confirmationModal.removeEventListener(handleCancel);
        this.confirmationModalConfig.show = false;
        resolve(false);
      };

      this.confirmationModal.addEventListener('confirm', handleConfirm);
      this.confirmationModal.addEventListener('cancel', handleCancel);
      this.confirmationModalConfig.show = true;
      this.confirmationModalConfig.messages = [message];
      this.confirmationModalConfig.title = title;
      this.confirmationModalConfig.confirmLabel = confirmLabel;
    });
  }

  handleAddToList(event) {
    const accountIds = [...event.detail.accountIds];
    if (accountIds.length <= MAX_ACCOUNTS_FOR_LIST) {
      this.header.addToList(accountIds);
    } else {
      this.dispatchEvent(VeevaToastEvent.error({ message: this.labels.accountLimitError.replace('{0}', MAX_ACCOUNTS_FOR_LIST) }));
    }
  }

  handleCreateNewList(event) {
    const accountIds = [...event.detail.accountIds];
    if (accountIds.length <= MAX_ACCOUNTS_FOR_LIST) {
      this.header.createNewList(accountIds);
    } else {
      this.dispatchEvent(VeevaToastEvent.error({ message: this.labels.accountLimitError.replace('{0}', MAX_ACCOUNTS_FOR_LIST) }));
    }
  }

  handleEditList() {
    this.header.editList();
  }

  handleCreateNewView(event) {
    this._navigateToStandardWebPage(event);
  }

  handleEditView(event) {
    if (this.view.id) {
      const urlContainsQueryParams = event.detail.url.includes('?');
      const urlEndsWithQuestionButNoQueryParams = event.detail.url.endsWith('?');
      if (urlContainsQueryParams && !urlEndsWithQuestionButNoQueryParams) {
        event.detail.url += `&vwid=${this.view.id}`;
      } else if (urlEndsWithQuestionButNoQueryParams) {
        event.detail.url += `vwid=${this.view.id}`;
      } else {
        event.detail.url += `?vwid=${this.view.id}`;
      }
    }
    this._navigateToStandardWebPage(event);
  }

  handleFiltersChange(event) {
    const { numFilters, numAccounts } = event.detail;
    this.disableClearFilters = !numFilters || numFilters === 0;
    if (numAccounts != null) {
      this.numberOfAccounts = numAccounts;
    }
  }

  handleSort(event) {
    this.sortedColumnName = event.detail.sortLabel;
    this.sortDirection = event.detail.ascending ? 'utility:up' : 'utility:down';
  }

  handleClearFilters() {
    this.grid.clearFilters();
  }

  async handleExport(event) {
    try {
      const exportType = event.detail.value;
      const filename = this._getExportFilename();
      const columns = this.grid.getColumns();
      const columnHeaderLabel = column => [column.prefix, column.text].filter(value => value).join(' ');
      const columnHeaders = columns.map(columnHeaderLabel);
      const isSorted = true;
      const shouldNotApplyFilters = false;
      const data = [...this.grid.getRows(isSorted, shouldNotApplyFilters)].map(row =>
        columns.map(column => {
          const value = row[column.field];
          const formatter = MyAccountsFormatterFactory.create(column, exportType);
          return formatter.format(value, row);
        })
      );
      if (exportType === 'csv') {
        await this._myAccountsExporter.exportToCSV(filename, columnHeaders, data);
      } else if (exportType === 'excel') {
        const sheetJS = await this._loadSheetJS();
        await this._myAccountsExporter.exportToExcel(sheetJS, filename, columnHeaders, data);
      }
    } catch (e) {
      this.dispatchEvent(VeevaToastEvent.error({ message: this.labels.actionErrorMessage }));
    }
  }

  _getExportFilename() {
    const formatter = Intl.DateTimeFormat(LOCALE.replace('_', '-'), {
      dateStyle: 'medium',
      timeZone: TIME_ZONE,
    });
    // eslint-disable-next-line no-useless-escape
    const viewNameWithSpecialCharactersReplaced =  this.view.name.replace(/[/\\\*\?\[\]\-\'\:\"\|\<\>\~]/g, '_');
    return `${viewNameWithSpecialCharactersReplaced} - ${formatter.format(new Date())}`;
  }


  async _loadSheetJS() {
    if (this._hasLoadedSheetJS) {
      return this._sheetJs;
    }
    await loadScript(this, SHEETJS_RESOURCE_URL);

    // SheetJS sets VEEVA_XLSX on the window object
    // we've modified the script to set VEEVA_XLSX instead of XLSX to avoid collisions with customers who use SheetJS as well
    // eslint-disable-next-line no-undef
    this._sheetJs = VEEVA_XLSX;
    this._hasLoadedSheetJS = true;
    return this._sheetJs;
  }
}