import EmExpenseLineController from 'c/emExpenseLineController';
import VeevaConstant from 'c/veevaConstant';
import VeevaSectionController from 'c/veevaSectionController';
import EVENT from '@salesforce/schema/Expense_Header_vod__c.Event_vod__c';
import EmEventConstant from 'c/emEventConstant';
import EmExpenseConstant from 'c/emExpenseConstant';
import { createMessageContext, publish } from 'lightning/messageService';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import template from './emExpenseLineSectionController.html';

const MAX_COLUMNS = 10;

const HIDDEN_DATA_TYPES = ['EncryptedString', 'Location', 'Time'];

const HIDDEN_FIELDS = [
  'Concur_Response_Timestamp_vod__c',
  'Concur_System_ID_vod__c',
  'CreatedById',
  'Event_vod__c',
  'Expense_Estimate_vod__c',
  'Expense_Header_vod__c',
  'Expense_Type_Code_vod__c',
  'Expense_Type_Name_vod__c',
  'External_ID_vod__c',
  'LastModifiedById',
  'Mobile_ID_vod__c',
  'Name',
  'Number_Of_People_vod__c',
  'Override_Lock_vod__c',
  'Parent_Expense_Type_Code_vod__c',
  'Parent_Expense_Type_Name_vod__c',
  'RecordTypeId',
  'Split_Amount_Per_Person_vod__c',
];

export default class EmExpenseLineSectionController extends VeevaSectionController {
  #initPromise;
  constructor(meta, pageCtrl) {
    super(meta, pageCtrl);
    this.expenseLineInfo = meta.expenseLineInfo;
    this.#initPromise = this.init();
  }

  initTemplate() {
    this.template = template;
    return this;
  }

  get isView() {
    return this.pageCtrl.page.action === 'View';
  }

  async init() {
    this.createExpenseLinePageCtrls();
    await Promise.all([this.newExpenseLineCtrl.initPageLayout(), this.loadMessages()]);
    this.setLayoutFields();
    this.createExpenseLineColumns();
  }

  async loadMessages() {
    [
      this.cancelLabel,
      this.deleteLabel,
      this.deleteConfirmMsg,
      this.newObjectMsg,
      this.updateCurrencyLabel,
      this.changeCurrencyMsg,
      this.noLabel,
      this.yesLabel,
    ] = await Promise.all([
      this.pageCtrl.getMessageWithDefault('CANCEL', 'Common', 'Cancel'),
      this.pageCtrl.getMessageWithDefault('DELETE', 'Common', 'Delete'),
      this.pageCtrl.getMessageWithDefault('GENERIC_DELETE_BODY', 'Common', 'Are you sure you want to delete this {0}?'),
      this.pageCtrl.getMessageWithDefault('NEW_OBJECT', 'TABLET', 'New {0}'),
      this.pageCtrl.getMessageWithDefault('UPDATE_CURRENCY', 'EVENT_MANAGEMENT', 'Update Currency?'),
      this.pageCtrl.getMessageWithDefault(
        'CURRENCY_CHANGE_LINES',
        'EVENT_MANAGEMENT',
        'Would you like to also change the currency of existing expense lines to {0}?'
      ),
      this.pageCtrl.getMessageWithDefault('NO', 'Common', 'No'),
      this.pageCtrl.getMessageWithDefault('YES', 'Common', 'Yes'),
    ]);
  }

  createExpenseLineColumns() {
    this.newExpenseLineColumns = [];
    this.newExpenseLineCtrl.page.layout?.sections?.forEach(section => {
      const columns = [[], []];
      section.layoutRows.forEach(row => {
        row.layoutItems.forEach((item, index) => {
          const fieldDescribe = this.expenseLineInfo.fields?.[item.field] ?? {};
          if (item.label && !HIDDEN_FIELDS.includes(item.field) && !HIDDEN_DATA_TYPES.includes(fieldDescribe.dataType)) {
            columns[index].push({
              ...item,
              apiName: item.field,
              labelHidden: true,
              required: !this.isView && (item.required || item.field === VeevaConstant.FLD_CURRENCY_ISO_CODE),
            });
          }
        });
      });
      this.newExpenseLineColumns.push(...columns[0], ...columns[1]);
    });
    if (this.newExpenseLineColumns.length > MAX_COLUMNS) {
      this.newExpenseLineColumns = this.newExpenseLineColumns.slice(0, MAX_COLUMNS);
    }
    if (this.isView) {
      this.newExpenseLineColumns.unshift({
        apiName: 'Name',
        isName: true,
        label: this.expenseLineInfo.fields?.Name?.label ?? 'Name',
      });
    }
    this.existingExpenseLineColumns = this.newExpenseLineColumns.map(column => ({
      ...column,
      editable: this.isView ? false : column.editableForUpdate,
    }));
  }

