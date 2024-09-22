import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import CloseIconImage from '@salesforce/resourceUrl/cancelicon';
import { CurrentPageReference } from 'lightning/navigation';

import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';
import updateResendInvitation from '@salesforce/apex/MSD_CORE_RegistrationController.updateResendInvitation';

import mfrdomainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

export default class MSD_CORE_GenericPopupModel extends NavigationMixin(LightningElement) {

    @api popup;
    @track expiredInvitation = false;
    @track existingCustomer = false;
    @track invalidLink = false;
    @track pendingReq = false;
    @track userNotExist = false;
    @track siteName = '';
    @track siteApiName = '';
    @track accrecordId;
    @track resendclick;
    @track resendnext = false;

    CloseIcon = CloseIconImage;

    contactpageurl = mfrdomainurl +'/my-contacts';

    connectedCallback() {
        console.log('this.popup-->', this.popup);
        this.popupmodel(this.popup);    
    }
    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.accrecordId = currentPageReference.state.recordId;
        }
    }


    @api
    popupmodel(popupvalue) {
        console.log('Popup Model Called');
        console.log({ popupvalue });
        if (popupvalue == "ExpiredInvitation") {
            this.expiredInvitation = true;
        } else if (popupvalue == "ExistingCustomer") {
            this.existingCustomer = true;
        } else if (popupvalue == "InvalidLink") {
            this.invalidLink = true;
        } else if(popupvalue == "PendingReq") {
            this.pendingReq = true;
        } else if(popupvalue == 'UserNotExist') {
            this.userNotExist = true;
        } 
    }

    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log('login mheee--->', { data });
        console.log({ error });
        if (data) {
            this.siteName = data.siteAPINamesdebuglog;
            this.siteApiName = data.siteNames;
        }
        if (error) {
            console.log({ error });
        }
    }
    
    handleresend(){
        console.log('accountid')
        updateResendInvitation({accountid : this.accrecordId})
        .then((result) => {
                console.log('result of resend-->',{result});
                this.resendclick = result ;
                this.resendnext = true;
                console.log('this.resendclick',this.resendclick);
            })
        .catch((error) => {
            console.log('Error of resend--->',{error});
        });    
        this.fireDataLayerEvent("button", 'step_0', "resend invitation", "registration_flow", 'Register', '/SelfRegister','account management','registration');
    }

    handleGA(){
        window.location.href
        this.fireDataLayerEvent("link", 'step_0', "contact merck", "registration_flow", 'mycontacts', '/my-contacts','account management','registration');
    }
    handleGAE(){
        this.fireDataLayerEvent("button", '', "contact merck", "registration_flow", 'mycontacts', '/my-contacts','account management','registration');
    }
    handlecloseevent(){
        this.fireDataLayerEvent("button", '', "back to screen_X", "modal", 'mfr_contactYourAccountManager__c', '/logout-confirmation-page/mfr-contactyouraccountmanager','other','error');
    }
    loginbtnclick(){
        this.fireDataLayerEvent("button", '', "login", "modal", 'Login', '/login','other','error');
    }
    forgotpassclick(){
        this.fireDataLayerEvent("link", '', "forgot password", "modal", 'Forgot_Password', '/ForgotPassword','other','error');
    }
    contactclick(){
        this.fireDataLayerEvent("link", '', "contact merck", "modal", 'mycontacts', '/my-contacts','other','error');
    }

    //google analytics 
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, pagetype, pagepurpose) {
        console.log('event triggered1>>>>>');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {
            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: pagetype,
                page_purpose: pagepurpose,
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
                sfmc_id: '',
                sfmc_audience: '',
                page_url: location.href,
                page_title: 'Self Registration',

            },
            bubbles: true,
            composed: true
        }));
    }
    
}