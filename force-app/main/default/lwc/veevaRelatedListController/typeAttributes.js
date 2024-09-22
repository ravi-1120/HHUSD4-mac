import TIME_ZONE from '@salesforce/i18n/timeZone';

const getTypeAttributes = (objectDescribe, column) => {
  let typeAttributes = {};
  switch (column.type) {
    case 'picklist':
      typeAttributes = getPicklistColumnAttributes(objectDescribe, column);
      break;
    case 'lookup':
      typeAttributes = getLookupColumnAttributes(objectDescribe, column);
      break;
    case 'veevaCurrency':
      typeAttributes = getCurrencyColumnAttributes(column);
      break;
    case 'date':
      typeAttributes = getDateTimeColumnAttributes();
      break;
    case 'date-local':
      typeAttributes = getDateColumnAttributes();
      break;
    case 'number':
      typeAttributes = getNumberColumnAttributes(objectDescribe, column);
      break;
    case 'veevaNumber':
      typeAttributes = getVeevaNumberColumnAttributes(objectDescribe, column);
      break;
    case 'veevaTextArea':
      typeAttributes = getVeevaTextColumnAttributes(column);
      break;
    default:
      break;
  }
  return typeAttributes;
};

function getPicklistColumnAttributes(objectDescribe, column) {
  const typeAttributes = {};
  typeAttributes.context = column.fieldName;
  typeAttributes.object = objectDescribe.apiName;
  typeAttributes.recordTypeId = { fieldName: 'RecordTypeId' };
  typeAttributes.displayReadOnlyIcon = column.displayReadOnlyIcon;
  typeAttributes.editable = column.editable;
  typeAttributes.key = { fieldName: 'Id' };
  typeAttributes.initialValue = { fieldName: column.fieldName };
  return typeAttributes;
}

function getLookupColumnAttributes(objectDescribe, column) {
  const typeAttributes = {};
  typeAttributes.context = column.fieldName;
  typeAttributes.object = objectDescribe.apiName;
  typeAttributes.displayReadOnlyIcon = column.displayReadOnlyIcon;
  typeAttributes.editable = column.editable;
  typeAttributes.key = { fieldName: 'Id' };
  typeAttributes.initialValue = { fieldName: column.fieldName };
  typeAttributes.useClickEvent = true;
  return typeAttributes;
}

function getCurrencyColumnAttributes(column) {
  const typeAttributes = {};
  typeAttributes.displayReadOnlyIcon = column.displayReadOnlyIcon;
  typeAttributes.editable = column.editable;
  typeAttributes.key = { fieldName: 'Id' };
  typeAttributes.initialValue = { fieldName: column.fieldName };
  return typeAttributes;
}

function getNumberColumnAttributes(objectDescribe, column) {
  const typeAttributes = {};
  const scale = objectDescribe.fields[column.fieldName]?.scale || 0;
  typeAttributes.step = 'any';
  typeAttributes.maximumFractionDigits = scale;
  typeAttributes.minimumFractionDigits = scale;
  return typeAttributes;
}

function getVeevaNumberColumnAttributes(objectDescribe, column) {
  return {
    displayReadOnlyIcon: column.displayReadOnlyIcon,
    editable: column.editable,
    formatter: objectDescribe.fields[column.fieldName]?.dataType === 'Percent' ? 'percent-fixed' : 'number',
    scale: objectDescribe.fields[column.fieldName]?.scale || 0,
    key: { fieldName: 'Id' },
    initialValue: { fieldName: column.fieldName },
  };
}

function getVeevaTextColumnAttributes(column) {
  return {
    displayReadOnlyIcon: column.displayReadOnlyIcon,
    editable: column.editable,
    key: { fieldName: 'Id' },
    initialValue: { fieldName: column.fieldName },
  };
}

function getDateTimeColumnAttributes() {
  return {
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    timeZone: TIME_ZONE,
  };
}

function getDateColumnAttributes() {
  return {
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
  };
}

export default getTypeAttributes;