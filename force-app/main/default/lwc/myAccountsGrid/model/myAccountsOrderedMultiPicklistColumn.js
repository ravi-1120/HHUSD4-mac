import MyAccountsColumn from './myAccountsColumn';

export default class MyAccountsOrderedMultiPicklistColumn extends MyAccountsColumn {
  constructor(column) {
    super(column);
    this.picklistValues = column.picklistValues;
  }
  renderer({ value, column }) {
    if (!value || typeof value !== 'string') {
      return null;
    }

    const { picklistValues } = column.originalData;    

    const values = value.split(';');

    return picklistValues.filter(picklistValue => values.includes(picklistValue)).join(';');
  }
}