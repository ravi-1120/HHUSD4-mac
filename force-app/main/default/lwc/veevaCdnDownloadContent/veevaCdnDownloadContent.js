import { getService } from 'c/veevaServiceFactory';
import { LightningElement, api } from 'lwc';
import VeevaMCDataService from "c/veevaMCDataService";
import VeevaFileDownload from "c/veevaFileDownload";

export default class VeevaCdnDownloadContent extends LightningElement {
    @api recordId;
    sessionSvc;
    uiApi;

    constructor() {
        super();
        this.sessionSvc = getService('sessionSvc');
        this.uiApi = getService('userInterfaceSvc');
        this.dataSvc = new VeevaMCDataService(this.sessionSvc);
    }

    @api async invoke() {
        const record = await this.uiApi.getRecord(this.recordId, ['Veeva_Distribution_vod__c.CDN_Path_vod__c', 'Veeva_Distribution_vod__c.File_Name_vod__c', 'Veeva_Distribution_vod__c.File_Extension_vod__c'], true);
        if(record.fields.CDN_Path_vod__c.value){
            const file = await this.dataSvc.downloadCDNFile(record);
            if(file && file.size > 0){
                let fileName = 'file';
                if (record.fields.File_Name_vod__c.value) {
                    fileName = record.fields.File_Name_vod__c.value;
                }
                if (record.fields.File_Extension_vod__c.value) {
                    fileName = `${fileName  }.${  record.fields.File_Extension_vod__c.value}`;
                }
                VeevaFileDownload.download(fileName, file);
            }
        }
    }    
}