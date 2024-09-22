import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import bannerLogo from '@salesforce/resourceUrl/banner';
import Welcomelogo from '@salesforce/resourceUrl/Welcomelogo';
import createpasswordcss from '@salesforce/resourceUrl/createpasswordcss';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
import Loginnewmoblogo from '@salesforce/resourceUrl/Loginnewmoblogo';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName'; // to bring api names and urls of all pages dynamically
import loginverification from '@salesforce/apex/CommunityAuthController.loginverification';
import { loadStyle } from 'lightning/platformResourceLoader';
import isguest from '@salesforce/user/isGuest';

export default class MSD_CORE_LoginNew extends LightningElement {

    bannerLogo = bannerLogo;
    Welcomelogo = Welcomelogo;
    domainurl = domainurl;
    Loginnewmoblogo = Loginnewmoblogo;
    navigatelearnmore;
    navigatelearnmorename;
    welcomelink;
    welcomeapiname;
    ForgotpasswordNewlink;
    ForgotpasswordNewapiname;
    @track inputType = 'password';
    @track password = '';
    @track emailinp = '';
    @track isChecked;
    @track checkval = true;
    @track subscribe = false;
    @track userinformation;
    @track iserror = false;
    @track emailclass = 'emailcls';
    @track passwordclass = 'input-container';
    eyeIcon = 'utility:hide';
    @track accountId;//Account Id
    @track portalType;
    @track brandId;

    showPasswordLabel = false;
    showEmailLabel = false;

    connectedCallback() {
        if(!this.isGuestUser) {
            window.location.href = this.domainurl+'/dashboard';
        }

        Promise.all([
            loadStyle(this, createpasswordcss)
        ])
        this.getsitename(); // to bring api names and urls of all pages dynamically
        this.getCookieValue(); // getting the cookie values
    }

    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.portalType = currentPageReference.state.pType;
            this.accountId = currentPageReference.state.recordId;
            this.brandId = currentPageReference.state.brandId;
        }
    }

    get isGuestUser() {
        return isguest;  
    }
    
    // saving the email ans password to browser cookie
    saveToCookie() {
        const cookieName = 'MFRCookie';
        const cookieValue = JSON.stringify({
            email: this.emailinp,
            password: this.password
        });
        const daysToExpire = 30;
        this.setCookie(cookieName, cookieValue, daysToExpire);
    }

    setCookie(name, value, days) {
        let expires = "";
        if (days) {
            const date = new Date();
            date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
            expires = "; expires=" + date.toUTCString();
        }
        document.cookie = name + "=" + (value || "")  + expires + "; path=/";
    }

    // getting the email ans password from browser cookie
    getCookieValue() {
        const cookieValue = this.getCookie('MFRCookie');
        if (cookieValue) {
            const cookieData = JSON.parse(cookieValue);
            this.emailinp = cookieData.email;
            this.password = cookieData.password;
        }
    }

    getCookie(name) {
        const nameEQ = name + "=";
        const ca = document.cookie.split(';');
        for (let i = 0; i < ca.length; i++) {
            let c = ca[i];
            while (c.charAt(0) === ' ') c = c.substring(1, c.length);
            if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
        }
        return null;
    }

    getsitename() {
        getSiteNameAndAPIName({ pageName: 'Learnmore' })
            .then((result) => {
                this.navigatelearnmore = this.addURLParameters(result.siteAPIName);
                this.navigatelearnmorename = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });

        getSiteNameAndAPIName({ pageName: 'Attestation' })
            .then((result) => {
                this.welcomelink = this.addURLParameters(result.siteAPIName);
                this.welcomeapiname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
        
        getSiteNameAndAPIName({ pageName: 'ForgotpasswordNew' })
            .then((result) => {
                this.ForgotpasswordNewlink = result.siteAPIName;
                this.ForgotpasswordNewapiname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }

    addURLParameters(url) {
        if (!url.includes('?')) {
            url += '?';
        } else {
            url += '&';
        }
        url += 'pType=' + this.portalType + '&recordId=' + this.accountId;
        return url;
    }

    togglePasswordVisibility() {
        this.inputType = this.inputType === 'password' ? 'text' : 'password';
        this.eyeIcon = this.inputType === 'password' ? 'utility:hide' : 'utility:preview';
    }

    handleChange(event) {
        this.emailinp = event.target.value;
        if (this.emailinp.trim() == '') {
            this.showEmailLabel = false;
        }
        else {
            this.showEmailLabel = true;
        }
    }

    handlepasword(event) {
        this.password = event.target.value;
        if (this.password.trim() == '') {
            this.showPasswordLabel = false;
        }
        else {
            this.showPasswordLabel = true;
        }
    }

    handleCheckboxChange(event) {
        this.subscribe = event.target.checked;
    }

    handlelogin(event) {
        if(this.subscribe == true && this.emailinp && this.password){
            this.saveToCookie(); // setting the cookie value
        }
        if (this.emailinp && this.password) {
            event.preventDefault();
            loginverification({ emailval: this.emailinp, passval: this.password, remberval: this.subscribe, brandId: this.brandId })
                .then(result => {
                    if (result.startsWith('http')) {
                        this.iserror = false;
                        this.emailclass = 'emailcls';
                        this.passwordclass = 'input-container';
                        window.location.href = result;
                    } else {
                        console.log('ELSE');
                    }
                })
                .catch(error => {
                    console.log('error' + JSON.stringify(error));
                    this.iserror = true;
                    this.emailclass = 'emailclserror';
                    this.passwordclass = 'input-container1';
                });

        } else {
            this.iserror = true;
            this.emailclass = 'emailclserror';
            this.passwordclass = 'input-container1';
        }
    }

    learnmoreClick() {
        var url = this.domainurl+'/organic-learn-more' + this.addParameters();
        
        window.location.href = url;
    }

    forgotpasswordClick() {
        var url = this.domainurl+'/organic-forgot-password' + this.addParameters();
        
        window.location.href = url;
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
}