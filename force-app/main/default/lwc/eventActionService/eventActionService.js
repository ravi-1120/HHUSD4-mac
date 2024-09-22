export default class EventActionService {
  constructor(dataSvc) {
    this.dataSvc = dataSvc;
  }

  async statusChange(eventId, actionId, data, checkBusinessRules = false) {
    const path = `/api/v1/em.action/${eventId}/${actionId}`;
    const params = {
      platform: 'Online',
      datetimeFormat: data.startDatetime && data.endDatetime ? 'UTC' : '',
      approverId: data.approverId || '',
      buttonName: data.buttonName || '',
      startDatetime: data.startDatetime || '',
      endDatetime: data.endDatetime || '',
      timeZone: data.timeZone || '',
      checkExpenseRules: checkBusinessRules,
      checkSpeakerRules: checkBusinessRules,
    };

    const postData = {
      comment: data.comment || '',
    };
    return this.dataSvc.sendRequest('POST', path, params, postData, 'statusChange');
  }

  async getEventAction(eventId, buttonName) {
    const path = `/api/v1/em.action/${eventId}/${buttonName}`;
    const params = {
      platform: 'Online',
    };
    return this.dataSvc.sendRequest('GET', path, params, null, 'getEventAction');
  }

  async rescheduleValidation(eventId, currentStartDatetime) {
    const path = `/api/v1/em.action/reschedule/${eventId}`;
    const params = {
      startDatetime: currentStartDatetime,
      datetimeFormat: 'UTC',
    };
    return this.dataSvc.sendRequest('GET', path, params, null, 'rescheduleValidation');
  }
}