import { LightningElement, track, wire, api } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import communityPath from '@salesforce/community/basePath';
import successicon from '@salesforce/resourceUrl/successicon';
import doAuthorize from '@salesforce/apex/MSD_CORE_UpdateEmailAddress.doAuthorize';
import doValidateOTP from '@salesforce/apex/MSD_CORE_UpdateEmailAddress.doValidateOTP';
/*import doExpire from '@salesforce/apex/MSD_CORE_UpdateEmailAddress.doExpire';*/
import RegistrationPage from '@salesforce/resourceUrl/RegistrationPage';

import Id from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import loggedInUserName from '@salesforce/schema/User.Name';
import loggedInUserEmail from '@salesforce/schema/User.Email';
import jobcode from '@salesforce/label/c.nonbrandjobcode';

import MSD_CORE_CloseIcon from '@salesforce/resourceUrl/MSD_CORE_CloseIcon';
import MSD_CORE_SelectIcon from '@salesforce/resourceUrl/MSD_CORE_SelectIcon';
import CloseIconImage from '@salesforce/resourceUrl/cancelicon';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import USER_ID from '@salesforce/user/Id';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';

export default class MSD_CORE_UpdateEmailAddress extends NavigationMixin(LightningElement) {

    closeicon = MSD_CORE_CloseIcon;
    selecticon = MSD_CORE_SelectIcon;
    closeIcon = CloseIconImage;
    successicon = successicon;

    @track currentUserName;
    @track currentUserEmailId;
    @track userId;
    @track navigatecontact;
    @track navigatecontactname;
    @track validatedNewEmailError = false;
    @track validatedConfirmEmailError = false;
    @track contactrole = '';

    @track validateEmails = false;
    @track isUsed = 'New';
    @track securityCode;
    @track invalidCode = false;

    @track oldEmail = false;
    @track oldConfirmEmail = false;
    @track newEmail;
    @track confirmEMail;
    @track siteName = '';

    @track settingpagetrue = true;
    @track nextbtnclass = 'nextbtncls';
    @track nextbtndisable = true;

    @api currentemailaddress = 'mfrpayor@domain.com';
    @api redirectedto;
    @api settingpagestatus = false;

    @track emailupdatepage = true;
    @track validateOTPpage = false;
    @track confirmationpage = false;
    @track updatePwdDisable = true;
    @track closingpagestatus = false;
    label = {jobcode};
    
