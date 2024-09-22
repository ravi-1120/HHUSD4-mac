import isEnhancedLookupEnabled from '@salesforce/apex/VeevaLookupDataHelper.isEnhancedLookupEnabled';
import getLookupFiltersForObject from '@salesforce/apex/VeevaLookupDataHelper.getLookupFiltersForObject';

export default class LookupDataService {
  constructor(dataSvc) {
    this.dataSvc = dataSvc;
  }

  async search(object, queryParams) {
    const path = `/api/v1/layout3/lookup/${object}`;
    return this.dataSvc.sendRequest('GET', path, queryParams, null, 'lookupSearch');
  }

  async enhancedSearch(object, queryParams, payload) {
    const path = `/api/v1/layout3/lookup/${object}/enhanced`;
    return this.dataSvc.sendRequest('POST', path, queryParams, payload, 'enhancedLookupSearch');
  }

  /**
   * Used when searching for venue on Epense Header Object
   */
  async venueSearch(object, queryParams) {
    const path = `/api/v1/layout3/lookup/${object}/venue`;
    return this.dataSvc.sendRequest('GET', path, queryParams, null, 'lookupSearch');
  }

  async isEnhancedLookupEnabled() {
    return isEnhancedLookupEnabled();
  }

  async getLookupFiltersForObject(objectName) {
    return getLookupFiltersForObject({ objectName });
  }
}