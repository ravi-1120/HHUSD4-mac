import AEDESCRIPTION from '@salesforce/label/c.MSD_CORE_ae_AE_Description';
import HCPPLACEHOLDER from '@salesforce/label/c.MSD_CORE_ae_AE_Description_hcpplaceholder';

import AEDESCRIPTIONPLACEHOLDER from '@salesforce/label/c.MSD_CORE_ae_AE_Description_placeholder';
import COMPANYAWARENESSDATE from '@salesforce/label/c.MSD_CORE_ae_Company_Awareness_Date';
import COUNTVALUE from '@salesforce/label/c.MSD_CORE_ae_Count_Value';
import DESCRITPIONFIELDHELP from '@salesforce/label/c.MSD_CORE_ae_Help_Description_Details';
import NEXT from '@salesforce/label/c.MSD_CORE_ae_Next_Button';
import PATIENTFIRSTEXPERIENCE from '@salesforce/label/c.MSD_CORE_ae_Patient_First_Experience';
import PREVIOUS from '@salesforce/label/c.MSD_CORE_ae_Previous_Button';
import REPORTMULTIPLEPATIENTS from '@salesforce/label/c.MSD_CORE_ae_Reporting_Multiple_patients';
import SKIPREVIEW from '@salesforce/label/c.MSD_CORE_ae_Skip_to_Review';
import { LightningElement, api, track } from 'lwc';

export default class MSD_CORE_ae_aeDetails extends LightningElement {
    @api caseDetails;
    @track inputValues = {};
    @api stageId;
    @api editedSection;
    @track charCount = 0;
    @api portalSetting;
    maxDate;
    // minDate;
    label = {
        SKIPREVIEW,
        PREVIOUS,
        NEXT,
        COUNTVALUE,
        COMPANYAWARENESSDATE,
        DESCRITPIONFIELDHELP,
        REPORTMULTIPLEPATIENTS,
        PATIENTFIRSTEXPERIENCE,
        AEDESCRIPTION,
        AEDESCRIPTIONPLACEHOLDER,
        HCPPLACEHOLDER

    }
    get showSkipButton() {
        return this.editedSection === this.stageId;
    }
    get patientOptions() {
        return this.processOptions(this.portalSetting.Reporting_AEs_for_multiple_patients__c, ';');
    }
    get isHCP() {
        let userChoice = this.caseDetails.stage1['userChoice'];
        return userChoice === 'Healthcare Professional';
    }
    get PSP() {
        let userChoice = this.caseDetails.stage1['userChoice'];
        return userChoice === 'PSP Representative';
    }
    get aeDescriptionPlaceholder() {
        if (this.isHCP) {
            return HCPPLACEHOLDER;
        } else if (this.PSP) {
            return  'Please provide the PSP patient enrollment status within the Adverse Event details (e.g., pre-enrollment, actively enrolled, re-enrollment, PSP completed).' + 
                    '\n' + AEDESCRIPTIONPLACEHOLDER;
        } else {
            return AEDESCRIPTIONPLACEHOLDER;
        }
    }

    processOptions(rawOptions, delimiter) {
        return rawOptions ? rawOptions.split(delimiter).map(option => {
            const [label, value] = option.split(':');
            return { label: label?.trim(), value: value?.trim() || label?.trim() };
        }) : [];
    }

    connectedCallback() {
        console.log('Case Details are:', JSON.stringify(this.caseDetails));
        if (this.caseDetails !== undefined && Object.keys(this.caseDetails).length !== 0) {
            this.populateInputs();
        }
        this.maxDate = new Date().toLocaleDateString('en-US', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        })
        this.minDate = new Date("1900-01-01").toLocaleDateString('en-US', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        })
        // this.minDate = "1900-01-01";
        // console.log('minDate:', this.minDate);
        console.log('maxDate:', this.maxDate);

    }
  
    populateInputs() {
        this.inputValues = Object.assign(this.inputValues, this.caseDetails.stage5);
        if(this.inputValues && this.inputValues.AE){
            this.charCount = (this.inputValues.AE).length;
        }
    }

    handleInput(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        console.log('Handling input for:', fieldName, 'with value:', fieldValue);
        this.inputValues[fieldName] = fieldValue;
        console.log('Updated inputValues:', JSON.stringify(this.inputValues));
        if(fieldName === 'MPI'){
            if(this.inputValues['MPI'] != null){
                event.target.setCustomValidity("");
            }   
        }
        if (fieldName === 'AE') {
            this.charCount = fieldValue.length;
        }
        if (fieldName === 'CAD') {
            let inputDate = new Date(fieldValue);
            let currentDate = new Date();
            console.log('currentDate:', currentDate);
            console.log('inputDate:', inputDate);
            console.log('maxDate:', this.maxDate);
            let maxDate = this.maxDate;
            console.log('maxDate:', this.maxDate);
            if (inputDate > currentDate) {
                this.inputValues.CAD = null;
                event.target.setCustomValidity("Date entered must be " + maxDate + " or earlier");
            } else {
                event.target.setCustomValidity("");
            }
        }
        event.target.reportValidity();
    }

    handlePrevNext(event) {
        let choice = event.target.name;
        if (choice === 'Next' || choice === 'Skip') {
            let isValid = this.validateRequiredFields();
            if (isValid) {
                this.StageDetails(choice);
            }
        }else if (choice === 'Previous') {
            this.StageDetails(choice);
        }
    }

    DateBlur(event) {
        const fieldName = event.target.name;
        if (fieldName === 'CAD') {
            let inputDate = new Date(event.target.value);
            let minDate = new Date(this.minDate);
           if (inputDate < minDate) {
                this.inputValues.CAD = null;
                console.log('Entered this loop for minDate');
                event.target.setCustomValidity("Year entered must be 1900 or later");
            } else {
                event.target.setCustomValidity("");
            }
        }
        event.target.reportValidity();
    }

    StageDetails(choice) {
        const stage5DetailsEvent = new CustomEvent("stagedetails", {
            detail: {
                'stageInputs': {
                    'stage5': this.inputValues
                },
                'action': choice,
            }
        });

        this.dispatchEvent(stage5DetailsEvent);
    }

    validateRequiredFields() {
        const allRequiredFields = [...this.template.querySelectorAll('.requiredField')];
        let isValid = allRequiredFields.every(field => {
            if (field.name === 'MPI' && !this.isHCP && !field.value) {
                field.setCustomValidity("Complete this field.");
                field.reportValidity();
                return false;   
            }
            if (field.name === 'MPI' && this.isHCP && !field.value) {
                return true;  
            }
            if (field.name === 'MPI' && field.value) {
                field.setCustomValidity("");
            }
            return field.reportValidity();
        });
        if (!this.isHCP) {
            const cadField = this.template.querySelector('input[name="CAD"]');
            if (!this.inputValues.CAD || !cadField.reportValidity()) {
                isValid = false;
                cadField.setCustomValidity("Company Awareness Date is required.");
                cadField.reportValidity();
            } else {
                cadField.setCustomValidity("");
            }
        }
        return isValid;
    }


}