import { LightningElement, wire, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import merckLogo from '@salesforce/resourceUrl/PDSMerckLogo';
import PDSLoginImg from '@salesforce/resourceUrl/PDSLoginCoverImage';
import PDSLoginImgMb from '@salesforce/resourceUrl/PDSLoginImgMb';
// import PDSEmailImg from '@salesforce/resourceUrl/PDSEmailImg';
import check from '@salesforce/resourceUrl/PDSCheckcircle';
import FORM_FACTOR from '@salesforce/client/formFactor';
import forgotPassword from '@salesforce/apex/PDS_PortalAuthController.forgotPassword';
import loginEmail from '@salesforce/label/c.PDS_Login_Email';
import resetpassword from '@salesforce/label/c.PDS_Reset_Password';
import successmsg from '@salesforce/label/c.PDS_Reset_Success';
import resendSuccess from '@salesforce/label/c.PDS_Resned_Success';
import resend from '@salesforce/label/c.PDS_Reset_Resend';
import header from '@salesforce/label/c.PDS_Reset_Header';
import emailErrorMsg from '@salesforce/label/c.PDS_Reset_ErrorMsg';
import { NavigationMixin } from 'lightning/navigation';


export default class PdsforgotPassword extends NavigationMixin(LightningElement) {
    merckLogo = merckLogo;
    PDSLoginImg = PDSLoginImg;
    PDSLoginImgMb = PDSLoginImgMb;
    // PDSEmailImg = PDSEmailImg;
    check = check;
    @track emailerrormsg = false;
    @track errormsgtext = '';
    @track successpage = false;
    @track successpage2 = false;
    @track image;
    @track emailVal = '';
    connectedCallback() {
        if (FORM_FACTOR === 'Small') {
            this.image = PDSLoginImgMb;
        } else {
            this.image = PDSLoginImg;
        }
    }

    labels = {
        header,
        loginEmail,
        resetpassword,
        successmsg,
        resendSuccess,
        resend,
        emailErrorMsg
    };

    handlemailchange(event) {
        this.email = event.target.value;
        console.log('this.email', this.email);
        if (event.key === 'Enter') {
            event.preventDefault();
            this.handleOnclick();
        }
    }

    handleOnclick() {
        if (this.email) {
            this.resetPassword(false);
        } else {
            this.emailerrormsg = true;
            this.errormsgtext = emailErrorMsg;
            console.log('handleclick---this.errormsgtex' + this.errormsgtext);
        }
    }

    resetPassword(isResend) {
        console.log('enteredresetPassword');
        forgotPassword({ useremail: this.email })
            .then(result => {
                console.log('result of resetPassword-->', result);
                if (result !== 'Reset Password Link Sent') {
                    this.emailerrormsg = true;
                    this.errormsgtext = emailErrorMsg;
                } else {
                    this.emailerrormsg = false;
                    this.errormsgtext = '';
                    //this.successpage = true;
                    if (isResend) {
                        this.successpage2 = true;
                    } else {
                        this.successpage = true;
                        this.successpage2 = false;
                    }
                    console.log('---this.emailerrormsg' + this.emailerrormsg);
                }
            })
            .catch(error => {
                console.error('error of resetPassword-->', error);
                this.emailerrormsg = true;
                this.errormsgtext = 'An error occurred while resetting the password.';
            });
    }

    handleResend() {
        this.resetPassword(true);
    }

    loginback() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'Login',
                url: '/login'
            }
        });
    }

}