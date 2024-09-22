/* eslint-disable no-console */
// TODO: remove above eslint-disable when the new logging framework is avaiable.
import getInfo from '@salesforce/apex/VeevaUserInterfaceAPI.getInfo';
import getData from '@salesforce/apex/VeevaUserInterfaceAPI.getData';
import VeevaUtils from 'c/veevaUtils';
import VeevaLayoutService from 'c/veevaLayoutService';

const TYPE_TO_DATATYPE = {
  boolean: 'Boolean',
  currency: 'Currency',
  date: 'Date',
  datetime: 'DateTime',
  double: 'Double',
  email: 'Email',
  integer: 'Int',
  location: 'Location',
  multipicklist: 'MultiPicklist',
  percent: 'Percent',
  phone: 'Phone',
  picklist: 'Picklist',
  reference: 'Reference',
  string: 'String',
  textarea: 'TextArea',
  time: 'Time',
  url: 'Url',
};

const GET_QUERY_CHAR_LIMIT = 16000;

// https://developer.salesforce.com/docs/atlas.en-us.uiapi.meta/uiapi/ui_api_get_started.htm
export default class VeevaUserInterfaceAPI {
  _promiseMap = {};

  constructor(requests) {
    this.requests = requests || [];
  }

  async getPicklistValues(recordTypeId, sobject, field) {
    const url = `/ui-api/object-info/${sobject}/picklist-values/${recordTypeId}/${field}`;
    const response = await this.performRequest('getPicklistValues', url);
    if (response.error) {
      console.warn(`Could not retrieve picklist values for ${sobject}.${field} (RecordTypeId: ${recordTypeId})`, response.error);
      return {};
    }
    return response.data;
  }

  async getPicklistValuesMap(recordTypeId, sobject) {
    let responseData = {};

    const url = `/ui-api/object-info/${sobject}/picklist-values/${recordTypeId}`;
    const response = await this.performRequest('getPicklistValuesMap', url);
    if (response.error) {
      console.warn(`Could not retrieve picklist values for ${sobject} (RecordTypeId: ${recordTypeId})`, response.error);
    } else {
      responseData = response.data;
    }

    return responseData && responseData.picklistFieldValues;
  }

  async getBatchRecords(ids, fields, useCache = false) {
    const idsStr = ids.join(',');
    const url = `/ui-api/records/batch/${idsStr}?fields=${fields}`;
    const response = await this.performRequest('getBatchRecords', url, !useCache);
    if (response.error) {
      console.warn(`Could not retrieve batch records for [${idsStr}] for fields ${fields}`, response.error);
      return [];
    }
    const { results } = response.data;
    return results.map(x => x.result);
  }

  async getCreateDefaults(sobject, recordTypeId, optionalFields = null) {
    return this._getCreateDefaultInfo(false, sobject, recordTypeId, optionalFields);
  }

  async getCreateDefaultRecord(sobject, recordTypeId, optionalFields = null) {
    return this._getCreateDefaultInfo(true, sobject, recordTypeId, optionalFields);
  }

  async _getCreateDefaultInfo(recordOnly, sobject, recordTypeId, optionalFields = null) {
    const templatePath = recordOnly ? 'template/' : '';
    let baseUrl = `/ui-api/record-defaults/${templatePath}create/${sobject}?`;
    const urlSearchParams = new URLSearchParams();

    if (recordTypeId) {
      urlSearchParams.set('recordTypeId', recordTypeId);
    }

    const urlsToQuery = optionalFields ? this._splitAndUrlify(optionalFields, urlSearchParams, baseUrl) : [(baseUrl += urlSearchParams.toString())];
    const responses = await Promise.all(urlsToQuery.map(url => this.performRequest('getCreateDefaults', url)));

    for (const response of responses) {
      if (response.error) {
        console.warn(`Could not get create defaults for ${sobject} (RecordTypeId: ${recordTypeId})`, response.error);
        return {}; // return an empty object if there's an error in any response
      }
    }

    const result = responses[0] || {};
    result.data.record.fields = this._getMergedRecordFields(responses);
    return result.data;
  }

