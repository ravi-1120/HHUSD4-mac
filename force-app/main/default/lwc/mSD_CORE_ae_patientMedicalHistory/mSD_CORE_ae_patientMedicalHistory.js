import { LightningElement,track,api } from 'lwc';
import getPicklist from '@salesforce/apex/MSD_CORE_ae_PortalStageHandler.getPicklist';
import SKIPTOREVIEW from '@salesforce/label/c.MSD_CORE_ae_Skip_to_Review';
import NEXTBUTTON from '@salesforce/label/c.MSD_CORE_ae_Next_Button';
import PREVIOUSBUTTON from '@salesforce/label/c.MSD_CORE_ae_Previous_Button';
import AECAUSEHOSPITALIZATION from '@salesforce/label/c.MSD_CORE_ae_AE_cause_Hospitalization';
import AECAUSEHOSPITALIZATIONHELP from '@salesforce/label/c.MSD_CORE_ae_AE_cause_Hospitalization_Help';
import PREVENTSERIOUSEVENT from '@salesforce/label/c.MSD_CORE_ae_Prevent_Serious_Event_label';
import PREVENTSERIOUSEVENTHELP from '@salesforce/label/c.MSD_CORE_ae_Prevent_Serious_Event';
import FollowingSeriousCriteria from '@salesforce/label/c.MSD_CORE_ae_Following_Serious_Criteria';
import PatientDie from '@salesforce/label/c.MSD_CORE_ae_Patient_Die';
import FillOutFields from '@salesforce/label/c.MSD_CORE_ae_Fill_Out_Fields';
import RouteOfAdministration from '@salesforce/label/c.MSD_CORE_ae_Route_of_Administration';
import TheraphyStartDate from '@salesforce/label/c.MSD_CORE_ae_Therapy_SD';
import Discontinued from '@salesforce/label/c.MSD_CORE_ae_Discontinued';
import TheraphyEndDate from '@salesforce/label/c.MSD_CORE_ae_Theraphy_End_Date';
import TheraphyDechallenge from '@salesforce/label/c.MSD_CORE_ae_Theraphy_Dechallenge';
import TheraphyRechallenge from '@salesforce/label/c.MSD_CORE_ae_Theraphy_Rechallenge';
import SoughtMedicalAttention from '@salesforce/label/c.MSD_CORE_ae_Sought_Medical_Attention';
import WasTreatmentGiven from '@salesforce/label/c.MSD_CORE_ae_Was_Treatment_Given_for_AE';
import PresentStatus from '@salesforce/label/c.MSD_CORE_ae_Present_Status';
import RecoveryDate from '@salesforce/label/c.MSD_CORE_ae_Recovery_Date';
import MedicalHistory from '@salesforce/label/c.MSD_CORE_ae_Medical_History_Known';
import Concomitant from '@salesforce/label/c.MSD_CORE_ae_Concomitant';
import PertinentMedical from '@salesforce/label/c.MSD_CORE_ae_Pertinent_Medical_History';
import DrugReactions from '@salesforce/label/c.MSD_CORE_ae_Drug_Reactions';
import LabDiagnostics from '@salesforce/label/c.MSD_CORE_ae_Lab_Diagnostics';
import YesTreatment from '@salesforce/label/c.MSD_CORE_ae_Yes_Treatment';
import CauseOfDeath from '@salesforce/label/c.MSD_CORE_ae_Yes_Cause_of_Death';
import DateOfDeath from '@salesforce/label/c.MSD_CORE_ae_Yes_Date_of_Death';
import ThreatningIllness from '@salesforce/label/c.MSD_CORE_ae_Threatning_Illness';
import Disability from '@salesforce/label/c.MSD_CORE_ae_Disability_Or_Incapacity';
import BirthDefect from '@salesforce/label/c.MSD_CORE_ae_Birth_Defect';
import AECancer from '@salesforce/label/c.MSD_CORE_ae_AE_Cancer';
import PatientOverdose from '@salesforce/label/c.MSD_CORE_ae_Patient_Overdose';
import Indication from '@salesforce/label/c.MSD_CORE_ae_Indication';

export default class MSD_CORE_ae_patientMedicalHistory extends LightningElement {

    @track inputValues = {};
    @track activeSections = ['1', '2', '3'];
    @track SeriousCriteriaOptions = [];
    @track TreatmentOptions = [];
    @track isyes = false;
    @track istherapy = false;
    @track isPatientYes = false;
    @track isRecovered = false;
    @api caseDetails;
    @api stageId; 
    @api editedSection;
    @api portalSetting;

