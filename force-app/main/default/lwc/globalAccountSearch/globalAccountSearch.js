import { wire, track } from 'lwc';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import searchAccounts from '@salesforce/apex/VeevaGlobalAccountSearchController.searchAccounts';
import getUserFilterFields from '@salesforce/apex/VeevaGlobalAccountSearchController.getUserFilterFields';
import VeevaToastEvent from 'c/veevaToastEvent';
import VeevaAccountRecordTypeIconConfig from 'c/veevaAccountRecordTypeIconConfig';
import getCustomSettingsForNewButtonConfig from '@salesforce/apex/VeevaGlobalAccountSearchController.getCustomSettingsForNewButtonConfig';
import GasCreateAccountAccess from 'c/gasCreateAccountAccess';
import GasSearchResultsFormatter from 'c/gasSearchResultsFormatter';
import accountRecordTypeIcons from '@salesforce/resourceUrl/account_record_type_icons';
import VeevaMainPage from 'c/veevaMainPage';
import VeevaObjectInfo from 'c/veevaObjectInfo';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ADDRESS_OBJECT from '@salesforce/schema/Address_vod__c';
import DATA_CHANGE_REQUEST_OBJECT from '@salesforce/schema/Data_Change_Request_vod__c';
import DATA_CHANGE_REQUEST_LINE_OBJECT from '@salesforce/schema/Data_Change_Request_Line_vod__c';
import DCR_FIELD_TYPE_OBJECT from '@salesforce/schema/DCR_Field_Type_vod__c';

const MAX_LIGHTNING_LAYOUT_ITEM_SIZE = 12;

export default class GlobalAccountSearch extends VeevaMainPage {
  pageName = 'Global Account Search';
  accountObjName;
  accountObjectInfo;
  accountPicklistValues;
  addressObjectInfo;
  resultCount = 0;
  enableAddToTerritory = false;
  showAddTerritory = false;
  loading;
  searchCalled = false;
  gasRecTypeIconConfig;
  customRecTypesIconSetting;
  errorMessage = 'An error occurred when performing the search';
  noSearchResultsMessage = 'No matches found.';
  disableNewAccount = true;
  showUserFilters = false;
  accountSearchString;
  addressSearchString;
  sortColumn;
  sortDirection;
  userFilters;
  userFiltersSize = 3;
  userFilterFields = null;
  minColumnWidth = 100;
  canCreateAccount = false;
  cannotCreateAccounts = false;
  hasDcrMode = false;
  isNAWEnabled = false;
  title = 'Global Account Search';

  objectNames = [ACCOUNT_OBJECT, ADDRESS_OBJECT, DATA_CHANGE_REQUEST_OBJECT, DATA_CHANGE_REQUEST_LINE_OBJECT, DCR_FIELD_TYPE_OBJECT];

  @track searchResultColumns = [];
  @track formattedSearchResults = [];
  @track accountTypeOptions = [];
  @track objectInfos = {};
  selectedAccountIds = [];

  get gasNavigator() {
    return this.template.querySelector('c-gas-navigator');
  }

  get datatableSize() {
    return this.showUserFilters ? MAX_LIGHTNING_LAYOUT_ITEM_SIZE - this.userFiltersSize : MAX_LIGHTNING_LAYOUT_ITEM_SIZE;
  }

  get gasHeader() {
    return this.template.querySelector('c-gas-header');
  }

  get noSearchResults() {
    return !this.loading && this.formattedSearchResults?.length === 0;
  }

  get isReadyToShowUserFilters() {
    return this.objectInfos && Object.keys(this.objectInfos).length > 0 && this.userFilterFields != null;
  }

  get isPageReady() {
    // We considering the page as ready when the isReadyToShowUserFilters field is true,
    // this field is true when User Filter Fields have been loaded and when objectInfos have been loaded
    return this.isReadyToShowUserFilters;
  }

  async connectedCallback() {
    super.connectedCallback();
    await this.loadVeevaMessages();
    this.gasRecTypeIconConfig = new VeevaAccountRecordTypeIconConfig(this.customRecTypesIconSetting);
    this.userFilterFields = await getUserFilterFields();

    // Changing tab title if user is in console mode
    try {
      const isConsoleNavigation = await this.invokeWorkspaceAPI('isConsoleNavigation');
      if (isConsoleNavigation) {
        const focusedTab = await this.invokeWorkspaceAPI('getFocusedTabInfo');
        this.invokeWorkspaceAPI('setTabLabel', {
          tabId: focusedTab.tabId,
          label: this.title
        })
        this.invokeWorkspaceAPI('setTabIcon', {
          tabId: focusedTab.tabId,
          icon: 'standard:search',
          iconAlt: this.title
        })
      }
    } catch(error){
      // eslint-disable-next-line no-console
      console.error(error);
    }
  }

