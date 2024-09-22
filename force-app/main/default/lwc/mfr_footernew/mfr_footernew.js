import { LightningElement, wire, api, track } from 'lwc';
import newlogo from '@salesforce/resourceUrl/footerlogonew';
import { NavigationMixin } from 'lightning/navigation';
import ftlogo1 from '@salesforce/resourceUrl/image';
import ftlogo2 from '@salesforce/resourceUrl/truste';
import ftlogo3 from '@salesforce/resourceUrl/truste2';
import jobcode from '@salesforce/label/c.nonbrandjobcode';
import { CurrentPageReference } from 'lightning/navigation';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import getAppointmentDetails from '@salesforce/apex/MSD_CORE_ProductList.getAppointmentDetails';
import getProducts from '@salesforce/apex/MSD_CORE_ProductList.getProducts';
import getCatalogRecord from '@salesforce/apex/MSD_CORE_ProductList.getCatalogRecord';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
/*import CopyRights from '@salesforce/label/c.mfr_CopyRights';
import CopyRights1 from '@salesforce/label/c.mfr_CopyRights1';*/
import USER_ID from "@salesforce/user/Id";
export default class Mfr_footernew extends NavigationMixin(LightningElement) {
    //label={CopyRights,CopyRights1};

    label = { jobcode };
    @track contactrole = '';
    @track yyyy;
    @track organiccomp = false;
    @track newfooter = true;
    logo1 = newlogo;
    ftlogo1 = ftlogo1;
    ftlogo2 = ftlogo2;
    ftlogo3 = ftlogo3;
    domainurl = domainurl;
    navigateothermercksites;
    navigateothermercksitesname;
    navigateContacts;
    navigateContactsname;
    productid;
    jobcode;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('IIIII');
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            console.log('urlStateParameters' + JSON.stringify(this.urlStateParameters));
            this.recId = this.urlStateParameters.recordId;
            this.productid = this.urlStateParameters.prodid;
        }
    }
    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        console.log({ value });
        const { data, error } = value;
        if (data) {
            console.log({ data });
            this.contactrole = data;
            console.log('raviteja>>>>>', data);
        }
        if (error) {
            console.log({ error });
        }
    }

    connectedCallback() {
        var today = new Date();
        this.yyyy = today.getFullYear();
        this.getcontactnames();
        this.getothermercksitenames();

        getAppointmentDetails({ appointmentID: this.recId }).then(result => {
            this.appointmentData = result;
            console.log({ result });
            this.jobcode = result[0].MSD_CORE_Product_Payor__r?.MSD_CORE_Job_code__c;
        }
        ).catch(error => {

            this.error = error;
        });

        getProducts({ prodId: this.recId }).then(result => {
            console.log({ result });
            this.jobcode = result[0].MSD_CORE_Job_code__c;
        }
        ).catch(error => {

            this.error = error;
        });

        getCatalogRecord({ recId: this.recId, userId: USER_ID })
            .then(result => {
                console.log({ result });
                if (result) {
                    this.jobcode = result.MSD_CORE_Product_Payor__r?.MSD_CORE_Job_code__c;
                }
            });
        console.log('non brand' + this.label.jobcode);
        if (!this.jobcode) {
            this.jobcode = this.label.jobcode;
        }

        const currenweltUrl = window.location.href.split("/").join("");
        if(currenweltUrl.includes('welcomepage') || currenweltUrl.includes('organic-login') || currenweltUrl.includes('organic') || currenweltUrl === this.domainurl.split("/").join("")){
              this.organiccomp = true;        
        }

        const currenweltUrl1 = window.location.href.split("/").join("");
        if(currenweltUrl1.includes('organic-attestation') || currenweltUrl1.includes('organic-signup') || currenweltUrl1.includes('organic-thank-you') || currenweltUrl1.includes('organic-verify-email') || currenweltUrl1.includes('organic-create-password') || currenweltUrl1.includes('organic-consultancy-information')){
              this.newfooter = false;       
              console.log('newfooter>>' + this.newfooter); 
        }


    }
    getcontactnames() {
        getSiteNameAndAPIName({ pageName: 'MyContacts' })
            .then((result) => {
                console.log({ result });
                this.navigateContacts = result.siteAPIName;
                this.navigateContactsname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }
    getothermercksitenames() {
        getSiteNameAndAPIName({ pageName: 'othermercksites' })
            .then((result) => {
                console.log({ result });
                this.navigateothermercksites = result.siteAPIName;
                this.navigateothermercksitesname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }


    redirectTermsofUse(event) {
        var labeluse = event.currentTarget.dataset.value;
        window.open('https://www.merck.com/terms-of-use/', '_blank').focus();
        this.fireDataLayerEvent('link', '', labeluse, 'footer', labeluse, 'https://www.merck.com/terms-of-use/', ''); //RT GA bug
    }
    accessibility(event) {
        var labeluse = event.currentTarget.dataset.value;
        window.open(' https://www.msdaccessibility.com/', '_blank').focus();
        this.fireDataLayerEvent('link', '', labeluse, 'footer', labeluse, 'https://www.msdaccessibility.com/', '');//RT GA bug
    }
    privacyPolicy(event) {
        var labeluse = event.currentTarget.dataset.value;
        window.open(' https://www.msdprivacy.com/us/en/', '_blank').focus();
        this.fireDataLayerEvent('link', '', labeluse, 'footer', labeluse, 'https://www.msdprivacy.com/us/en/', '');//RT GA bug
    }
    myContacts(event) {
        var labeluse = event.currentTarget.dataset.value;
        this[NavigationMixin.Navigate]({
            // type: 'comm__namedPage',
            type: 'standard__webPage',
            attributes: {
                name: this.navigateContactsname,
                url: this.navigateContacts
            },
        });
        this.fireDataLayerEvent('link', '', labeluse, 'footer', this.navigateContactsname, this.navigateContacts, '');//RT GA bug
    }
    Additional(event) {
        var labeluse = event.currentTarget.dataset.value;
        this[NavigationMixin.Navigate]({
            // type: 'comm__namedPage',
            type: 'standard__webPage',
            attributes: {
                name: this.navigateothermercksitesname,
                url: this.navigateothermercksites
            },
        });
        this.fireDataLayerEvent('link', '', labeluse, 'footer', this.navigateothermercksitesname, this.navigateothermercksites, '');//RT GA bug
    }
    CookiePreferences(event) {
        var labeluse = event.currentTarget.dataset.value;
        this.fireDataLayerEvent('link', '', labeluse, 'footer', 'Home', '/merckportal/', '');//RT GA bug
    }
    Accesibilityicon(event) {
        var labeluse = event.currentTarget.dataset.value;
        this.fireDataLayerEvent('button', '', labeluse, 'footer', 'Home', '/merckportal/', '');//RT GA bug
    }
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