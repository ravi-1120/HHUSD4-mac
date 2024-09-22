/* eslint-disable no-param-reassign */
/* eslint-disable class-methods-use-this */
import { api, track, LightningElement, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import { getSelectionPageController, DuplicateError } from 'c/emSelectionPageControllerFactory';
import EmEventConstant from 'c/emEventConstant';
import VeevaConstant from 'c/veevaConstant';
import { setFormulaLinkFields } from 'c/veevaDatatable';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import VeevaAlertLightningModal from 'c/veevaAlertLightningModal';
import getParticipantCount from '@salesforce/apex/EmAttendeeSelection.getParticipantCount';

const DETAILS_POP = 'Details';
const FILTER_POP = 'Filter';
const NAME = 'Name';
const ID = 'Id';
const FIFTY_PLUS = '50+';
const INITIAL_SEARCH_LIMIT = 51;
const LOAD_MORE_INCREMENTS = 50;
const ASC = 'asc';
const MAX_PARTICIPANT_WITH_URL = 300;

export default class EmSelectionPage extends LightningElement {
  NAME_COLUMN = {
    label: '',
    fieldName: NAME,
    type: 'nameDetails',
    hideDefaultActions: true,
    sortable: true,
    typeAttributes: { id: { fieldName: ID }, icon: { fieldName: 'icon' } },
  };
  CUSTOM_CHECKBOX_COLUMN = {
    label: '',
    fieldName: 'checked',
    type: 'customCheckbox',
    hideDefaultActions: true,
    fixedWidth: 32,
    typeAttributes: { disabled: { fieldName: 'disabled' }, id: { fieldName: ID } },
  };
  CUSTOM_BUTTON_ICON_COLUMN = {
    label: '',
    fieldName: 'customButtonIcon',
    type: 'customButtonIcon',
    hideDefaultActions: true,
    fixedWidth: 32,
    sortable: false,
    typeAttributes: { id: { fieldName: ID } },
  };

  @api set parentRecord(value) {
    this._parentRecord = JSON.parse(value);
  }
  get parentRecord() {
    return this._parentRecord;
  }
  @api relatedList;
  @api recordType;
  @api saveResults;
  @api exitEarly;

  @wire(MessageContext)
  messageContext;

  actionTaken = false;
  hidden = true;
  loading = true;
  saving = false;

  title;
  sortedBy;
  sortDirection;
  hideCheckboxes = false;

  @track ctrl;
  @track selectedFilters = [];
  @track selectedRows;
  columns = [];
  @track data = [];
  hasMoreData;
  views = [];
  currentView;

  currentPopover = '';
  popoverRecord = {};

  get searchSectionClass() {
    let css = 'search';
    if (this.views?.length > 0) {
      css += ' slds-combobox-group';
    }
    return css;
  }

  get searchBarClass() {
    let css = 'slds-size_1-of-3';
    if (this.views?.length > 0) {
      css = 'view-search';
    }
    return css;
  }

  get searchPlaceholder() {
    let placeholder = '';
    if (this.searchMsg) {
      placeholder = `${this.searchMsg} ${this.objectInfo.labelPlural}...`;
    }
    return placeholder;
  }

  get numResults() {
    let results = '';
    const num = this.data.length > 50 ? FIFTY_PLUS : this.data.length;
    if (this.resultsVeevaMessage) {
      results = this.resultsVeevaMessage.replace('{0}', num);
    }
    return results;
  }

  get sortedByLabel() {
    let label = '';
    if (this.sortedBy && this.columns?.length > 0) {
      const columnLabel = this.columns.find(col => col.fieldName === this.sortedBy).label;
      label = `• ${this.sortedByVeevaMessage?.replace('{0}', columnLabel)}`;
    }
    return label;
  }

  get sortDirectionIcon() {
    let icon = 'utility:up';
    if (this.sortDirection === 'desc') {
      icon = 'utility:down';
    }
    return icon;
  }

  get numSelected() {
    let selected = '';
    if (this.selectedRowsVeevaMessage) {
      selected = `• ${this.selectedRowsVeevaMessage?.replace('{0}', this.selectedRowsIds.length)}`;
    }
    return selected;
  }

  get attendeeResultTruncatedLabel() {
    let msg = '';
    if (this.attendeeResultTruncated) {
      msg = this.attendeeResultTruncated.replace('{0}', EmEventConstant.ATTENDEE_SELCTION_SOQL_LIMIT);
    }
    return msg;
  }
  // Disables the toggle input based on ctrl defined method
  get disableToggle() {
    if (this.toggle?.disable) {
      const args = this.toggle.disableArgs?.map(arg => this[arg]); // Collect disable method arguments
      return this.toggle.disable(...args);
    }
    return false;
  }

  set toggledOn(value) {
    this._toggledOn = value;
    if (this.toggle) {
      const index = this.selectedFilters.findIndex(object => object.toggle);
      if (index > -1) {
        this.selectedFilters.splice(index, 1);
      }
      this.selectedFilters.push({ toggle: true, value });
    }
  }

  get toggledOn() {
    return this._toggledOn;
  }

  get isHierarchyView() {
    return this.views?.find(v => v.value === this.currentView)?.hierarchy === true;
  }

  get disableSave() {
    return !this.actionTaken || this.saving;
  }

  get canRemoveAll() {
    return this.ctrl?.canRemoveAll;
  }

  get hasFilters() {
    return this.ctrl?.filterOptions?.length > 0;
  }

  get hideDatatable() {
    return this.loading || this.data.length === 0;
  }

  get noResults() {
    return !this.loading && this.data.length === 0;
  }

  get detailsPopoverActive() {
    return this.currentPopover === DETAILS_POP;
  }

  get filterPopoverActive() {
    return this.currentPopover === FILTER_POP;
  }

  get selectedRowsPills() {
    return this.ctrl.getPills(this.selectedRows).sort((a, b) => {
      const aName = a.label;
      const bName = b.label;
      return aName.localeCompare(bName);
    });
  }

  get selectedRowsIds() {
    return Object.keys(this.selectedRows) ?? [];
  }

  get showAttendeeResultTruncatedWarning() {
    return this.ctrl.showAttendeeResultTruncatedWarning;
  }

  async connectedCallback() {
    this.ctrl = getSelectionPageController(this.relatedList, this.parentRecord);
    this.loading = true;
    this.init().then(() => {
      if (this.participantCount > MAX_PARTICIPANT_WITH_URL) {
        this.dispatchEvent(
          new ShowToastEvent({
            variant: 'warning',
            title: this.exceedMaxAttendee.replace('{0}', this.participantCount),
            mode: 'sticky',
          })
        );
      }
      this.loading = false;
    });
  }

  resetState() {
    this.searchTerm = '';
    this.sortedBy = NAME;
    this.sortDirection = ASC;
    this.popoverRecord = {};
    this.currentPopover = '';
    this.selectedRows = {};
    this.columns = [];
    this.data = [];
    this.selectedFilters = [];
    this.saveResults = null;
    this.actionTaken = false;
    this.toggledOn = false;
  }

  async init() {
    this.resetState();
    const [objectInfo, views] = await Promise.all([this.ctrl.getObjectInfo(), this.getViews(), this.getToggle()]);
    this.objectInfo = objectInfo;
    this.views = views;
    const [columns] = await Promise.all([this.getColumns(this.currentView), this.getMessages(), this.initFilters()]);
    this.columns = columns;
    setFormulaLinkFields(this.objectInfo.fields, this.columns);
    const [selectedRows, participantCount] = await Promise.all([this.ctrl.getExistingRecords(), getParticipantCount({ eventId: this.ctrl.eventId })]);
    this.selectedRows = selectedRows;
    this.participantCount = participantCount;
    await this.search();
  }

  async getMessages() {
    const messages = [
      { key: 'SAVE', category: 'Common', defaultMessage: 'Save' },
      { key: 'CANCEL', category: 'Common', defaultMessage: 'Cancel' },
      { key: 'SORTED_BY', category: 'Common', defaultMessage: 'Sorted by {0}' },
      { key: 'SELECTED_ROWS', category: 'Common', defaultMessage: '{0} Selected' },
      { key: 'RESULTS', category: 'Common', defaultMessage: '{0} Results' },
      { key: 'SEARCH', category: 'Common', defaultMessage: 'Search' },
      { key: 'NO_RECORDS', category: 'Common', defaultMessage: 'No records to display' },
      { key: 'REMOVE_ALL_ATTENDEE', category: 'CallReport', defaultMessage: 'Remove All' },
      { key: 'EVENT_RECORD_ADD_SUCCESS', category: 'EVENT_MANAGEMENT', defaultMessage: 'You have successfully added {0} {1} to the event.' },
      { key: 'EVENT_RECORD_ADD_FAIL', category: 'EVENT_MANAGEMENT', defaultMessage: 'You were not able to add {0} {1} to the event.' },
      { key: 'EVENT_RECORD_DELETE_SUCCESS', category: 'EVENT_MANAGEMENT', defaultMessage: 'You have successfully removed {0} {1} from the event.' },
      { key: 'EVENT_RECORD_DELETE_FAIL', category: 'EVENT_MANAGEMENT', defaultMessage: 'You were not able to remove {0} {1} from the event.' },
      { key: 'FILTER', category: 'Common', defaultMessage: 'Filter' },
      {
        key: 'EXCEEDED_MAX_ATTENDEE',
        category: 'EVENT_MANAGEMENT',
        defaultMessage: 'There are currently {0} attendees and speakers. You may still invite but Engage supports a limit of 300 guests.',
      },
      { key: 'DUPLICATE_ATTENDEES_HEADER', category: 'EVENT_MANAGEMENT', defaultMessage: 'Duplicate Attendee(s)' },
      {
        key: 'DUPLICATE_ATTENDEES_BODY',
        category: 'EVENT_MANAGEMENT',
        defaultMessage: `The following accounts cannot be added because they have been selected more than once.
          {0}
          You must remove all duplicates before you can proceed.`,
      },
      { key: 'ATTENDEE_RESULT_TRUNCATED', category: 'EVENT_MANAGEMENT', defaultMessage: 'Results truncated at {0} rows. Please refine search.' },
    ];
    messages.push(this.ctrl.pageTitleMessage);
    const [
      save,
      cancel,
      sortedBy,
      selectedRows,
      results,
      searchMsg,
      noResultsMsg,
      removeAll,
      addSuccess,
      addFailure,
      deleteSuccess,
      deleteFail,
      filter,
      exceedMaxAttendee,
      duplicateAttendeeHeader,
      duplicateAttendeeBody,
      attendeeResultTruncated,
      pageTitle,
    ] = await Promise.all(messages.map(msg => this.ctrl.getMessage(msg)));
    this.saveLabel = save;
    this.cancelLabel = cancel;
    this.sortedByVeevaMessage = sortedBy;
    this.selectedRowsVeevaMessage = selectedRows;
    this.resultsVeevaMessage = results;
    this.searchMsg = searchMsg;
    this.noResultsLabel = noResultsMsg;
    this.removeAllLabel = removeAll;
    this.addSuccessMsg = addSuccess;
    this.addFailMsg = addFailure;
    this.deleteSuccessMsg = deleteSuccess;
    this.deleteFailMsg = deleteFail;
    this.title = pageTitle;
    this.filterLabel = filter;
    this.exceedMaxAttendee = exceedMaxAttendee;
    this.duplicateAttendeeHeader = duplicateAttendeeHeader;
    this.duplicateAttendeeBody = duplicateAttendeeBody;
    this.attendeeResultTruncated = attendeeResultTruncated;
  }

  async getColumns(view) {
    const cols = (await this.ctrl.getColumns(view)) || [];
    return cols.map(column => {
      let col;
      const { fieldName } = column;
      const fieldDescribe = this.objectInfo.fields[fieldName] || {};
      if (fieldName === this.NAME_COLUMN.fieldName) {
        col = this.NAME_COLUMN;
        col.label = column.label;
      } else if (fieldName === this.CUSTOM_CHECKBOX_COLUMN.fieldName) {
        col = this.CUSTOM_CHECKBOX_COLUMN;
        this.hideCheckboxes = true;
      } else if (fieldName === this.CUSTOM_BUTTON_ICON_COLUMN.fieldName) {
        col = this.CUSTOM_BUTTON_ICON_COLUMN;
      } else if (fieldDescribe.dataType === 'Reference') {
        col = {
          label: column.label,
          fieldName,
          type: 'lookup',
          typeAttributes: {
            lookupRecord: { fieldName: fieldDescribe.relationshipName },
          },
          hideDefaultActions: true,
          sortable: Object.prototype.hasOwnProperty.call(column, 'sortable') ? column.sortable : fieldDescribe.sortable,
        };
      } else {
        col = {
          label: column.label,
          fieldName,
          type: 'text',
          hideDefaultActions: true,
          sortable: Object.prototype.hasOwnProperty.call(column, 'sortable') ? column.sortable : fieldDescribe.sortable ?? true,
        };
      }
      return col;
    });
  }

  async getViews() {
    let views = [];
    if (this.ctrl?.getViews) {
      views = await this.ctrl.getViews();
      if (views?.length > 0) {
        this.currentView = views[0].value;
        this.selectedFilters.push({ view: true, value: this.currentView });
      }
    }
    return views;
  }

  async getToggle() {
    if (this.ctrl?.getToggle) {
      this.toggle = await this.ctrl.getToggle();
      if (this.toggle) {
        this.toggledOn = false;
      }
    }
  }

  closeModal(event) {
    if (event === 'save') {
      this.exitEarly = false;
    } else {
      this.exitEarly = true;
    }
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  /* Search */
  async _search(term, data, updateColumns = false) {
    let limit = INITIAL_SEARCH_LIMIT;
    let offset = 0;
    if (data) {
      limit = LOAD_MORE_INCREMENTS;
      offset = data.length;
    }

    if (updateColumns) {
      this.columns = await this.getColumns(this.currentView);
    }
    const results = (await this.ctrl.search(term, this.selectedFilters, this.sortedBy, this.sortDirection, limit + 1, offset)) || []; // add 1 more to limit
    this.hasMoreData = results.length > limit;
    if (this.hasMoreData) {
      // if search return 1 more than limit we need to remove the last one to prevent duplicating it
      results.splice(limit, 1);
    }
    return results;
  }

  async loadMore(event) {
    if (!this.hasMoreData) {
      return;
    }
    const table = event.target;
    table.isLoading = true;
    const results = (await this._search(this.searchTerm, this.data)) || [];
    this.data = this.data.concat(this.getProcessedRecords(results));
    table.isLoading = false;
  }

  async search(updateColumns = false) {
    if (!this.searchTerm) {
      this.searchTerm = '';
    }
    if (this.searchTerm.length !== 1) {
      try {
        this.loading = true;
        this.hasMoreData = false;
        this.data = [];
        this.closePopover();
        const results = await this._search(this.searchTerm, null, updateColumns);
        this.processRecords(results);
      } finally {
        this.loading = false;
      }
    }
  }

  processRecords(results) {
    this.data = this.getProcessedRecords(results);
  }

  getProcessedRecords(results) {
    let duplicateRows = new Map();
    if (this.ctrl.getDuplicateRows) {
      duplicateRows = this.ctrl.getDuplicateRows(this.selectedRows);
    }
    return results.map(record => this.processRecord(record, duplicateRows));
  }

  processRecord(record, duplicateRows = new Map()) {
    if (this.selectedRows[record.Id]) {
      // eslint-disable-next-line no-param-reassign
      record.checked = true;
    }
    return this.ctrl.processRecord ? this.ctrl.processRecord(record, duplicateRows) : record;
  }

  updateTerm(event) {
    this.searchTerm = event.detail.value;
    window.clearTimeout(this.debounce);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.debounce = setTimeout(() => {
      this.search();
    }, VeevaConstant.DEBOUNCE_DELAY);
  }

  onHandleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
    this.search();
  }

  togglePopover(mode) {
    if (this.currentPopover === mode) {
      this.currentPopover = '';
    } else {
      this.currentPopover = mode;
    }
  }

  _closePopover() {
    this.currentPopover = '';
    this.popoverRecord = {};
  }
  closePopover = this._closePopover.bind(this);

  /* Details Popover */
  toggleDetailsPopover(event) {
    event.stopPropagation();
    if (this.popoverRecord?.Id !== event.detail.record.id) {
      const nubbin = this.nubbinPosition(event);
      this.popoverRecord = this.data.find(row => row.Id === event.detail.record.id);
      document.documentElement.style.setProperty('--selectionDetailsPopoverXCoord', `${event.detail.x}px`);
      document.documentElement.style.setProperty('--selectionDetailsPopoverYCoord', `${event.detail.y}px`);
      document.documentElement.style.setProperty('--selectionDetailsTranslateYDistance', nubbin);
      this.currentPopover = DETAILS_POP;
    } else {
      this.togglePopover(DETAILS_POP);
    }
  }

  nubbinPosition(event) {
    const rect = event.target.getBoundingClientRect();
    const positionRelativeToTable = event.detail.y - rect.top + parseInt(getComputedStyle(document.documentElement).fontSize, 10);
    const thirdOfTableHeight = rect.height / 3;
    const nubbinPositionThirds = {
      1: '35%',
      2: '50%',
      3: '80%',
    };
    let third = 1;
    while (third < 3 && positionRelativeToTable > third * thirdOfTableHeight) {
      third++;
    }
    return nubbinPositionThirds[third] || '50%';
  }

  updateData(event) {
    if (!this.actionTaken) {
      this.actionTaken = true;
    }
    const selected = event.detail.checked;
    const { id } = event.detail;
    const idx = this.data.findIndex(row => row.Id === id);
    if (idx > -1) {
      // if row is in current visible dataset
      const row = this.data[idx];
      row.checked = selected;
      if (selected) {
        this.selectedRows[id] = row;
      }
    }
    if (!selected && id) {
      // remove via popover, pill, unchecking
      delete this.selectedRows[id];
    }
    this.processRecords(this.data);
  }

  updateBulkData(newSelectedRows) {
    if (!this.actionTaken) {
      this.actionTaken = true;
    }
    this.data.forEach(row => {
      if (this.selectedRows[row.Id]) {
        delete this.selectedRows[row.Id];
        row.checked = false;
      }
    });
    newSelectedRows.forEach(row => {
      row.checked = true;
      this.selectedRows[row.Id] = row;
    });
    this.processRecords(this.data);
  }

  handleDetailsPopover(event) {
    this.updateData(event);
    this.closePopover();
  }

  /* Multi Row Selection */
  handleRemoveSelectedPill(event) {
    this.handleRowSelection(
      new CustomEvent('customrowselection', {
        detail: {
          checked: false,
          id: event.detail?.value,
        },
      })
    );
  }

  handleToggle(event) {
    this.toggledOn = event.detail.checked;
    this.search();
  }

  handleRemoveAll() {
    if (!this.actionTaken) {
      this.actionTaken = true;
    }
    this.selectedRows = {};
    this.data.forEach(row => {
      row.checked = false;
    });
    this.processRecords(this.data);
  }

  handleRowSelection(event) {
    event.stopPropagation();
    const eventDetail = event.detail;
    if (eventDetail && eventDetail.id) {
      this.updateData(event);
    } else if (eventDetail.selectedRows) {
      this.updateBulkData(eventDetail.selectedRows);
    }
  }

  async save() {
    this.loading = true;
    let abortSave = false;
    try {
      this.saving = true;
      const results = await this.ctrl.save(this.selectedRows, this.recordType);
      if (results) {
        const messages = {
          addSuccessMsg: this.addSuccessMsg,
          addFailMsg: this.addFailMsg,
          deleteSuccessMsg: this.deleteSuccessMsg,
          deleteFailMsg: this.deleteFailMsg,
        };
        this.saveResults = JSON.stringify({ ...results, messages });

        const payload = {
          key: EmEventConstant.REFRESH_RELATED_LIST,
          parentId: this.ctrl.eventId,
          relationship: this.ctrl.relatedList,
        };
        publish(this.messageContext, eventsManagementChannel, payload);
      }
    } catch (e) {
      if (e instanceof DuplicateError) {
        await this.showDuplicateErrorModal(e.records);
        return;
      }
      if (e.name === 'AbortSaveError') {
        abortSave = true;
        if (e.message) {
          this.dispatchEvent(
            new ShowToastEvent({
              message: e.message,
              variant: 'error',
            })
          );
        }
      }
    } finally {
      this.saving = false;
      this.loading = false;
    }
    if (!abortSave) {
      const save = this.saveResults !== null ? 'save' : null;
      this.closeModal(save);
    }
  }

  async showDuplicateErrorModal(attendees) {
    const [preDelimiterPart, postDelimiterPart] = this.duplicateAttendeeBody.split('{0}');
    /* eslint-disable @locker/locker/distorted-xml-http-request-window-open */
    return VeevaAlertLightningModal.open({
      title: this.duplicateAttendeeHeader,
      messages: [preDelimiterPart, ...attendees, postDelimiterPart],
      footerHorizontalAlign: 'center',
      size: 'small',
    });
  }

  /* Filters */
  async initFilters() {
    if (this.ctrl.getPreselectedFilters) {
      this.selectedFilters = await this.ctrl.getPreselectedFilters();
    }
  }

  toggleFilterPopover() {
    this.togglePopover(FILTER_POP);
  }

  saveFilters(event) {
    this.selectedFilters = event.detail.filters;
    this.search();
  }

  handleRemoveFilter(event) {
    const index = this.selectedFilters.findIndex(object => object.value === event.detail.value);
    if (index > -1) {
      this.selectedFilters.splice(index, 1);
      this.selectedFilters = this.selectedFilters.concat([]); // reassign shallow copy to update UI
      this.search();
    }
  }

  async handleViewSelect(event) {
    const index = this.selectedFilters.findIndex(object => object.view);
    if (index > -1) {
      this.selectedFilters.splice(index, 1);
    }
    const newView = event.detail.value;
    const isHierarchyAction = event.detail?.actionSource === 'hierarchy';

    const objectChanged = this.ctrl.getViewObject && this.ctrl.getViewObject(this.currentView) !== this.ctrl.getViewObject(newView);
    if (objectChanged) {
      this.objectInfo = await this.ctrl.getObjectInfo(newView);
      this.searchTerm = '';
      this.sortedBy = NAME;
      this.sortDirection = ASC;
    }
    this.toggledOn = false;
    if (!isHierarchyAction && newView !== this.currentView) {
      this.removeHierarchyViews(newView);
    }
    this.currentView = newView;
    this.selectedFilters.push({ view: true, value: newView });
    this.search(objectChanged);
  }

  removeHierarchyViews(target) {
    const isHierarchy = this.views.find(v => v.value === target).hierarchy;
    let currentView = this.views[0];
    while (currentView?.hierarchy && target !== currentView.value) {
      this.views.shift();
      [currentView] = this.views;
    }
    this.views = [].concat(this.views);
    if (!isHierarchy) {
      this.firstView = null;
    }
  }

  drillDownHierarchy(event) {
    event.stopPropagation();
    const { id } = event.detail;
    const businessAccount = this.data.find(row => row.Id === id);
    if (!this.firstView) {
      this.firstView = this.currentView;
    }
    const hierarchyView = {
      label: this.ctrl.getNameForObject(businessAccount),
      value: id,
      prefixIconName: 'utility:hierarchy',
      hierarchy: true,
    };
    this.views = [hierarchyView, ...this.views]; // add to ui tracked views
    this.searchTerm = '';
    this.handleViewSelect({
      detail: {
        value: id,
        actionSource: 'hierarchy',
      },
    });
  }

  backToParent() {
    this.views = this.views.slice(1);
    const nextView = this.views[0];
    let { value } = nextView;
    if (!nextView.hierarchy && this.firstView) {
      value = this.firstView;
      this.firstView = null;
    }
    this.searchTerm = '';
    this.handleViewSelect({
      detail: {
        value,
        actionSource: 'hierarchy',
      },
    });
  }
}