import { LightningElement, track } from 'lwc';
import { getService } from 'c/veevaServiceFactory';
import SpeakerPortalDataService from 'c/speakerPortalDataService'

export default class SpeakerPortalSubDomain extends LightningElement {
  @track orgInfo = {};
  @track messageMap = {};

  speakerPortalDataSvc;
  showDomainModal = false;

  async connectedCallback() {
    this.messageMap = await this.loadVeevaMessages();
    this.speakerPortalDataSvc = new SpeakerPortalDataService(getService('sessionSvc'));
    this.getOrgInfo();
  }

  async loadVeevaMessages() {
    const messageSvc = getService('messageSvc');
    return messageSvc
      .createMessageRequest()
      .addRequest( 'Edit', 'Common', 'Edit', 'editButtonLabel')
      .addRequest( 'EM_QR_LAST_MODIFIED', 'EVENT_MANAGEMENT', 'Last Modified', 'lastModFieldLabel')
      .addRequest( 'SUB_DOMAIN_TITLE', 'SPEAKER_PORTAL', 'Custom Subdomain', 'domainCardTitle')
      .addRequest( 'SUB_DOMAIN_FIELD', 'SPEAKER_PORTAL', 'Subdomain', 'subDomainFieldLabel')
      .sendRequest();
  }

  displayDomainModal() {
    this.showDomainModal = true;
  }

  closeDomainModal() {
    this.showDomainModal = false;
  }

  async saveDomainModal(event) {
    this.orgInfo = event.detail;
    this.showDomainModal = false;
  }

  async getOrgInfo() {
    try {
      const response = await this.speakerPortalDataSvc.getOrgInfo();
      this.orgInfo = response.data;
    } catch (error) {
      if(error.status === 404) {
        const myDomain = window.location.hostname.split('.')[0];
        this.orgInfo = {
          domain: myDomain,
        }
      }
    }
  }

  get disableEdit() {
    return !this.orgInfo?.domain;
  }
}