  /**
   * Converts fields into a list of URLs that do not exceed the GET query character limit.
   *
   * @param {string[]} fields - List of fields to be converted into URL query parameters.
   * @param {URLSearchParams} urlSearchParams - Existing search parameters.
   * @param {string} baseUrl - Base URL to which the parameters will be appended.
   * @returns {string[]} - An array of URLs.
   */
  _splitAndUrlify(fields, urlSearchParams, baseUrl) {
    const urls = [];

    urlSearchParams.set('optionalFields', fields.join(','));
    const fullUrl = baseUrl + urlSearchParams.toString();

    if (fullUrl.length <= GET_QUERY_CHAR_LIMIT) {
      urls.push(fullUrl);
    } else {
      const middle = Math.floor(fields.length / 2);
      urls.push(...this._splitAndUrlify(fields.slice(0, middle), urlSearchParams, baseUrl));
      urls.push(...this._splitAndUrlify(fields.slice(middle), urlSearchParams, baseUrl));
    }
    return urls;
  }

  /**
   * Merges fields from an array of responses.
   *
   * @param {Array} responses - List of responses with record fields.
   * @returns {Object} Merged fields from all responses.
   */
  _getMergedRecordFields(responses) {
    return responses.reduce((acc, response) => {
      Object.assign(acc, response.data?.record?.fields);
      return acc;
    }, {});
  }

  async getDescribeButtons(sobject, recordTypeId) {
    let buttons = [];
    const url = `/sobjects/${sobject}/describe/layouts/${recordTypeId || ''}`;
    const response = await this.performRequest('describeButtons', url);
    if (response.error) {
      console.warn(`Could not describe buttons for ${sobject} (RecordTypeId: ${recordTypeId})`, response.error);
      return [];
    }

    const layoutRes = response.data;
    if (layoutRes.buttonLayoutSection) {
      buttons = layoutRes.buttonLayoutSection.detailButtons;
    }
    return buttons;
  }

  async search(sobject, field, target, term, dependents, nextPageUrl) {
    let url = `/ui-api/lookups/${sobject}/${field}/${target}`;
    if (!nextPageUrl) {
      if (VeevaUtils.isValidSearchTerm(term)) {
        const param = encodeURIComponent(term.trim());
        url += `?searchType=Search&q=${param}`;
      } else {
        url += '?searchType=Recent';
      }
      if (dependents) {
        const str = Object.entries(dependents)
          .map(([key, value]) => `${key}=${encodeURIComponent(value)}`)
          .join(',');
        if (str) {
          url += `&dependentFieldBindings=${str}`;
        }
      }
      url += '&pageSize=50';
    } else {
      const [, nextPageParams] = nextPageUrl.split('?');
      url += `?${nextPageParams}`;
    }
    const response = await this.performRequest('search', url);
    if (response.error) {
      console.warn(`Could not search ${sobject} for ${field} with target of ${target}`, response.error);
      return null;
    }
    return response.data;
  }

  async searchLayout(sobject) {
    const response = await this.searchLayouts([sobject]);
    return response && response.length > 0 ? response[0] : null;
  }

  async searchLayouts(sobjects) {
    const url = `/search/layout?q=${sobjects}`;
    const response = await this.performRequest('searchLayout', url);
    if (response.error) {
      console.warn(`Could not search layouts for ${sobjects}`, response.error);
      return null;
    }
    return response.data;
  }

  async objectInfoDirectory() {
    const url = '/ui-api/object-info';
    const response = (await this.performRequest('objectInfoDirectory', url)) || {};
    if (response.error) {
      console.warn(`Could not get object info directory`, response.error);
      return {};
    }
    return response.data;
  }

  async objectInfo(sobject) {
    const url = `/ui-api/object-info/${sobject}`;
    const response = (await this.performRequest('objectInfo', url)) || {};
    if (response.error) {
      console.warn(`Could not get object info`, response.error);
      return [];
    }
    return response.data;
  }

  // returns a map of objectApiName to objectInfo
  async objectInfos(sobjects) {
    if (!sobjects || sobjects.length === 0) return {};

    const url = `/ui-api/object-info/batch/${sobjects.join(',')}`;
    const response = (await this.performRequest('objectInfos', url)) || {};
    if (response.error) {
      console.warn(`Could not get object infos`, response.error);
      return {};
    }
    const { results } = response.data;
    const objectInfosMap = {};

    results
      .filter(info => info.statusCode === 200)
      .map(info => info.result)
      .forEach(info => {
        objectInfosMap[info.apiName] = info;
      });
    return objectInfosMap;
  }

