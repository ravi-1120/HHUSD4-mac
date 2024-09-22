import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

import MSD_CORE_CloseIcon from '@salesforce/resourceUrl/MSD_CORE_CloseIcon';
import MSD_CORE_SelectIcon from '@salesforce/resourceUrl/MSD_CORE_SelectIcon';
import RegistrationPage from '@salesforce/resourceUrl/RegistrationPage';
import jobcode from '@salesforce/label/c.nonbrandjobcode';
import updatePassword from '@salesforce/apex/CommunityAuthController.updatePassword';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';
import CloseIconImage from '@salesforce/resourceUrl/cancelicon';
import TurePasswordUpdateImage from '@salesforce/resourceUrl/MSD_CORE_TurePasswordUpdateImage';
import USER_ID from '@salesforce/user/Id';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';

export default class MSD_CORE_PasswordUpdate extends NavigationMixin(LightningElement) {

    closeicon = MSD_CORE_CloseIcon;
    selecticon = MSD_CORE_SelectIcon;

    @api heading1;
    @api subheading1;
    @api settingpagetrue = false;
    @api page;

    @track contactrole = '';
    @track heading1val = '';
    @track subheading1parentval = false;

    @track checkchar = false;
    @track checkletter = false;
    @track checknum = false;
    @track checkspecial = false;
    @track checkpassmatch = false;
    @track nextbtndisable = true;
    @track password = '';
    @track confirmpassword = '';
    @track nextbtnclass = 'nextbtncls';
    @track errormsg = false;
    @track accountID;

    @track siteName = '';
    @track siteApiName = '';

    @track userAccount = false;
    @track userAccounterrormess = '';

    @track passwordUpdatePage = false;

    CloseIcon = CloseIconImage;
    TureIcon = TurePasswordUpdateImage;
    label = {jobcode};
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

