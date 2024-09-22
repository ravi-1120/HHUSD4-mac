import getRelatedRecords from '@salesforce/apex/VeevaRelatedObjectController.getRelatedRecords';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getRelatedRecordsCount from '@salesforce/apex/VeevaRelatedObjectController.getRelatedRecordsCount';
import getRecordsById from '@salesforce/apex/VeevaRelatedObjectController.getRecordsById';
import { getService } from 'c/veevaServiceFactory';
import searchRelatedRecords from '@salesforce/apex/VeevaRelatedObjectController.searchRelatedRecords';
import VeevaRecord from 'c/veevaRecord';
import VeevaUtils from 'c/veevaUtils';
import getTypeAttributes from './typeAttributes';

export default class VeevaRelatedListController {
  ACTION_COLUMN_WIDTH = 80;
  ACTION_LINKS_COLUMN = {
    label: '',
    fieldName: 'actionLinks',
    type: 'action',
    typeAttributes: {},
    hideDefaultActions: true,
    fixedWidth: this.ACTION_COLUMN_WIDTH,
  };

  get allowInlineEdit() {
    return false;
  }

  constructor(meta, pageCtrl) {
    this.meta = meta;
    this.pageCtrl = pageCtrl;
    this.objectDescribe = {};
    this.allRecords = [];
    this.searchParams = {};

    this.baseDataSvc = getService('baseDataService');
  }

  get creatable() {
    let createPermission = true;
    if (this.objectDescribe) {
      createPermission = this.objectDescribe.createable;
    }
    return createPermission;
  }

  get defaultSortColumn() {
    let sortColumn = this.nameField;
    if (this.meta?.columns && !this.meta.columns.some(col => col.name === this.nameField)) {
      sortColumn = this.meta.columns[0].name;
    }
    return sortColumn;
  }

  get defaultSortDirection() {
    return 'asc';
  }

  get nameField() {
    let nameField = 'Name';
    if (this.objectDescribe?.nameFields?.length === 1) {
      [nameField] = this.objectDescribe.nameFields;
    }
    return nameField;
  }

  get showFileUpload() {
    return false;
  }

  get iconName() {
    return VeevaUtils.getIconFromUrl(this.objectDescribe?.themeInfo?.iconUrl);
  }

  get isTree() {
    return false;
  }

  async getButtons() {
    const buttons = [];
    if (this.creatable && this.meta.buttons?.some(button => button === 'New')) {
      const newMessage = await this.pageCtrl.getMessageWithDefault('NEW_OBJECT', 'TABLET', 'New {0}');
      buttons.push({
        label: newMessage.replace('{0}', this.objectDescribe.label),
        name: 'new',
      });
    }
    return buttons;
  }

  async getColumns() {
    const columnsList = [];
    this.getParsedColumns(this.meta.columns).forEach(col => {
      if (col.name === this.nameField) {
        columnsList.push(this.getLinkNameColumn(col));
        return;
      }
      const column = {
        label: col.label,
        fieldName: col.name,
        type: this.getColumnType(col.name),
        hideDefaultActions: true,
        cellAttributes: { alignment: 'left' },
        sortable: this.isSortable(col.name),
        editable: this.isEditable(col),
        displayReadOnlyIcon: this.isLocked(col),
      };
      column.typeAttributes = this.getTypeAttributes(column);
      columnsList.push(column);
    });
    this.ACTION_LINKS_COLUMN.typeAttributes.rowActions = this.getRowActions.bind(this);
    columnsList.push(this.ACTION_LINKS_COLUMN);
    return columnsList;
  }

  getLinkNameColumn(col) {
    const linkNameColumn = {
      label: col.label,
      fieldName: this.nameField,
      type: 'lookup',
      hideDefaultActions: true,
      sortable: true,
      editable: this.isEditable(col),
      displayReadOnlyIcon: this.isLocked(col),
    };
    linkNameColumn.typeAttributes = this.getTypeAttributes(linkNameColumn);
    return linkNameColumn;
  }

