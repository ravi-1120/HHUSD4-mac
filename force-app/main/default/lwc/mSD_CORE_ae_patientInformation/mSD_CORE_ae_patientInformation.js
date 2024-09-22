import getRecordTypeId from "@salesforce/apex/MSD_CORE_ae_CaseController.getRecordTypeId";
import getPicklist from '@salesforce/apex/MSD_CORE_ae_PortalStageHandler.getPicklist';
import Addressline2 from '@salesforce/label/c.MSD_CORE_ae_Address_Line2';
import Addressline1 from '@salesforce/label/c.MSD_CORE_ae_Address_Line_1';
import ADVERSEEVENTFORTHISPATIENT from '@salesforce/label/c.MSD_CORE_ae_Adverse_Event_for_this_patient_to_Merck';
import AREYOUPATIENT from '@salesforce/label/c.MSD_CORE_ae_Are_You_Patient';
import city from '@salesforce/label/c.MSD_CORE_ae_City';
import Country from '@salesforce/label/c.MSD_CORE_ae_Country';
import Email from '@salesforce/label/c.MSD_CORE_ae_Email';
import EVENTCASENUMBER from '@salesforce/label/c.MSD_CORE_ae_Event_Case_number_if_available';
import firstname from '@salesforce/label/c.MSD_CORE_ae_First_Name';
import IsReporterHCPSame from '@salesforce/label/c.MSD_CORE_ae_Hcp_Information_Noted';
import HEALTHCAREPROVIDER from '@salesforce/label/c.MSD_CORE_ae_Healthcare_Provider_Information';
import ISPATIENTPREGNANT from '@salesforce/label/c.MSD_CORE_ae_Is_Patient_Pregnant';
import IsPatientReported from '@salesforce/label/c.MSD_CORE_ae_Is_Patient_Reported_this_AE';
import Lastname from '@salesforce/label/c.MSD_CORE_ae_Last_Name';
import LASTNAMEFIELDHELP from '@salesforce/label/c.MSD_CORE_ae_Last_Name_Field_Help';
import NEXTBUTTON from '@salesforce/label/c.MSD_CORE_ae_Next_Button';
import PATIENTAGE from '@salesforce/label/c.MSD_CORE_ae_Patient_Age';
import PATIENTDATEOFBIRTH from '@salesforce/label/c.MSD_CORE_ae_Patient_Date_of_Birth';
import PATIENTFIRSTNAME from '@salesforce/label/c.MSD_CORE_ae_Patient_First_Name';
import PATIENTGENDER from '@salesforce/label/c.MSD_CORE_ae_Patient_Gender';
import patientInformation from '@salesforce/label/c.MSD_CORE_ae_Patient_Information';
import PATIENTLASTNAME from '@salesforce/label/c.MSD_CORE_ae_Patient_Last_Name';
import patientReporterInformation from '@salesforce/label/c.MSD_CORE_ae_Patient_Reporter_Information';
import PermissionToContactOffice from '@salesforce/label/c.MSD_CORE_ae_Permission_To_Contact_Office';
import PermissionToContact from '@salesforce/label/c.MSD_CORE_ae_Permission_To_Contact_hcp';
import PERMISSIONTOCONTACT from '@salesforce/label/c.MSD_CORE_ae_Permission_to_Contact';
import phone from '@salesforce/label/c.MSD_CORE_ae_Phone';
import PracticeorFacilityName from '@salesforce/label/c.MSD_CORE_ae_Practice_or_Facility_Name';
import PREGNANCYGESTATION from '@salesforce/label/c.MSD_CORE_ae_Pregnancy_Gestation_LMP';
import PREVIOUSBUTTON from '@salesforce/label/c.MSD_CORE_ae_Previous_Button';
import REPORTERINFORMATION from '@salesforce/label/c.MSD_CORE_ae_Reporter_Information';
import SKIPTOREVIEW from '@salesforce/label/c.MSD_CORE_ae_Skip_to_Review';
import State from '@salesforce/label/c.MSD_CORE_ae_State';
import TYPEHEALTHCARE from '@salesforce/label/c.MSD_CORE_ae_Type_of_HealthCare_Provider';
import WhoReportedAe from '@salesforce/label/c.MSD_CORE_ae_Who_Reported_AE';
import zipcode from '@salesforce/label/c.MSD_CORE_ae_Zip_Code';
import HCPTypeField from "@salesforce/schema/MSD_CORE_AE_Contact__c.MSD_CORE_Type__c";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { LightningElement, api, track, wire } from 'lwc';


export default class MSD_CORE_ae_patientInformation extends LightningElement {

