import VeevaSearchLookup from 'c/veevaSearchLookup';
import { getService, SERVICES } from 'c/veevaServiceFactory';

/**
 * EmVenueSearchLookup slots into VeevaSearchResults on VeevaSearch modal
 * The component consists of
 * 1. VeevaLookup
 * 2. lightning-input text field Location
 * 3. lightning-button Search
 */

export default class EmVenueSearchLookup extends VeevaSearchLookup {
  searchTerm = ''; // Store search term so that search button can dispatch the value on click
  messages = {};

  handleInputChange(event) {
    this.setLocation(event.detail.value);
  }

  async connectedCallback() {
    this.setLocation('');
    this.messages = await getService(SERVICES.MESSAGE)
      .createMessageRequest()
      .addRequest('SEARCH', 'Common', 'Search', 'search')
      .addRequest('LOCATION', 'Common', 'Location', 'location')
      .sendRequest();
  }

  disconnectedCallback() {
    this.setLocation('');
  }

  setLocation(value) {
    this.ctrl.location = value;
  }

  handleSearchButtonClick() {
    this.dispatchEvent(new CustomEvent('searchmode', { detail: { search: true, term: this.searchTerm } }));
  }

  handleChange(event) {
    this.searchTerm = event.detail.value;
  }
}