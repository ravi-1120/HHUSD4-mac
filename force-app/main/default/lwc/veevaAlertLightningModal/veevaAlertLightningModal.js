import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { getService, SERVICES } from 'c/veevaServiceFactory';

export default class VeevaAlertLightningModal extends LightningModal {
  @api title;
  @api messages;
  @api messageHorizontalAlign = 'center';
  @api footerHorizontalAlign = 'end';
  @api iconLogo;
  @api confirmLabel;
  @api buttonVariant;

  defaultConfirmationLabel = 'Okay';
  defaultButtonVariant = 'brand';
  _messageMarginSize;

  get confirmButtonLabel() {
    return this.confirmLabel || this.defaultConfirmationLabel;
  }

  get confirmButtonVariant() {
    return this.buttonVariant || this.defaultButtonVariant;
  }

  connectedCallback() {
    this.loadDefaultVeevaMessages();
  }

  renderedCallback() {
    const confirmButton = this.template.querySelector('lightning-button');
    if (confirmButton) {
      confirmButton.focus();
    }
  }

  async loadDefaultVeevaMessages() {
    const veevaMessageService = getService(SERVICES.MESSAGE);
    this.defaultConfirmationLabel = await veevaMessageService.getMessageWithDefault('OK', 'Common', this.defaultConfirmationLabel);
  }

  handleModalConfirm() {
    this.close();
  }

  @api
  get messageMarginSize() {
    if (this._messageMarginSize) {
      return this._messageMarginSize;
    }
    return 'slds-var-m-around_small';
  }
  set messageMarginSize(size) {
    if (size === 'large') {
      this._messageMarginSize = 'slds-var-m-around_x-large';
    }
  }
}