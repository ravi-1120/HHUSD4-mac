import { LightningElement, wire, track, api } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';

import banner from '@salesforce/resourceUrl/PurpleBanner';
import minize from '@salesforce/resourceUrl/minimize';
import hint from '@salesforce/resourceUrl/hint';
import max from '@salesforce/resourceUrl/max';
import closemodal from '@salesforce/resourceUrl/closemodal';
import crossmark from '@salesforce/resourceUrl/cross';
import rightarrow from '@salesforce/resourceUrl/rightarrow2';
import popupmodelcss from '@salesforce/resourceUrl/popupmodelcss';

import getPhaseCount from '@salesforce/apex/MSD_CORE_Pipeline.getPhaseCount';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';

import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';

import USER_ID from "@salesforce/user/Id";
import logo from '@salesforce/resourceUrl/logo';

const phaseType = ['Phase2', 'Phase3', 'In Review'];
const LAST_INTERACTION_KEY = 'lastInteractionTime';

export default class MSD_CORE_Pipeline extends NavigationMixin(LightningElement) {
    @api phaseTypeLabel;
    cross = crossmark;
    @track tab1Bool = true;
    @track tab2Bool;
    @track tab3Bool;
    activetabvalue = '1'
    bannerimg = banner;
    minize = minize;
    hint = hint;
    max = max;
    isVisibaleGrayList = true;
    isMaxVisible = false;
    isMinVisible = true;
    isShowModal = false;
    closemodal = closemodal;
    arrow = rightarrow;
    phase2Count = 0;
    phase3Count = 0;
    inReviewCount = 0;

    error;

    //Added for mobile screens Start

    @track isPhase2Bool = true;
    @track isPhase3Bool = false;
    @track isInreviewBool = false;

    // Added new variable for active selected tab
    @track phase2lstcls = "slds-tabs_default__item slds-is-active";
    @track phase3lstcls = "slds-tabs_default__item";
    @track inReviewlstcls = "slds-tabs_default__item";

    value = 'Phase 2';
    test = 'Test';
    //Added for mobile screens End

    @track siteAPINames;
    @track siteNames;
    @track contactrole = '';

    @track phasevalue;

    @track mobilescreen;

    renderedCallback() {

        Promise.all([
            loadStyle(this, popupmodelcss)
        ]).then(() => {
        })
            .catch(error => {
                console.log(error.body.message);
            });


    }

