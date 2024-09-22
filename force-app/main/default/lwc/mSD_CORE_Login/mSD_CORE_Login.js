import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';

import merckconnectlogo from '@salesforce/resourceUrl/merckconnectlogo';
import cssfile from '@salesforce/resourceUrl/librarypagecss';

import doLogin from '@salesforce/apex/CommunityAuthController.doLoginMHEE';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import getAllSiteMFRNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';       //Get All Site Value


import autoLoginKey from '@salesforce/label/c.MSD_CORE_MFR_AUTO_LOGIN_KEY';
import autoLoginValue from '@salesforce/label/c.MSD_CORE_MFR_AUTO_LOGIN_VALUE';
import autoLoginUn from '@salesforce/label/c.MSD_CORE_MFR_AUTO_LOGIN_USER_NAME';
import autoLoginPs from '@salesforce/label/c.MSD_CORE_MFR_AUTO_LOGIN_PASSWORD';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import supportcall from '@salesforce/label/c.MSD_CORE_SupportCall';
import mfrdomainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
import USER_ID from "@salesforce/user/Id";
import MSD_CORE_MedicalSettings_Url from '@salesforce/label/c.MSD_CORE_MedicalSettings_Url';

export default class MSD_CORE_Login extends NavigationMixin(LightningElement) {
    label = { autoLoginKey, autoLoginValue, autoLoginUn, autoLoginPs,supportcall };
    logo = merckconnectlogo;
    username;
    password;
    error;
    errorMessage;
    errorpopup = false;
    isUnameerrorVisible = false;
    isPWDerrorVisible = false;
    navigatedashboard;
    navigatedashboardname;
    startURL;
    contactpageurl = mfrdomainurl +'/my-contacts';

    @track siteName;
    @track siteApiName;

    @track contactrole = '';

    @track sectionstyle;
    @track authval = false;
    @track authentication = true;
    @track forgotpass = '';

    @track isAccountLocked = false;

    connectedCallback() {
        this.setFocus();

        let currentDomain = window.location.hostname;
        if (currentDomain === "www.merckformularyresources.com") {
            this.authentication = false;
        }

        // OT auto login        
        this.handleOTAutoLogin();
        sessionStorage.setItem("SFMC_ID", USER_ID);
        this.contactrole = sessionStorage.getItem("SFMC_Audience");
        this.fireOnLoadEvent();
    }

