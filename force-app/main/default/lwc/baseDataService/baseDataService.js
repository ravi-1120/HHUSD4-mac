export default class BaseDataService {
  constructor(dataSvc) {
    this.dataSvc = dataSvc;
  }

  async query(object, queryParams) {
    const path = `/api/v1/base/data/${object}/format`;
    return this.dataSvc.sendRequest('GET', path, queryParams, null, 'baseDataQuery');
  }

  async createRecord(changes, objectApiName) {
    const path = `/api/v1/base/data/${objectApiName}`;
    return this.dataSvc.sendRequest('POST', path, null, changes, 'baseDataCreate');
  }

  async updateRecords(changes, objectApiName) {
    const body = this.buildBulkUpdatePayload(changes, objectApiName);
    const objectTypePlural = objectApiName.concat('s');
    const path = `/api/v1/base/data/${objectTypePlural}`;
    return this.dataSvc.sendRequest('PUT', path, null, body, 'baseDataUpdate', {'Content-Type': 'application/json'});
  }

  // eslint-disable-next-line class-methods-use-this
  buildBulkUpdatePayload(changes, objectApiName) {
    return {
      [objectApiName]: changes
    };
  }
}