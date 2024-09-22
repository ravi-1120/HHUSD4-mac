import { LightningElement, api, wire } from 'lwc';
import { getUpdatedDraftValues } from 'c/veevaCustomDraftValue';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import veevaDatatableChannel from '@salesforce/messageChannel/Veeva_Datatable_Channel__c';

const TD_INDEX = 4;
const TR_INDEX = 5;
const EDIT_PANEL_WIDTH = 310;

export default class VeevaEditDatatableContainer extends LightningElement {
  colType;
  _draftValues;

  @api records;
  @api columns;
  @api objectApiName;
  @api get draftValues() {
    return this._draftValues;
  }
  set draftValues(val) {
    this._draftValues = [...val] || [];
  }

  errors;
  inlineEditRowId = ''; // Row triggering inline edit
  initialItem = {};
  editPanelOpen = false;

  @wire(getObjectInfo, { objectApiName: '$objectApiName' })
  wiredObjectInfo({ error, data }) {
    if (data) {
      this.objectInfo = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.objectInfo = undefined;
    }
  }

  @wire(MessageContext)
  messageContext;

  get draftValuesPresent() {
    return this.draftValues?.length > 0;
  }

  get isNumber() {
    return this.colType === 'veevaCurrency' || this.colType === 'veevaNumber';
  }

  get isPicklist() {
    return this.colType === 'picklist';
  }

  get isLookup() {
    return this.colType === 'lookup';
  }

  get isTextArea() {
    return this.colType === 'veevaTextArea';
  }

  get dataTable() {
    if (!this._dataTable) {
      this._dataTable = this.querySelector('[data-table-edit]');
    }
    return this._dataTable;
  }

  get selectedRows() {
    return this.dataTable?.getSelectedRows() || [];
  }

  connectedCallback() {
    document.addEventListener('click', (this._handler = this.closePanel.bind(this)));
    this.subscription = subscribe(this.messageContext, veevaDatatableChannel, message => this.handleMessage(message));
  }

  disconnectedCallback() {
    document.removeEventListener('click', this._handler);
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  handleMessage(message) {
    if (message.action === 'scroll') {
      this.closePanel();
    }
  }

  closePanel() {
    if (this.editPanelOpen) {
      this.template.querySelector('c-veeva-datatable-lookup')?.closeLookup();
      this.inlineEditRowId = '';
      this.togglePanelState();
    }
  }

  setLookupObject(field) {
    let base = field.split('__r')[0];
    base = `${base}__c`;
    this.lookupObject = this.objectInfo.fields[base].referenceToInfos[0].apiName;
  }

  setScale(field) {
    this.scale = this.objectInfo.fields[field]?.scale ?? 0;
  }

  setLength(field) {
    this.length = this.objectInfo.fields[field]?.length ?? 0;
  }

  setInitialItem(draftRecord, record, colName) {
    const fieldValue = draftRecord[colName] ?? record[colName] ?? {};
    this.initialItem = {
      context: this.field,
      value: fieldValue.value,
      label: fieldValue.displayValue ?? fieldValue.value,
      recordId: this.inlineEditRowId,
    };
  }

  // Handles custom column changes like picklists and lookups
  handleValueChange(event) {
    event.stopPropagation();
    const dataRecieved = event.detail.data;
    dataRecieved.forEach(item => {
      const updatedItem = {
        Id: item.recordId,
        value: item.value,
        label: item.label || item.value,
        field: item.context,
      };
      this.draftValues = [...getUpdatedDraftValues(this.draftValues, { ...updatedItem })];
    });
    this.dispatchEvent(
      new CustomEvent('draftchange', {
        detail: this.draftValues,
      })
    );
    if (event.detail.source !== 'LookupCleared') {
      this.closePanel();
    }
  }

  handleClick(event) {
    if (!event.path[0] || event.path[0].tagName !== 'BUTTON') {
      return;
    }
    event.stopPropagation();

    const td = event.path[TD_INDEX];
    const tr = event.path[TR_INDEX];
    const colName = td.dataset.colKeyValue.split('-')[0];
    const colType = td.dataset.colKeyValue.split('-')[1];
    const rowId = tr.dataset.rowKeyValue;
    const record = this.records.find(r => r.Id === rowId) || {};
    const draftRecord = this.draftValues.find(draft => draft.id === rowId) || {};

    this.inlineEditRowId = rowId;
    this.field = colName;
    this.colType = colType;
    this.object = this.objectApiName;
    this.recordtypeId = record.RecordTypeId;

    this.setInitialItem(draftRecord, record, colName);

    if (this.isLookup) {
      this.setLookupObject(this.field);
    } else if (this.isNumber) {
      this.setScale(this.field);
    } else if (this.isTextArea) {
      this.setLength(this.field);
    }

    this.toggleEditPanel(this.getEditPanelXCoordinate(td, tr), this.getEditPanelYCoordinate(td));
    if (!this.editPanelOpen) {
      this.togglePanelState();
    }
  }

  getEditPanelXCoordinate(td, tr) {
    const cellBounds = td.getBoundingClientRect();
    const rowBounds = tr.getBoundingClientRect();
    let { left } = cellBounds;

    // Shift panel left when it overflows the row's right boundary
    if (left + EDIT_PANEL_WIDTH > rowBounds.right) {
      left = cellBounds.right - EDIT_PANEL_WIDTH;
    }
    return left;
  }

  getEditPanelYCoordinate(td) {
    return td.getBoundingClientRect().top;
  }

  toggleEditPanel(x, y) {
    document.documentElement.style.setProperty('--selectionDetailsPopoverXCoord', `${x}px`);
    document.documentElement.style.setProperty('--selectionDetailsPopoverYCoord', `${y}px`);
  }

  togglePanelState() {
    this.dataTable?.toggleEditPanel();
    this.editPanelOpen = !this.editPanelOpen;
  }
}