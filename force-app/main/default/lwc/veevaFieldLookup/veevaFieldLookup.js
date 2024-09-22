import { LightningElement, api, track } from 'lwc';
import VeevaErrorHandlerMixin from 'c/veevaErrorHandlerMixin';

export default class VeevaFieldLookup extends VeevaErrorHandlerMixin(LightningElement) {
  @api ctrl;
  @track searchTerm = '';
  searchIconClicked;
  startTerm = '';
  currentElementSelector = 'c-veeva-field-lookup';
  validityElementsSelector = '[data-validity]';
  checkValidityOnRender = false;

  get isMultiobject() {
    return this.ctrl && this.ctrl.meta && this.ctrl.meta.objectList;
  }

  get showSearchModal() {
    return this.searchTerm || this.searchIconClicked;
  }

  handleSelection(evt) {
    this.resetSearch();
    this.ctrl.setFieldValue(evt.detail.id, evt.detail);
    this.refreshLookupSelectedValue();
    const changedEvent = new CustomEvent('change');
    this.dispatchEvent(changedEvent);
  }

  handleClear() {
    this.ctrl.setFieldValue(null);
    const changedEvent = new CustomEvent('change');
    this.dispatchEvent(changedEvent);
  }

  handleClose() {
    this.startTerm = this.searchTerm;
    this.searchTerm = '';
    // set the flag to check validity on veevaLookup
    this.checkValidityOnRender = true;
    this.searchIconClicked = false;
  }

  startSearch(event) {
    this.searchTerm = event.detail.term;
    if (!this.searchTerm) {
      this.searchIconClicked = true;
    }
  }

  resetSearch() {
    this.startTerm = '';
    this.searchTerm = '';
    this.searchIconClicked = false;
  }

  /**
   * Method rerenders veevaLookup in case startTerm is unchanged
   */
  refreshLookupSelectedValue() {
    this.template.querySelector(this.validityElementsSelector)?.refreshSelectedValue();
  }
}