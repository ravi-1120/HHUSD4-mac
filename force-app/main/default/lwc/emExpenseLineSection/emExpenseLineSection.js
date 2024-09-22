import { LightningElement, api, wire, track } from 'lwc';
import EmEventConstant from 'c/emEventConstant';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import { loadStyle } from 'lightning/platformResourceLoader';
import expenseLineSectionStyling from '@salesforce/resourceUrl/expenseLineSectionStyling';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';
import { getNestedFieldErrors } from 'c/veevaPageFieldErrors';

export default class EmExpenseLineSection extends VeevaErrorHandlerMixin(LightningElement) {
  @api ctrl;
  @api
  get recordUpdateFlag() {
    return this._recordUpdateFlag;
  }

  set recordUpdateFlag(value) {
    if (this._recordUpdateFlag !== undefined) {
      this.ctrl.getExpenseLines().then(records => {
        this.records = records;
      });
    }
    this._recordUpdateFlag = value;
    this.linesUpdatedFlag = !this.linesUpdatedFlag;
  }

  @track records = [];
  @track linesUpdatedFlag;

  get sectionClass() {
    return this.ctrl?.pageCtrl?.action !== 'View' && this.records.length ? 'expense-line-section-editable' : '';
  }

  columns;
  newButtonLabel;

  deleteModalLabels = {};
  disableDeleteModalButtons = false;
  recordToDelete;
  showDeleteModal = false;

  currencyModalLabels = {};
  changeCurrencyModalBody = [];
  showChangeCurrencyModal = false;

  currentElementSelector = 'c-em-expense-line-section';
  validityElementsSelector = 'c-expense-line-section-row';

  @wire(MessageContext)
  messageContext;
  subscription = null;

  async connectedCallback() {
    this.subscribeToChannel();
    [this.records, this.newButtonLabel, this.deleteModalLabels, this.currencyModalLabels, this.columns] = await Promise.all([
      this.ctrl.getExpenseLines(),
      this.ctrl.getNewButtonLabel(),
      this.ctrl.getDeleteModalLabels(),
      this.ctrl.getCurrencyModalLabels(),
      this.ctrl.getColumns(),
    ]);

    loadStyle(this, expenseLineSectionStyling);
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
    if (msg.recordId === this.ctrl.pageCtrl.id) {
      if (msg.key === EmEventConstant.EXPENSE_LINE_SECTION_UPDATE_FLAG) {
        this.linesUpdatedFlag = !this.linesUpdatedFlag;
      } else if (msg.key === EmEventConstant.EXPENSE_HEADER_CURRENCY_CHANGED) {
        this.showCurrencyModalIfNeeded(msg.value);
      }
    }
  }

  async addRow() {
    const newRecord = await this.ctrl.addExpenseLine();
    this.records = [...this.records, newRecord];
  }

  handleMenuAction(event) {
    event.stopPropagation();
    if (event.detail.action === 'Delete') {
      this.recordToDelete = event.detail.recordId;
      const record = this.records.find(x => x.id === this.recordToDelete);
      if (!record) {
        return;
      }
      if (record.record.isNew) {
        this.deleteRow(event.detail.recordId);
      } else {
        this.disableDeleteModalButtons = false;
        this.showDeleteModal = true;
      }
    }
  }

  async deleteRow(id) {
    const { success, toast } = await this.ctrl.deleteExpenseLine(id);
    if (success) {
      this.records = this.records.filter(x => x.id !== id);
    }
    if (toast) {
      this.dispatchEvent(toast);
    }
  }

  async handleDeleteConfirm(event) {
    event.stopPropagation();
    this.disableDeleteModalButtons = true;
    await this.deleteRow(this.recordToDelete);
    this.showDeleteModal = false;
  }

  handleDeleteCancel(event) {
    event.stopPropagation();
    this.showDeleteModal = false;
  }

  showCurrencyModalIfNeeded(value) {
    if (value && this.ctrl.shouldShowCurrencyModal()) {
      this.changeCurrencyModalBody = [this.currencyModalLabels.changeBodyMsg.replace('{0}', value)];
      this.showChangeCurrencyModal = true;
    }
  }

  handleChangeCurrencyConfirm(event) {
    event.stopPropagation();
    this.ctrl.updateExpenseLineCurrency();
    this.linesUpdatedFlag = !this.linesUpdatedFlag;
    this.showChangeCurrencyModal = false;
  }

  handleChangeCurrencyCancel(event) {
    event.stopPropagation();
    this.showChangeCurrencyModal = false;
  }

  @api getFieldErrors() {
    const fieldErrors = getNestedFieldErrors(this.getDataValidityElements(), this.currentElementSelector);
    // LinesUpdatedFlag signals all lines to re-render with record and line errors shown
    this.linesUpdatedFlag = !this.linesUpdatedFlag;
    return fieldErrors;
  }

  get recordsWithAlignment() {
    if (!this.records) {
        return [];
    }

    return this.records.map((record, index, array) => {
        const isLast = index === array.length - 1;
        return {
            ...record,
            menuAlign: isLast ? 'auto' : 'right',
        };
    });
  }

}