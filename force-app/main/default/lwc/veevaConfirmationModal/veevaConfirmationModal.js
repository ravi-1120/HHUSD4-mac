import { api, LightningElement } from 'lwc';
import { getService } from 'c/veevaServiceFactory';

export default class VeevaConfirmationModal extends LightningElement {
  @api title;
  @api show;
  @api size = 'small';
  @api messages;
  @api messageHorizontalAlign = 'center';
  @api confirmLabel;
  @api cancelLabel;
  @api isCancelPrimaryButton = false;
  @api disableButtons = false;

  defaultConfirmLabel = 'Okay';
  defaultCancelLabel = 'Cancel';

  get confirmButtonLabel() {
    // Perform a "falsy" check on confirmLabel which checks for not null and not empty string
    return this.confirmLabel || this.defaultConfirmLabel;
  }

  get cancelButtonLabel() {
    // Perform a "falsy" check on cancelLabel which checks for not null and not empty string
    return this.cancelLabel || this.defaultCancelLabel;
  }

  get cancelButtonVariant() {
    return (this.isCancelPrimaryButton) ? 'brand' : 'neutral';
  }

  get okayButtonVariant() {
    return (this.isCancelPrimaryButton) ? 'neutral' : 'brand';
  }

  get hasHeader() {
    return !this.title;
  }

  connectedCallback() {
    this.loadDefaultVeevaMessages();
  }

  renderedCallback() {
    const buttonSelector = (this.isCancelPrimaryButton) ? '[data-id="confirm-modal-cancel-button"]' : '[data-id="confirm-modal-ok-button"]';
    const primaryButton = this.template.querySelector(buttonSelector);
    if (primaryButton) {
      primaryButton.focus();
    }
  }

  async loadDefaultVeevaMessages() {
    const veevaMessageService = getService('messageSvc');
    [this.defaultConfirmLabel, this.defaultCancelLabel] = await Promise.all([
      veevaMessageService.getMessageWithDefault('OK', 'Common', this.defaultConfirmLabel),
      veevaMessageService.getMessageWithDefault('CANCEL', 'Common', this.defaultCancelLabel),
    ]);
  }

  /**
   * This method is called whenever the user clicks on the confirmation button on the modal.
   */
  handleModalConfirm() {
    this.dispatchEvent(new CustomEvent('confirm'));
  }

  /**
   * This method is called whenever the user clicks on a button that intends to cancel the confirmation modal.
   */
  handleModalCancel() {
    this.dispatchEvent(new CustomEvent('cancel'));
  }
}