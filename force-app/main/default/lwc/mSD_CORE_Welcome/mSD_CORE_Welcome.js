import { LightningElement, wire, track } from 'lwc';
import bannerLogo from '@salesforce/resourceUrl/banner';
import Welcomelogo from '@salesforce/resourceUrl/Welcomelogo';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
import { CurrentPageReference } from 'lightning/navigation';
import isguest from '@salesforce/user/isGuest';

export default class MSD_CORE_Welcome extends LightningElement {
    bannerLogo = bannerLogo;
    Welcomelogo = Welcomelogo;
    domainurl = domainurl;
    //samplegif = samplegif;
    navigatelearnmore;
    navigatelearnmorename;
    navigatesingup;
    navigatesingupname;
    navigateattestation;
    navigateattestationname;
    navigatelogin;
    navigateloginname;
    @track accountId;//Account Id
    @track portalType;
    @track brandId;
    connectedCallback() {
        if(!this.isGuestUser) {
            window.location.href = this.domainurl+'/dashboard';
        }
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
    
    sinupclick() {
        var url = this.domainurl+'/organic-attestation' + this.addParameters();
        
        window.location.href = url;
    }

    loginclick() {
        var url = this.domainurl+'/organic-login' + this.addParameters();
        
        window.location.href = url;
    }

    learnmoreClick() {
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