    @api caseDetails;
    @track inputValues = {RepCountry:'US',HCPCountry:'US'};
    @track genderOptions = [];
    @track pregnantOptions = [];
    @track CredOptions = [];
    @track hcpFieldDisabled = {
        HCPFirstName: false,
        HCPLastName: false,
        HCPPhone: false,
        HCPEmail: false,
        HCPAddress: false,
        HCPAddressLine2: false,
        HCPCity: false,
        HCPType: false,
        HCPZip: false,
        HCPState: false,
        HCPFacilityName: false,
        HCPCredential: false
    };
    @track patientFieldDisabled = {
        PatientFirstName: false,
        PatientLastName: false,
    }; 
    @track RepFieldDisabled = {
        RepFirstName: false,
        RepLastName: false,
        RepPhone: false,
        RepEmail: false,
        RepCountry: false,
    }
    @api stageId;
    @api editedSection;
    @track permissionOptions;
    @track isHealthcareProvider = null;
    aeRecordTypeId;
    @track stateOptions = [];
    @track hcpTypeOptions = [];
    @track activeSections = ['ReporterInfo', 'HCPInfo' ,'PatientInfo'];
    disableFields = false;
    hcpdisable = false;
    isFemale;
    ifPregnantYes;
    isRepFemale;
    ifRepPregnantYes;
    @api portalSetting;
    searchTerm = '';
    @track hcpCredentialSearchTerm = '';
    @track repCredentialSearchTerm = '';
    @track repStateSearchTerm = '';
    @track hcpStateSearchTerm = '';
    CredOptions = [];
    @track selectedValues = {
        repState: '',
        repCredential: '',
        hcpState: '',
        hcpCredential: '',
    }; 
    @track filteredResults = {
        hcpCredential: [],
        repCredential: [],
        repState: [],
        hcpState: []
    };
    get hbpTypeOptions() {
        return this.processOptions(this.portalSetting.HBP_Type__c, ';');
    }

    label = {
        EVENTCASENUMBER,
        ADVERSEEVENTFORTHISPATIENT,
        WhoReportedAe,
        IsReporterHCPSame,
        IsPatientReported,
        PATIENTFIRSTNAME,
        PATIENTLASTNAME,
        PATIENTDATEOFBIRTH,
        PATIENTAGE,
        PATIENTGENDER,
        ISPATIENTPREGNANT,
        HEALTHCAREPROVIDER,
        TYPEHEALTHCARE,
        PERMISSIONTOCONTACT,
        PREGNANCYGESTATION,
        LASTNAMEFIELDHELP,
        NEXTBUTTON,
        PermissionToContact,
        PermissionToContactOffice,
        PREVIOUSBUTTON,
        SKIPTOREVIEW,
        REPORTERINFORMATION,
        firstname,
        Addressline1,
        Lastname,
        phone,
        Email,
        Addressline2,
        city,
        zipcode,
        State,
        Country,
        PracticeorFacilityName,
        patientReporterInformation,
        patientInformation,
        AREYOUPATIENT
    }
    get ifHCP() {
        return (this.inputValues.ReporterType === 'INDIV HEALTHCARE PROF');
    }
    get ifHBP() {
        return (this.inputValues.ReporterType === 'HEALTHCARE BUSINESS PROF');
    }
    get ifPatient(){
        let userChoice = this.caseDetails.stage1['userChoice'];
        return this.inputValues.ReporterType === 'Patient' && this.inputValues.ReporterType !== null && userChoice !== 'Healthcare Professional';
    }
    get showSkipButton() {
        return this.editedSection === this.stageId;
    }
    get reporterOptions() {
        let options = this.processOptions(this.portalSetting.Reporters__c, ';');
        if (this.caseDetails.stage1['userChoice'] === 'PSP Representative') {
            options = options.filter(option => option.value!== 'Patient');
        }
        return options;
    }

    get HCPOptions() {
        return this.processOptions(this.portalSetting.Permission_to_Contact__c, ';');
    }
    get patientReporterOptions() {
        return this.processOptions(this.portalSetting.Patient_Reported_this_AE_to_you__c, ';');
    }
    get CountryOptions(){
        const options = this.processOptions(this.portalSetting.Country__c, ';');
        return options.sort((a, b) => {
            if (a.label === 'United States') return -1;
            if (b.label === 'United States') return 1; 
            return a.label.localeCompare(b.label);   
        });
    }
    get ContactOptions() {
        return this.processOptions(this.portalSetting.Permission__c, ';');
    }
    get Options() {
        return this.processOptions(this.portalSetting.First_Report__c, ';');
    }
    get PatientsHCP() {
        return this.processOptions(this.portalSetting.Patients_HCP__c, ';');
    }

    get isMerckEmployee() {
        let userChoice = this.caseDetails.stage1['userChoice'];
        return userChoice === 'Merck Employee';
    }
    get NonFieldBased (){
        let Nonfieldbased = this.caseDetails.stage2['FieldBased'];
        return Nonfieldbased === 'no';
    }
    get isHCP() {
        let userChoice = this.caseDetails.stage1['userChoice'];
        return userChoice === 'Healthcare Professional';
    }
    get isLicensedHCP() {
        let userChoice = this.caseDetails.stage1['userChoice'];
        let licensedHCP = this.caseDetails.stage2['licensedHCP'];
        return ( licensedHCP === 'Licensed Healthcare Professional' && userChoice === 'Healthcare Professional');
    }
    get isLicensedHBP() {
        let userChoice = this.caseDetails.stage1['userChoice'];
        let licensedHBP = this.caseDetails.stage2['licensedHCP'];
        return ( licensedHBP === 'Healthcare Office Worker or Facility Personnel' && userChoice === 'Healthcare Professional');
    }
    get isType() {
        const userChoice = this.caseDetails.stage1['userChoice'];
        return  (this.inputValues.PatientsHC === 'No' && userChoice === 'Healthcare Professional') || this.inputValues.ReporterType === 'INDIV HEALTHCARE PROF';
    }
    get firstReport(){
        return this.inputValues['firstReport'] == 'No';
    }
    get PatientReporter() {
        return this.inputValues.ReporterType === 'Patient';
    }
    get fillHCP() {
        return this.inputValues['PatientsHC'] == 'No';
    }
    get populateHCP() {
        const hasPatientsHCValue = !!this.inputValues['PatientsHC'];
        let licensedHCP = this.caseDetails.stage2['licensedHCP'];
        const isReporterTypeValid = this.inputValues['ReporterType'] && this.inputValues['ReporterType'] !== 'INDIV HEALTHCARE PROF';
        const isReporterHCPWithNo = this.inputValues['ReporterType'] === 'INDIV HEALTHCARE PROF' && this.inputValues['ReporterHCPSame'] === 'No';
        return hasPatientsHCValue || isReporterTypeValid || isReporterHCPWithNo || licensedHCP === 'Healthcare Office Worker or Facility Personnel';
    }
    get hasHCPCredentialSearchResults() {
        return this.hcpCredentialSearchTerm.length > 0 && this.filteredResults.hcpCredential.length > 0;
    }
    get hasRepCredentialSearchResults() {
        return this.repCredentialSearchTerm.length > 0 && this.filteredResults.repCredential.length > 0;
    }
    get hasRepStateSearchResults() {
        return this.repStateSearchTerm.length > 0 && this.filteredResults.repState.length > 0;
    }
    
