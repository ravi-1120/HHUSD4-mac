import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import isguest from '@salesforce/user/isGuest'
import bannerLogo from '@salesforce/resourceUrl/banner';
import SignupLogo from '@salesforce/resourceUrl/SignupLogo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPicklistValue from '@salesforce/apex/MSD_CORE_SignUpController.getPicklistValue';
import getOrganizations from '@salesforce/apex/MSD_CORE_RegistrationController.getOrganizations';
import createEligibility from '@salesforce/apex/MSD_CORE_SignUpController.createEligibility';
import updateEligibilityManualProcess from '@salesforce/apex/MSD_CORE_SignUpController.updateEligibilityManualProcess';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

export default class MSD_CORE_Signup extends LightningElement {
    bannerLogo = bannerLogo;
    signupHeroLogo = SignupLogo;
    decisionMaker = false;
    showError = false;
    showForm = false;
    accrecordId = '';
    orginput ='';
    @track orgName = '';
    orgIdinput = '';
    showConsultancy = false;
    fieldValueMap = {};
    domainurl = domainurl;
    typingTimer;
    doneTypingInterval = 300;
    @track consultantlist = [];

    fields = {
        FirstName: { fieldValue: '', required: true, error: false, errorMessage: 'First name is required', showLabel:false },
        LastName: { fieldValue: '', required: true, error: false, errorMessage: 'Last name is required', showLabel:false },
        Organization: { fieldValue: '', required: true, error: false, errorMessage: 'Please select an organization', showLabel:false },
        OrganizationType: { fieldValue: '', required: true, error: false, errorMessage: 'Please select an organization type', showLabel:false },
        WorkAddress: { fieldValue: '', required: true, error: false, errorMessage: 'Invalid work address', showLabel:false },
        Zip: { fieldValue: '', required: true, error: false, errorMessage: 'Invalid Zip', showLabel:false },
        City: { fieldValue: '', required: true, error: false, errorMessage: 'Invalid city', showLabel:false },
        State: { fieldValue: '', required: true, error: false, errorMessage: 'Please select a state', showLabel:false },
        Email: { fieldValue: '', required: true, error: false, errorMessage: 'Please use a valid email address', showLabel:false },
        Phone: { fieldValue: '', required: true, error: false, errorMessage: 'Phone number must be valid and contain 10 digits', showLabel:false },
        Role: { fieldValue: '', required: true, error: false, errorMessage: 'Please select a specific role', showLabel:false },
        Unit: { fieldValue: '', required: false, error: false, errorMessage: '', showLabel:false },
        PleaseSpecify: { fieldValue: '', required: false, error: false, errorMessage: '', showLabel:false }
    };

    @track rolelist = [];
    @track orgtypelist = [];
    @track statelist = [];
    @track stateexist = []; 
    @track orglist = [];
    @track portalType; //It contains either MFR or MHEE
    @track brandId;
    roleComboList = [];
    @track hcDMaker =''; //Health care decession Maker from Attestion Page
    @track roleBlockValues = ['Clinician / Physician', 'Government Relations Representative', 'Health Economist', 'Contracting manager / Director', 'Provider Relations Director', 'Quality Director', 'Trade / Industry Relations Director'];
    consultantYesNo = '';
    ptYesNo = '';


    get isGuestUser() {
        return isguest;  
    }

    get isRoleChanged() {
        return (this.fields.Role.fieldValue == 'Other' || this.fields.Role.fieldValue == 'Consultant' || (this.fields.Role.fieldValue != undefined && this.roleBlockValues.indexOf(this.fields.Role.fieldValue) != -1)) ? true : false;  
    }

    get showRoleBlock() {
        return (this.fields.Role.fieldValue != undefined && this.roleBlockValues.indexOf(this.fields.Role.fieldValue) != -1) ? true : false;
    }

    get showOtherRoleBlock() {
        return (this.fields.Role.fieldValue != undefined && this.fields.Role.fieldValue == 'Other') ? true : false;
    }

    get showConsultantRoleBlock() {
        return (this.fields.Role.fieldValue != undefined && this.fields.Role.fieldValue == 'Consultant') ? true : false;
    }

    get buttonText() {
        return (this.fields.Role.fieldValue != undefined && this.fields.Role.fieldValue == 'Consultant' && this.consultantYesNo == 'Yes') ? 'Continue' : 'Sign up';
    }

    get consultantChecked() {
        return this.consultantYesNo == 'Yes' ? true : false;
    }

