import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import VeevaUtils from 'c/veevaUtils';
import { SERVICES, getService } from 'c/veevaServiceFactory';
import { createColumn, formatData } from './support/gridHelper';

const LIST_VIEW_PAGE_SIZE = 200;
const RECENT_VIEW = 'Recent';
const MESSAGES = [
  { key: 'NEW', category: 'Common', defaultMessage: 'New', label: 'newLabel' },
  { key: 'CLEAR_FILTERS', category: 'Common', defaultMessage: 'Clear Filters', label: 'clearFiltersLabel' },
  { key: 'LIST_VIEWS', category: 'Common', defaultMessage: 'List Views', label: 'listViewsSubheaderLabel' },
  { key: 'RECENTLY_VIEWED', category: 'Common', defaultMessage: 'Recently Viewed', label: 'recentlyViewedLabel' },
];
export default class VeevaListViewPage extends NavigationMixin(LightningElement) {
    
  @api objectApiName;
  @api hideCheckboxColumn;

  @wire(CurrentPageReference)
  getCurrentPageReference(currentPageReference) {
    this.pageRef = currentPageReference;
    if (this.gridInitialized) {
      this.handleViewChange({ detail: { value: RECENT_VIEW} });
    }
  }

  @wire(getObjectInfo, { objectApiName: '$objectApiName' })
  wiredObjectInfo({ data }) {
      if (data) {
          this.objectInfo = data;
          this.loadingAction(this.init);
      }
  }

  viewMetadata = {};
  gridInitialized;
  loading = true;
  gridFeatures = {
    sort: true,
    filter: true,
    headerMenu: false,
    cellMenu: false,
    cellEdit: false,
  };
  views = [];
  currentView;
  data = [];
  columns = [ {type: 'rownumber'} ];
  uiApi = getService(SERVICES.UI_API);
  messageService = getService(SERVICES.MESSAGE);
  hasFilters;
  actionOverrides;

  get icon() {
      return VeevaUtils.getIconFromUrl(this.objectInfo?.themeInfo?.iconUrl);
  }

  get subtitle() {
      return this.objectInfo?.labelPlural;
  }

  get modelFields() {
    return this.columns.filter(c => c.field).map(col => {
      let modelField = col.field;
      if (modelField.includes('.')) {
        modelField = {
          name: col.field,
          dataSource: col.field
        }
      }
      return modelField;
    });
  }

  get enableClearFilters() {
    return !this.hasFilters;
  }

  get hasVFOverride() {
    return this.actionOverrides.some(override => override.name === 'New' && override.formFactor === null && override.url != null);
  }

  get hasLEXOverride() {
    return this.actionOverrides.some(override => override.name === 'New' && override.formFactor === 'LARGE' && override.url === null);
  }

  async renderedCallback() {
    this.grid = this.template.querySelector('c-veeva-bryntum-grid');
    this.renderGrid();
    if (!this.actionOverrides) {
      this.actionOverrides = (await this.uiApi.getObjectInfoFromRestApi(this.objectApiName)).actionOverrides;
    }
  }

  async renderGrid() {
    if (!this.gridInitialized && this.grid) {
      await this.grid.renderGrid(this.data, this.columns);
      this.gridInitialized = true;
    }
  }

  async loadingAction(fn, ...args) {
    try {
      this.loading = true;
      await fn.bind(this)(...args);
    } finally {
      this.loading = false;
    }
  }

  async init() {
    await this.loadVeevaMessages();
    this.views = await this.getViews();
    this.currentView = RECENT_VIEW;
    await this.updateListColumnsAndData(this.currentView);
  }

  async loadVeevaMessages() {
    const vmr = this.messageService.createMessageRequest();
    MESSAGES.forEach(({key, category, defaultMessage, label}) => vmr.addRequest(key, category, defaultMessage, label));
    let msgMap = {};
    try {
      msgMap = await this.messageService.getMessageMap(vmr);
    } catch (e) {
      // fallback to default english message if error
      MESSAGES.forEach(({ defaultMessage, label}) => {
        msgMap[label] = defaultMessage;
      });
    }
    Object.entries(msgMap).forEach(([key, value]) => {
      this[key] = value;
    });
  }

