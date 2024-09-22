import { LightningElement, api, track } from 'lwc';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

const OPEN_ICON = 'utility:chevrondown';
const CLOSE_ICON = 'utility:chevronright';
const OPEN_CLASS = 'slds-section slds-is-open';
const CLOSE_CLASS = 'slds-section slds-is-close';

export default class SectionTemplate extends VeevaErrorHandlerMixin(LightningElement) {
  @api ctrl;
  @api first;
  @api record;
  @api heading;
  @api rawHeading;
  @api recordUpdateFlag;

  @track expanderIcon;
  @track sectionClass;

  currentElementSelector = 'c-section-template[data-validity]';
  validityElementsSelector = 'c-veeva-row';

  @api get open() {
    return this._open;
  }

  set open(value) {
    this._open = value;
    this.expanderIcon = this._open ? OPEN_ICON : CLOSE_ICON;
    this.sectionClass = this._open ? OPEN_CLASS : CLOSE_CLASS;
  }

  get displayHeader() {
    if (this.ctrl?.meta?.useHeading == null) {
      return true;
    }
    return this.ctrl?.meta?.useHeading;
  }

  get sectionHeading() {
    return this.heading || this.ctrl.title;
  }

  get sectionRawHeading() {
    return this.rawHeading || this.ctrl.meta.rawHeading;
  }

  get layoutRows() {
    return this.ctrl?.meta?.layoutRows || [];
  }

  toggleSection() {
    this.open = !this.open;
  }

  @api refreshComponent(key) {
    const children = this.getDataValidityElements();
    children.forEach(child => {
      if (child.refreshComponent) {
        child.refreshComponent(key);
      }
    });
  }
}