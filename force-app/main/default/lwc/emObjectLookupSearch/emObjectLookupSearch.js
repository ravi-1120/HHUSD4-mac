import VeevaUtils from 'c/veevaUtils';
import EmEventConstant from 'c/emEventConstant';
import getLookupRequiredId from './emObjectLookupSearchUtils';

let _isEnhancedLookupEnabled;

const emLookupGetQueryParams = (term, ctrl) => ({
  q: term,
  field: ctrl.field.apiName,
  refTo: ctrl.targetSObject,
  id: ctrl.data.rawValue(getLookupRequiredId(ctrl.objectApiName, ctrl.field.apiName)),
  recordType: ctrl.data.rawValue('RecordType')?.fields?.DeveloperName?.value ?? '',
  sobject: ctrl.objectApiName,
});

const getColumnType = column => {
  let type = 'text';
  if (column.name === 'Name') {
    type = 'nameLink';
  } else if (column.checkbox) {
    type = 'boolean';
  }
  return type;
};

const emLookupToSearchRecord = (record, columns) => {
  const result = { id: record.Id, apiName: record.type, icon: VeevaUtils.getIconHardcoded(record.type) };
  result.name = record[EmEventConstant.OBJECT_TO_NAME_FIELD[record.type]] || record.Name || '';
  if (columns) {
    columns.forEach(column => {
      const { fieldName } = column;
      if (column.isLookup) {
        const [parentObj, lookupField] = fieldName.split('-');
        if (parentObj.endsWith('__c')) {
          result[fieldName] = record[`${parentObj.slice(0, -1)}r`]?.[lookupField];
        } else {
          result[fieldName] = record[parentObj]?.[lookupField];
        }
      }
      if (column.type === 'boolean') {
        result[fieldName] = record[fieldName] === 'true' || record[fieldName] === true;
      }
      if (!(fieldName in result)) {
        result[fieldName] = record[fieldName];
      }
    });
  }
  return result;
};

const toSearchColumn = column => ({
  label: column.label,
  fieldName: column.lookup ? `${column.name}-${column.lookupField ?? 'Name'}` : column.name,
  type: getColumnType(column),
  ...(column.name === 'Name' && { typeAttributes: { id: { fieldName: 'id' } } }),
  isLookup: column.lookup,
});

const getQueryParamsWithOffset = (ctrl, term, offset) => {
  const queryParams = ctrl.getQueryParams(term);
  if (offset) {
    queryParams.offset = offset;
  }
  return queryParams;
};

const executeSearch = async (objectApiName, queryParams, ctrl, searchMethod, extraParams) => {
  const response = await searchMethod(objectApiName, queryParams, extraParams);
  ctrl.setColumns(response.metadata?.map(column => toSearchColumn(column)));
  response.records = response.payload?.map(payloadRecord => ctrl.toSearchRecord(payloadRecord));
  response.count = response.records?.length;
  return response;
};

const emLookupSearch = async (term, ctrl, offset) => {
  const { lookupDataSvc, objectApiName } = ctrl;
  let response;

  if (term?.length === 1) {
    return {};
  }

  try {
    const enhancedLookupEnabled = await isEnhancedLookupEnabled(lookupDataSvc);
    let enhancedFilterParams;

    if (enhancedLookupEnabled) {
      const lookupFilters = await ctrl.lookupDataSvc.getLookupFiltersForObject(objectApiName);
      enhancedFilterParams = getEnhancedFilterParams(lookupFilters, ctrl);
    }

    const queryParams = getQueryParamsWithOffset(ctrl, term, offset);
    const extraParams = enhancedFilterParams ? { enhancedFilterParams, ...(queryParams.location ? { location: queryParams.location } : {}) } : {};

    response = await executeSearch(
      objectApiName,
      queryParams,
      ctrl,
      enhancedFilterParams ? lookupDataSvc.enhancedSearch.bind(lookupDataSvc) : lookupDataSvc.search.bind(lookupDataSvc),
      extraParams
    );
  } catch (err) {
    response = {};
  }
  return response;
};

const venueSearch = async (term, ctrl, offset) => {
  const { lookupDataSvc, objectApiName } = ctrl;
  let response;

  if (term?.length === 1) {
    return {};
  }

  try {
    const queryParams = getQueryParamsWithOffset(ctrl, term, offset);
    response = await executeSearch(objectApiName, queryParams, ctrl, lookupDataSvc.venueSearch.bind(lookupDataSvc));
  } catch (err) {
    response = {};
  }
  return response;
};

async function isEnhancedLookupEnabled(lookupDataSvc) {
  if (_isEnhancedLookupEnabled === undefined) {
    _isEnhancedLookupEnabled = await lookupDataSvc.isEnhancedLookupEnabled();
  }
  return _isEnhancedLookupEnabled;
}

function getEnhancedFilterParams(lookupFilters, ctrl) {
  const lookupFilterName = `${ctrl.objectApiName}.${ctrl.field.apiName}`;
  const filterParams = lookupFilters[lookupFilterName];

  if (!filterParams) {
    return undefined;
  }

  const enhancedFilterParams = {
    ...filterParams,
    Predicate: filterParams.Predicate ?? null,
    params: filterParams.params.reduce((obj, param) => {
      obj[param] = ctrl.record.rawValue(param);
      return obj;
    }, {}),
  };

  return enhancedFilterParams;
}

const getColumnsAndSearch = async (ctrl, term) => {
  const response = await ctrl.search(term, 0);
  const columns = await ctrl.getColumns();
  return { columns, response };
};

const searchWithColumns = async (ctrl, term, offset) => {
  const response = await ctrl.search(term, offset);
  response.records = await ctrl.parseForColumns(response.records);
  return response;
};

// eslint-disable-next-line no-unused-vars
const getInfiniteLoadingParam = (response, records) => records.length;

const isInfiniteLoadingEnabled = response => response.records?.length;

const getRecentLabel = async (ctrl, targetObjectInfo) => {
  const recentMessage = await ctrl.pageCtrl.getMessageWithDefault('RESULTS', 'Common', '{0} Results');
  return recentMessage.replace('{0}', targetObjectInfo.label);
};

export {
  emLookupGetQueryParams,
  getColumnType,
  emLookupToSearchRecord,
  toSearchColumn,
  emLookupSearch,
  venueSearch,
  getColumnsAndSearch,
  searchWithColumns,
  getInfiniteLoadingParam,
  isInfiniteLoadingEnabled,
  getRecentLabel,
};