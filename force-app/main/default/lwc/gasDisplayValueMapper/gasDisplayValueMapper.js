import VeevaRecord from 'c/veevaRecord';

export default class GasDisplayValueMapper {
  constructor(veevaUserInterfaceApi) {
    this.veevaUserInterfaceApi = veevaUserInterfaceApi;
  }

  async generateDisplayValueMap(fieldsWithValues, pageCtrlsByObjectName) {
    const displayValuesByFieldKey = {};
    const recordIdsToLookup = [];
    const objectNameFieldsToLookup = [];
    const picklistValuesByFieldKey = await getPicklistValuesByFieldKey(fieldsWithValues, pageCtrlsByObjectName);

    fieldsWithValues
      .filter(({ objectApiName, fieldApiName }) => getObjectInfo(objectApiName, pageCtrlsByObjectName)?.getFieldInfo(fieldApiName))
      .forEach(({ key, fieldApiName, objectApiName, value }) => {
        const pageCtrl = pageCtrlsByObjectName[objectApiName];
        const picklistValues = picklistValuesByFieldKey[key];
        const fieldInfo = pageCtrl.objectInfo.getFieldInfo(fieldApiName);
        const { dataType } = fieldInfo;

        if (!(key in displayValuesByFieldKey)) {
          displayValuesByFieldKey[key] = {};
        }
        switch (dataType) {
          case 'Picklist':
            picklistValues?.forEach(picklistValue => {
              displayValuesByFieldKey[key][picklistValue.value] = picklistValue.label;
            });
            break;
          case 'Reference':
            if (shouldLookupRecordId(fieldApiName)) {
              recordIdsToLookup.push(value);
              objectNameFieldsToLookup.push(getObjectNameFieldToLookup(fieldInfo));
            }
            Object.entries(getDisplayValuesForReferenceField(fieldApiName, pageCtrl, value)).forEach(([recordId, displayValue]) => {
              displayValuesByFieldKey[key][recordId] = displayValue;
            });
            break;
          default:
            displayValuesByFieldKey[key][value] = value;
            break;
        }
      });

    const possibleNameFields = objectNameFieldsToLookup.map(fieldName => fieldName.split('.')[1]);
    const recordIdLabels = await getLabelsForRecordId(recordIdsToLookup, objectNameFieldsToLookup, possibleNameFields, this.veevaUserInterfaceApi);
    const updatedDisplayValuesByFieldKey = updateDisplayValuesByFieldKeyUsingRecordIdDisplayValues(displayValuesByFieldKey, recordIdLabels);
    return updatedDisplayValuesByFieldKey;
  }
}

async function getLabelsForRecordId(lookupIdsRef, lookupObjectFieldNamesRef, possibleNameFields, veevaUserInterfaceApi) {
  const recordIdToLabel = {};

  if (lookupIdsRef.length > 0 && lookupObjectFieldNamesRef.length > 0) {
    const lookupIds = [...new Set(lookupIdsRef)]; // only unique lookup ids
    const lookupObjectFieldNames = [...new Set(lookupObjectFieldNamesRef)]; // only unique lookup object field names
    const records = await veevaUserInterfaceApi.getBatchRecords(lookupIds, lookupObjectFieldNames);
    records.forEach(record => {
      const nameField = possibleNameFields.find(nameFieldOption => record.fields[nameFieldOption] != null);
      const nameFieldValue = record.fields[nameField];
      recordIdToLabel[record.id] = nameFieldValue.displayValue ?? nameFieldValue.value;
    });
  }

  return recordIdToLabel;
}

async function getPicklistValuesByFieldKey(fieldsWithValues, pageCtrlsByObjectName) {
  const picklistValuesByFieldKey = {};

  // Disabling the no-restricted-syntax because ESLint complains about the usage of a for loop instead of a Array.prototype.forEach
  // We choose to use the for loop here to allow us to await the picklistValues
  // eslint-disable-next-line no-restricted-syntax
  for (const fieldWithValues of fieldsWithValues) {
    const { key, objectApiName, fieldApiName } = fieldWithValues;
    const fieldInfo = getObjectInfo(objectApiName, pageCtrlsByObjectName).getFieldInfo(fieldApiName);
    if (fieldInfo?.dataType === 'Picklist') {
      const pageCtrl = pageCtrlsByObjectName[objectApiName];
      // We need to await the picklistValues
      // eslint-disable-next-line no-await-in-loop
      const picklistValues = await pageCtrl.getPicklistValues(fieldApiName, VeevaRecord.MASTER_RECORD_TYPE_ID);
      picklistValuesByFieldKey[key] = picklistValues.values;
    }
  }
  return picklistValuesByFieldKey;
}

function updateDisplayValuesByFieldKeyUsingRecordIdDisplayValues(displayValuesByFieldKey, recordIdDisplayValues) {
  const updatedLabelOptionsByField = {};

  Object.entries(displayValuesByFieldKey).forEach(([fieldKey, displayValuesByValue]) => {
    const displayValuesByRecordIds = { ...displayValuesByValue };
    Object.entries(recordIdDisplayValues)
      .filter(([recordId]) => recordId in displayValuesByValue)
      .forEach(([recordId, recordIdDisplayValue]) => {
        displayValuesByRecordIds[recordId] = recordIdDisplayValue;
      });
    // Overwrite labelOptionsByField for fieldKey using optionsWithUpdatedRecordIdLabels
    updatedLabelOptionsByField[fieldKey] = displayValuesByRecordIds;
  });

  return updatedLabelOptionsByField;
}

function getDisplayValuesForReferenceField(fieldApiName, pageCtrl, value) {
  const displayValues = {};
  if ('RecordTypeId' === fieldApiName) {
    Object.entries(pageCtrl.objectInfo.recordTypeInfos).forEach(([recordTypeId, recordTypeInfo]) => {
      displayValues[recordTypeId] = recordTypeInfo.name;
    });
  } else {
    displayValues[value] = value;
  }
  return displayValues;
}

function shouldLookupRecordId(fieldApiName) {
  return 'RecordTypeId' !== fieldApiName;
}

function getObjectNameFieldToLookup(fieldInfo) {
  const referenceToInfo = fieldInfo.referenceToInfos[0];
  const { nameFields } = referenceToInfo;
  return `${referenceToInfo.apiName}.${nameFields[nameFields.length - 1]}`;
}

function getObjectInfo(objectApiName, pageCtrlsByObjectName) {
  return pageCtrlsByObjectName[objectApiName]?.objectInfo;
}