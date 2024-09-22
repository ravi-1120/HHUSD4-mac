import EmBudgetPicklistController from 'c/emBudgetPicklistController';
import EmConcurService from 'c/emConcurService';
import EmController from 'c/emController';
import EmEventConstant from 'c/emEventConstant';
import EmExpenseConstant from 'c/emExpenseConstant';
import ExpenseLineExpenseTypePicklistController from 'c/expenseLineExpenseTypePicklistController';
import VeevaConstant from 'c/veevaConstant';
import { isStatusSendingOrSubmitted } from 'c/emSubmitToConcurErrorHandling';

import LightningAlert from 'lightning/alert';
import LightningConfirm from 'lightning/confirm';
import { createMessageContext, publish } from 'lightning/messageService';
import ACTUAL from '@salesforce/schema/Expense_Line_vod__c.Actual_vod__c';
import EVENT from '@salesforce/schema/Expense_Line_vod__c.Event_vod__c';
import EVENT_BUDGET from '@salesforce/schema/Expense_Line_vod__c.Event_Budget_vod__c';
import EXPENSE_ESTIMATE from '@salesforce/schema/Expense_Line_vod__c.Expense_Estimate_vod__c';
import EXPENSE_HEADER from '@salesforce/schema/Expense_Line_vod__c.Expense_Header_vod__c';
import EXPENSE_TYPE from '@salesforce/schema/Expense_Line_vod__c.Expense_Type_vod__c';
import getEventBudgets from '@salesforce/apex/EmExpensesController.getEventBudgets';
import getExpenseLineExpenseTypes from '@salesforce/apex/EmExpensesController.getExpenseLineExpenseTypes';
import getExpenseTypeToExpenseEstimateMapping from '@salesforce/apex/EmExpensesController.getExpenseTypeToExpenseEstimateMapping';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';

import BlankFieldController from './blankFieldController';

export default class EmExpenseLineController extends EmController {
  #childTypeToParentMap = {};

  expenseHeaderPleParams;
  isSplitExpense = false;

  constructor(dataSvc, userInterface, messageSvc, metaStore, emPageLayoutEngineSvc) {
    super(dataSvc, userInterface, messageSvc, metaStore, emPageLayoutEngineSvc);
    this.concurSvc = new EmConcurService(this.dataSvc, this.uiApi);
  }

  getOptionalQueryFields() {
    const optionalQueryFields = super.getOptionalQueryFields();
    optionalQueryFields.push(`${this.objectApiName}.${EmExpenseConstant.EXPENSE_HEADER_RELATED}.${EmExpenseConstant.CONCUR_STATUS}`);
    return optionalQueryFields;
  }

  async loadMetadata() {
    this.concurStatus = this.record.rawValue(EmExpenseConstant.EXPENSE_HEADER_RELATED)?.fields?.[EmExpenseConstant.CONCUR_STATUS]?.value;
    await Promise.all([this.populateConcurMessageMap(), super.loadMetadata()]);
  }

  async populateConcurMessageMap() {
    this.concurMessageMap = await this.messageSvc
      .createMessageRequest()
      .addRequest('CONCUR_ALREADY_SENT_VIEW', 'Concur', EmExpenseConstant.CONCUR_ALREADY_SENT_DEFAULT, 'concurAlreadySent')
      .sendRequest();

    Object.entries(this.concurMessageMap).forEach(([key, message]) => {
      this[key] = message;
    });
  }

  async getPleParams() {
    return this.expenseHeaderPleParams ?? super.getPleParams();
  }

  isItemToRemove(item) {
    if (this.isSplitExpense && item.field === EXPENSE_HEADER.fieldApiName) {
      return true;
    }
    if (!this.isSplitExpense && this.record.isNew && this.objectInfo.getFieldInfo(item.field)?.calculated) {
      // keep formula columns in Expense Line table section for Payments
      return false;
    }
    return super.isItemToRemove(item);
  }

  initItemController(meta, record) {
    const { field } = meta;
    if (field) {
      const fieldDescribe = this.objectInfo.getFieldInfo(field);
      if (this.isSplitExpense && this.action === 'View' && this.record.isNew) {
        return new BlankFieldController(meta, this, fieldDescribe, record);
      }
      if (field === EXPENSE_TYPE.fieldApiName && this.action !== 'View') {
        return new ExpenseLineExpenseTypePicklistController(meta, this, fieldDescribe, record);
      }
      if (field === EVENT_BUDGET.fieldApiName && this.action !== 'View') {
        return new EmBudgetPicklistController(meta, this, fieldDescribe, record);
      }
    }
    return super.initItemController(meta, record);
  }

