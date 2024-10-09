import { LightningElement, track, api } from 'lwc';
import Next from '@salesforce/label/c.MSD_CORE_ciportal_nextnavi';
import Previous from '@salesforce/label/c.MSD_CORE_ciportal_prevnavi';
import AEURL from '@salesforce/label/c.MSD_CORE_aePortal_URL';

export default class MSD_CORE_ci_adverse extends LightningElement {
    label = {
        Next,
        Previous
        
    }
    portalUrl = AEURL;
    @api caseDetails;
    @track inputValues = {};
    @api portalSetting;
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
    get options() {
        return this.processOptions(this.portalSetting.AdverseOptions__c, ';');
    }
    processOptions(rawOptions, delimiter) {
        return rawOptions ? rawOptions.split(delimiter).map(option => {
            const [label, value] = option.split(':');
            return { label: label?.trim(), value: value?.trim() || label?.trim() };
        }) : [];
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
        console.log('Case Details in Stage 4 are:', JSON.stringify(this.caseDetails));
    }

    prepopulateInputs() {
        if (this.caseDetails !== undefined) {
            this.inputValues = Object.assign(this.inputValues, this.caseDetails.stage4);
        }
    }
    get fieldVisibility() {
        const visibility = {
            isadverse: false,
            isnoadverse: false,   
        };

        const adverse = this.inputValues.adverse;

        if (adverse === 'Yes') {
            visibility.isadverse = true;

        }  else if (adverse === 'No') {
            visibility.isnoadverse = true;
        } 
        return visibility;
    }
    openPortalInNewTab() {
        window.open(this.portalUrl, '_blank');
    }
    handleInput(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        this.inputValues[fieldName] = fieldValue;
        this.updateFieldVisibility();
    }

    updateFieldVisibility() {
        const visibility = this.fieldVisibility;
        this.inputValues.isadverse = visibility.isadverse;
        this.inputValues.isnoadverse = visibility.isnoadverse;
    }

    isValid() {
        const inputElements = Array.from(this.template.querySelectorAll('lightning-input, lightning-combobox'));
        return inputElements.every(input => {
            if (input.required) {
                input.reportValidity();
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