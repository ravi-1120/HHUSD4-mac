/**
 * Auther:              Ravi Modi (Focal CXM)
 * Component Name:      mSD_CORE_ForgotPassword
 * Description:         Used for reset password
 * Used in:             MFR/MHEE Portal Forgot password page
 * Created Date:        05th July 2023
 * Lastmodified Date:   07th July 2023
 */

import { LightningElement, track, wire } from 'lwc';
import USER_ID from "@salesforce/user/Id";
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import jobcode from '@salesforce/label/c.nonbrandjobcode';
// Static Resource
import merckconnectlogo from '@salesforce/resourceUrl/merckconnectlogo';
import forgotpasswordpage from '@salesforce/resourceUrl/forgotpasswordpage';

// Apex Class
import forgotPassword from '@salesforce/apex/CommunityAuthController.forgotPassword';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import mfrdomainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

export default class MSD_CORE_ForgotPassword extends LightningElement {
    
    domain = mfrdomainurl +'/my-contacts';
    @track emailVal = '';
    @track emailerrormsg = false;
    @track errormsgtext = '';
    @track confirmpage = false;
    @track siteName = '';
    @track siteApiName = '';
    @track contactrole = ''; 
    mercklogo = merckconnectlogo;
    label = {jobcode};
    
    handleEmailValidation() {
        try {
            var flag = true;
            const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
            let email = this.template.querySelector('[data-id="txtEmailAddress"]');
            this.emailVal = email.value;
            if (this.emailVal) {
                if (this.emailVal.match(emailRegex)) {
                    this.emailerrormsg = false;
                    this.errormsgtext = '';
                } else {
                    flag = false;
                    this.emailerrormsg = true;
                    this.errormsgtext = 'Please enter a valid email address';
                }
                email.reportValidity();
            }
            return flag;
        } catch (error) {
            console.log('Error in handle Email Validation-->',{error});
        }

    }
    
    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        console.log({ value });
        const { data, error } = value;
        if (data) {
            console.log({ data });
            this.contactrole = data;
        }
        if (error) {
            console.log({ error });
        }
    }  
    
    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log({ data });
        console.log({ error });
        if (data) {
            this.siteName = data.siteAPINamesdebuglog;
            this.siteApiName = data.siteNames;
        }
        if (error) {
            console.log({ error });
        }
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, forgotpasswordpage)
        ]).then(() => {
            console.log('CSS Loaded');
        })
        .catch(error => {
            console.log('Error in loading CSS-->',{error});
        });
        this.fireOnLoadEvent();
    }

    handleOnclick() {
        try {
            if (this.handleEmailValidation()) {
                if (this.emailVal) {
                    this.userResetPassword();
                } else {
                    this.emailerrormsg = true;
                    this.errormsgtext = 'Please enter a valid email address';
                }
            } else {
                this.emailerrormsg = true;
                this.errormsgtext = 'Please enter a valid email address';
            }
        } catch (error) {
            console.log('Error On HandleClick-->',{error});
        }
        this.fireDataLayerEvent("button", '', "reset", "password_flow", 'Forgot_Password', '/ForgotPassword');
    }

    userResetPassword() {
        this.fireDataLayerEvent("link", '', "new link", "password_flow", 'Forgot_Password', '/ForgotPassword');

        forgotPassword({useremail: this.emailVal})
        .then((result) => {
            console.log('result of resetPassword-->',{result});
            if (result != 'Reset Password Link Sent successfully!') {
                this.emailerrormsg = true;
                this.errormsgtext = 'Please enter a valid email address';
            } else {
                this.emailerrormsg = false;
                this.errormsgtext = '';
                this.confirmpage = true;
            }
        })
        .catch((error) => {
            console.log('error of resetPassword-->',{error});
            this.emailerrormsg = true;
        })
    }

    handlegaevent(event){
        let labelname = event.currentTarget.dataset.name;
        if(labelname == 'email'){
           this.fireDataLayerEvent("label", '', "email", "password_flow", 'Forgot_Password', '/ForgotPassword');
        }else if(labelname == 'contact'){
           this.fireDataLayerEvent("link", '', "contact", "password_flow", 'mycontacts__c', '/my-contacts');
        //    window.open(this.domain);
        }else if(labelname == 'contactreset'){
           this.fireDataLayerEvent("link", '', "contact", "password_flow", 'mycontacts__c', '/my-contacts');
        }  
        
    }

    //google analytics 
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'login',
                page_purpose: 'forgot password',
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
                page_title: 'Forgot Password',

            },
            bubbles: true,
            composed: true
        }));
    }

    fireOnLoadEvent() {
        console.log('EVENT TRIGGERED');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                data_design_category: '',
                data_design_action: '',
                data_design_label: '',
                data_design_module: '',
                page_type: 'login',
                page_purpose: 'forgot password',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'Forgot_Password',
                link_url: '/ForgotPassword',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                content_count: '',
                sfmc_id: '',
                sfmc_audience: '',
                page_url: location.href,
                page_title: 'Forgot Password',
            },
            bubbles: true,
            composed: true
        }));
    }
}