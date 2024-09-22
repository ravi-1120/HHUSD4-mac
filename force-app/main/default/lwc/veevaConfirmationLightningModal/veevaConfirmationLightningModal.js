import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { getService, SERVICES } from 'c/veevaServiceFactory';

export default class VeevaConfirmationLightningModal extends LightningModal {
  @api title;
  @api messages;
  @api confirmLabel;
  @api cancelLabel;
  @api messageHorizontalAlign = 'center';
  @api buttonHorizontalAlign = 'end';
  @api centerMessagesAbsolutely = false;
  @api isCancelPrimaryButton = false;

  defaultConfirmLabel = 'Okay';
  defaultCancelLabel = 'Cancel';

  get confirmButtonLabel() {
    return this.confirmLabel || this.defaultConfirmLabel;
  }

  get cancelButtonLabel() {
    return this.cancelLabel || this.defaultCancelLabel;
  }

  get cancelButtonVariant() {
    return this.isCancelPrimaryButton ? 'brand' : 'neutral';
  }

  get okayButtonVariant() {
    return this.isCancelPrimaryButton ? 'neutral' : 'brand';
  }

  get messageStyling() {
    return this.centerMessagesAbsolutely ? 'modal-content-message slds-align_absolute-center' : 'modal-content-message';
  }

  connectedCallback() {
    this.loadDefaultVeevaMessages();
  }

  async loadDefaultVeevaMessages() {
    const msgMap = await getService(SERVICES.MESSAGE)
      .createMessageRequest()
      .addRequest('OK', 'Common', this.defaultConfirmLabel, 'defaultConfirmLabel')
      .addRequest('CANCEL', 'Common', this.defaultCancelLabel, 'defaultCancelLabel')
      .sendRequest();
    this.defaultCancelLabel = msgMap.defaultCancelLabel;
    this.defaultConfirmLabel = msgMap.defaultConfirmLabel;
  }

  handleModalConfirm() {
    this.close('confirm');
  }

  handleModalCancel() {
    this.close();
  }
}