  @wire(getObjectInfos, { objectApiNames: '$objectNames' })
  async wiredObjectInfo({ error, data }) {
    if (data) {
      const objectInfos = data.results;
      const accountObjectInfo = new VeevaObjectInfo(objectInfos[0].result);
      const addressObjectInfo = new VeevaObjectInfo(objectInfos[1].result);
      this.accountObjName = accountObjectInfo.label;
      this.cannotCreateAccounts = !accountObjectInfo.createable;

      this.objectInfos[ACCOUNT_OBJECT.objectApiName] = accountObjectInfo;
      this.objectInfos[ADDRESS_OBJECT.objectApiName] = addressObjectInfo;

      this.canCreateAccount = accountObjectInfo.createable;
      const canCreateDCR = objectInfos[2].result?.createable;
      const canCreateDCRLine = objectInfos[3].result?.createable;
      const canQueryDCRFieldType = objectInfos[4].result?.queryable;
      this.setNewAccountBtnVisibility(this.canCreateAccount, canCreateDCR, canCreateDCRLine, canQueryDCRFieldType);
    } else if (error) {
      // eslint-disable-next-line no-console
      console.error(error);
      this.setError(error);
    }
  }

  async performSearch(sortInfo) {
    this.loading = true;
    this.searchCalled = true;
    try {
      const result = await searchAccounts({
        searchText: this.accountSearchString,
        locationSearchText: this.addressSearchString,
        accountType: this.accountTypeFilter,
        userFilters: this.userFilters,
        sortConditions: sortInfo,
      });
      const searchResultFormatter = new GasSearchResultsFormatter(this.objectInfos, this.gasRecTypeIconConfig, result.fields, result.records);
      this.setSearchResultHeaders(searchResultFormatter);
      this.formatSearchResults(searchResultFormatter);
    } catch (e) {
      this.setError(e);
      this.loading = false;
    }
    this.loading = false;
  }

  async handleSearchEvent(event) {
    event.stopPropagation();
    this.accountSearchString = event.detail.accountSearchText;
    this.addressSearchString = event.detail.addressSearchText;
    this.accountTypeFilter = event.detail.accountType;
    // Reset user filters when the user intentionally clicks "Search"
    // the only criteria applied when the user presses "Search" is
    // the Account Type, Account Search Text, and Address Search Text
    this.userFilters = [];
    // Reset sort in each new search
    const sortInfo = {};
    this.sortColumn = null;
    this.sortDirection = null;
    await this.performSearch(sortInfo);
    this.disableNewAccount = false;
  }

  setSearchResultHeaders(searchResultFormatter) {
    const colHeaders = searchResultFormatter.getColumns();
    // We need to format the Account.Name since the click handler navigates using our gasNavigator
    colHeaders.forEach(column => {
      /* eslint no-param-reassign: ["error", { "props": true, "ignorePropertyModificationsFor": ["column"] }] */
      if (column.fieldName === 'Account.Formatted_Name_vod__c') {
        column.type = 'account-name-display';
        column.typeAttributes = {
          id: { fieldName: 'Account.Id' },
          isButton: { fieldName: 'insideTerritory' },
          recordTypeIconUrl: { fieldName: 'recTypeIconUrl' },
          recordTypeName: { fieldName: 'recTypeName' },
          clickHandler: this.navigateToAccountHandler.bind(this),
        };
        column.cellAttributes = {
          iconName: { fieldName: 'accountIcon' },
          iconPosition: 'left',
          iconAlternativeText: 'Account',
        };
      }
      // Check for previous column width adjustments
      if (this.searchResultColumns && this.searchResultColumns.length > 0) {
        column.initialWidth = this.getUserWidthSetting(column.fieldName);
      }
    });
    this.searchResultColumns = colHeaders;
  }

  formatSearchResults(searchResultFormatter) {
    const formattedResults = searchResultFormatter.getSearchResults();
    this.resultCount = formattedResults.length;
    this.formattedSearchResults = formattedResults;
  }

  createNewAccount() {
    if (!this.isNAWEnabled && this.canCreateAccount) {
      this.gasNavigator.navigateToNewAccountPage(this.hasDcrMode);
    } else {
      this.gasNavigator.navigateToNewAccountWizard(this.hasDcrMode);
    }
    this.disableNewAccount = true;
  }

  handleApplyUserFilters(event) {
    this.userFilters = event.detail.userFilters?.map(userFilter => ({
      objectApiName: userFilter.objectApiName,
      fieldApiName: userFilter.fieldApiName,
      selectedOptions: userFilter.selectedOptions.map(selectedOption => selectedOption.value),
    }));
    // If gasHeader was not populated correctly then we will not search at all
    if (this.gasHeader.checkValidity()) {
      // Reset sort each time user applies user filters
      const sortInfo = {};
      this.sortColumn = null;
      this.sortDirection = null;
      this.performSearch(sortInfo);
    }
  }