  getTypeAttributes(column) {
    return getTypeAttributes(this.objectDescribe, column);
  }

  async fetchRecords(params, forceRefresh = false) {
    let records = [];
    if (params.searchTerm) {
      const paramsNoOffsetLimit = JSON.parse(JSON.stringify(params));
      delete paramsNoOffsetLimit.qlimit;
      delete paramsNoOffsetLimit.offset;

      if (forceRefresh || !VeevaUtils.deepEqual(this.searchParams, paramsNoOffsetLimit)) {
        this.allRecords = await searchRelatedRecords(paramsNoOffsetLimit);
        this.searchParams = paramsNoOffsetLimit;
      }
      records = this.allRecords.slice(params.offset, params.offset + params.qlimit);
    } else {
      records = await getRelatedRecords(params);
    }
    return records;
  }

  async fetchRecordsById(params) {
    return getRecordsById(params);
  }

  async fetchRecordsWithTotals(params, forceRefresh = false) {
    let records = [];
    let recordTotalCount = 0;

    if (params.searchTerm) {
      records = await this.fetchRecords(params, forceRefresh);
      recordTotalCount = this.allRecords.length;
    } else {
      [records, recordTotalCount] = await Promise.all([
        this.fetchRecords(params),
        getRelatedRecordsCount({
          childObject: params.objectApiName,
          referenceFieldName: params.relationField,
          objectId: params.id,
          filters: params.filters,
        }),
      ]);
    }
    return { records, recordTotalCount };
  }

  async deleteRow(rowId, objectApiName) {
    try {
      const response = await this.doDeleteRow(rowId, objectApiName);
      if (this.allRecords?.length > 0) {
        this.allRecords = this.allRecords.filter(row => row.Id !== rowId);
      }
      return response;
    } catch (error) {
      // eslint-disable-next-line prefer-promise-reject-errors
      return Promise.reject({
        recordErrors: error.data.recordErrors.concat(Object.values(error.data.fieldErrors)),
      });
    }
  }

  doDeleteRow(rowId, objectApiName) {
    return this.pageCtrl.dataSvc.save({
      Deleted: 'true',
      Id: rowId,
      type: objectApiName,
    });
  }

  knownTypes = {
    Boolean: 'boolean',
    Email: 'email',
    Location: 'location',
    Phone: 'phone',
    Url: 'url',
    Currency: 'veevaCurrency',
    Date: 'date-local',
    DateTime: 'date',
    Time: 'text',
    Double: 'number',
    Int: 'number',
    Percent: 'veevaNumber',
    Picklist: 'picklist',
    TextArea: 'veevaTextArea',
  };

  getColumnType(fieldName) {
    const field = this.objectDescribe && this.objectDescribe.fields && this.objectDescribe.fields[fieldName];
    const dataType = field && field.dataType;
    let type = '';

    if (dataType && this.knownTypes[dataType]) {
      type = this.knownTypes[dataType];
    } else if (this.isLookup(fieldName)) {
      type = 'lookup';
    } else {
      type = 'text';
    }
    return type;
  }

  getFieldMeta(colName) {
    const parts = colName.split('.');
    let fieldName = parts[0];
    if (parts.length > 1) {
      if (fieldName.endsWith('__r')) {
        fieldName = fieldName.replace('__r', '__c');
      } else {
        fieldName += 'Id';
      }
    }
    return this.objectDescribe?.fields?.[fieldName] || {};
  }

  async getRowActions(row, doneCallback) {
    const actions = [];
    if (row.isUpdateable) {
      const editMessage = await this.pageCtrl.getMessageWithDefault('Edit', 'Common', 'Edit');
      actions.push({ label: editMessage, name: 'edit' });
    }
    if (row.isDeletable) {
      const deleteMessage = await this.pageCtrl.getMessageWithDefault('DELETE', 'Common', 'Delete');
      actions.push({ label: deleteMessage, name: 'delete' });
    }
    if (actions.length === 0) {
      const noActionsMessage = await this.pageCtrl.getMessageWithDefault('NO_ACTIONS', 'Common', 'No Actions Available');
      actions.push({ label: noActionsMessage, name: 'noActions', disabled: true });
    }
    doneCallback(actions);
  }

