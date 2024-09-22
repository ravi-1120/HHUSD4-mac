import { api, LightningElement } from 'lwc';

import VeevaToastEvent from 'c/veevaToastEvent';

export default class MyAccountsModalDispatch extends LightningElement {
  /**
   * This method allows us to dispatch error toasts for any modal created using LightningModal.
   *
   * According to https://salesforce.stackexchange.com/questions/387924/lightning-modal-custom-event-not-working-in-winter-23-release
   * Without enabling Lightning Web Security we cannot dispatch events from elements extending LightningModal
   */
  @api
  dispatchErrorToast(e) {
    const toastError = VeevaToastEvent.error(e);
    this.dispatchEvent(toastError);
  }

  /**
   * This method allows us to dispatch custom event for any modal created using LightningModal.
   *
   * According to https://salesforce.stackexchange.com/questions/387924/lightning-modal-custom-event-not-working-in-winter-23-release
   * Without enabling Lightning Web Security we cannot dispatch events from elements extending LightningModal
   */
  @api
  dispatchCustomEvent(e) {
    this.dispatchEvent(e);
  }
}