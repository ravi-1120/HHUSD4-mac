import VeevaMCDataService from "c/veevaMCDataService";

export default class AdminDataService extends VeevaMCDataService {
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

    async deleteCredential(systemType, systemId, id) {
        const request = await this.initMcRequest();
        request.url += `/api/v1/credentials/${systemType}?systemIds=${systemId}&ids=${id}`;
        request.method = "DELETE";
        try {
            return await this.request(request, 'deleteCredential');
        } catch(err) {
            return {};
        }
    }

    async retrieveOrgId() {
        const vodInfo = await this.sessionSvc.getVodInfo();
        return vodInfo.orgId;
    }

    async retrieveVaultFieldsAndStates(integrationType, vaultUrl, isLifeCycleState) {
        const request = await this.initMcRequest();
        if(isLifeCycleState) {
            request.url += `/api/v1/vaultservice/documents/lifecycles?integrationType=${integrationType}&vaultUrl=${vaultUrl}`;
        } else {
            request.url += `/api/v1/vaultservice/documents/fields?integrationType=${integrationType}&vaultUrl=${vaultUrl}`;
        }
        request.method = "GET";
        try {
            return await this.request(request, 'retrieveVaultFieldsAndStates');
        } catch(err) {
            return {};
        }
    }

    async runMcTask(taskName, taskId, taskInstruction) {
        const contentTypeHeader = {'Content-Type': 'text/plain' };
        const request = await this.initMcRequest();
        request.url += `/api/v1/mcservice/actions/run/task/${taskName}/${taskId}`
        request.method = "POST";
        request.headers = {...request.headers, ...contentTypeHeader};
        if(taskInstruction) {
            request.body = taskInstruction;
        }
        try {
            return await this.request(request, 'runMcTask');
        } catch(err) {
            return {};
        }
    }

    async getJobStatus(recordType, count, unit, jobId) {
        const request = await this.initMcRequest();
        if(jobId) {
            request.url += `/api/v1/stats/status/refresh?recordType=${recordType}&count=${count}&unit=${unit}&jobId=${jobId}`
        } else {
            request.url += `/api/v1/stats/status/refresh?recordType=${recordType}&count=${count}&unit=${unit}`
        }
        request.method = "GET";
        try {
            return await this.request(request, 'getJobStatus');
        } catch(err) {
            return {};
        }
    }

    saveBlob(blob, fileName) {
        const a = document.createElement('a');
        a.href = window.URL.createObjectURL(blob);
        a.download = fileName;
        a.dispatchEvent(new MouseEvent('click'));
    }

}