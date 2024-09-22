import { LightningElement,api,wire, track } from 'lwc';
export default class MSD_CORE_RegistrationProgress extends LightningElement {
    @api pageName = 'Eligibility';
    @track isPassword = false;
    @track isEligibility = false;
    @track isPersonal = false;
    @track isSuccess = false;
    @track isPasswordComplete = false;
    @track isEligibilityComplete = false;
    @track isPersonalComplete = false;
    @track isSuccessComplete = false;
    mobilescreen = false;
    renderedCallback(){
        if(this.pageName == 'Password'){
                this.isPassword = true;
                this.isEligibility = false;
                this.isPersonal = false;
                this.isSuccess = false;
                this.isPasswordComplete = false;
                this.isEligibilityComplete = false;
                this.isPersonalComplete = false;
                this.isSuccessComplete = false;
                
        }
        else if(this.pageName == 'Eligibility'){
                this.isPassword = false;
                this.isEligibility = true;
                this.isPersonal = false;
                this.isSuccess = false;
                this.isPasswordComplete = true;
                this.isEligibilityComplete = false;
                this.isPersonalComplete = false;
                this.isSuccessComplete = false;
        }
        else if(this.pageName == 'Personal'){
                this.isPassword = false;
                this.isEligibility = false;
                this.isPersonal = true;
                this.isSuccess = false;
                this.isPasswordComplete = true;
                this.isEligibilityComplete = true;
                this.isPersonalComplete = false;
                this.isSuccessComplete = false;
        }
        else if(this.pageName == 'Success'){
                this.isPassword = false;
                this.isEligibility = false;
                this.isPersonal = false;
                this.isSuccess = true;
                this.isPasswordComplete = true;
                this.isEligibilityComplete = true;
                this.isPersonalComplete = true;
                this.isSuccessComplete = false;
        }
    }

    connectedCallback() {
           var screenwidth = (window.innerWidth > 0) ? window.innerWidth : screen.width;
                if (screenwidth > 768) {
                this.mobilescreen = false;
                console.log('system Screen size is '+this.mobilescreen);
                } else {
                this.mobilescreen = true;
                console.log('Mobile Screen size is '+this.mobilescreen);
                }
    }
}