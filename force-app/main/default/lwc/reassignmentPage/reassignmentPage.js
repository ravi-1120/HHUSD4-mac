import { LightningElement } from 'lwc';
import ReassignmentDataService from "c/reassignmentDataService";
import VeevaMessageService from "c/veevaMessageService";
import VeevaSessionService from "c/veevaSessionService";
import getDomainUrl from '@salesforce/apex/WeChatSettings.getDomainUrl';


export default class ReassignmentWrapper extends LightningElement {
    pageStatus = '';
    detailProcessId;
    waiting = false;

    get inSummary(){
        return this.pageStatus === 'summary';
    }

    get inDetail(){
        return this.pageStatus === 'detail';
    }

    get inUploading(){
        return this.pageStatus === 'uploading';
    }

    async initComponent() {
        this.waiting = true;
        const sessionSvc = new VeevaSessionService();
        const messageSvc = new VeevaMessageService();
        const domainUrl = await getDomainUrl();
        this.dataSvc = new ReassignmentDataService(sessionSvc, messageSvc, ['WeChat'], domainUrl);
        this.pageStatus = 'summary';
        this.waiting = false;
    }

    async connectedCallback() {
        this.initComponent();
    }

    actionHandler(event) {
        event.stopPropagation();
        const {action, recordId} = event.detail.data;
        if (action === 'goToDetail') {
            this.pageStatus = 'detail';
            this.detailProcessId = recordId;
        }
    }

    pageStatusChangedHandler(event) {
        const {status, recordId} = event.detail.data;
        this.pageStatus = status;
        this.detailProcessId = recordId;
    }
}