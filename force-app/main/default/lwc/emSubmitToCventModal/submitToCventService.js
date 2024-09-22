import { getService, SERVICES } from 'c/veevaServiceFactory';

export default class SubmitToCventService {
  constructor() {
    this.dataSvc = getService(SERVICES.DATA);
  }

  async createMeetingRequest(eventId) {
    return this.dataSvc.sendRequest('POST', '/api/v1/cvent/meeting-request-forms', { eventId }, null, 'submitToCvent');
  }
}