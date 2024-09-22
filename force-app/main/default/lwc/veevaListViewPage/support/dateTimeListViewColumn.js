import TIME_ZONE from '@salesforce/i18n/timeZone';
import DefaultListViewColumn from "./defaultListViewColumn";

export default class DateTimeListViewColumn extends DefaultListViewColumn {
    type = 'date';
    sfDataType;

    constructor(field, label, sfDataType) {
      super(field, label);
      this.sfDataType = sfDataType;
    }

    get _filterable() {
        return {
                filterField: {
                type: 'date',
                editable: false,
            },
            filterFn: this.dateTimeFilterFn
        }
    };

    dateTimeFilterFn({ record, value, operator, column }) {
        const recordValue = record[column.field].value;
        if (!recordValue) {
          return false;
        }

        let recordValueDateOnly;
        let recordValueAsDate = new Date(recordValue);
        if (column.originalData.sfDataType === 'date') {
          const MS_IN_MINUTE = 60 * 1000;
          const recordValueTimeFactoringTimezone = recordValueAsDate.getTime() + recordValueAsDate.getTimezoneOffset() * MS_IN_MINUTE;
          recordValueAsDate = new Date(recordValueTimeFactoringTimezone);
          recordValueDateOnly = new Date(recordValueAsDate.toLocaleDateString('en-US'));
        } else {
          recordValueDateOnly = new Date(recordValueAsDate.toLocaleDateString('en-US', { timeZone: TIME_ZONE }));
        }
        switch (operator) {
          case 'sameDay':
            return recordValueDateOnly.getTime() === value.getTime();
          case '<':
            return recordValueDateOnly.getTime() < value.getTime();
          case '>':
            return recordValueDateOnly.getTime() > value.getTime();
          default:
            return false;
        }
    }
}