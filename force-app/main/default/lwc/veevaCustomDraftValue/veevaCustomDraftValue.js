/**
 * Draft values hold extra info to support fields like lookups, picklists, and currency fields
 * @param {Object} draftValue to filter the unnecessary fields for save
 * @returns {Object} with values only from draftValue
 */
const getValuesFrom = draftValue => {
  const toSave = {};
  Object.entries(draftValue).forEach(([key, value]) => {
    if (typeof value === 'object' && Object.prototype.hasOwnProperty.call(value, 'displayValue')) {
      let field = key;
      if (key.endsWith('__r.Name')) {
        field = `${key.split('__r.')[0]}__c`;
      }
      toSave[field] = value.value;
    } else if (typeof value !== 'function' && key !== 'id') {
      toSave[key] = value;
    }
  });
  return toSave;
};

/**
 * VeevaCustomDraftValue class supports complex fields like picklists and lookups
 * By default such fields are not supported by lightning data table as of Winter 23
 */
class VeevaCustomDraftValue {
  id;

  constructor(id) {
    this.id = id;
  }

  // Out of the box draft values have "I" capitalized
  get Id() {
    return this.id;
  }

  set Id(val) {
    this.id = val;
  }

  toBaseApiSaveFormat() {
    return swapEmptyValuesToNull(this.toSaveFormat());

    function swapEmptyValuesToNull(draftValue) {
      const obj = {};
      Object.entries(draftValue).forEach(([key, value]) => {
        obj[key] = value === '' ? null : value;
      });
      return obj;
    }
  }

  toSaveFormat() {
    return { Id: this.id, ...getValuesFrom({ ...this }) };
  }

  upsertCustomField(field, value, displayValue) {
    this[field] = { value, displayValue };
  }

  upsertStandardField(field, value) {
    this[field] = value;
  }
}

const updateDraftWithItem = (draft, updateItem) => {
  if (Object.prototype.hasOwnProperty.call(updateItem, 'label')) {
    draft.upsertCustomField(updateItem.field, updateItem.value, updateItem.label);
  } else {
    Object.keys(updateItem).forEach(field => {
      draft.upsertStandardField(field, updateItem[field]);
    });
  }
};

const getUpdatedDraftValues = (draftValues, updateItem) => {
  let result = [];
  let draftValueChanged = false;
  const copyDraftValues = [...draftValues];

  copyDraftValues.forEach(draft => {
    if (draft.Id === updateItem.Id) {
      updateDraftWithItem(draft, updateItem);
      draftValueChanged = true;
    }
  });

  if (draftValueChanged) {
    result = [...copyDraftValues];
  } else {
    const draft = new VeevaCustomDraftValue(updateItem.Id);
    updateDraftWithItem(draft, updateItem);
    result = [...copyDraftValues, draft];
  }
  return result;
};

export { VeevaCustomDraftValue, getUpdatedDraftValues };