    get hasHCPStateSearchResults() {
        return this.hcpStateSearchTerm.length > 0 && this.filteredResults.hcpState.length > 0;
    }

    processOptions(rawOptions, delimiter) {
        return rawOptions ? rawOptions.split(delimiter).map(option => {
            const [label, value] = option.split(':');
            return { label: label?.trim(), value: value?.trim() || label?.trim() };
        }) : [];
    }

    connectedCallback() {
        this.fetchRecordType();
        this.prepopulateInputs();
        this.configurePicklist();
        // if(this.isLicensedHBP){
        //     this.clearHCPFields();
        // }
        this.syncWithReporter();
        this.clearValidationMessages();
        console.log('caseDetails----->' + JSON.stringify(this.caseDetails));
        console.log('caseDetails----->' + JSON.stringify(this.caseDetails.stage2));
        if(this.isMerckEmployee && this.inputValues.ReporterType === 'Patient'){
            this.RepFromStage2();
        }
        if (this.isHCP && this.inputValues['PatientsHC'] === 'Yes') {
            this.HCPFromStage2();
        }
        if(this.ifHCP && this.inputValues['ReporterHCPSame'] === 'Yes'){
            this.updateHCPFields();
        }
    }

    fetchRecordType() {
        getRecordTypeId({ devName: 'Adverse_Event_MVN', sObjectType: 'MSD_CORE_AE_Contact__c' })
            .then(result => {
                this.aeRecordTypeId = result;
            })
            .catch(error => {
                console.log('Error RecType-> ' + error);
            })
    }

    configurePicklist() {
        const picklistFieldsConfig = [
            { objectApiName: 'MSD_CORE_AE_Contact__c', fieldApiName: 'MSD_CORE_Permission_to_Contact__c', propertyName: 'permissionOptions' },
            { objectApiName: 'Case', fieldApiName: 'MSD_CORE_AE_Patient_Gender__c', propertyName: 'genderOptions' },
            { objectApiName: 'Case', fieldApiName: 'MSD_CORE_AE_Is_Patient_Pregnant__c', propertyName: 'pregnantOptions' },
            { objectApiName: 'MSD_CORE_AE_Contact__c', fieldApiName: 'MSD_CORE_Credentials__c', propertyName: 'CredOptions' },
            { objectApiName: 'MSD_CORE_AE_Contact__c', fieldApiName: 'MSD_CORE_State_Province__c', propertyName: 'stateOptions' }
        ];
        picklistFieldsConfig.forEach(({ objectApiName, fieldApiName, propertyName }) => {
            getPicklist({ objectApiName, fieldApiName })
                .then(result => {
                    this[propertyName] = result.map(entry => ({ label: entry.label, value: entry.value }));
                    if (propertyName === 'stateOptions') {
                        this.filteredResults.state = [...this[propertyName]];
                    }
                    if (propertyName === 'CredOptions') {
                        this.filteredResults.state = [...this[propertyName]];
                    }
                })
                .catch(error => {
                    console.error(`Error retrieving ${fieldApiName} picklist values`, error);
                });
        });
    }
    prepopulateInputs() {
        if (this.caseDetails !== undefined) {
            this.inputValues = Object.assign(this.inputValues, this.caseDetails.stage3);
            this.HCPFromStage2();
            if (this.inputValues.isPatientReporter === 'Yes') {
                this.disableFields = true;
            }
            if(this.isMerckEmployee && this.inputValues.ReporterType === 'Patient'){
                this.RepFromStage2();
            }
            if (this.inputValues.ReporterType !== '') {
                this.activeSections.push('HCPInfo');
            }
            if(this.isHCP && this.inputValues.isHealthcareProvider !== null){
                this.showSecondQuestion = true;
            }
            this.isHealthcareProvider = this.inputValues.isHealthcareProvider || null;
            this.isFemale = this.inputValues.isFemale || false;
            this.isRepFemale = this.inputValues.isRepFemale || false;
            this.ifPregnantYes = this.inputValues.ifPregnantYes || false;
            this.ifRepPregnantYes = this.inputValues.ifRepPregnantYes || false;
            if (this.caseDetails.stage2 && this.inputValues['PatientsHC'] === 'Yes' && this.inputValues['isPatientReporter'] === 'Yes') {
                console.log('Method Executing for Patient Name Sync with HCP');
                this.inputValues.PatientFirstName = this.caseDetails.stage2.hcpFirstName;
                console.log('Patient First Name--->' + this.inputValues.PatientFirstName);
                this.inputValues.PatientLastName = this.caseDetails.stage2.hcpLastName;
                console.log('Patient Last Name--->' + this.inputValues.PatientLastName);
            }

        }
    }
    
