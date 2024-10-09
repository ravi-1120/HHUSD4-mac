import { LightningElement, track } from 'lwc';
import StageNames from '@salesforce/apex/MSD_CORE_ci_PortalStageHandler.StageNames';
import picklistOptions from '@salesforce/apex/MSD_CORE_ci_PortalStageHandler.picklistOptions';
import landingCSS from '@salesforce/resourceUrl/MSD_CORE_ci_landingCSS';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

export default class MSD_CORE_ci_landingpage extends LightningElement {

    @track steps = [];
    currentStep = 1;
    lastStep;
    @track caseDetails = {};
    @track showQuestionnaire = false;
    @track modal = true;
    buttonType;
    showWelcomePopup = true;
    employeeDetails = {};
    @track completedStages = new Set();
    portalSetting;
    

    connectedCallback() {
        this.populateSteps();
        this.loadCustomCSS();
        this.loadPicklistOptions();
        this.caseDetails = this.setCaseDetails();
        this.completedStages = new Set();
        console.log('Case Details in Stage 1 are:', JSON.stringify(this.caseDetails));
    }

    loadCustomCSS(){
        Promise.all([
            loadStyle(this, landingCSS)
        ]).then(() => {
            console.log('CSS file :landingCSS loaded');
        })
        .catch(error => {
            console.log(error.body.message);
        });
    }
    
    loadPicklistOptions() {
        picklistOptions()
            .then(result => {
                this.portalSetting = result;
            })
            .catch(error => {
                console.error('Error retrieving raw picklist options:', error);
            });
    }

    setCaseDetails() {
        let caseDtl = {
            stage1: {},
            stage2: {},
            stage3: {},
            stage4: {}
        };
        return caseDtl;
    }

    handleShowToast(event) {
        const { type, message } = event.detail;
        this.showNotification(type, message);
    }

    get containerClass() {
        return this.modal ? 'no-scroll' : '';
    }

    showNotification(type, message) {
        this.template.querySelector('c-custom-toast').showToast(type, message);
    }

    handleValidationComplete(event) {
        this.showQuestionnaire = event.detail.success;
        if (this.showQuestionnaire) {
            this.employeeDetails = event.detail.data;
            this.populateCaseDetails();
        }
    }
    populateCaseDetails() {
        if (this.employeeDetails) {
            this.caseDetails.employeeDetails = {
                EmployeeId: this.employeeDetails.Id || '',
                FirstName: this.employeeDetails.FirstName || '',
                MaskedFirstName: this.employeeDetails.MaskedFirstName || '******',
                LastName: this.employeeDetails.LastName || '',
                MaskedLastName:  this.employeeDetails.MaskedLastName || '******',
            };
        }
    }

    handleModalChange(event) {
        this.modal = event.detail;
    }

    get stageName() {
        if (!this.showQuestionnaire) {
            return "Employee Validation";
        }
        const step = this.steps.find(o => o.id === this.currentStep);
        return step ? step.label : '';
    }

    populateSteps() {
        StageNames()
            .then(stageNames => {
                this.steps = stageNames.map((label, index) => ({
                    id: index + 1,
                    label,
                    icon: this.getIcon(index + 1),
                    className: this.getClass(index + 1)
                }));
                this.lastStep = this.steps.length;
            })
            .catch(error => {
                console.error('Error retrieving stage names:', error);
            });
    }
        getIcon(stepId) {
            switch(stepId) {
                case 1: return 'utility:user';
                case 2: return 'utility:product';
                case 3: return 'utility:attach';
                case 4: return 'utility:new';
                case 5: return 'utility:info';
                case 6: return 'utility:success';
                default: return 'utility:dash';
            }
        }

        getClass(stepId) {
            let baseClass = 'progress-step';
            if (stepId === this.currentStep) {
                return `${baseClass} active`;
            } else if (this.completedStages.has(stepId)) {
                return `${baseClass} completed`;
            } else if (stepId < this.currentStep) {
                return `${baseClass} completed`;
            } else {
                return baseClass;
            }
        }

    getLabelClass(stepId) {
        return stepId === this.currentStep ? 'progress-label active-label' : 'progress-label';
    }
    handleSubmitSuccess(event) {
        const caseNumber = event.detail.caseNumber;
        this.caseDetails.caseNumber = caseNumber;
        this.currentStep = 6;
        this.disableProgressBar();
        this.updateSteps();
    }
    handleResetReport(event) {
        console.log('Reset requested:', event.detail.message);
    
        // Clear case details
        this.caseDetails = {
            stage1: {},
            stage2: {},
            stage3: {},
            stage4: {},
            employeeDetails: {},
        };
    
        // Reset progress and UI states
        this.currentStep = 1;
        this.showQuestionnaire = false;
        this.modal = true; 
        if (this.completedStages) {
            this.completedStages.clear();
        } else {
            this.completedStages = new Set();
        }
        this.updateSteps();
        this.showNotification('info', 'The form has been reset. Please start a new report.');
        window.scrollTo(0, 0);
    }
    disableProgressBar() {
        this.steps = this.steps.map(step => {
            return {
                ...step,
                className: step.id < this.currentStep ? 'progress-step completed disabled' : 'progress-step disabled'
            };
        });
    }