  async getPicklistValues(field, recordTypeId) {
    switch (field) {
      case EXPENSE_TYPE.fieldApiName:
        return this.getExpenseTypes();
      case EVENT_BUDGET.fieldApiName:
        return this.getEventBudgets();
      default:
        return super.getPicklistValues(field, recordTypeId);
    }
  }

  getExpenseTypes() {
    if (!this.expenseTypes) {
      this.expenseTypes = getExpenseLineExpenseTypes()
        .then(expenseTypeWrappers => {
          this.#childTypeToParentMap = this.getChildToParentMap(expenseTypeWrappers);
          return ExpenseLineExpenseTypePicklistController.buildPicklistValues(expenseTypeWrappers);
        })
        .catch(() => []);
    }
    return this.expenseTypes;
  }

  getChildToParentMap(expenseTypeWrappers) {
    return expenseTypeWrappers.reduce((obj, wrapper) => {
      wrapper.subTypes.forEach(subType => {
        obj[subType.Id] = wrapper.parentId;
      });
      return obj;
    }, {});
  }

  getEventBudgets() {
    if (!this.eventBudgets) {
      this.eventBudgets = getEventBudgets({ eventId: this.record.rawValue(EVENT.fieldApiName) })
        .then(budgets => EmBudgetPicklistController.buildPicklistValues(budgets))
        .catch(() => []);
    }
    return this.eventBudgets;
  }

  async save(value) {
    if (await isStatusSendingOrSubmitted(this.concurSvc, this.expenseHeaderId)) {
      this.isPopupAlreadyShown = true;
      const confirm = await this.showConcurAlreadySentConfirmPopup();
      if (confirm) {
        return {};
      }
      throw new Error();
    }
    const result = await super.save(value);
    this.refreshParent();
    return result;
  }

  /**
   * Refreshes Parent records
   */
  refreshParent() {
    const headerId = this.record.rawValue(EXPENSE_HEADER.fieldApiName);
    if (headerId) {
      this.notifyLDSCache([{ recordId: headerId }]);
    }

    [EVENT.fieldApiName, EVENT_BUDGET.fieldApiName, EXPENSE_ESTIMATE.fieldApiName].forEach(field => {
      const id = this.record.rawValue(field);
      if (id) {
        this.refreshParentRecordUi(true, id, EmEventConstant.FIELDS_EXPENSE_LINES_UPDATE_ASYNC);
      }
    });
  }

  setFieldValue(field, value, reference, record, source) {
    if (field.apiName === EXPENSE_TYPE.fieldApiName) {
      this.setExpenseTypeDependentFields(value, record);
    }
    super.setFieldValue(field, value, reference, record, source);
    if (this.isSplitExpense && field.apiName === ACTUAL.fieldApiName) {
      this.publishSplitAmountChangedMessage();
    }
  }

  setExpenseTypeDependentFields(expenseTypeId, record) {
    const dataRecord = record || this.record;

    const hasEventBudgetEditFls = this.objectInfo.updateableField(EVENT_BUDGET.fieldApiName);
    const hasExpenseEstimateEditFls = this.objectInfo.updateableField(EXPENSE_ESTIMATE.fieldApiName)

    if ((!hasEventBudgetEditFls && !hasExpenseEstimateEditFls) || (!dataRecord.rawValue(EXPENSE_TYPE.fieldApiName) && !expenseTypeId)) {
      return;
    }

    this.getExpenseTypeToExpenseEstimateMapping().then(parentExpenseToExpenseEstimateMap => {
      let budgetChanged = false;
      let estimateChanged = false;

      const parentId = this.#childTypeToParentMap[expenseTypeId];
      const estimate = parentExpenseToExpenseEstimateMap[parentId] ?? {};

      if (hasEventBudgetEditFls) {
        budgetChanged = this.updateEventBudget(dataRecord, estimate);
      }

      if (hasExpenseEstimateEditFls) {
        estimateChanged = this.updateExpenseEstimate(dataRecord, estimate);
      }

      if (budgetChanged || estimateChanged) {
        this.page.recordUpdateFlag = !this.page.recordUpdateFlag;
      }
    });
  }

