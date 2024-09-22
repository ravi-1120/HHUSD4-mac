/**
 * Auther:              Ravi Modi (Focal CXM)
 * Component Name:      mSD_CORE_StudyDetail
 * Description:         Used for Display Study Detail data in Study Detail Page.
 * Used in:             MHEE Portal Site Study Detail Community Page
 * Created Date:        13th March 2023
 * Lastmodified Date:   16th March 2023
 */

import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

import USER_ID from '@salesforce/user/Id';          //User Id

// Static Resource
import banner from '@salesforce/resourceUrl/PurpleBanner';
import lock from '@salesforce/resourceUrl/MSD_CORE_Lock';
import studyDetailCSS from '@salesforce/resourceUrl/MSD_CORE_StudyDetailCSS';
import bookmark from '@salesforce/resourceUrl/bookmark';

// Apex Class
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import getStudyDetail from '@salesforce/apex/MSD_CORE_StudyDetailController.getStudyDetail';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';

export default class MSD_CORE_StudyDetail extends NavigationMixin(LightningElement) { 

    bannerimg = banner;                     //Banner Image
    lockimg = lock;                         //lock Image
    bookmarkimg = bookmark;                         //bookmark Image

    @track sdrecordId;                      //Storing Study Detail Id from the Parameter
    @track siteAPINames;                    //Site Page Api Name    
    @track siteNames;                       //Site Page URL
    @track phasenav;                        //Navigate to specific Phase tab on Pipeline page
    @track isopenmodal;                     //Used to Hide/Show Popup modal
    @track studyDetail;                     //Storing Study Detail Data
    @track contactrole;                     //Storing contact role

    // Get Banner Image in Bacground
    get backgroundStyle() {
        return `background-image:url(${banner})`;
    }