  getColumnsWithRelatedFields() {
    const columnsWithRelatedFields = this.meta.columns.filter(column => column.name.includes('.')).map(column => column.name);
    return columnsWithRelatedFields;
  }

  getRelatedFields() {
    const relatedFields = [];
    const columnsWithRelatedFields = this.getColumnsWithRelatedFields();
    columnsWithRelatedFields.forEach(column => {
      const [parentFieldName, childFieldName] = column.split('.');
      relatedFields.push({ parentFieldName, childFieldName });
    });

    return relatedFields;
  }

  addRelatedFieldValuesToRecord(record, relatedFields) {
    relatedFields.forEach(relatedField => {
      const { parentFieldName, childFieldName } = relatedField;
      if (record?.[parentFieldName]?.[childFieldName]) {
        record[`${parentFieldName}.${childFieldName}`] = record[parentFieldName][childFieldName];
      }
    });
  }

  processRecords(data) {
    const newRecords = [];
    if (data && data.length > 0) {
      const relatedFields = this.getRelatedFields();

      data.forEach(record => {
        const temp = { ...record };
        temp.RecordTypeId = temp.RecordTypeId ?? VeevaRecord.MASTER_RECORD_TYPE_ID;
        temp.linkName = `/${record.Id}`;
        if (this.objectDescribe) {
          temp.isUpdateable = this.objectDescribe.updateable;
          temp.isDeletable = this.objectDescribe.deletable;
        }
        this.addRelatedFieldValuesToRecord(temp, relatedFields);
        this.addDisplayValuesToRecord(temp);
        newRecords.push(this.processRecord(temp));
      });
    }
    return newRecords;
  }

  /**
   * Adds value and displayValue pair to lookup, currency, and picklist fields
   * @param {Object} record returned by getRelatedRecords
   */
  addDisplayValuesToRecord(record) {
    Object.keys(record).forEach(key => {
      const dataTypesToModify = ['Currency', 'Picklist', 'Time', 'Percent', 'Lookup', 'TextArea'];
      const fieldMeta = this.getFieldMeta(key);
      const { dataType, extraTypeInfo } = fieldMeta;
      const fieldDataType = this.isLookup(key) ? 'Lookup' : dataType;

      if (dataTypesToModify.includes(fieldDataType) && extraTypeInfo !== 'RichTextArea') {
        record[key] = getDisplayValue(key, fieldDataType, this.nameField);
      }
    });

    function getDisplayValue(key, dataType, nameField) {
      let value = {};
      const toLabelKey = `toLabel_${key}`;
      const toFormatKey = `toFormat_${key}`;
      if (key === nameField) {
        value = {
          value: record.Id,
          displayValue: record[nameField],
        };
      } else if (dataType === 'Lookup') {
        const base = key.split('.')[0];
        const lookupField = record[base];
        value = {
          value: lookupField.Id,
          displayValue: lookupField.Name,
        };
      } else if (dataType === 'Time') {
        value = record[toFormatKey];
      } else if (dataType === 'Percent') {
        value = { value: record[key] };
      } else if (toLabelKey in record || toFormatKey in record) {
        value = {
          value: record[key],
          displayValue: record[toLabelKey] || record[toFormatKey],
        };
      } else {
        value = {
          value: record[key],
          displayValue: record[key],
        };
      }
      return value;
    }
  }

  processRecord(record) {
    record.ctrl = this;
    return record;
  }

  async getInContextOfRefForNew() {
    return {
      type: 'standard__recordPage',
      attributes: {
        objectApiName: this.pageCtrl.objectApiName,
        recordId: this.pageCtrl.recordId,
        actionName: 'view',
      },
    };
  }

