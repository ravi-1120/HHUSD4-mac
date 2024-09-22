import { LightningElement, api } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { getService } from 'c/veevaServiceFactory';

export default class aeCampaignDownloadErrorLogQuickAction extends NavigationMixin(LightningElement) {
    @api recordId;
    sessionSvc;
    uiApi;
    constructor() {
        super();
        this.sessionSvc = getService('sessionSvc');
        this.uiApi = getService('userInterfaceSvc');
    }

    @api async invoke() {
        const record = await this.uiApi.getRecord(this.recordId, ['Campaign_Job_History_vod__c.Campaign_Activity_vod__c', 'Campaign_Job_History_vod__c.Job_Id_vod__c'], true);
        const vodInfo = await this.sessionSvc.getVodInfo();
        if (vodInfo != null && record?.fields?.Campaign_Activity_vod__c?.value != null && record?.fields?.Job_Id_vod__c?.value != null) {
            const pageRef = {
                type: 'standard__webPage',
                attributes: {
                    url: `${vodInfo.mcServer}/${vodInfo.mcVersion}/api/v1/ae/campaigns/${record.fields.Campaign_Activity_vod__c.value}/jobs/${record.fields.Job_Id_vod__c.value}?ses=${vodInfo.sfSession}&url=${vodInfo.sfEndpoint}`,
                },
            };
            this[NavigationMixin.Navigate](pageRef);
        }
    }
}