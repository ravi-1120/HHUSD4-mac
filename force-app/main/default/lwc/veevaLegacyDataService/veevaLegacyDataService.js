import VeevaDataService from 'c/veevaDataService';

export default class VeevaLegacyDataService extends VeevaDataService {
    // eslint-disable-next-line default-param-last
    async sendRequest(method, path, params, body=null, name) {
        const paramString = this.toQueryParams(params);
        const vodRequest = await this.initVodRequest(method);

        vodRequest.method = method;
        if(path) {
            vodRequest.url += path;
        }
        if(method === 'GET') {
            vodRequest.url += `?${await this.getSFSessionParameters()}`;
        }
        if (typeof paramString === 'string') {
            vodRequest.url += method !== 'GET' ? '?' : '&';
            vodRequest.url += `${paramString}`;
        }

        const bodyString = this.toBodyParams(body);
        if(typeof bodyString === 'string') {
            vodRequest.body += `&${bodyString}`;
        }

        return this.request(vodRequest, name);
    }

    async getSFSessionParameters() {
        const vodInfo = await this.sessionService.getVodInfo();
        return `VER=${vodInfo.veevaVersion}&ses=${vodInfo.sfSession}&url=${vodInfo.sfEndpoint}`;
    }

    toBodyParams(params) {
        return Object.keys(params).map(key => `${key}=${params[key]}`).join('&');
    }

    async initVodRequest() {
        const vodRequest = {};
        const vodInfo = await this.sessionService.getVodInfo();
        vodRequest.url = vodInfo.veevaServer;
        vodRequest.headers = {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'};
        vodRequest.body = `${vodInfo.veevaVersion}?VER=${vodInfo.veevaVersion}&ses=${vodInfo.sfSession}&url=${vodInfo.sfEndpoint}`;
        return vodRequest;
    }
}