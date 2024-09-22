import { LightningElement, api } from 'lwc';
import SearchLookupTemplate from './veevaSearchLookupTemplate.html';

export default class VeevaSearchLookupTemplate extends LightningElement {
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

  render() {
    return this.ctrl?.searchLookupTemplate || SearchLookupTemplate;
  }
}