    label = {
        SKIPTOREVIEW,
        NEXTBUTTON,
        PREVIOUSBUTTON,
        AECAUSEHOSPITALIZATION,
        AECAUSEHOSPITALIZATIONHELP,
        PREVENTSERIOUSEVENT,
        PREVENTSERIOUSEVENTHELP,
        FollowingSeriousCriteria,
        PatientDie,
        FillOutFields,
        RouteOfAdministration,
        TheraphyStartDate,
        Discontinued,
        TheraphyEndDate,
        TheraphyDechallenge,
        TheraphyRechallenge,
        SoughtMedicalAttention,
        WasTreatmentGiven,
        PresentStatus,
        RecoveryDate,
        MedicalHistory,
        Concomitant,
        PertinentMedical,
        DrugReactions,
        LabDiagnostics,
        YesTreatment,
        DateOfDeath,
        CauseOfDeath,
        ThreatningIllness,
        Disability,
        BirthDefect,
        AECancer,
        PatientOverdose,
        Indication
    }
    get StatusOptions() {
        return this.processOptions(this.portalSetting.Present_Status__c, ';');
    }

    get rechallengeOptions() {
        return this.processOptions(this.portalSetting.Rechallenge__c, ';');
    }

    get dechallengeOptions() {
        return this.processOptions(this.portalSetting.Dechallenge__c, ';');
    }

    get patientOptions() {
        return this.processOptions(this.portalSetting.Reporting_AEs_for_multiple_patients__c, ';');
    }

    processOptions(rawOptions, delimiter) {
        return rawOptions ? rawOptions.split(delimiter).map(option => {
            const [label, value] = option.split(':');
            return { label: label?.trim(), value: value?.trim() || label?.trim() };
        }) : [];
    }
    connectedCallback(){
        this.prepopulateInputs();
        this.configurePicklist();
    }
    get showSkipButton() {
        return this.editedSection === this.stageId;
    }

        prepopulateInputs() {
        if (this.caseDetails !== undefined) {
                this.inputValues = Object.assign(this.inputValues, this.caseDetails.stage6);
            }
            if (this.inputValues) {
                this.istherapy = this.inputValues.istherapy || false;
                this.isRecovered = this.inputValues.isRecovered || false;
                this.isyes = this.inputValues.isyes || false;
                this.istreatment = this.inputValues.istreatment || false;
            }
        }
        configurePicklist(){
            getPicklist({ objectApiName: 'Case', fieldApiName: 'MSD_CORE_AE_Was_Treatment_Given_for_AE__c' })
            .then(result => {
                this.TreatmentOptions = result.map(entry => ({ label: entry.label, value: entry.value }));
            })
            .catch(error => {
                console.error('Error retrieving Treatment picklist values', error);
            });
            getPicklist({ objectApiName: 'Case', fieldApiName: 'MSD_CORE_AE_Intervention_Prevent_Serious__c' })
            .then(result => {
                this.SeriousCriteriaOptions = result.map(entry => ({ label: entry.label, value: entry.value }));
            })
            .catch(error => {
                console.error('Error retrieving Serious CriteriaOptions picklist values', error);
            });
        }
    

    handleInput(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        this.inputValues[fieldName] = fieldValue;
        // console.log('inputValues-> '+JSON.stringify(this.inputValues));
        if(fieldName === 'patientdeath') {
            this.handlePatientDeath();
        }
        if(fieldName === 'Treatmentque') {
            this.handleTreatChange();
        }
        if(fieldName === 'therapyque') {
            this.handleTherapy();
        }
        if(fieldName === 'presentstatus') {
            this.handleStatus();
        }
        this.inputValues.istherapy = this.istherapy;
        this.inputValues.isRecovered = this.isRecovered;
        this.inputValues.isyes = this.isyes;
        this.inputValues.istreatment = this.istreatment;
    }
    handlePatientDeath(){
        if (this.inputValues.patientdeath === 'Yes') {
            this.isyes = true;
       } else {
             this.isyes = false;
             this.inputValues.causedeath = null;
             this.inputValues.deathdate = null; 
       }
    }
    handleTreatChange() {
    if (this.inputValues.Treatmentque === 'Yes') {
        this.istreatment = true;
   } else {
         this.istreatment = false;
         this.inputValues.isTreatment = null; 
   }
}
handleStatus() {
    if(this.inputValues.presentstatus === 'Recovered') {
        this.isRecovered = true;
    } else {
        this.isRecovered = false;
        this.inputValues.RecoveryDate = null; 
    }
}
handleTherapy() {
    if(this.inputValues.therapyque === 'Yes'){
        this.istherapy = true;
    } else {
        this.istherapy = false;
        this.inputValues.TherapyED = null;
        this.inputValues.dechallenge = null;
        this.inputValues.rechallenge = null;
    }
}

    handlePrevNext(event){
        let choice = event.target.name;
        const stage6DetailsEvent = new CustomEvent("stagedetails", {
        detail: {
            'stageInputs': {
                'stage6': this.inputValues,
            },
            'action': choice,
          }
        });

    this.dispatchEvent(stage6DetailsEvent);
    }
}