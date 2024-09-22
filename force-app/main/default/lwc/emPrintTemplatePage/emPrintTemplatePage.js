import { LightningElement, api } from 'lwc';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import EmEventConstant from 'c/emEventConstant';

export default class EmPrintTemplatePage extends LightningElement {
  @api recordId;
  display = false;
  meta;

  connectedCallback() {
    registerListener(EmEventConstant.DISPLAY_PRINT_TEMPLATE_DIALOG, this.displayDialog, this);
  }

  disconnectedCallback() {
    unregisterAllListeners(this);
  }

  displayDialog(meta) {
    this.meta = meta;
    this.display = true;
  }

  handleClose() {
    this.display = false;
  }
}