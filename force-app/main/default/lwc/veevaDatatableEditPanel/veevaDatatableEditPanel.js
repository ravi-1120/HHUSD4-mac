import { LightningElement, api } from 'lwc';
import { getService, SERVICES } from 'c/veevaServiceFactory';

const APPLY_DEFAULT_LABEL = 'Apply';
const CANCEL_DEFAULT_LABEL = 'Cancel';
const UPDATE_ITEMS_DEFAULT_LABEL = 'Update {0} selected items';

export default class VeevaDatatableEditPanel extends LightningElement {
  messageMap = {};
  updateAllRows = false;

  @api selectedRows = [];
  @api get initialItem() {
    return this._initialItem;
  };
  set initialItem(value) {
    this.rowId = value.recordId;
    this.updatedItem = value;
    this._initialItem = value;
  }

  get multiRowSelect() {
    return this.selectedRows.length > 1 && this.selectedRows.some(row => row.Id === this.rowId);
  }

  get numberOfSelectedRows() {
    return this.selectedRows.length;
  }

  get applyLabel() {
    return this.messageMap.apply || APPLY_DEFAULT_LABEL;
  }

  get cancelLabel() {
    return this.messageMap.cancel || CANCEL_DEFAULT_LABEL;
  }

  get checkboxLabel() {
    const label = this.messageMap.updateItems || UPDATE_ITEMS_DEFAULT_LABEL;
    return label.replace('{0}', this.numberOfSelectedRows);
  }

  async connectedCallback() {
    this.messageMap = await this.loadVeevaMessages();
  }

  async loadVeevaMessages() {
    const messageSvc = getService(SERVICES.MESSAGE);
    return messageSvc
      .createMessageRequest()
      .addRequest('UPDATE_RELATED_LIST_RECORDS', 'Lightning', UPDATE_ITEMS_DEFAULT_LABEL, 'updateItems')
      .addRequest('APPLY', 'Common', APPLY_DEFAULT_LABEL, 'apply')
      .addRequest('CANCEL', 'Common', CANCEL_DEFAULT_LABEL, 'cancel')
      .sendRequest();
  }

  stopClickPropagation(event) {
    event.stopPropagation();
  }

  handleValueChange(event) {
    if (this.multiRowSelect) {
      event.stopPropagation();
      const dataReceived = event.detail.data[0];
      this.updatedItem = {
        recordId: dataReceived.recordId,
        value: dataReceived.value,
        label: dataReceived.label,
        context: dataReceived.context,
      };
    }
  }

  handleKeyDown(event) {
    if (event.code === 'Escape') {
      this.closePanel();
    }
  }

  handleCancel() {
    this.closePanel();
  }

  handleApply() {
    const updatedItems = [];
    if (this.multiRowSelect && this.updateAllRows) {
      this.selectedRows.forEach(row => {
        const temp = { ...this.updatedItem };
        temp.recordId = row.Id;
        updatedItems.push(temp);
      });
    } else {
      updatedItems.push(this.updatedItem);
    }

    this.dispatchEvent(
      new CustomEvent('valuechange', {
        composed: true,
        bubbles: true,
        cancelable: true,
        detail: { data: updatedItems },
      })
    );
  }

  closePanel() {
    this.dispatchEvent(
      new CustomEvent('closepanel', {
        composed: true,
        bubbles: true,
        cancelable: true,
      })
    );
  }

  handleCheckboxChange(event) {
    this.updateAllRows = event.target.checked;
  }
}