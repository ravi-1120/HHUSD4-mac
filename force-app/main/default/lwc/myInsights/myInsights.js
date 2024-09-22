import { LightningElement, api, wire } from 'lwc';
import { getPageController } from "c/veevaPageControllerFactory";
import CommandHandlerFactory from "c/commandHandlerFactory";
import MyInsightsLightningBridge from "c/myInsightsLightningBridge";
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import HTML_REPORT_NAME_FLD from '@salesforce/schema/HTML_Report_vod__c.Name';
import HTML_REPORT_VISIBILITY_CRITERIA_FLD from '@salesforce/schema/HTML_Report_vod__c.Visibility_Criteria_vod__c';

const HTML_REPORT_FIELDS = [HTML_REPORT_NAME_FLD];
const HTML_REPORT_OPTIONAL_FIELDS = [HTML_REPORT_VISIBILITY_CRITERIA_FLD];
export default class MyInsights extends LightningElement {
    /*
    * When this component is displayed on its own, htmlReportId will be defined and htmlReport will be undefined. orgId and
    * baseCdnDomainUrl will be initially undefined but are later defined.
    * When this component is wrapped withing myInsightsV2, the opposite is true. htmlReport will be defined, and htmlReportId will be
    * undefined. orgId and baseCdnDomainUrl will be defined, and their values are not changed in this LWC
    */
    @api htmlReportId;
    @api htmlReport;
    @api orgId;
    @api baseCdnDomainUrl;

    // recordId and objectApiName are both optional parameters, and if they are not received from myInsightsV2 they will be populated here
    @api recordId;
    @api objectApiName;
    @api maxHeight;
    @api pageCtrl;
    @api htmlReports;
    @api myInsightsUuid;

    myInsightsContentPath;
    cdnAuthToken;

    lightningBridge;
    uuid;
    objectRecordId;
    recordApiName;
    optionalObjectFields = [];
    awaitingObjectData = false;
    awaitingObjectRecordData = false;
    visibCritChecked = false;

    @api
    refresh() {
        this.myInsightsReportContainer?.refresh();
    }

    initializePageCtrl() {
        this.pageCtrl = getPageController("HTML_Report_vod__c--MyInsights");
        this.pageCtrl.page = {
            requests: [],
            action: 'View'
        };
    }

    async connectedCallback() {
        if (!this.pageCtrl) {
            this.initializePageCtrl();
        }

        // Bypass @wire if htmlReport is already populated
        if (this.htmlReport == null) {
            this.reportIdTrigger = this.htmlReportId;
        } else if (this.htmlReport?.Id) {
            this.htmlReportId = this.htmlReport.Id;
            this.visibCritChecked = true;
            await this.triggerWires();
        }
    }

    @wire(getRecord, {recordId: "$reportIdTrigger", fields: HTML_REPORT_FIELDS, optionalFields: HTML_REPORT_OPTIONAL_FIELDS})
    async wiredHtmlReport(htmlReport) {
        if (!this.pageCtrl) {
            this.initializePageCtrl();
        }
        // When this.htmlReportId and htmlReport.data are populated this means that
        // the myInsights LWC was configured to use a specific HTML Report and the user
        // has access to this report. We will not show a Toast to the user since it is possible
        // that a page will contain a MyInsights LWC but should only be visible to the user
        // if the user has access to view the HTML Report. Since myInsights LWCs can be on any page (App, Record, Home)
        // the rationale for not showing a Toast is that the Lightning App Builder does not allow an admin to configure
        // the visibility of an HTML Report based on a User's access to the HTML Report. So it may be desired that
        // different users will use the same Flexipage but will only see the myInsights LWC based on their access to the htmlReportId
        if (this.htmlReportId && htmlReport.data) {
            this.htmlReport = htmlReport.data;
            await this.triggerWires();
        } else {
            this.htmlReport = null;
        }
    }

