import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getPageController } from 'c/veevaPageControllerFactory';
import getVisibleHTMLReports from "@salesforce/apex/MyInsightsService.getVisibleHTMLReports";
import {MessageContext, subscribe} from "lightning/messageService";
import myInsightsNavigationChannel from '@salesforce/messageChannel/MyInsights_Navigation__c';

export default class MyInsightsV2 extends LightningElement {
    /*
        htmlReport stores a serialized JSON object with the following fields:
            - String id: id of the selected HTML Report
            - String pageType: type of page report is on (used for deployment validation)
            - String objectType: type of object page is related to (used for deployment validation)
    */
    @api htmlReport;
    @api recordId;
    @api objectApiName;
    @api maxHeight;

    htmlReports = [];
    loading;

    orgId;
    baseCdnDomainUrl;

    // Vars related to viewSection and viewRecord commands
    myInsightsUuid;
    hasRendered = true;
    urlStateParameters = null;

    @wire(MessageContext)
    messageContext;

    subscription;

    get oneReport() {
        return this.htmlReports?.length === 1;
    }

    get multReports() {
        return this.htmlReports?.length > 1;
    }

    get firstReport() {
        if (this.htmlReports?.length > 0) {
            return this.htmlReports[0];
        }
        return null;
    }

    initializePageCtrl() {
        this.pageCtrl = getPageController("HTML_Report_vod__c--MyInsights");
        this.pageCtrl.page = {
            requests: [],
            action: 'View'
        };
    }

    parseHTMLReportId() {
        try {
            return JSON.parse(this.htmlReport);
        } catch (error) {
            return {
                id: this.htmlReport
            }
        }
    }

    async connectedCallback() {
        const parsedReport = this.parseHTMLReportId();
        this.loading = true;
        this.initializePageCtrl();
        // Querying for orgId and baseCdnDomainUrl here to prevent unnecessary repetition for multiple HTML Reports
        [this.orgId, this.baseCdnDomainUrl] = await Promise.all([
            this.pageCtrl.getOrgId(),
            this.pageCtrl.getBaseCdnDomainUrl()
        ]);

        try {
            this.htmlReports = await getVisibleHTMLReports({
                recordId: this.recordId,
                reportValue: parsedReport
            });
        } catch (e) {
            // Keeping reports as empty array in the case of exception
            this.htmlReports = [];
        }
        this.loading = false;

        // eslint-disable-next-line no-restricted-globals
        this.myInsightsUuid = self.crypto.randomUUID();
        this.subscribeToNavigationChannel();
    }

    @api
    refresh() {
        if (this.oneReport) {
            this.myInsights[0].refresh();
        }
    }

    get myInsights() {
        return this.template.querySelectorAll('c-my-insights');
    }

    // Logic related to viewRecord and viewSection commands
    subscribeToNavigationChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, myInsightsNavigationChannel, message => this.handleMessage(message));
        }
    }

    handleMessage(message) {
        if (this.htmlReports.length > 1 && message.myInsightsUuid === this.myInsightsUuid && message.viewSection && this.isValidNavTarget(message.viewSection.recordId)) {
            this.handleTabNav(message.viewSection.recordId);
        }
    }

    isValidNavTarget(recordId) {
        return this.htmlReports.find(e => e.Id === recordId) !== undefined;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
        }
    }

    renderedCallback() {
        if (this.hasRendered && this.htmlReports.length !== 0) {
            if(this.urlStateParameters?.c__myinsightsTabId && this.isValidNavTarget(this.urlStateParameters.c__myinsightsTabId)) {
                this.handleTabNav(this.urlStateParameters.c__myinsightsTabId);
            }
            this.hasRendered = false;
        }
    }

    handleTabNav(id){
        this.template.querySelector('lightning-tabset').activeTabValue = id;
    }
}