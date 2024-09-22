import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import getLicenses from '@salesforce/apex/MSD_CORE_ProductList.getLicenses';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import USER_ID from "@salesforce/user/Id";
import communityPath from '@salesforce/community/basePath';
import banner_img from '@salesforce/resourceUrl/banner';
import prescribinginfo from '@salesforce/resourceUrl/prescribinginfo';
import mediguide from '@salesforce/label/c.MSD_CORE_MedicationGuide';        //Label for Medical Guide
import patientinfo from '@salesforce/label/c.MSD_CORE_PatientInformation';   //Label for Patient Information
import preinfo from '@salesforce/label/c.MSD_CORE_PrescribingInformation';   //Label for Prescribing Information
import prodlabel from '@salesforce/label/c.MSD_CORE_Product';                //Label for Prescribing Information
import prodsublabel from '@salesforce/label/c.MSD_CORE_Product_Subheader';   //Label for Prescribing Information
import arrow from '@salesforce/resourceUrl/rightarrow2';
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import getEligibilityRecords from '@salesforce/apex/MSD_CORE_SettingsController.getEligibilityRecords';
import { loadStyle } from 'lightning/platformResourceLoader';
import settingscss from '@salesforce/resourceUrl/settingscss';
import { refreshApex } from '@salesforce/apex';
import CloseIconImage from '@salesforce/resourceUrl/cancelicon';
import getAccountLockStatus from '@salesforce/apex/MSD_CORE_RedirectController.getAccountLockStatus';
import DROPDOWN from '@salesforce/resourceUrl/Dropdown';
import getPayorNotificationsData from '@salesforce/apex/MSD_CORE_SettingsController.getPayorNotificationsData';
import getPriorDaysExpireList from '@salesforce/apex/MSD_CORE_SettingsController.getPriorDaysExpireList';
import updateNotificationSetting from '@salesforce/apex/MSD_CORE_SettingsController.updateNotificationSetting';

import alertcircle from '@salesforce/resourceUrl/MSD_CORE_Alert_circle';
import whitecross from '@salesforce/resourceUrl/MSD_CORE_White_Cross';

// import updatepassword from '@salesforce/label/MSD_CORE_UpdatePasswordSubHead';

const FIELDS = [
    'Contact.Name',
    'Contact.Title',
    'Contact.Phone',
    'Contact.MSD_CORE_Role__c',
    'Contact.MSD_CORE_P_T_process__c',
    'Contact.MSD_CORE_Organization_type__c	',
    'Contact.MSD_CORE_Title__c',
    'Contact.MSD_CORE_Organization_name__c',
    'Contact.MSD_CORE_Professional_organization_mail__c',
    'Contact.MSD_CORE_Country__c',
    'Contact.MSD_CORE_State__c',
    'Contact.MSD_CORE_City__c',
    'Contact.Department',
];

export default class Settings extends NavigationMixin(LightningElement) {

    @track btnstyle;
    @track value = 'Account information';
    
    @track tabsetOptions = [
        { label: 'Account information', value: 'Account information' },
        { label: 'Eligibility information', value: 'Eligibility information' },
        { label: 'Notifications', value: 'Notifications' }
    ];

    @track consultantblock = false;
    @track PTblock = false;
    @track otherblock = false;
    @track licenses = false;
    @track tab1Bool = true;
    @track tab2Bool = false;
    @track tab3Bool = false;
    @track tab1CSS = 'slds-tabs_default__item slds-is-active';
    @track tab2CSS = 'slds-tabs_default__item';
    @track tab3CSS = 'slds-tabs_default__item';
    @track editcomponent = false;
    @api userId;
    @track eligibilityRecords;
    products; //Product Data
    error; // Error Message
    prodId; //Selected Product Id
    roleId;
    presinfo = prescribinginfo;
    banner = banner_img;
    norecord = false;
    sidearrow = arrow;
    settingscss = settingscss;
    navigatedashboard;
    @track tabVal;
    @track isshowmodal = true;
    @track isUpdatePassword = false;
    @track hedi = 'Update password';
    @track subhed = true;
    @track pageName = 'SettingPage';
    @track updatesettingpage = true;
    CloseIcon = CloseIconImage;
    @track maineligibility;
    urlStateParameters;
    @track isAccountLocked = false;

    @track showpersonaleditpage = false;

    reviewLabelStyle = '';
    accLockCss = '';
    @track accbtndisable = false;
    @track accemailbtn = 'accemail'
    @track updatpass = 'updatebtn';

    label = {
        mediguide,
        patientinfo,
        preinfo,
        prodlabel,
        prodsublabel
    }

    @track licenses = [];
    @track contactrole = '';

    @track showtoast = false;
    alertimg = alertcircle;
    crossimg = whitecross;