    RepFromStage2(){
        console.log('Method Executing');
        const RepFieldMapping = this.NonFieldBased ? {
            NName: 'RepLastName',
            NFirstName: 'RepFirstName',
            NempPhone: 'RepPhone',
            NempEmail: 'RepEmail',
            NempCountry: 'RepCountry'
        } : {
            LastName: 'RepLastName',
            MaskedFirstName: 'RepFirstName',
            MaskedPhone: 'RepPhone',
            MaskedEmail: 'RepEmail'

        };
        Object.keys(RepFieldMapping).forEach(stage2Field => {
            const stage3Field = RepFieldMapping[stage2Field];
            if (this.caseDetails.stage2[stage2Field]) {
                this.inputValues[stage3Field] = this.caseDetails.stage2[stage2Field];
                this.RepFieldDisabled[stage3Field] = true;
            }  if (!this.inputValues[stage3Field]) {
            this.RepFieldDisabled[stage3Field] = false;
        }
        });    
    }
    
    HCPFromStage2() {

        console.log('Method Executing');
        if (this.caseDetails.stage2 && this.inputValues['PatientsHC'] === 'Yes'&& this.isLicensedHCP) {
            console.log('Method HCPFromStage2 started')
            const hcpFieldMapping = {
                hcpFirstName: 'HCPFirstName',
                hcpLastName: 'HCPLastName',
                hcpPhone: 'HCPPhone',
                hcpEmail: 'HCPEmail',
                hcpAddress: 'HCPAddress',
                hcpAddressLine2: 'HCPAddressLine2',
                hcpCity: 'HCPCity',
                hcpCountry: 'HCPCountry',
                HCPType:'HCPType',
                hcpZip: 'HCPZip',
                hcpState: 'HCPState',
                hcpFacilityName: 'HCPFacilityName',
                hcpCredential: 'HCPCredential'
            };
            Object.keys(hcpFieldMapping).forEach(stage2Field => {
                const stage3Field = hcpFieldMapping[stage2Field];
                if (this.caseDetails.stage2[stage2Field]) {
                    this.inputValues[stage3Field] = this.caseDetails.stage2[stage2Field];
                    const inputComponent = this.template.querySelector('lightning-input[name="${stage3Field}"]');
                    if (inputComponent) {
                        console.log('Method Executing for HCP Fields for removing custom validation');
                        inputComponent.setCustomValidity('');
                        inputComponent.reportValidity();
                        console.log('Method Executing for HCP Fields for removing custom validation is Finished');
                    }
                    this.hcpFieldDisabled[stage3Field] = true;

                } else if (!this.inputValues[stage3Field]) {
                    this.hcpFieldDisabled[stage3Field] = false;
                    const inputComponent = this.template.querySelector(`lightning-input[name="${stage3Field}"]`);
                    if (inputComponent) {
                        console.log('Method Executing for HCP Fields for removing custom validation');
                        inputComponent.setCustomValidity('');
                        inputComponent.reportValidity();
                    }
                }
            });
        }
        this.syncPatientNameWithHCP();
    }

    syncPatientNameWithHCP() {
        if (this.inputValues['PatientsHC'] === 'Yes' && this.inputValues['isPatientReporter'] === 'Yes' && this.isLicensedHCP) {
            this.inputValues.PatientFirstName = this.caseDetails.stage2.hcpFirstName;
            this.inputValues.PatientLastName = this.caseDetails.stage2.hcpLastName;
            this.patientFieldDisabled.PatientFirstName = !!this.inputValues.PatientFirstName;
            this.patientFieldDisabled.PatientLastName = !!this.inputValues.PatientLastName;
            if (this.inputValues.PatientFirstName == null) {
                this.patientFieldDisabled.PatientFirstName = false;
            }
            if (this.inputValues.PatientLastName == null) {
                this.patientFieldDisabled.PatientLastName = false; 
            }
        }        
    }
    
