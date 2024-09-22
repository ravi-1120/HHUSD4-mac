import { LightningElement, track, api } from 'lwc';
import Next from '@salesforce/label/c.MSD_CORE_ciportal_nextnavi';

export default class MSD_CORE_ci_questionnaire extends LightningElement {
    label={
        Next
    }
    @api caseDetails;
    @track inputValues = {};
    @api
validateAndDispatch() {
    const isValid = this.isValid();
    console.log('Child Component: isValid =', isValid);
    this.dispatchEvent(new CustomEvent('stagevalidation', {
        detail: { isValid, stage: this.currentStage }
    }));
    if (isValid) {
        this.dispatchCaseDetails();
    }
    return isValid;
}

@api
dispatchCaseDetails() {
    const stageDetailsEvent = new CustomEvent('stagedetails', {
        detail: {
            stageInputs: this.inputValues,
            isValid: this.isValid()
        }
    });
    console.log('Child Component: Dispatching Case Details =', JSON.stringify(stageDetailsEvent.detail));
    this.dispatchEvent(stageDetailsEvent);
}
    connectedCallback() {
        this.prepopulateInputs();
        console.log('Case Details in Stage 1 are:', JSON.stringify(this.caseDetails));
    }

    prepopulateInputs() {
        if (this.caseDetails) {
            this.inputValues = {
                ...this.inputValues,
                ...this.caseDetails.stage1,
                RepName: this.caseDetails.employeeDetails.MaskedFirstName || 'Not Available'
            };
        }
    }
    handleInput(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        this.inputValues[fieldName] = fieldValue;
    }
    isValid() {
        const inputElements = Array.from(this.template.querySelectorAll('lightning-input, lightning-combobox'));
        return inputElements.every(input => {
            if (input.required) {
                input.reportValidity(); // Show validity messages
                return input.checkValidity();
            }
            return true;
        });
    }
    handlePrevNext(event) {
        const choice = event.target.name;
        let isValid = true;
        let invalidElement = null;
        if (choice === 'Next') {
            const inputElements = Array.from(this.template.querySelectorAll('lightning-input, lightning-combobox'));
            inputElements.forEach(input => {
                if (input.required && !input.checkValidity()) {
                    isValid = false;
                    if (!invalidElement) {
                        invalidElement = input;
                    }
                }
            });  
            if (!isValid) {
                this.dispatchEvent(
                    new CustomEvent('showtoast', {
                        detail: { type: 'warning', message: 'Provide all the mandatory values before proceeding!' },
                        bubbles: true,
                        composed: true
                    })
                );
                if (invalidElement) {
                    invalidElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    invalidElement.focus();
                }
                return;
            }
        }
        const stageDetailsEvent = new CustomEvent("stagedetails", {
            detail: {
                stageInputs: this.inputValues,
                action: choice,
                isValid: isValid
            }
        });
        this.dispatchEvent(stageDetailsEvent);
    }
}