  toggleUserFilters() {
    this.showUserFilters = !this.showUserFilters;
  }

  async loadVeevaMessages() {
    const messageService = getService(SERVICES.MESSAGE);
    const messageRequest = messageService.createMessageRequest();

    const labels = await messageRequest
      .addRequest('GAS_SEARCH_ERROR', 'Global Account Search', this.errorMessage, 'errorMessage')
      .addRequest('ACCOUNT_RECORD_TYPE_ICON_MAP', 'Common', '', 'customRecTypesIconSetting')
      .addRequest('NO_MATCH_FOUND', 'Common', this.noSearchResultsMessage, 'noSearchResultsMessage')
      .addRequest('GAS_TITLE', 'Global Account Search', this.title, 'title')
      .sendRequest()

    this.errorMessage = labels.errorMessage;
    this.customRecTypesIconSetting = labels.customRecTypesIconSetting ?? '';
    this.noSearchResultsMessage = labels.noSearchResultsMessage;
    this.title = labels.title;
  }

  async setError(e) {
    const errMsg = e.body && e.body.message ? e.body.message : this.errorMessage;
    const error = { message: errMsg };
    this.dispatchEvent(VeevaToastEvent.error(error, 'sticky'));
  }

  navigateToAccountHandler(event) {
    const accountId = event.currentTarget.title;
    this.gasNavigator.navigateToViewAccount(accountId);
  }

  handleRowSelection(event) {
    const { selectedRows } = event.detail;
    const selectedAccountIdSet = new Set(this.selectedAccountIds);
    this.selectedAccountIds = selectedRows
      .filter(row => !row.insideTerritory)
      .filter(row => !selectedAccountIdSet.has(row['Account.Id']))
      .map(row => row['Account.Id']);

    this.enableAddToTerritory = this.selectedAccountIds.length > 0;
  }

  handleAccountAddedToTerritory(event) {
    const { accountId } = event.detail;
    const accountInSearchResults = this.formattedSearchResults?.find(searchResult => searchResult['Account.Id'] === accountId);
    if (accountInSearchResults) {
      accountInSearchResults.insideTerritory = true;
      accountInSearchResults.recTypeIconUrl = this.getRecordTypeIconUrl(accountInSearchResults);
      // Forces the lightning-datatable to recognize that the data has been updated
      this.formattedSearchResults = [...this.formattedSearchResults];
    }
  }

  getRecordTypeIconUrl(record) {
    return (
      accountRecordTypeIcons +
      this.gasRecTypeIconConfig.getIconUrlForRecordType(
        record['Account.RecordTypeId.DeveloperName'],
        record['Account.IsPersonAccount'],
        record.insideTerritory
      )
    );
  }

  addTerritory() {
    this.showAddTerritory = true;
    [this.accountIdToAddToTerritory] = this.selectedAccountIds;
  }

  closeAddTerritory() {
    this.showAddTerritory = false;
  }

  showToast(event) {
    const { message, variant } = event.detail;
    if (variant === 'success') {
      this.enableAddToTerritory = false;
      this.dispatchEvent(VeevaToastEvent.successMessage(message));
    } else {
      this.dispatchEvent(
        VeevaToastEvent.error({
          message,
        })
      );
    }
  }

  searchModified() {
    this.disableNewAccount = true;
  }

  performSort(event) {
    this.sortColumn = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    const sortInfo = { sortColumn: this.sortColumn, sortDirection: this.sortDirection };
    this.performSearch(sortInfo);
  }

  async setNewAccountBtnVisibility(canCreateAccount, canCreateDCR, canCreateDCRLine, canQueryDCRFieldType) {
    const customSettingValues = await getCustomSettingsForNewButtonConfig();
    this.hasDcrMode = GasCreateAccountAccess.NON_DISABLED_DCR_MODES.includes(customSettingValues.dcrMode);
    this.isNAWEnabled = customSettingValues.isNAWEnabled;
    this.cannotCreateAccounts = GasCreateAccountAccess.isAccountNotCreateable(
      canCreateAccount,
      canCreateDCR,
      canCreateDCRLine,
      canQueryDCRFieldType,
      customSettingValues
    );
  }

  handleResize(event) {
    if (event.detail.isUserTriggered) {
      let i = 0;
      this.searchResultColumns.forEach(column => {
        // eslint-disable-next-line no-param-reassign
        column.initialWidth = event.detail.columnWidths[i++];
      });
    }
  }

  getUserWidthSetting(fieldName) {
    const column = this.searchResultColumns.find(col => col.fieldName === fieldName);
    return column.initialWidth;
  }

  // Gives access to Workspace API methods within LWC
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
}