  async getRecord(id, optionalFields, useCache = false) {
    const fields = optionalFields.join(',');
    const url = `/ui-api/records/${id}?optionalFields=${fields}`;
    const response = await this.performRequest('objectInfo', url, !useCache);
    if (response.error) {
      console.warn(`Could not get records with id ${id} with fields ${optionalFields}`, response.error);
      return [];
    }
    return response.data;
  }

  async getRecordActions(recordId, useCacheForButton = true) {
    const buttonUrl = `/ui-api/actions/record/${recordId}?actionTypes=StandardButton,CustomButton`;
    const buttonsResponse = await this.performRequest('getRecordActions', buttonUrl, !useCacheForButton);
    if (buttonsResponse.error) {
      console.warn(`Could not retrieve buttons for recordId: ${recordId}`, buttonsResponse.error);
    }
    return buttonsResponse.success ? buttonsResponse.data : [];
  }

  async getPageLayout(apiName, action, recordTypeId, recordId) {
    const layoutUrl = `/ui-api/layout/${apiName}?mode=${action}&recordTypeId=${recordTypeId}`;
    const layoutPromise = this.performRequest('getRecordLayout', layoutUrl);
    const buttonUrl = `/ui-api/actions/record/${recordId}?actionTypes=StandardButton,CustomButton`;
    const buttonPromise = this.performRequest('getRecordActions', buttonUrl);

    const [layoutResponse, buttonsResponse] = await Promise.all([layoutPromise, buttonPromise]);
    if (layoutResponse.error) {
      console.warn(`Could not retrieve page layout for ${apiName} (RecordTypeId: ${recordTypeId}) in mode ${action}`, layoutResponse.error);
    }
    if (buttonsResponse.error) {
      console.warn(`Could not retrieve buttons for recordId: ${recordId}`, buttonsResponse.error);
    }

    const layout = VeevaLayoutService.toVeevaLayout(layoutResponse.data, action);
    const buttons = buttonsResponse.success ? buttonsResponse.data : [];
    if (buttons && buttons.actions && buttons.actions[recordId]) {
      layout.buttons = VeevaLayoutService.toButtons(buttons.actions[recordId].actions);
    } else {
      layout.buttons = [];
    }
    return layout;
  }

  async getPageLayoutNoButtons(apiName, action, recordTypeId) {
    const layoutMode = action === 'New' ? 'Create' : action; // layout api doesn't support New, only Create
    const layoutUrl = `/ui-api/layout/${apiName}?mode=${layoutMode}&recordTypeId=${recordTypeId}`;
    const layoutResponse = await this.performRequest('getRecordLayout', layoutUrl);

    if (layoutResponse.error) {
      console.warn(`Could not retrieve page layout for ${apiName} (RecordTypeId: ${recordTypeId}) in mode ${action}`, layoutResponse.error);
    }

    return VeevaLayoutService.toVeevaLayout(layoutResponse.data, action);
  }

  async getCompactLayout(apiName, action, recordTypeId) {
    const layoutUrl = `/ui-api/layout/${apiName}?mode=${action}&layoutType=Compact&recordTypeId=${recordTypeId}`;
    const layout = await this.performRequest('getRecordCompactLayout', layoutUrl);
    return layout;
  }

  async getRelatedLists(apiName, recordTypeId) {
    const relatedListUrl = `/ui-api/related-list-info/${apiName}?recordTypeId=${recordTypeId}`;
    const response = await this.performRequest('getRelatedLists', relatedListUrl);
    if (response.error) {
      console.warn(`Could not get related lists for ${apiName} (RecordTypeId: ${recordTypeId})`, response.error);
      return null;
    }
    return response.data;
  }

  async getListViewSummaryCollection(objectApiName) {
    const listViewSummaryCollectionUrl = `/ui-api/list-ui/${objectApiName}?pageSize=200`;
    const response = await this.performRequest('getListViewSummaryCollection', listViewSummaryCollectionUrl);
    if (!response.success && response.error) {
      return [];
    }
    return response.data.lists;
  }

  async getListViewMetadata(viewId) {
    const listViewMetaUrl = `/ui-api/list-info/${viewId}`;
    const response = await this.performRequest('getListViewMetadata', listViewMetaUrl);
    if (!response.success && response.error) {
      return {};
    }
    return response.data;
  }

