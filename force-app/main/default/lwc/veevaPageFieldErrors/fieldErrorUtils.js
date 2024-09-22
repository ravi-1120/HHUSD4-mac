/**
 * Layouts may have record with sub records, fieldErrorsFromApi may contain subrecord field errors
 * Flatten the fieldErrorsApi object to contain ${recordId}_${fieldApiName} as keys
 * @param {Map} fieldErrorsFromApi contains all errored fields api returns
 * @param {ObjectInfo.fields{}} fieldLabelMap contains ObjectInfo.fields object
 * @param {String} recordId of the record with failed fields
 */
const getFlatErrors = (fieldErrorsFromApi, fieldLabelMap, recordId) =>
  Object.entries(fieldErrorsFromApi).reduce((acc, [error, errorMessage]) => {
    if (errorMessage && typeof errorMessage === 'object') {
      Object.assign(acc, getFlatErrors(errorMessage, fieldLabelMap, error));
    } else {
      acc[`${recordId}_${error}`] = {
        value: errorMessage,
        label: fieldLabelMap[error]?.label,
      };
    }
    return acc;
  }, {});

export default getFlatErrors;