  updateEventBudget(record, estimate) {
    const newBudgetId = estimate.Event_Budget_vod__c || '';
    const existingBudgetId = record.rawValue(EVENT_BUDGET.fieldApiName) || '';
    if (newBudgetId !== existingBudgetId) {
      record.setFieldValue(EVENT_BUDGET.fieldApiName, newBudgetId);
      return true;
    }
    return false;
  }

  updateExpenseEstimate(record, estimate) {
    const newEstimateId = estimate.Id || '';
    const existingEstimateId = record.rawValue(EXPENSE_ESTIMATE.fieldApiName) || '';
    if (newEstimateId !== existingEstimateId) {
      const expenseEstimateField = this.objectInfo.getFieldInfo(EXPENSE_ESTIMATE.fieldApiName);
      let reference = null;
      if (newEstimateId) {
        reference = {
          name: estimate.Expense_Type_Name_vod__c ?? estimate.Name ?? null,
          apiName: expenseEstimateField.referenceToInfos[0].apiName,
          id: newEstimateId,
        };
      }
      record.setFieldValue(expenseEstimateField, newEstimateId, reference);
      return true;
    }
    return false;
  }

  getExpenseTypeToExpenseEstimateMapping() {
    if (!this.expenseTypeToExpenseEstimateMapping) {
      this.expenseTypeToExpenseEstimateMapping = getExpenseTypeToExpenseEstimateMapping({
        eventId: this.record.rawValue(EVENT.fieldApiName),
      });
    }
    return this.expenseTypeToExpenseEstimateMapping;
  }

  publishSplitAmountChangedMessage() {
    const payload = {
      key: EmEventConstant.EXPENSE_SPLIT_AMOUNT_CHANGED,
      recordId: this.recordId,
    };
    publish(createMessageContext(), eventsManagementChannel, payload);
  }

  initTemplate(ctrl) {
    if (ctrl.fieldApiName === EXPENSE_HEADER.fieldApiName && ctrl.displayValue) {
      ctrl.editable = false;
    }
    if (ctrl.fieldApiName === VeevaConstant.FLD_CURRENCY_ISO_CODE) {
      if (this.isSplitExpense) {
        ctrl.editable = false;
      } else if (this.page.action !== 'View') {
        ctrl.required = true;
      }
    }
    return super.initTemplate(ctrl);
  }

  getEmDefaultFieldValues() {
    const defVals = super.getEmDefaultFieldValues();
    if (this.record?.rawValue('Expense_Header_vod__r')?.id) {
      defVals.Expense_Header_vod__c = {
        value: this.record.rawValue('Expense_Header_vod__r').id,
        displayValue: this.record.fields.Expense_Header_vod__r.displayValue,
      };
    } else if (this.record?.rawValue(EXPENSE_HEADER.fieldApiName)) {
      defVals.Expense_Header_vod__c = this.record.fields.Expense_Header_vod__c;
    }
    return defVals;
  }

  getHeaderButtons() {
    let buttons = this.page.layout.buttons || [];
    if (EmExpenseConstant.HIDE_BUTTONS_CONCUR_STATUSES.includes(this.concurStatus)) {
      buttons = [];
      return buttons;
    }
    return buttons;
  }

  async showConcurAlreadySentAlertPopup() {
    // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
    return LightningAlert.open({
      message: this.concurAlreadySent,
      variant: 'headerless',
    });
  }

  get expenseHeaderId() {
    return this.record?.fields?.[EmExpenseConstant.EXPENSE_HEADER]?.value;
  }

  async showConcurAlreadySentConfirmPopup() {
    // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
    return LightningConfirm.open({
      message: this.concurAlreadySent,
      variant: 'headerless',
    });
  }

  async getRedirectPageRef() {
    if (this.page.action === 'Edit' && ((await this.alreadySubmittedToConcur()) || !this.canEdit)) {
      return {
        type: 'standard__recordPage',
        attributes: {
          recordId: this.id,
          objectApiName: this.objectApiName,
          actionName: 'view',
        },
      };
    }

    return null;
  }

  async alreadySubmittedToConcur() {
    if (await isStatusSendingOrSubmitted(this.concurSvc, this.expenseHeaderId)) {
      if (!this.isPopupAlreadyShown) {
        this.isPopupAlreadyShown = true;
        await this.showConcurAlreadySentAlertPopup();
      }
      return true;
    }
    return false;
  }

  async delete() {
    if (await isStatusSendingOrSubmitted(this.concurSvc, this.expenseHeaderId)) {
      await this.showConcurAlreadySentAlertPopup();
      return {};
    }
    return super.delete();
  }
}