  async getViews() {
    const listViews = await this.uiApi.getListViewSummaryCollection(this.objectApiName);
    const customViews = listViews?.map(view => ({
      label: view.label,
      value: view.id
    })) ?? [];
    const viewOptions = [ { label: this.recentlyViewedLabel, value: RECENT_VIEW } ]
      .concat(customViews)
      .sort((a, b) => a.label.localeCompare(b.label));
    viewOptions.unshift({
      subheader: true,
      label: this.listViewsSubheaderLabel
    });
    viewOptions.forEach((v, idx) => { v.key = idx });
    return viewOptions;
  }

  async getColumns(view) {
    if (!this.viewMetadata[view]) {
      const getAndParse = async (v) => {
        const info = await this.getListViewMetadata(v);
        return [{ type : 'rownumber' }, ...this.parseColumns(info)];
      }
      this.viewMetadata[view] = getAndParse(view);
    }
    return this.viewMetadata[view];
  }

  parseColumns({ displayColumns }) {
    return displayColumns?.map(col => createColumn(col.fieldApiName, col.label, this.objectInfo ));
  }

  parseData(records, columns) {
    return records.map(({ fields: record }) => formatData(record, columns));
  }

  newRecord() {
    this[NavigationMixin.Navigate]({
      type: 'standard__objectPage',
      attributes: {
          objectApiName: this.objectApiName,
          actionName: 'new',
      },
      state: {
        inContextOfRef: `1.${window.btoa(JSON.stringify(this.pageRef))}`,
        useRecordTypeCheck: this.hasVFOverride && !this.hasLEXOverride
      }
    });
  }

  handleFilter(event) {
    const { filters } = event.detail;
    this.hasFilters = filters?.values?.length > 0;
  }

  clearFilters() {
    this.grid.clearFilters();
    this.hasFilters = false;
  }

  async handleViewChange(event) {
    const { value } = event.detail;
    this.currentView = value;
    this.loading = true;
    this.clearFilters();
    if (this.currentView === RECENT_VIEW) {
      this.sortedBy = null;
      this.sortAscending = null;
    } else {
      const columns = await this.getColumns(this.currentView);
      this.sortedBy = columns[1].field; // first column is row number, so we take the second column
      this.sortAscending = true;
    }
    this.grid.sort({ field: this.sortedBy, ascending: this.sortAscending }); // this will invoke the sort event handler
  }

  async handleSort(event) {
    this.sortedBy = event.detail.sorters[0].field;
    this.sortAscending = event.detail.sorters[0].ascending;
    await this.loadingAction(this.updateListColumnsAndData, this.currentView);
  }

  async updateListColumnsAndData(view) {
    const [columns, records] = await Promise.all([this.getColumns(this.currentView), this.partitionedGetListViewRecords(view)]);
    this.columns = columns;
    this.data = this.parseData(records, this.columns);
  }

  getListViewMetadata(view) {
    let method = 'getListViewMetadata';
    let viewId = view;
    if (viewId === RECENT_VIEW) {
      method = 'getRecentlyViewedListMetadata';
      viewId = this.objectApiName;
    }
    return this.uiApi[method](viewId);
  }

  getListViewRecords(view, pageToken=0) {
    let viewId = view;
    let method = 'getListViewRecords';
    if (viewId === RECENT_VIEW) {
      method = 'getRecentlyViewedListRecords';
      viewId = this.objectApiName;
    }
    const params = {
      pageSize: LIST_VIEW_PAGE_SIZE,
      pageToken
    };
    if (this.sortedBy) {
      params.sortBy = this.sortedBy;
      params.sortAscending = this.sortAscending;
    }
    return this.uiApi[method](viewId, params);
  }

  async partitionedGetListViewRecords(view, pageToken, page=0) {
    const { nextPageToken, records } = await this.getListViewRecords(view, pageToken);
    if (!nextPageToken || page === 4) { // 5 iterations, chunks of 200, 1000 records maximum
      return records;
    }
    return this.partitionedGetListViewRecords(view, nextPageToken, page+1).then(response => records.concat(response));
  }
}