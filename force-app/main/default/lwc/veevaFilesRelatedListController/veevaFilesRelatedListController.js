import VeevaConstant from 'c/veevaConstant';
import VeevaRelatedListController from 'c/veevaRelatedListController';
import fetchFiles from '@salesforce/apex/NotesAttachmentsFilesController.fetchFiles';
import CONTENT_SIZE from '@salesforce/schema/ContentDocument.ContentSize';
import LAST_MODIFIED_DATE from '@salesforce/schema/ContentDocument.LastModifiedDate';

const DOWNLOAD_FILE_ACTION = 'downloadFile';
const VIEW_FILE_DETAILS_ACTION = 'viewFileDetails';

export default class VeevaFilesRelatedListController extends VeevaRelatedListController {
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
    this.#labelsPromise = this.loadFileLabels();
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

  async loadFileLabels() {
    this.#labels = await this.pageCtrl.messageSvc
      .createMessageRequest()
      .addRequest('KB', 'TABLET', 'KB', 'kbLabel')
      .addRequest('MB', 'TABLET', 'MB', 'mbLabel')
      .addRequest('DOWNLOAD', 'Common', 'Download', 'downloadLabel')
      .addRequest('VIEW_FILE_DETAILS', 'Lightning', 'View File Details', 'viewFileDetailsLabel')
      .addRequest('OWNER', 'Common', 'Owner', 'ownerLabel')
      .sendRequest();
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
    return super.getColumns();
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
        class: 'iconCell',
      },
    };
    return linkNameColumn;
  }

  getColumnType(columnName) {
    let colType = '';
    if (columnName === CONTENT_SIZE.fieldApiName || columnName === LAST_MODIFIED_DATE.fieldApiName) {
      colType = 'text';
    } else {
      colType = super.getColumnType(columnName);
    }
    return colType;
  }

  async fetchRecords({ id, offset, qlimit, sortBy, sortDirection }) {
    await this.#labelsPromise;
    if (offset === 0) {
      this.#allRecords = await fetchFiles({ recordId: id, sortBy, sortDirection });
    }
    return this.#allRecords.slice(offset, offset + qlimit);
  }

  async fetchRecordsWithTotals(params) {
    const records = await this.fetchRecords(params);
    return { records, recordTotalCount: this.#allRecords.length };
  }

  processRecords(data) {
    if (data && data.length > 0) {
      const records = data.map(record => ({ ...record, displayValue: record.Title }));
      return super.processRecords(records);
    }
    return [];
  }

  processRecord(record) {
    const processedRecord = super.processRecord(record);
    let displaySize = Math.floor(record.ContentSize / VeevaConstant.BYTES_PER_KB);
    let units = this.#labels.kbLabel;
    if (displaySize > VeevaConstant.BYTES_PER_KB) {
      displaySize = (displaySize / VeevaConstant.BYTES_PER_KB).toFixed(1);
      units = this.#labels.mbLabel;
    }
    processedRecord.ContentSize = `${displaySize}${units}`;
    processedRecord.linkName = `/lightning/page/filePreview?selectedRecordId=${record.Id}`;
    processedRecord.icon = `doctype:${VeevaConstant.FILE_TYPE_TO_ICON[record.FileExtension?.toLowerCase()] || 'unknown'}`;
    return processedRecord;
  }

  // eslint-disable-next-line class-methods-use-this
  async getRowActions(row, doneCallback) {
    const actions = [
      {
        label: row.ctrl.#labels.downloadLabel,
        name: DOWNLOAD_FILE_ACTION,
      },
      {
        label: row.ctrl.#labels.viewFileDetailsLabel,
        name: VIEW_FILE_DETAILS_ACTION,
      },
    ];
    doneCallback(actions);
  }

  // eslint-disable-next-line class-methods-use-this
  handleRowAction(action, row) {
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
    return {};
  }
}