    clearHCPFields() {
        const fields = [
            'HCPFirstName', 'HCPLastName', 'HCPPhone', 'HCPEmail',
            'HCPAddress', 'HCPAddressLine2', 'HCPCity', 'HCPZip','HCPCountry',
            'HCPState', 'HCPType', 'HCPFacilityName', 'HCPCredential'
        ];
        fields.forEach(field => {
            this.inputValues[field] = null;
            this.hcpFieldDisabled[field] = false;
            const inputElement = this.template.querySelector(`lightning-input[field-name="${field}"]`);
            if (inputElement) {
                inputElement.setCustomValidity('');
                inputElement.reportValidity(); 
            }
        });
        this.inputValues['HCPCountry'] = 'US';
    }
    handleHCPRepSame(event) {
        if (event.target.value === 'Yes') {
            this.inputValues['HCPFirstName'] = this.inputValues['RepFirstName'];
            this.inputValues['HCPLastName'] = this.inputValues['RepLastName'];
            this.inputValues['HCPPhone'] = this.inputValues['RepPhone'];
            this.inputValues['HCPEmail'] = this.inputValues['RepEmail'];
            this.inputValues['HCPAddress'] = this.inputValues['RepAddress'];
            this.inputValues['HCPAddressLine2'] = this.inputValues['RepAddressLine2'];
            this.inputValues['HCPCity'] = this.inputValues['RepCity'];
            this.inputValues['HCPZip'] = this.inputValues['RepZip'];
            this.inputValues['HCPState'] = this.inputValues['RepState'];
            this.inputValues['HCPType'] = this.inputValues['RepType'];
            this.inputValues['HCPFacilityName'] = this.inputValues['RepFacilityName'];
        }else{
            this.inputValues['HCPFirstName'] = '';
            this.inputValues['HCPLastName'] = '';
            this.inputValues['HCPPhone'] = '';
            this.inputValues['HCPEmail'] = '';
            this.inputValues['HCPAddress'] = '';
            this.inputValues['HCPAddressLine2'] = '';
            this.inputValues['HCPCity'] = '';
            this.inputValues['HCPZip'] = '';
            this.inputValues['HCPState'] = '';
            this.inputValues['HCPType'] = '';
            this.inputValues['HCPFacilityName'] = '';
        }
        this.handleInput(event);
    }
    handleInput(event) {
        const { name: fieldName, value: fieldValue } = event.target;
        this.inputValues[fieldName] = fieldValue;
        event.target.setCustomValidity('');
        if (fieldName === 'HCPFirstName' || fieldName === 'HCPLastName' || fieldName === 'RepFirstName' || fieldName === 'RepLastName') {
            this.inputValues['isPatientReporter'] = null;
            this.clearPatientInfo();
        }
        if (fieldName === 'HCPState' || fieldName === 'RepState'|| fieldName === 'RepCredential' || fieldName === 'HCPCredential') {
            event.target.setCustomValidity('');
            event.target.reportValidity();
        }
        if (this.ifHCP) {
            if (fieldName === 'RepFirstName' || fieldName === 'RepLastName' || fieldName === 'RepPhone' || fieldName === 'RepEmail' || fieldName === 'RepAddress' || fieldName === 'RepAddressLine2' || fieldName === 'RepCity' || fieldName === 'RepZip' || fieldName === 'RepState' || fieldName === 'RepType' || fieldName === 'RepFacilityName' || fieldName === 'RepCredential') {
            console.log('HCP Info Fields Cleared as there is a change in Reporter Info');
            this.inputValues['ReporterHCPSame'] = null;
            this.clearHCPFields();
            }
        }
        if(fieldName === 'ReporterType'){
            this.clearValidationMessages();
        }

        
        switch (fieldName) {
            case 'PatientsHC':
                this.isHealthcareProvider = fieldValue === 'Yes' ? true : fieldValue === 'No' ? false : null;
                if (fieldValue === 'No' || fieldValue === 'Yes') {
                    this.inputValues['isPatientReporter'] = null
                    this.clearPatientInfo();
                }
                if (fieldValue === 'Yes' && this.isHCP) {
                    this.clearValidationMessages();
                    this.HCPFromStage2();
                    this.hcpdisable = true;
                } else if (fieldValue === 'No') {
                    this.hcpdisable = false;
                    this.clearValidationMessages();
                    this.clearHCPFields();
                }
                break;
            case 'RepGender':
                this.handleRepGender();
                break;
            case 'isRepPregnant':
                this.handleRepPregnant();
                break;
            case 'PatientGender':
                this.handlePatientGender();
                break;
            case 'isPatientPregnant':
                this.handlePregnant();
                break;
            case 'ReporterType':
                this.handleReporterType(event);
                break;
            case 'isPatientReporter':
                this.handlePatientReporter();
            case 'HCPCredential':
                this.hcpCredentialSearchTerm = fieldValue;
                this.filterOptions('hcpCredential');
                break;
            case 'RepCredential':
                this.repCredentialSearchTerm = fieldValue;
                this.filterOptions('repCredential');
                break;
            case 'RepState':
                this.repStateSearchTerm = fieldValue;
                this.filterOptions('repState');
                break;
            case 'HCPState':
                this.hcpStateSearchTerm = fieldValue;
                this.filterOptions('hcpState');
                break;
            case 'ReporterHCPSame':
                if (fieldValue === 'Yes') {
                    console.log('ReporterHCPSame--->' + fieldValue);
                    this.updateHCPFields();
                } else  if (fieldValue === 'No') {
                    console.log('ReporterHCPSame--->' + fieldValue);
                    this.clearHCPFields();  
                }
        }
        this.inputValues.isHealthcareProvider = this.isHealthcareProvider;
        if(this.isHCP && this.inputValues.isHealthcareProvider !== null){
            this.showSecondQuestion = true;
        }
        this.inputValues.isFemale = this.isFemale;
        this.inputValues.isRepFemale = this.isRepFemale;
        this.inputValues.ifPregnantYes = this.ifPregnantYes;
        this.inputValues.ifRepPregnantYes = this.ifRepPregnantYes;
    //     if (this.inputValues.ReporterType === 'INDIV HEALTHCARE PROF' && 
    //     ['RepFirstName', 'RepLastName', 'RepPhone', 'RepEmail', 'RepAddress', 'RepCredential', 'RepAddressLine2', 'RepCity', 'RepZip', 'RepState', 'RepType','RepCountry', 'RepFacilityName', 'ReporterHCPSame'].includes(fieldName)) {
    //     this.clearHCPFields();
    // }
    }
    handleFocus(event) {
        const fieldName = event.target.name;
        if (fieldName === 'hcpCredential') {
            this.filteredResults.hcpCredential = [];
            this.filterOptions('hcpCredential');
        } else if (fieldName === 'RepCredential') {
            this.filteredResults.repCredential = [];
            this.filterOptions('repCredential');
        } else if (fieldName === 'HCPState') {
            this.filteredResults.hcpState = [];
            this.filterOptions('hcpState');
        } else if (fieldName === 'RepState') {
            this.filteredResults.repState = [];
            this.filterOptions('repState');
        }
    }

    
    filterOptions(field) {
        let searchTerm = '';
        let options = [];
    
        if (field === 'repState') {
            searchTerm = this.repStateSearchTerm;
            options = this.stateOptions;
        } else if (field === 'hcpState') {
            searchTerm = this.hcpStateSearchTerm;
            options = this.stateOptions;
        } else if (field === 'hcpCredential') {
            searchTerm = this.hcpCredentialSearchTerm;
            options = this.CredOptions;
        } else if (field === 'repCredential') {
            searchTerm = this.repCredentialSearchTerm;
            options = this.CredOptions;
        }
    
        if (searchTerm) {
            const normalizedSearchTerm = this.normalizeString(searchTerm);
            this.filteredResults[field] = options.filter(option =>
                this.normalizeString(option.label).includes(normalizedSearchTerm));
        } else {
            this.filteredResults[field] = [];
        }
    }
    normalizeString(str) {
        return str.replace(/[^0-9a-zA-Z]/g, '').toLowerCase();
    }
    clearValidationMessages() {
        const allInputFields = this.template.querySelectorAll('lightning-input, lightning-combobox');
        console.log('Method Executing for Clear Validation Messages');
        allInputFields.forEach(input => {
            console.log('Input Field--->' + input.name);
            input.setCustomValidity('');
            input.reportValidity('');
        console.log('Method Executing for Clear Validation Messages is Finished');
        });
    }

 
    

