/* eslint-disable dot-notation */
/* eslint-disable no-param-reassign */
import VeevaLayoutService from 'c/veevaLayoutService';

export default class EmPageLayoutEngineService {
  constructor(dataSvc) {
    this.dataSvc = dataSvc;
  }

  // EM Specific request to CRM for page layout, other areas should be using lightning ui-api
  async getPageLayout(object, action, recordId, recordTypeId, eventId, params = {}) {
    let path = '/api/v1/events-service/events';
    if (object === 'EM_Event_vod__c') {
      if (action === 'New') {
        path += '/new/layouts';
      } else {
        path += `/${eventId}/layouts`;
      }
    } else {
      path += `/${eventId}/${object}/layouts`;
      params['recordId'] = recordId;
    }

    params['mode'] = action;
    params['recordTypeId'] = recordTypeId;

    Object.keys(params).forEach(key => {
      params[key] = params[key] || '';
    });

    const response = await this.dataSvc.sendRequest('GET', path, params, null, 'getEmPageLayout', { 'response-type': 'json' });
    const layout = response.data[0];
    layout.buttons = VeevaLayoutService.describeToButtons(layout.buttons);
    return VeevaLayoutService.toVeevaLayout(layout, action);
  }

  async getEventLayoutButtons(eventId, object, recordTypeId, eventStatus, countryAlpha2Code, eventConfigId) {
    const path = `/api/v1/events-service/events/${eventId}/${object}/layouts/buttons`;
    const params = {
      recordTypeId,
      eventStatus,
      countryAlpha2Code,
      eventConfigId,
    };
    return this.dataSvc.sendRequest('GET', path, params, null, 'getEventLayoutButtons', { 'response-type': 'json' });
  }

  async getBatchEventLayoutButtons(eventId, object, recordTypeIds, eventStatus, countryAlpha2Code, eventConfigId) {
    const path = `/api/v1/events-service/events/${eventId}/${object}/batch/layouts/buttons`;
    const params = {
      recordTypeIds,
      eventStatus,
      countryAlpha2Code,
      eventConfigId,
    };
    return this.dataSvc.sendRequest('GET', path, params, null, 'getEventLayoutButtons', { 'response-type': 'json' });
  }
}