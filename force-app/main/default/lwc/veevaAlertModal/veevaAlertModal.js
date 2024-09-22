import { api, LightningElement } from 'lwc';
import { getService } from 'c/veevaServiceFactory';

export default class VeevaAlertModal extends LightningElement {
  @api title;
  @api show;
  @api size = 'small';
  @api messages;
  @api messageHorizontalAlign = 'center';
  @api footerHorizontalAlign = 'end';
  @api iconLogo;
  @api okayLabel;
  @api buttonStyle;
  @api headerStyle;
  @api footerStyle;
  @api hideCloseIcon;
  @api minimizeWidth = false;

  defaultOkayLabel = 'Okay';
  defaultButtonStyle = 'brand';
  _messageMarginSize;
  get okayButtonLabel() {
    // Perform a "falsy" check on okayLabel which checks for not null and not empty string
    return this.okayLabel || this.defaultOkayLabel;
  }

  get okayButtonStyle() {
      return this.buttonStyle || this.defaultButtonStyle;
  }

  get hasHeader() {
    return !this.title;
  }

  connectedCallback() {
    this.loadDefaultVeevaMessages();
  }

  renderedCallback() {
    const okayButton = this.template.querySelector('lightning-button');
    if (okayButton) {
      okayButton.focus();
    }
  }

  async loadDefaultVeevaMessages() {
    const veevaMessageService = getService('messageSvc');
    this.defaultOkayLabel = await veevaMessageService.getMessageWithDefault('OK', 'Common', this.defaultOkayLabel);
  }

  /**
   * This method is called whenever the user clicks on a button that closes the modal.
   */
  handleModalClose() {
    this.close();
  }

  /**
   * This method is called whenever the user clicks the confirmation/okay button on the alert.
   *
   * Note since this is a alert modal we will still emit the same onclose event if the user clicks the close icon or "Okay"
   */
  handleModalConfirm() {
    this.close();
  }

  close() {
    this.dispatchEvent(new CustomEvent('close'));
  }
  @api
  get messageMarginSize() {
    if (this._messageMarginSize) {
      return this._messageMarginSize;
    }
    return "slds-var-m-around_small";
  }
  set messageMarginSize(size) {
    if (size === "large") {
      this._messageMarginSize = "slds-var-m-around_x-large";
    }
  }
}