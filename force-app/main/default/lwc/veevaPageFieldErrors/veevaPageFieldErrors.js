import getFlatErrors from './fieldErrorUtils';

class VeevaFieldError {
  fieldLabel;
  fieldKey;
  path; // {Array} containing a unique path for a field on the layout
  constructor(fieldLabel, fieldKey, path) {
    this.fieldLabel = fieldLabel;
    this.fieldKey = fieldKey;
    this.path = path;
  }
}

/**
 * Rolls up nested field errors, i.e. on veeva-modal-page rolls up multiple veeva-section errors
 * @param {LWC[]} childElements to call getFieldErrors for
 * @param {String} parentSelector to append to child element error path
 * @returns {VeevaFieldError[]} field error array with prepended element's selector unique identifier
 */
const getNestedFieldErrors = (childElements, parentSelector) => {
  let fieldErrors = [];
  childElements.forEach(el => {
    if (el.getFieldErrors) {
      fieldErrors = [...fieldErrors, ...el.getFieldErrors()];
    }
  });

  if (parentSelector) {
    fieldErrors.forEach(field => {
      field.path.unshift(parentSelector);
    });
  }
  return fieldErrors;
};

/**
 * Gets a single errored leaf field, i.e. veeva-lightning-input
 * @param {LWC} field element to check valididty
 * @param {String} elementTagName for the passed element
 * @returns {VeevaFieldError[]} field error array
 */
const getFieldErrors = (element, elementTagName) => {
  const fieldErrors = [];
  const isValid = element.checkValidity();
  if (isValid === false) {
    fieldErrors.push(new VeevaFieldError(element.ctrl.label, `${element.ctrl.id}_${element.ctrl.fieldApiName}`, [elementTagName]));
  }
  return fieldErrors;
};

/**
 * Focuses on the element path, supports veeva-error-popover field focus
 * @param {String[]} path to focus on the last indentifier in the array
 */
const focusOn = (component, path) => {
  const element = component.template.querySelector(path.shift());
  if (element?.focusOn) {
    element.focusOn(path);
  }
};

/**
 * For any errored fields not on the layout, do the following
 * Add VeevaFieldError to the page.fieldErrors
 * Add the field error to the record errors
 * @param {Map} fieldErrorsFromApi contains all errored fields api returns
 * @param {VeevaFieldError[]} pageFieldErrors rolled up layout field errors
 * @param {String[]} recordErrors
 * @param {ObjectInfo.fields{}} fieldLabelMap contains ObjectInfo.fields object
 */
const processFieldErrorsNotOnLayout = (pageFieldErrors, fieldErrorsFromApi, recordErrors, fieldLabelMap, mainRecordId) => {
  const flatErrors = getFlatErrors(fieldErrorsFromApi, fieldLabelMap, mainRecordId);
  Object.entries(flatErrors).forEach(([fieldKey, errorObj]) => {
    if (!pageFieldErrors.some(el => el.fieldKey === fieldKey)) {
      if (errorObj.label) pageFieldErrors.push(new VeevaFieldError(errorObj.label, fieldKey, []));
      recordErrors.push(errorObj.value);
    }
  });
};

export { VeevaFieldError, getNestedFieldErrors, getFieldErrors, focusOn, processFieldErrorsNotOnLayout };