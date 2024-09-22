import LookupDataReferenceController from 'c/lookupDataReferenceController';
import template from './searchTemplate.html';

export default class VenueReferenceController extends LookupDataReferenceController {
  static searchLookupTemplate = template;

  searchLookupTemplate = VenueReferenceController.searchLookupTemplate; // Overrides the veevaSearchLookup template
  location = ''; // Search for location on venue search modal

  getQueryParams(term) {
    const queryParams = super.getQueryParams(term);
    return this.location ? { ...queryParams, location: this.location } : queryParams;
  }
}