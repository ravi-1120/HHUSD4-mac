import { LightningElement, wire, track } from 'lwc';
import bannerLogo from '@salesforce/resourceUrl/banner';
import SignupSubmit_Logo from '@salesforce/resourceUrl/SignupSubmit_Logo';
import SignupSubmit_Logo1 from '@salesforce/resourceUrl/SignupSubmit_Logo1';
import { CurrentPageReference } from 'lightning/navigation';
import submitOTP from '@salesforce/apex/MSD_CORE_SignUpController.submitOTP';
import createOTP from '@salesforce/apex/MSD_CORE_SignUpController.createOTP';
import submitEligibility from '@salesforce/apex/MSD_CORE_SignUpController.submitEligibility';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
import isguest from '@salesforce/user/isGuest';

export default class MSD_CORE_Verifyemail extends LightningElement {
    @track bannerLogo = bannerLogo;
    @track SignupSubmit_Logo = SignupSubmit_Logo;
    @track SignupSubmit_Logo1 = SignupSubmit_Logo1;
    @track inputValue;
    @track errorOtp = false;
    @track showCodeLabel = false;
    @track showForm = false;
    @track otpClass = 'otpcode';
    @track emailReceivedFromSignup;
    @track recordId;
    @track errorDetails = 'Please Enter Valid OTP';
    @track isButtonDisabled = false;
    domainurl = domainurl;
    @track brandId;

    connectedCallback() {
        if(!this.isGuestUser) {
            window.location.href = this.domainurl+'/dashboard';
        }

        this.showForm = true;
        this.createOTPOnLoad();
    }

    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.emailReceivedFromSignup = currentPageReference.state.email;
            this.accountId = currentPageReference.state.recordId;
            this.brandId = currentPageReference.state.brandId;
        }
    }

    get isGuestUser() {
        return isguest;  
    }
    
    createOTPOnLoad() {
        createOTP({ recordId: this.accountId })
        .then(result => {
            if (!result) {
                this.errorOtp = true;
                this.errorDetails = 'Failed to create OTP on load';
            }
        })
        .catch(error => {
            console.error('Error in createOTP on load:', error);
            this.errorDetails = 'Error in createOTP';
            this.errorOtp = true;
        });
    }

    handleInput(event) {
        this.inputValue = event.target.value.trim();
        this.showCodeLabel = this.inputValue !== '';
    }

    resendVerification() {
        createOTP({ recordId: this.accountId })
        .then(result => {
            if (!result) {
                this.errorOtp = true;
                this.errorDetails = 'Failed to resend OTP';
            }
        })
        .catch(error => {
            console.error('Error in resendVerification:', error);
            this.errorDetails = 'Error in resendVerification';
            this.errorOtp = true;
        });
    }

    verify() {
        // Disable the button to prevent multiple clicks
        this.isButtonDisabled = true;

        submitOTP({ recordId: this.accountId, otpval: this.inputValue })
        .then(result => {
            if (result === 'Valid OTP!') {
                return submitEligibility({ accountid: this.accountId });
            } else {
                throw new Error('Invalid OTP');
                this.errorDetails = 'Please Enter Valid OTP';
                this.errorOtp = true;
            }
        })
        .then(result => {
            if (result === 'Success') {
                var url = this.domainurl+'/organic-create-password' + this.addParameters();
        
                window.location.href = url;
            } else {
                this.errorDetails = 'Please try again. The code you entered is invalid or may have expired. ';
                this.errorOtp = true;
                this.otpClass = 'otpcodered';
            }
        })
        .catch(error => {
            console.error('Error:', error);
            this.errorDetails = 'Please try again. The code you entered is invalid or may have expired. ';
            this.errorOtp = true;
            this.otpClass = 'otpcodered';
        })
        .finally(() => {
            this.isButtonDisabled = false;
        });
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
}