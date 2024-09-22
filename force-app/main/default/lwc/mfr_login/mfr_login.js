import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import doLogin from '@salesforce/apex/CommunityAuthController.doLogin';

import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';       //Get All Site Value
import merckconnectlogo from '@salesforce/resourceUrl/merckconnectlogo';

import { loadStyle } from 'lightning/platformResourceLoader';
import cssfile from '@salesforce/resourceUrl/librarypagecss';

import autoLoginKey from '@salesforce/label/c.MSD_CORE_MFR_AUTO_LOGIN_KEY';
import autoLoginValue from '@salesforce/label/c.MSD_CORE_MFR_AUTO_LOGIN_VALUE';
import autoLoginUn from '@salesforce/label/c.MSD_CORE_MFR_AUTO_LOGIN_USER_NAME';
import autoLoginPs from '@salesforce/label/c.MSD_CORE_MFR_AUTO_LOGIN_PASSWORD';
import jobcode from '@salesforce/label/c.nonbrandjobcode';
import supportcall from '@salesforce/label/c.MSD_CORE_SupportCall';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import USER_ID from "@salesforce/user/Id";

export default class Mfr_login extends NavigationMixin(LightningElement) {

    label = { autoLoginKey, autoLoginValue, autoLoginUn, autoLoginPs, jobcode, supportcall };
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

    @track siteName;
    @track siteApiName;

    @track sectionstyle;
    @track authval = false;

    @track contactrole = '';
    @track authentication = true;
    @track forgotpass = '';

    connectedCallback() {
        let currentDomain = window.location.hostname;
        // let currentDomain ="msdlogin--d2fclmerge.sandbox.my.site.com";
        console.log('currentDomain-->' + currentDomain);
        // this.sectionstyle = 'pointer-events:none; cursor:none;';
        if (currentDomain === "www.merckformularyresources.com") {
            this.authentication = false;

        }
        // sessionStorage.setItem("SFMC_ID",USER_ID );

        // this.setFocus();

        // Ontrust auto login
        console.log('mfr login connectedCallback');

        this.fireOnLoadEvent();

        this.handleOTAutoLogin();
        console.log('userid>>>1', USER_ID);
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
        console.log('contactrole>>', this.contactrole);
        console.log('userid>>>', USER_ID);
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


    @wire(getSiteNameAndAPIName, { pageName: 'Dashboard' })
    wiredgetSiteNameAndAPIName(value) {
        console.log('Wired Count');
        console.log(value);
        const { data, error } = value;
        if (data) {
            console.log('apiname' + data.siteAPIName)
            this.navigatedashboard = data.siteAPIName;
            this.navigatedashboardname = data.siteName;
        } else if (error) {
            this.error = error;
            console.log('error in getSiteNameAndAPIName ' + JSON.stringify(this.error));
        }
    }

    @wire(getSiteNameAndAPIName, { pageName: 'forgotpassword' })
    wiredgetSiteNameAndAPIName(value) {
        console.log('value>>>', value);
        const { data, error } = value;
        if (data) {
            this.forgotpass = data.siteAPIName;
        } else if (error) {
            console.log('error>>', error);
            this.error = error;
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(CurrentPageReference) {
        console.log({ CurrentPageReference });
        if (CurrentPageReference) {
            this.startURL = CurrentPageReference.state.startURL;
            console.log('this.starturl-->', this.startURL);
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

        // console.log('In Rendered Callback');
        // if(this.authval) {
        //     this.sectionstyle = 'pointer-events:auto;';
        // } else {
        //     this.sectionstyle = 'pointer-events:none;';
        // }
    }

    getvaluefrombsauth(event) {
        console.log('getvaluefrombsauth==>', event.detail);
        this.authval = event.detail;
        console.log("yes")

        if (this.authval) {
            this.sectionstyle = 'z-index: 10; position: absolute; top:0; right:0; left:0; bottom:0;';
            // } else {
            //     this.sectionstyle = 'cursor: none;';
        }
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
        console.log(this.username + ' ' + this.password + ' ' + this.startURL);
        if (this.username && this.password && this.startURL) {
            event.preventDefault();
            doLogin({ username: this.username, password: this.password, startURLval: this.startURL })
                .then((result) => {
                    console.log({ result });
                    if (result.startsWith('http')) {
                        this.fireDataLayerEvent('button', '', 'login success', '', 'homepage', '/');
                        window.location.href = result;
                    } else {
                        console.log('ELSE');
                    }
                })
                .catch((error) => {
                    this.fireDataLayerEvent('button', '', 'login failed', '', 'login', '/login');
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
        console.log('queryParamPath ' + queryParamPath);
        if (queryParamPath) {
            const urlParams = new URLSearchParams(queryParamPath);
            console.log('urlParams ' + urlParams);
            console.log('urlParams ' + urlParams.get('ec'));
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
                    this.fireDataLayerEvent('button', '', 'login success', '', 'homepage', '/');
                    window.location.href = result;
                } else {
                    console.log('ELSE');
                }
            })
            .catch((error) => {
                this.fireDataLayerEvent('button', '', 'login failed', '', 'login', '/login');
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
                // type: 'comm__namedPage',
                type: 'standard__webPage',
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

     handlegaevent(event){
        let inputtype = event.currentTarget.dataset.id;
        console.log('inputtype>>' , inputtype);
        if (inputtype == 'username'){
            this.fireDataLayerEvent('label', '', 'email', '', 'Login', '/login');
        }
        if (inputtype == 'forgotpasslink'){
            this.fireDataLayerEvent('link', '', 'forgot password', '', 'Forgot_Password', '/ForgotPassword');
        }
        if (inputtype == 'contactmerck'){
            this.fireDataLayerEvent('link', '', 'contact', '', 'mycontacts__c', '/my-contacts');
        }
        else if (inputtype == 'Password'){
            console.log('inputtypeentered' , inputtype);
            this.fireDataLayerEvent('label', '', 'password', '', 'Login', '/login');
        }
        
    }

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
        // window.setTimeout(() => {
        const firstInput = this.template.querySelector('[data-id="username"]');
        if (firstInput) firstInput.focus();
        // }, 0);
    }
    //event
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayerevent', {

            detail: {
                // event_category: category,
                // event_action: action,
                // event_label: label,
                // page_type: 'login',
                // page_purpose:'login',
                // page_audience: 'payor',
                // page_marketname: 'united_states',
                // page_region: 'us',
                // page_contentclassification: 'non-commercial'
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
                sfmc_id: '',
                sfmc_audience: '',
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
                sfmc_id: '',
                sfmc_audience: '',
                page_url: location.href,
                page_title: 'login',
            },
            bubbles: true,
            composed: true
        }));
    }
}