import VeevaDataService from 'c/veevaDataService';
import getSpeakerPortalServer from '@salesforce/apex/VeevaAdminController.getSpeakerPortalServer';

export default class SpeakerPortalDataService extends VeevaDataService {
  #speakerPortalServer;
  #orgId;

  constructor(sessionSvc) {
    super(sessionSvc, []);
    this.sessionSvc = sessionSvc;
  }

  async clearSpeakerPortalCache() {
    const request = await this.initVodRequest();
    request.url = await this.getSpeakerPortalServer();
    request.url += '/api/v1/speaker-portal/sf/cache';
    request.method = 'DELETE';
    return this.request(request, 'clearSpeakerPortalCache');
  }

  async getOrgInfo() {
    const orgId = await this.getOrgId();
    const request = await this.initVodRequest();
    request.url = await this.getSpeakerPortalServer();
    request.url += `/api/v1/speaker-portal/sf/orgs/${orgId}`;
    request.method = 'GET';
    return this.request(request, 'getOrgInfo', this.rejectionHandlerWithStatus);
  }

  async updateOrgInfo(body) {
    const orgId = await this.getOrgId();
    const request = await this.initVodRequest();
    request.url = await this.getSpeakerPortalServer();
    request.url += `/api/v1/speaker-portal/sf/orgs/${orgId}`;
    request.method = 'PUT';
    request.body = JSON.stringify(body);
    return this.request(request, 'getOrgInfo');
  }

  async getSpeakerPortalServer() {
    if (!this.#speakerPortalServer) {
      this.#speakerPortalServer = await getSpeakerPortalServer();
    }
    return this.#speakerPortalServer;
  }

  async getOrgId() {
    if(!this.#orgId) {
      const vodInfo = await this.sessionSvc.getVodInfo();
      this.#orgId = vodInfo.orgId;
    }
    return this.#orgId;
  }

  rejectionHandlerWithStatus(callingObject, xhr) {
    return {
      status: xhr.status,
      response: callingObject.safeJsonParse(xhr.response)
    }
  }
}