    sortByRelevance(aLabel, bLabel, searchTerm) {
        const normalizedSearchTerm = this.normalizeString(searchTerm);
        const normalizedALabel = this.normalizeString(aLabel);
        const normalizedBLabel = this.normalizeString(bLabel);
        if (normalizedALabel === normalizedSearchTerm) return -1;
        if (normalizedBLabel === normalizedSearchTerm) return 1;
        if (normalizedALabel.startsWith(normalizedSearchTerm)) return -1;
        if (normalizedBLabel.startsWith(normalizedSearchTerm)) return 1;
        return normalizedALabel.indexOf(normalizedSearchTerm) - normalizedBLabel.indexOf(normalizedSearchTerm);
    }   
    handleSelectOption(event) {
        const field = event.currentTarget.dataset.field;
        const selectedValue = event.currentTarget.dataset.value;
        const selectedOption = this.filteredResults[field].find(option => option.value === selectedValue);
        if (selectedOption) {
            if (field === 'hcpCredential') {
                this.inputValues.HCPCredential = selectedOption.label;
                this.selectedValues.hcpCredential = selectedOption.label;
            } else if (field === 'repCredential') {
                this.inputValues.RepCredential = selectedOption.label;
                this.selectedValues.repCredential = selectedOption.label;
            } else if (field === 'hcpState') {
                this.inputValues.HCPState = selectedOption.label;
                this.selectedValues.hcpState = selectedOption.label;
            } else if (field === 'repState') {
                this.inputValues.RepState = selectedOption.label;
                this.selectedValues.repState = selectedOption.label;
            }
            this[`${field}SearchTerm`] = '';
            this.filteredResults[field] = [];
        }
    }
    // handleBlur(event) {
    //     const fieldName = event.target.name;
    //     const fieldValue = event.target.value;
        
    //     const validationRules = {
    //         'HCPCredential': {
    //             isValid: this.inputValues.HCPCredential === this.selectedValues.hcpCredential,
    //             errorMessage: "Please select an option from the dropdown."
    //         },
    //         'RepCredential': {
    //             isValid: this.inputValues.RepCredential === this.selectedValues.repCredential,
    //             errorMessage: "Please select an option from the dropdown."
    //         },
    //         'HCPState': {
    //             isValid: this.inputValues.HCPState === this.selectedValues.hcpState,
    //             errorMessage: "Please select an option from the dropdown."
    //         },
    //         'RepState': {
    //             isValid: this.inputValues.RepState === this.selectedValues.repState,
    //             errorMessage: "Please select an option from the dropdown."
    //         },
    //         'HCPPhone': {
    //             isValid: fieldValue === '' || /^[\d+-]{0,30}$/.test(fieldValue),
    //             errorMessage: "Invalid Phone Number"
    //         },
    //         'HCPEmail': {
    //             isValid: fieldValue === '' || /\S+@\S+\.\S+/.test(fieldValue),
    //             errorMessage: "Invalid Email Address"
    //         },
    //         'RepPhone': {
    //             isValid: fieldValue === '' || /^[\d+-]{0,30}$/.test(fieldValue),
    //             errorMessage: "Invalid Phone Number"
    //         },
    //         'RepEmail': {
    //             isValid: fieldValue === '' || /\S+@\S+\.\S+/.test(fieldValue),
    //             errorMessage: "Invalid Email Address"
    //         }
    //     };
    
    //     const { isValid, errorMessage } = validationRules[fieldName];
    
    //     if (!isValid) {
    //         event.target.setCustomValidity(errorMessage);
    //         this.inputValues[fieldName] = ''; 
    //     } else {
    //         event.target.setCustomValidity('');
    //         this.inputValues[fieldName] = fieldValue;
    //     }
    
    //     event.target.reportValidity();
    
