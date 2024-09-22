export default class EventButtonService {
  constructor(dataSvc) {
    this.dataSvc = dataSvc;
  }

  async getEventQRCode(eventId) {
    return this.dataSvc.sendRequest('GET', `/api/v1/em/events/${eventId}/qrcodes/`, null, null, 'getQRCode');
  }

  async scheduleEngageMeeting(data) {
    return this.dataSvc.sendRequest('POST', '/api/v1/layout3/EM_Event_vod__c/meeting', null, data, 'scheduleEngageMeeting');
  }

  async startPackageCreation(data) {
    data.device = 'CRM_Engage_vod';
    return this.dataSvc.sendRequest('POST', '/api/v1/jobs/viewmedia', null, data, 'startPackageCreation');
  }
}