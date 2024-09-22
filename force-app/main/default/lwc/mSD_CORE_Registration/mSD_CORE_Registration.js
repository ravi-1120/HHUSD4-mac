import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import mercklogo from '@salesforce/resourceUrl/MSD_CORE_MerckImage';
import jobcode from '@salesforce/label/c.nonbrandjobcode';
import checkExistingUser from '@salesforce/apex/MSD_CORE_RegistrationController.checkExistingUser';
import createOTP from '@salesforce/apex/MSD_CORE_RegistrationController.createOTP';

export default class MSD_CORE_Registration extends LightningElement {

    @track showOTP = false;
    @track showPassword = false;
    @track showEligilibility = false;
    @track showPersonal = false;
    @track showSuccess = false;

    @track accrecordId;
    @track checkExpiration = true;
    @track eligibilityPopup = false;
    @track statusval;

    @track eligibilityResult = '';

    @track registrationwrap;
    @track popupData = '';
    @track isLinkValid = true;

    @track showMainContain = false;
    @track otpvalue = '';
    @track accEmail = '';

    @track mobilescreen = false;
    merckimage = mercklogo;
    @track isResend = false;
    label = {jobcode};

    // Method Name:         WiredgetStateParameters
    // Method Use:          Used for getting Record Id from the parameter
    // Developer Name:      Ravi Modi
    // Created Date:        29th May 2023
    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.accrecordId = currentPageReference.state.recordId;
            if(currentPageReference.state.s){
                this.checkExpiration = false;
            }
            if (currentPageReference.state.resend) {
                this.isResend = true;
            }
        }
    }

    connectedCallback() {
        
        if (this.accrecordId) {
            this.isLinkValid = true;
            this.checkRegistrationStatus();
        } else {
            this.isLinkValid = false;
            this.popupData = 'InvalidLink';
        }
        this.loadWrapperData();
        this.fireOnLoadEvent();

         var screenwidth = (window.innerWidth > 0) ? window.innerWidth : screen.width;
            if (screenwidth > 768) {
                this.mobilescreen = false;
                console.log('system Screen size is '+this.mobilescreen);
            } else {
                this.mobilescreen = true;
                console.log('Mobile Screen size is '+this.mobilescreen);
            }

           
    }

    // Method Name:         hideHeader
    // Method Use:          Used for hiding the header from the registration page
    // Developer Name:      Ravi Modi
    // Created Date:        31th July 2023
    hideHeader() {
        this.dispatchEvent(new CustomEvent('hideHeader', {
            detail: 'hide',
            bubbles: true,
            composed: true
        }));
    }

    // Method Name:         showHeader
    // Method Use:          Used for show the header from the registration page
    // Developer Name:      Ravi Modi
    // Created Date:        31th July 2023
    showHeader() {
        this.dispatchEvent(new CustomEvent('showHeader', {
            detail: 'show',
            bubbles: true,
            composed: true
        }));
    }

    // Method Name:         hidePasswordPage
    // Method Use:          Used for Show Eligibility Page
    // Developer Name:      Ravi Modi
    // Created Date:        26th May 2023
    hidePasswordPage(event) {
        this.showEligilibility = true;
        this.showPassword = event.detail;
        this.showPersonal = false;
        this.showSuccess = false;
        
    }

    // Method Name:         showPersonalPage
    // Method Use:          Used for Show personal Page
    // Developer Name:      Ravi Modi
    // Created Date:        26th May 2023
    showPersonalPage(event) {
        this.showEligilibility = event.detail;
        this.showPersonal = true;
        this.showSuccess = false;
        this.showPassword = false;
    }

    // Method Name:         hideEligibilityPage
    // Method Use:          Used for Hide Eligibility Page
    // Developer Name:      Ravi Modi
    // Created Date:        26th May 2023
    hideEligibilityPage(event) {
        this.showEligilibility = event.detail;
        this.showPassword = true;
        this.showPersonal = false;
        this.showSuccess = false;
        this.showOTP = true;
        this.otpvalue = '';
    }

    // Method Name:         showSuccessPage
    // Method Use:          Used for Show Success Page
    // Developer Name:      Ravi Modi
    // Created Date:        26th May 2023
    showSuccessPage(event) {
        this.showPersonal = event.detail;
        this.showSuccess = true;
        this.showPassword = false;
        this.showEligilibility = false;
    }

    // Method Name:         hidePersonalPage
    // Method Use:          Used for Hide Personal Page
    // Developer Name:      Ravi Modi
    // Created Date:        26th May 2023
    hidePersonalPage(event) {
        this.showPersonal = event.detail.showPersonal;
        this.showSuccess = false;
        this.showEligilibility = true;
        this.showPassword = false;
        this.registrationwrap.salutation = event.detail.salutation;
        this.registrationwrap.firstname = event.detail.firstname;
        this.registrationwrap.lastname = event.detail.lastname;
        this.registrationwrap.suffix = event.detail.suffix;
        this.registrationwrap.designation = event.detail.designation;
        this.registrationwrap.Specialty = event.detail.speciality;
    }

    // Method Name:         createOTPOnLoad
    // Method Use:          Used for create OTP record
    // Developer Name:      Ravi Modi
    // Created Date:        31th July 2023
    createOTPOnLoad() {
        this.hideHeader();
        createOTP({recordId:this.accrecordId})
        .then((result)=>{
            this.showOTP = true;
            this.showHeader();
            console.log('Result of CreateOTP ==>',{result});
            this.otpvalue = result;
            this.isLinkValid = true;
            this.eligibilityPopup = true;
            this.showMainContain = true;
        })
        .catch((error)=>{
            console.log('Error of CreateOTP ==>',{error});
        })
    }

    // Method Name:         showNextPage
    // Method Use:          Used for Show Eligibility/Personal Page
    // Developer Name:      Ravi Modi
    // Created Date:        01 Aug 2023
    showNextPage(event) {
        if(this.eligibilityResult.eligibilityStage == 'Eligibility') {
            this.showEligilibility = false;
            this.showPersonal = true;
            this.showSuccess = false;
            this.showOTP = false;
        } else {
            this.showEligilibility = true;
            this.showPersonal = false;
            this.showSuccess = false;
            this.showOTP = false;
        }
    }

    // Method Name:         resendotp
    // Method Use:          Used for Resend OTP
    // Developer Name:      Ravi Modi
    // Created Date:        01 Aug 2023
    resendotp(event) {
        this.createOTPOnLoad();
    }

    // Method Name:         checkRegistrationStatus
    // Method Use:          Used for checkRegistrationStatus
    // Developer Name:      Ravi Modi
    // Created Date:        31st July 2023
    checkRegistrationStatus() {
        checkExistingUser({recordId:this.accrecordId, checkExpiration: this.checkExpiration, isResend: this.isResend})
        .then((result) => {
            console.log('Result of checkExistingUser--->',{result});
            this.eligibilityResult = result;
            if(result) {

                if (result.isLinkInvalid) {
                    this.showMainContain = true;
                    this.isLinkValid = false;
                    this.popupData = 'InvalidLink';
                    this.template.querySelector('c-m-s-d_-c-o-r-e_-generic-popup-model').popupmodel('InvalidLink');
                } else {
                    // If User not exist in SF
                    if (!result.checkUserExist) {
                        this.isLinkValid = false;
                        this.popupData = 'UserNotExist';
                        this.showMainContain = true;
                    } else {
                        // If ExistingCustomer
                        if (result.isExistingCustomer) {
                            this.showMainContain = true;
                            this.eligibilityPopup = false;
                            this.isLinkValid = true;
                            this.popupData = 'ExistingCustomer';
                            this.template.querySelector('c-m-s-d_-c-o-r-e_-generic-popup-model').popupmodel('ExistingCustomer');
                        } else {
                            this.accEmail = result.accEmail;
                            // Check if Eligibility Record is exist?
                            if (result.isEligibilityExist) {
                                // Check if Eligibility Record Status
                                if (result.eligibilityStatus == 'In Progress') {
                                    this.createOTPOnLoad();
                                } else {
                                    this.showMainContain = true;
                                    this.isLinkValid = false;
                                    this.popupData = 'PendingReq';
                                } 
                            } else {
                                // Check if invitation link is Expired?
                                if (result.isExpiredInvitation) {
                                    this.showMainContain = true;
                                    this.eligibilityPopup = false;
                                    this.isLinkValid = true;
                                    this.popupData = 'ExpiredInvitation';
                                    this.template.querySelector('c-m-s-d_-c-o-r-e_-generic-popup-model').popupmodel('ExpiredInvitation');
                                } else {
                                    this.createOTPOnLoad();
                                }

                            }
                        }
                    }
                }

                
            }
        })
        .catch((error) => {
            console.log('Error of checkExistingUser--->',{error});
        })
    }

    loadWrapperData() {
        this.registrationwrap = {};
        this.registrationwrap.salutation = '';
        this.registrationwrap.firstname = '';
        this.registrationwrap.lastname = '';
        this.registrationwrap.suffix = '';
        this.registrationwrap.designation = '';
        this.registrationwrap.Specialty = '';
    }

     fireOnLoadEvent() {
        console.log('Call Events');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                data_design_category: '',
                data_design_action: '',
                data_design_label: '',
                data_design_module: '',
                page_type: 'account management',
                page_purpose: 'registration',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'Register',
                link_url: '/SelfRegister',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                content_count: '',
                sfmc_id: '',
                sfmc_audience: '',
                page_url: location.href,
                page_title: 'Self Registration',
            },
            bubbles: true,
            composed: true
        }));
    }
}