    @wire(getRecord, {recordId: "$objectRecordId", layoutTypes: "Full", modes: "View", optionalFields: "$optionalObjectFields"})
    async wiredObjectRecord(objectRecord) {
        if (objectRecord.data) {
            this.pageCtrl.record = JSON.parse(JSON.stringify(objectRecord.data));
            this.awaitingObjectRecordData = false;
            if (this.recordApiName == null && objectRecord.data.apiName != null) {
                this.recordApiName = objectRecord.data.apiName;
            }
        }
    }

    @wire(getObjectInfo, {objectApiName: "$recordApiName"})
    async wiredObjectInfo(objectInformation) {
        if (objectInformation.data) {
            this.pageCtrl.objectInfo = JSON.parse(JSON.stringify(objectInformation.data));
            this.awaitingObjectData = false;
        }
    }

    get iframeUrl() {
        if (!this.myInsightsContentPath || !this.cdnAuthToken) {
            return null;
        }
        return `${this.myInsightsContentPath}/index.html?${this.cdnAuthToken}`;
    }

    get loading() {
        // We will only show the loading spinner if we determine that we should show this LWC to the user
        // and if the iframeUrl has not been generated yet.ß
        return this.iframeUrl === null && this.showMyInsightsLWC;
    }

    get htmlReportValidAndLoaded() {
        // We will only show the myInsights content if we determine that we should show this LWC to the user
        // and if the iframeUrl has not been generated yet.ß
        return this.iframeUrl && this.showMyInsightsLWC;
    }

    get showMyInsightsLWC() {
        // We only show the myInsights LWC after we determine that the user has access to this.htmlReportId
        // this.htmlReport will be populated by our getRecord wire for htmlReportId if the user has access to the htmlReportId
        // It can also be populated by passing it directly to the component, as is done by upgradedMyInsights
        // Two reasons for not having access to the HTML Report is due to a lack of read permission to HTML_Report_vod__c
        // or the user does not have access to the specific HTML Report due to sharing rules.
        const baseShowReportCondition = this.htmlReportId && this.htmlReport;
        let showReport = baseShowReportCondition;

        // Customers can optionally configure record-level visibility for visualizations since information might not be available
        // to display for all records for which the LWC is configured. Visibility is controlled by the Visibility_Crtieria_vod__c
        // text field on HTML_Report_vod__c that references the Checkbox/Formula(Checkbox) field on the page object.
        // ex: HTML_Report_vod__c.Visibility_Criteria_vod__c = "Account.Show_KOL_Report_vod__c"
        const populatedPageCtrl = this.pageCtrl.record && this.pageCtrl.objectInfo;
        const visCriteriaField = this.htmlReport?.fields?.Visibility_Criteria_vod__c;
        if (!this.visibCritChecked && baseShowReportCondition && this.objectRecordId && visCriteriaField && populatedPageCtrl) {
            const visCriteriaValue = visCriteriaField.value;
            showReport = this.parseVisibilityCriteria(visCriteriaValue);
        }
        return showReport && !this.awaitingObjectRecordData  && !this.awaitingObjectData;
    }

    get myInsightsReportContainer() {
        return this.template.querySelector('c-my-insights-report-container');
    }

    parseVisibilityCriteria(visCriteriaValue) {
        // We will parse information from the value of the Visibility_Criteria_vod__c field to determine which
        // field we will key on for the target object. Any misconfiguration of the value in this field will result
        // in the report being shown on the page.
        let showReport = true;

        if (visCriteriaValue && visCriteriaValue.trim().length > 0) {
            const visCriteriaParts = visCriteriaValue.split('.');
            if (visCriteriaParts.length === 2) {
                const pageObjectName = this.pageCtrl.record.apiName.toLowerCase();
                const pageObjectRecordFields = this.getLowerCaseFieldToValues(this.pageCtrl.record.fields);
                const pageObjectInfoFields = this.getLowerCaseFieldToValues(this.pageCtrl.objectInfo.fields);
                const criteriaObjectName = visCriteriaParts[0].toLowerCase();
                const criteriaFieldName = visCriteriaParts[1].toLowerCase();

                if (criteriaObjectName === pageObjectName
                    && pageObjectRecordFields[criteriaFieldName]
                    && pageObjectInfoFields[criteriaFieldName]) {
                    const showReportFieldValue = pageObjectRecordFields[criteriaFieldName].value;
                    const showReportFieldDataType = pageObjectInfoFields[criteriaFieldName].dataType;
                    showReport = (showReportFieldDataType !== "Boolean" || showReportFieldValue);
                }
            }
        }

        return showReport;
    }

