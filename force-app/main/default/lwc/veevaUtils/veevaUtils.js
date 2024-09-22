import VeevaConstant from 'c/veevaConstant';

export default class VeevaUtils {
  static validSfdcId = id => id && /[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}/.test(id);

  static getRandomId() {
    return `_${Math.random()
      .toString(36)
      .substring(2, 15)}`;
  }

  static clone = obj => {
    const result = Object.create(Object.getPrototypeOf(obj));
    // copy enumerable properties
    for (const x in obj) {
      // eslint-disable-next-line no-prototype-builtins
      if (obj.hasOwnProperty(x)) {
        result[x] = obj[x];
      }
    }
    return result;
  };

  static isEmptyObject = obj => {
    if (obj === undefined || obj === null) {
      return true;
    }
    // eslint-disable-next-line guard-for-in,no-unreachable-loop
    for (const name in obj) {
      return false;
    }
    return true;
  };

  static hasCJK = term => {
    if (term === null) {
      return false;
    }
    if (typeof term !== 'string') {
      return false;
    }
    const chars = term.trim().split('');
    for (let i = 0; i < chars.length; i++) {
      if (/^[\u1100-\u1200\u3040-\uFB00\uFE30-\uFE50\uFF00-\uFFF0]+$/.test(chars[i])) {
        return true;
      }
    }
    return false;
  };

  static isValidSearchTerm = term => {
    if (!term) {
      return false;
    }
    const normalizedTerm = term.replace(/[()"?*]+/g, '').trim();
    return normalizedTerm.length >= 2 || VeevaUtils.hasCJK(normalizedTerm);
  };

  /**
   * @param apiName - object to check for a hardcoded icon
   * @returns {string} a valid icon-name attribute for a <lightning-icon/> component
   */
  static getIconHardcoded = apiName => VeevaConstant.OBJECT_ICONS[apiName] || VeevaConstant.DEFAULT_ICON;

  /**
   * @param iconUrl - url from themeInfo of ui-api/object-info
   * @returns {string} a valid icon-name attribute for a <lightning-icon/> component
   */
  static getIconFromUrl = iconUrl => {
    if (iconUrl) {
      const standardIconRegex = /standard\/([a-zA-Z]*)_/;
      const standardMatch = standardIconRegex.exec(iconUrl);
      if (standardMatch && standardMatch[1]) {
        return `standard:${standardMatch[1]}`;
      }
      const customIconRegex = /custom\/custom(\d*)_/;
      const customMatch = customIconRegex.exec(iconUrl);
      if (customMatch && customMatch[1]) {
        return `custom:custom${customMatch[1]}`;
      }
    }

    return VeevaConstant.DEFAULT_ICON;
  };

  static to = promise =>
    promise
      .then(
        data => [null, data],
        err => [err]
      )
      .catch(err => [err]);

  static convertRecordType = recordTypeInfo => ({
    label: recordTypeInfo.name,
    value: recordTypeInfo.recordTypeId,
    defaultType: recordTypeInfo.defaultRecordTypeMapping,
  });

  static getAvailableRecordTypes = recordTypeInfos => {
    let availableTypes = [];

    availableTypes = Object.values(recordTypeInfos)
      .filter(recordTypeInfo => !recordTypeInfo.master && recordTypeInfo.available)
      .map(VeevaUtils.convertRecordType)
      .sort((type1, type2) => {
        if (type1.label && type2.label) {
          if (type1.label < type2.label) {
            return -1;
          }
          if (type1.label > type2.label) {
            return 1;
          }
        }
        return 0;
      });

    if (availableTypes.length === 0) {
      const masterType = Object.values(recordTypeInfos).find(recordTypeInfo => recordTypeInfo.master);
      if (masterType) {
        availableTypes = [VeevaUtils.convertRecordType(masterType)];
      }
    }

    return availableTypes;
  };

  /**
   * Polls until the result is valid or maxAttempts reached.
   * @param {function} fn - Function to be repeatedly called.
   * @param {function} isValid - Function validating result of fn.
   * @param {number} delay - Delay after each fn call.
   * @param {number} maxAttempts - Maximum attempts.
   * @returns {promise} returns the result of repeatedly called function
   */
  static async poll(fn, isValid, delay, maxAttempts = 1) {
    let attempts = 1;
    let result = await fn();
    while (!isValid(result) && attempts < maxAttempts) {
      attempts++;
      // eslint-disable-next-line no-await-in-loop,@lwc/lwc/no-async-operation,no-promise-executor-return
      await new Promise(resolve => setTimeout(resolve, delay));
      // eslint-disable-next-line no-await-in-loop
      result = await fn();
    }
    return result;
  }

  static lookupTraversal = lookupVal =>
    function findFieldValue(fieldsToTraverse) {
      return fieldsToTraverse.reduce((acc, currentValue) => {
        if (acc === undefined || acc === null) {
          return acc;
        }
        return acc.fields?.[currentValue]?.value;
      }, lookupVal);
    };

  static isUser = id => id?.startsWith('005');

  static deepEqual = (object1, object2) => {
    const keys1 = Object.keys(object1);
    const keys2 = Object.keys(object2);

    if (keys1.length !== keys2.length) {
      return false;
    }

    for (const key of keys1) {
      const val1 = object1[key];
      const val2 = object2[key];
      const areObjects = this.isObject(val1) && this.isObject(val2);
      if ((areObjects && !this.deepEqual(val1, val2)) || (!areObjects && val1 !== val2)) {
        return false;
      }
    }

    return true;
  };

  static isObject = object => object != null && typeof object === 'object';

  /**
   * @param {Object} deleteResponse returned by dataService delete operation
   * @returns a response in the format of a dataService save operation
   */
  static getConvertedToSaveErrorFormat = deleteResponse => {
    const { errors, ...restResponse } = deleteResponse;

    if (!errors) {
      return { ...restResponse, data: { recordErrors: [deleteResponse.message] } };
    }

    const fieldErrors = {};
    Object.keys(errors).forEach(field => {
      // If the field has 'errorMessage' property, consider it a fieldError
      if (errors[field].errorMessage) {
        fieldErrors[field] = errors[field].errorMessage;
      }
    });

    return { ...restResponse, data: { fieldErrors, recordErrors: [] } };
  };
}