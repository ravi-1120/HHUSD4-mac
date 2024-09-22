import EVENT_OBJ from '@salesforce/schema/EM_Event_vod__c';
import EVENT_STATUS_FLD from '@salesforce/schema/EM_Event_vod__c.Status_vod__c';
import EVENT_CONFIGURATION_ID_FLD from '@salesforce/schema/EM_Event_vod__c.Event_Configuration_vod__c';
import EVENT_COUNTRY_CODE from '@salesforce/schema/EM_Event_vod__c.Country_vod__r.Alpha_2_Code_vod__c';

const PLE_ERROR = {
  READONLY: 'readonly',
  REQUIRED: 'required',
};

const createBaseApiFormattedError = (objectApiName, recordId, updateErrors) => {
  const error = {
    [objectApiName]: {
      Id: recordId,
    },
    updateErrors,
  };
  return error;
};

const createFieldUpdateErrors = (fields, message, objectInfo) => {
  const fieldLabels = fields.map(field => objectInfo.fields[field].label);
  return {
    fields,
    message: message.replace('{0}', fieldLabels.join(', ')),
  };
};

const createErrorObjectFromFieldErrors = (id, failedFieldErrors, messages, objectDescribe) => {
  const readonlyFields = [];
  const requiredFields = [];

  failedFieldErrors.forEach(fieldError => {
    if (fieldError.errorType === PLE_ERROR.READONLY) {
      readonlyFields.push(fieldError.field);
    } else if (fieldError.errorType === PLE_ERROR.REQUIRED) {
      requiredFields.push(fieldError.field);
    }
  });

  const updateErrors = [];
  if (readonlyFields.length) {
    updateErrors.push(createFieldUpdateErrors(readonlyFields, messages.readonlyPleField, objectDescribe));
  }
  if (requiredFields.length) {
    updateErrors.push(createFieldUpdateErrors(requiredFields, messages.requiredPleField, objectDescribe));
  }
  return createBaseApiFormattedError(objectDescribe.apiName, id, updateErrors);
}

const getPleErrorType = (field, layoutFields, record) => {
  if (field === 'Id') {
    return null;
  }
  let errorType = null;
  if (layoutFields[field]?.editable !== true) {
    errorType = PLE_ERROR.READONLY;
  } else if (!record[field] && layoutFields[field]?.required) {
    errorType = PLE_ERROR.REQUIRED;
  }
  return errorType;
};

const createLayoutKey = (recordTypeId, eventId, eventConfigId, eventStatus, eventCountry) => (
  `${recordTypeId}:${eventId}:${eventConfigId}:${eventStatus}:${eventCountry}`
);

const getKeyProps = (key) => {
  const [ recordTypeId, eventId, eventConfigId, eventStatus, countryAlpha2Code ] = key.split(':');
  return { 
    recordTypeId, 
    eventId, 
    pleParams: { 
      eventConfigId, 
      eventStatus, 
      countryAlpha2Code 
    }
  };
};

const processBatch = (batch, parentEventId, parentEventPleParams) => {
  const layoutKeyToRecordIds = {};

  batch.forEach(record => {
    const recordTypeId = record.fields?.RecordTypeId?.value || record.recordTypeId;
    const eventConfigId = parentEventPleParams?.eventConfigId ?? record.fields?.Event_Configuration_vod__c?.value;
    const eventStatus = parentEventPleParams?.eventStatus ?? record.fields?.Status_vod__c?.value;
    const countryAlpha2Code = parentEventPleParams?.countryAlpha2Code ?? record.fields?.Country_vod__r?.value.fields?.Alpha_2_Code_vod__c?.value;
    const layoutKey = createLayoutKey(recordTypeId, parentEventId || record.id, eventConfigId, eventStatus, countryAlpha2Code);

    layoutKeyToRecordIds[layoutKey] = layoutKeyToRecordIds[layoutKey] || [];
    layoutKeyToRecordIds[layoutKey].push(record.id);
  });

  return layoutKeyToRecordIds;
};

const getLayoutKeyToRecordIds = async (recordsToSave, pageCtrl, objectApiName) => {
  const recordIds = recordsToSave.map(record => record.Id);

  // Set fields to query
  const fields = [`${objectApiName}.RecordTypeId`];
  if (objectApiName === 'EM_Event_vod__c') {
    fields.push(
      `${EVENT_OBJ.objectApiName}.${EVENT_STATUS_FLD.fieldApiName}`, 
      `${EVENT_OBJ.objectApiName}.${EVENT_COUNTRY_CODE.fieldApiName}`, 
      `${EVENT_OBJ.objectApiName}.${EVENT_CONFIGURATION_ID_FLD.fieldApiName}`
    );
  }

  const batch = await pageCtrl.uiApi.getBatchRecords(recordIds, fields);

  let layoutKeyToRecordIds;
  if (objectApiName === EVENT_OBJ.objectApiName) {
    layoutKeyToRecordIds = processBatch(batch);
  } else {
    const [ parentEventId, parentEventPleParams ] = await Promise.all([pageCtrl.getEventId(), pageCtrl.getPleParams()]);
    layoutKeyToRecordIds = processBatch(batch, parentEventId, parentEventPleParams);
  }

  return layoutKeyToRecordIds;
};

const getLayout = (emPageLayoutEngineSvc, objectApiName, action, recordTypeId, eventId, pleParams) => (emPageLayoutEngineSvc.getPageLayout(objectApiName, action, null, recordTypeId, eventId, pleParams));

export { createLayoutKey, getKeyProps, getLayout, getLayoutKeyToRecordIds, createBaseApiFormattedError, createFieldUpdateErrors, createErrorObjectFromFieldErrors, getPleErrorType };