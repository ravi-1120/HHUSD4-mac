import VeevaDataService from "c/veevaDataService";


export default class ReassignmentDataService extends VeevaDataService {    

    constructor(sessionSvc, messageSvc, msgCategories, awDomainUrl) {
        super(sessionSvc, []);
        this.sessionSvc = sessionSvc;
        this.messageSvc = messageSvc;
        this.awDomainUrl = awDomainUrl;
        this.messageSvc.loadVeevaMessageCategories(msgCategories);
    }

    async initReassignmentRequest() {
        const awRequest = {};
        const vodInfo = await this.sessionService.getVodInfo();
        this.orgId = vodInfo.orgId;
        awRequest.url = `${this.awDomainUrl}/qyaw-service/external/v1/qyaw/reassignment`;
        awRequest.headers = { sfSession: vodInfo.sfSession, sfEndpoint: vodInfo.sfEndpoint, 'Content-Type': 'application/json' };
        return awRequest;
    }

    async getTableData(path) {
        const request = await this.initReassignmentRequest();
        request.url += `${path}&orgId=${this.orgId}`;
        request.method = "GET";
        try {
            const response = await this.request(request);
            return response;
        } catch(err) {
            return null;
        }
    }

    static parseFileData(e, fileType) {
        const blob = new Blob([e.currentTarget.response], {type: fileType});
        return blob;
    }

    static parseFileDataWithName(e, fileType) {
        const contentDisposition = e.currentTarget.getResponseHeader('Content-disposition');
        if (contentDisposition) {
            const name = decodeURI(contentDisposition.split(`filename*=UTF-8''`)[1]);
            const blob = new Blob([e.currentTarget.response], {type: fileType});
            return [blob, name];
        }
        return null;
    }

    async getFileDataWithName(path, fileType) {
        return this.getFile(path, fileType, ReassignmentDataService.parseFileDataWithName);
    }

    async getFileData(path) {
        return this.getFile(path, null, ReassignmentDataService.parseFileData);
    }

    async getFile(path, fileType, parseResultFunc) {
        const request = await this.initReassignmentRequest();
        request.headers["Content-Type"] = "text/plain";
        request.url += `${path}?orgId=${this.orgId}`;

        return new Promise((resolve) => {
            const xhr = new XMLHttpRequest();
            xhr.open("GET", request.url, true);
            xhr.setRequestHeader("sfEndpoint", request.headers.sfEndpoint);
            xhr.setRequestHeader("sfSession", request.headers.sfSession);
            xhr.responseType = "blob";
            xhr.onload = (e) => {
                const result = parseResultFunc(e, fileType || "text/plain");
                resolve(result);
            }
            xhr.send();
        });
    }

    static saveBlob(blob, fileName) {
        const a = document.createElement('a');
        a.href = window.URL.createObjectURL(blob);
        a.download = fileName;
        a.dispatchEvent(new MouseEvent('click'));
    }

    async checkAllowToUpload () {
        const path = `/uploading-allowance?orgId=${this.orgId}`;
        return this.getResponsePayload(path);
    }

    async getResponsePayload(path, method) {
        const request = await this.initReassignmentRequest();
        request.url += path;
        request.method = method || "GET";
        try {
            const response = await this.request(request);
            return response.payload;
        } catch(err) {
            return null;
        }
    }

    async doReassignment (file) {
        const request = await this.initReassignmentRequest();
        request.url += `?orgId=${this.orgId}`;
        request.headers['Content-Type'] = 'application/json; charset=UTF-8';
        request.body = file;
        request.method = "POST";
        try {
            const response = await this.request(request);
            return response;
        } catch(err) {
            return null;
        }
    } 

    async checkAllowToCalculate () {
        const path = `/comparison/calculation-allowance?orgId=${this.orgId}`;
        return this.getResponsePayload(path);;
    }

    async doCalculationActon(action) {
        const path = `/comparison/calculation?action=${action}&orgId=${this.orgId}`;
        return this.getResponsePayload(path, 'POST');
    }

    async getCalculationStatus(processId) {
        const path = `/comparison/${processId}/status?orgId=${this.orgId}`;
        return this.getResponsePayload(path);
    }
}