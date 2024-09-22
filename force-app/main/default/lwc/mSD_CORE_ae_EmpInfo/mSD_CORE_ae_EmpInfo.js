import getRecordTypeId from '@salesforce/apex/MSD_CORE_ae_CaseController.getRecordTypeId';
import getEmployeeDetails from '@salesforce/apex/MSD_CORE_ae_PortalStageHandler.getEmployeeDetails';
import Addressline2 from '@salesforce/label/c.MSD_CORE_ae_Address_Line2';
import Addressline1 from '@salesforce/label/c.MSD_CORE_ae_Address_Line_1';
import ALLFILES from '@salesforce/label/c.MSD_CORE_ae_All_Files';
import city from '@salesforce/label/c.MSD_CORE_ae_City';
import Country from '@salesforce/label/c.MSD_CORE_ae_Country';
import DELETE from '@salesforce/label/c.MSD_CORE_ae_Delete';
import DOWNLOAD from '@salesforce/label/c.MSD_CORE_ae_Download';
import EMAIL from '@salesforce/label/c.MSD_CORE_ae_Email_Address';
import EMPLOYEEID from '@salesforce/label/c.MSD_CORE_ae_Employee_ID';
import FILENAME from '@salesforce/label/c.MSD_CORE_ae_File_Name';
import FILESIZE from '@salesforce/label/c.MSD_CORE_ae_File_Size';
import FILESUPLOAD from '@salesforce/label/c.MSD_CORE_ae_Files_Uploaded';
import FIRSTNAME from '@salesforce/label/c.MSD_CORE_ae_First_Name';
import LASTNAME from '@salesforce/label/c.MSD_CORE_ae_Last_Name';
import MAXFILES from '@salesforce/label/c.MSD_CORE_ae_Max_File';
import MERCKFIELDBASES from '@salesforce/label/c.MSD_CORE_ae_Merck_Fields_Bases_Employee';
import MULTIPLEPATIENTS from '@salesforce/label/c.MSD_CORE_ae_Multiple_Patients_Involved';
import NAMEOFAGENT from '@salesforce/label/c.MSD_CORE_ae_Name_Of_Agent';
import NEXTBUTTON from '@salesforce/label/c.MSD_CORE_ae_Next_Button';
import PSPCOMPANY from '@salesforce/label/c.MSD_CORE_ae_PSP_Company';
import PSPCOMPANYOTHER from '@salesforce/label/c.MSD_CORE_ae_PSP_Company_Other';
import PSPNUMBER from '@salesforce/label/c.MSD_CORE_ae_PSP_Number';
import PSPNUMBEROTHER from '@salesforce/label/c.MSD_CORE_ae_PSP_Number_Other';
import PSPPROGRAMNAME from '@salesforce/label/c.MSD_CORE_ae_PSP_Program_Name';
import PSPPROGRAMNAMEOTHER from '@salesforce/label/c.MSD_CORE_ae_PSP_Program_Name_Other';
import PATIENTID from '@salesforce/label/c.MSD_CORE_ae_Patient_ID';
import PHONE from '@salesforce/label/c.MSD_CORE_ae_Phone';
import PracticeorFacilityName from '@salesforce/label/c.MSD_CORE_ae_Practice_or_Facility_Name';
import PREVIOUSBUTTON from '@salesforce/label/c.MSD_CORE_ae_Previous_Button';
import SKIPTOREVIEW from '@salesforce/label/c.MSD_CORE_ae_Skip_to_Review';
import State from '@salesforce/label/c.MSD_CORE_ae_State';
import TYPEHEALTHCARE from '@salesforce/label/c.MSD_CORE_ae_Type_of_HealthCare_Provider';
import UPLOADDOCUMENTS from '@salesforce/label/c.MSD_CORE_ae_Upload_Documents';
import VALIDATEBUTTON from '@salesforce/label/c.MSD_CORE_ae_Validate';
import zipcode from '@salesforce/label/c.MSD_CORE_ae_Zip_Code';
import RADIOGROUP_NO from '@salesforce/label/c.MSD_CORE_ae_radio_NO';
import RADIOGROUP_YES from '@salesforce/label/c.MSD_CORE_ae_radio_Yes';
import PSPCompany from "@salesforce/schema/Case.MSD_CORE_PSP_Company__c";
import PSPNumber from "@salesforce/schema/Case.MSD_CORE_PSP_Number__c";
import PSPProgramName from "@salesforce/schema/Case.MSD_CORE_PSP_Program_Name__c";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { LightningElement, api, track, wire } from 'lwc';


