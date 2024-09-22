import EmRelatedListController from 'c/emRelatedListController';
import EmConcurService from 'c/emConcurService';
import EmEventConstant from 'c/emEventConstant';
import EmExpenseConstant from 'c/emExpenseConstant';
import { addConcurStatusToQueryFields, handleNoButtonDropdown, isStatusSendingOrSubmitted } from 'c/emSubmitToConcurErrorHandling';
import CONCUR_STATUS from '@salesforce/schema/Expense_Header_vod__c.Concur_Status_vod__c';
import EmConcurSubmissionStatusField from 'c/emConcurSubmissionStatusField';
import getRelatedExpenseHeaders from '@salesforce/apex/EmExpensesController.getRelatedExpenseHeaders';
import searchRelatedExpenseHeaders from '@salesforce/apex/EmExpensesController.searchRelatedExpenseHeaders';
import getFilters from '@salesforce/apex/EmExpensesController.getFilters';
import EXPENSE_LINE_OBJECT from '@salesforce/schema/Expense_Line_vod__c';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import VeevaUtils from 'c/veevaUtils';
import { createMessageContext, publish } from 'lightning/messageService';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';

const SUBMISSION_STATUS_ICON_NAME = 'concurSubmissionStatusIcon';
const SUBMISSION_STATUS_HELP_TEXT = 'concurSubmissionStatusHelpText';
const VEEVA_NEW_EM_EXPENSE_FLOW = 'VeevaNewEmExpenseFlow';

export default class EmExpenseHeaderRelatedListController extends EmRelatedListController {
  headerColumnsToHide = [];
  lineColumnsToHide = [];

  constructor(meta, pageCtrl) {
    super(meta, pageCtrl);
    this.uiApi = getService(SERVICES.UI_API);
    this.expenseLineObjectDescribePromise = this.uiApi.objectInfo(EXPENSE_LINE_OBJECT.objectApiName);
    this.concurSvc = new EmConcurService(getService(SERVICES.DATA), this.uiApi);
  }

  get meta() {
    return this._meta;
  }

  set meta(value) {
    this._meta = { ...value };
  }

  get isTree() {
    return true;
  }

  async getColumns() {
    this.expenseLineObjectDescribe = await this.expenseLineObjectDescribePromise;
    const columnsList = [];
    let columnOverrides;
    if (this.pageCtrl.expenseRelatedListFields) {
      const [key, category] = this.pageCtrl.expenseRelatedListFields.split(';;');
      if (category === 'EXPENSE_FIELDS') {
        columnOverrides = await this.pageCtrl.getMessageWithDefault(key, category, null);
      }
    }
    if (columnOverrides) {
      const parsedColumns = columnOverrides.split(';').filter(field => field);
      columnsList.push({
        name: 'Name',
        label: this.objectDescribe?.fields?.Name?.label ?? 'Name',
        readOnly: true,
      });
      let index = 0;
      while (index < parsedColumns.length && columnsList.length < 10) {
        const [objectName, columnName] = parsedColumns[index].split('.');
        let colName = columnName;
        if ((objectName === 'Expense_Line_vod' || objectName === 'Expense_Header_vod') && colName) {
          let [primaryDescribe, secondaryDescribe] = this.getColumnDescribes(objectName, colName);
          if (!primaryDescribe && !colName.endsWith('__c')) {
            colName = colName.concat('__c');
            [primaryDescribe, secondaryDescribe] = this.getColumnDescribes(objectName, colName);
          }
          if (
            primaryDescribe &&
            !columnsList.map(c => c.name).includes(colName) &&
            (!secondaryDescribe || primaryDescribe?.dataType === secondaryDescribe?.dataType)
          ) {
            const label = this.objectDescribe?.fields?.[colName]?.label || this.expenseLineObjectDescribe?.fields?.[colName]?.label;
            if (primaryDescribe.dataType === 'Reference') {
              if (colName.endsWith('__c')) {
                colName = colName.replace('__c', '__r.Name');
              } else if (colName.endsWith('Id')) {
                colName = colName.slice(0, -2);
                colName += '.Name';
              }
            }
            const col = {
              name: colName,
              readOnly: true,
              label,
            };
            columnsList.push(col);
          }
        }
        index++;
      }
    } else {
      super.getParsedColumns(this.meta.columns).forEach(col => {
        const parts = col.name.split('.');
        let fieldName = parts[0];
        if (parts.length > 1) {
          if (fieldName.endsWith('__r')) {
            fieldName = fieldName.replace('__r', '__c');
          } else {
            fieldName += 'Id';
          }
        }
        const headerDescribe = this.objectDescribe?.fields?.[fieldName];
        const lineDescribe = this.expenseLineObjectDescribe?.fields?.[fieldName];
        if (headerDescribe && (!lineDescribe || headerDescribe.dataType === lineDescribe.dataType)) {
          columnsList.push(col);
        }
      });
    }

    columnsList.forEach(({ name }) => {
      if (this.objectDescribe?.fields?.[name]?.htmlFormatted) {
        this.headerColumnsToHide.push(name);
      }
      if (this.expenseLineObjectDescribe?.fields?.[name]?.htmlFormatted) {
        this.lineColumnsToHide.push(name);
      }
    });

    this.meta.columns = columnsList;
    const columns = await super.getColumns();

    const concurColumn = columns.find(column => column.fieldName === CONCUR_STATUS.fieldApiName);
    if (concurColumn) {
      concurColumn.cellAttributes = {
        iconName: { fieldName: SUBMISSION_STATUS_ICON_NAME },
        iconAlternativeText: { fieldName: SUBMISSION_STATUS_HELP_TEXT },
        iconPosition: 'left',
      };
    }
    return columns;
  }

