import { api, LightningElement } from 'lwc';

export default class veevaPopover extends LightningElement {
  @api nubbin;
  @api size;
  @api type = 'panel';
  @api showCloseButton = false;
  @api closeButtonVariant = '';
  @api fadeIn = false;

  footerSlotClass = '';
  headerSlotClass = '';

  get popoverClass() {
    let css = `veeva-popover slds-popover slds-popover_${this.type}`;
    if (this.size) {
      css += ` slds-popover_${this.size}`;
    } else {
      css += ' veeva-popover_size-hook';
    }
    if (this.nubbin) {
      css += ` slds-nubbin_${this.nubbin}`;
    }
    if (this.type === 'prompt') {
      css += ' veeva-prompt-top-center';
    } else if (this.type === 'panel') {
      css += ' veeva-popover-panel';
    }
    if (this.fadeIn) {
      css += ' fade-in';
    }
    return css;
  }

  handleFooterSlotChange(evt) {
    const slot = evt.target;
    const hasFooter = slot.assignedElements().length !== 0;
    this.footerSlotClass = hasFooter ? 'slds-popover__footer' : '';
  }

  handleHeaderSlotChange(evt) {
    const slot = evt.target;
    const hasHeader = slot.assignedElements().length !== 0;
    this.headerSlotClass = hasHeader ? 'slds-popover__header veeva-popover-header' : '';
  }

  close() {
    this.dispatchEvent(new CustomEvent('close'));
  }
}