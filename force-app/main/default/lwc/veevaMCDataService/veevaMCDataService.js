import VeevaDataService from "c/veevaDataService";

export default class VeevaMCDataService extends VeevaDataService{

      async downloadCDNFile(record){
        const mcRequest = await this.initMcRequest();
        const path = `/api/v1/cdn/veeva-distributions/files?cdnPath=${encodeURIComponent((record.fields.CDN_Path_vod__c).value)}`;
        mcRequest.url += path;
        return this.getFile(mcRequest, null, this.parseFileData);
      }

    parseFileData(e, fileType) {
        const blob = new Blob([e.currentTarget.response], {type: fileType});
        return blob;
    }

    async getMcJobCsvFile(jobId, type) {
        const request = await this.initMcRequest();
        request.url += `/api/v1/stats/refresh/records/${jobId}/log?integrationType=${type}`
        return this.getFile(request, null, this.parseFileData);
    }

    async getFile(request, fileType, parseResultFunc) {
        request.headers["Content-Type"] = "text/plain";

        return new Promise((resolve) => {
            const xhr = new XMLHttpRequest();
            xhr.open("GET", request.url, true);
            xhr.setRequestHeader("sfEndpoint", request.headers.sfEndpoint);
            xhr.setRequestHeader("sfSession", request.headers.sfSession);
            xhr.responseType = "blob";
            xhr.onload = (e) => {
                const result = parseResultFunc(e, fileType || "application/octet-stream");
                resolve(result);
            }
            xhr.send();
        });
    }
}