  getColumnDescribes(object, colName) {
    const headerDescribe = this.objectDescribe?.fields?.[colName];
    const lineDescribe = this.expenseLineObjectDescribe?.fields?.[colName];
    const primaryDescribe = object === 'Expense_Line_vod' ? lineDescribe : headerDescribe;
    const secondaryDescribe = object === 'Expense_Line_vod' ? headerDescribe : lineDescribe;

    return [primaryDescribe, secondaryDescribe];
  }

  getParsedColumns(columns) {
    return columns;
  }

  getColumnType(fieldName) {
    const knownTypes = ['Boolean', 'Email', 'Location', 'Phone', 'Url'];
    const expenseHeaderType = this.objectDescribe?.fields?.[fieldName]?.dataType;
    const expenseLineType = this.expenseLineObjectDescribe?.fields?.[fieldName]?.dataType;
    const dataType = expenseHeaderType || expenseLineType;

    let type = '';

    if (knownTypes.includes(dataType)) {
      type = dataType.toLowerCase();
    } else {
      type = 'text';
    }

    return type;
  }

  addDisplayValuesToRecord() {
    // no-op to prevent default behavior from VeevaRelatedListController
  }

  async fetchRecords(params, forceRefresh = false) {
    let records;
    if (params.searchTerm) {
      if (forceRefresh || !VeevaUtils.deepEqual(this.searchParams, params)) {
        this.allRecords = await searchRelatedExpenseHeaders(params);
        this.searchParams = params;
      }
      records = this.allRecords;
    } else {
      records = await getRelatedExpenseHeaders(params);
    }
    return records;
  }

  async fetchRecordsWithTotals(params) {
    const records = await this.fetchRecords(params);
    return { records, recordTotalCount: records?.length };
  }

  getLinkNameColumn(col) {
    const linkNameColumn = {
      fieldName: 'linkName',
      label: col.label,
      type: 'url',
      typeAttributes: {
        label: {
          fieldName: 'Name',
        },
        tooltip: {
          fieldName: 'Name',
        },
      },
      hideDefaultActions: true,
    };
    return linkNameColumn;
  }

  async initData() {
    const messages = await this.pageCtrl.messageSvc
      .createMessageRequest()
      .addRequest('CONCUR_CONNECTION_ERROR', 'Concur', 'Lost connection to Concur. Please retry.', 'CONCUR_CONNECTION_ERROR')
      .addRequest('CONCUR_POST_ERROR', 'Concur', 'There was an error submitting to Concur. Please contact your administrator.', 'CONCUR_POST_ERROR')
      .addRequest(
        'CONCUR_SUBMIT_CANCELED',
        'Concur',
        'The system admin has canceled this expense from being sent to Concur.',
        'CONCUR_SUBMIT_CANCELED'
      )
      .sendRequest();
    Object.entries(messages).forEach(([messageName, messageText]) => {
      this[messageName] = messageText;
    });
  }

