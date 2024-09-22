import PicklistController from 'c/picklistController';
import getEstimateExpenseTypes from '@salesforce/apex/EmExpensesController.getEstimateExpenseTypes';
import EVENT from '@salesforce/schema/EM_Expense_Estimate_vod__c.Event_vod__c';

export default class EstimateExpenseTypePicklistController extends PicklistController {
  async options() {
    if (!this._metaOptions) {
      this._metaOptions = await this.getPicklistValues();
    }
    return this._metaOptions;
  }

  async getPicklistValues() {
    const picklistValues = {};
    const types =
      (await getEstimateExpenseTypes({
        eventId: this.data.rawValue(EVENT.fieldApiName),
        selectedTypeId: this.selected,
      })) || [];

    picklistValues.values = types.map(type => ({ value: type.Id, label: this.buildExpenseTypeLabel(type) }));
    picklistValues.defaultValue = null;
    return picklistValues;
  }

  // eslint-disable-next-line class-methods-use-this
  buildExpenseTypeLabel(type) {
    let labelName = type.Name;
    if (type.Expense_Code_vod__c && type.Country_vod__c) {
      labelName += `(${type.Expense_Code_vod__c}, ${type.Country_vod__r.Country_Name_vod__c})`;
    } else if (type.Expense_Code_vod__c) {
      labelName += `(${type.Expense_Code_vod__c})`;
    } else if (type.Country_vod__c) {
      labelName += `(${type.Country_vod__r.Country_Name_vod__c})`;
    }
    return labelName;
  }
}