    async triggerWires() {
        // getRecord does not provide data for a field if it's not included on the page layout. We can parse the visibility
        // criteria value and add it as an optionalField to query along with the rest of object record data.
        if (this.htmlReport.Visibility_Criteria_vod__c) {
            this.optionalObjectFields.push(this.htmlReport.Visibility_Criteria_vod__c);
        }
        this.awaitingObjectRecordData = (this.recordId !== undefined);
        this.awaitingObjectData = (this.objectApiName !== undefined);
        this.objectRecordId = this.recordId;
        this.recordApiName = this.objectApiName;
        await this.initializeMyInsights();
    }

    /**
     * Takes the fields in record and creates a set of lower case fields.
     * This will allow us to perform case insensitive field checks.
     * @returns {Set} returns a set of lower case fields from record
     */
    getLowerCaseFieldToValues(record) {
        const lowerCaseFieldsToValues = {};
        if (record) {
            Object.entries(record)
                .forEach(([field, fieldValue]) => {
                    const lowerCaseField = field.toLowerCase();
                    lowerCaseFieldsToValues[lowerCaseField] = fieldValue;
                });
        }
        return lowerCaseFieldsToValues;
    }

    async initializeMyInsights() {
        // construct timer to track my insights initialization process
        const pageMetricsService = this.pageCtrl.getPageMetricsService();
        const compMetricsService = pageMetricsService.createComponentMetricsService('time_to_initialize_component', 'MyInsights');
        const timer = compMetricsService.createMetricTimer();
        timer.start();

        if (this.orgId == null || this.baseCdnDomainUrl == null) {
            [this.orgId, this.baseCdnDomainUrl] = await Promise.all([
                this.pageCtrl.getOrgId(),
                this.pageCtrl.getBaseCdnDomainUrl()
            ]);
        }

        this.updateMyInsightsContentPath(this.orgId, this.baseCdnDomainUrl);
        this.updateCdnAuthToken(this.orgId);

        // eslint-disable-next-line no-restricted-globals
        this.uuid = self.crypto.randomUUID();
        // Update MyInsightsController's htmlReportId
        this.pageCtrl.htmlReportId = this.htmlReportId;
        this.pageCtrl.htmlReportUUID = this.uuid;
        this.initializeLightningBridge(this.baseCdnDomainUrl);

        // end timer once initialization is complete
        timer.end();
    }

    initializeLightningBridge(baseCdnDomainUrl) {
        const veevaUserInterfaceAPI = getPageController("userInterfaceSvc");
        const veevaSessionService = getPageController("sessionSvc");
        const veevaDataService = getPageController("dataSvc");
        const veevaBypassProxyDataStore = getPageController("bypassProxyDataStore");
        const commandHandlers = CommandHandlerFactory.commandHandlers(veevaUserInterfaceAPI, veevaSessionService, veevaDataService, veevaBypassProxyDataStore, this.pageCtrl, this.htmlReports, this.myInsightsUuid);
        this.lightningBridge = new MyInsightsLightningBridge(baseCdnDomainUrl, this.htmlReportId, this.uuid, commandHandlers);
    }

    async updateCdnAuthToken(orgId) {
        const path = `/${orgId}/${this.htmlReportId}/`;
        this.cdnAuthToken = await this.pageCtrl.getCdnAuthToken(path);
    }

    updateMyInsightsContentPath(orgId, baseCdnDomainUrl) {
        const reportPath = `/${orgId}/${this.htmlReportId}`;
        const contentUrl = new URL(baseCdnDomainUrl);
        contentUrl.pathname = reportPath;
        this.myInsightsContentPath = contentUrl.toString();
    }
}