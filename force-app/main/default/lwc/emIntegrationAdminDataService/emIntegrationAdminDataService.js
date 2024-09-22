import VeevaDataService from "c/veevaDataService";

export default class EmIntegrationAdminDataService extends VeevaDataService {
    constructor(sessionSvc, messageSvc) {
        super(sessionSvc, []);
        this.sessionSvc = sessionSvc;
        this.messageSvc = messageSvc;
    }

    async readVerifyCredential(action, systemType, systemId) {
        const request = await this.initMcRequest();
        if(systemId) {
            request.url += `/api/v1/credentials/${systemType}?action=${action}&systemId=${systemId}`;
        } else {
            request.url += `/api/v1/credentials/${systemType}?action=${action}`;
        }
        request.method = "GET";
        try {
            return await this.request(request, 'readVerifyCredential');
        } catch(err) {
            return {};
        }
    }

    async upsertCredential(systemType, body) {
        const contentTypeHeader = {'Content-Type': 'application/x-www-form-urlencoded' };
        const request = await this.initMcRequest();
        request.url += `/api/v1/credentials/${systemType}`
        request.method = "POST";
        request.headers = {...request.headers, ...contentTypeHeader};
        request.body = body;
        try {
            return await this.request(request, 'upsertCredential');
        } catch(err) {
            return err;
        }
    }

    async retrieveOrgId() {
        const vodInfo = await this.sessionSvc.getVodInfo();
        return vodInfo.orgId;
    }
}