    //     const errorElement = this.template.querySelector(`[data-id="${fieldName}-error"]`);
    //     if (errorElement) {
    //         errorElement.textContent = isValid ? '' : errorMessage;
    //     }
    // }

    handleBlur(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
    
        const validationRules = {
            'HCPCredential': {
                isValid: this.inputValues.HCPCredential === this.selectedValues.hcpCredential,
                errorMessage: "Please select an option from the dropdown."
            },
            'RepCredential': {
                isValid: this.inputValues.RepCredential === this.selectedValues.repCredential,
                errorMessage: "Please select an option from the dropdown."
            },
            'HCPState': {
                isValid: this.inputValues.HCPState === this.selectedValues.hcpState,
                errorMessage: "Please select an option from the dropdown."
            },
            'RepState': {
                isValid: this.inputValues.RepState === this.selectedValues.repState,
                errorMessage: "Please select an option from the dropdown."
            },
            'HCPPhone': {
                isValid: fieldValue === '' || /^[\d+-]{0,30}$/.test(fieldValue),
                errorMessage: "Invalid Phone Number"
            },
            'HCPEmail': {
                isValid: fieldValue === null || fieldValue === '' || /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/.test(fieldValue),
                errorMessage: "Invalid Email Address"
            },
            'RepPhone': {
                isValid: fieldValue === '' || /^[\d+-]{0,30}$/.test(fieldValue),
                errorMessage: "Invalid Phone Number"
            },
            'RepEmail': {
                isValid: fieldValue === null || fieldValue === '' || /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/.test(fieldValue),
                errorMessage: "Invalid Email Address"
            }
        };
    
        const { isValid, errorMessage } = validationRules[fieldName];
    
        if (!isValid) {
            event.target.setCustomValidity(errorMessage);
            this.inputValues[`${fieldName}Valid`] = false;
        } else {
            event.target.setCustomValidity('');
            this.inputValues[fieldName] = fieldValue;
            this.inputValues[`${fieldName}Valid`] = true;
        }
    
        event.target.reportValidity();
    
        const errorElement = this.template.querySelector(`[data-id="${fieldName}-error"]`);
        if (errorElement) {
            errorElement.textContent = isValid ? '' : errorMessage;
        }
    }
    syncWithReporter() {
        if(this.inputValues['isPatientReporter'] === 'Yes'&& (this.isLicensedHBP || this.isLicensedHCP)){
            this.inputValues['PatientFirstName'] = this.caseDetails.stage2['hcpFirstName'];
            this.inputValues['PatientLastName'] = this.caseDetails.stage2['hcpLastName'];
            this.patientFieldDisabled.PatientFirstName = !!this.inputValues['PatientFirstName'];
            this.patientFieldDisabled.PatientLastName = !!this.inputValues['PatientLastName'];

        }
        else if(this.inputValues['isPatientReporter'] === 'Yes'){
        this.inputValues['PatientFirstName'] = this.inputValues['RepFirstName'];
        this.inputValues['PatientLastName'] = this.inputValues['RepLastName'];
        this.patientFieldDisabled.PatientFirstName = !!this.inputValues['PatientFirstName'];
        this.patientFieldDisabled.PatientLastName = !!this.inputValues['PatientLastName'];
        }
    }

    updateHCPFieldDisabledState() {
        this.patientFieldDisabled.PatientFirstName = this.hcpFieldDisabled.HCPFirstName;
        this.patientFieldDisabled.PatientLastName = this.hcpFieldDisabled.HCPLastName;
    }

