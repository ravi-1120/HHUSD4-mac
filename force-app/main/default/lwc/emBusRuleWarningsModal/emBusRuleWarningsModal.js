import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';

import WarningsModalController from './warningsModalController';

export default class EmBusRuleWarningsModal extends LightningModal {
  @api warnings;
  @api type;

  @track page = {};

  checkedRows = [];
  componentInitialized = false;
  loading = true;
  messages = {};

  async connectedCallback() {
    if (!this.componentInitialized) {
      this.componentInitialized = true;
      this.ctrl = new WarningsModalController(this.warnings, this.type);
      this.page = await this.ctrl.getPage();
      this.loading = false;
    }
  }

  handleCheckboxSelectionChange(event) {
    this.checkedRows = event.detail.checkedRows;
  }

  handleContinue() {
    this.close({ recordsToRemove: this.checkedRows, success: true });
  }
}