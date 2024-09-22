import { LightningElement, wire, api, track } from 'lwc';
import newlogo from '@salesforce/resourceUrl/MerckLogoblack';
import { NavigationMixin } from 'lightning/navigation';
import ftlogo1 from '@salesforce/resourceUrl/image';
import ftlogo2 from '@salesforce/resourceUrl/truste';
import ftlogo3 from '@salesforce/resourceUrl/truste2';

import TermsOfUse from '@salesforce/label/c.MSD_CORE_MHEE_Terms';
import Trustee from '@salesforce/label/c.MSD_CORE_MHEE_Trustee';
import ApecPrivacy from '@salesforce/label/c.MSD_CORE_MHEE_Apec_Privacy';
import Privacy from '@salesforce/label/c.MSD_CORE_MHEE_Privacy';
import Accessibility from '@salesforce/label/c.MSD_CORE_MHEE_Accessibility';
import termsofuse from '@salesforce/label/c.MSD_CORE_MHEE_TermsOfUse';
import privacypolicy from '@salesforce/label/c.MSD_CORE_MHEE_PrivacyPolicy';
import cookiepreference from '@salesforce/label/c.MSD_CORE_MHEE_CookiePreference';
import accessibilitytxt from '@salesforce/label/c.MSD_CORE_MHEE_AccessibilityText';
import additionalmerck from '@salesforce/label/c.MSD_CORE_MHEE_AdditionalMerck';

import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import USER_ID from "@salesforce/user/Id"; 
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
export default class MSD_CORE_Footer extends NavigationMixin(LightningElement) {

    @track yyyy;
    logo1 = newlogo;
    ftlogo1 = ftlogo1;
    ftlogo2 = ftlogo2;
    ftlogo3 = ftlogo3;
    @track products = [];
    @track contactrole = '';
    @track siteAPINames;
    @track siteNames;

    label = {
        termsofuse,
        privacypolicy,
        cookiepreference,
        accessibilitytxt,
        additionalmerck,
    }

    connectedCallback() {
        var today = new Date();
        this.yyyy = today.getFullYear();
    }

    redirectTermsofUse(event) {
        window.open(TermsOfUse, '_blank').focus();
        let term = event.currentTarget.dataset.value;
        this.fireDataLayerEvent('link', '', term, 'footer', 'Home', '/merckmhee/', '');//RT GA 1122
    }


    accessibility() {
        window.open(Accessibility, '_blank').focus();
        let term = event.currentTarget.dataset.value;
        this.fireDataLayerEvent('link', '', term, 'footer', 'Home', '/merckmhee/', '');//RT GA 1122
    }

    verifyTrustee() {
        window.open(Trustee, '_blank').focus();
    }

    apecPriviacy() {
        window.open(ApecPrivacy, '_blank').focus();
    }

    privacyPolicy(event) { 
        window.open(Privacy, '_blank').focus(); 
        let term = event.currentTarget.dataset.value;
        this.fireDataLayerEvent('link', '', term, 'footer', 'Home', '/merckmhee/', '');//RT GA 1122
    }
    cookiepref(event){
        let term = event.currentTarget.dataset.value;
        this.fireDataLayerEvent('link', '', term, 'footer', 'Home', '/merckmhee/', '');//RT GA 1122
    }
    imageclick(){
        this.fireDataLayerEvent('button', '',"accessibility icon", 'footer', 'Home', '/merckmhee/', '');//RT GA 1122   
    }

    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({error, data}) {
        console.log({data});
        console.log({error});
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
        }
        if (error) {
            console.log({error});
        } 
    }    
    @wire(getContactRole, { userId:USER_ID })
    wiredgetContactRole(value) {
        console.log({value});
        const { data, error } = value;
        if(data) {
            console.log({data});
            this.contactrole = data;
            console.log('raviteja>>>>>',data);
        }
        if(error) {
            console.log({error});
        }
    }

    Additional(event) {

        this[NavigationMixin.Navigate]({
            //type: 'comm__namedPage',
            type:'standard__webPage',
            attributes: {
                name: this.siteAPINames.othermercksite,
                url: this.siteNames.othermercksite
            },
        });
        let term = event.currentTarget.dataset.value;
        this.fireDataLayerEvent('link', '', term, 'footer', 'Home', '/merckmhee/', '');//RT GA 1122
    }

    // Google Analytics
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, productname) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'homepage',
                page_purpose: 'homepage',
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
                page_localproductname: productname,
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'dashboard',

            },
            bubbles: true,
            composed: true
        }));
    }
}