    /* Initiating Variables for Updating Email Address */
    @track isUpdateEmail = false;
    @track emailPage = false;
    @track userEmailAddress = '';
    @track updateEmailSettingPage = true;
    /* Closing Loop for Updating Email Address Variables*/

    //Notification Page Varialbles
    priorDaysExpireList = [];
    notificationData;

    onUpdatePassword() {
        this.isshowmodal = false;
        this.isUpdateEmail = false;
        this.dispatchEvent(new CustomEvent('footerRemove', {
            detail: 'remove',
            bubbles: true,
            composed: true
        }));
        this.isUpdatePassword = true;
        this.fireDataClickEvent("button", '', 'update password', '', 'settings__c', '/settings');
    }

    updateEmail() {
        this.isshowmodal = false;
        this.isUpdatePassword = false;
        this.dispatchEvent(new CustomEvent('footerRemove', {
            detail: 'remove',
            bubbles: true,
            composed: true
        }));
        this.updateEmailSettingPage = true;
        this.isUpdateEmail = true;
        this.fireDataClickEvent("button", '', 'update email', '', 'settings__c', '/settings');
    }

    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    user;

    get contactId() {
        return getFieldValue(this.user.data, CONTACT_ID);
    }

    connectedCallback() {
        this.fireOnLoadEvent();
        if (this.urlStateParameters.tab) {
            this.setTabVisibility(this.urlStateParameters.tab);
        }
        loadStyle(this, DROPDOWN)
                .then(() => {
                    console.log('Styles loaded successfully');
                })
                .catch(error => {
                    console.error('Error loading styles', error);
                });
        getPriorDaysExpireList()
            .then(result => {
                this.priorDaysExpireList = result;
            });

        this.getPayorNotificationsData();
    }

    getPayorNotificationsData() {
        getPayorNotificationsData()
        .then(result => {
            this.notificationData = result;
        });
    }

