import PicklistController from 'c/picklistController';

export default class ExpenseLineExpenseTypePicklistController extends PicklistController {
  static buildPicklistValues(types) {
    const picklistValues = {};
    picklistValues.values = [];

    types.forEach(type => {
      type.subTypes.forEach(subType =>
        picklistValues.values.push({
          value: subType.Id,
          label: ExpenseLineExpenseTypePicklistController.formatLabel(type, subType),
        })
      );
    });

    picklistValues.defaultValue = null;
    return picklistValues;
  }

  static formatLabel = (parent, subType) => {
    const formatSubTypeLabel = sT => {
      let label = `${sT.Name}`;
      if (sT.Expense_Type_Identifier_vod__c && sT.Country_vod__c) {
        label += `(${sT.Expense_Type_Identifier_vod__c}, ${sT.Country_vod__r.Country_Name_vod__c})`;
      } else if (sT.Expense_Type_Identifier_vod__c) {
        label += `(${sT.Expense_Type_Identifier_vod__c})`;
      } else if (sT.Country_vod__c) {
        label += `(${sT.Country_vod__r.Country_Name_vod__c})`;
      }
      return label;
    };

    const subTypeLabel = formatSubTypeLabel(subType);
    if (parent.parentId === subType.Id) {
      return `${subTypeLabel}`;
    }
    return `${parent.parentName}: ${subTypeLabel}`;
  };
}