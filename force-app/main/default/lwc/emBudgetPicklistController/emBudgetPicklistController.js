/* eslint-disable class-methods-use-this */
/* eslint-disable prefer-destructuring */
import PicklistController from 'c/picklistController';

export default class EmBudgetPicklistController extends PicklistController {
  constructor(meta, pageCtrl, field, record) {
    super(meta, pageCtrl, field, record);
    this.initMessages();
  }

  initMessages() {
    this.initMsgParams();
    this.pageCtrl.getMessageWithDefault(this._msgKey, this._msgCategory, this._noBudgetMessageDefault).then(msg => {
      this._noBudgetMessage = msg;
    });
  }

  initMsgParams() {
    if (this.pageCtrl.objectApiName === 'EM_Expense_Estimate_vod__c') {
      this._noBudgetMessageDefault = 'Please add a budget from the Event Budgets related list before creating any Expense Estimates';
      this._msgKey = 'BUDGET_REQUIRED';
      this._msgCategory = 'Event_Management';
    } else if (this.pageCtrl.objectApiName === 'Expense_Line_vod__c') {
      this._noBudgetMessageDefault = 'Please add a budget from the Event Budgets related list before creating any Expense Lines';
      this._msgKey = 'BUDGET_REQUIRED_LINES';
      this._msgCategory = 'EVENT_MANAGEMENT';
    } else {
      this._noBudgetMessageDefault = 'Error: field is required';
      this._msgKey = 'FIELD_REQUIRED';
      this._msgCategory = 'TABLET';
    }
  }

  get noBudgetMessage() {
    return this._noBudgetMessage || this._noBudgetMessageDefault;
  }

  static buildPicklistValues(values) {
    const budgetToOptions = budgets => {
      const options = [];
      budgets.forEach(budget => {
        options.push({
          value: budget.Id,
          label: budget.Budget_Name_vod__c,
        });
      });
      return options;
    };
    const picklistValues = {};
    picklistValues.values = budgetToOptions(values);

    if (picklistValues.values.length === 1) {
      picklistValues.defaultValue = picklistValues.values[0];
    } else {
      picklistValues.defaultValue = null;
    }
    return picklistValues;
  }

  /**
   * --None-- or empty option is not a valid value for required readonly picklists
   */
  validate(element) {
    let isValid = true;
    if (element.readOnly && element.required && !element.value) {
      isValid = false;
      const errors = this.pageCtrl.fieldErrors;

      errors[this.record.id] = errors[this.record.id] || {};
      errors[this.record.id].Event_Budget_vod__c = this.noBudgetMessage;
    }
    return isValid;
  }
}