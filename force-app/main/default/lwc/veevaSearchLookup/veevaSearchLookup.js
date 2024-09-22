import { LightningElement, api } from 'lwc';

export default class VeevaSearchLookup extends LightningElement {
  @api ctrl; // Reference field controller
  @api customIcons = false;
  @api isObjectSearchPopup = false;
  @api startTerm = '';

  handleLookupSelection(event) {
    event.stopPropagation();
    this.propagateEvent('lookupselection', event.detail);
  }

  startSearch(event) {
    event.stopPropagation();
    this.propagateEvent('searchmode', event.detail);
  }

  propagateEvent(eventName, detail) {
    this.dispatchEvent(new CustomEvent(eventName, { detail }));
  }
}