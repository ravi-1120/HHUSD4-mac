import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';

import { BusRuleConstant } from 'c/emBusRuleUtils';

import LightningAlert from 'lightning/alert';
import ViolationsModalController from './violationsModalController';

export default class EmBusRuleViolationsModal extends LightningModal {
  @api violations = [];
  @api buttonName;
  @api eventId;
  @api eventName;
  @api entryPoint;

  componentInitialized = false;
  loading;

  @track _page;

  get page() {
    return this._page ?? {};
  }

  set page(value) {
    if (value.close) {
      this.close(value.close);
    } else {
      this._page = value;
      this.checkedRows = [];
      this.overrides = [];
    }
  }

  get buttons() {
    return this.page.buttons ?? [];
  }

  async connectedCallback() {
    if (!this.componentInitialized) {
      this.componentInitialized = true;
      this.loading = true;
      this.modalCtrl = new ViolationsModalController(this.buttonName, this.eventId, this.eventName, this.violations, this.entryPoint);
      this.page = await this.modalCtrl.getNextPage();
      this.loading = false;
    }
  }

  handleButton(event) {
    this.handleButtonAsync(event.currentTarget.name);
  }

  async handleButtonAsync(buttonName) {
    try {
      this.loading = true;
      this.buttons.forEach(button => {
        button.disabled = true;
      });
      this.page = await this.modalCtrl.handleButton(buttonName, this.overrides, this.checkedRows);
    } catch (error) {
      // eslint-disable-next-line @locker/locker/distorted-xml-http-request-window-open
      await LightningAlert.open({
        message: error.message || this.messages.ERROR_EVENT_BUSINESS_RULE_SYSTEM_DESCRIPTION,
        theme: 'error',
        variant: 'headerless',
      });
      this.buttons.forEach(button => {
        button.disabled = false;
      });
    } finally {
      this.loading = false;
    }
  }

  handleOverridesChange(event) {
    this.overrides = event.detail.overrides;
    const formIncomplete = this.overrides.some(
      override => override.Comment_Box_vod__c === BusRuleConstant.COMMENT_TYPE.REQUIRED && !override.Comment_vod__c?.trim().length
    );
    const saveOverridesContinueButton = this.buttons.find(button => button.name === BusRuleConstant.ACTION_NAME.SAVE_OVERRIDES_CONTINUE);
    if (saveOverridesContinueButton) {
      if (formIncomplete) {
        saveOverridesContinueButton.disabled = true;
      } else {
        saveOverridesContinueButton.disabled = false;
      }
    }
  }

  handleCheckboxSelectionChange(event) {
    this.checkedRows = event.detail.checkedRows;
  }
}