    get ptChecked() {
        return this.ptYesNo == 'Yes' ? true : false;
    }

    get formatPhoneNumber() {
        this.fields.Phone.fieldValue = this.fields.Phone.fieldValue.replace(/\D/g,'').substring(0,10); //Strip everything but 1st 10 digits
        var size = this.fields.Phone.fieldValue.length;
        if (size>0) {this.fields.Phone.fieldValue="("+this.fields.Phone.fieldValue}
        if (size>3) {this.fields.Phone.fieldValue=this.fields.Phone.fieldValue.slice(0,4)+") "+this.fields.Phone.fieldValue.slice(4)}
        if (size>6) {this.fields.Phone.fieldValue=this.fields.Phone.fieldValue.slice(0,9)+"-" +this.fields.Phone.fieldValue.slice(9)}
        var cleaned = ('' + this.fields.Phone.fieldValue).replace(/\D/g, '');
        
        return this.fields.Phone.fieldValue;
    }

    connectedCallback() {
        if(!this.isGuestUser) {
            window.location.href = this.domainurl+'/dashboard';
        }

        this.showForm = true;
        this.getorgtype();
        this.getroles();
        this.getstates();
        this.getOrganizations();
    }

    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.accrecordId = currentPageReference.state.recordId;
            this.portalType = currentPageReference.state.pType;
            this.hcDMaker = currentPageReference.state.hcDMaker;
            this.brandId = currentPageReference.state.brandId;
        }
    }

    getorgtype(){
        getPicklistValue({ objectType: 'MSD_CORE_Eligibility__c', selectedField: 'MSD_CORE_Organization_Type__c' })
            .then(result => {
                this.orgtypelist = result;
        }).catch(error => {
            
        });
    };

    getroles(){
        getPicklistValue({ objectType: 'MSD_CORE_Eligibility__c', selectedField: 'MSD_CORE_Role__c' })
            .then(result => {
                this.rolelist = result;
        }).catch(error => {
            
        });
    };

    getstates(){
        getPicklistValue({ objectType: 'MSD_CORE_Eligibility__c', selectedField: 'MS_CORE_Organization_State_Code__c' })
            .then(result => {
                this.statelist = result;
                this.stateexist = this.statelist;
        }).catch(error => {
            
        });
    };

    getOrganizations(){
        getOrganizations({ searchKey: null }).then((result) => {
            this.orglist = [];
            this.orglist = result;
        })
    };

    privacyPolicy(event) {
        var labeluse = event.currentTarget.dataset.value;
        window.open(' https://www.msdprivacy.com/us/en/', '_blank').focus();
    }

    handleChange(event) {
        this.decisionMaker = event.target.checked;
    }

    handleRoleSelection(event) {
        this.consultantYesNo = event.currentTarget.dataset.id;
        this.template.querySelector('.checkmark-radio')?.classList.remove('required');
        this.template.querySelector('.checkmark-radio2')?.classList.remove('required');
    }

    handlePTSelection(event) {
        this.ptYesNo = event.currentTarget.dataset.id;
        this.template.querySelector('.checkmark-radio')?.classList.remove('required');
        this.template.querySelector('.checkmark-radio2')?.classList.remove('required');
    }

    handleSignUp(event) {
        this.showForm = false;
        var error = false;
        this.showError = false;
        
        if(!this.decisionMaker) {
            this.showError = true;
            error = true;
            this.template.querySelector('.checkmark').classList.add('required');
        }
        else {
            this.template.querySelector('.checkmark').classList.remove('required');
        }

        if(this.consultantYesNo == 'Yes' || this.consultantYesNo == 'No' || this.showConsultantRoleBlock == false) {
            this.template.querySelector('.checkmark-radio')?.classList.remove('required');
            this.template.querySelector('.checkmark-radio2')?.classList.remove('required');
        }
        else {
            this.showError = true;
            error = true;
            this.template.querySelector('.checkmark-radio')?.classList.add('required');
            this.template.querySelector('.checkmark-radio2')?.classList.add('required');
        }

        if(this.ptYesNo == 'Yes' || this.ptYesNo == 'No' || this.showRoleBlock == false) {
            this.template.querySelector('.checkmark-radio22')?.classList.remove('required');
            this.template.querySelector('.checkmark-radio222')?.classList.remove('required');
        }
        else {
            this.showError = true;
            error = true;
            this.template.querySelector('.checkmark-radio22')?.classList.add('required');
            this.template.querySelector('.checkmark-radio222')?.classList.add('required');
        }
        
        this.fields.FirstName.error = false;
        this.fields.LastName.error = false;
        this.fields.Organization.error = false;
        this.fields.OrganizationType.error = false;
        this.fields.WorkAddress.error = false;
        this.fields.Zip.error = false;
        this.fields.City.error = false;
        this.fields.State.error = false;
        this.fields.Email.error = false;
        this.fields.Phone.error = false;
        this.fields.Role.error = false;

        this.template.querySelector(`[data-id="FirstName"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="FirstName2"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="LastName"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="LastName2"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="Organization"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="OrganizationType"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="WorkAddress"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="Zip"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="City"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="State"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="Zip2"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="City2"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="State2"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="Email"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="Phone"]`)?.classList.remove('required');
        this.template.querySelector(`[data-id="Role"]`)?.classList.remove('required');
        
        if(this.fields.FirstName.fieldValue.trim() == '') {
            this.fields.FirstName.error = true;
            error = true;
            this.template.querySelector(`[data-id="FirstName"]`)?.classList.add('required');
            this.template.querySelector(`[data-id="FirstName2"]`)?.classList.add('required');
        }
        if(this.fields.LastName.fieldValue.trim() == '') {
            this.fields.LastName.error = true;
            error = true;
            this.template.querySelector(`[data-id="LastName"]`)?.classList.add('required');
            this.template.querySelector(`[data-id="LastName2"]`)?.classList.add('required');
        }
        if(this.fields.Organization.fieldValue.trim() == '') {
            this.fields.Organization.error = true;
            error = true;
            this.template.querySelector(`[data-id="Organization"]`)?.classList.add('required');
        }
        if(this.fields.OrganizationType.fieldValue.trim() == '') {
            this.fields.OrganizationType.error = true;
            error = true;
            this.template.querySelector(`[data-id="OrganizationType"]`)?.classList.add('required');
        }
        if(this.fields.WorkAddress.fieldValue.trim() == '') {
            this.fields.WorkAddress.error = true;
            error = true;
            this.template.querySelector(`[data-id="WorkAddress"]`)?.classList.add('required');
        }
        if(this.fields.Zip.fieldValue.trim() == '') {
            this.fields.Zip.error = true;
            error = true;
            this.template.querySelector(`[data-id="Zip"]`)?.classList.add('required');
            this.template.querySelector(`[data-id="Zip2"]`)?.classList.add('required');
        }
        if(this.fields.City.fieldValue.trim() == '') {
            this.fields.City.error = true;
            error = true;
            this.template.querySelector(`[data-id="City"]`)?.classList.add('required');
            this.template.querySelector(`[data-id="City2"]`)?.classList.add('required');
        }
        if(this.fields.State.fieldValue.trim() == '') {
            this.fields.State.error = true;
            error = true;
            this.template.querySelector(`[data-id="State"]`)?.classList.add('required');
            this.template.querySelector(`[data-id="State2"]`)?.classList.add('required');
        }
        if(this.fields.Email.fieldValue.trim() == '') {
            this.fields.Email.error = true;
            error = true;
            this.template.querySelector(`[data-id="Email"]`)?.classList.add('required');
        }
        if(this.fields.Phone.fieldValue.trim() == '') {
            this.fields.Phone.error = true;
            error = true;
            this.template.querySelector(`[data-id="Phone"]`)?.classList.add('required');
        }
        if(this.fields.Role.fieldValue.trim() == '') {
            this.fields.Role.error = true;
            error = true;
            this.template.querySelector(`[data-id="Role"]`)?.classList.add('required');
        }

        if(!error) {
            this.fieldValueMap = {};
            Object.entries(this.fields).forEach(([key, value]) => {
                this.fieldValueMap[key] = value.fieldValue;
            });

            this.showConsultancy = false;
            
            createEligibility({ accountid: this.accrecordId, data: JSON.stringify(this.fieldValueMap), consultantChecked: this.consultantChecked, ptChecked: this.ptChecked, hcDMakerChecked: this.hcDMaker, portalType: this.portalType, orgListJSON: '' })
                .then(result => {
                    if (result && Object.keys(result).length === 1) {
                        const accountId = Object.keys(result)[0];
                        const isApprovalNeeded = result[accountId];
                        if (accountId && accountId.trim() !== '') {
                            this.accrecordId = accountId; 
                        }

                        if (isApprovalNeeded === true) {
                            //Manual Approval
                            if(this.fields.Role.fieldValue == 'Consultant' && this.consultantYesNo == 'Yes')
                            {
                                var url = this.domainurl+'/organic-consultancy-information' + this.addParameters() + '&email=' + this.fields.Email.fieldValue;
        
                                window.location.href = url;
                            }
                            else
                            {
                                this.updateEligibilityAndRedirect();
                            }
                        }
                        else {
                            //Auto approval
                            this.updateEligibilityAndRedirecttoVerify();
                        }
                    }
                    else {
                        console.log('Invalid result format or no result found.');
                    }
            }).catch(error => {
                let errorMessage = '';
                if ( error.body.message) {
                    errorMessage = error.body.message;
                }
                this.showToast('Something went wrong', errorMessage, 'error');
            });
        }
        this.showForm = true;
    }

    goToSignUp() {
        this.showConsultancy = false;
    }

    showToast(theTitle, theMessage, theVariant) {
        const event = new ShowToastEvent({
            title: theTitle,
            message: theMessage,
            variant: theVariant
        });
        this.dispatchEvent(event);
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

        if(id == 'Phone') this.validatePhoneNumber();
        if(id == 'Email') this.validateEmail();

        this.showForm = true;
    }

    inputtrim(event){
        const phoneInput = this.template.querySelector('input[data-id="Phone"]');
        if (phoneInput) {
            const trimmedValue = phoneInput.value.replace(/\D/g, '');
            phoneInput.value = trimmedValue;
            console.log('Trimmed value:', trimmedValue);
        }
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

    validatePhoneNumber() {
        this.fields.Phone.fieldValue = this.fields.Phone.fieldValue.replace(/\D/g,'').substring(0,10); //Strip everything but 1st 10 digits
        var size = this.fields.Phone.fieldValue.length;
        if (size>0) {this.fields.Phone.fieldValue="("+this.fields.Phone.fieldValue}
        if (size>3) {this.fields.Phone.fieldValue=this.fields.Phone.fieldValue.slice(0,4)+") "+this.fields.Phone.fieldValue.slice(4)}
        if (size>6) {this.fields.Phone.fieldValue=this.fields.Phone.fieldValue.slice(0,9)+"-" +this.fields.Phone.fieldValue.slice(9)}
        var cleaned = ('' + this.fields.Phone.fieldValue).replace(/\D/g, '');
        var match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);
        if (match) {
            this.fields.Phone.error = false;
        }else{
            this.fields.Phone.error = true;
        }
    }

    validateEmail() {
        const regex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$/;
        var match = regex.test(this.fields.Email.fieldValue);

        if (match) {
            this.fields.Email.error = false;
        }else{
            this.fields.Email.error = true;
        }
    }

    onlyNumberKey(event) {
        // Only ASCII character in that range allowed
        this.validatePhoneNumber();
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

        const inputElement = this.template.querySelector('[data-id="Organization"]');
        if (inputElement) {
            // Set the value of the input element
            inputElement.value = event.currentTarget.attributes.value.value;
        }
    }

    handleOrgChange(event) {
        this.orgIdinput = event.target.value;
        this.fields.Organization.fieldValue = event.target.value;
    }

    handleSeachKeyChangeDebounced(event){
        let value = event.target.value;
            
        getOrganizations({ searchKey: value }).then((result) => {
            this.orglist = [];
            this.orglist = result;
        })
    }

    handleSearch(event){
        if(!this.orginput){
            getOrganizations({ searchKey: null }).then((result) => {
                this.orglist = [];
                this.orglist = result;
            }) 
        }
    }

    loginClick() {
        var url = this.domainurl+'/organic-login' + this.addParameters();
        
        window.location.href = url;
    }

    // Update eligibility status and redirect
    updateEligibilityAndRedirect() {
        updateEligibilityManualProcess({ accountid: this.accrecordId })
        .then(result => {
            window.location.href = this.domainurl+'/organic-thank-you';
        })
        .catch(error => {
            console.error('Error updating eligibility status:', error);
            this.showToast('Something went wrong', 'Unable to update eligibility status', 'error');
        });
    }

    // Update eligibility status and redirect
    updateEligibilityAndRedirecttoVerify() {
        updateEligibilityManualProcess({ accountid: this.accrecordId })
        .then(result => {
            var url = this.domainurl+'/organic-verify-email' + this.addParameters() + '&email=' + this.fields.Email.fieldValue;
        
            window.location.href = url;
        })
        .catch(error => {
            console.error('Error updating eligibility status:', error);
            this.showToast('Something went wrong', 'Unable to update eligibility status', 'error');
        });
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