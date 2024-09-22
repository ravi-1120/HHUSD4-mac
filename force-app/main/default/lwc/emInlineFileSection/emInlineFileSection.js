import { LightningElement, api } from 'lwc';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class EmInlineFileSection extends VeevaErrorHandlerMixin(LightningElement) {
  @api ctrl;
  id;
  pageCtrl;
  meta;
  loading = true;

  connectedCallback() {
    this.pageCtrl = this.ctrl.pageCtrl;
    if (this.pageCtrl.action !== 'New') {
      this.id = this.ctrl.id;
    }
    this.meta = {
      columns: [],
      label: this.ctrl.title,
      objectApiName: 'ContentDocument',
      relationship: 'CombinedAttachments',
    };
    this.loading = false;
  }
}