  createExpenseLinePageCtrls() {
    const expenseLineRecordType = this.pageCtrl.expenseLineRecordType ?? this.expenseLineInfo.defaultRecordTypeId;
    const record = {
      apiName: this.expenseLineInfo.apiName,
      fields: { RecordTypeId: { value: expenseLineRecordType } },
      recordTypeId: expenseLineRecordType,
    };
    record.fields[EVENT.fieldApiName] = this.pageCtrl.record.value(EVENT.fieldApiName);

    this.newExpenseLineCtrl = new EmExpenseLineController(
      this.pageCtrl.dataSvc,
      this.pageCtrl.uiApi,
      this.pageCtrl.messageSvc,
      this.pageCtrl.metaStore,
      this.pageCtrl.emPageLayoutEngineSvc
    );
    this.newExpenseLineCtrl.objectInfo = this.expenseLineInfo;
    this.newExpenseLineCtrl.page = this.getProxiedPage({
      action: 'New',
      recordUpdateFlag: false,
      headerId: this.pageCtrl.id,
    });
    this.newExpenseLineCtrl.record = record;

    this.existingExpenseLineCtrl = new EmExpenseLineController(
      this.pageCtrl.dataSvc,
      this.pageCtrl.uiApi,
      this.pageCtrl.messageSvc,
      this.pageCtrl.metaStore
    );
    this.existingExpenseLineCtrl.objectInfo = this.expenseLineInfo;
    this.existingExpenseLineCtrl.page = this.getProxiedPage({
      action: this.isView ? 'View' : 'Edit',
      recordUpdateFlag: false,
      headerId: this.pageCtrl.id,
    });
    this.existingExpenseLineCtrl.record = record;
  }

  getProxiedPage = page => {
    const handler = {
      set(obj, prop, value) {
        if (prop === 'recordUpdateFlag') {
          const payload = {
            key: EmEventConstant.EXPENSE_LINE_SECTION_UPDATE_FLAG,
            recordId: obj.headerId,
          };
          publish(createMessageContext(), eventsManagementChannel, payload);
        }
        obj[prop] = value;
        return true;
      },
    };
    return new Proxy(page, handler);
  };

  setLayoutFields() {
    this.existingExpenseLineCtrl.layoutFields = this.newExpenseLineCtrl.layoutFields;
  }

  async getExpenseLines() {
    await this.#initPromise;
    const expenseLines = await this.pageCtrl.getExpenseLines();
    const deleteButton = this.newExpenseLineCtrl.page.layout.buttons.find(button => button.name === 'Delete');
    const alreadySubmittedToConcur = EmExpenseConstant.HIDE_BUTTONS_CONCUR_STATUSES.includes(this.pageCtrl.getConcurStatus());
    expenseLines.forEach(line => {
      if (!line.record.isNew && !line.columns) {
        this.existingExpenseLineCtrl.updateReferenceFields(line.record);
        line.columns = this.existingExpenseLineColumns;
        line.pageCtrl = this.existingExpenseLineCtrl;
        line.actions = deleteButton && !alreadySubmittedToConcur && this.expenseLineInfo.deletable ? [deleteButton] : [];
        line.url = `/${line.record.id}`;
      }
    });
    return [...expenseLines];
  }

  async getNewButtonLabel() {
    await this.#initPromise;
    if (this.expenseLineInfo.createable && !this.isView) {
      return this.newObjectMsg.replace('{0}', this.expenseLineInfo.label);
    }
    return null;
  }

  async addExpenseLine() {
    const newExpenseLine = await this.pageCtrl.createNewExpenseLine();
    newExpenseLine.actions = [{ label: this.deleteLabel, name: 'Delete' }];
    newExpenseLine.columns = this.newExpenseLineColumns;
    newExpenseLine.pageCtrl = this.newExpenseLineCtrl;
    return newExpenseLine;
  }

  deleteExpenseLine(id) {
    return this.pageCtrl.deleteExpenseLine(id);
  }

  async getColumns() {
    await this.#initPromise;
    return this.newExpenseLineColumns;
  }

  async getDeleteModalLabels() {
    await this.#initPromise;
    return {
      body: [this.deleteConfirmMsg.replace('{0}', this.expenseLineInfo.label)],
      cancel: this.cancelLabel,
      delete: this.deleteLabel,
      header: `${this.deleteLabel} ${this.expenseLineInfo.label}`,
    };
  }

  async getCurrencyModalLabels() {
    await this.#initPromise;
    return {
      changeBodyMsg: this.changeCurrencyMsg,
      changeHeader: this.updateCurrencyLabel,
      no: this.noLabel,
      yes: this.yesLabel,
    };
  }

  shouldShowCurrencyModal() {
    return this.pageCtrl.hasCurrencyDiscrepancy();
  }

  updateExpenseLineCurrency() {
    this.pageCtrl.updateExpenseLineCurrency();
  }

  clearPageCtrlErrors() {
    this.existingExpenseLineCtrl.clearErrors();
    this.newExpenseLineCtrl.clearErrors();
  }
}