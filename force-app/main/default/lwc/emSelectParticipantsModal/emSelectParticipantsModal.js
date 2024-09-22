import { LightningElement, api, track } from 'lwc';
import EmEventConstant from 'c/emEventConstant';
import VeevaConstant from 'c/veevaConstant';
import VeevaUtils from 'c/veevaUtils';
import SelectParticipantsModalController from './selectParticipantsModalController';

const ASC = 'asc';
const INFINITE_SCROLL_INCREMENT = 50;
const NAME = 'Name';

export default class EmSelectParticipantsModal extends LightningElement {
  @api pageCtrl;

  @track attributions = [];

  columns = [];
  currentView;
  hasMoreData = false;
  labels = {};
  results = [];
  searching = true;
  searchTerm = '';
  sortDirection = ASC;
  sortedBy;
  views = [];

  get loading() {
    return this.searching && !this.results.length;
  }

  get noResults() {
    return !this.searching && !this.results.length;
  }

  get selectedRows() {
    return this.attributions.filter(row => !row.Deleted);
  }

  get selectedRowsPills() {
    return this.selectedRows.sort((a, b) => {
      const aName = a.Incurred_Expense_vod__c ?? '';
      const bName = b.Incurred_Expense_vod__c ?? '';
      return aName.localeCompare(bName);
    });
  }

  get selectedRowsIds() {
    return this.selectedRows.map(row => row.participantId);
  }

  get searchPlaceholder() {
    let placeholder = '';
    if (this.labels.search) {
      placeholder = `${this.labels.search} ${this.views.find(v => v.value === this.currentView)?.label}...`;
    }
    return placeholder;
  }

  get numResults() {
    let num = this.results.length;
    if (this.hasMoreData) num += '+';
    return this.labels.numResults?.replace('{0}', num);
  }

  get numSelected() {
    let selected = '';
    if (this.labels.numSelected) {
      selected = `• ${this.labels.numSelected?.replace('{0}', this.selectedRows.length)}`;
    }
    return selected;
  }

  get sortedByLabel() {
    let label = '';
    if (this.sortedBy && this.columns.length) {
      label = `• ${this.labels.sortedBy?.replace('{0}', this.columns.find(c => c.fieldName === this.sortedBy)?.label ?? this.sortedBy)}`;
    }
    return label;
  }

  get sortDirectionIcon() {
    let icon = '';
    if (this.sortedBy && this.columns.length) {
      icon = this.sortDirection === 'desc' ? 'utility:down' : 'utility:up';
    }
    return icon;
  }

  connectedCallback() {
    this.init();
  }

  async init() {
    this.ctrl = new SelectParticipantsModalController(this.pageCtrl);
    await Promise.all([this.loadLabels(), this.initViews()]);
    // force rerender before rendering pills
    await new Promise(resolve => {
      // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
      setTimeout(resolve, 0);
    });
    this.attributions = this.ctrl.getInitialSelection();
    this.initSearch();
  }

  async loadLabels() {
    this.labels = await this.pageCtrl.messageSvc
      .createMessageRequest()
      .addRequest('SAVE', 'Common', 'Save', 'save')
      .addRequest('CANCEL', 'Common', 'Cancel', 'cancel')
      .addRequest('SORTED_BY', 'Common', 'Sorted by {0}', 'sortedBy')
      .addRequest('SELECTED_ROWS', 'Common', '{0} Selected', 'numSelected')
      .addRequest('RESULTS', 'Common', '{0} Results', 'numResults')
      .addRequest('SEARCH', 'Common', 'Search', 'search')
      .addRequest('NO_RECORDS', 'Common', 'No records to display', 'noRecords')
      .addRequest('REMOVE_ALL_ATTENDEE', 'CallReport', 'Remove All', 'removeAll')
      .addRequest('SELECT_PARTICIPANTS', 'EVENT_MANAGEMENT', 'Select Participants', 'selectParticipants')
      .sendRequest();
  }

  async initViews() {
    this.views = await this.ctrl.getViews();
    this.currentView = this.views[0]?.value;
    this.sortedBy = EmEventConstant.OBJECT_TO_NAME_FIELD[this.currentView] ?? NAME;
  }

  handleViewSelect(event) {
    this.currentView = event.detail.value;
    this.searchTerm = '';
    this.columns = [];
    this.sortedBy = EmEventConstant.OBJECT_TO_NAME_FIELD[this.currentView] ?? NAME;
    this.sortDirection = ASC;
    this.initSearch();
  }

  updateTerm(event) {
    this.searchTerm = event.detail.value;
    window.clearTimeout(this.debounce);
    // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
    this.debounce = setTimeout(() => {
      this.initSearch();
    }, VeevaConstant.DEBOUNCE_DELAY);
  }

  handleRemoveAll() {
    this.attributions.forEach(row => {
      row.Deleted = 'true';
    });
  }

  handleRemoveSelectedPill(event) {
    this.deleteParticipant(event.detail.value);
  }

  addParticipant(participant) {
    const existingParticipant = this.attributions.find(row => row.participantId === participant.participantId);
    if (existingParticipant) {
      delete existingParticipant.Deleted;
    } else {
      this.attributions.push({
        ...participant,
        Id: VeevaUtils.getRandomId(),
        mealOptIn: participant.Meal_Opt_In_vod__c,
        status: participant.Status_vod__c,
      });
    }
  }

  deleteParticipant(participantId) {
    const participant = this.attributions.find(row => row.participantId === participantId);
    if (participant) {
      participant.Deleted = 'true';
    }
  }

  handleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
    this.initSearch();
  }

  handleRowSelection(event) {
    const { selectedRows } = event.detail;
    const existingSelection = new Set(this.selectedRowsIds);
    const newSelection = new Set(selectedRows.map(row => row.participantId));
    this.results.forEach(row => {
      if (existingSelection.has(row.participantId) && !newSelection.has(row.participantId)) {
        this.deleteParticipant(row.participantId);
      } else if (!existingSelection.has(row.participantId) && newSelection.has(row.participantId)) {
        this.addParticipant(row);
      }
    });
  }

  async performSearch(setColumns = false) {
    this.rejectCancelSearchPromise?.('cancel search');
    const cancelSearchPromise = new Promise((_resolve, reject) => {
      this.rejectCancelSearchPromise = reject;
    });
    this.searching = true;
    try {
      const { columns = [], records = [] } = await Promise.race([
        this.ctrl.search(this.currentView, this.searchTerm, this.results.length, INFINITE_SCROLL_INCREMENT, this.sortedBy, this.sortDirection),
        cancelSearchPromise,
      ]);

      if (setColumns) {
        this.columns = columns;
      }
      this.results = this.results.concat(records);

      this.hasMoreData = records.length === INFINITE_SCROLL_INCREMENT;

      this.searching = false;
    } catch (error) {
      // ignore
    }
  }

  async initSearch() {
    if (this.searchTerm.length === 1) {
      return;
    }
    this.hasMoreData = false;
    this.results = [];
    await this.performSearch(true);
  }

  async loadMore(event) {
    const table = event.target;
    table.isLoading = true;
    await this.performSearch();
    table.isLoading = false;
  }

  save() {
    const dataStoreId = this.ctrl.saveAttributions(this.attributions);
    this.closeModal(dataStoreId);
  }

  handleClose(event) {
    event.stopPropagation();
    this.closeModal();
  }

  closeModal(dataStoreId) {
    this.dispatchEvent(new CustomEvent('close', { detail: { dataStoreId } }));
  }
}