    // Method Name:         WiredgetSiteNameAndAPIName
    // Method Use:          Used for getting all community site page and url for the navigation
    // Developer Name:      Ravi Modi
    // Created Date:        13th March 2023
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({error, data}) {
        console.log('getAllSiteNameAndAPINames-->',{data});
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
            if (this.studyDetail) {
                this.phasenav = this.siteNames.Pipeline + '?phase=' + this.studyDetail.MSD_CORE_Phase__c;
            }
        } else if (error) {
            console.log('ERROR in Getting Sites Name-->',{error});
        } 
    }

    // Method Name:         WiredgetStateParameters
    // Method Use:          Used for getting Record Id from the parameter
    // Developer Name:      Ravi Modi
    // Created Date:        14th March 2023
    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.sdrecordId = currentPageReference.state.recordId;
        }
    }

    // Method Name:         WiredgetStudyDetail
    // Method Use:          Used for getting Study Detail Record all Value
    // Developer Name:      Ravi Modi
    // Created Date:        14th March 2023
    @wire(getStudyDetail, { recordId : '$sdrecordId' })
    WiredgetStudyDetail(value) {
        console.log('wiredgetStudyDetail -->',{value});
        const { data, error } = value;
        if(data) {
            this.studyDetail = data; 
            if (data.MSD_CORE_Medical_Therapeutic_Area__r) {
                document.documentElement.style.setProperty('--therapeuticBGcolor', data.MSD_CORE_Medical_Therapeutic_Area__r.MSD_CORE_BG_color__c);
                document.documentElement.style.setProperty('--therapeuticTEXTcolor', data.MSD_CORE_Medical_Therapeutic_Area__r.MSD_CORE_Text_color__c);
            }
            if (this.siteNames.Pipeline) {
                this.phasenav = this.siteNames.Pipeline + '?phase=' + data.MSD_CORE_Phase__c;
            }
        } else if(error) {
            console.log('wiredgetStudyDetail--->',{error});
        }
    }

    // Method Name:         renderedCallback
    // Method Use:          Used for loading external CSS file
    // Developer Name:      Ravi Modi
    // Created Date:        16th March 2023
    renderedCallback() {
        Promise.all([
            loadStyle(this, studyDetailCSS),
        ]).then(() => {
            console.log('Files loaded');
        })
        .catch(error => {
            console.log(error.body.message);
        });
        this.addCSSForWindows();

        if(this.siteNames && this.contactrole) {
            this.fireOnLoadEvent();
        }
    }

    // Method Name:         connectedcallback
    // Method Use:          Called when page is loaded
    // Developer Name:      Ravi Modi
    // Created Date:        3rd April 2023    
    connectedCallback() {

        // For Scrolling to top of the page
        let scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
    }

    // Method Name:         wiredgetContactRole
    // Method Use:          Used for getting Contact role
    // Developer Name:      Ravi Modi
    // Created Date:        3rd April 2023
    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        console.log('wiredgetContactRole-->',{ value });
        const { data, error } = value;
        if (data) {
            this.contactrole = data;
        }
        if (error) {
            console.log({ error });
        }
    }

    // Method Name:         addCSSForWindows
    // Method Use:          Used CSS for Windows OS
    // Developer Name:      Ravi Modi
    // Created Date:        16th March 2023
    addCSSForWindows() {
        try {
            let os = navigator.userAgent;
            if (os.search('Windows')!==-1){
                let cmpcls = this.template.querySelector('.compoundname');
                if (cmpcls) {
                    cmpcls.classList.add('compoundnamewindows')
                }
            }
        } catch (error) {
            console.log('Error in addCSSForWindows-->',{error});
        }
    }

    // Method Name:         requestbtnclk
    // Method Use:          Used for Navigation to Schedule Appointment Page
    // Developer Name:      Ravi Modi
    // Created Date:        14th March 2023
    requestbtnclk(event) {
        
        let resid = event.currentTarget.dataset.id;
        let typeget = event.currentTarget.dataset.type;
        let typeval = '';
        let diseaseval = '';
        if (typeget == 'Oncology') {
            typeval = 'Oncology';
            diseaseval = event.currentTarget.dataset.typevalue;
        } else {
            typeval = 'NonOncology';
            diseaseval = event.currentTarget.dataset.value;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.siteAPINames.Schedule,
                url: this.siteNames.Schedule + '?recordId=' + resid + '&type=' + typeval + '&disease=' + diseaseval + '&ptype=' + this.studyDetail.MSD_CORE_Phase__c +'&prevPage=studydetail'
            }
        })
        let contname = event.currentTarget.dataset.value;
        this.fireDataLayerEvent('button', '', "request presentation", '',this.siteAPINames.Schedule, this.siteNames.Schedule + '?recordId=' + resid + '&type=' + typeval + '&disease=' + diseaseval + '&ptype=' + this.studyDetail.MSD_CORE_Phase__c +'&prevPage=studydetail', contname);    //RT GA 1122  
    }

    // Method Name:         openmodal
    // Method Use:          Used for Open Forward Looking Statement Popup
    // Developer Name:      Ravi Modi
    // Created Date:        14th March 2023
    openmodal(event) {
        try {
            this.template.querySelector("c-m-s-d_-c-o-r-e_-f-l-s-popup").openModal();
        } catch (error) {
            console.log('Error in OpenModal=>',{error});
        }
        var contname = event.currentTarget.dataset.name;
        this.fireDataLayerEvent('button', '', "forward looking statement", '','StudyDetail__c', '/studydetail', contname);    //RT GA 1122
    }

    // Method Name:         navbreadcrumb
    // Method Use:          Used for Navigate breadcrumb for mobile view
    // Developer Name:      Ravi Modi
    // Created Date:        05 April 2023
    navbreadcrumb(event) {
        let nav = event.currentTarget.dataset.navvar;
        let name;
        let url;

        if(nav== "Dashboard") {
            name = this.siteAPINames.Dashboard;
            url = this.siteNames.Dashboard;
            this.fireDataLayerEvent('link', '', "Dashboard", '','Home', '/merckmhee', contname);    //RT GA 1122
        } else if(nav== "Phase") {
            name = this.siteAPINames.Pipeline;
            url = this.phasenav;
            this.fireDataLayerEvent('link', '', phasename, '','pipeline__c', '/pipeline', contname);    //RT GA 1122
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: name,
                url: url
            }
        })
    }
    clickdashboard(event){
    let contname = event.currentTarget.dataset.contname;
    this.fireDataLayerEvent('link', '', "Dashboard", '','Home', '/merckmhee', contname);    //RT GA 1122
    }
    clickpipeline(event){
    let contname = event.currentTarget.dataset.contname;
    this.fireDataLayerEvent('link', '', "Pipeline Information", '','pipeline__c', '/pipeline', contname);    //RT GA 1122
    }
    clickPhase(event){
    let contname = event.currentTarget.dataset.contname;
    let phasename = event.currentTarget.dataset.phasename;
    this.fireDataLayerEvent('link', '', phasename, '','pipeline__c', '/pipeline', contname);    //RT GA 1122
    }

    //Google Analytics Event
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, contentvalue) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'resources',
                page_purpose: 'product detail',
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
                page_title: 'Study Details',

            },
            bubbles: true,
            composed: true
        }));
    }
    fireOnLoadEvent() {
        console.log('Call Events');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                data_design_category: '',
                data_design_action: '',
                data_design_label: '',
                data_design_module: '',
                page_type: 'resources',
                page_purpose: 'product detail',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: this.siteAPINames.StudyDetail,
                link_url: this.siteNames.StudyDetail,
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: this.studyDetail.Name,
                page_localproductname: '',
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'Study Details',
            },
            bubbles: true,
            composed: true
        }));
    }
}