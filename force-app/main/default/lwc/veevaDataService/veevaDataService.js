export default class VeevaDataService {

    constructor(sessionService, requests) {
        this.sessionService = sessionService;
        this.requests = requests || [];
    }

    toQueryParams(params) {
        if (params instanceof Object) {
            return Object.keys(params).map(key => `${encodeURIComponent(key)  }=${  encodeURIComponent(params[key])}`).join('&');
        }
        return params;
    }
    // eslint-disable-next-line default-param-last
    async sendRequest(method, path, params, body = null, name, header = {}) {
        const paramString = this.toQueryParams(params);
        let url = path;
        if (typeof paramString === 'string') {
            url += `?${ paramString}`;
        }

        const vodRequest = await this.initVodRequest();
        vodRequest.headers = {...vodRequest.headers, ...header};
        vodRequest.method = method;
        vodRequest.url += url;
        if (body) {
            vodRequest.body = JSON.stringify(body);
        }
        return this.request(vodRequest, name);
      }

    async sendMultiformRequest(method, path, params, name, body=null, header={}) {
        const paramString = this.toQueryParams(params);
        let url = path;
        if (typeof paramString === 'string') {
            url += `?${ paramString}`;
        }

        const vodRequest = await this.initVodRequest();
        delete vodRequest.headers['Content-Type'];
        vodRequest.headers = {...vodRequest.headers, ...header};
        vodRequest.method = method;
        vodRequest.url += url;
        vodRequest.body = body;
        return this.request(vodRequest, name);
    }

    request(obj, name, rejectionHandler=this.defaultRejectionHandler) {
        return new Promise((resolve, reject) => {
            const xhr = new XMLHttpRequest();
            xhr.open(obj.method || "GET", obj.url);
            if (obj.headers) {
                Object.keys(obj.headers).forEach(key => {
                    xhr.setRequestHeader(key, obj.headers[key]);
                });
            }
            xhr.onload = () => {
                this.requests.splice(this.requests.indexOf(name), 1);
                if (xhr.status >= 200 && xhr.status < 300) {
                    resolve(this.safeJsonParse(xhr.response));
                } else {
                    reject(rejectionHandler(this, xhr));
                }
            };
            xhr.onerror = () => { 
                this.requests.splice(this.requests.indexOf(name), 1);
                let response = this.safeJsonParse(xhr.response);
                if (!response) {
                    response = {
                        error: true
                    };
                }
                reject(response); 
            };
            this.requests.push(name);
            xhr.send(obj.body);
        });
    }

    defaultRejectionHandler(callingObject, xhr) {
        const response = callingObject.safeJsonParse(xhr.response);
        if (typeof response === 'object') {
            response.httpStatusCode = xhr.status;
        }
        return response;
    }

    async logClientPageTiming(msg){
        if (msg){
            const vodRequest = await this.initVodRequest();
            vodRequest.url += '/api/v1/clientPageTiming';
            vodRequest.method = 'POST';
            vodRequest.body = JSON.stringify(msg);
            await this.request(vodRequest, 'logClientPageTiming');
        }
    }

    async save(changes) {
        if (changes) {
            const url = changes.type || changes.url;
            const data = changes.data || changes;
            if (url) {
                const vodRequest = await this.initVodRequest();
                vodRequest.url += `/api/v1/layout3/data/${  url  }?skipFieldErrorDuplication=true&data-format=raw`;
                vodRequest.method = 'POST';
                vodRequest.body = JSON.stringify(data);
                return this.request(vodRequest, 'save');
            }
        }
        return Promise.resolve({ data: {} }); // empty data
    }

    /**
     * Supports Object records requiring DELETE request
     * Unlike POST save request with a deleted flag, this method deletes a record by Object Type and an ID
     */
    async delete(type, id) {
        if (!type || !id) {
            return Promise.resolve({ data: {} });
        }
        const vodRequest = await this.initVodRequest();
        vodRequest.url += `/api/v1/layout3/data/${type}/${id}`;
        vodRequest.method = 'DELETE';
        return this.request(vodRequest, 'delete');
    }
    
    async lookupSearch(sObject, params) {
        const vodRequest = await this.initVodRequest();
        vodRequest.url += `/api/v1/layout3/lookup/${  sObject}`;
        const urlSearchParamsBuilder = new URLSearchParams();
        for (const [key, value] of Object.entries(params)) {
            // filter out null/undefined values but keep empty strings
            if (value != null) {
                urlSearchParamsBuilder.append(key, value);
            }
        }
        vodRequest.url += `?${  urlSearchParamsBuilder.toString()}`;
        vodRequest.method = 'GET';
        return this.request(vodRequest, 'lookupSearch');
    }

    async initVodRequest() {
        const vodRequest = {};
        const vodInfo = await this.sessionService.getVodInfo();
        vodRequest.url = vodInfo.veevaServer;
        vodRequest.headers = { sfSession: vodInfo.sfSession, sfEndpoint: vodInfo.sfEndpoint, 'Content-Type': 'application/json' };
        return vodRequest;
    }

    async initMcRequest() {
        const mcRequest = {};
        const mcInfo = await this.sessionService.getVodInfo();
        mcRequest.url = `${mcInfo.mcServer  }/${  mcInfo.mcVersion}`;
        mcRequest.headers = { sfSession: mcInfo.sfSession, sfEndpoint: mcInfo.sfEndpoint };
        return mcRequest;
    }

    safeJsonParse(response) {
        try {
            return JSON.parse(response);
        } catch (err) {
            return response;
        }
    }

}