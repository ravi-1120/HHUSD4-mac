import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
//Static Resources
import merckLogo from '@salesforce/resourceUrl/PDSMerckLogo';
import PDSExternalCSS from '@salesforce/resourceUrl/PDSExternalCSS';
import loginImage from '@salesforce/resourceUrl/PDSLoginCoverImage';
import PDSLoginImgMb from '@salesforce/resourceUrl/PDSLoginImgMb';
import check from '@salesforce/resourceUrl/PDSCheckcircle';
//Apex
import decryptToken from '@salesforce/apex/PDS_PortalAuthController.decryptToken';
import changePassword from '@salesforce/apex/PDS_PortalAuthController.changeUserPassword';
import resendWelcomeEmail from '@salesforce/apex/PDS_PortalAuthController.resendWelcomeEmail';
//Labels
import cnHeader from '@salesforce/label/c.PDS_CreateNew_Password';
import newPassword from '@salesforce/label/c.PDS_New_Password';
import confirmPassword from '@salesforce/label/c.PDS_ConfirmPassword';
import pwdRequirements from '@salesforce/label/c.PDS_PWD_Requirements';
import resetPwd from '@salesforce/label/c.PDS_Reset_Button';
import invalidPage from '@salesforce/label/c.PDS_InvalidPage';
import ActivationMessage from '@salesforce/label/c.PDS_ActivationLink';
import resetErrorMsg from '@salesforce/label/c.PDS_RepeatedPassword_Error';


export default class PdsChangePassword extends NavigationMixin(LightningElement) {
    merckLogo = merckLogo;
    loginImage = loginImage;
    PDSLoginImgMb = PDSLoginImgMb;
    resetDisabled = true;
    encyptedToken;
    check = check;
    @track resendActivation = false;

    labels = {
        cnHeader,
        confirmPassword,
        newPassword,
        pwdRequirements,
        resetPwd,
        invalidPage,
        ActivationMessage,
        resetErrorMsg
    };

    @track validToken = false;
    @track errorMsg = false;
    @track newPassword = '';
    @track confirmPassword = '';
    @track image;
    isNewUser = false;
    @track showSpinner = false;
    idUser;
    malformedURL = false;
    resetError = false;

    @track passwordCriteria = {
        length: false,
        alpha: false,
        number: false,
        specialChar: false,
        match: false
    };

    @track valRules = [
        { label: 'length', regex: /.{8,}/, message: '8 or more characters' },
        { label: 'alpha', regex: /^(?=.*[a-z])(?=.*[A-Z]).*$/, message: 'At least one uppercase one lowercase letter' },
        { label: 'number', regex: /\d/, message: 'At least one number' },
        { label: 'specialChar', regex: /[!@#$%^&*()_+{}\[\]:;'"<>,.?/~`\\|\-=]/, message: 'At least one special character, for example !@#?].' },
        { label: 'match', message: 'Passwords match' },
    ];

    connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        this.encyptedToken = urlParams.get('token');
        this.showSpinner = true;
        decryptToken({ encryptedToken: this.encyptedToken })
            .then(result => {
                console.log('result ' + JSON.stringify(result));
                this.showSpinner = false;
                if ((result.status == 'Valid' || result.status == 'Valid New User') && this.encyptedToken != '')
                {
                    this.validToken = true;
                }else{
                    this.validToken = false;
                    this.errorMsg = true;
                }
                if (result.status == 'Valid New User' || result.newUser == 'true') {
                    this.isNewUser = true;
                }
                this.idUser = result.userId;
                if(this.idUser != undefined && this.idUser != null){
                    this.malformedURL = true;
                }
            })
            .catch(error => {
                console.error('Error', error);
            });

        if (FORM_FACTOR === 'Small') {
            this.image = PDSLoginImgMb;
        } else {
            this.image = loginImage;
        }

        Promise.all([
            loadStyle(this, PDSExternalCSS)
        ])
    }

    handleUserInput(event) {
        const { name, value } = event.target;
        if (name == 'Password') this.newPassword = value;
        if (name == 'Confirm Password') this.confirmPassword = value;

        this.validatePassword();
        this.disableReset();
    }

    validatePassword() {
        this.passwordCriteria = this.valRules.reduce((result, valRule) => {
            if (valRule.regex) {
                result[valRule.label] = valRule.regex.test(this.newPassword);
            }
            return result;
        }, { match: this.newPassword !== '' && this.confirmPassword !== '' && this.newPassword === this.confirmPassword });
        this.getClassNames();
    }

    getClassNames() {
        this.valRules = this.valRules.map(rule => {
            const className = this.passwordCriteria[rule.label] ? 'active-vc' : '';
            return { ...rule, className };
        });
    }

    disableReset() {
        this.resetDisabled = !Object.values(this.passwordCriteria).every(value => value);
    }

    handleChangePassword() {
        if (!this.changeUserPassword && this.validToken) {
            console.log('encyptedToken ' + this.encyptedToken);
            this.showSpinner = true;
            changePassword({ encryptedToken: this.encyptedToken, newPassword: this.newPassword })
                .then(result => {
                    console.log('Result ' + result);
                    if (result == 'Reset Success') {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                name: 'Home',
                                url: '/'
                            }
                        });
                    }else if(result.includes('invalid repeated')){
                        this.resetError = true;
                    }
                    this.showSpinner = false;
                })
                .catch(error => {
                    console.error('Error', error);
                });
        }
    }

    resendLink() {
        this.showSpinner = true;
        resendWelcomeEmail({ userId: this.idUser, isNewUser: this.isNewUser == 'true' ? false : true })
            .then(result => {
                this.resendActivation = true;
                this.showSpinner = false;
            })
            .catch(error => {
                this.resendActivation = false;
                console.error('Error', error);
            });
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