export default class MSD_CORE_ae_EmpInfo extends LightningElement {

    label = {
        RADIOGROUP_NO,
        RADIOGROUP_YES,
        NEXTBUTTON,
        PREVIOUSBUTTON,
        VALIDATEBUTTON,
        MULTIPLEPATIENTS,
        FILESUPLOAD,
        FILENAME,
        FILESIZE,
        DOWNLOAD,
        DELETE,
        MAXFILES,
        ALLFILES,
        SKIPTOREVIEW,
        EMPLOYEEID,
        FIRSTNAME,
        LASTNAME,
        PHONE,
        EMAIL,
        PSPPROGRAMNAME,
        PSPCOMPANY,
        PSPPROGRAMNAMEOTHER,
        PSPCOMPANYOTHER,
        PSPNUMBER,
        PSPNUMBEROTHER,
        PATIENTID,
        NAMEOFAGENT,
        Addressline1,
        Addressline2,
        city,
        zipcode,
        State,
        Country,
        PracticeorFacilityName,
        TYPEHEALTHCARE,
        UPLOADDOCUMENTS,
        MERCKFIELDBASES
    }
    @track stateOptions = [];
    @track hcpTypeOptions = [];
    @track searchResults = [];
    searchTerm = '';
    CredOptions = [];
    @api stageId;
    @api editedSection;
    @api stageName;
    @api caseDetails;
    @api portalSetting;
    recordTypeId;
    @track inputValues = {NempCountry: 'US'};
    @track isProgramOtherFieldDisabled = false;
    @track isCompanyOtherFieldDisabled = false;
    @track isNumberOtherFieldDisabled = false;
    notificationMessage = '';
    previousWinId = '';
    previousLastName = '';
    @track isValidationSuccessful = false;
    @track showFileUpload = false;
    uploadedFileNames = '';
    @track prepopulatedFiles = [];
    @track uploadedFileData = [];
    uploadedFilesList = [];
    @track pspProgramOptions =[];
    @track pspCompanyOptions;
    @track pspNumberOption;
    @track pspProgram;
    @track pspCompanyData;
    @track pspNumberData;
    @track selectedValue;
    // @track isOtherSelected = false;
    // @track pspProgramOptions = [];


    dependentDisabled = true;
    hasValidated = false;
    validateCount = 0;
    get isMerckEmployee() {
        let userChoice = this.caseDetails.stage1['userChoice'];
        return userChoice === 'Merck Employee';
    }
    get isPSP() {
        let userChoice = this.caseDetails.stage1['userChoice'];
        return userChoice === 'PSP Representative';
    }   
    get showSkipButton() {
        return this.editedSection === this.stageId;
    }
    get FieldBased(){
        return this.inputValues['FieldBased']=='yes';
    }
    get NonFieldBased(){
        return this.inputValues['FieldBased']=='no';
    } 
    get dependentDisabled(){
        return this.FieldBased === 'no' ? false:true;
    }
    get CountryOptions(){
        const options = this.processOptions(this.portalSetting.Country__c, ';');
        return options.sort((a, b) => {
            if (a.label === 'United States') return -1;
            if (b.label === 'United States') return 1; 
            return a.label.localeCompare(b.label);   
        });
    }
    processOptions(rawOptions, delimiter) {
        return rawOptions ? rawOptions.split(delimiter).map(option => {
            const [label, value] = option.split(':');
            return { label: label?.trim(), value: value?.trim() || label?.trim() };
        }) : [];
    }