    @wire(getRecord, { recordId: '$contactId', fields: FIELDS })
    contact;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
        }
    }

    @wire(getSiteNameAndAPIName, { pageName: 'Dashboard' })
    wiredgetSiteNameAndAPIName(value) {
        const { data, error } = value;
        if (data) {
            this.navigatedashboard = data.siteAPIName;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        const { data, error } = value;
        if (data) {
            this.contactrole = data;
        }
        if (error) {
            console.log({ error });
        }
    }

    @wire(getEligibilityRecords, { userId: USER_ID })
    wiredEligibilityRecords(value) {
        const { data, error } = value;
        this.maineligibility = value;
        if (data) {
            this.eligibilityRecords = data;

            if (this.eligibilityRecords.showRed == true) {
                this.reviewLabelStyle = 'reviewLabelStyle bgRed';
                this.accLockCss = 'tagtwocls txtColorRed';
                this.btnstyle = 'btnclsgreen';
            } else {
                this.reviewLabelStyle = 'reviewLabelStyle bgGreen';
                this.accLockCss = 'tagtwocls';
                this.btnstyle = 'btncls';
            }


            if (this.eligibilityRecords.role == 'Consultant') {
                this.consultantblock = true;
                this.PTblock = false;
                this.otherblock = false;
            }
            if (!(this.eligibilityRecords.role == 'Other' || this.eligibilityRecords.role == 'Consultant')) {
                this.otherblock = false;
                this.consultantblock = false;
                this.PTblock = true;
            }
            else if (this.eligibilityRecords.role == 'Other') {
                this.PTblock = false;
                this.otherblock = true;
                this.consultantblock = false;
            }
        }
        if (error) {
            console.log('Error fetching records:', error);
            this.error = error;
        }
    }

    get isActiveTab1() {
        return this.value === 'Account information';
    }

    get isActiveTab2() {
        return this.value === 'Eligibility information';
    }


    @wire(getAccountLockStatus, { userId: USER_ID })
    wiredgetAccountLockStatus(value) {
        const { data, error } = value;
        if (data) {
            this.data = data;
            if (this.data.accountStatus == 'Locked') {
                this.isAccountLocked = true;
            }
        }
        else if (error) {
            console.log(error);
        }
    }


    showPersonal() {
        this.accbtndisable = true;
        this.showpersonaleditpage = true;
        this.accemailbtn = 'accemail btndisablecss';
        this.updatpass = 'updatebtn btndisablecss';
        this.fireDataClickEvent("button", '', 'edit', '', 'settings__c', '/settings');
    }

    hideEditPersonal(event) {

        if (event.detail == 'success') {
            this.showtoast = true;
            setTimeout(() => {
                this.showtoast = false;
            }, 8000);
        }
        this.accbtndisable = false;
        this.showpersonaleditpage = false;
        this.accemailbtn = 'accemail';
        this.updatpass = 'updatebtn';
        return refreshApex(this.maineligibility);
    }

    closeclick() {
        this.showtoast = false;
    }

    handlePickListChange(event) {
        this.value = event.detail.value;
        
        if (this.value == 'Eligibility information') {
            this.tab2Bool = true;
            this.tab1Bool = false;
            this.tab3Bool = false;
        } else if (this.value == 'Account information') {
            this.tab2Bool = false;
            this.tab1Bool = true;
            this.tab3Bool = false;
        }
        else if (this.value == 'Notifications') {
            this.tab2Bool = false;
            this.tab3Bool = true;
            this.tab1Bool = false;
        }

        this.hideEditPersonal('');
    }

    renderedCallback() {
        Promise.all([loadStyle(this, settingscss)]).
            then(() => {
            })
            .catch(error => {
                console.log(error.body.message);
            });
    }

    handleTabClick(event) {
        if (event.currentTarget.dataset.id != undefined) {
            let tabName = event.currentTarget.dataset.id
            this.hideEditPersonal('');
            this.setTabVisibility(tabName);
        }
        var tabname = event.currentTarget.dataset.name;
    }

    setTabVisibility(tabName) {
        switch (tabName) {
            case '1':
                this.tab1Bool = true;
                this.tab2Bool = false;
                this.tab3Bool = false;
                this.tab1CSS = 'slds-tabs_default__item slds-is-active';
                this.tab2CSS = 'slds-tabs_default__item';
                this.tab3CSS = 'slds-tabs_default__item';
                this.fireDataClickEvent("content_switcher", '', 'Account information', '', 'settings__c', '/settings');
                break;
            case '2':
                this.tab1Bool = false;
                this.tab2Bool = true;
                this.tab3Bool = false;
                this.tab1CSS = 'slds-tabs_default__item';
                this.tab2CSS = 'slds-tabs_default__item slds-is-active';
                this.tab3CSS = 'slds-tabs_default__item';
                this.fireDataClickEvent("content_switcher", '', 'Eligibility information', '', 'settings__c', '/settings');
                break;
            case '3':
                this.tab1Bool = false;
                this.tab2Bool = false;
                this.tab3Bool = true;
                this.tab1CSS = 'slds-tabs_default__item';
                this.tab2CSS = 'slds-tabs_default__item';
                this.tab3CSS = 'slds-tabs_default__item slds-is-active';
                this.fireDataClickEvent("content_switcher", '', 'Notifications', '', 'settings__c', '/settings');
                this.getPayorNotificationsData();
                break;
        }
    }

    handleConfirm() {
        this.editcomponent = true;
        this.fireDataClickEvent("button", '', 'confirm eligibility', '', 'settings__c', '/settings');
    }

    handleCancelConfirmEligibility() {
        this.editcomponent = false;
        return refreshApex(this.maineligibility);
    }

    handlerOnclickProduct(event) {
        this.prodId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'productdetail__c',
                url: '/s/product/productdetail' + '?recordId=' + this.prodId
            }
        });
    }

    navigateToNewRecordPage(url) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    handleCloseValue() {
        this.isshowmodal = true;
        this.isUpdatePassword = false;
        this.isUpdateEmail = false;
    }

    handlenavigatedashboard() {
        this.fireDataClickEvent("top_nav_breadcrumb", '', 'Dashboard', 'navigation', 'Dashboard__c', '/dashboard');
    }

    sitelogout(event) {
        if (window.performance) {
            console.info("window.performance works fine on this browser");
        }
        console.info(performance.navigation.type);
        if (performance.navigation.type == performance.navigation.TYPE_RELOAD) {
            this.url = communityPath + '/secur/logout.jsp?retUrl=%2Flogin';
            window.location.replace(this.url);
        }
    }

    fireDataClickEvent(category, action, label, module, linkedtext, linkedurl) {
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'account management',
                page_purpose: 'account management',
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
                page_title: 'settings',

            },
            bubbles: true,
            composed: true
        }));
    }

    //Google Analytics Event
    fireOnLoadEvent() {
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                data_design_category: '',
                data_design_action: '',
                data_design_label: '',
                data_design_module: '',
                page_type: 'account management',
                page_purpose: 'account management',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'settings__c',
                link_url: '/settings',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'settings',
            },
            bubbles: true,
            composed: true
        }));
    }

    handlePriorDaysExpireChange(event) {
        const selectedPriorDaysExpire = event.target.value;

        updateNotificationSetting({ fieldApiName: 'Prior_Days_to_Expire__c', value: selectedPriorDaysExpire })
        .then(result => {
            this.getPayorNotificationsData();
        })
        .catch(error => {
            console.error('Error fetching files:', error);
        });
    }

    handleNotificationCheckChange(event) {
        
        updateNotificationSetting({ fieldApiName: event.target.dataset.field, value: event.target.checked })
        .then(result => {
            // this.getPayorNotificationsData();
        })
        .catch(error => {
            console.error('Error fetching files:', error);
        });
    }
}