  processRecord(record) {
    record.concurStatusRaw = record[CONCUR_STATUS.fieldApiName];
    record[CONCUR_STATUS.fieldApiName] = record.toLabel_Concur_Status_vod__c;
    const concurSubmissionStatusValue = record.concurStatusRaw;
    const submissionStatus = EmConcurSubmissionStatusField.getConcurStatus(concurSubmissionStatusValue);
    record[SUBMISSION_STATUS_ICON_NAME] = submissionStatus.icon;
    if (submissionStatus.helptext?.key) {
      record[SUBMISSION_STATUS_HELP_TEXT] = this[submissionStatus.helptext.key];
    }
    record.linkName = `/${record.Id}`;
    record.objectApiName = this.objectDescribe.apiName;
    this.headerColumnsToHide.forEach(field => {
      record[field] = '';
    });
    if (record.Expense_Lines_vod__r?.length) {
      this.processChildren(record);
    }
    return super.processRecord(record);
  }

  processChildren(record) {
    record._children = record.Expense_Lines_vod__r;
    const relatedFields = this.getRelatedFields();
    record._children.forEach(child => {
      child.linkName = `/${child.Id}`;
      child.isUpdateable = this.expenseLineObjectDescribe.updateable;
      child.isDeletable = this.expenseLineObjectDescribe.deletable;
      child.objectApiName = this.expenseLineObjectDescribe.apiName;
      child.objectLabel = this.expenseLineObjectDescribe.label;
      child.concurStatusRaw = record.concurStatusRaw;
      child.expenseHeaderId = record.Id;
      this.lineColumnsToHide.forEach(field => {
        child[field] = '';
      });
      this.addRelatedFieldValuesToRecord(child, relatedFields);
    });
  }

  async deleteRow(rowId, objectApiName) {
    if (await isStatusSendingOrSubmitted(this.concurSvc, rowId, objectApiName)) {
      throw await this.pageCtrl.getMessageWithDefault('CONCUR_ALREADY_SENT_VIEW', 'Concur', EmExpenseConstant.CONCUR_ALREADY_SENT_DEFAULT);
    }
    const result = await super.deleteRow(rowId, objectApiName);
    this.pageCtrl.refreshParentRecordUi(true, this.pageCtrl.id, EmEventConstant.FIELDS_EXPENSE_LINES_UPDATE_ASYNC);
    return result;
  }

  // eslint-disable-next-line no-unused-vars
  getQueryFields(columns) {
    const queryFields = super.getQueryFields(this.meta.columns);
    return addConcurStatusToQueryFields(queryFields, EmExpenseConstant.CONCUR_STATUS);
  }

  async getRowActions(row, doneCallback) {
    if (EmExpenseConstant.HIDE_BUTTONS_CONCUR_STATUSES.includes(row?.concurStatusRaw)) {
      await handleNoButtonDropdown(row, doneCallback, this.pageCtrl);
    } else {
      await super.getRowActions(row, doneCallback);
    }
  }

  async getFilters(params) {
    return getFilters(params);
  }

  showFilter() {
    return true;
  }

  async launchNewFlow(context) {
    const payload = {
      flowName: VEEVA_NEW_EM_EXPENSE_FLOW,
      flowVariables: this.getFlowVariables(context),
    };
    publish(createMessageContext(), eventsManagementChannel, payload);
  }

  getFlowVariables(context, row) {
    const flowVars = [
      {
        name: 'objectApiName',
        value: row?.objectApiName || this.objectDescribe.apiName,
        type: 'String',
      },
      {
        name: 'flowContext',
        value: JSON.stringify(context),
        type: 'String',
      },
    ];

    if (row) {
      flowVars.push({
        name: 'recordId',
        value: row.Id,
        type: 'String',
      });
    }
    return flowVars;
  }
}