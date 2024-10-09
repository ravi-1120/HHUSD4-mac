import { LightningElement,track,api } from 'lwc';
import sendEmail from '@salesforce/apex/MSD_CORE_ae_EmailCaseDetails.sendEmail';
import Button from '@salesforce/label/c.MSD_ae_warningbtn';
import ADVERSEEVENTCONFIRMATION from '@salesforce/label/c.MSD_CORE_ae_Adverse_Event_Confirmation';
import SERVICECLOUDCASENUMBER from '@salesforce/label/c.MSD_CORE_ae_ServiceCloud_Case_Number';
import SUBMISSIONDATETIME from '@salesforce/label/c.MSD_CORE_ae_Submission_Date_Time';

export default class MSD_CORE_ae_submission extends LightningElement {
    label = {
        Button,
        ADVERSEEVENTCONFIRMATION,
        SERVICECLOUDCASENUMBER,
        SUBMISSIONDATETIME
      } 
    @track buttonClicked = false;
    @api isSubmitClicked;
    @track isCheckboxChecked = false;
    @track isLoading = true;
    @api caseDetails;
    @track email = '';
    privateCaseNumber;
    @track showCheckbox = true;

    @api
    get caseNumber() {
        return this.privateCaseNumber;
    }
    set caseNumber(value) {
        if (value) {
            this.isLoading = false;
        }
        this.privateCaseNumber = value;
    }

    handleButtonClick() {
        console.log('MSD_CORE_ae_warningMsg - handleButtonClick');
        this.buttonClicked = true;
        this.dispatchEvent(new CustomEvent('showmaincontent'));
    }

    connectedCallback() {
        console.log('Case Details received from review and Confirmation:', JSON.stringify(this.caseDetails));
    }

    get isMerckEmployee() {
        let userChoice = this.caseDetails.stage1['userChoice'];
        return userChoice === 'Merck Employee';
    }

    get isHCP() {
        let userChoice = this.caseDetails.stage1['userChoice'];
        return userChoice === 'Healthcare Professional';
    }

    handleCheckboxChange(event) {
        console.log('isCheckboxChecked previous value:', this.isCheckboxChecked);
        this.isCheckboxChecked = event.target.checked;
        console.log('isCheckboxChecked new value:', this.isCheckboxChecked);
        if (this.isCheckboxChecked) {
            this.setEmail();
        }
    }

    handleEmailChange(event) {
        console.log('Email before change:', this.email);
        this.email = event.target.value;
        console.log('Email after change:', this.email);
    }

    setEmail() {
        if (this.isHCP) {
            this.email = this.caseDetails.stage2.hcpEmail;
        } else if (this.isMerckEmployee) {
            this.email = this.FieldBased ? this.caseDetails.stage2.MaskedEmail : this.caseDetails.stage2.NempEmail;
        }
        console.log('Email set to:', this.email);
    }

    get FieldBased() {
        let FieldBased = this.caseDetails.stage2['FieldBased'];
        return FieldBased === 'yes';
    }

    closeModal() {
        this.isCheckboxChecked = false;
    }

    sendEmail() {
        if (this.validateRequiredFields()) {
            console.log('Sending email to:', this.email);
            this.sendEmailWithDetails();
            this.closeModal();
        } else {
            this.showNotification('error', 'Please enter a valid Email Address');
        }
    }

    async sendEmailWithDetails() {
        try {
            await sendEmail({ 
                recipientEmail: this.email, 
                caseNumber: this.caseNumber, 
                submissionDateTime: this.currentDateTime 
            });
            this.showCheckbox = false;
            this.showNotification('success', 'Email sent successfully');
        } catch (error) {
            console.error('Error sending email:', error);
            this.showNotification('error', 'Failed to send email');
        }
    }

    validateRequiredFields() {
        const allRequiredFields = [...this.template.querySelectorAll('.requiredField')];
        let isValid = allRequiredFields.every(field => {
            return field.reportValidity();
        });
        return isValid;
    }

    onBlur(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        const validationRules = {
            'sendemail': {
                isValid: fieldValue === '' || /\S+@\S+\.\S+/.test(fieldValue),
                errorMessage: "Invalid Email Address"
            },
        };
        const { isValid, errorMessage } = validationRules[fieldName];
        if (!isValid) {
            event.target.setCustomValidity(errorMessage);
            event.target.value = '';
        } else {
            event.target.setCustomValidity('');
        }
        event.target.reportValidity();
    }

    get currentDateTime() {
        let now = new Date();
        let month = String(now.getMonth() + 1).padStart(2, '0');
        let day = String(now.getDate()).padStart(2, '0');
        let year = now.getFullYear();
        let hours = now.getHours();
        let minutes = String(now.getMinutes()).padStart(2, '0');
        let ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12;
        hours = String(hours).padStart(2, '0');
        return `${month}/${day}/${year}, ${hours}:${minutes} ${ampm}`;
    }
    showNotification(type, message) {
        this.template.querySelector('c-custom-toast').showToast(type, message);
    }
}