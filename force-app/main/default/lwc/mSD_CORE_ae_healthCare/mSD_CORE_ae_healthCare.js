import getRecordTypeId from '@salesforce/apex/MSD_CORE_ae_CaseController.getRecordTypeId';
import getPicklist from '@salesforce/apex/MSD_CORE_ae_PortalStageHandler.getPicklist';
import Addressline2 from '@salesforce/label/c.MSD_CORE_ae_Address_Line2';
import Addressline1 from '@salesforce/label/c.MSD_CORE_ae_Address_Line_1';
import ALLFILES from '@salesforce/label/c.MSD_CORE_ae_All_Files';
import city from '@salesforce/label/c.MSD_CORE_ae_City';
import Country from '@salesforce/label/c.MSD_CORE_ae_Country';
import DELETE from '@salesforce/label/c.MSD_CORE_ae_Delete';
import DOWNLOAD from '@salesforce/label/c.MSD_CORE_ae_Download';
import EMAIL from '@salesforce/label/c.MSD_CORE_ae_Email_Address';
import FILENAME from '@salesforce/label/c.MSD_CORE_ae_File_Name';
import FILESIZE from '@salesforce/label/c.MSD_CORE_ae_File_Size';
import FILESUPLOAD from '@salesforce/label/c.MSD_CORE_ae_Files_Uploaded';
import FIRSTNAME from '@salesforce/label/c.MSD_CORE_ae_First_Name';
import LASTNAME from '@salesforce/label/c.MSD_CORE_ae_Last_Name';
import MAXFILES from '@salesforce/label/c.MSD_CORE_ae_Max_File';
import NEXTBUTTON from '@salesforce/label/c.MSD_CORE_ae_Next_Button';
import PHONE from '@salesforce/label/c.MSD_CORE_ae_Phone';
import PracticeorFacilityName from '@salesforce/label/c.MSD_CORE_ae_Practice_or_Facility_Name';
import PREVIOUSBUTTON from '@salesforce/label/c.MSD_CORE_ae_Previous_Button';
import SKIPTOREVIEW from '@salesforce/label/c.MSD_CORE_ae_Skip_to_Review';
import State from '@salesforce/label/c.MSD_CORE_ae_State';
import TYPEOFHEALTHCATEPROFESSIONAL from '@salesforce/label/c.MSD_CORE_ae_Type_Of_Healthcare_Professional';
import TYPEHEALTHCARE from '@salesforce/label/c.MSD_CORE_ae_Type_of_HealthCare_Provider';
import UPLOADDOCUMENTS from '@salesforce/label/c.MSD_CORE_ae_Upload_Documents';
import zipcode from '@salesforce/label/c.MSD_CORE_ae_Zip_Code';
import RADIOGROUP_NO from '@salesforce/label/c.MSD_CORE_ae_radio_NO';
import RADIOGROUP_YES from '@salesforce/label/c.MSD_CORE_ae_radio_Yes';
import HCPTypeField from "@salesforce/schema/MSD_CORE_AE_Contact__c.MSD_CORE_Type__c";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { LightningElement, api, track, wire } from 'lwc';
export default class MSD_CORE_ae_healthCare extends LightningElement {
    label = {
        RADIOGROUP_NO,
        RADIOGROUP_YES,
        NEXTBUTTON,
        PREVIOUSBUTTON,
        FILESUPLOAD,
        FILENAME,
        FILESIZE,
        DOWNLOAD,
        DELETE,
        MAXFILES,
        ALLFILES,
        SKIPTOREVIEW,
        FIRSTNAME,
        LASTNAME,
        PHONE,
        EMAIL,
        Addressline1,
        Addressline2,
        city,
        zipcode,
        State,
        Country,
        PracticeorFacilityName,
        TYPEHEALTHCARE,
        TYPEOFHEALTHCATEPROFESSIONAL,
        UPLOADDOCUMENTS
    }
    @track stateOptions = [];
    @track hcpTypeOptions = [];
    searchTerm = '';
    @track credentialsSearchTerm = '';
    @track stateSearchTerm = '';
    CredOptions = [];
    @api stageId;
    @api editedSection;
    @api stageName;
    @api caseDetails;
    @api portalSetting;
    @track showFileUpload = false;
    uploadedFileNames = '';
    @track prepopulatedFiles = [];
    @track uploadedFileData = [];
    uploadedFilesList = [];
    recordTypeId;
    aeRecordTypeId;
    @track inputValues = {hcpCountry: 'US'};
    @track selectedValues = {
        state: '',
        credentials: ''
    };
    
