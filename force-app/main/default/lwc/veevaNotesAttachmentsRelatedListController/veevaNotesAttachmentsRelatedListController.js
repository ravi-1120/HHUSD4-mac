import VeevaConstant from 'c/veevaConstant';
import VeevaRelatedListController from 'c/veevaRelatedListController';
import fetchNotesAttachmentsFiles from '@salesforce/apex/NotesAttachmentsFilesController.fetchNotesAttachmentsFiles';
import LAST_MODIFIED_DATE from '@salesforce/schema/ContentDocument.LastModifiedDate';

const DOWNLOAD_FILE_ACTION = 'downloadFile';
const VIEW_FILE_DETAILS_ACTION = 'viewFileDetails';
const DOWNLOAD_ATTACHMENT_ACTION = 'downloadAttachment';
const EDIT_NOTE_ACTION = 'editNote';
export default class VeevaNotesAttachmentsRelatedListController extends VeevaRelatedListController {
  #allRecords;
  #labels;
  #labelsPromise;

  get meta() {
    return this._meta;
  }

  set meta(value) {
    this._meta = { ...value };
  }

  constructor(meta, pageCtrl) {
    super(meta, pageCtrl);
    this.#labelsPromise = this.loadAttachmentLabels();
  }

  // eslint-disable-next-line class-methods-use-this
  get defaultSortColumn() {
    return 'LastModifiedDate';
  }

  // eslint-disable-next-line class-methods-use-this
  get defaultSortDirection() {
    return 'desc';
  }

  get showFileUpload() {
    return this.pageCtrl.objectInfo.updateable && this.pageCtrl.shouldShowFileUpload;
  }

  async loadAttachmentLabels() {
    const msgRequest = this.pageCtrl.messageSvc
      .createMessageRequest()
      .addRequest('Edit', 'Common', 'Edit', 'editLabel')
      .addRequest('DELETE', 'Common', 'Delete', 'deleteLabel')
      .addRequest('DOWNLOAD', 'Common', 'Download', 'downloadLabel')
      .addRequest('VIEW_FILE_DETAILS', 'Lightning', 'View File Details', 'viewFileDetailsLabel')
      .addRequest('CREATEDBY', 'Common', 'Created By', 'createdByLabel')
      .addRequest('TYPE', 'Common', 'Type', 'typeLabel')
      .addRequest('ATTACHMENT', 'Attachment', 'Attachment', 'attachmentLabel');

    const noteLabelRequest = this.pageCtrl.uiApi.objectInfo('Note').then(data => data.label);
    const [messages, noteLabel] = await Promise.all([msgRequest.sendRequest(), noteLabelRequest]);
    this.#labels = { ...messages, noteLabel };
  }

  // eslint-disable-next-line class-methods-use-this
  async getButtons() {
    return [];
  }

  async getColumns() {
    await this.#labelsPromise;
    this.meta.columns = [
      {
        label: this.objectDescribe.fields.Title.label,
        name: 'Title',
      },
      {
        label: this.#labels.typeLabel,
        name: 'objectLabel',
      },
      {
        label: this.#labels.createdByLabel,
        name: 'CreatedBy.Name',
      },
      {
        label: this.objectDescribe.fields.LastModifiedDate.label,
        name: LAST_MODIFIED_DATE.fieldApiName,
      },
    ];

    const columns = await super.getColumns();
    const typeCol = columns.find(column => column.fieldName === 'objectLabel');
    if (typeCol) {
      typeCol.sortable = false;
    }
    return columns;
  }

  getLinkNameColumn(col) {
    const linkNameColumn = {
      fieldName: 'linkName',
      label: col.label,
      type: 'url',
      typeAttributes: {
        label: {
          fieldName: 'displayValue',
          target: '_blank',
        },
      },
      hideDefaultActions: true,
      sortable: true,
      cellAttributes: {
        iconName: { fieldName: 'icon' },
      },
    };
    return linkNameColumn;
  }

  getColumnType(columnName) {
    let colType = '';
    if (columnName === LAST_MODIFIED_DATE.fieldApiName) {
      colType = 'text';
    } else {
      colType = super.getColumnType(columnName);
    }
    return colType;
  }

