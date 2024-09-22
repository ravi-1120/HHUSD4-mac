import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import isguest from '@salesforce/user/isGuest'
import bannerLogo from '@salesforce/resourceUrl/banner';
import SignupLogo from '@salesforce/resourceUrl/SignupLogo';
import LearnMorePlusIcon from '@salesforce/resourceUrl/LearnMorePlusIcon';
import LearnMoreMinusIcon from '@salesforce/resourceUrl/ConsultancyInfoRedMinusIcon';
import ConsultancyInfoBackArrow from '@salesforce/resourceUrl/ConsultancyInfoBackArrow';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
import getPicklistValue from '@salesforce/apex/MSD_CORE_SignUpController.getPicklistValue';
import getOrganizations from '@salesforce/apex/MSD_CORE_SignUpController.getOrganizations';
import createEligibilityConsultancy from '@salesforce/apex/MSD_CORE_SignUpController.createEligibilityConsultancy';

export default class Msd_CORE_Consultancy_Information extends LightningElement {
    @track organizations = [];
    @api fieldValueMap = {};
    @api accrecordId;
    @api consultantChecked;
    @api ptChecked;
    @track accountId;
    @track portalType;
    @track brandId;
    dataMap = {};

    bannerLogo = bannerLogo;
    signupHeroLogo = SignupLogo;
    learnMorePlus = LearnMorePlusIcon;
    learnMoreMinus = LearnMoreMinusIcon;
    consultancyInfoBackArrow = ConsultancyInfoBackArrow;
    decisionMaker = false;
    showError = false;
    showForm = false;
    domainurl = domainurl;
    orginput ='';
    orgIdinput = '';

    fields = {
        ConsultancyAgency: { fieldValue: '', required: true, error: false, errorMessage: 'Consultancy agency is required', showLabel:false },
        AgencyEmail: { fieldValue: '', required: true, error: false, errorMessage: 'Please use a valid agency email address', showLabel:false },
        Organization: { fieldValue: '', required: true, error: false, errorMessage: 'Please select an organization', showLabel:false },
        OrganizationType: { fieldValue: '', required: true, error: false, errorMessage: 'Please select an organization type', showLabel:false },
        OrganizationEmail: { fieldValue: '', required: true, error: false, errorMessage: 'Please use a valid organization email address', showLabel:false }
    };

    @track rolelist = [];
    @track orgtypelist = [];
    @track statelist = [];
    @track stateexist = []; //INC2747384
    @track orglist = [];
    
    roleComboList = [];

    @track roleBlockValues = ['Clinician / Physician', 'Government relations representative', 'Health economist', 'Provider relations director', 'Quality director', 'Contracting manager / Director','Trade / Industry relations director'];
    consultantYesNo = '';

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

    get buttonText() {
        return 'Sign up';
    }

    connectedCallback() {
        if(!this.isGuestUser) {
            window.location.href = this.domainurl+'/dashboard';
        }

        this.showForm = true;
        this.dataMap = {...this.fieldValueMap};
        this.getOrganizations();
        this.getorgtype();
    }

    getOrganizations(){
        getOrganizations({ searchKey: null }).then((result) => {
            this.orglist = [];
            this.orglist = result;
        })
    };

    getorgtype(){
        getPicklistValue({ objectType: 'MSD_CORE_Eligibility__c', selectedField: 'MSD_CORE_Organization_Type__c' })
            .then(result => {
            this.orgtypelist = result;
        }).catch(error => {
            
        });
    };

    privacyPolicy(event) {
        var labeluse = event.currentTarget.dataset.value;
        window.open(' https://www.msdprivacy.com/us/en/', '_blank').focus();
    }

    handleChange(event) {
        this.decisionMaker = event.target.checked;
        if(this.decisionMaker){
            this.template.querySelector('.checkmark').classList.remove('required');
            this.showError = false;
        }
    }

    handleRoleSelection(event) {
        this.consultantYesNo = event.currentTarget.dataset.id;
        this.template.querySelector('.checkmark-radio')?.classList.remove('required');
        this.template.querySelector('.checkmark-radio2')?.classList.remove('required');
    }

