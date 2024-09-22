import VeevaRelatedListController from 'c/veevaRelatedListController';
import VeevaConstant from 'c/veevaConstant';
import fetchFiles from '@salesforce/apex/NotesAttachmentsFilesController.fetchFiles';
import fetchNotesAttachmentsFiles from '@salesforce/apex/NotesAttachmentsFilesController.fetchNotesAttachmentsFiles';
import LAST_MODIFIED_DATE from '@salesforce/schema/ContentDocument.LastModifiedDate';
import CONTENT_SIZE from '@salesforce/schema/ContentDocument.ContentSize';

export default class EmInlineFilesRelatedListController extends VeevaRelatedListController {
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
    this.#labelsPromise = this.loadLabels();
    if (!pageCtrl.unlinkedDocumentIds) {
      pageCtrl.unlinkedDocumentIds = [];
    }
  }

  get defaultSortColumn() {
    return 'LastModifiedDate';
  }

  get defaultSortDirection() {
    return 'desc';
  }

  get showFileUpload() {
    return this.pageCtrl.objectInfo.updateable && this.pageCtrl.shouldShowFileUpload;
  }

  async loadLabels() {
    this.#labels = await this.pageCtrl.messageSvc
      .createMessageRequest()
      .addRequest('KB', 'TABLET', 'KB', 'kbLabel')
      .addRequest('MB', 'TABLET', 'MB', 'mbLabel')
      .addRequest('DELETE', 'Common', 'Delete', 'deleteLabel')
      .addRequest('OWNER', 'Common', 'Owner', 'ownerLabel')
      .sendRequest();
  }

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
        label: this.#labels.ownerLabel,
        name: 'Owner.Name',
      },
      {
        label: this.objectDescribe.fields.LastModifiedDate.label,
        name: LAST_MODIFIED_DATE.fieldApiName,
      },
      {
        label: this.objectDescribe.fields.ContentSize.label,
        name: CONTENT_SIZE.fieldApiName,
      },
    ];

    const columns = await super.getColumns();
    return columns;
  }

  getLinkNameColumn(col) {
    const linkNameColumn = {
      fieldName: col.name,
      label: col.label,
      type: 'text',
      hideDefaultActions: true,
      sortable: true,
      cellAttributes: {
        iconName: { fieldName: 'icon' },
        iconLabel: { fieldName: 'displayValue' },
      },
    };
    return linkNameColumn;
  }

  getColumnType(columnName) {
    switch (columnName) {
      case CONTENT_SIZE.fieldApiName:
      case LAST_MODIFIED_DATE.fieldApiName:
      case 'Owner.Name':
        return 'text';
      default:
        return super.getColumnType(columnName);
    }
  }

  isLookup(field) {
    if (field === 'Owner.Name') {
      return false;
    }
    return super.isLookup(field);
  }

  async fetchRecords({ id, offset, qlimit, sortBy, sortDirection }) {
    await this.#labelsPromise;
    if (offset === 0 || !this.#allRecords) {
      if (id) {
        if (sortBy === CONTENT_SIZE.fieldApiName) {
          this.#allRecords = await fetchNotesAttachmentsFiles({ recordId: id });
          this.#allRecords = this.#allRecords.filter(record => record.type !== 'note').sort(this.sortRecordsByContentSizeAsc);
          if (sortDirection === 'desc') {
            this.#allRecords.reverse();
          }
        } else {
          this.#allRecords = await fetchNotesAttachmentsFiles({ recordId: id, sortBy, sortDirection });
          this.#allRecords = this.#allRecords.filter(record => record.type !== 'note');
        }
      } else if (this.pageCtrl.unlinkedDocumentIds.length !== 0) {
        this.#allRecords = await fetchFiles({ contentDocIds: this.pageCtrl.unlinkedDocumentIds, sortBy, sortDirection });
      } else {
        this.#allRecords = [];
      }
    }
    return this.#allRecords.slice(offset, offset + qlimit);
  }

  sortRecordsByContentSizeAsc(record1, record2) {
    const size1 = record1?.data?.ContentSize || 0;
    const size2 = record2?.data?.ContentSize || 0;
    return size1 - size2;
  }

  async fetchRecordsWithTotals(params) {
    const records = await this.fetchRecords(params);
    return { records, recordTotalCount: this.#allRecords.length };
  }

  processRecords(data) {
    if (data && data.length > 0) {
      let records = [];
      if (this.pageCtrl.action === 'New') {
        records = data.map(record => ({ ...record, displayValue: record.Title, 'Owner.Name': record.Owner.Name }));
      } else {
        records = data.map(record => ({
          ...record.data,
          LastModifiedDate: record.lastModifiedDate,
          displayValue: record.data.Title,
          'Owner.Name': record.data.Owner.Name,
          type: record.type,
        }));
      }
      return super.processRecords(records);
    }
    return [];
  }

  processRecord(record) {
    const processedRecord = super.processRecord(record);
    if (this.pageCtrl.action === 'New') {
      this.processFileRecords(processedRecord);
    } else {
      this.processsNotesAttachmentsFileRecords(processedRecord);
    }
    return processedRecord;
  }

  processsNotesAttachmentsFileRecords(record) {
    if (record.type === 'attachment') {
      record.icon = 'doctype:attachment';
      record.objectApiName = 'Attachment';
    } else if (record.type === 'file') {
      this.processFileRecords(record);
    }
  }

  processFileRecords(record) {
    record.icon = `doctype:${VeevaConstant.FILE_TYPE_TO_ICON[record.FileExtension?.toLowerCase()] || 'unknown'}`;
    record.objectApiName = 'ContentDocument';

    let displaySize = Math.floor(record.ContentSize / VeevaConstant.BYTES_PER_KB);
    let units = this.#labels.kbLabel;
    if (displaySize > VeevaConstant.BYTES_PER_KB) {
      displaySize = (displaySize / VeevaConstant.BYTES_PER_KB).toFixed(1);
      units = this.#labels.mbLabel;
    }
    record.ContentSize = `${displaySize}${units}`;
  }

  async deleteRow(rowId, objectApiName) {
    const result = await super.deleteRow(rowId, objectApiName);
    this.#allRecords = this.#allRecords.filter(row => (row.data?.Id || row.Id) !== rowId);
    if (this.pageCtrl.action === 'New') {
      this.pageCtrl.unlinkedDocumentIds = this.pageCtrl.unlinkedDocumentIds.filter(id => id !== rowId);
    }
    return result;
  }

  async getRowActions(row, doneCallback) {
    const actions = [
      {
        label: row.ctrl.#labels.deleteLabel,
        name: 'delete',
      },
    ];
    doneCallback(actions);
  }

  handleUploadFinished(files) {
    if (this.pageCtrl.action === 'New' && files?.length > 0) {
      this.pageCtrl.unlinkedDocumentIds.push(...files.map(file => file.documentId));
    }
  }
}