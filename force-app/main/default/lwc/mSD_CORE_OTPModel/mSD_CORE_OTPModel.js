import { LightningElement, wire, track, api } from 'lwc';

import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

import RegistrationPage from '@salesforce/resourceUrl/RegistrationPage';

import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';
import submitOTP from '@salesforce/apex/MSD_CORE_RegistrationController.submitOTP';
import mfrdomainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

export default class MSD_CORE_OTPModel extends LightningElement {

    @track siteName = '';
    @track siteApiName = '';
    @track nextbtnclass = 'nextbtncls';
    @track errormsg = false;
    @track errormsgtext = '';
    @track otpval = '';

    @api personemail;
    @api otpid;

    contactpageurl = mfrdomainurl +'/my-contacts';

    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log({ error });
        if (data) {
            this.siteName = data.siteAPINamesdebuglog;
            this.siteApiName = data.siteNames;
        }
        if (error) {
            console.log({ error });
        }
    }

    // Method Name:         renderedCallback
    // Method Use:          Used for loading external CSS file
    // Developer Name:      Ravi Modi
    // Created Date:        01 Aug 2023
    renderedCallback() {
        Promise.all([
            loadStyle(this, RegistrationPage),
        ]).then(() => {
            console.log('Files loaded');
        })
        .catch(error => {
            console.log(error.body.message);
        });
    }

    // Method Name:         handlechange
    // Method Use:          Used for getting the value on change
    // Developer Name:      Ravi Modi
    // Created Date:        01 Aug 2023
    handlechange(event) {

        this.errormsg = false;
        this.otpval = event.target.value;
        let otpcheck = contains6Char(this.otpval);
        if (otpcheck) {
            this.nextbtndisable = false;
            this.nextbtnclass = 'nextbtncls btnenablecls';
        } else {
            this.nextbtndisable = true;
            this.nextbtnclass = 'nextbtncls';
        }
    }
    handlega(){
         this.fireDataLayerEvent("link", 'step_1', "contact merck", "registration_flow", 'mycontacts', '/my-contacts');
    }
    oninputclickga(){
        this.fireDataLayerEvent("label", 'step_1', "one time password", "registration_flow", 'Register', '/SelfRegister');
    }

    showHeader() {
        this.dispatchEvent(new CustomEvent('showHeader', {
            detail: 'show',
            bubbles: true,
            composed: true
        }));
    }
    // Method Name:         requestnewotp
    // Method Use:          Used for resend otp
    // Developer Name:      Ravi Modi
    // Created Date:        01 Aug 2023
    requestnewotp() {
        const resendevt = new CustomEvent("resendemail", {
            detail: true
        });
        this.dispatchEvent(resendevt);
        this.showHeader();
        this.fireDataLayerEvent("link", 'step_1', "request new password", "registration_flow", 'Register', '/SelfRegister');
    }

    // Method Name:         submitotp
    // Method Use:          Used for checking the OTP value
    // Developer Name:      Ravi Modi
    // Created Date:        01 Aug 2023
    submitotp() {
        console.log('this.otpid-->',this.otpid);
        console.log('this.otpval-->',this.otpval);
        submitOTP({recordId:this.otpid, otpval:this.otpval})
        .then((result)=>{
            console.log('Result of submitOTP ==>',{result});
            if (result == 'Valid OTP!') {
                const clicksubmt = new CustomEvent("shownextpage", {
                    detail: true
                });
                this.dispatchEvent(clicksubmt);
                this.fireDataLayerEvent("button", 'step_2', "submit success", "registration_flow", 'Register', '/SelfRegister');
            } else if (result == 'Exiperd OTP!') {
                this.errormsg = true;
                this.errormsgtext = 'This password has expired. One-time passwords expire after 10 minutes.';
                this.fireDataLayerEvent("button", 'step_1', "submit failed", "registration_flow", 'Register', '/SelfRegister');
            } else {
                this.errormsg = true;
                this.errormsgtext = 'Incorrect password. Please refer to your email for the correct password.';
                this.fireDataLayerEvent("button", 'step_1', "submit failed", "registration_flow", 'Register', '/SelfRegister');
            }
        })
        .catch((error)=>{
            console.log('Error of submitOTP ==>',{error});
            this.errormsg = true;
        })
        // this.fireDataLayerEvent("button", 'step_1', "submit failed", "registration_flow", 'Register', '/SelfRegister');
    }

    // google analytics 
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl) {
        console.log('event triggered1>>>>>');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {
            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'account management',
                page_purpose: 'registration',
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


function contains6Char(str) {
    return /^[0-9]{6,6}$/.test(str);
}