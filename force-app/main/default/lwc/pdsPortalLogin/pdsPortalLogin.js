import { LightningElement, track } from 'lwc';
//Platform
import { loadStyle } from 'lightning/platformResourceLoader';
import isLogged from '@salesforce/user/isGuest';
import basePath from "@salesforce/community/basePath";
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
//Apex
import userAuth from '@salesforce/apex/PDS_PortalAuthController.userAuth';
//Static Resources
import merckLogo from '@salesforce/resourceUrl/PDSMerckLogo';
import PDSExternalCSS from '@salesforce/resourceUrl/PDSExternalCSS';
import loginImage from '@salesforce/resourceUrl/PDSLoginCoverImage';
import PDSLoginImgMb from '@salesforce/resourceUrl/PDSLoginImgMb';
//Labels
import loginHeader from '@salesforce/label/c.PDS_login_header';
import loginError from '@salesforce/label/c.PDS_Login_Error';
import lockedError from '@salesforce/label/c.PDS_Portal_User_Locked';
import loginEmail from '@salesforce/label/c.PDS_Login_Email';
import loginPassword from '@salesforce/label/c.PDS_Login_Password';
import signIn from '@salesforce/label/c.PDS_SignIn';
import forgotPwd from '@salesforce/label/c.PDS_ForgotPWD';

import autoLoginKey from '@salesforce/label/c.PDS_AutoLoginKey';
import autoLoginValue from '@salesforce/label/c.PDS_AutoLoginValue';
import autoLoginUn from '@salesforce/label/c.PDS_AutoLoginEmail';
import autoLoginPs from '@salesforce/label/c.PDS_AutoLoginPassword';
import loginDescHeader from '@salesforce/label/c.PDS_LoginDescriptionHeader';
import loginDesc from '@salesforce/label/c.PDS_LoginDescription';
import loginDesc2 from '@salesforce/label/c.PDS_LoginDescription2';


export default class PdsPortalLogin extends NavigationMixin(LightningElement) {
    merckLogo = merckLogo;
    loginImage = loginImage;
    PDSLoginImgMb = PDSLoginImgMb;
    loginError = false;
    userEmail;
    password;
    labels = {
        loginHeader,
        loginError,
        loginEmail,
        loginPassword,
        signIn,
        forgotPwd,
        autoLoginKey,
        autoLoginValue,
        autoLoginUn,
        autoLoginPs,
        loginDescHeader,
        loginDesc,
        loginDesc2

    };

    @track loginErrorMessage;
    @track image;


    connectedCallback() {
        // const urlParams = new URLSearchParams(window.location.search);
        // let startURL = urlParams.get('startURL');
        // if (startURL && startURL.includes('Locked')) {
        //     this.loginErrorMessage = lockedError;
        //     this.loginError = true;
        // }
        if (FORM_FACTOR === 'Small') {
            this.image = PDSLoginImgMb;
        } else {
            this.image = loginImage;
        }
        // if (isLogged == false) {
        //     window.location.href = basePath;
        // }

        Promise.all([
            loadStyle(this, PDSExternalCSS)
        ])
        this.handleAutoLogin();
    }

    handleUserInput(event) {
        let fieldName = event.target.name;
        let fieldValue = event.target.value;
        if (fieldName == 'useremail') this.userEmail = fieldValue;
        if (fieldName == 'userpwd') this.password = fieldValue;
        if(event.key === 'Enter'){
            event.preventDefault();
            this.handleLogin();
        }
    }

    handleLogin() {
        this.loginError = false;
        this.loginErrorMessage = this.labels.loginError;
        if (this.userEmail && this.password) {
            userAuth({ useremail: this.userEmail, password: this.password })
                .then((result) => {
                    console.log('Result ' + result);
                    if (result != this.labels.loginError && result != lockedError) {
                        window.location.href = result;
                    } else {
                        this.loginErrorMessage = result;
                        this.loginError = true;
                    }
                }).catch((err) => {
                    this.loginError = true;
                    console.log('Auth Error ' + JSON.stringify(err));
                });
        } else {
            this.loginError = true;
        }
    }

    forgotpassword() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'Forgot_Password',
                url: '/ForgotPassword'
            }
        });
    }
    
    handleAutoLogin() {
        const queryParamPath = window.location.search;
        console.log('queryParamPath: ' + queryParamPath);
        if (queryParamPath) {
            const urlParams = new URLSearchParams(queryParamPath);
            console.log('urlParams: ' +urlParams);

            const startURL = urlParams.get('startURL');
            console.log('startURL: ' + startURL);

            if (startURL) {
                const startIndex = startURL.indexOf('?');
                if (startIndex !== -1) {
                    const nestedParams = startURL.substring(startIndex + 1);
                    console.log('nestedParams: ', nestedParams);
                    const nestedParamsArray = nestedParams.split('&');
                    for (const param of nestedParamsArray) {
                        const [key, value] = param.split('=');
                        console.log(key + ': ' + value);
                        if (key === 'autoLoginKey') {
                            this.autoLoginKey = value;
                        } else if (key === 'autoLoginValue') {
                            this.autoLoginValue = value;
                        }
                    }
                    if (this.autoLoginKey === this.labels.autoLoginKey && this.autoLoginValue === this.labels.autoLoginValue) {
                        this.userEmail = this.labels.autoLoginUn;
                        this.password = this.labels.autoLoginPs;
                        console.log('userEmail & password: ' + this.userEmail + ' ' + this.password);
                        this.handleLogin();
                    }
                }
            }
        }
    }
}