    setStep(event) {
        const stepNumber = parseInt(event.currentTarget.dataset.step, 10);
        let activeComponent;
        if (this.currentStep === 6) {
            this.showNotification('warning', 'You cannot navigate back after submission.');
            return;
        }
    
        switch (this.currentStep) {
            case 1:
                activeComponent = this.template.querySelector('c-m-s-d_-c-o-r-e_ci_questionnaire');
                break;
            case 2:
                activeComponent = this.template.querySelector('c-m-s-d_-c-o-r-e_ci_product');
                break;
            case 3:
                activeComponent = this.template.querySelector('c-m-s-d_-c-o-r-e_ci_typeofinfo');
                break;
            case 4:
                activeComponent = this.template.querySelector('c-m-s-d_-c-o-r-e_ci_adverse');
                break;
            default:
                break;
        }
    
        if (stepNumber > this.currentStep) {
            if (activeComponent) {
                const isValid = activeComponent.validateAndDispatch();
                if (isValid) {
                    this.completedStages.add(this.currentStep);
                    const navigationResult = this.canNavigateToStep(stepNumber);
                    if (navigationResult.canNavigate) {
                        this.currentStep = stepNumber;
                        this.updateSteps();
                    } else {
                        this.showNotification('warning', `Please complete "${navigationResult.incompleteStageName}" stage before proceeding.`);
                    }
                } else {
                    this.showNotification('error', 'Provide all the mandatory values before proceeding!');
                }
            }
        } else if (stepNumber < this.currentStep) {
            if (activeComponent) {
                activeComponent.dispatchCaseDetails();
            }
            this.currentStep = stepNumber;
            this.updateSteps();
        }
    }

    canNavigateToStep(stepNumber) {
        for (let i = 1; i < stepNumber; i++) {
            const stageKey = `stage${i}`;
            if (!this.caseDetails[stageKey]?.statusCompletion) {
                const incompleteStage = this.steps.find(step => step.id === i);
                return { canNavigate: false, incompleteStageName: incompleteStage ? incompleteStage.label : `Stage ${i}` };
            }
        }
        return { canNavigate: true, incompleteStageName: null };
    }


    updateSteps() {
        this.steps = this.steps.map(step => ({
            ...step,
            className: this.getClass(step.id)
        }));
    }
    get isStep1() {
        return this.currentStep === 1;
    }

    get isStep2() {
        return this.currentStep === 2;
    }

    get isStep3() {
        return this.currentStep === 3;
    }

    get isStep4() {
        return this.currentStep === 4;
    }

    get isStep5() {
        return this.currentStep === 5;
    }

    get isStep6(){
        return this.currentStep === 6;
    }
    nextStep() {
        if (this.currentStep < this.lastStep) {
            this.completedStages.add(this.currentStep);
            this.currentStep++;
            this.updateSteps();
        }
    }

    previousStep() {
        if (this.currentStep > 1) {
            this.currentStep--;
            this.updateSteps();
        }
    }
    
    handlePrevNext(event) {
        if (event.detail) {
            const currentStageKey = `stage${this.currentStep}`;
            const isValid = event.detail.isValid || false;
    
            this.caseDetails[currentStageKey] = {
                ...this.caseDetails[currentStageKey],
                ...event.detail.stageInputs,
                statusCompletion: isValid
            };
    
            switch (event.detail.action) {
                case 'Next':
                    if (this.currentStep < this.lastStep && isValid) {
                        this.completedStages.add(this.currentStep);
                        this.nextStep();
                    } else {
                        this.showNotification('error', 'Please complete the current step before proceeding.');
                    }
                    break;
                case 'Previous':
                    this.previousStep();
                    break;
                case 'Skip':
                    const navigationResult = this.canNavigateToStep(this.lastStep);
                    if (navigationResult.canNavigate) {
                        this.currentStep = this.lastStep;
                        this.updateSteps();
                    } else {
                        this.showNotification('warning', `Please complete "${navigationResult.incompleteStageName}" stage before skipping.`);
                    }
                    break;
                default:
                    break;
            }
        }
    }


}