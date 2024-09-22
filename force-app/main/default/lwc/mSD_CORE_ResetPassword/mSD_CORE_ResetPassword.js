import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import jobcode from '@salesforce/label/c.nonbrandjobcode';
import merckconnectlogo from '@salesforce/resourceUrl/merckconnectlogo';

import MSD_CORE_CloseIcon from '@salesforce/resourceUrl/MSD_CORE_CloseIcon';
import MSD_CORE_SelectIcon from '@salesforce/resourceUrl/MSD_CORE_SelectIcon';
import RegistrationPage from '@salesforce/resourceUrl/RegistrationPage';
import ResetPasswordPageCSS from '@salesforce/resourceUrl/ResetPasswordPageCSS';

import checkOTP from '@salesforce/apex/CommunityAuthController.checkOTP';
import resetPassword from '@salesforce/apex/CommunityAuthController.resetPassword';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';
export default class MSD_CORE_ResetPassword extends NavigationMixin(LightningElement) {

    closeicon = MSD_CORE_CloseIcon;
    selecticon = MSD_CORE_SelectIcon;

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
    @track passPage = true;
    @track siteName = '';
    @track siteApiName = '';
    label = {jobcode};
    @track userId;
    @track token = '';
    @track isotpValid = false;
    @track otperrormsg = '';

    mercklogo = merckconnectlogo;
    @track showerrormsg;

    // Method Name:         renderedCallback
    // Method Use:          Used for loading external CSS file
    // Developer Name:      Ravi Modi
    // Created Date:        10th July 2023
    renderedCallback() {
        Promise.all([
            loadStyle(this, RegistrationPage),
            loadStyle(this, ResetPasswordPageCSS),
        ]).then(() => {
            console.log('Files loaded');
        })
            .catch(error => {
                console.log(error.body.message);
            });

      this.fireOnLoadEvent();
      
    }

    // Method Name:         WiredgetStateParameters
    // Method Use:          Used for getting Record Id from the parameter
    // Developer Name:      Ravi Modi
    // Created Date:        13 July 2023
    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.userId = currentPageReference.state.recordId;
            this.token = currentPageReference.state.token;
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

    // Method Name:         wiredcheckOTP
    // Developer Name:      Ravi Modi
    // Created Date:        14 July 2023
    @wire(checkOTP, { userId : '$userId', token : '$token' })
    wiredcheckOTP(value) {
        console.log('wiredcheckOTP -->',{value});
        const { data, error } = value;
        if(data) {
            if (data == 'Valid OTP') {
                this.isotpValid = true;
            } else if(data == 'Invalid OTP'){
                this.otperrormsg = 'Invalid OTP';
                this.isotpValid = false;
            } else {
                this.isotpValid = false;
                this.otperrormsg = data;
                this.handleOnclick();
            }
        } else if(error) {
            console.log('wiredcheckOTP--->',{error});
        }
    }

    // Method Name:         handlechange
    // Method Use:          Used for getting the value on change
    // Developer Name:      Ravi Modi
    // Created Date:        10th July 2023
    handlechange(event) {

        let nameval = event.currentTarget.dataset.name;
        if (nameval == 'password') {
            this.password = event.target.value;
            this.checkchar = contains12Char(this.password);
            this.checkletter = containsUppercase(this.password);
            this.checknum = containsNumber(this.password);
            this.checkspecial = containsSpecialChar(this.password);
            this.checkpassmatch = containsPasswordMatch(this.password, this.confirmpassword);
            this.handleClickButton();
              

        } else if (nameval == 'confirmpassword') {
            this.confirmpassword = event.target.value;
            this.checkpassmatch = containsPasswordMatch(this.password, this.confirmpassword);
            this.handleClickButton();
            
        }
    }

    // Method Name:         handleClick
    // Method Use:          Used for button enable
    // Developer Name:      Ravi Modi
    // Created Date:        10th July 2023

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
    // Created Date:        10th July 2023
    handleClick(event) {

        if (this.password != '' || this.confirmpassword != '') {
            if (this.password === this.confirmpassword) {
                this.errormsg = false;
                this.resetpassword();
            } else {
                this.errormsg = true;
            }
        }
        this.fireDataLayerEvent("button", '', 	"reset password", "password_flow", 'ChangePassword__c', '/changepassword');
    }

    handlegaevent(event){
        let labelname = event.currentTarget.dataset.name;
        if(labelname == 'contact'){
            this.fireDataLayerEvent("link", '', "contact", "password_flow", 'ChangePassword__c', '/changepassword');
        }else if (labelname == 'contactother'){
            this.fireDataLayerEvent("link", '', "contact", "password_flow", 'ChangePassword__c', '/changepassword');
        }else if (labelname == 'password'){
            this.fireDataLayerEvent("label", '', "new password", "password_flow", 'ChangePassword__c', '/changepassword'); 
        }else if (labelname == 'confirmpassword'){
            this.fireDataLayerEvent("label", '', "confirm password", "password_flow", 'ChangePassword__c', '/changepassword');
        }
    }

    // Method Name:         resetpassword
    // Method Use:          Used for Reset the password
    // Developer Name:      Ravi Modi
    // Created Date:        10th July 2023
    resetpassword() {
        console.log('userId--->', this.userId);
        console.log('password-->', this.password);
        console.log('token-->', this.token);
        resetPassword({ userId: this.userId, newPassword: this.password, token: this.token })
            .then((result) => {
                console.log('<-----Result of resetPassword----->', { result });
                if (result == 'Success!') {
                    this.passPage = false;
                } else {
                    this.errormsg = true;
                    this.showerrormsg = result;
                }
            })
            .catch((error) => {
                console.log('<-----Error in resetPassword----->', { error });
                this.template.querySelector('c-custom-toast').showToast('error', error);
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
        this.fireDataLayerEvent("button", '', "login", "password_flow", 'Login', '/login');
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
                link_text: 'ChangePassword__c',
                link_url: '/changepassword',
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