import VeevaConfirmationLightningModal from 'c/veevaConfirmationLightningModal';
import VeevaRelatedListController from 'c/veevaRelatedListController';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import VeevaToastEvent from 'c/veevaToastEvent';

import fetchNotes from '@salesforce/apex/NotesAttachmentsFilesController.fetchNotes';
import { deleteRecord } from 'lightning/uiRecordApi';

const REMOVE_FROM_RECORD_ACTION = 'removeFromRecord';

export default class VeevaNotesRelatedListController extends VeevaRelatedListController {
  #allRecords;
  #labels;
  #labelsPromise = this.loadNoteLabels();

  get meta() {
    return this._meta;
  }

  set meta(value) {
    this._meta = { ...value };
  }

  get defaultSortColumn() {
    return 'LastModifiedDate';
  }

  get defaultSortDirection() {
    return 'desc';
  }

  async loadNoteLabels() {
    this.#labels = await this.pageCtrl.messageSvc
      .createMessageRequest()
      .addRequest('CANCEL', 'Common', 'Cancel', 'cancel')
      .addRequest('CONTENT_DOCUMENT_LINK_DELETED', 'Lightning', 'Content Document Link was deleted', 'removeSuccess')
      .addRequest('CREATEDBY', 'Common', 'Created By', 'createdBy')
      .addRequest('DELETE', 'Common', 'Delete', 'delete')
      .addRequest('LAST_MOD', 'Common', 'Last Modified By', 'lastModifiedBy')
      .addRequest('REMOVE_FROM_RECORD', 'Common', 'Remove from Record', 'removeFromRecord')
      .addRequest(
        'REMOVE_NOTE_FROM_RECORD_BODY',
        'Lightning',
        'If you remove the note from this record, people with access to the record may not be able to see the note.',
        'removeConfirmBody'
      )
      .addRequest('REMOVE_NOTE_HEADER', 'Lightning', 'Remove note from {0}?', 'removeConfirmHeader')
      .addRequest('REMOVE', 'Common', 'Remove', 'remove')
      .sendRequest();
  }

  async getColumns() {
    await this.#labelsPromise;
    this.meta.columns = [
      {
        label: this.objectDescribe.fields.Title.label,
        name: 'Title',
      },
      {
        label: this.objectDescribe.fields.TextPreview.label,
        name: 'TextPreview',
      },
      {
        label: this.#labels.createdBy,
        name: 'CreatedBy.Name',
      },
      {
        label: this.objectDescribe.fields.LastModifiedDate.label,
        name: 'LastModifiedDate',
      },
      {
        label: this.#labels.lastModifiedBy,
        name: 'LastModifiedBy.Name',
      },
    ];
    return super.getColumns();
  }

  getColumnType(columnName) {
    let colType = super.getColumnType(columnName);
    if (colType !== 'lookup') {
      colType = 'text';
    }
    return colType;
  }

  async fetchRecords({ id, offset, qlimit, sortBy, sortDirection }) {
    await this.#labelsPromise;
    if (offset === 0) {
      this.#allRecords = await fetchNotes({ recordId: id, sortBy, sortDirection });
    }
    return this.#allRecords.slice(offset, offset + qlimit);
  }

  async fetchRecordsWithTotals(params) {
    const records = await this.fetchRecords(params);
    return { records, recordTotalCount: this.#allRecords.length };
  }

  async getPageRefForNew() {
    const baseDataSvc = getService(SERVICES.BASE_DATA);
    const response = await baseDataSvc.createRecord({ parentId: this.pageCtrl.id }, 'content-notes');
    return {
      type: 'standard__objectPage',
      attributes: {
        objectApiName: 'ContentNote',
        actionName: 'home',
      },
      state: {
        recordId: response.data.Id,
      },
    };
  }

  async deleteRow(rowId, objectApiName) {
    const result = await super.deleteRow(rowId, objectApiName);
    this.#allRecords = this.#allRecords.filter(row => row.Id !== rowId);
    return result;
  }

  async getRowActions(row, doneCallback) {
    const actions = [
      {
        label: this.#labels.delete,
        name: 'delete',
      },
      {
        label: this.#labels.removeFromRecord,
        name: REMOVE_FROM_RECORD_ACTION,
      },
    ];
    doneCallback(actions);
  }

  async handleRowAction(action, row) {
    if (action.name === REMOVE_FROM_RECORD_ACTION) {
      return this.removeFromRecord(row);
    }
    return {};
  }

  async removeFromRecord(row) {
    const response = {};
    const modalResult = await VeevaConfirmationLightningModal.open({
      title: this.#labels.removeConfirmHeader.replace('{0}', this.pageCtrl.record.name),
      messages: [this.#labels.removeConfirmBody],
      confirmLabel: this.#labels.remove,
      cancelLabel: this.#labels.cancel,
      buttonHorizontalAlign: 'center',
      centerMessagesAbsolutely: true,
      size: 'small',
    });
    if (!modalResult) {
      return response;
    }
    try {
      await deleteRecord(row.contentDocumentLinkId);
      response.refreshRecords = true;
      response.toastEvent = VeevaToastEvent.successMessage(this.#labels.removeSuccess);
    } catch (error) {
      response.toastEvent = VeevaToastEvent.error(error);
    }
    return response;
  }
}