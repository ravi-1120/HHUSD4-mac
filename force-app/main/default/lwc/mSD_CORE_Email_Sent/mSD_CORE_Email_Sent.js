import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import bannerLogo from '@salesforce/resourceUrl/banner';
import SignupSubmit_Logo from '@salesforce/resourceUrl/SignupSubmit_Logo';
import SignupSubmit_Logo1 from '@salesforce/resourceUrl/SignupSubmit_Logo1';
import forgotpasswordverify from '@salesforce/apex/CommunityAuthController.forgotpasswordverify';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
import isguest from '@salesforce/user/isGuest';

export default class MSD_CORE_Email_Sent extends LightningElement {
    bannerLogo = bannerLogo;
    SignupSubmit_Logo = SignupSubmit_Logo;
    SignupSubmit_Logo1= SignupSubmit_Logo1;
    navigatelearnmore;
    navigatelearnmorename;
    navigatesingup;
    navigatesingupname;
    navigatelogin;
    navigateloginname;
    navigateWelcome;
    navigateWelcomeName;
    @track emailrecvd;
    domainurl = domainurl;

    connectedCallback() {
        if(!this.isGuestUser) {
            window.location.href = this.domainurl+'/dashboard';
        }
    }
    
    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.emailrecvd = currentPageReference.state.email;
        }
    }
    
    get isGuestUser() {
        return isguest;  
    }
    welcomePageClick() {
        window.location.href = this.navigateWelcome;
    }

    // for onlclick on singup button
    sinupclick(){
        window.location.href = this.navigatesingup;
    }

    // for onlclick on login button
    loginclick(){
        window.location.href = this.domainurl+'/organic-login';
    }

    userResetPassword() {
        forgotpasswordverify({emailval: this.emailrecvd})
        .then((result) => {
            if (result != 'Reset Password Link Sent successfully!') {
                this.emailerrormsg = true;
                this.errormsgtext = 'Please enter a valid email address';
            } else {
                this.emailerrormsg = false;
                this.errormsgtext = '';
                this.confirmpage = true;
            }
        })
        .catch((error) => {
            console.log('error of resetPassword-->',{error});
            this.emailerrormsg = true;
        })
    }
}