    // Method Name:         WiredgetStateParameters
    // Method Use:          Used for getting Record Id from the parameter
    // Developer Name:      Ravi Modi
    // Created Date:        25 July 2023
    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        console.log('this.accountID--->', this.accountID);
        if (currentPageReference) {
            this.accountID = currentPageReference.state.recordId;
            console.log('this.accountID--->', this.accountID);
        }
    }


    // Method Name:         renderedCallback
    // Method Use:          Used for loading external CSS file
    // Developer Name:      Ravi Modi
    // Created Date:        22th May 2023
    renderedCallback() {
        console.log('subheading1-->', this.subheading1);
        if (this.heading1 && this.subheading1) {
            this.heading1val = this.heading1;
            if (this.subheading1) {
                this.subheading1parentval = true;
            }
        } else {
            this.heading1val = 'Create your password.';
            this.subheading1parentval = false;
        }
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
    // Created Date:        23th May 2023
    handlechange(event) {

        let nameval = event.currentTarget.dataset.name;

        if (nameval == 'password') {
            this.userAccount = false;
            this.errormsg = false;
            this.password = event.target.value;
            this.checkchar = contains12Char(this.password);
            this.checkletter = containsUppercase(this.password);
            this.checknum = containsNumber(this.password);
            this.checkspecial = containsSpecialChar(this.password);
            this.checkpassmatch = containsPasswordMatch(this.password, this.confirmpassword);
            this.handleClickButton();
        } else if (nameval == 'confirmpassword') {
            this.userAccount = false;
            this.errormsg = false;
            this.confirmpassword = event.target.value;
            this.checkpassmatch = containsPasswordMatch(this.password, this.confirmpassword);
            this.handleClickButton();
        }
    }
    


    // Method Name:         handleClick
    // Method Use:          Used for button enable
    // Developer Name:      Ravi Modi
    // Created Date:        19th July 2023
    handleClickButton() {
        if (this.checkchar && this.checkletter && this.checknum && this.checkspecial && this.checkpassmatch) {
            this.nextbtndisable = false;
            this.nextbtnclass = 'nextbtncls btnenablecls';
        } else {
            this.nextbtndisable = true;
            this.nextbtnclass = 'nextbtncls';
        }
    }

    // Method Name:         handleClick
    // Method Use:          Used for Navigation and validation check
    // Developer Name:      Ravi Modi
    // Created Date:        24th May 2023
    handleClick(event) {
        let btname = event.currentTarget.dataset.name;

        if (this.password != '' || this.confirmpassword != '') {
            if (this.password === this.confirmpassword) {
                this.errormsg = false;
                this.savePassword();
            } else {
                this.errormsg = true;
            }
        }
        if(btname == 'save'){
            this.fireDataLayerEvent("button", '', 	"save", "modal", 'settings__c', '/settings');
        }
        this.fireDataLayerEvent("button", '', 	"login", "form", 'Password__c', '/password');
    }

     handlegaevent(event){
        let labelname = event.currentTarget.dataset.name;
         if (labelname == 'password'){
            this.fireDataLayerEvent("label", '', "new password", "modal", 'settings__c', '/settings'); 
        }else if (labelname == 'confirmpassword'){
            this.fireDataLayerEvent("label", '', "confirm password", "modal", 'settings__c', '/settings');
        }else if (labelname == 'contactlink'){
            this.fireDataLayerEvent("link", '', "contact", "modal", 'settings__c', '/settings');
        }
    }

    // Method Name:         savePassword
    // Method Use:          Used for Saving data into backedn
    // Developer Name:      Ravi Modi
    // Created Date:        24th May 2023
    savePassword() {

        updatePassword({ accountID: this.accountID, newPassword: this.password })
            .then((result) => {
                console.log('result------>', result);
                if (result == 'Success!') {
                    if (this.page == 'SettingPage') {
                        this.passwordUpdatePage = true;
                    } else {
                        this.handleOnclick();
                    }
                } else if (result == 'Not found any user') {
                    this.userAccount = true;
                    this.userAccounterrormess = 'User Not Found, contact System Admin';
                } else if (result == 'Cannot use old password') {
                    this.userAccount = true;
                    this.userAccounterrormess = 'Cannot use old password';
                } else {
                    this.userAccount = true;
                    this.userAccounterrormess = 'something went wrong';
                }

                console.log('<-----Result of savePassword----->', { result });

            })
            .catch((error) => {
                console.log('<-----Error in savePassword----->', { error });
            })

    }

    // Method Name:         handleOnclick
    // Method Use:          Used for Login to portal
    // Developer Name:      Ravi Modi
    // Created Date:        10th July 2023
    handleOnclick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.siteApiName.login,
                url: this.siteName.login
            }
        });
    }

  

    // Method Name:         handleClose
    // Method Use:          Used for close popup model
    // Developer Name:      Ravi Modi
    // Created Date:        24th July 2023
    handleClose(event) {
        let btnName = event.currentTarget.dataset.name;

        const closeEvent = new CustomEvent("popupclose", {
            detail: true
        })
        this.dispatchEvent(closeEvent);
        this.dispatchEvent(new CustomEvent('footerShow', {
            detail: 'show',
            bubbles: true,
            composed: true
        }));

        if(btnName == 'cross'){
            this.fireDataLayerEvent('button', '', 'back to screen_X', 'modal', 'settings__c', '/settings', '');
        }else if (btnName == 'cancel'){
            this.fireDataLayerEvent('button', '', 'cancel', 'modal', 'settings__c', '/settings', '');
        }
    }


//gaevent
 fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl){
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {
            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'account management',
                page_purpose: 'password',
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
                page_title: 'New Password',

            },
            bubbles: true,
            composed: true
        }));
     }
}

function contains12Char(str) {
    return /.{8,}$/.test(str);
}
function containsUppercase(str) {
    let checkup = /[A-Z]/.test(str);
    let checklo = /[a-z]/.test(str);
    let checkval;
    if (checkup && checklo) {
        checkval = true;
    } else {
        checkval = false;
    }
    return checkval;
}
function containsNumber(str) {
    return /[0-9]/.test(str);
}
function containsSpecialChar(str) {
    return /[-’/`~!#*$@_%+=.,^&(){}[\]|;:”<>?\\]/g.test(str);
}
function containsPasswordMatch(pass, confPass) {
    console.log('pass==>', pass);
    console.log('confPass==>', confPass);
    if (pass != '' && pass != '' && pass != null && pass != undefined && confPass != null && confPass != undefined) {
        if (pass === confPass) {
            return true;
        } else {
            return false;
        }
    } else {
        return false;
    }
}