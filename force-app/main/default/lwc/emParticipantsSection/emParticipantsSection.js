import { LightningElement, api, wire } from 'lwc';
import EmEventConstant from 'c/emEventConstant';

import LightningAlert from 'lightning/alert';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';

const ACTION_COLUMN_WIDTH = 80;
const INFINITE_SCROLL_INCREMENT = 50;

export default class EmParticipantsSection extends LightningElement {
  @api ctrl;
  @api recordUpdateFlag;

  @wire(MessageContext)
  messageContext;

  columns = [];
  groups = [];
  labels = {};
  participants = [];
  participantsToDisplay = [];

  ready = false;
  showSelectModal = false;

  get noParticipants() {
    return this.participants.length === 0;
  }

  get numItems() {
    return this.labels.numItems?.replace('{0}', this.participants.length);
  }

  get hasMoreData() {
    return this.participants.length > this.participantsToDisplay.length;
  }

  connectedCallback() {
    this.subscribeToChannel();
    this.init();
  }

  disconnectedCallback() {
    this.unsubscribeToChannel();
  }

  subscribeToChannel() {
    if (!this.subscription) {
      this.subscription = subscribe(this.messageContext, eventsManagementChannel, message => this.handleMessage(message));
    }
  }

  unsubscribeToChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  handleMessage(msg) {
    if (msg.recordId === this.ctrl.pageCtrl.id && msg.key === EmEventConstant.EXPENSE_HEADER_CURRENCY_CHANGED) {
      this.initColumns();
    } else if (msg.recordId === this.ctrl.expenseLineId && msg.key === EmEventConstant.EXPENSE_SPLIT_AMOUNT_CHANGED) {
      this.initParticipants();
    }
  }

  async init() {
    [this.labels, this.groups] = await Promise.all([this.getLabels(), this.ctrl.getGroups()]);
    this.initParticipants();
    this.initColumns();
    this.ready = true;
  }

  async getLabels() {
    const messageMap = await this.ctrl.pageCtrl.messageSvc
      .createMessageRequest()
      .addRequest('NAME', 'TABLET', 'Name', 'name')
      .addRequest('ADD_PARTICIPANTS', 'EVENT_MANAGEMENT', 'Add Participants', 'addParticipants')
      .addRequest('NO_PARTICIPANTS', 'EVENT_MANAGEMENT', 'No Participants', 'noParticipants')
      .addRequest('SELECT_PARTICIPANTS', 'EVENT_MANAGEMENT', 'Select Participants', 'selectParticipants')
      .addRequest('SPLIT_EXPENSE_ACTUAL_REQUIRED', 'EVENT_MANAGEMENT', 'Input the actual value before splitting.', 'actualRequired')
      .addRequest('TYPE', 'Common', 'Type', 'type')
      .addRequest('STATUS', 'Common', 'Status', 'status')
      .addRequest('MEAL_OPT_IN_LABEL', 'EVENT_MANAGEMENT', 'Meal Opt In', 'mealOptIn')
      .addRequest('DELETE', 'Common', 'Delete', 'delete')
      .addRequest('ITEMS_IN_LIST', 'Common', '{0} Items', 'numItems')
      .sendRequest();

    messageMap.actual = this.ctrl.pageCtrl.expenseLineInfo.fields?.Actual_vod__c?.label ?? 'Actual';

    return messageMap;
  }

  initParticipants() {
    this.participants = this.ctrl.getParticipants();
    this.participantsToDisplay = this.participants.slice(0, Math.max(this.participantsToDisplay.length, INFINITE_SCROLL_INCREMENT));
  }

  renderMoreParticipants() {
    this.participantsToDisplay = this.participants.slice(0, this.participantsToDisplay.length + INFINITE_SCROLL_INCREMENT);
  }

  initColumns() {
    const columns = [
      {
        ...this.createColumn(this.labels.name, 'Incurred_Expense_vod__c'),
        cellAttributes: {
          iconName: { fieldName: 'icon' },
        },
      },
      {
        ...this.createColumn(this.labels.actual, 'actual'),
        type: 'currency',
        typeAttributes: {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
          ...(this.ctrl.isMultiCurrency ? { currencyCode: this.ctrl.getCurrency(), currencyDisplayAs: 'code' } : {}),
        },
      },
      this.createColumn(this.labels.type, 'toLabel_Incurred_Expense_Type_vod__c'),
      this.createColumn(this.labels.status, 'status'),
      {
        ...this.createColumn(this.labels.mealOptIn, 'mealOptIn'),
        type: 'boolean',
      },
    ];
    if (!this.ctrl.isView) {
      columns.push({
        ...this.createColumn('', 'actionLinks'),
        type: 'action',
        typeAttributes: {
          rowActions: [{ label: this.labels.delete, name: 'delete' }],
        },
        hideDefaultActions: true,
        fixedWidth: ACTION_COLUMN_WIDTH,
      });
    }
    this.columns = columns;
  }

  createColumn(label, fieldName) {
    return {
      label,
      fieldName,
      type: 'text',
      hideDefaultActions: true,
    };
  }

  checkExpenseLineActual(event) {
    if (this.ctrl.getActual() <= 0) {
      event.preventDefault();
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      LightningAlert.open({
        message: this.labels.actualRequired,
        variant: 'headerless',
      });
    }
  }

  addGroup(event) {
    const groupId = event.currentTarget.dataset.id;
    const group = this.groups.find(g => g.id === groupId);
    this.ctrl.addParticipants(group?.participants ?? []);
    this.publishSplitAmountChangedMessage();
  }

  openSelectModal() {
    this.showSelectModal = true;
  }

  handleSelectModalClose(event) {
    event.stopPropagation();
    if (event.detail?.dataStoreId) {
      this.ctrl.updateAttributionsFromDataStore(event.detail.dataStoreId);
      this.publishSplitAmountChangedMessage();
    }
    this.showSelectModal = false;
  }

  handleRowAction(event) {
    const { row, action } = event.detail;
    if (action.name === 'delete') {
      this.ctrl.deleteParticipant(row.Id);
      this.publishSplitAmountChangedMessage();
    }
  }

  publishSplitAmountChangedMessage() {
    publish(this.messageContext, eventsManagementChannel, {
      key: EmEventConstant.EXPENSE_SPLIT_AMOUNT_CHANGED,
      recordId: this.ctrl.expenseLineId,
    });
  }
}