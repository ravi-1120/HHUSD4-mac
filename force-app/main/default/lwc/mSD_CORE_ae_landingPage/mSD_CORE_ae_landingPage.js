import picklistOptions from '@salesforce/apex/MSD_CORE_ae_PortalStageHandler.picklistOptions';
import AE_STAGES from '@salesforce/label/c.MSD_CORE_ae_StageLabels';
import AMO_FONTS from '@salesforce/resourceUrl/AMO_Fonts';
import { LightningElement, track } from 'lwc';

export default class MSD_CORE_ae_landingPage extends LightningElement {
    fontsBaseUrl = AMO_FONTS;
    buttonType;
    showWelcomePopup = true;
    lastStep;
    currentStep = 1;
    @track steps = [];
    @track caseDetails = {};
    @track modal = true;
    portalSetting;

    get stageName() {
        const step = this.steps.filter(o => o.id == this.currentStep)[0];
        return step ? step.label : '';
    }
    get stepIsOne() {
        return this.currentStep === 1;
    }
    get HealthcareProfessional() {
        return this.currentStep === 2 && this.buttonType === 'Healthcare Professional';
    }
    get PSP (){
        return this.currentStep === 2 && this.buttonType === 'PSP Representative';
    }
    get Employee() {
        return this.currentStep === 2 && this.buttonType === 'Merck Employee';
    }    
    get stepIsTwo() {
        return this.currentStep === 2;
    }
    get stepIsThree() {
        return this.currentStep === 3;
    }
    get stepIsFour() {
        return this.currentStep === 4;
    }
    get stepIsFive() {
        return this.currentStep === 5;
    }
    get stepIsSix() {
        return this.currentStep === 6;
    }
    get isLastStep() {
        return this.currentStep === this.lastStep;
    }

