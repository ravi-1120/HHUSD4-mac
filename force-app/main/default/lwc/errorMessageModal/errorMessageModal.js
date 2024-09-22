import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { api, track, LightningElement } from 'lwc';

export default class ErrorMessageModal extends LightningElement {
  @api errorMessage;
  @track errorMessages = [];
  @track showAlert = false;

  connectedCallback() {
    this.errorMessages = [this.errorMessage];
    this.showAlert = true;
  }

  finishFlow() {
    this.dispatchEvent(new FlowNavigationFinishEvent());
  }
}