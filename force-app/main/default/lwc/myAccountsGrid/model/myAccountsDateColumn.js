import TIME_ZONE from '@salesforce/i18n/timeZone';

import MyAccountsColumn from './myAccountsColumn';

export default class MyAccountsDateColumn extends MyAccountsColumn {
  constructor(column, labels) {
    super(column, labels);
    this.sortable = this._sort;
  }

  _sort(left, right) {
    const leftDate = left.get(this.field) ? new Date(left.get(this.field)) : new Date(0, 0, 1);
    const rightDate = right.get(this.field) ? new Date(right.get(this.field)) : new Date(0, 0, 1);

    let comparison = 0;
    if (!rightDate || leftDate > rightDate) {
      comparison = 1;
    } else if (leftDate < rightDate) {
      comparison = -1;
    }
    return comparison;
  }

  _getBryntumFilterable() {
    return {
      filterField: {
        type: 'salesforcedate',
        // Prevents users from typing in dates; instead they must use the calendar picker
        editable: false,
      },
      filterFn: MyAccountsDateColumn._filterDateAndDateTime,
    };
  }

  _getBryntumType() {
    return 'date';
  }

  _getBryntumFormat() {
    const lowerCaseSFDisplayType = this.sfDisplayType?.toLowerCase();
    if (lowerCaseSFDisplayType === 'date') {
      return 'L';
    }
    if (lowerCaseSFDisplayType === 'datetime') {
      return 'L LT';
    }
    return undefined;
  }

  /**
   * A Filter Function that will be used by Date and Datetime Columns.
   * We will only filter the Date portion of Date Time columns.
   *
   * This filter function gives us control over how we want to compare the Datetime value and the selected filter
   */
  static _filterDateAndDateTime({ record, value, property, operator, column }) {
    const recordValue = record[property];
    if (!recordValue) {
      return false;
    }
    const columnFieldType = column.originalData.sfDisplayType?.toLowerCase();

    // The incoming filter value (value) is the exact date the user selected
    // Salesforce stores the exact date for Date fields
    // However when the ISO date is read by Date without a time it attempts to convert the date into the user's timezone
    let recordValueAsDate = new Date(recordValue);

    // We need update Date fields using the timezone offset to get the original ISO date provided
    if (columnFieldType === 'date') {
      const MS_IN_MINUTE = 60 * 1000;
      const recordValueTimeFactoringTimezone = recordValueAsDate.getTime() + recordValueAsDate.getTimezoneOffset() * MS_IN_MINUTE;
      recordValueAsDate = new Date(recordValueTimeFactoringTimezone);
    }

    // We will create a new Date object that only looks at the Date portion and is in the User's Timezone
    // The Date constructor is able to parse a Date String in the en-US format where we will use the User's Timezone
    let recordValueDateOnly;
    if (columnFieldType === 'date') {
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