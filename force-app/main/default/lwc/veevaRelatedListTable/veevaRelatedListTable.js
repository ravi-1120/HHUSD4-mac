import { api, track, LightningElement, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import VeevaConstant from 'c/veevaConstant';
import VeevaToastEvent from 'c/veevaToastEvent';
import { setFormulaLinkFields } from 'c/veevaDatatable';
import { loadStyle } from 'lightning/platformResourceLoader';
import styleOverride from '@salesforce/resourceUrl/veevaRelatedListTableStyling';
import { getUpdatedDraftValues } from 'c/veevaCustomDraftValue';
import VeevaConfirmationLightningModal from 'c/veevaConfirmationLightningModal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import RelatedListControllerFactory from './relatedListControllerFactory';

const INITIAL_OFFSET = 0;
const INITIAL_LIMIT = 51;
const INFINITE_SCROLL_INCREMENTS = 20;
const MAX_ROW_SELECTION = 200;
const EXCLUDED_SEARCH_OBJECTS = ['ContentDocument', 'ContentNote'];

export default class VeevaRelatedListTable extends NavigationMixin(LightningElement) {
  static styleOverridePromise;
  @api parentId;
  @api meta;
  @api pageCtrl;
  @api size;
  @track buttons = [];
  @track records = [];
  msgMap = {};
  recordTotalCount;
  selectedRowsCount;
  iconName = '';
  showDeleteModal = false;
  isDeleting = false;
  isLoading = true;
  msgCancel;
  msgDelete;
  deleteModalBody;
  deleteModalHeader;
  recordToDelete;
  columns = [];
  ctrl;
  hasMoreData = true;
  sortDirection;
  sortBy;
  hideFileUpload = true;
  rowId = '';
  draftValues = [];
  errors = {};
  searchTerm = '';
  filters = [];
  selectedFilters = {};
  showFilter = false;
  displayFilterPopover = false;
  discardModalOpen = false;

  @wire(getObjectInfo, { objectApiName: '$objectApiName' })
  wireObjectInfo(result) {
    const { data, error } = result;
    if ((data || error) && this.ctrl) {
      if (data) {
        this.ctrl.objectDescribe = data;
      }
      this.ctrl.meta = this.meta;
      this.ctrl.getButtons().then(buttons => {
        this.buttons = buttons;
      });
      this.ctrl.getColumns().then(columns => {
        this.columns = columns;
        if (this.ctrl.objectDescribe?.fields) {
          setFormulaLinkFields(this.ctrl.objectDescribe.fields, this.columns);
        }
        this.initRecords();
      });
      this.initIcon();
      this.initFilters();
      this.initDeleteModal();
    }
  }

  get recordTotalCountLabel() {
    return this.msgMap.items?.replace('{0}', this.recordTotalCount || '0') || '';
  }

  get selectedRowsCountLabel() {
    let label = '';
    const message = this.msgMap.selected?.replace('{0}', this.selectedRowsCount || '0');
    if (message) {
      label = ` • ${message}`;
    }
    return label;
  }

  get sortedByLabel() {
    let label = '';
    if (this.sortBy && this.columns?.length > 0) {
      const columnLabel = this.columns.find(col => col.fieldName === this.sortBy)?.label;
      const message = this.msgMap.sortedBy;
      if (columnLabel && message) {
        label = ` • ${message.replace('{0}', columnLabel)}`;
      }
    }
    return label;
  }

  get sortDirectionIcon() {
    let icon = '';
    if (this.sortedByLabel) {
      icon = this.sortDirection === 'desc' ? 'utility:down' : 'utility:up';
    }
    return icon;
  }

  get filtersSelectedLabel() {
    let label = '';
    const selectedFilterFields = Object.keys(this.selectedFilters);
    const numFilters = selectedFilterFields.length;
    if (numFilters > 0 && this.recordTotalCount) {
      label = ' • ';
    }
    if (numFilters >= 4) {
      label += this.msgMap.filtersAppliedLabel.replace('{0}', numFilters);
    } else if (numFilters > 0) {
      const filterFieldLabels = this.filters
        .filter(filterGroup => selectedFilterFields.includes(filterGroup.fieldName))
        .map(filterGroup => filterGroup.fieldLabel);
      label += this.msgMap.filteredByLabel.replace('{0}', filterFieldLabels.join(', '));
    }
    return label;
  }

  get hideCheckboxColumn() {
    return !this.columns.some(col => col.editable === true);
  }

  get relatedListStyle() {
    let style = 'slds-card__body slds-is-relative slds-border_top related-list-table';
    if (this.size === 'small') {
      style += ' related-list-small';
    }
    if (this.size === 'large') {
      style += ' related-list-large';
    }
    if (this.size === 'host') {
      style += ' host-height-related-list';
    }
    return style;
  }

  get recordsLength() {
    let num = 0;
    if (this.records) {
      num = this.records.length;
    }
    return num;
  }

  get objectApiName() {
    return this.meta.objectApiName;
  }

  get noRecords() {
    return this.recordsLength === 0 && !this.isLoading;
  }

  get queryFieldsString() {
    return this.ctrl.getQueryFields(this.meta.columns).join(',');
  }

  get objectLabel() {
    return this.ctrl.objectDescribe.label;
  }

  get showFileUpload() {
    return this.ctrl.showFileUpload && !this.hideFileUpload;
  }

  get maxRowSelection() {
    return MAX_ROW_SELECTION;
  }

  get noRecordsClass() {
    return this.size === 'host' ? 'no-records-msg-host-height' : 'no-records-msg';
  }

  initIcon() {
    this.iconName = this.ctrl.iconName;
  }

  async initFilters() {
    this.showFilter = this.ctrl.showFilter();
    await this.refreshFilters();
  }

  async initRecords(sortBy, sortDirection, queryLimit, forceRefresh = false) {
    if (!sortBy) {
      // eslint-disable-next-line no-param-reassign
      sortBy = this.ctrl.defaultSortColumn;
    }
    if (!sortDirection) {
      // eslint-disable-next-line no-param-reassign
      sortDirection = this.ctrl.defaultSortDirection;
    }
    this.isLoading = true;
    try {
      const { records, recordTotalCount } = await this.ctrl.fetchRecordsWithTotals(
        {
          fields: this.queryFieldsString,
          objectApiName: this.objectApiName,
          relationField: this.meta.field,
          id: this.parentId,
          qlimit: queryLimit || INITIAL_LIMIT,
          offset: INITIAL_OFFSET,
          sortBy: sortBy === 'linkName' ? this.ctrl.nameField : sortBy,
          sortDirection,
          duplicateRawFields: true,
          searchTerm: this.searchTerm,
          filters: this.selectedFilters,
        },
        forceRefresh
      );
      this.records = this.ctrl.processRecords(records);
      this.recordTotalCount = recordTotalCount;
      this.sortBy = sortBy;
      this.sortDirection = sortDirection;
      this.hasMoreData = this.recordsLength >= INITIAL_LIMIT;
    } catch (error) {
      this.records = [];
      this.recordTotalCount = 0;
    } finally {
      this.isLoading = false;
    }
  }

  async initDeleteModal() {
    [this.msgConfirmDelete, this.msgDelete, this.msgCancel] = await Promise.all([
      this.pageCtrl.getMessageWithDefault('GENERIC_DELETE_BODY', 'Common', 'Are you sure you want to delete this {0}?'),
      this.pageCtrl.getMessageWithDefault('DELETE', 'Common', 'Delete'),
      this.pageCtrl.getMessageWithDefault('CANCEL', 'Common', 'Cancel'),
    ]);
  }

  @api resetRecords() {
    if (this.recordsLength > INITIAL_LIMIT) {
      this.refreshRecords();
    }
  }

  @api async refreshRecords(qlimit = INITIAL_LIMIT, resetDraftValues = true, refreshFilters = true) {
    if (resetDraftValues) this.updateDraftValues([]);
    this.updateErrors({});
    this.hasMoreData = false;
    this.records = [];
    if (refreshFilters) {
      this.refreshFilters();
    }
    await this.initRecords(this.sortBy, this.sortDirection, qlimit, true);
  }

  async connectedCallback() {
    if (!VeevaRelatedListTable.styleOverridePromise) {
      VeevaRelatedListTable.styleOverridePromise = loadStyle(this, styleOverride).catch(() => {
        VeevaRelatedListTable.styleOverridePromise = null;
      });
    }
    VeevaRelatedListTable.styleOverridePromise.finally(() => {
      this.hideFileUpload = false;
    });

    let ctrl;
    if (this.pageCtrl.getRelatedListController) {
      ctrl = this.pageCtrl.getRelatedListController(this.meta, this.pageCtrl);
    }
    if (!ctrl) {
      ctrl = RelatedListControllerFactory.relatedListController(this.meta, this.pageCtrl);
    }
    this.ctrl = ctrl;
    if (this.ctrl.initData) {
      await this.ctrl.initData();
    }
    this.msgMap = await this.pageCtrl.messageSvc
      .createMessageRequest()
      .addRequest('NO_RECORDS', 'Common', 'No records to display', 'noRecordsMsg')
      .addRequest('CANNOT_SAVE_RELATED_LIST_RECORDS', 'Lightning', `Can't save records with errors.`, 'saveErrors')
      .addRequest('RELATED_LIST_RECORD_ERROR', 'Lightning', 'Item {0} has errors.', 'itemError')
      .addRequest('RELATED_LIST_RECORDS_UPDATE_SUCCESS', 'Lightning', 'Your changes are saved.', 'saveSuccess')
      .addRequest('RELATED_LIST_FIELD_ERROR', 'Lightning', 'Item {0} has errors in these fields: {1}', 'fieldError')
      .addRequest('ITEMS_IN_LIST', 'Common', '{0} Items', 'items')
      .addRequest('SELECTED_ROWS', 'Common', '{0} Selected', 'selected')
      .addRequest('SORTED_BY', 'Common', 'Sorted by {0}', 'sortedBy')
      .addRequest('MAXIMUM_ITEMS_SELECTED', 'Lightning', 'The maximum number of items have been selected', 'maximumItemsSelected')
      .addRequest('EDITING_ITEMS_IN_LIST', 'Lightning', 'Editing Item(s) in {0}', 'discardPromptHeader')
      .addRequest('UNSAVED_CHANGES_IN_LIST', 'Lightning', `You have unsaved changes.`, 'unsavedChanges')
      .addRequest('DISCARD_CHANGES_IN_LIST', 'Lightning', `Are you sure you want to discard these changes?`, 'discardChangesPrompt')
      .addRequest('STAY_ON_THIS_LIST', 'Lightning', 'Stay on this List', 'stayOnList')
      .addRequest('DISCARD_CHANGES', 'Lightning', 'Discard Changes', 'discardChanges')
      .addRequest('SEARCH_THIS_LIST', 'Lightning', 'Search this list...', 'searchThisListLabel')
      .addRequest('FILTER', 'Common', 'Filter', 'filterLabel')
      .addRequest('FILTERED_BY', 'Lightning', 'Filtered by {0}', 'filteredByLabel')
      .addRequest('FILTERS_APPLIED', 'Lightning', '{0} Filters Applied', 'filtersAppliedLabel')
      .sendRequest();
  }

  deleteRecord(id) {
    const newList = this.records.filter(row => row.Id !== id);
    this.records = newList;
    this.updateRecordTotals(this.recordTotalCount - 1);
  }

  updateRecordTotals(value) {
    this.recordTotalCount = value;
  }

  handleRowSelection(event) {
    this.selectedRowsCount = event.detail.selectedRows.length;
    if (this.selectedRowsCount === this.maxRowSelection) {
      this.dispatchEvent(
        new ShowToastEvent({
          message: this.msgMap.maximumItemsSelected,
          variant: 'warning',
        })
      );
    }
  }

  async handleButton(event) {
    const button = event.target;
    if (!(await this.confirmDiscardDraft())) {
      return;
    }
    switch (button.name) {
      case 'new':
        await this.routeToNew();
        break;
      default:
        // non standard button
        this.ctrl.handleButton(button.name);
    }
  }

  async routeToNew() {
    const context = await this.ctrl.getInContextOfRefForNew();
    if (this.ctrl.launchNewFlow) {
      try {
        await this.ctrl.launchNewFlow(context);
      } catch (e) {
        this.dispatchEvent(VeevaToastEvent.error({ message: e }));
      }
    } else {
      this.isLoading = true;
      try {
        const newObject = await this.ctrl.getPageRefForNew(context);
        if (this.ctrl.objectDescribe.apiName === "ContentNote") {
          window.location = `/${newObject.state.recordId}`;
        } else {
          this[NavigationMixin.Navigate](newObject);
        }
      } catch (e) {
        this.dispatchEvent(VeevaToastEvent.error(e));
      } finally {
        this.isLoading = false;
      }
    }
  }

  async routeToEdit(row) {
    if (this.ctrl.launchEditFlow) {
      try {
        await this.ctrl.launchEditFlow(row);
      } catch (e) {
        this.dispatchEvent(VeevaToastEvent.error({ message: e }));
      }
    } else {
      this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
          recordId: row.Id,
          objectApiName: this.objectApiName,
          actionName: 'edit',
        },
      });
    }
  }

  async partialRefresh(savedRecords, recordIdToIndexMap) {
    this.refreshFilters();

    const savedIds = new Set();
    savedRecords.forEach(record => savedIds.add(record.Id));

    const records = await this.ctrl.fetchRecordsById({
      ids: [...savedIds],
      fields: this.queryFieldsString,
      objectApiName: this.objectApiName,
      duplicateRawFields: true,
    });

    const processed = this.ctrl.processRecords(records);
    processed.forEach(record => {
      const index = recordIdToIndexMap[record.Id];
      if (index >= 0) {
        this.records[index] = record;
      }
    });
  }

  async handleRowAction(event) {
    const { action } = event.detail;
    const { row } = event.detail;

    if (!(await this.confirmDiscardDraft())) {
      return;
    }

    switch (action.name) {
      case 'edit':
        await this.routeToEdit(row);
        break;
      case 'delete': {
        const objectApiName = row.objectApiName || this.objectApiName;
        const objectLabel = row.objectLabel || this.objectLabel;
        this.recordToDelete = { Id: row.Id, Name: row[this.ctrl.nameField], objectApiName, objectLabel };
        this.deleteModalBody = [this.msgConfirmDelete.replace('{0}', objectLabel)];
        this.deleteModalHeader = `${this.msgDelete} ${objectLabel}`;
        this.isDeleting = false;
        this.showDeleteModal = true;
        break;
      }
      default: {
        // non standard action
        const { pageRef, toastEvent, refreshRecords } = (await this.ctrl.handleRowAction(action, row)) || {};
        if (pageRef) {
          this[NavigationMixin.Navigate](pageRef);
        }
        if (toastEvent) {
          this.dispatchEvent(toastEvent);
        }
        if (refreshRecords) {
          this.refreshRecords();
        }
      }
    }
  }

  handleDelete() {
    this.isDeleting = true;
    const recordToDelete = { ...this.recordToDelete };
    this.ctrl
      .deleteRow(recordToDelete.Id, recordToDelete.objectApiName)
      .then(async () => {
        // successful delete
        this.deleteRecord(recordToDelete.Id);
        this.refreshFilters();
        const toast = await VeevaToastEvent.recordDeleted(recordToDelete.objectLabel, recordToDelete.Name.displayValue ?? recordToDelete.Name);
        this.dispatchEvent(toast);
      })
      .catch(error => {
        // delete error
        let message = error;
        if (error.recordErrors && error.recordErrors.length > 0) {
          [message] = error.recordErrors;
        }
        this.dispatchEvent(VeevaToastEvent.error({ message }));
      })
      .finally(() => {
        this.showDeleteModal = false;
        this.isDeleting = false;
      });
  }

  handleDatatableCancel(event) {
    this.errors = {};
    event.preventDefault();
    this.updateDraftValues([]);
  }

  // Handles out of the box column changes, like text, datetime, etc.
  handleCellChange(event) {
    event.preventDefault();
    event.detail.draftValues.forEach(draftValue => {
      this.updateDraftValues(getUpdatedDraftValues(this.draftValues, draftValue));
    });
  }

  handleDraftValuesChange(event) {
    this.updateDraftValues(event.detail);
  }

  updateErrors(newErrors) {
    this.errors = newErrors;
  }

  // rerender the table with updated draft values
  updateDraftValues(newDraftValues) {
    this.draftValues = [...newDraftValues];
  }

  handleCancel() {
    this.recordToDelete = null;
    this.showDeleteModal = false;
  }

  async handleSave() {
    this.isLoading = true;
    const toSave = this.draftValues.map(draftValue => draftValue.toBaseApiSaveFormat());
    try {
      const { savedRecords, failedRecords } = await this.ctrl.save(toSave);
      const recordIdToIndexMap = {};
      this.records.forEach((record, index) => {
        recordIdToIndexMap[record.Id] = index;
      });

      if (failedRecords.length === 0) {
        this.dispatchEvent(
          new ShowToastEvent({
            message: this.msgMap.saveSuccess,
            variant: 'success',
          })
        );
        await this.partialRefresh(savedRecords, recordIdToIndexMap);
        this.updateDraftValues([]);
        this.updateErrors({});
      } else {
        if (savedRecords.length > 0) {
          // Refresh table to display potential new data due to automation, i.e triggers
          await this.partialRefresh(savedRecords, recordIdToIndexMap);
        }
        const newDraftValues = [];
        const savedRecordsSet = new Set();
        Object.keys(savedRecords).forEach(key => savedRecordsSet.add(savedRecords[key].Id));

        // Keep draftValues for failed records
        this.draftValues.forEach(draftValue => {
          if (!savedRecordsSet.has(draftValue.Id)) {
            newDraftValues.push(draftValue);
          }
        });

        const errors = this.getDatatableFormattedErrors(failedRecords, recordIdToIndexMap);
        this.updateDraftValues(newDraftValues);
        this.updateErrors(errors);
      }
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error(`error : ${error}`);
    } finally {
      this.isLoading = false;
    }
  }

  async loadMoreData(event) {
    if (!this.hasMoreData) {
      return;
    }

    const table = event.target;
    try {
      table.isLoading = true;
      const records = await this.ctrl.fetchRecords({
        fields: this.queryFieldsString,
        objectApiName: this.objectApiName,
        relationField: this.meta.field,
        id: this.parentId,
        qlimit: INFINITE_SCROLL_INCREMENTS,
        offset: this.recordsLength,
        sortBy: this.sortBy === 'linkName' ? this.ctrl.nameField : this.sortBy,
        sortDirection: this.sortDirection,
        duplicateRawFields: true,
        searchTerm: this.searchTerm,
        filters: this.selectedFilters,
      });

      if (records.length > 0) {
        this.records = this.records.concat(this.ctrl.processRecords(records));
      } else {
        // assume that there are no more data to be fetched
        this.hasMoreData = false;
      }
    } finally {
      table.isLoading = false;
    }
  }

  async handleSort(event) {
    const { fieldName: sortBy, sortDirection } = event.detail;
    if (!(await this.confirmDiscardDraft())) {
      return;
    }
    this.hasMoreData = false;
    this.records = [];
    this.initRecords(sortBy, sortDirection);
  }

  async handleLinkClick(event) {
    if (await this.confirmDiscardDraft()) {
      if (this.ctrl.objectDescribe.apiName === "ContentNote") {
        window.location = event.detail.url;
      } else {
        this[NavigationMixin.Navigate]({
          type: 'standard__webPage',
          attributes: { url: event.detail.url },
        });
      }
    }
  }

  async confirmDiscardDraft() {
    let confirm = true;
    if (this.draftValues.length > 0) {
      if (await this.promptToDiscardDraftValues()) {
        this.updateDraftValues([]);
        this.updateErrors({});
      } else {
        confirm = false;
      }
    }
    return confirm;
  }

  async promptToDiscardDraftValues() {
    this.discardModalOpen = true;
    /* eslint-disable @locker/locker/distorted-xml-http-request-window-open */
    const confirm = await VeevaConfirmationLightningModal.open({
      title: this.msgMap.discardPromptHeader.replace('{0}', this.objectLabel),
      messages: [this.msgMap.unsavedChanges, this.msgMap.discardChangesPrompt],
      confirmLabel: this.msgMap.discardChanges,
      cancelLabel: this.msgMap.stayOnList,
      buttonHorizontalAlign: 'center',
      centerMessagesAbsolutely: true,
      size: 'small',
    });
    this.discardModalOpen = false;
    return confirm;
  }

  async handleRefresh() {
    if (await this.confirmDiscardDraft()) {
      this.refreshRecords();
    }
  }

  handleUploadFinished(event) {
    this.ctrl.handleUploadFinished(event?.detail?.files);
    this.refreshRecords();
  }

  getDatatableFormattedErrors(failedRecords, recordIdToIndexMap) {
    const errors = {};
    const { rowErrors, indexToFailedFieldsMap } = this.getRowErrors(failedRecords, recordIdToIndexMap);
    errors.rows = rowErrors;
    errors.table = this.getTableErrors(indexToFailedFieldsMap);
    return errors;
  }

  getRowErrors(failedRecords, recordIdToIndexMap) {
    const rowErrors = {};
    const indexToFailedFieldsMap = {};

    failedRecords.forEach(record => {
      const id = record[this.ctrl.objectDescribe.apiName].Id;
      const recordIndex = recordIdToIndexMap[id];
      const errObject = { title: this.msgMap.itemError.replace('{0}', recordIndex + 1), messages: [], fieldNames: [] };

      record.updateErrors.forEach(updateError => {
        if (!indexToFailedFieldsMap[recordIndex]) {
          indexToFailedFieldsMap[recordIndex] = [];
        }
        const translatedFields = updateError.fields.map(field => {
          let fieldName = field;
          const potentialLookup = `${field.split('__c')[0]}__r.Name`;
          if (this.columns.some(col => col.fieldName === potentialLookup)) {
            fieldName = potentialLookup;
          }
          return fieldName;
        });
        indexToFailedFieldsMap[recordIndex].push(...updateError.fields);
        errObject.messages.push(updateError.message);
        errObject.fieldNames.push(...translatedFields);
      });
      rowErrors[id] = errObject;
    });

    return { rowErrors, indexToFailedFieldsMap };
  }

  getTableErrors(indexToFailedFieldsMap) {
    const indexToFailedFieldLabelsMap = {};
    const indices = Object.keys(indexToFailedFieldsMap);

    indices.forEach(index => {
      const fieldApiNames = indexToFailedFieldsMap[index];
      const fieldLabels = fieldApiNames.map(fieldApiName => this.ctrl.objectDescribe.fields[fieldApiName]?.label || fieldApiName);
      indexToFailedFieldLabelsMap[index] = fieldLabels;
    });

    const tableErrors = {
      title: this.msgMap.saveErrors,
      messages: indices
        .sort((a, b) => a - b)
        .map(index => {
          let message = '';
          if (indexToFailedFieldLabelsMap[index]?.length > 0) {
            message = this.msgMap.fieldError.replace('{0}', parseInt(index, 10) + 1).replace('{1}', indexToFailedFieldLabelsMap[index].join(', '));
          } else {
            message = this.msgMap.itemError.replace('{0}', parseInt(index, 10) + 1);
          }
          return message;
        }),
    };
    return tableErrors;
  }

  updateSearchTerm(event) {
    if (event.detail.value && event.detail.value.length < 2) {
      return;
    }
    this.searchTerm = event.detail.value;
    window.clearTimeout(this.debounce);
    // eslint-disable-next-line @locker/locker/distorted-window-set-timeout, @lwc/lwc/no-async-operation
    this.debounce = setTimeout(() => {
      this.refreshRecords(undefined, undefined, false);
    }, VeevaConstant.DEBOUNCE_DELAY);
  }

  get showSearchBox() {
    return !EXCLUDED_SEARCH_OBJECTS.includes(this.objectApiName);
  }

  async toggleFilterPopover() {
    if (this.filters.length > 0 && (this.displayFilterPopover || (await this.confirmDiscardDraft()))) {
      this.displayFilterPopover = !this.displayFilterPopover;
    }
  }

  async applyFilters(event) {
    this.selectedFilters = event.detail.filters;
    this.closeFilterPopover();
    this.refreshRecords(undefined, undefined, false);
  }

  closeFilterPopover() {
    this.displayFilterPopover = false;
  }

  get highlightFilterButton() {
    return this.displayFilterPopover || Object.keys(this.selectedFilters).length > 0;
  }

  async refreshFilters() {
    if (this.showFilter) {
      this.filters = await this.ctrl.getFilters({ objectApiName: this.objectApiName, referenceFieldName: this.meta.field, recordId: this.parentId });
    }
  }

  get disableFilter() {
    return this.filters.length === 0;
  }

  async handleSearchFocus() {
    if (this.discardModalOpen) {
      return;
    }
    if (!(await this.confirmDiscardDraft())) {
      this.template.querySelector('.searchBox')?.blur();
    }
  }
}