    get validateBtnDisable() {
        let lessCount = (this.validateCount) < this.portalSetting.Validate_Count__c;
        let showBtn = lessCount && (this.inputValues.WinId && this.inputValues.WinId.trim() !== '' && this.inputValues.LastName && this.inputValues.LastName.trim() !== '');
        return !showBtn;
    }

    @track uploadFileOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
    ];
    @track FieldBasedOptions = [
         { label: 'Yes', value: 'yes' },
        { label: 'No', value: 'no' },
    ]

    populateInputs() {
        console.log('Method Called now checking stage 2 population values', JSON.stringify(this.caseDetails));
        this.inputValues = Object.assign(this.inputValues, this.caseDetails.stage2);
        console.log('populateInputs', JSON.stringify(this.inputValues));
        if (this.inputValues.WinId && this.inputValues.LastName && this.FieldBased ) {
            this.hasValidated = false;

            if (this.inputValues['EmployeeId'] && this.inputValues['LastName'] && this.FieldBased )  {
                this.isValidationSuccessful = true;
            }
        }
        if (this.inputValues.uploadFile !== undefined) {
            this.showFileUpload = this.inputValues.uploadFile === 'Yes' ? true : false;
        }
        if (this.inputValues.uploadedFiles) {
            this.uploadedFileNames = this.inputValues.uploadedFiles.map(file => file.filename).join(', ');
        }
        if (this.isPSP) {
            if (this.inputValues['PSPProgramName']) {
                this.fetchDependentPicklist(this.inputValues['PSPProgramName']);
                this.updatePspOtherFields('PSPProgramName', this.inputValues['PSPProgramName']);
            }
            if (this.inputValues['PSPNumber']) {
                this.updatePspOtherFields('PSPNumber', this.inputValues['PSPNumber']);
            }
            if (this.inputValues['PSPCompany']) {
                this.updatePspOtherFields('PSPCompany', this.inputValues['PSPCompany']);
            }
        } else {
            this.handleValidate();
        }
        if (this.inputValues.uploadedFiles) {
            this.uploadedFiles = this.inputValues.uploadedFiles;
            this.uploadedFilesList = [...this.inputValues.uploadedFiles];
        }
        // this.isFemale = this.inputValues.isFemale || false;
        // this.ifPregnantYes = this.inputValues.ifPregnantYes || false;
    }
    connectedCallback() {

        if (!this.recordTypeId) {
            this.fetchRecordTypeId();
        }
        if (this.isPSP) {
            this.inputValues.PrePopulate = true;
        }
        if(this.isMerckEmployee){
            this.inputValues.PrePopulate = true;
            this.populateInputs();
        }
        // console.log('Options retrieved are', JSON.stringify(this.portalSetting));
    }

    fetchRecordTypeId() {
        getRecordTypeId({ devName: 'Adverse_Event_MVN', sObjectType: 'Case' })
            .then(result => {
                this.recordTypeId = result;
                this.inputValues['Adverse_Event_MVN'] = result;
            })
            .catch(error => {
                console.error('Error fetching Case recordType: ', JSON.stringify(error));
            });
    }


    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PSPProgramName })
    programInfo({ data, error }) {
        if (data) {
            this.pspProgramOptions = this.sortPicklistOptions([...data.values]);
            console.log('pspProgramOptions------>'+JSON.stringify(this.pspProgramOptions));
            if (this.caseDetails.stage2.PrePopulate && this.pspNumberData && this.pspCompanyData && this.pspNumberData) {
                this.populateInputs();
            }
        } else if (error) {
            console.log('Error --->' + JSON.stringify(error));
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PSPNumber })
    pspNumberInfo({ data, error }) {
        if (data) {
            this.pspNumberData = data;
            if (this.caseDetails.stage2.PrePopulate && this.pspNumberData && this.pspCompanyData && this.pspNumberData) {
                this.populateInputs();
            }
        } else if (error) {
            console.log('Error --->' + JSON.stringify(error));
        }
    }


    handleFile(event) {
        var fieldValue = event.target.value;
        if (fieldValue === 'Yes') {
            this.showFileUpload = true;
        } else {
            this.showFileUpload = false;
            this.uploadedFileNames = '';
            this.uploadedFilesList = [];
            this.inputValues.uploadedFiles = [];
        }
    }
    handleInput(event) {
        const fieldName = event.target.name;
        let fieldValue = event.target.value;
        if (event.target.type === 'checkbox') {
            fieldValue = event.target.checked;
        } else if (event.target.type === 'radio') {
            fieldValue = event.target.value;
        }
        if (fieldName === 'FieldBased') {
            if (fieldValue === 'yes') {
                this.clearNonFieldBasedInputs();
            } else if (fieldValue === 'no') {
                this.clearFieldBasedInputs();
            }
        }

        if(fieldName ===''){
            this.clearValidationMessages();
        }
        
        this.inputValues[fieldName] = fieldValue;
        this.inputValues.isHCPType = this.isHCPType;
        this.inputValues.isHBPType = this.isHBPType;
        switch (fieldName) {
            case 'WinId':
            case 'LastName':
                this.hasValidated = false;
                this.isValidationSuccessful = false;
                this.inputValues['EmployeeId'] = '';
                this.inputValues['FirstName'] = '';
                this.inputValues['Phone'] = '';
                this.inputValues['Email'] = '';
                this.inputValues['MaskedFirstName'] = '';
                this.inputValues['MaskedPhone'] = '';
                this.inputValues['MaskedEmail'] = '';
                if (fieldName === 'WinId' && this.previousWinId !== fieldValue) {
                    this.previousWinId = fieldValue;
                }
                break;
            case 'PSPProgramName':
                this.inputValues.PSPCompany = '';
                this.inputValues.PSPNumber = '';
                this.inputValues.PSPCompanyOther = null;
                this.inputValues.PSPNumberOther = null;
                this.inputValues.PSPProgramNameOther = null;
                this.isNumberOtherFieldDisabled = false;
                this.isCompanyOtherFieldDisabled = false;
                this.isProgramOtherFieldDisabled = false;
                break;
            case 'uploadFile':
                this.handleFile(event);
                break;
            default:
                if (this.isPSP) {
                    this.updatePspOtherFields(fieldName, fieldValue);
                }
                break;
        }
    }
    clearFieldBasedInputs() {
        // Clear Field-Based Employee inputs
        this.inputValues['WinId'] = '';
        this.inputValues['LastName'] = '';
        this.inputValues['FirstName'] = '';
        this.inputValues['Phone'] = '';
        this.inputValues['Email'] = '';
        this.inputValues['MaskedFirstName'] = '';
        this.inputValues['MaskedPhone'] = '';
        this.inputValues['MaskedEmail'] = '';
    }
    
    clearNonFieldBasedInputs() {
        this.inputValues['NEmployeeId'] = '';
        this.inputValues['NFirstName'] = '';
        this.inputValues['NName'] = '';
        this.inputValues['NempPhone'] = '';
        this.inputValues['NempEmail'] = '';
    }

    onBlur(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        
        const validationRules = {
            'NempPhone': {
                isValid: fieldValue === '' || /^[\d+-]{0,30}$/.test(fieldValue),
                errorMessage: "Invalid Phone Number"
            },
            'NempEmail': {
                isValid: fieldValue === '' || /\S+@\S+\.\S+/.test(fieldValue),
                errorMessage: "Invalid Email Address"
            }
        };
    
        const { isValid, errorMessage } = validationRules[fieldName];
    
        if (!isValid) {
            event.target.setCustomValidity(errorMessage);
            this.inputValues[fieldName] = ''; 
        } else {
            event.target.setCustomValidity('');
            if(fieldName === 'NempEmail') {
                event.target.setCustomValidity('');
            }
            this.inputValues[fieldName] = fieldValue;
            
        }
    
        event.target.reportValidity();
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


    updatePspOtherFields(fieldName, fieldValue) {
        console.log('fieldValue---->'+fieldValue);
        if (fieldValue === 'Other') {
            console.log('fieldValue1---->'+fieldValue);
            switch (fieldName) {
                case 'PSPProgramName':
                    this.isProgramOtherFieldDisabled = true;
                    console.log('isProgramOtherFieldDisabled----->'+fieldValue);
                    break;
                case 'PSPCompany':
                    this.isCompanyOtherFieldDisabled = true;
                    console.log('isCompanyOtherFieldDisabled----->'+fieldValue);
                    break;
                case 'PSPNumber':
                    this.isNumberOtherFieldDisabled = true;
                    console.log('isNumberOtherFieldDisabled----->'+fieldValue);
                    break;
                default: break;
            }
        } else {
            switch (fieldName) {
                case 'PSPProgramName':
                    this.isProgramOtherFieldDisabled = false;
                    this.inputValues['PSPProgramNameOther'] = null;
                    break;
                case 'PSPCompany':
                    this.isCompanyOtherFieldDisabled = false;
                    this.inputValues['PSPCompanyOther'] = null;
                    break;
                case 'PSPNumber':
                    this.isNumberOtherFieldDisabled = false;
                    this.inputValues['PSPNumberOther'] = null;
                    break;
                default: break;
            }
        }
    }
    handleFocus() {
        this.searchResults = [];
    }

   

    normalizeString(str) {
        return str.replace(/[^0-9a-zA-Z]/g, '').toLowerCase();
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





    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PSPCompany })
    pspCompanyInfo({ data, error }) {
        if (data) {
            this.pspCompanyData = data;
            if (this.caseDetails.stage2.PrePopulate && this.pspNumberData && this.pspCompanyData && this.pspNumberData) {
                this.populateInputs();
            }
        } else if (error) {
            console.log('Error --->' + JSON.stringify(error));
        }
    }

    handleProgramChange(event) {
        let programSelected = event.target.value;
        console.log('other1===>'+programSelected);
        this.fetchDependentPicklist(programSelected);
        console.log('other===>'+programSelected);
        if (programSelected === 'Other') {
            this.isProgramOtherFieldDisabled = true;
        }
        this.handleInput(event);
    }
    fetchDependentPicklist(programSelected) {
        let key = this.pspCompanyData.controllerValues[programSelected];
        let key2 = this.pspNumberData.controllerValues[programSelected];
        let filteredCompanyOptions = this.pspCompanyData.values.filter(opt => opt.validFor.includes(key));
        let filteredNumberOptions = this.pspNumberData.values.filter(opt => opt.validFor.includes(key2));
        this.pspCompanyOptions = this.sortPicklistOptions(filteredCompanyOptions);
        this.pspNumberOption = this.sortPicklistOptions(filteredNumberOptions);
        if (this.pspCompanyOptions != undefined && this.pspNumberOption != undefined) {
            this.dependentDisabled = false;
         }
         //else {
        //     this.dependentDisabled = true; // Disable dependent fields if options are not available
        // }
    }
    sortPicklistOptions(options) {
        return options.sort((a, b) => {
            if (a.label === 'Other') return b.label === 'Not Applicable' ? -1 : 1;
            if (b.label === 'Other') return a.label === 'Not Applicable' ? 1 : -1;
            if (a.label === 'Not Applicable') return 1;
            if (b.label === 'Not Applicable') return -1;
            return a.label.localeCompare(b.label);
        });
    }

    handleKeydown(event) {
        if (this.inputValues.WinId && this.inputValues.WinId.trim() !== '' && this.inputValues['LastName'] && this.inputValues['LastName'].trim() !== '' && event.keyCode === 13) {
            this.validateCounter();
        }
    }

    validateCounter() {
        if (this.NonFieldBased) {
            return;
        }
        if (this.validateCount < this.portalSetting.Validate_Count__c) {
            this.validateCount++;
            this.handleValidate();
        } else {
            let empMsg = 'You\'ve Exceeded 10 Attempts to Validate.';
            this.showValidationMsg(empMsg, '');
        }
    }

    showValidationMsg(empMsg, LastMsg) {
        const employeeIdInput = this.template.querySelector('.employee-id-input');
        const lastNameInput = this.template.querySelector('.last-name-input');
        if (employeeIdInput) {
            employeeIdInput.setCustomValidity(empMsg);
            employeeIdInput.reportValidity();
        } else {
            console.warn('Employee ID input not found.');
        }
    
        if (lastNameInput) {
            lastNameInput.setCustomValidity(LastMsg);
            lastNameInput.reportValidity();
        } else {
            console.warn('Last Name input not found.');
        }
    }

    handleValidate() {
        const employeeIdInput = this.template.querySelector('.employee-id-input');
        const lastNameInput = this.template.querySelector('.last-name-input');
        if (!this.inputValues['WinId'] || this.inputValues['WinId'].trim() === '' || !this.inputValues['LastName'] || this.inputValues['LastName'].trim() === '') {
            this.inputValues.PrePopulate = false;
            return;
        }
        if (this.NonFieldBased) {
            this.hasValidated = true;
        }
        
        // if (!this.inputValues['WinId'] || this.inputValues['WinId'].trim() === '') {
        //     this.inputValues.PrePopulate = false;
        //     return;
        // }
        this.hasValidated = true;
        let winId = 'WIN-' + this.inputValues['WinId'];
        let lastName = this.inputValues['LastName'];
        getEmployeeDetails({ winId: winId, lastName: lastName })
            .then(result => {
                console.log('Account Results result----->'+JSON.stringify(result));
                if (result[0] !== undefined) {
                    this.inputValues['EmployeeId'] = result[0].Id;
                    this.inputValues['FirstName'] = result[0].FirstName;
                    this.inputValues['Phone'] = result[0].Phone;
                    this.inputValues['Email'] = result[0].Email;
                    this.inputValues['MaskedFirstName'] = result[0].MaskedFirstName;
                    this.inputValues['MaskedAddressLine1'] = result[0].MaskedAddressLine1;
                    this.inputValues['MaskedAddressLine2'] = result[0].MaskedAddressLine2;

                    this.inputValues['MaskedPhone'] = result[0].MaskedPhone;
                    this.inputValues['MaskedEmail'] = result[0].MaskedEmail;
                    this.inputValues['Type'] = result[0].Class_of_Trade_MRK__c;
                    this.inputValues['Address1'] = result[0].MSD_CORE_Primary_Address_Line_1__c;
                    this.inputValues['Address2'] = result[0].MSD_CORE_Primary_Address_Line_2__c;
                    this.inputValues['City'] = result[0].MSD_CORE_Primary_City__c;
                    this.inputValues['State'] = result[0].MSD_CORE_Primary_State__c;
                    this.inputValues['Country'] = result[0].PersonMailingCountryCode;
                    this.inputValues['Zip'] = result[0].MSD_CORE_Primary_Zip__c;
                    this.isValidationSuccessful = true;
                    this.inputValues.PrePopulate = true;
                    this.showValidationMsg('', '');
                } else {
                    this.inputValues.PrePopulate = false;
                    let empMsg = 'Invalid Employee ID, Last Name, or you may not currently be aligned to the U.S. or a U.S. Territory';
                    this.showValidationMsg(empMsg, '');
                }
            }).catch(error => {
                console.error(error);
                this.isValidationSuccessful = false;
                let empMsg = 'Error during validation';
                this.showValidationMsg(empMsg, '');
            });
    }   

    // handlePrevNext(event) {
    //     let choice = event.target.name;
    //     let isValid = this.validateRequiredFields();
    //     if ((choice === 'Next' || choice === 'Skip') && this.inputValues.uploadFile === 'Yes' && this.uploadedFilesList.length === 0) {
    //         this.showNotification('warning', 'Please attach a file to upload.');
    //         return;
    //     }
    //     if (choice === 'Next' || choice === 'Skip') {
    //         if (this.isMerckEmployee) {
    //             if (!this.inputValues.WinId || !this.inputValues.LastName) {
    //                 this.showNotification('warning', 'Please enter the Employee ID & Last Name.');
    //                 return;
    //             }

    //             if (!this.isValidationSuccessful) {
    //                 this.showNotification('Error', 'Employee Details are required!');
    //                 return;
    //             }
    //         }
    //         if (isValid) {
    //             this.StageDetails(choice);
    //         } else {
    //             this.showNotification('error', 'All required fields must be filled!');
    //         }
    //     } else {
    //         this.StageDetails(choice);
    //     }
    // }
    handlePrevNext(event) {
        let choice = event.target.name;
        
        // Universal file upload validation for 'Next' or 'Skip' choices
        if ((choice === 'Next' || choice === 'Skip') && this.inputValues.uploadFile === 'Yes' && this.uploadedFilesList.length === 0) {
            this.showNotification('warning', 'Please attach a file to upload.');
            return; // Exit the function early if validation fails
        }
    
        let isValid = this.validateRequiredFields();
        
        // Continue with the rest of your logic after the universal check
        if (this.NonFieldBased && isValid) {
            this.StageDetails(choice);
        } else {
            if (choice === 'Next' || choice === 'Skip') {
                if (this.isMerckEmployee && !this.NonFieldBased) {
                    if (!this.inputValues.WinId || !this.inputValues.LastName) {
                        this.showNotification('warning', 'Please enter the Employee ID & Last Name.');
                        return;
                    }
    
                    if (!this.isValidationSuccessful) {
                        this.showNotification('Error', 'Employee Details are required!');
                        return;
                    }
                }
                if (isValid) {
                    this.StageDetails(choice);
                } else {
                    this.showNotification('error', 'All required fields must be filled!');
                }
            } else {
                this.StageDetails(choice);
            }
        }
    }
        

    StageDetails(choice) {
        const stage2DetailsEvent = new CustomEvent("stagedetails", {
            detail: {
                'stageInputs': {
                    'stage2': this.inputValues,
                    'recordTypeId': this.recordTypeId
                },
                'action': choice,
            }
        });

        this.dispatchEvent(stage2DetailsEvent);
        
    }

    validateRequiredFields() {
        const allRequiredFields = [...this.template.querySelectorAll('.requiredField')];
        let isValid = allRequiredFields.every(field => {
            return field.reportValidity();
        });
        return isValid;
    }

    showNotification(type, message) {
        this.template.querySelector('c-custom-toast').showToast(type, message);
    }

    get acceptedFormats() {
        let formats = this.portalSetting.File_Format__c.split(',');
        formats = formats.map(format => format.trim().replace(/'/g, ""));
        return formats;
    }
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length + this.uploadedFilesList.length > 1) {
            this.showNotification('error', 'You can only upload 1 file.');
            return;
        }

        let fileNames = '';
        const fileReadPromises = [];
        const sizeLimit = 20 * 1024 * 1024;
        const acceptedFormats = this.acceptedFormats;

        for (let i = 0; i < uploadedFiles.length; i++) {
            const file = uploadedFiles[i];
            const fileExtension = `.${file.name.split('.').pop()}`;


            if (!acceptedFormats.includes(fileExtension)) {
                this.showNotification('error', `File ${file.name} is not an allowed format.`);
                return;
            }
            if (file.size > sizeLimit) {
                this.showNotification('error', `File ${file.name} exceeds 21 MB size limit.`);
                return;
            }

            fileNames += file.name + ', ';
            const promise = new Promise((resolve, reject) => {
                let reader = new FileReader();
                reader.onload = () => {
                    const base64 = reader.result.split(',')[1];
                    const uniqueId = new Date().getTime() + '_' + i;
                    resolve({
                        id: uniqueId,
                        base64: base64,
                        filename: file.name,
                        size: (file.size / (1024 * 1024)).toFixed(2)
                    });
                };
                reader.onerror = (error) => {
                    this.showNotification('error', `Error reading ${file.name}.`);
                    reject(error);
                };
                reader.readAsDataURL(file);
            });
            fileReadPromises.push(promise);
        }

        Promise.all(fileReadPromises).then((filesData) => {
            this.uploadedFilesList = [...this.uploadedFilesList, ...filesData];
            this.inputValues.uploadedFiles = this.uploadedFilesList;
        }).catch(error => {
            console.error('Error processing files', error);
        });

        fileNames = fileNames.slice(0, -2);
        this.uploadedFileNames = fileNames;
        this.showNotification('success', `${fileNames} uploaded successfully`);
    }

    handleFileDeletion(event) {
        const fileId = event.currentTarget.dataset.fileId;
        this.uploadedFilesList = this.uploadedFilesList.filter(file => file.id !== fileId);
        this.uploadedFileNames = this.uploadedFilesList.map(file => file.filename).join(', ');
        this.inputValues.uploadedFiles = this.uploadedFilesList;
        if (this.uploadedFilesList.length === 0) {
            this.uploadedFileNames = '';
        }
    }

    handleFilePreview(event) {
        const fileId = event.currentTarget.dataset.id;
        const file = this.uploadedFilesList.find(f => f.id === fileId);

        if (file && file.base64) {
            this.base64ToBlob(file.base64, file.filename);
        }
    }

    base64ToBlob(base64, filename) {
        const binaryString = window.atob(base64);
        const binaryLen = binaryString.length;
        const binaryData = new Uint8Array(binaryLen);

        for (let i = 0; i < binaryLen; i++) {
            binaryData[i] = binaryString.charCodeAt(i);
        }
        let contentType = 'application/octet-stream';
        const extension = filename.split('.').pop().toLowerCase();

        switch (extension) {
            case 'pdf':
                contentType = 'application/pdf';
                break;
            case 'ppt':
            case 'pptx':
                contentType = 'application/vnd.ms-powerpoint';
                break;
            case 'docx':
                contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
                break;
            case 'xlsx':
                contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
                break;
            case 'csv':
                contentType = 'text/csv';
                break;
            default:
                console.log('Extension different than configured - No preview');
                return;
        }

        const blob = new Blob([binaryData], { type: contentType });
        const blobURL = URL.createObjectURL(blob);
        window.open(blobURL, '_blank');
    }
    handleFileDownload(event) {
        const fileId = event.currentTarget.dataset.id;
        const file = this.uploadedFilesList.find(f => f.id === fileId);

        if (file && file.base64) {
            this.base64ToDownloadLink(file.base64, file.filename);
        }
    }
    base64ToDownloadLink(base64, filename) {
        const binaryString = window.atob(base64);
        const binaryLen = binaryString.length;
        const binaryData = new Uint8Array(binaryLen);

        for (let i = 0; i < binaryLen; i++) {
            binaryData[i] = binaryString.charCodeAt(i);
        }

        const blob = new Blob([binaryData], { type: 'application/octet-stream' });
        const blobURL = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.style.display = 'none';
        a.href = blobURL;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
    }




    // handleFieldEmployeeChange(event) {
    //     this.selectedValue = event.detail.value;
    //     console.log('this.selectedValue----->'+this.selectedValue);
    //     this.showValidationFields = this.selectedValue === 'yes';
    //     this.showReportingPage = this.selectedValue === 'no';
    // }

    

}