import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import bannerLogo from '@salesforce/resourceUrl/banner';
import forgotpasswordlogo from '@salesforce/resourceUrl/forgotpasswordlogo'; 
import forgotpasswordmobilelogo from '@salesforce/resourceUrl/forgotpasswordmobilelogo';
import forgotpasswordverify from '@salesforce/apex/CommunityAuthController.forgotpasswordverify';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
import isguest from '@salesforce/user/isGuest';

export default class MSD_CORE_Forgotpasswordnew extends LightningElement {

    navigatelearnmore;
    navigatelearnmorename;
    welcomelink;
    welcomeapiname;
    bannerLogo = bannerLogo;
    domainurl = domainurl;
    forgotpasswordlogo = forgotpasswordlogo;
    forgotpasswordmobilelogo = forgotpasswordmobilelogo;
    @track emailVal = '';
    @track emailclass= 'emailcls';
    @track errormsgtext = '';
    @track emailerrormsg = false;
    showForm = false;
    showCodeLabel = false;
    @track accountId;//Account Id
    @track portalType;

    connectedCallback() {
        if(!this.isGuestUser) {
            window.location.href = this.domainurl+'/dashboard';
        }

        this.showForm = true;
        this.getsitename(); // to bring api names and urls of all pages dynamically
    }

    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.portalType = currentPageReference.state.pType;
            this.accountId = currentPageReference.state.recordId;
        }
    }

    get isGuestUser() {
        return isguest;  
    }

    getsitename() {
        getSiteNameAndAPIName({ pageName: 'Organic Welcome' })
        .then((result) => {
            console.log({ result });
            this.welcomelink = result.siteAPIName;
            this.welcomeapiname = result.siteName;
        })
        .catch((error) => {
            console.log(' User Calling Error' + JSON.stringify(error));
            this.error = error;
        });
    }

    handleChange(event){
        this.emailinp = event.target.value;
    }

    handleInputFocus(event){
        this.showForm = false;
        var vl = event.target.value;
        if(vl.trim() == '') {
            this.showCodeLabel = false;
        }
        else {
            this.showCodeLabel = true;
        }

        this.showForm = true;
    }

    handleInputChange(event){
        this.emailinp = event.target.value;
        var vl = event.target.value;

        if(vl.trim() == '') {
            this.showCodeLabel = false;
        }
        else {
            this.showCodeLabel = true;
        }
    }
    
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

    handleForgotPaswd() {
        try {
            if (this.handleEmailValidation()) {
                if (this.emailVal) {
                    this.userResetPassword();
                } else {
                    this.emailerrormsg = true;
                    this.errormsgtext = 'Invalid email format.';
                    this.iserror = true;
                    this.emailclass = 'emailclserror';
                }
            } else {
                this.emailerrormsg = true;
                this.errormsgtext = 'Invalid email format.';
                this.iserror = true;
                this.emailclass = 'emailclserror';
            }
        } catch (error) {
            console.log('Error On HandleClick-->',{error});
        }
    }

    signupClick() {
        var url = this.domainurl+'/organic-attestation' + this.addParameters();
        
        window.location.href = url;
    }

    addParameters() {
        var parameters = '';

        if (typeof this.portalType !== 'undefined' && this.portalType !== null) {
            parameters += '?pType=' + this.portalType;
        } 
        else {
            parameters += '?pType=MFR';
        } 

        if (typeof this.accountId !== 'undefined' && this.accountId !== null) {
            parameters += '&recordId=' + this.accountId;
        }

        if (typeof this.brandId !== 'undefined' && this.brandId !== null) {
            parameters += '&brandId=' + this.brandId;
        }

        return parameters;
    }

    userResetPassword() {
        forgotpasswordverify({emailval: this.emailVal})
        .then((result) => {
            console.log('result of resetPassword-->',{result});
            if (result != 'Reset Password Link Sent successfully!') {
                this.iserror = true;
                this.emailclass = 'emailclserror';
            } else {
                this.iserror = false;
                this.emailclass = 'emailcls';
                window.location.href = this.domainurl+'/organic-email-sent?email='+this.emailVal;
            }
        })
        .catch((error) => {
            console.log('error of resetPassword-->',{error});
            this.emailerrormsg = true;
        })
    }
}