    validateAllFields() {
        const allInputFields = this.template.querySelectorAll('lightning-input');
        let allAreValid = Array.from(allInputFields).every(input => {
            return input.checkValidity();
        });
        allInputFields.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
            }
        });
        const emailValid = this.inputValues.RepEmailValid !== false;
        const hcpemailValid = this.inputValues.HCPEmailValid !== false; 
        return allAreValid && emailValid && hcpemailValid;
    }
    
    clearPatientInfo() {
        this.patientFieldDisabled.PatientFirstName = false;
        this.patientFieldDisabled.PatientLastName = false;
        const patientFields = [
            'PatientFirstName', 'PatientLastName', 'PatientDOB',
            'PatientAge', 'PatientGender', 'isPatientPregnant', 'GestationOrLMP'
        ];
        patientFields.forEach(field => this.inputValues[field] = null);
        this.isFemale = false;
        this.ifPregnantYes = false;
    }   
    updateHCPFields() {
            const fieldsToUpdate = ['FirstName', 'LastName', 'Phone', 'Email', 'Address', 'AddressLine2', 'City', 'Zip', 'State','Country', 'Type', 'FacilityName', 'Credential'];
            fieldsToUpdate.forEach(field => {
                this.inputValues[`HCP${field}`] = this.inputValues[`Rep${field}`];
                console.log('HCP Fields Updated', JSON.stringify(this.inputValues));
            });
            console.log('HCP Fields Updated');
    }

    handleReporterType(event) {
        const reporterFields = [
            'RepFirstName', 'RepLastName', 'RepPhone', 'RepEmail',
            'RepAddress', 'RepAddressLine2', 'RepCity', 'RepZip',
            'RepState', 'RepType', 'RepFacilityName','RepCredential', 'ReporterHCPSame','RepDOB','RepAge','RepGender','isRepPregnant','RepGestationOrLMP'
        ];
        const hcpFields = [
            'HCPFirstName', 'HCPLastName', 'HCPPhone', 'HCPEmail',
            'HCPAddress', 'HCPAddressLine2', 'HCPCity', 'HCPZip',
            'HCPState', 'HCPType','HCPCountry', 'HCPFacilityName', 'HCPCredential'
        ];
        const patientFields = [
            'isPatientReporter', 'PatientFirstName', 'PatientLastName','PatientDOB','PatientAge','PatientGender','isPatientPregnant','GestationOrLMP','isFemale','ifPregnantYes'
        ];
        const allFieldsToClear = reporterFields.concat(hcpFields, patientFields);
        allFieldsToClear.forEach(field => {
            this.inputValues[field] = null;
        });
        this.disableFields=false;
        this.isFemale = false;
        this.ifPregnantYes = false;
        this.isHealthcareProvider = null;
        this.inputValues['RepCountry'] = 'US';
        this.inputValues['HCPCountry'] = 'US';
        this.activeSections = ['ReporterInfo', 'PatientInfo', 'HCPInfo'];
        if (event.detail.value !== 'INDIV HEALTHCARE PROF') {
            this.inputValues['RepFacilityName'] = '';
        }
        if(event.detail.value === 'Patient'){
            this.RepFromStage2();
        }else{
        this.RepFieldDisabled.RepFirstName = false;
        this.RepFieldDisabled.RepLastName = false;
        this.RepFieldDisabled.RepPhone = false;
        this.RepFieldDisabled.RepEmail = false;
        this.RepFieldDisabled.RepCountry = false;
        }
        const label = event.target.options.find(opt => opt.value === event.detail.value)?.label;
        this.inputValues['ReporterTypeLabel'] = label;
    }
    handleRepGender() {
        if (this.inputValues.RepGender === 'Female') {
            this.isRepFemale = true;
        } else {
            this.isRepFemale = false;
            this.ifRepPregnantYes = false;
            this.inputValues.isRepPregnant = null;
            this.inputValues.RepGestationOrLMP = null;
        }
    }
    validateFields() {
        const allInputFields = this.template.querySelectorAll('lightning-input');
        const allAreValid = Array.from(allInputFields).every(input => {
            return input.checkValidity();
        });
        allInputFields.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
            }
        });
        return allAreValid;
    }
    
    handlePatientGender() {
        if (this.inputValues.PatientGender === 'Female') {
            this.isFemale = true;
        } else {
            this.isFemale = false;
            this.ifPregnantYes = false;
            this.inputValues.isPatientPregnant = null;
            this.inputValues.GestationOrLMP = null;
        }
    }

    HCPProvider() {
        if (this.inputValues.PatientsHC === 'Yes') {
            this.isHealthcareProvider = true;
        }else{
            this.isHealthcareProvider = false;
        }
    }

    get PatientLabel() {
        return this.isHCP ? this.label.IsPatientReported : this.label.patientReporterInformation;
    }

    get questionLabel() {
        return this.isHealthcareProvider ? this.label.PermissionToContact : this.label.PermissionToContactOffice;
    }
    handleRepPregnant() {
        if (this.inputValues.RepGender === 'Female' && this.inputValues.isRepPregnant === 'Yes') {
            this.ifRepPregnantYes = true;
        } else {
            this.ifRepPregnantYes = false;
            this.inputValues.RepGestationOrLMP = null;
        }
    }

    handlePregnant() {
        if (this.inputValues.PatientGender === 'Female' && this.inputValues.isPatientPregnant === 'Yes') {
            this.ifPregnantYes = true;
        } else {
            this.ifPregnantYes = false;
            this.inputValues.GestationOrLMP = null;
        }
    }

    handlePatientReporter() {
        if (this.inputValues['isPatientReporter'] === 'Yes') {
            this.disableFields = true;
            this.syncWithReporter();
        } else {
            this.clearPatientInfo();
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$aeRecordTypeId', fieldApiName: HCPTypeField })
    hcpTypeInfo({ data, error }) {
        if (data) {
            let typeList = ['Physician', 'Nurse Practitioner', 'Physician Assistant', 'Nurse',
                'Pharmacist', 'Medical Assistant', 'Other']; //fetch it from Type of HCP from AE_Portal Metadata
            this.hcpTypeOptions = data.values.filter(opt => typeList.includes(opt.value));
        } else if (error) {
            console.log('Error HCPType-> ' + JSON.stringify(error));
        }
    }
    handlePrevNext(event) {
        let choice = event.target.name;       
        let isValid = this.validateAllFields();
            if (choice === 'Next' || choice === 'Skip') {
                if (isValid) {
                    this.StageDetails(choice);
                } else if(!isValid) {
                    this.showNotification('warning', 'Invalid values must be corrected!');
                }
                else {
                    this.showNotification('error', 'Please fill all required fields.');
                }
            } else {
                this.StageDetails(choice);
            }  
    }

    showNotification(type, message) {
        this.template.querySelector('c-custom-toast').showToast(type, message);
    }

    StageDetails(choice) {
        const stage3DetailsEvent = new CustomEvent("stagedetails", {
            detail: {
                'stageInputs': {
                    'stage3': this.inputValues
                },
                'action': choice,
            }
        });
        this.dispatchEvent(stage3DetailsEvent);       
    }

    isValid() {
        let isInputsCorrect = [...this.template.querySelectorAll('lightning-input,lightning-combobox,lightning-textarea,input')].reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);

        return isInputsCorrect;
    }

    openAccordion() {
        const accordionSection = this.template.querySelector('lightning-accordion-section');
        if (accordionSection) {
            console.log('open');
            accordionSection.open();
        }
    }

}