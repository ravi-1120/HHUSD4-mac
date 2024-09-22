import { LightningElement, wire, api, track } from 'lwc';
import getPhaseDetail from '@salesforce/apex/MSD_CORE_Pipeline.getPhaseDetail';
import { NavigationMixin } from 'lightning/navigation';
import rightarrow from '@salesforce/resourceUrl/rightarrow2';
import USER_ID from "@salesforce/user/Id";
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import corePhaseCSS from '@salesforce/resourceUrl/corePhaseCSS'
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import whitearrow from '@salesforce/resourceUrl/rarrow';
import FORM_FACTOR from '@salesforce/client/formFactor';
export default class MSD_CORE_Phase extends NavigationMixin(LightningElement) {

    @api phaseType;
    @api phaseTypeLabel;
    rowLimit = 5;
    rowOffSet = 0;
    @api totalCount;
    @track PhaseDetail = [];
    error;
    arrow = rightarrow;
    ctrCounter = 1;
    @track searchKey = '';
    therapeuticArea = '';
    @track schedulepageapi;
    @track schedulepage;
    isLoading = false;
    isloadMore = true;
    @track contactrole = '';
    @track sortby = 'Name';
    isLoadCompleted = false;
    whitearrow = whitearrow;//Rusheel-1028
    placeholderText = '';//Rusheel-1022
    @track studydetailpageapi;//Rusheel-Jira-1020
    @track studydetailpage;//Rusheel-Jira-1020

    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log({ data });
        console.log({ error });
        if (data) {
            this.schedulepageapi = data.siteAPINames.Schedule;
            this.schedulepage = data.siteNames.Schedule;
            this.studydetialpageapi = data.siteAPINames.StudyDetail;//Rusheel-Jira-1020
            this.studydetailpage = data.siteNames.StudyDetail;//Rusheel-Jira-1020

        }
        if (error) {
            console.log({ error });
        }
    }
    get isShow() {
        if (this.totalCount > 0) {
            return true;
        } else {
            return false;
        }
    }

    get filteroptions() {
        return [
            { label: 'View All', value: '' },
            { label: 'Cardiovascular disease', value: 'Cardiovascular disease' },
            { label: 'Diabetes and endocrinology', value: 'Diabetes and endocrinology' },
            { label: 'Infectious disease', value: 'Infectious disease' },
            { label: 'Neurosciences', value: 'Neurosciences' },
            { label: 'Oncology', value: 'Oncology' },
            { label: 'Respiratory and immunology', value: 'Respiratory and immunology' },
            { label: 'Vaccines', value: 'Vaccines' },
        ];
    }

    resetValue() {
        this.PhaseDetail = [];
        this.isloadMore = true;
        this.ctrCounter = 1;
        this.rowOffSet = 0;
    }
    connectedCallback() {
        /* Jira-1022-start */
        if (FORM_FACTOR === 'Small') {
            this.placeholderText = 'Search';
        } else {
            this.placeholderText = 'Type a clinical trial name, number or therapeutic area';
        }
        /* Jira-1022-end */

        this.setCustomStaticCSS();
        console.log('connectedCallback');
        this.resetValue();//Removed SetTimeOut Code
        this.loadPhaseDetail(true);
        this.contactrole = sessionStorage.getItem("SFMC_Audience");
    }

    setCustomStaticCSS() {
        Promise.all([
            loadStyle(this, corePhaseCSS),
        ]).then(() => {
            console.log('Files loaded');
        });
    }

    get sortoptions() {
        return [
            { label: 'Alphabatically', value: 'Name' },
            { label: 'By therapeutic area', value: 'MSD_CORE_Therapeutic__c' },
        ];
    }
    handleTherapeticAreaChange(event) {
        this.therapeuticArea = event.detail.value;
        this.resetValue();
        this.loadPhaseDetail(true);
        this.fireDataLayerEvent('filter', '', this.therapeuticArea, '', 'pipeline__c', '/pipeline', '');    //RT-N-1053
    }
    handleSort(event) {
        this.sortby = event.target.value;
        this.resetValue();
        this.loadPhaseDetail(true);
        this.fireDataLayerEvent('sort', '', this.sortby, '', 'pipeline__c', '/pipeline', '');    //RT-N-1053
    }
    disable(event){
        event.preventDefault();
    }
    handleSearch(event) {
        this.searchKey = event.target.value;
        this.resetValue();
        this.loadPhaseDetail(true);
        if(event.type == 'blur'){
            this.fireDataLayerEvent('search', '', this.searchKey, '', 'pipeline__c', '/pipeline', '');
        }
            
    }
    loadPhaseDetail(isPageLoad) {
        console.log('<===loadPhaseDetail===>');

        if (!isPageLoad && this.ctrCounter == this.totalCount + 1) {
            console.log('<===false===>');
            return false;
        }

        this.isLoading = true;
        this.isLoadCompleted = false;
        getPhaseDetail({ PhaseType: this.phaseType, pageSize: this.rowLimit, offset: this.rowOffSet, searchKey: this.searchKey, therapeuticArea: this.therapeuticArea, sortby: this.sortby })
            .then(result => {
                console.log('GET PHASE DETAIL');
                console.log({ result });
                let newResult = this.setStyling(result);
                if (this.PhaseDetail == undefined) {
                    this.PhaseDetail = [];
                }
                let updatedRecords = [...this.PhaseDetail, ...newResult];
                this.PhaseDetail = [];
                this.PhaseDetail = [...updatedRecords];
                console.log('this.PhaseDetail-->', this.PhaseDetail);
                this.error = undefined;
                if (this.PhaseDetail.length == this.totalCount) {
                    this.isloadMore = false;
                }
                this.isLoading = false;
                this.isLoadCompleted = true;
            })
            .catch(error => {
                this.error = error;
                this.PhaseDetail = undefined;
                this.isLoading = false;
            });
    }
    viewRequest(event) {
        console.log({ event });
        let resid = event.currentTarget.dataset.id;
        console.log({ resid });
        let typeget = event.currentTarget.dataset.type;
        console.log({ typeget });
        let typeval = '';
        let diseaseval = '';
        if (typeget == 'Oncology') {
            typeval = 'Oncology';
            diseaseval = event.currentTarget.dataset.typevalue;
        } else {
            typeval = 'NonOncology';
            diseaseval = event.currentTarget.dataset.value;
        }
        console.log({ diseaseval });
        this.fireDataLayerEvent('button', '', 'request presentation', '', this.schedulepageapi, this.schedulepage, diseaseval);    //Event Added
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.schedulepageapi,
                url: this.schedulepage + '?recordId=' + resid + '&type=' + typeval + '&disease=' + diseaseval + '&ptype=' + this.phaseType + '&prevPage=pipeline'

            }
        })
    }
    handleCustomEvent(event) {
        console.log('handlePagination ---- ' + event.detail);
        this.pageNumber = event.detail;
    }
    setStyling(phaseDetail) {
        let _ctrCounter = this.ctrCounter;
        let _phaseDetail = phaseDetail.map(
            record => {
                const fields = Object.assign({ "cssStyle": this.totalCount == 1 ? 'border_cls3 slds-p-vertical_small slds-p-left_medium' : (_ctrCounter == this.totalCount) ? 'border_cls2 slds-p-vertical_small slds-p-left_medium' : 'border_cls slds-p-vertical_small slds-p-left_medium' }, record)
                _ctrCounter++;
                return fields
            });
        console.log('this.ctrCounter = _ctrCounter' + _ctrCounter);
        this.ctrCounter = _ctrCounter;
        return _phaseDetail;
    }
    loadMoreData() {
        if (this.isloadMore && this.isLoadCompleted) {
            if (this.rowOffSet != this.totalCount) {
                this.rowOffSet = this.rowOffSet + this.rowLimit;
            }
            this.loadPhaseDetail(false);
        }
    }

    @api
    handleLoadMore() {
        this.loadMoreData();
    }

    // Rusheel-Jira-1020-navigatetostudydetail-start
    viewStudy(event) {
        console.log(event)
        let resid = event.currentTarget.dataset.id;
        console.log({ resid });
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.studydetialpageapi,
                url: this.studydetailpage + '?recordId=' + resid

            }
        })
        this.fireDataLayerEvent('button', '', "view study details", '',this.studydetialpageapi, this.studydetailpage + '?recordId=' + resid, '');    //RT GA 1122

    }
    // Rusheel-Jira-1020-navigatetostudydetail-end

    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, contentvalue) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'resources',
                page_purpose: 'product listing',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: linkedtext,
                link_url: linkedurl,
                content_count: '',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: contentvalue,
                page_localproductname: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'scheduleappointment',

            },
            bubbles: true,
            composed: true
        }));
    }
}