    @wire(getRecord, { recordId: Id, fields: [loggedInUserName, loggedInUserEmail] })
    userDetails({ error, data }) {
        if (data) {
            this.userId = Id;
            this.currentUserName = data.fields.Name.value;
            this.currentUserEmailId = data.fields.Email.value;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log({ data });
        console.log({ error });
        if (data) {
            this.siteName = data.siteAPINamesdebuglog;
            this.siteApiName = data.siteNames;
        } else if (error) {
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

    renderedCallback() {
        this.getnamesnew();
        Promise.all([
            loadStyle(this, RegistrationPage),
        ]).then(() => {
            console.log('Files loaded');
        })
            .catch(error => {
                console.log(error.body.message);
            });
    }

    getnamesnew() {
        getSiteNameAndAPIName({ pageName: 'contactmanager' })
            .then((result) => {
                console.log('getnamesnew-->' + JSON.stringify(result));
                this.navigatecontact = result.siteAPIName;
                this.navigatecontactname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }

    handlegaevent(event){
        let labelName = event.currentTarget.dataset.name;
        if(labelName == 'newPayorEmail'){
            this.fireDataLayerEvent('label', '', 'new email', 'modal', 'settings__c', '/settings', '');
        }else if (labelName == 'confirmPayorEmail'){
            this.fireDataLayerEvent('label', '', 'confirm email', 'modal', 'settings__c', '/settings', '');
        }else if (labelName == 'contact'){
            this.fireDataLayerEvent('link', '', 'contact', 'modal', 'mycontacts__c', '/my-contacts', '');
        }
    }
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

    disablePaste(event) {
        event.preventDefault();
    }

    handleEmailValidation() {
        var flag = true;
        const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        let email = this.template.querySelector('[data-id="newEmailAddress"]');
        console.log('email : ',email);
        let emailVal = email.value;
        if (emailVal.match(emailRegex)) {
            email.setCustomValidity("");
        } else {
            flag = false;
            email.setCustomValidity("Email is incorrect. Please enter a valid email.");
        }
        email.reportValidity();
        this.handleConfirmEmailValidation();
        return flag;
    }

    emailValidation(event) {
        const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        let emailIn = this.template.querySelector('[data-id="newEmailAddress"]');
        let nameval = event.currentTarget.dataset.name;
        console.log('nameval : ',nameval);
        if (nameval == 'newPayorEmail') {
            this.newEmail = event.target.value.toLowerCase();
            const newEmailValue = this.newEmail;
            if (newEmailValue.match(emailRegex)) {
                this.validatedNewEmailError = false;
                emailIn.setCustomValidity("");
            } else if(this.newEmail != null || this.newEmail != ''){ 
                this.validatedNewEmailError = true; 
                emailIn.setCustomValidity("Email is incorrect. Please enter a valid email.");
            }
            emailIn.reportValidity();

            if (this.newEmail === this.currentUserEmailId) {
                this.oldEmail = true;
            } else { 
                this.oldEmail = false; 
            }
            this.validateEmails = matchEmails(this.newEmail, this.confirmEMail, this.validatedNewEmailError, this.validatedConfirmEmailError);
            if ((this.newEmail === this.confirmEMail) && (!this.validatedConfirmEmailError) && (!this.validatedNewEmailError) && (this.newEmail != this.currentUserEmailId) && (this.newEmail != '' && this.newEmail != undefined && this.newEmail != null) && (this.confirmEMail != '' && this.confirmEMail != undefined && this.confirmEMail != null)) {
                this.nextbtndisable = false;
                this.nextbtnclass = 'nextbtncls btnenablecls';
            } else {
                this.nextbtndisable = true;
                this.nextbtnclass = 'nextbtncls';
            }

            if(this.newEmail === null || this.newEmail === ''){
                emailIn.setCustomValidity("");
            }
             emailIn.reportValidity();
        } 
        
        else if (nameval == 'confirmPayorEmail') {
            let emailIn = this.template.querySelector('[data-id="confirmEmailAddress"]');
            this.confirmEMail = event.target.value.toLowerCase();
             console.log('con email : ', this.confirmEMail );
            const nconEmailValue = this.confirmEMail;
            if (nconEmailValue.match(emailRegex)) {
                this.validatedConfirmEmailError = false;
                 emailIn.setCustomValidity(""); 
            } else if(this.confirmEMail != null || this.confirmEMail != ''){ 
                this.validatedConfirmEmailError = true; 
            emailIn.setCustomValidity("Email is incorrect. Please enter a valid email.");
            }
             emailIn.reportValidity();

             if (this.newEmail === this.currentUserEmailId) {
                this.oldConfirmEmail = true;
            } else { this.oldConfirmEmail = false; }
            this.validateEmails = matchEmails(this.newEmail, this.confirmEMail, this.validatedNewEmailError, this.validatedConfirmEmailError);
            if (this.confirmEMail === this.currentUserEmailId) {
                this.confirmEMail = '';
            }
            if ((this.newEmail === this.confirmEMail) && (!this.validatedConfirmEmailError) && (!this.validatedNewEmailError) && (this.confirmEMail != this.currentUserEmailId) && (this.newEmail != '' && this.newEmail != undefined && this.newEmail != null) && (this.confirmEMail != '' && this.confirmEMail != undefined && this.confirmEMail != null)) {
                this.nextbtndisable = false;
                this.nextbtnclass = 'nextbtncls btnenablecls';
            } else {
                this.nextbtndisable = true;
                this.nextbtnclass = 'nextbtncls';
            }

            if(this.confirmEMail === null || this.confirmEMail === ''){
                emailIn.setCustomValidity("");
            }
             emailIn.reportValidity();
        }
    }

    handleClick(event) {
        console.log('Button Click');
        doAuthorize({
            userId: this.userId,
            email: this.currentUserEmailId,
            newEmail: this.newEmail
        }).then(result => {
            console.log('result is ' + result);
            this.emailupdatepage = false;
            this.validateOTPpage = true;
            this.nextbtnclass = 'nextbtncls'
        }).catch(error => {
            console.log('Error is' + error);
        });

        let btnName = event.currentTarget.dataset.name;
        if(btnName == 'securitycode'){
            this.fireDataLayerEvent('button', '', 'send security code', 'modal', 'settings__c', '/settings', '');
        }
        
    }

    backtoEmail() {
        this.emailupdatepage = true;
        this.validateOTPpage = false;
        this.confirmationpage = false;
        this.nextbtnclass = 'nextbtncls btnenablecls';
        
        doExpire({
              userId: this.userId
        }).then(result => {
            alert(result);
            this.enteredOTP = '';
         this.securityCode = '';
            console.log('result is ' + result);
             this.securityCode = '';
        }).catch(error => {
            alert('Error is' + error);
            console.log('Error is' + error);
        });
       
    }

    handleEnter(event) {
        if (event.keyCode === 13) {
            this.otpValidation(event);
        }
    }

    otpValidation(event) {
        this.securityCode = event.target.value;
        if (this.securityCode != null || this.securityCode != undefined || this.securityCode != '') {
            if (this.securityCode.length === 6) {
                this.updatePwdDisable = false;
                this.nextbtnclass = 'nextbtncls btnenablecls';
            } else {
                this.updatePwdDisable = true;
                this.nextbtnclass = 'nextbtncls';
            }
        }
    }

    handleOTPClick() {
        console.log('Validating the OTP enetered.');
        doValidateOTP({
            userId: this.userId,
            isUsed: this.isUsed,
            enteredOTP: this.securityCode,
            emailId: this.newEmail
        }).then(result => {
            console.log('result is ' + result);
            if (result == 'success') {
                console.log('OTP Validated');
                this.emailupdatepage = false;
                this.validateOTPpage = false;
                this.settingpagestatus = false;
                this.closingpagestatus = true;
                this.confirmationpage = true;
                this.invalidCode = false;
            } else if (result == 'invalidOTP') {
                console.log('Invalid OTP');
                this.updatePwdDisable = true;
                this.nextbtnclass = 'nextbtncls';
                this.invalidCode = true;
                this.emailupdatepage = false;
                this.validateOTPpage = true;
                this.settingpagestatus = true;
                this.closingpagestatus = false;
                this.confirmationpage = false;
            }
        }).catch(error => {
            console.log('Error is' + error);
        });
    }

    handleClose1() {
        this.url = communityPath + '/secur/logout.jsp?retUrl=%2Fmerckportal%2Flogout-confirmation-page';
        window.location.replace(this.url);
    }

    navigateToLogoutPage() {
        //this.url = communityPath + '/secur/logout.jsp?retUrl=%2Flogin';
        this.url = communityPath+ '/secur/logout.jsp?retUrl=%2Fmerckportal%2Flogout-confirmation-page%2Fmfr-contactyouraccountmanager';
        window.location.replace(this.url);
        console.log('loggedOut in mfr upadte');
        /*
        let intervalId = setInterval(() => {

            let normalurl = communityPath + '/logout-confirmation-page/mfr-contactyouraccountmanager';
            alert(normalurl);

            window.location.replace(normalurl)
        }, 5000);
        clearInterval(intervalId); */


        //this.mfrcontactyouraccountmanager();
        console.log('navigated to contact manager page');
        
    }

    mfrcontactyouraccountmanager() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.navigatecontactname,
                url: this.navigatecontact
            },

        });
    }

    //Google Analytics
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

function matchEmails(newEmail, confirmEmail, validateNewEmail, validateOldEmail) {
    let returnValue;
    if ((newEmail != '' && newEmail != undefined && newEmail != null) && (confirmEmail != '' && confirmEmail != undefined && confirmEmail != null) && validateNewEmail === false && validateOldEmail === false) {
        if (newEmail === confirmEmail) {
            returnValue = false;
        } else {
            returnValue = true;
        }
    } else {
        returnValue = false;
    }
    return returnValue;
}