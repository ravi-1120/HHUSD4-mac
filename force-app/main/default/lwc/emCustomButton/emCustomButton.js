import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import VeevaToastEvent from 'c/veevaToastEvent';
import getButtonController from './buttonControllerFactory';

export default class EmCustomButton extends NavigationMixin(LightningElement) {
  @api meta;
  @api pageCtrl;
  @api disableButton;
  showSpinner = false;

  connectedCallback() {
    if (!this.ctrl) {
      this.ctrl = getButtonController(this.meta, this.pageCtrl);
    }
  }

  get isWarning() {
    return this.meta.isWarning;
  }

  get isMenu() {
    return this.meta.menu;
  }

  get buttonClass() {
    return this.isWarning ? 'slds-card__header-title' : '';
  }

  get title() {
    return this.meta.title ?? this.meta.label;
  }

  get iconName() {
    return this.isWarning ? 'utility:warning' : '';
  }

  get variant() {
    return this.isWarning ? 'destructive-text' : 'neutral';
  }

  async handleClick() {
    this.toggleLoading();
    try {
      if (this.ctrl.isNavigationAction()) {
        this[NavigationMixin.Navigate](this.ctrl.getNavigationUrl());
      } else {
        await this.ctrl.handleClick();
      }
    } catch (error) {
      if (error.message) {
        this.dispatchEvent(VeevaToastEvent.error(error));
      }
    }
    this.toggleLoading();
  }

  toggleLoading() {
    this.showSpinner = !this.showSpinner;
    this.dispatchEvent(new CustomEvent('toggleloading', { bubbles: true, composed: true }));
  }
}