import { api, LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';

import myAccountsGridStyleOverrides from '@salesforce/resourceUrl/myAccountsGridStyleOverrides';

import { getService, SERVICES } from 'c/veevaServiceFactory';

import MyAccountsCallAccountModal from 'c/myAccountsCallAccountModal';

import USER_ID from '@salesforce/user/Id';
import CALL_CENTER_FLD from '@salesforce/schema/User.CallCenterId';

import MyAccountsColumnFactory from './myAccountsColumnFactory';
import MyAccountsRow from './model/myAccountsRow';

export default class MyAccountsGrid extends NavigationMixin(LightningElement) {
  _labels;
  _stylesLoaded = false;
  _initializedGrid = false;
  _currentRows = [];
  _originalColumns = [];
  _selectedRecords = [];
  _userInformation = {};
  _currentView = {};

  userId = USER_ID;
  userFields = [CALL_CENTER_FLD];

  gridFeatures = {
    cellMenu: false,
    headerMenu: false,
    filter: true,
    sort: true,
  };
  useRawData = true;
  gridColumns = [{ id: '', field: '', text: '' }];

  bryntumGridDataStore = getService(SERVICES.BYPASS_PROXY_DATA_STORE);

  @api
  get labels() {
    return this._labels;
  }

  set labels(value) {
    if (value) {
      this._labels = value;
      if (Object.keys(this._labels).length > 0) {
        this._updateColumns(this._originalColumns);
      }
    }
  }

  @api
  get rows() {
    return this._currentRows;
  }

  set rows(newRows) {
    const rowsToUse = MyAccountsGrid.DATA || newRows;
    if (rowsToUse) {
      const accountRows = rowsToUse.map(row => new MyAccountsRow(row));

      const dataStoreId = this.bryntumGridDataStore.put(accountRows);
      accountRows.dataStoreId = dataStoreId;
      
      if (this._currentRows?.dataStoreId) {
        this.bryntumGridDataStore.remove(this._currentRows?.dataStoreId);
      }
      this._currentRows = accountRows;
    }
  }

  @api 
  get view() {
    return this._currentView;
  }

  set view(value) {
    if (value) {
      this._currentView = value;
      if (this._originalColumns?.length) {
        this._updateColumns(this._originalColumns);
      }
    }
  }

  @api
  get columns() {
    return this._originalColumns;
  }

  set columns(newColumns) {
    if (newColumns) {
      this._originalColumns = newColumns;
      this._updateColumns(newColumns);
    }
  }

  @api
  get selectedRecords() {
    return this._selectedRecords;
  }

  set selectedRecords(selectedRecords) {
    this._selectedRecords = selectedRecords ? selectedRecords.map(record => record.id) : [];
  }

  @wire(getRecord, { recordId: '$userId', fields: '$userFields'})
  wiredUserDetails({ data }) {
    if (data) {
      this._userInformation = Object.entries(data?.fields ?? {}).reduce((currentMap, [key, valueObject]) => {
        currentMap[key] = valueObject.value;
        return currentMap;
      }, {});
      this._updateColumns(this._originalColumns);
    }
  }

  get fields() {
    // Columns of type MyAccountsColumn will have a getFieldDefinition method that will be used
    // Otherwise we will just use the column.field
    return this.gridColumns.map(column => {
      if (column.getFieldDefinition) {
        return column.getFieldDefinition();
      }
      return column.field;
    });
  }

  get grid() {
    return this.template.querySelector('c-veeva-bryntum-grid');
  }

  renderedCallback() {
    if (!this._initializedGrid) {
      this._initializedGrid = true;
      this.renderGrid();
    }
    if (!this._stylesLoaded) {
      loadStyle(this, myAccountsGridStyleOverrides);
      this._stylesLoaded = true;
  }
  }

  disconnectedCallback() {
    this.bryntumGridDataStore.remove(this._currentRows?.dataStoreId);
  }

  async renderGrid() {
    await this.grid.renderGrid(this._currentRows, this.gridColumns);
  }

  /**
   * Programmatically specify a column to sort by
   *
   * @param sortConfig specifies the columns to sort by and ascending boolean
   */
  @api
  sort(columnAndAscending) {
    const { column, ascending } = columnAndAscending;
    const sortConfig = { field: MyAccountsColumnFactory.create(column, null, this.labels).field, ascending };
    // See VeevaBryntumGrid.sort for more information
    this.grid.sort(sortConfig);
  }

  @api
  clearFilters() {
    this.grid.clearFilters();
  }

  @api
  removeAccountsFromGrid(accountIds) {
    if (accountIds && accountIds.length > 0) {
      this.grid.applyChangeset({
        removed: accountIds.map(accountId => ({ id: accountId })),
      });
    }
  }

  @api
  getRows(isSorted, shouldApplyFilters) {
    return [...this.grid.getRows(isSorted, shouldApplyFilters)];
  }

  /**
   * Gets the currently used columns for the Grid
   */
  @api
  getColumns() {
    return this.gridColumns;
  }

  handleSelectionChange(event) {
    this.dispatchEvent(
      new CustomEvent('selectionchange', {
        detail: {
          // We will propagate a shallow copy so we do not end up passing the proxy of event.detail.selection
          selected: [...event.detail.selection],
        },
      })
    );
  }

  handleFilterChange(event) {
    const detailObj = {
      numFilters: event.detail.filters?.totalCount ?? 0,
    }
    if (event.detail.removed !== undefined || event.detail.added !== undefined) {
      detailObj.numAccounts = event.detail.records?.length ?? 0;
    }

    this.dispatchEvent(
      new CustomEvent('filterschange', {
        detail: detailObj,
      })
    );
  }

  handleRowAction(event) {
    const { row } = event.detail;
    const actionName = event.detail.action?.name;
    if (actionName === 'viewRecord') {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
          actionName: 'view',
          recordId: row.id,
          objectApiName: row.objectApiName,
        },
      });
    } else if (actionName === 'call') {
      MyAccountsCallAccountModal.open({
        size: 'small',
        record: row.record,
        phoneNumber: event.detail.row.phoneNumber,
        labels: this.labels,
      });
    }
  }

  handleSort(event) {
    const sortingGridColumn = this.gridColumns.find(gridColumn => gridColumn.field === event.detail.sorters[0]?.field);
    const sortLabel = [sortingGridColumn?.prefix, sortingGridColumn?.text].filter(value => value).join(' ');

    this.dispatchEvent(
      new CustomEvent('sort', {
        detail: {
          ascending: event.detail.sorters[0].ascending,
          sortLabel
        }
      })
    );
  }

  _updateColumns(newColumns) {
    this.gridColumns = newColumns.map(column => MyAccountsColumnFactory.create(column, this.view, this._userInformation, this.labels));
  }
}