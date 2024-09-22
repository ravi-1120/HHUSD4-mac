import { ALIGN_TYPES, NULL_DISPLAY_STRING } from 'c/territoryFeedbackConstants';

const MILLIS_IN_MINUTE = 60000;

// Changing this file without touching the parent `FeedbackAccountsDatatable` JS or HTML could result in build failure.

export default class ColumnUtils {
  static addParentColumnToArray(column, array) {
    addColumnToArray(column, array);
  }

  /* eslint-disable no-param-reassign */
  static addChildColumnToParent(parentColumn, childColumn) {
    if (!parentColumn.children) {
      parentColumn.children = [];
    }
    // By default, Bryntum renders a Filter menu option for parent columns despite not having any data associated with them
    parentColumn.filterable = false;
    addColumnToArray(childColumn, parentColumn.children);
  }
  /* eslint-enable no-param-reassign */

  static getFilterableColumnProperties(alignType, translator, filterFnCallback) {
    let filterableConfig = {
      filterable: {
        filterFn: filterFnCallback,
      },
    };

    switch (alignType) {
      case ALIGN_TYPES.STRING:
        break;
      case ALIGN_TYPES.BOOLEAN:
        filterableConfig = this.getComboFilterableProperties(
          [
            { value: true, text: translator.localizeField(ALIGN_TYPES.BOOLEAN, 'true') },
            { value: false, text: translator.localizeField(ALIGN_TYPES.BOOLEAN, 'false') },
          ],
          filterFnCallback
        );
        break;
      case ALIGN_TYPES.DATE:
        filterableConfig.type = 'date';
        filterableConfig.filterable.filterField = {
          type: 'date',
          // Prevents users from typing in dates; instead they must use the calendar picker
          editable: false,
        };
        break;
      case ALIGN_TYPES.DATETIME:
        // DateTime fields specifically need `type === 'date'` in order for filter inputs to display correctly
        filterableConfig.type = 'date';
        filterableConfig.filterable.filterField = {
          type: 'datetime',
          cls: 'datetime-filter-field datetime-filter-input',
          dateField: {
            editable: false,
          },
          timeField: {
            editable: false,
          },
        };
        break;
      case ALIGN_TYPES.NUMBER:
        filterableConfig.type = 'number';
        filterableConfig.filterable.filterField = {
          type: 'number',
          format: {
            locale: translator.userLocale,
          },
        };
        break;
      default:
    }

    return filterableConfig;
  }

  static getComboFilterableProperties(items, filterFnCallback) {
    const comboFilterable = {
      filterable: {
        filterField: {
          type: 'combo',
          value: '',
          items,
          // Prevents users from typing into combo filter inputs
          editable: false,
        },
      },
    };

    // A filter function is optional when the column has a `field` property defined. In this scenario, Bryntum will
    // default to filtering rows where row[field] === filterValue. Otherwise, Bryntum will use the supplied filterFnCallback.
    if (filterFnCallback) {
      comboFilterable.filterable.filterFn = filterFnCallback;
    }

    return comboFilterable;
  }

  static sort(alignType, value1, value2) {
    const convertedValue1 = convertRecordValueString(alignType, value1);
    const convertedValue2 = convertRecordValueString(alignType, value2);

    return (convertedValue1 > convertedValue2) - (convertedValue2 > convertedValue1);
  }

  static filter(alignType, recordValue, filterValue, operator) {
    const convertedRecordValue = convertRecordValueString(alignType, recordValue);
    const convertedFilterValue = convertFilterValue(alignType, filterValue);

    return compareForFilter(convertedRecordValue, convertedFilterValue, operator);
  }
}

function addColumnToArray(column, array) {
  addGlobalPropertiesToColumn(column);
  array.push(column);
}

/* eslint-disable no-param-reassign */
function addGlobalPropertiesToColumn(column) {
  column.groupable = false;
  column.hideable = false;
  column.draggable = false;
}
/* eslint-enable no-param-reassign */

function convertRecordValueString(alignType, recordValue) {
  switch (alignType) {
    case ALIGN_TYPES.STRING:
    case ALIGN_TYPES.BOOLEAN:
      return recordValue?.toString().toLowerCase() || NULL_DISPLAY_STRING;
    case ALIGN_TYPES.DATE:
    case ALIGN_TYPES.DATETIME:
      // Handles NaN when recordValue not parsed correctly.
      return new Date(recordValue).getTime() || 0;
    case ALIGN_TYPES.NUMBER:
      // Handles NaN when recordValue not parsed correctly.
      return Number.parseFloat(recordValue) || 0;
    default:
      return recordValue;
  }
}

function convertFilterValue(alignType, filterValue) {
  switch (alignType) {
    case ALIGN_TYPES.STRING:
    case ALIGN_TYPES.BOOLEAN:
      return filterValue?.toString().toLowerCase();
    case ALIGN_TYPES.DATE:
    case ALIGN_TYPES.DATETIME:
      return getTimeInUTC(filterValue);
    case ALIGN_TYPES.NUMBER:
      return filterValue;
    default:
      return filterValue;
  }
}

function compareForFilter(recordValue, filterValue, operator) {
  switch (operator) {
    case '<':
      return recordValue < filterValue;
    case '=':
    case 'sameDay':
      return recordValue === filterValue;
    case '>':
      return recordValue > filterValue;
    case '*':
      return !recordValue ? filterValue === NULL_DISPLAY_STRING : recordValue.includes(filterValue);
    default:
      return false;
  }
}

// Necessary because when a date is supplied to a filter, Bryntum parses the date in the user's timezone.
// However, we want to interpret dates exactly as how they're sent via Align.
function getTimeInUTC(date) {
  return date.getTime() - date.getTimezoneOffset() * MILLIS_IN_MINUTE;
}