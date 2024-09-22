import DefaultListViewColumn from "./defaultListViewColumn"

export default class NumberListViewColumn extends DefaultListViewColumn {

    type = 'number';

    _filterable({ record, value, operator, column }) {
        const recordValue = record[column.field].value;
        if (recordValue !== 0 && !recordValue) {
          return false;
        }
        switch (operator) {
          case '=':
            return recordValue === value;
          case '<':
            return recordValue < value;
          case '>':
            return recordValue > value;
          default:
            return false;
        }
    }
}