  getPageRefForNew(context) {
    let defaultFieldValues;
    if (this.meta.field) {
      defaultFieldValues = encodeDefaultFieldValues({ [this.meta.field]: this.pageCtrl.recordId });
    }
    return {
      type: 'standard__objectPage',
      attributes: {
        objectApiName: this.meta.objectApiName,
        actionName: 'new',
      },
      state: {
        useRecordTypeCheck: true,
        inContextOfRef: window.btoa(JSON.stringify(context)),
        defaultFieldValues,
      },
    };
  }

  async save(recordsToSave) {
    let response = {};
    try {
      response = await this.baseDataSvc.updateRecords(recordsToSave, this.objectDescribe.apiName);
      return { savedRecords: response.updateRecords, failedRecords: response.failedRecords || [] };
    } catch (error) {
      // eslint-disable-next-line prefer-promise-reject-errors
      return Promise.reject(error);
    }
  }

  isLookup(field) {
    return (field.endsWith('.Name') && field !== 'RecordType.Name') || field === this.nameField || field.startsWith('Owner.');
  }

  isSortable(colName) {
    return this.getFieldMeta(colName).sortable ?? false;
  }

  /**
   * Checks if a column is editable
   * Meant to run for all derived classes
   * @param {Object} column
   * @returns {boolean}
   */
  isEditable(column) {
    if (!this.allowInlineEdit) {
      return false;
    }

    const { dataType, controllerName, extraTypeInfo, length } = this.getFieldMeta(column.name);
    const lockedDataTypes = ['MultiPicklist', 'Time'];
    const controllingFields = this.getControllingFields();
    if (
      column.name === this.nameField ||
      lockedDataTypes.includes(dataType) ||
      controllingFields.has(column.name) ||
      controllerName ||
      this.isLockedTextArea(extraTypeInfo, length)
    ) {
      return false;
    }
    return this.checkEditPermission(column);
  }

  isLockedTextArea(extraTypeInfo, length) {
    // Lock Rich Text Area and Long Text Area
    return extraTypeInfo === 'RichTextArea' || (extraTypeInfo === 'PlainTextArea' && length > 255);
  }

  /**
   * Checks if a column has FLS to support editing
   * Can be overriden for custom checking
   * @param {Object} column
   * @returns {boolean}
   */
  checkEditPermission(column) {
    return this.getFieldMeta(column.name).updateable ?? false;
  }

  getControllingFields() {
    const fieldList = this.objectDescribe.fields;
    if (!this._controllingFields) {
      this._controllingFields = new Set();
      for (const field in fieldList) {
        if (fieldList[field].controllerName) {
          this._controllingFields.add(fieldList[field].controllerName);
        }
      }
    }
    return this._controllingFields;
  }

  isLocked(column) {
    if (!this.allowInlineEdit) {
      return false;
    }
    return !this.isEditable(column);
  }

  getQueryFields(columns) {
    const queryFields = this.getParsedColumns(columns)
      .map(column => column.name)
      .filter(column => column !== 'RecordType.Name');
    if (queryFields.indexOf('RecordTypeId') === -1) {
      queryFields.push('RecordTypeId');
    }
    return queryFields;
  }

  getParsedColumns(columns) {
    const localColumns = JSON.parse(JSON.stringify(columns));
    localColumns.forEach(col => {
      if (col.name.startsWith('toLabel(')) {
        col.name = col.name.replace('toLabel(', '').replace(')', '');
      }
    });
    return localColumns;
  }

  // eslint-disable-next-line no-unused-vars
  async getFilters(params) {
    return [];
  }

  showFilter() {
    return false;
  }

  processFilterLabels(filters, fieldLabelMap) {
    filters.forEach(filter => {
      if (Object.prototype.hasOwnProperty.call(fieldLabelMap, filter.fieldName)) {
        const fieldLabels = fieldLabelMap[filter.fieldName];
        filter.options.forEach(option => {
          if (Object.prototype.hasOwnProperty.call(fieldLabels, option.value)) {
            option.label = fieldLabels[option.value];
          }
        });
      }
    });
  }

  // eslint-disable-next-line no-unused-vars
  handleUploadFinished(files) {}
}