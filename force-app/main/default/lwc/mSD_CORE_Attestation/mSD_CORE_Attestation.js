import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import isguest from '@salesforce/user/isGuest'
import bannerLogo from '@salesforce/resourceUrl/banner';
import AttestationImage from '@salesforce/resourceUrl/AttestationImage';
import Attestationstylesheet from '@salesforce/resourceUrl/Attestationstylesheet';
import crossmark from '@salesforce/resourceUrl/cross';
import { loadStyle } from 'lightning/platformResourceLoader';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

export default class MSD_CORE_Attestation extends LightningElement {

    bannerLogo = bannerLogo;
    AttestationHeroImage = AttestationImage;
    decisionMaker = false;
    showError = false;
    cross = crossmark;
    @track value;
    @track isShowModal = false;
    // @track mercksupport = '';
    @track accountId;//Account Id
    @track portalType;
    domainurl = domainurl;
    @track mycontacts = 'https://www.merck.com/contact-us/';
    @track brandId;

    connectedCallback() {
        if(!this.isGuestUser) {
            window.location.href = this.domainurl+'/dashboard';
        }

        Promise.all([
            loadStyle(this, Attestationstylesheet)
        ])
        this.getsitename(); // to bring api names and urls of all pages dynamically
        
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

    handleChange(event) {
        this.decisionMaker = event.target.checked;
    }

    handleClose() {
        var url = this.domainurl+'/organic-welcome' + this.addParameters();
        
        window.location.href = url;
    }

    handlesupport(){
        window.location.href = this.domainurl+'/my-contacts';
    }

    handleLogin(){
        var url = this.domainurl+'/organic-login' + this.addParameters();
        
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

    handleContinue(event) {
        if(this.value === 'Yes'){
            this.uncheckRadioButtons();

            var url = this.domainurl+'/organic-signup' + this.addParameters() + '&hcDMaker=Yes';
        
            window.location.href = url;
        }
        else if (this.value === 'No'){
            this.isShowModal = true;
        }
        else {
            this.showError = true;
            this.template.querySelector('.checkmark-radio')?.classList.add('required');
            this.template.querySelector('.checkmark-radio2')?.classList.add('required');
            this.template.querySelector('.checkmark-radio3')?.classList.add('required');
            this.template.querySelector('.checkmark-radio4')?.classList.add('required');
        }
    }

    get options() {
        return [
            { label: 'Yes, I am a health care decision maker.', value: 'YES' },
            { label: 'No, I am not a health care decision maker.', value: 'NO' },
        ];
    }

    // Handler for the change event
    handleChangeradio(event) {
        this.value = event.detail.value;
    }

    closeModal(){
        this.handleClose();
    }

    uncheckRadioButtons() {
        const radioYes = this.template.querySelector('input[data-id="Yes"]');
        const radioNo = this.template.querySelector('input[data-id="No"]');

        if (radioYes) {
            radioYes.checked = false;
        }
        if (radioNo) {
            radioNo.checked = false;
        }
    }

    handleRoleSelection(event) {
        this.value = event.currentTarget.dataset.id;
        this.showError = false;
        
        this.template.querySelector('.checkmark-radio')?.classList.remove('required');
        this.template.querySelector('.checkmark-radio2')?.classList.remove('required');
        this.template.querySelector('.checkmark-radio3')?.classList.remove('required');
        this.template.querySelector('.checkmark-radio4')?.classList.remove('required');
    }
}