    @track filteredResults = {
        credentials: [],
        state: []
    };
    get isHCP() {
        let userChoice = this.caseDetails.stage1['userChoice'];
        return userChoice === 'Healthcare Professional';
    }
    get isLicensedHCP() {
        return (this.inputValues.licensedHCP === 'Licensed Healthcare Professional');
    }
    get isLicensedHBP() {
        return (this.inputValues.licensedHCP === 'Healthcare Office Worker or Facility Personnel');
    }
    get hasCredentialsSearchResults() {
        return this.credentialsSearchTerm.length > 0 && this.filteredResults.credentials.length > 0;
    }
    get hasStateSearchResults() {
        return this.stateSearchTerm.length > 0 && this.filteredResults.state.length > 0;
    }     
    get showSkipButton() {
        return this.editedSection === this.stageId;
    }
    get CountryOptions(){
        const options = this.processOptions(this.portalSetting.Country__c, ';');
        return options.sort((a, b) => {
            if (a.label === 'United States') return -1;
            if (b.label === 'United States') return 1; 
            return a.label.localeCompare(b.label);   
        });
    }
    get HCPOptions() {
        return this.processOptions(this.portalSetting.Licensed_HCP__c, ';');
    }
    get uploadFileOptions() {
        return this.processOptions(this.portalSetting.Upload_File__c, ';');
    }
    get hbpTypeOptions() {
        return this.processOptions(this.portalSetting.HBP_Type__c, ';');
    }
    processOptions(rawOptions, delimiter) {
        return rawOptions ? rawOptions.split(delimiter).map(option => {
            const [label, value] = option.split(':');
            return { label: label?.trim(), value: value?.trim() || label?.trim() };
        }) : [];
    }
    configurePicklist() {
        getPicklist({ objectApiName: 'MSD_CORE_AE_Contact__c', fieldApiName: 'MSD_CORE_Credentials__c' })
            .then(result => {
                this.CredOptions = result.map(entry => ({ label: entry.label, value: entry.value }));
                this.filteredResults.credentials = [...this.CredOptions];
               
            })
            .catch(error => {
                console.error('Error retrieving Gender picklist values', error);
            });    
    

    
        getPicklist({ objectApiName: 'MSD_CORE_AE_Contact__c', fieldApiName: 'MSD_CORE_State_Province__c' })
            .then(result => {
                this.stateOptions = result.map(entry => ({ label: entry.label, value: entry.value }));
                this.filteredResults.state = [...this.stateOptions];
            })
            .catch(error => {
                console.error('Error retrieving Gender picklist values', error);
            });   
    }
    populateInputs() {
        console.log('Method Called now checking stage 2 population values', JSON.stringify(this.caseDetails));
        this.inputValues = Object.assign(this.inputValues, this.caseDetails.stage2);
        console.log('populateInputs', JSON.stringify(this.inputValues));
        if (this.inputValues.uploadFile !== undefined) {
            this.showFileUpload = this.inputValues.uploadFile === 'Yes' ? true : false;
        }
        if (this.inputValues.uploadedFiles) {
            this.uploadedFileNames = this.inputValues.uploadedFiles.map(file => file.filename).join(', ');
        }
        if (this.inputValues.uploadedFiles) {
            this.uploadedFiles = this.inputValues.uploadedFiles;
            this.uploadedFilesList = [...this.inputValues.uploadedFiles];
        }
        this.isHCPType = this.inputValues.licensedHCP === 'Licensed Healthcare Professional';
        this.isHBPType = this.inputValues.licensedHCP === 'Healthcare Office Worker or Facility Personnel';
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
    connectedCallback() {

        if (!this.recordTypeId) {
            this.fetchRecordTypeId();
        }
        this.populateInputs();
        this.clearValidationMessages();
        this.configurePicklist();
        this.fetchRecordType();
        this.HCPFromStage3();
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

    fetchRecordType() {
        getRecordTypeId({ devName: 'Adverse_Event_MVN', sObjectType: 'MSD_CORE_AE_Contact__c' })
            .then(result => {
                this.aeRecordTypeId = result;
            })
            .catch(error => {
                console.log('Error RecType-> ' + error);
            })
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
    HCPFromStage3() {
        console.log('Method Executing');
        // Check if stage 3 exists and the specific condition is met
        if (this.caseDetails.stage3 && this.caseDetails.stage3['PatientsHC'] === 'Yes' && this.isLicensedHCP) {
            // Mapping of stage 3 fields to stage 2 fields
            const hcpFieldMapping = {
                HCPFirstName: 'hcpFirstName',
                HCPLastName: 'hcpLastName',
                HCPPhone: 'hcpPhone',
                HCPEmail: 'hcpEmail',
                HCPAddress: 'hcpAddress',
                HCPType: 'HCPType',
                HCPAddressLine2: 'hcpAddressLine2',
                HCPCity: 'hcpCity',
                HCPZip: 'hcpZip',
                HCPState: 'hcpState',
                HCPCountry: 'hcpCountry',
                HCPFacilityName: 'hcpFacilityName',
                HCPCredential: 'hcpCredential'
            };
            
            // Iterate over the mapping object
            Object.keys(hcpFieldMapping).forEach(stage3Field => {
                const stage2Field = hcpFieldMapping[stage3Field];
                // Check if the corresponding stage 2 field is null or blank, and stage 3 field has a value
                if ((this.inputValues[stage2Field] === null || this.inputValues[stage2Field] === '') && this.caseDetails.stage3[stage3Field]) {
                    // Prepopulate only if the stage 2 field is null or blank
                    this.inputValues[stage2Field] = this.caseDetails.stage3[stage3Field];
                }
            });
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
        if (fieldName === 'hcpState' || fieldName === 'hcpCredential') {
            event.target.setCustomValidity('');
            event.target.reportValidity();
        }
        this.inputValues[fieldName] = fieldValue;
        this.inputValues.isHCPType = this.isHCPType;
        this.inputValues.isHBPType = this.isHBPType;
        switch (fieldName) {
            case 'uploadFile':
                this.handleFile(event);
                break;
            case 'hcpCredential':
                this.credentialsSearchTerm = fieldValue;
                this.filterOptions('credentials');
                break;
            case 'licensedHCP':
                this.clearValidationMessages();
                this.handleLicensedHCP();
                break;
            case 'hcpState':
                 this.stateSearchTerm = fieldValue;
                 this.filterOptions('state');
                break;

        }
    }
    handleLicensedHCP() {
        const hcpType = this.inputValues.licensedHCP;
        this.isHCPType = hcpType === 'Licensed Healthcare Professional';
        this.isHBPType = hcpType === 'Healthcare Office Worker or Facility Personnel';
        if (this.isHCPType) {
            this.resetFields(['hcpFirstName', 'hcpLastName', 'hcpPhone', 'hcpEmail', 'hcpAddress', 'hcpAddressLine2', 'hcpCity', 'hcpZip', 'hcpState','HCPType', 'hcpCredential', 'hcpFacilityName']);
            this.inputValues.hcpCountry = 'US';
        } else if (this.isHBPType) {
            this.resetFields(['hcpFirstName', 'hcpLastName', 'hcpPhone', 'hcpEmail', 'hcpAddress', 'hcpAddressLine2', 'hcpCity', 'hcpZip', 'hcpState','HBPType', 'hcpFacilityName']);
            this.inputValues.hcpCountry = 'US';
        }
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

    resetFields(fieldsToReset) {
        fieldsToReset.forEach(field => {
            this.inputValues[field] = '';
        });
    }
    handleFocus(event) {
        this.filteredResults = {
            credentials: [],
            state: []
        };
        const fieldName = event.target.name;
        if (fieldName === 'hcpCredential') {
            this.filteredResults.credentials = [];
        } else if (fieldName === 'hcpState') {
            this.filteredResults.state = [];
        }
    }
    
    filterOptions(field) {
        let searchTerm = field === 'state' ? this.stateSearchTerm : this.credentialsSearchTerm;
        let options = field === 'state' ? this.stateOptions : this.CredOptions;
    
        if (searchTerm) {
            const normalizedSearchTerm = this.normalizeString(searchTerm);
            this.filteredResults[field] = options.filter(option =>
                this.normalizeString(option.label).includes(normalizedSearchTerm)
            ).sort((a, b) => this.sortByRelevance(a.label, b.label, searchTerm));
        } else {
            this.filteredResults[field] = [];
        }
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
    handleSelectOption(event) {
        const field = event.currentTarget.dataset.field;
        const selectedValue = event.currentTarget.dataset.value;
        const selectedOption = this.filteredResults[field].find(option => option.value === selectedValue);
    
        if (selectedOption) {
            if (field === 'state') {
                this.inputValues.hcpState = selectedOption.label;
                this.selectedValues.state = selectedOption.label; 
            } else if (field === 'credentials') {
                this.inputValues.hcpCredential = selectedOption.label;
                this.selectedValues.credentials = selectedOption.label;
            }
            this.filteredResults[field] = [];
            if (field === 'state') {
                this.stateSearchTerm = '';
            } else {
                this.credentialsSearchTerm = '';
            }
        }
    }
    
    handleBlur(event) {
        const fieldName = event.target.name;
        let isValidOption = false;
        if (fieldName === 'hcpState' || fieldName === 'hcpCredential') {
            const searchField = fieldName === 'hcpState' ? 'state' : 'credentials';
            const inputValue = this.inputValues[fieldName];
            isValidOption = this.selectedValues[searchField] === inputValue; // Use selectedValues for validation
    
            if (!isValidOption) {
                event.target.setCustomValidity("Please select an option from the dropdown.");
                this.inputValues[fieldName] = '';
            } else {
                event.target.setCustomValidity('');
            }
            event.target.reportValidity();
        }
    }
    handlePrevNext(event) {
        let choice = event.target.name;

        if ((choice === 'Next' || choice === 'Skip') && this.inputValues.uploadFile === 'Yes' && this.uploadedFilesList.length === 0) {
            this.showNotification('warning', 'Please attach a file to upload.');
            return;
        }
       
        let isValid = this.validateRequiredFields() && this.validateAllFields();;
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
        const emailValid = this.inputValues.hcpEmailValid !== false;  
        return allAreValid && emailValid;
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
    onBlur(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        
        const validationRules = {
            'hcpPhone': {
            isValid: fieldValue === '' || /^[\d+-]{0,30}$/.test(fieldValue),
            errorMessage: "Invalid Phone Number"
            },
            'hcpEmail': {
            isValid: fieldValue === '' || /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/.test(fieldValue),
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
    handleKeydown(){

    }



}