    connectedCallback() {
        this.caseDetails = this.setCaseDetails();
        this.loadPicklistOptions();
        console.log('Case Details are:', JSON.stringify(this.caseDetails));
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

    //Added for handling the modal inside the landing page clip path design
    handleClassChange(event) {
        let modalAction = event.detail;
        if (modalAction === 'ModalOpen') {
            this.template.querySelector('.MainformCls').classList.remove('MainFormClip');
            this.template.querySelector('.formCls').classList.remove('formClip');
        } else if (modalAction === 'ModalClose') {
            this.template.querySelector('.MainformCls').classList.add('MainFormClip');
            this.template.querySelector('.formCls').classList.add('formClip');
        }
    }

    getClass(stepId) {
        if (stepId === this.currentStep) {
            return 'progress-circle active';
        } else if (stepId < this.currentStep) {
            return 'progress-circle completed';
        } else {
            return 'progress-circle';
        }
    }

    getLabelClass(stepId) {
        return stepId === this.currentStep ? 'progress-label active-label' : 'progress-label';
    }

    populateSteps() { // move all the labels to custommetadata options
        let stageArr = AE_STAGES.split(',');
        this.steps = [];

        let Stepnumber = false;
        stageArr.forEach((stageNames, index) => {
            if (index === 5 && this.caseDetails.stage5.MPI !== 'No') {
                if (this.buttonType !== 'Healthcare Professional') {
                    Stepnumber = true;
                    this.stage6Reset();
                    return;
                }
            }

            let stepId = index + 1;
            let label = stageNames;
            if (Stepnumber) stepId--;
            // Corrected version
            if (stepId === 2 && this.buttonType === 'Merck Employee') { // move to custom labels for all button types
                label = 'Employee Information';
            } else if (stepId === 2 && this.buttonType === 'Healthcare Professional') { 
                label = 'Healthcare Professional Reporter Information';
            } 
            if(stepId === 3 && this.buttonType === 'Healthcare Professional'){
                label = 'Patient Information';
            }

            this.steps.push({
                id: stepId,
                label: label,
                class: this.getClass(stepId),
                labelClass: this.getLabelClass(stepId)
            });
        });
        this.lastStep = this.steps.length;
    }

    handleButtonChoice(event) {
        this.showWelcomePopup = false;
        this.buttonType = event.detail.buttonType;
        this.caseDetails.stage1 = { 'userChoice': this.buttonType };
        this.populateSteps();
    }

    handleAssessment(event) {
        if (event.detail !== undefined) {
            if (event.detail === 'Next') {
                this.nextStep();
            } else if (event.detail === 'New') {
                this.modal = true;
                this.showWelcomePopup = true;
                this.editedSection = undefined;
                this.currentStep = 1;
                this.caseDetails = this.setCaseDetails();
            }
        }
    }

    nextStep() {
        this.currentStep++;
        this.populateSteps();
        this.updateSteps();
    }

    previousStep() {
        this.currentStep--;
        this.populateSteps();
        this.updateSteps();
    }

    handleEdit(event) {
        const stageTo = event.detail;
        this.editedSection = stageTo;
        this.currentStep = parseInt(stageTo, 10);
        this.updateSteps();
    }

    updateSteps() {
        this.steps = this.steps.map(step => {
            return { ...step, class: this.getClass(step.id), labelClass: this.getLabelClass(step.id) };
        });
    }

    handleModalChange(event) {
        this.modal = event.detail;
    }

    handlePrevNext(event) {
        if (event.detail !== undefined) {
            this.caseDetails = { ...this.caseDetails, ...(event.detail.stageInputs) };
            // console.log('caseDetails-->' + JSON.stringify(this.caseDetails));

            switch (event.detail.action) {
                case 'Next':
                    this.nextStep();
                    break;
                case 'Skip':
                    this.populateSteps();
                    this.currentStep = this.lastStep;
                    this.updateSteps();
                    break;
                default:
                    this.previousStep();
                    break;
            }
        }
    }

    stage6Reset() {
        this.caseDetails.stage6 = {
            patientdeath: '',
            causedeath: '',
            deathdate: '',
            AEhospitilization: '',
            illness: '',
            disability: '',
            birthdefect: '',
            cancer: '',
            overdose: '',
            intervention: '',
            indication: '',
            roa: '',
            TherapySD: '',
            therapyque: '',
            TherapyED: '',
            dechallenge: '',
            rechallenge: '',
            sma: '',
            Treatmentque: '',
            isTreatment: '',
            presentstatus: '',
            RecoveryDate: '',
            CM: '',
            PMH: '',
            DRA: '',
            LDSP: ''
        };
    }

    setCaseDetails() {
        let caseDtl = {};
        caseDtl.stage1 = {};
        caseDtl.stage2 = {};
        caseDtl.stage3 = {};
        caseDtl.stage4 = {};
        caseDtl.stage5 = {};
        caseDtl.stage6 = {};
        caseDtl.stage1.userChoice = '';
        caseDtl.stage2.PrePopulate = false;
        caseDtl.stage2.Adverse_Event_MVN = null;
        caseDtl.stage2.FieldBased = '';
        caseDtl.stage2.WinId = '';
        caseDtl.stage2.EmployeeId = '';
        caseDtl.stage2.FirstName = '';
        caseDtl.stage2.LastName = '';
        caseDtl.stage2.Phone = '';
        caseDtl.stage2.Email = '';
        caseDtl.stage2.NEmployeeId = '';
        caseDtl.stage2.NFirstName = '';
        caseDtl.stage2.NName = '';
        caseDtl.stage2.NempEmail = '';
        caseDtl.stage2.NempPhone = '';
        caseDtl.stage2.MaskedPhone = '';
        caseDtl.stage2.MaskedEmail = '';
        caseDtl.stage2.MaskedFirstName = '';
        caseDtl.stage2.PSPProgramName = '';
        caseDtl.stage2.PSPCompany = '';
        caseDtl.stage2.PSPNumber = '';
        caseDtl.stage2.PSPProgramOther = '';
        caseDtl.stage2.PSPCompanyOther = '';
        caseDtl.stage2.PSPNumberOther = '';
        caseDtl.stage2.PatientID = '';
        caseDtl.stage2.Agentname = '';
        caseDtl.stage2.licensedHCP = '';
        caseDtl.stage2.hcpFirstName = '';
        caseDtl.stage2.hcpLastName = '';
        caseDtl.stage2.hcpPhone = '';
        caseDtl.stage2.hcpEmail = '';
        caseDtl.stage2.hcpAddress = '';
        caseDtl.stage2.hcpCity = '';
        caseDtl.stage2.hcpZip = '';
        caseDtl.stage2.hcpState = '';
        caseDtl.stage2.HCPType = '';
        caseDtl.stage2.HBPType = '';
        caseDtl.stage2.hcpFacilityName = '';
        caseDtl.stage2.hcpCredential = '';
        caseDtl.stage3.ReporterTypeLabel = '';
        caseDtl.stage3.ReporterType = '';
        caseDtl.stage3.RepFirstName = '';
        caseDtl.stage3.RepLastName = '';
        caseDtl.stage3.RepPhone = '';
        caseDtl.stage3.RepEmail = '';
        caseDtl.stage3.RepAddress = '';
        caseDtl.stage3.RepCity = '';
        caseDtl.stage3.RepZip = '';
        caseDtl.stage3.RepState = '';
        caseDtl.stage3.RepType = '';
        caseDtl.stage3.RepCredential = '';
        caseDtl.stage3.RepFacilityName = '';
        caseDtl.stage3.ReporterHCPSame = '';
        caseDtl.stage3.PatientsHC = '';
        caseDtl.stage3.HCPFirstName = '';
        caseDtl.stage3.HCPLastName = '';
        caseDtl.stage3.HCPPhone = '';
        caseDtl.stage3.HCPEmail = '';
        caseDtl.stage3.HCPAddress = '';
        caseDtl.stage3.HCPCity = '';
        caseDtl.stage3.HCPZip = '';
        caseDtl.stage3.HCPState = '';
        caseDtl.stage3.HCPType = '';
        caseDtl.stage3.HCPFacilityName = '';
        caseDtl.stage3.HCPPermission = '';
        caseDtl.stage3.HCPCredential = '';
        caseDtl.stage3.PatientFirstName = '';
        caseDtl.stage3.PatientLastName = '';
        caseDtl.stage3.PatientDOB = '';
        caseDtl.stage3.PatientAge = '';
        caseDtl.stage3.PatientGender = '';
        caseDtl.stage3.isPatientPregnant = '';
        caseDtl.stage3.GestationOrLMP = '';
        caseDtl.stage5.MPI = '';
        caseDtl.stage5.AE = '';
        caseDtl.stage5.CAD = '';
        caseDtl.stage5.AOD = '';
        caseDtl.stage6.patientdeath = '';
        caseDtl.stage6.causedeath = '';
        caseDtl.stage6.deathdate = '';
        caseDtl.stage6.AEhospitilization = '';
        caseDtl.stage6.illness = '';
        caseDtl.stage6.disability = '';
        caseDtl.stage6.birthdefect = '';
        caseDtl.stage6.cancer = '';
        caseDtl.stage6.overdose = '';
        caseDtl.stage6.intervention = '';
        caseDtl.stage6.indication = '';
        caseDtl.stage6.roa = '';
        caseDtl.stage6.TherapySD = '';
        caseDtl.stage6.therapyque = '';
        caseDtl.stage6.TherapyED = '';
        caseDtl.stage6.dechallenge = '';
        caseDtl.stage6.rechallenge = '';
        caseDtl.stage6.sma = '';
        caseDtl.stage6.Treatmentque = '';
        caseDtl.stage6.isTreatment = '';
        caseDtl.stage6.presentstatus = '';
        caseDtl.stage6.RecoveryDate = '';
        caseDtl.stage6.CM = '';
        caseDtl.stage6.PMH = '';
        caseDtl.stage6.DRA = '';
        caseDtl.stage6.LDSP = '';
        return caseDtl;
    }

}