  async getListViewRecords(viewId, params) {
    const listViewRecordsUrl = `/ui-api/list-records/${viewId}`;
    return this.getViewRecords('getListViewRecords', listViewRecordsUrl, params);
  }

  async getRecentlyViewedListMetadata(objectApiName) {
    const recentlyViewedMetaUrl = `/ui-api/mru-list-info/${objectApiName}`;
    const response = await this.performRequest('getRecentlyViewedListMetadata', recentlyViewedMetaUrl);
    if (!response.success && response.error) {
      return {};
    }
    return response.data;
  }

  async getRecentlyViewedListRecords(objectApiName, params) {
    const recentlyViewedRecordsUrl = `/ui-api/mru-list-records/${objectApiName}`;
    return this.getViewRecords('getRecentlyViewedListRecords', recentlyViewedRecordsUrl, params);
  }

  async getViewRecords(methodName, url, { pageSize, pageToken, sortBy, sortAscending }) {
    const params = new URLSearchParams();
    if (pageSize) {
      params.append('pageSize', pageSize);
    }
    if (pageToken) {
      params.append('pageToken', pageToken);
    }
    if (sortBy) {
      let sortParam = sortBy;
      if (sortAscending === false) {
        sortParam = `-${sortParam}`;
      }
      params.append('sortBy', sortParam);
    }
    const fullUrl = `${url}?${params.toString()}`;
    const response = await this.performRequest(methodName, fullUrl, true);
    if (!response.success && response.error) {
      return [];
    }
    return response.data;
  }

  async getObjectInfoFromRestApi(objectName) {
    const objectNameEncoded = encodeURIComponent(objectName);
    const url = `/sobjects/${objectNameEncoded}/describe`;
    const response = await this.performRequest('getObjectInfoFromRestApi', url);
    if (!response.success) {
      return {};
    }
    const fieldMap = {};
    const nameFields = [];
    if (response.data.fields) {
      response.data.fields.forEach(field => {
        const dataType = TYPE_TO_DATATYPE[field.type.toLowerCase()] ?? 'String';
        fieldMap[field.name] = {
          apiName: field.name,
          dataType,
          ...field,
        };
        if (field.nameField) {
          nameFields.push(field.name);
        }
      });
    }
    return {
      ...response.data,
      apiName: objectName,
      fields: fieldMap,
      nameFields,
    };
  }

  /**
   * @deprecated This method does not provide error information, please use {@link VeevaUserInterfaceAPI.performRequest}
   */
  async request(name, path, data) {
    console.warn(
      `Using the deprecated ${this.constructor.name}.request method, please use the newer performRequest ${this.constructor.name}.method.`
    );
    const response = await this.performRequest(name, path, data);
    if (!response.success && response.error) {
      console.warn('Request Error Found');
      console.warn({ name, path, error: response.error });
      return null;
    }
    return response.data;
  }

  async performRequest(name, path, data) {
    const request = { path };
    this.requests.push(name);
    let result;
    try {
      result = data ? await getData(request) : await this._getInfoWithCacheCheck(request);
    } catch (err) {
      result = {};
    }
    this.requests.splice(this.requests.indexOf(name), 1);
    if (result.data) {
      return {
        success: true,
        data: JSON.parse(result.data),
      };
    }
    if (result.errorStatus) {
      return {
        success: false,
        error: this.errorFromResult(result),
      };
    }
    return {
      success: false,
      error: {
        errorStatus: 'Error in response or response from VeevaUserInterfaceAPI did not match expected format',
      },
    };
  }

  // helper function to allow "@AuraEnabled" client-side cache to populate before subsequent getInfo() calls are made
  async _getInfoWithCacheCheck(request) {
    let infoPromise = this._promiseMap[request.path];
    if (!infoPromise) {
      infoPromise = getInfo(request);
      this._promiseMap[request.path] = infoPromise;
    }
    const metadataResponse = await infoPromise;
    // "@AuraEnabled" client-side cache is now populated; map entry is no longer needed
    delete this._promiseMap[request.path];
    return metadataResponse;
  }

  errorFromResult(result) {
    let message;
    try {
      message = JSON.parse(result.errorData);
    } catch {
      message = result.errorData;
    }
    return {
      errorStatus: result.errorStatus,
      message,
    };
  }
}