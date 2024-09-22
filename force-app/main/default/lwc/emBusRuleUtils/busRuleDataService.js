import { getService, SERVICES } from 'c/veevaServiceFactory';
import BaseDataService from 'c/baseDataService';
import EVENT_OVERRIDE from '@salesforce/schema/EM_Event_Override_vod__c';

export default class BusRuleDataService {
  #dataSvc = getService(SERVICES.DATA);
  #baseDataSvc = new BaseDataService(this.#dataSvc);

  async removeAttendees(attendeeIds) {
    const path = '/api/v1/layout3/data/EM_Attendee_vod__c/Bulk';
    return this._removeParticipants(path, attendeeIds);
  }

  async removeEventSpeakers(eventSpeakerIds) {
    const path = '/api/v1/layout3/data/EM_Event_Speaker_vod__c/bulk';
    return this._removeParticipants(path, eventSpeakerIds);
  }

  async _removeParticipants(path, participantIds) {
    const body = {
      Ids: participantIds,
    };
    const headers = {
      'Content-Type': 'application/json',
    };
    return this.#dataSvc.sendRequest('DELETE', path, null, body, 'removeParticipants', headers);
  }

  async saveEventOverrides(eventOverrides) {
    const response = await this.#baseDataSvc.updateRecords(eventOverrides, EVENT_OVERRIDE.objectApiName);

    if (response.failedCount) {
      const errorMessage = this._getErrorMessageFromResponse(response);
      throw new Error(errorMessage);
    }

    return response;
  }

  _getErrorMessageFromResponse(response) {
    let errorMessage;
    const failedRecord = response.failedRecords?.[0];
    const errors = failedRecord?.insertErrors || failedRecord?.updateErrors || [];
    if (errors.length) {
      errorMessage = errors.map(error => error.message).join('; ');
    }
    return errorMessage;
  }

  async reloadPerEventViolations(eventId, buttonName) {
    const path = `/api/v1/em.action/${eventId}/${buttonName}/business-rules`;
    const body = {
      platform: 'Online',
      ruleRecordTypes: ['EM_Per_Event_Attendance_Limit_Rule_vod', 'EM_Per_Event_Speaker_Limit_Rule_vod', 'EM_Per_Event_Speaker_Ratio_Rule_vod'],
    };
    const response = await this.#dataSvc.sendRequest('POST', path, null, body, 'reloadPerEventViolations');
    if (response.status !== 0) {
      throw response;
    }
    return response.data;
  }
}