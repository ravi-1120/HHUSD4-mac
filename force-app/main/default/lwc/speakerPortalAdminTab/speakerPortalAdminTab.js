import { LightningElement, track } from 'lwc';
import { getService } from 'c/veevaServiceFactory';
import VeevaToastEvent from 'c/veevaToastEvent';
import SpeakerPortalDataService from 'c/speakerPortalDataService';

export default class SpeakerPortalAdminTab extends LightningElement {
  @track messageMap = {};
  loading = false;
  speakerPortalDataSvc;

  async connectedCallback() {
    this.messageMap = await this.loadVeevaMessages();
    this.speakerPortalDataSvc = new SpeakerPortalDataService(getService('sessionSvc'));
  }

  async loadVeevaMessages() {
    const messageSvc = getService('messageSvc');
    return messageSvc
      .createMessageRequest()
      .addRequest('INTEGRATION_ADMIN_PAGE_CLEAR_CACHE', 'SPEAKER_PORTAL', 'Clear Cache', 'speakerPortalClearCache')
      .addRequest('INTEGRATION_ADMIN_PAGE_CLEAR_CACHE_SUCCESS', 'SPEAKER_PORTAL', 'Speaker Portal Cache Cleared', 'speakerPortalClearCacheSuccess')
      .addRequest('INTEGRATION_ADMIN_PAGE_CLEAR_CACHE_ERROR', 'SPEAKER_PORTAL', 'An error occurred, please try again', 'speakerPortalClearCacheError')
      .sendRequest();
  }

  async clearCache() {
    try {
      this.loading = true;
      await this.speakerPortalDataSvc.clearSpeakerPortalCache();
      this.dispatchEvent(VeevaToastEvent.successMessage(this.messageMap.speakerPortalClearCacheSuccess));
    } catch (error) {
      const errorObj = { message: this.messageMap.speakerPortalClearCacheError };
      this.dispatchEvent(VeevaToastEvent.error(errorObj));
    } finally {
      this.loading = false;
    }
  }
}