    // For getting all Sites API Name and Url MFR
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log({ data });
        console.log({ error });
        if (data) {
            this.navigatedashboardname = data.siteAPINames.Dashboard;
            this.navigatedashboard = data.siteNames.Dashboard;
            this.forgotpass = data.siteNames.forgotpassword;
        }
        if (error) {
            console.log({ error });
        }
    }

    // For getting all Sites API Name and Url
    @wire(getAllSiteMFRNameAndAPINames)
    WiredgetAllSiteMFRNameAndAPINames({ error, data }) {
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

    getvaluefrombsauth(event) {
        console.log('getvaluefrombsauth==>',event.detail);
        this.authval = event.detail;
        console.log("yes")
        
        if(this.authval) {
            this.sectionstyle = 'z-index: 10; position: absolute; top:0; right:0; left:0; bottom:0;';
        }
    }



    @wire(CurrentPageReference)
    getStateParameters(CurrentPageReference) {
        console.log({CurrentPageReference});
        if (CurrentPageReference) {
            this.startURL = CurrentPageReference.state.startURL;
            console.log('this.starturl-->',this.startURL);
        }
    }

    // FOR LOADING CSS FILE FROM STATIC RESOURCES
    renderedCallback() {

        Promise.all([
            loadStyle(this, cssfile),
        ]).then(() => {
            console.log('Files loaded!!');
        })
            .catch(error => {
                console.log(error.body.message);
            });


    }

    handleLogIn(event) {
        let curnturl = window.location.href;
        console.log('current url>>' + curnturl);
        this.errorpopup = false;
        this.username = this.template.querySelector('.uname').value;
        this.password = this.template.querySelector('.pwd').value;
        if (!this.username) {
            this.isUnameerrorVisible = true;
        }

        if (!this.password) {
            this.isPWDerrorVisible = true;
        }

        if (this.username && this.password && this.startURL) {
            event.preventDefault();
            doLogin({ username: this.username, password: this.password, startUrl: this.startURL })
                .then((result) => {
                    console.log('Result of doLogin-->',{ result });
                    if (result.startsWith('http')) {
                        this.fireDataLayerEvent('button', '', 'login success', '', 'Login', '/login');   //Event added
                        window.location.href = result;
                    
                      }else if(result == "Account Locked"){
                        var prevurl = MSD_CORE_MedicalSettings_Url;
                        console.log('prevurl');
                        window.open(prevurl, "_self");
                }
                else {
                   this.fireDataLayerEvent('button', '', 'login failed', '', 'Login', '/login');   //Event Added
                   console.log('ELSE');

               }
                })
                .catch((error) => {
                    console.log('error' + JSON.stringify(error));
                    this.error = error;
                    this.errorpopup = true;
                    this.errorMessage = error.body.message;
                });

        }
        else if (this.username && this.password) {
            event.preventDefault();
            this.handleApexLogin();
        }
    }
    // Handle OT auto login
    handleOTAutoLogin() {
        const queryParamPath = window.location.search;
        if (queryParamPath) {
            const urlParams = new URLSearchParams(queryParamPath);
            if (urlParams && urlParams.get(this.label.autoLoginKey) && urlParams.get(this.label.autoLoginKey) === this.label.autoLoginValue) {
                this.username = this.label.autoLoginUn;
                this.password = this.label.autoLoginPs;
                this.handleApexLogin();
            }

        }
    }
    // Validate user credentials in the backend
    handleApexLogin() {
        doLogin({ username: this.username, password: this.password })
            .then((result) => {
                console.log({ result });
                if (result.startsWith('http')) {
                    this.fireDataLayerEvent('button', '', 'login success', '', 'Login', '/login');   //Event Added
                    window.location.href = result;
                } else {
                    console.log('ELSE');
                }
            })
            .catch((error) => {
                this.fireDataLayerEvent('button', '', 'login failed', '', 'Login', '/login');    //Event Added
                console.log('error' + JSON.stringify(error));
                this.error = error;
                this.errorpopup = true;
                this.errorMessage = error.body.message;
            });
    }

    hideModalBox() {
        this.errorpopup = false;
    }
    reditectToHomePage() {
        if (this.navigatedashboardname != undefined && this.navigatedashboard != undefined) {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: this.navigatedashboardname,
                    url: this.navigatedashboard
                }
            });
        }

    }
    
    /* handleHavingTrouble(event) {
         this[NavigationMixin.Navigate]({
             type: 'comm__namedPage',
             attributes: {
                 name: 'Forgot_Password'
             }
         });
 
     }*/
    handleUserNameChange(event) {

        this.errorpopup = false;
        if (event.target.value != '') {
            this.isUnameerrorVisible = false;
        } else {
            this.isUnameerrorVisible = true;
        }
        this.username = event.target.value;
    }

    handlePasswordChange(event) {
        this.errorpopup = false;
        if (event.target.value != '') {
            this.isPWDerrorVisible = false;
        } else {
            this.isPWDerrorVisible = true;
        }
        this.password = event.target.value;
    }

    setFocus() {
        window.setTimeout(() => {
            const firstInput = this.template.querySelector('[data-id="username"]');
            if (firstInput) firstInput.focus();
        }, 0);
    }


    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'login',
                page_purpose: 'login',
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
                page_title: 'login',

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
                page_type: 'login',
                page_purpose: 'login',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'Login',
                link_url: '/login',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'login',
            },
            bubbles: true,
            composed: true
        }));
    }
}