import VeevaPageReference from 'c/veevaPageReference';

export default class EmPageReference extends VeevaPageReference {
  static getCreateDefaults = async (uiAPI, recordTypeId, apiName, fields, pageRef) => {
    const optionalFields = Object.values(fields).map(value => `${apiName}.${value.apiName}`);
    const defaults = await uiAPI.getCreateDefaults(apiName, recordTypeId, optionalFields);
    const result = {
      record: JSON.parse(JSON.stringify(defaults.record)),
    };

    await VeevaPageReference.setParentValueAndDisplayName(defaults, pageRef, result, apiName, uiAPI);

    return result;
  };

  static _processDisplayValues = (fields, fn) => {
    if (fields) {
      Object.values(fields).forEach(field => {
        if (field.displayValue) {
          field.displayValue = fn(field.displayValue);
        }
      });
    }
    return fields;
  };

  static encodeEmDefaultFieldValues = defVals => EmPageReference._processDisplayValues(defVals, encodeURIComponent);

  static decodeEmDefaultFieldValues = defVals => EmPageReference._processDisplayValues(defVals, decodeURIComponent);
}