import VeevaConstant from 'c/veevaConstant';
import account_record_type_icons from '@salesforce/resourceUrl/account_record_type_icons';
import USER_TIME_ZONE from '@salesforce/i18n/timeZone';


const DATATYPE_TO_DATATABLETYPE = {
  ...VeevaConstant.DATATYPE_TO_INPUTTYPE,
  Boolean: 'boolean',
  DateTime: 'date',
  Date: 'date-local',
  Picklist: 'text',
  MultiPicklist: 'text',
};

const YEAR_FORMAT = 'numeric';
const MONTH_FORMAT = '2-digit';
const DAY_FORMAT = '2-digit';

const NOT_SORTABLE_FIELDS = new Set(['TextArea', 'MultiPicklist']);

export default class GasSearchResultsFormatter {
  objectInfoMap;
  gasRecTypeIconConfig;
  columnInfo;
  searchResults;

  constructor(objectInfoMap, gasRecTypeIconConfig, columnInfo, searchResults) {
    this.objectInfoMap = objectInfoMap;
    this.gasRecTypeIconConfig = gasRecTypeIconConfig;
    this.columnInfo = columnInfo;
    this.searchResults = searchResults;
    this.fieldInfos = this.getFieldInfos();
    this.fieldsToFormat = this.getFieldsToFormat();
  }

  getColumns() {
    const columns = [];
    this.columnInfo
      .filter(columnInfo => {
        const { objectName } = columnInfo;
        const fieldName = columnInfo.fieldName.split('.')[1];
        return this.userHasAccessToField(fieldName, objectName);
      })
      .forEach(columnInfo => {
        const { fieldType } = this.fieldInfos[columnInfo.fieldName];
        // If we have not defined the dataType to Datatable Type mapping we will stick with 'text'
        const dataTableType = DATATYPE_TO_DATATABLETYPE[fieldType] ?? 'text';
        const column = {
          label: columnInfo.label,
          fieldName: columnInfo.fieldName,
          type: dataTableType,
          sortable: !NOT_SORTABLE_FIELDS.has(fieldType),
        };
        if (fieldType === 'Date' || fieldType === 'DateTime') {
          column.typeAttributes = typeAttributesForDate(fieldType);
        }
        columns.push(column);
      });
    return columns;
  }

  getSearchResults() {
    const resultSet = [];
    if (this.searchResults && this.searchResults.length > 0) {
      this.searchResults?.forEach(referenceRecord => {
        const record = { ...referenceRecord };
        record.recTypeName = record['Account.RecordTypeId.Name'];
        record.recTypeIconUrl = this.getRecordTypeIconUrl(record);

        this.fieldsToFormat
          .filter(fieldToFormat => record[fieldToFormat] != null) // checks that the field is defined
          .forEach(fieldToFormat => {
            switch (this.fieldInfos[fieldToFormat].fieldType) {
              case 'MultiPicklist':
                record[fieldToFormat] = record[fieldToFormat]?.replace(/;/g, ',');
                break;
              case 'Date':
                record[fieldToFormat] = new Date(record[fieldToFormat]).getTime();
                break;
              case 'DateTime':
                record[fieldToFormat] = new Date(record[fieldToFormat]).getTime();
                break;
              default:
                break;
            }
          });
        resultSet.push(record);
      });
    }
    return resultSet;
  }

  getFieldsToFormat() {
    return Object.keys(this.fieldInfos).filter(
      key =>
        this.fieldInfos[key].fieldType === 'MultiPicklist' ||
        this.fieldInfos[key].fieldType === 'DateTime' ||
        this.fieldInfos[key].fieldType === 'Date'
    );
  }

  getFieldInfos() {
    const fieldInfos = {};
    this.columnInfo
      ?.filter(column => column.fieldName.includes('.'))
      .map(column => column.fieldName)
      .forEach(field => {
        const parts = field.split('.');
        const objectName = parts[0];
        const fieldName = parts[1];
        if (this.userHasAccessToField(parts[1], parts[0])) {
          const fieldType = this.getFieldType(fieldName, objectName);
          fieldInfos[field] = {
            objectName,
            fieldName,
            fieldType,
          };
        }
      });
    return fieldInfos;
  }

  userHasAccessToField(fieldName, objectName) {
    return this.objectInfoMap[objectName]?.fields[fieldName] !== undefined;
  }

  getFieldType(fieldName, objectName) {
    return this.objectInfoMap[objectName]?.fields[fieldName]?.dataType ?? 'String';
  }

  getRecordTypeIconUrl(record) {
    return (
      account_record_type_icons +
      this.gasRecTypeIconConfig.getIconUrlForRecordType(
        record['Account.RecordTypeId.DeveloperName'],
        record['Account.IsPersonAccount'],
        record.insideTerritory
      )
    );
  }
}

function typeAttributesForDate(fieldType) {
  const typeAttributes = {};
  switch (fieldType) {
    case 'Date':
      typeAttributes.year = YEAR_FORMAT;
      typeAttributes.month = MONTH_FORMAT;
      typeAttributes.day = DAY_FORMAT;
      break;
    case 'DateTime':
      typeAttributes.year = YEAR_FORMAT;
      typeAttributes.month = MONTH_FORMAT;
      typeAttributes.day = DAY_FORMAT;
      typeAttributes.hour = '2-digit';
      typeAttributes.minute = '2-digit';
      typeAttributes.timeZone = USER_TIME_ZONE;
      break;
    default:
      break;
  }
  return typeAttributes;
}