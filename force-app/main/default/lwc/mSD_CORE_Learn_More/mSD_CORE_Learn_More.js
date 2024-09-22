import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import isguest from '@salesforce/user/isGuest';
import LearnMoreWorkingRemoteImage from '@salesforce/resourceUrl/LearnMoreWorkingRemoteImage';
import LearnMoreRelentlessImage from '@salesforce/resourceUrl/LearnMoreRelentlessImage';
import LearnMoreBackgroundGreenIcon from '@salesforce/resourceUrl/LearnMoreBackgroundGreenIcon';
import LearnMoreUserIcon from '@salesforce/resourceUrl/LearnMoreUserIcon';
import LearnMoreDesktopIcon from '@salesforce/resourceUrl/LearnMoreDesktopIcon';
import LearnMoreInfoIcon from '@salesforce/resourceUrl/LearnMoreInfoIcon';
import LearnMorePlusIcon from '@salesforce/resourceUrl/LearnMorePlusIcon';
import LearnMoreMinusIcon from '@salesforce/resourceUrl/LearnMoreMinusIcon';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

export default class MSD_CORE_Learn_More extends LightningElement {

    learnMoreWorkingRemote = LearnMoreWorkingRemoteImage;
    learnMoreRelentless = LearnMoreRelentlessImage;
    learnMoreBackgroundGreen = LearnMoreBackgroundGreenIcon;
    learnMoreUser = LearnMoreUserIcon;
    learnMoreDesktop = LearnMoreDesktopIcon;
    learnMoreInfo = LearnMoreInfoIcon;
    learnMorePlus = LearnMorePlusIcon;
    learnMoreMinus = LearnMoreMinusIcon;
    domainurl = domainurl;
    showBenefits = false;
    showAddResources = false;
    showPortal = false;
    showFormularyResources = false;

    @track accountId;
    @track portalType;
    @track brandId;
    signupLinkHref = '';

    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.emailReceivedFromSignup = currentPageReference.state.email;
            this.accountId = currentPageReference.state.recordId;
            this.portalType = currentPageReference.state.pType;
            this.brandId = currentPageReference.state.brandId;
            
            // Call method to set href dynamically
            this.setSignupLinkHref();
        }
    }

    connectedCallback() {
        if(!this.isGuestUser) {
            //const previousPageUrl = document.referrer;
            const currentPageUrl = window.location.href;
            console.log('Previous Page URL:', previousPageUrl);
            console.log('Previous Page URL:', currentPageUrl);
            if (this.currentPageUrl.includes('dashboard=no')){
                console.log('organicpageurl');
                return;
                // window.location.href = this.domainurl+'/organic-learn-more';
            }else{
                window.location.href = this.domainurl+'/dashboard';
                console.log('dashboardpageurl');
                // window.location.assign(this.domainurl+'/dashboard');
                
                
            }
        }
        this.setSignupLinkHref();
    }

    // renderCallback() {
    //     const previousPageUrl = document.referrer;
    //         console.log('Previous Page URL:', previousPageUrl);
    //         if (this.previousPageUrl == 'https://msdlogin--hhusd3.sandbox.my.site.com/merckmhee/'){
    //             console.log('organicpageurl');
              
    //             window.location.href = this.domainurl+'/organic-learn-more';
    //         }
    // }

    // Method to set the href dynamically
    setSignupLinkHref() {
        var url = this.domainurl+'/organic-attestation' + this.addParameters();
        
        this.signupLinkHref = url;
    }

    singnupclick() {
       window.location.href = this.signupLinkHref;
    }

    get isGuestUser() {
        return isguest;  
    }

    toggleBenefits() {
        this.showBenefits = (this.showBenefits ? false : true);
    }

    toggleAddResources() {
        this.showAddResources = (this.showAddResources ? false : true);
    }

    togglePortal() {
        this.showPortal = (this.showPortal ? false : true);
    }

    toggleFormularyResources() {
        this.showFormularyResources = (this.showFormularyResources ? false : true);
    }

    reloadPage() {
        var url = this.domainurl+'/organic-learn-more' + this.addParameters();
        
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