  async fetchRecords({ id, offset, qlimit, sortBy, sortDirection }) {
    await this.#labelsPromise;
    if (offset === 0 || !this.#allRecords) {
      this.#allRecords = await fetchNotesAttachmentsFiles({ recordId: id, sortBy, sortDirection });
    }
    return this.#allRecords.slice(offset, offset + qlimit);
  }

  async fetchRecordsWithTotals(params) {
    const records = await this.fetchRecords(params);
    return { records, recordTotalCount: this.#allRecords.length };
  }

  processRecords(data) {
    if (data && data.length > 0) {
      const records = data.map(record => ({
        ...record.data,
        type: record.type,
        LastModifiedDate: record.lastModifiedDate,
        displayValue: record.data.Title,
      }));
      return super.processRecords(records);
    }
    return [];
  }

  processRecord(record) {
    if (record.type === 'attachment') {
      record.icon = 'doctype:attachment';
      record.objectLabel = this.#labels.attachmentLabel;
      record.objectApiName = 'Attachment';
    }
    if (record.type === 'file') {
      record.linkName = `/lightning/page/filePreview?selectedRecordId=${record.Id}`;
      record.icon = `doctype:${VeevaConstant.FILE_TYPE_TO_ICON[record.FileExtension?.toLowerCase()] || 'unknown'}`;
      record.objectLabel = this.objectDescribe.label;
      record.objectApiName = 'ContentDocument';
    }
    if (record.type === 'note') {
      record.icon = 'doctype:stypi';
      record.objectLabel = this.#labels.noteLabel;
      record.objectApiName = 'Note';
    }
    return super.processRecord(record);
  }

  async deleteRow(rowId, objectApiName) {
    const result = await super.deleteRow(rowId, objectApiName);
    this.#allRecords = this.#allRecords.filter(row => row.data.Id !== rowId);
    return result;
  }

  // eslint-disable-next-line class-methods-use-this
  async getRowActions(row, doneCallback) {
    let actions;
    if (row.objectApiName === 'Attachment') {
      actions = [
        {
          label: row.ctrl.#labels.downloadLabel,
          name: DOWNLOAD_ATTACHMENT_ACTION,
        },
        {
          label: row.ctrl.#labels.deleteLabel,
          name: 'delete',
        },
      ];
    } else if (row.objectApiName === 'ContentDocument') {
      actions = [
        {
          label: row.ctrl.#labels.downloadLabel,
          name: DOWNLOAD_FILE_ACTION,
        },
        {
          label: row.ctrl.#labels.viewFileDetailsLabel,
          name: VIEW_FILE_DETAILS_ACTION,
        },
      ];
    } else if (row.objectApiName === 'Note') {
      actions = [
        {
          label: row.ctrl.#labels.editLabel,
          name: EDIT_NOTE_ACTION,
        },
        {
          label: row.ctrl.#labels.deleteLabel,
          name: 'delete',
        },
      ];
    }
    doneCallback(actions);
  }

  // eslint-disable-next-line class-methods-use-this
  handleRowAction(action, row) {
    if (action.name === DOWNLOAD_ATTACHMENT_ACTION) {
      return {
        pageRef: {
          type: 'standard__recordPage',
          attributes: {
            recordId: row.Id,
            objectApiName: 'Attachment',
            actionName: 'view',
          },
        },
      };
    }
    if (action.name === DOWNLOAD_FILE_ACTION) {
      return {
        pageRef: {
          type: 'standard__webPage',
          attributes: {
            url: `/sfc/servlet.shepherd/document/download/${row.Id}`,
          },
        },
      };
    }
    if (action.name === VIEW_FILE_DETAILS_ACTION) {
      return {
        pageRef: {
          type: 'standard__recordPage',
          attributes: {
            recordId: row.Id,
            objectApiName: 'ContentDocument',
            actionName: 'view',
          },
        },
      };
    }
    if (action.name === EDIT_NOTE_ACTION) {
      return {
        pageRef: {
          type: 'standard__recordPage',
          attributes: {
            recordId: row.Id,
            objectApiName: 'Note',
            actionName: 'edit',
          },
        },
      };
    }
    return {};
  }
}