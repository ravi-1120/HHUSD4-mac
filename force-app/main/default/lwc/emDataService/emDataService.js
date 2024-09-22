import BaseDataService from 'c/baseDataService';

export default class EmDataService extends BaseDataService {
  async getPreferredAddress(accountId) {
    const path = `/api/v1/base/data/Account_vod__c/${accountId}/address`;
    return this.dataSvc.sendRequest('GET', path, null, null, 'getPreferredAddress');
  }

  async eventTemplateSave(data) {
    const path = '/api/v1/layout3/EM_Event_vod__c/event-template-save';
    return this.dataSvc.sendRequest('POST', path, null, data, 'eventTemplateSave');
  }
}