    // Method Name:         WiredgetStateParameters
    // Method Use:          Used for getting Phase Name From the parameter
    // Developer Name:      Ravi Modi
    // Created Date:        14th March 2023
    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            if (currentPageReference.state.phase) {
                this.phasevalue = currentPageReference.state.phase;
                if (this.phasevalue == 'In Review') {
                    this.isInreviewBool = true;
                    this.isPhase2Bool = false;
                    this.isPhase3Bool = false;
                    this.value = 'In Review';

                    this.phase2lstcls = "slds-tabs_default__item";
                    this.phase3lstcls = "slds-tabs_default__item";
                    this.inReviewlstcls = "slds-tabs_default__item slds-is-active";

                    this.tab3Bool = true;
                    this.tab1Bool = false;
                    this.tab2Bool = false;
                } else if (this.phasevalue == 'Phase2') {
                    this.isPhase2Bool = true;
                    this.isInreviewBool = false;
                    this.isPhase3Bool = false;
                    this.value = 'Phase 2';

                    this.inReviewlstcls = "slds-tabs_default__item";
                    this.phase2lstcls = "slds-tabs_default__item slds-is-active";
                    this.phase3lstcls = "slds-tabs_default__item";

                    this.tab1Bool = true;
                    this.tab2Bool = false;
                    this.tab3Bool = false;
                } else if (this.phasevalue == 'Phase3') {
                    this.isPhase3Bool = true;
                    this.isInreviewBool = false;
                    this.isPhase2Bool = false;
                    this.value = 'Phase 3';

                    this.phase3lstcls = "slds-tabs_default__item slds-is-active";
                    this.inReviewlstcls = "slds-tabs_default__item";
                    this.phase2lstcls = "slds-tabs_default__item";

                    this.tab2Bool = true;
                    this.tab1Bool = false;
                    this.tab3Bool = false;
                }
            }
        }
    }

    @wire(getPhaseCount, {})
    wiredgetPhaseCount(value) {
        console.log('wiredgetPhaseCount Count');
        console.log({ value });
        const { data, error } = value;
        if (data) {
            this.setPhaseCount(data);
        } else if (error) {
            this.error = error;
            console.log('error in getRequestsCount ' + JSON.stringify(this.error));
        }
    }

    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log({ data });
        console.log({ error });
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
        }
        if (error) {
            console.log({ error });
        }
    }

    connectedCallback() {
        const lastInteractionTime = sessionStorage.getItem(LAST_INTERACTION_KEY);
        console.log('LAST_INTERACTION_KEY--->'+lastInteractionTime);
        if(!lastInteractionTime || this.isTimeElapsed (lastInteractionTime)){
           this.isShowModal = true;
           sessionStorage.setItem(LAST_INTERACTION_KEY, String(Date.now()));
        }
        

        let scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);

        //Added for mobile redirection
        if (screen.width < 768) {
            // this.isPhase2Bool = true;
            // this.mobtabredirecton();
        }
        //UAT_Bug_01 - RT
        var screenwidth = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        if (screenwidth > 768) {
            this.mobilescreen = false;
        } else {
            this.mobilescreen = true;
        }

        sessionStorage.setItem("SFMC_ID", USER_ID);
        this.contactrole = sessionStorage.getItem("SFMC_Audience");
        this.fireOnLoadEvent();
    }

    @api
    loadmoredata(data) {
        console.log('<==loadmoredata==>');
        console.log({ data });
        let phasecmp = this.template.querySelectorAll('c-m-s-d_-c-o-r-e_-phase');
        console.log('phasecmp==>',{phasecmp});
        for (var key in phasecmp) {
            if (phasecmp[key].phaseType == "Phase2") {
                console.log('===Phase 2===');
                phasecmp[key].handleLoadMore();
            } else if (phasecmp[key].phaseType == "Phase3") {
                console.log('===Phase 3===');
                phasecmp[key].handleLoadMore();
            } else if (phasecmp[key].phaseType == "In Review") {
                console.log('===IN Review===');
                phasecmp[key].handleLoadMore();
            }
        }
    }

    isTimeElapsed(lastInteractionTime){
        const currentTime = Date.now();
        const thirtyminsinMS = 30*60*1000;
        const lastInteractionTimeInMS = parseInt(lastInteractionTime);
        return(currentTime-lastInteractionTimeInMS) >= thirtyminsinMS;
    }

    handleTabClick(event) {
        let buttonClicked = event.target.value;
        switch (buttonClicked) {
            case '1':
                this.tab1Bool = true;
                this.tab2Bool = false;
                this.tab3Bool = false;
                break;
            case '2':
                this.tab1Bool = false;
                this.tab2Bool = true;
                this.tab3Bool = false;
                break;
            case '3':
                this.tab1Bool = false;
                this.tab2Bool = false;
                this.tab3Bool = true;
                break;

        }
    }
    showList(event) {
        this.isMaxVisible = false;
        this.isVisibaleGrayList = true;
        this.isMinVisible = true;
    }
    hideList(event) {
        this.isMaxVisible = true;
        this.isVisibaleGrayList = false;
        this.isMinVisible = false;
    }
    showModal(event) {
        event.stopPropagation();
        this.isShowModal = true;
        sessionStorage.setItem(LAST_INTERACTION_KEY, String(Date.now()));
        this.fireDataClickEvent("button", '',"forward looking statement", '', 'pipeline__c', '/pipeline');//RT GA 1122
    }
    closeModal(event) {
        event.stopPropagation();
        this.isShowModal = false;
        var btnlabel = event.currentTarget.dataset.label;
        this.fireDataClickEvent("button", '', btnlabel, 'modal', 'pipeline__c', '/pipeline');//RT-N-1053
    }
    setPhaseCount(phases) {
        let phase2Count = 0;
        let phase3Count = 0;
        let inReviewCount = 0;

        console.log('setPhaseCount ' + phases);
        try {
            phaseType.forEach(record => {

                var results = phases.filter(row => {
                    return row.MSD_CORE_Phase__c == record;
                });

                if (record == 'Phase2') {
                    results.forEach(record => {
                        phase2Count += parseInt(record.expr0);
                    });

                }
                else if (record == 'Phase3') {
                    results.forEach(record => {
                        phase3Count += parseInt(record.expr0);
                    });
                }
                else if (record == 'In Review') {
                    results.forEach(record => {
                        inReviewCount += parseInt(record.expr0);
                    });
                }
            });

            this.phase2Count = phase2Count;
            this.phase3Count = phase3Count;
            this.inReviewCount = inReviewCount;
        } catch (error) {
            console.log('exception in setRequestCount ' + error)
        }
        this.mobPickValueandLabels();
    }
    handleCustomEvent(event) {
        console.log('handlePagination ---- ' + event.detail);
        this.pageNumber = event.detail;
    }
    handleTabClick(event) {
        if (event.currentTarget.dataset.id != undefined) {
            let tabName = event.currentTarget.dataset.id
            var phasecount = event.currentTarget.dataset.count;
            this.template.querySelector(".slds-is-active").className = 'slds-tabs_default__item';
            event.currentTarget.className = 'slds-tabs_default__item slds-is-active';
            console.log('TAB NAME ' + tabName);
            this.setTabVisibility(tabName,phasecount);
        }
    }
    setTabVisibility(tabName,phasecount) {
        switch (tabName) {
            case 'phase2':
                this.fireDataLayerEvent('content_switcher', '', 'phase 2', '', 'pipeline__c', '/pipeline',phasecount); //RT GA 1122
                this.tab1Bool = true;
                this.tab2Bool = false;
                this.tab3Bool = false;
                break;
            case 'phase3':
                this.fireDataLayerEvent('content_switcher', '', 'phase 3', '', 'pipeline__c', '/pipeline',phasecount); //RT GA 1122
                this.tab1Bool = false;
                this.tab2Bool = true;
                this.tab3Bool = false;
                break;
            case 'inreview':
                this.fireDataLayerEvent('content_switcher', '', 'in review', '', 'pipeline__c', '/pipeline',phasecount); //RT GA 1122
                this.tab1Bool = false;
                this.tab2Bool = false;
                this.tab3Bool = true;
                break;

        }
    }

    handlenavigatedashboard() {

        this.fireDataClickEvent("top_nav_breadcrumb", '', 'Dashboard', 'navigation', this.siteNames.Dashboard, this.siteAPINames.Dashboard);//RT GA 1122
    }

    fireDataClickEvent(category, action, label, module, linkedtext, linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'resource',
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
                content_name: '',
                page_localproductname: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'pipeline',

            },
            bubbles: true,
            composed: true
        }));
    }

    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl,phasecount) {
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
                content_count: phasecount,
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'pipeline',

            },
            bubbles: true,
            composed: true
        }));
    }

    //Google Analytics Event
    fireOnLoadEvent() {
        console.log('EVENT TRIGGERED');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                data_design_category: '',
                data_design_action: '',
                data_design_label: '',
                data_design_module: '',
                page_type: 'resources',
                page_purpose: 'product listing',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'pipeline__c',
                link_url: '/pipeline',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'pipeline',
            },
            bubbles: true,
            composed: true
        }));
    }


    // added for genrating picklist for mobile view Start
    mobPickValueandLabels() {

        var phase2Label = 'Phase 2 (' + this.phase2Count + ')';
        var phase3Label = 'Phase 3 (' + this.phase3Count + ')';
        var inreviewLabel = 'In Review (' + this.inReviewCount + ')';

        this.tabsetOptions = [
            { label: phase2Label, value: 'Phase 2' },
            { label: phase3Label, value: 'Phase 3' },
            { label: inreviewLabel, value: 'In Review' }
        ];

        this.mobTabvalue = phase2Label;
        var mtbValue = this.tabname;

        if (mtbValue == 'Phase 2') {
            this.mobTabvalue = phase2Label;
        } else if (mtbValue == 'Phase 3') {
            this.mobTabvalue = phase3Label;
        } else if (mtbValue == 'In Review') {
            this.mobTabvalue = inreviewLabel;
        }
    }
    // added for genrating picklist for mobile view End

    //Added for mobile screen Start
    handlePickListChange(event) {
        console.log("pick list changed");
        var tabValue = event.currentTarget.value;
        console.log("tab Value ===>" + tabValue);

        if (tabValue == 'Phase 2') {
            this.isPhase2Bool = true;
            this.isPhase3Bool = false;
            this.isInreviewBool = false;
        } else if (tabValue == 'Phase 3') {
            this.isPhase2Bool = false;
            this.isPhase3Bool = true;
            this.isInreviewBool = false;
        } else if (tabValue == 'In Review') {
            console.log('IFFF');
            this.isPhase2Bool = false;
            this.isPhase3Bool = false;
            this.isInreviewBool = true;
        }
    }
    //Added for mobile screen End


    //Added for mobile screen Start
    mobtabredirecton() {

        console.log(this.tabname);

        var tabValue = this.tabname;
        // this.mobTabvalue = tabValue;

        if (tabValue == 'Phase 2') {

            this.isPhase2Bool = true;
            this.isPhase3Bool = false;
            this.isInreviewBool = false;

        } else if (tabValue == 'Phase 3') {

            this.isPhase2Bool = false;
            this.isPhase3Bool = true;
            this.isInreviewBool = false;

        } else if (tabValue == 'In Review') {
            this.isPhase2Bool = false;
            this.isPhase3Bool = false;
            this.isInreviewBool = true;
        }


        this.value = this.tabname;
    }
    //Added for mobile screen End

}