import { LightningElement, api } from 'lwc';
import { VeevaMessageRequest } from 'c/veevaMessageService';

export default class StakeholderNavigatorAccountSearchModal extends LightningElement {

  @api ctrl;
  @api fromAccountId;
  okButtonDisabled = true;
  messageMap = {};
  selected = {};

  async connectedCallback() {
    const msgRequest = new VeevaMessageRequest();
    msgRequest.addRequest('CANCEL', 'Common', 'Cancel', 'msgCancel');
    msgRequest.addRequest('OK', 'Common', 'Ok', 'msgOk');
    msgRequest.addRequest('SELECT_AFFILIATION', 'Account', 'Select Affiliation', 'modalTitle');
    this.messageMap = await this.ctrl.pageCtrl.getMessageMap(msgRequest);
  }

  createEvent() {
    if (this.selected.id === this.fromAccountId) {
      this.dispatchEvent(new CustomEvent('invalidselection'));
    } else {
      this.dispatchEvent(new CustomEvent('accountselection', { detail: this.selected.id }));
    }
  }

  handleCancel() {
    this.selected = {};
    this.okButtonDisabled = true;
    this.dispatchEvent(new CustomEvent('cancel'));
  }

  handleAccountSelected(event) {
    this.selected = event.detail;
    this.okButtonDisabled = false;
  }

  handleSearchCleared() {
    this.okButtonDisabled = true;
    this.selected = {};
  }
}