    handleSignUp(event) {
        var error = false;
        
        if(this.fields.Organization.fieldValue.trim() != '') {
            this.dataMap['Organization'] = this.fields.Organization.fieldValue;
        }

        if(this.fields.OrganizationType.fieldValue.trim() != '') {
             this.dataMap['OrganizationType'] = this.fields.OrganizationType.fieldValue;
        }

        if(this.fields.OrganizationEmail.fieldValue.trim() != '') {
             this.dataMap['OrganizationEmail'] = this.fields.OrganizationEmail.fieldValue;
        }

        if(this.fields.ConsultancyAgency.fieldValue.trim() != '') {
            this.dataMap['ConsultancyAgency'] = this.fields.ConsultancyAgency.fieldValue;
        }else{
            this.template.querySelector(`[data-id="ConsultancyAgency"]`)?.classList.add('required');
            this.fields.ConsultancyAgency.error = true;
            error = true;
        }
        
        if(this.fields.AgencyEmail.fieldValue.trim() != '') {
            this.dataMap['AgencyEmail'] = this.fields.AgencyEmail.fieldValue;
        }else{
            this.template.querySelector(`[data-id="AgencyEmail"]`)?.classList.add('required');
            this.fields.AgencyEmail.error = true;
            error = true;
        } 

        if(!this.decisionMaker) {
            this.showError = true;
            error = true;
            this.template.querySelector('.checkmark').classList.add('required');
        }

        if(!error){
            createEligibilityConsultancy({ accountid: this.accountId, data: JSON.stringify(this.dataMap), consultantChecked: this.consultantChecked, ptChecked: this.ptChecked, hdMakerChecked: this.hcDMakerChecked, portalType: this.portalType, orgListJSON : JSON.stringify(this.organizations) })            
            .then(result => {   
            window.location.href = this.domainurl+'/organic-thank-you';
        }).catch(error => {
            let errorMessage = '';
            if ( error.body.message) {
                errorMessage = error.body.message;
            }
            
            this.showToast('Something went wrong', errorMessage, 'error');
        });
        }else{
            this.showForm = true;
        }
    }

    handleInputChange(event){
        this.showForm = false;
        var vl = event.target.value;
        var id = event.currentTarget.dataset.id;
        var formattedId = id.replace('2', '');

        this.fields[formattedId].fieldValue = vl;
        this.fields[formattedId].error = false;
        this.template.querySelector(`[data-id="${id}"]`)?.classList.remove('required');

        if(vl.trim() == '') {
            this.fields[formattedId].error = true;
            this.fields[formattedId].showLabel = false;
            this.template.querySelector(`[data-id="${id}"]`)?.classList.add('required');
        }
        else {
            this.fields[formattedId].showLabel = true;
        }

        if(id == 'AgencyEmail') this.validateEmail();
        if(id == 'OrganizationEmail') this.validateEmail();
        this.showForm = true;
    }

    handleOrgInputChange(event){
        this.showForm = false;
        var vl = event.target.value;
        var id = event.currentTarget.dataset.id;
        var indx = event.currentTarget.dataset.index;
        var formattedId = id.replace('2', '');

        this.organizations[indx][formattedId].fieldValue = vl;

        this.showForm = true;
    }

    handleInputFocus(event){
        this.showForm = false;
        var vl = event.target.value;
        var id = event.currentTarget.dataset.id;
        var formattedId = id.replace('2', '');

        if(vl.trim() == '') {
            this.fields[formattedId].showLabel = false;
        }
        else {
            this.fields[formattedId].showLabel = true;
        }

        this.showForm = true;
    }

    validateEmail() {
        const regex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$/;
        var match = regex.test(this.fields.AgencyEmail.fieldValue);

        if (match) {
            this.fields.AgencyEmail.error = false;
        }else{
            this.fields.AgencyEmail.error = true;
        }
    }

    onlyNumberKey(event) {
        // Only ASCII character in that range allowed
    }

    addOrganization(event) {
        const newOrg = {
            Organization: { fieldValue: '', required: true, error: false, errorMessage: 'Please select an organization', showLabel:false },
            OrganizationType: { fieldValue: '', required: true, error: false, errorMessage: 'Please select an organization type', showLabel:false },
            OrganizationEmail: { fieldValue: '', required: true, error: false, errorMessage: 'Please use a valid organization email address', showLabel:false }
        };
        
        this.organizations = [...this.organizations, newOrg];
    }

    removeOrganization(event) {
        var id = event.currentTarget.dataset.id;
        var tempArr = [];
        
        for(var i=0; i < this.organizations.length; i++) {
            if(i != parseInt(id)) {
                tempArr.push(this.organizations[i]);
            }
        }

        this.organizations = [];
        this.organizations = tempArr;
    }

    goToLogin() {
        var url = this.domainurl+'/organic-login' + this.addParameters();
        
        window.location.href = url;
    }

    goToSignUp() {
        let ev = new CustomEvent('signup', {detail : ''});
        this.dispatchEvent(ev); 
    }

    handleDefaults(event){
        let dropdownitems = this.template.querySelectorAll('.slds-dropdown-trigger');
        dropdownitems.forEach((el) => {
            el.classList.remove('slds-is-open');
        });
    }

    handleDropdown(event){
        const evt = event.currentTarget;
        evt.classList.toggle('slds-is-open');
    }

    handleOrg(event) {
        this.orginput = event.currentTarget.attributes.value.value;
        this.orgIdinput = event.currentTarget.dataset.id;
        this.fields.Organization.fieldValue = event.currentTarget.dataset.id;
    }

    handleOrgChange(event) {
        this.orginput = event.target.value;
        this.orgIdinput = event.target.value;
        this.fields.Organization.fieldValue = event.target.value;
    }

    handleOrgClick(event) {
        this.showForm = false;
       
        var vl = event.currentTarget.attributes.value.value;
        var id = event.currentTarget.dataset.id;
        var indx = event.currentTarget.dataset.index;
        
        this.organizations[indx].Organization.fieldValue = vl;

        this.showForm = true;
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