/* eslint-disable @lwc/lwc/no-async-operation */
import EmController from 'c/emController';
import EmBudgetPicklistController from 'c/emBudgetPicklistController';
import EstimateExpenseTypePicklistController from 'c/estimateExpenseTypePicklistController';
import EVENT_BUDGET from '@salesforce/schema/EM_Expense_Estimate_vod__c.Event_Budget_vod__c';
import EXPENSE_TYPE from '@salesforce/schema/EM_Expense_Estimate_vod__c.Expense_Type_vod__c';
import ESTIMATED_COST from '@salesforce/schema/EM_Event_vod__c.Estimated_Cost_vod__c';
import ESTIMATE from '@salesforce/schema/EM_Event_Budget_vod__c.Estimate_vod__c';
import EVENT from '@salesforce/schema/EM_Expense_Estimate_vod__c.Event_vod__c';
import getEventBudgets from '@salesforce/apex/EmExpensesController.getEventBudgets';

export default class EmExpenseEstimateController extends EmController {
  initItemController(meta, record) {
    const { field } = meta;
    if (field) {
      const fieldDescribe = this.objectInfo.getFieldInfo(field);
      if (field === EVENT_BUDGET.fieldApiName && this.action !== 'View') {
        return new EmBudgetPicklistController(meta, this, fieldDescribe, record);
      }
      if (field === EXPENSE_TYPE.fieldApiName && this.action !== 'View') {
        return new EstimateExpenseTypePicklistController(meta, this, fieldDescribe, record);
      }
    }
    return super.initItemController(meta, record);
  }

  async save(value) {
    const result = await super.save(value);
    this.refreshParent();
    return result;
  }

  /**
   * Refreshes Parent records
   */
  refreshParent() {
    const fieldsToPoll = [ESTIMATED_COST.fieldApiName, ESTIMATE.fieldApiName];

    [EVENT.fieldApiName, EVENT_BUDGET.fieldApiName].forEach(field => {
      const id = this.record.rawValue(field);
      if (id) {
        this.refreshParentRecordUi(true, id, fieldsToPoll);
      }
    });
  }

  async getPicklistValues(field, recordTypeId) {
    switch (field) {
      case EVENT_BUDGET.fieldApiName:
        return this.getEventBudgets();
      default:
        return super.getPicklistValues(field, recordTypeId);
    }
  }

  async getEventBudgets() {
    if (!this.eventBudgets) {
      this.eventBudgets = getEventBudgets({ eventId: this.record.rawValue(EVENT.fieldApiName) });
    }
    const response = (await this.eventBudgets) || [];
    return EmBudgetPicklistController.buildPicklistValues(response);
  }
}