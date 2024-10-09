import { LightningElement, track, api } from 'lwc';
import WarningMsg from '@salesforce/label/c.MSD_CORE_ae_warningmsg1';
import Phone from '@salesforce/label/c.MSD_CORE_ae_merckPhone';
import WarningMsg2 from '@salesforce/label/c.MSD_CORE_ae_warningmsg2';
import ALLFILES from '@salesforce/label/c.MSD_CORE_ci_All_Files';
import DELETE from '@salesforce/label/c.MSD_CORE_ae_Delete';
import DOWNLOAD from '@salesforce/label/c.MSD_CORE_ae_Download';
import UPLOADDOCUMENTS from '@salesforce/label/c.MSD_CORE_ae_Upload_Documents';
import FILENAME from '@salesforce/label/c.MSD_CORE_ae_File_Name';
import FILESIZE from '@salesforce/label/c.MSD_CORE_ae_File_Size';
import FILESUPLOAD from '@salesforce/label/c.MSD_CORE_ae_Files_Uploaded';
import MAXFILES from '@salesforce/label/c.MSD_CORE_ci_Files';
import Email from '@salesforce/label/c.MSD_CORE_ae_merckSupport_Email';
import Button from '@salesforce/label/c.MSD_ae_warningbtn';
import WarningMsg3 from '@salesforce/label/c.MSD_CORE_ae_warningmsg3';
import attachmentinfo from '@salesforce/label/c.MSD_CORE_ci_attachmentstatement';
import TypeOfInformation from '@salesforce/label/c.MSD_CORE_ciportal_typeOfInformation';
import InfoTiming from '@salesforce/label/c.MSD_CORE_Verbal_InfoTiming';
import MainMessage from '@salesforce/label/c.MSD_CORE_Verbal_MainMessage';
import infoMainMessage from '@salesforce/label/c.MSD_CORE_Detail_infoMainMessage';
import ItemTiming from '@salesforce/label/c.MSD_CORE_Detail_ItemTiming';
import PermissionGranted from '@salesforce/label/c.MSD_CORE_Detail_PermissionGranted';
import WhoGavePermission from '@salesforce/label/c.MSD_CORE_Detail_WhoGavePermission';
import RoleOfPermissionGiver from '@salesforce/label/c.MSD_CORE_Detail_RoleOfPermissionGiver';
import titleOfItem from '@salesforce/label/c.MSD_CORE_Detail_titleOfItem';
import uploadFile from '@salesforce/label/c.MSD_CORE_Detail_uploadFile';
import reasonForNoFile from '@salesforce/label/c.MSD_CORE_Detail_reasonForNoFile';
import warning from '@salesforce/label/c.MSD_CORE_Detail_warning';
import ProgramTopic from '@salesforce/label/c.MSD_CORE_isEducational_ProgramTopic';
import ProgramTiming from '@salesforce/label/c.MSD_CORE_isEducational_ProgramTiming';
import ProgramSponsor from '@salesforce/label/c.MSD_CORE_isEducational_ProgramSponsor';
import CompanyName from '@salesforce/label/c.MSD_CORE_isEducational_CompanyName';
import ProgramAttendees from '@salesforce/label/c.MSD_CORE_isEducational_ProgramAttendees';
import EmployeeCount from '@salesforce/label/c.MSD_CORE_isSalesforce_EmployeeCount';
import Region from '@salesforce/label/c.MSD_CORE_isSalesforce_Region';
import OtherInfo from '@salesforce/label/c.MSD_CORE_isOther_OtherInfo';
import VaccineInfo from '@salesforce/label/c.MSD_CORE_isVaccines_VaccineInfo';
import VaccineCompetitor from '@salesforce/label/c.MSD_CORE_isVaccines_VaccineCompetitor';
import VaccineCustomer from '@salesforce/label/c.MSD_CORE_isVaccines_VaccineCustomer';
import VaccineCustomerhelp from '@salesforce/label/c.MSD_CORE_ci_VaccCusthelp';
import Previous from '@salesforce/label/c.MSD_CORE_ciportal_prevnavi';
import Next from '@salesforce/label/c.MSD_CORE_ciportal_nextnavi';
import typeInfoCSS from '@salesforce/resourceUrl/MSD_CORE_ci_typeInfoCSS';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';



export default class MSD_CORE_ci_typeofinfo extends LightningElement {
    @track inputValues = {};
    @api caseDetails;
    @api portalSetting;
    @api editedSection;
    @track charCount = 0;
    @track messageCount = 0;
    @track VaccineCount = 0;
    @track activeSections = []; 
    // @track showFileUpload = false;
    @track FileOther = false;
    uploadedFileNames = '';
    @track prepopulatedFiles = [];
    @track uploadedFileData = [];
    uploadedFilesList = [];
    label = {
        attachmentinfo,
        ALLFILES,
        DELETE,
        DOWNLOAD,
        UPLOADDOCUMENTS,
        FILENAME,
        FILESIZE,
        FILESUPLOAD,
        MAXFILES,
        WarningMsg,
        Phone,
        WarningMsg2,
        Email,
        Button,
        WarningMsg3,
        TypeOfInformation,
        InfoTiming,
        MainMessage,
        infoMainMessage,
        ItemTiming,
        PermissionGranted,
        WhoGavePermission,
        RoleOfPermissionGiver,
        titleOfItem,
        uploadFile,
        reasonForNoFile,
        warning,
        ProgramTopic,
        ProgramTiming,
        ProgramSponsor,
        CompanyName,
        ProgramAttendees,
        EmployeeCount,
        Region,
        OtherInfo,
        VaccineInfo,
        VaccineCompetitor,
        VaccineCustomer,
        VaccineCustomerhelp,
        Previous,
        Next

      }
    //   @track uploadFileOptions = [
    //     { label: 'Yes', value: 'Yes' },
    //     { label: 'No', value: 'No' },
    // ];
    @api
    validateAndDispatch() {
        let isValid = this.isValid();
        let reason = '';
        console.log('Validation Result:', JSON.stringify({ isValid, reason }));
    
        this.dispatchEvent(new CustomEvent('stagevalidation', {
            detail: { isValid, reason, stage: this.currentStage }
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
    get phoneHref() {
        return `tel:${this.label.Phone}`;
    }
    get allSections() {
        return this.inputValues.typeOfInformation ? [this.inputValues.typeOfInformation] : [];
    }


    get emailHref() {
        return `mailto:${this.label.Email}`;
    }
    get options() {
        return this.processOptions(this.portalSetting.TypeofInfo__c, ';');
    }
    get yesNoOptions() {
        return this.processOptions(this.portalSetting.PermissionGranted__c, ';');
    }
    get uploadFileOptions() {
        return this.processOptions(this.portalSetting.uploadFile__c, ';');
    }
    get buttonContainerClass() {
        return this.showFileUpload ? 'button-container':'button-container button-container-bottom';
    }

    processOptions(rawOptions, delimiter) {
        return rawOptions ? rawOptions.split(delimiter).map(option => {
            const [label, value] = option.split(':');
            return { label: label?.trim(), value: value?.trim() || label?.trim() };
        }) : [];
    }

    yesNoOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];
    sendOptions = [
        {label: 'MNSC Fax', value: 'MNSC Fax'},
        {label: 'MNSC E-mail', value: 'MNSC E-mail'},
        {label: 'MNSC Mailing Address', value: 'MNSC Mailing Address'}
    ];
    connectedCallback() {
        this.prepopulateInputs();
        this.loadCustomCSS();
        console.log('Case Details in Stage 3 are:', JSON.stringify(this.caseDetails));
        if (this.inputValues.typeOfInformation) {
            this.activeSections = [this.inputValues.typeOfInformation];
        }
    }

    loadCustomCSS(){
        Promise.all([
            loadStyle(this, typeInfoCSS)
        ]).then(() => {
            console.log('CSS file :landingCSS loaded');
        })
        .catch(error => {
            console.log(error.body.message);
        });
    }
    
    prepopulateInputs() {
        if (this.caseDetails!==undefined) {
            this.inputValues = Object.assign(this.inputValues, this.caseDetails.stage3);
        }
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
        if(this.inputValues && this.inputValues.summary){
            this.charCount = (this.inputValues.summary).length;
        }
        if (this.inputValues && this.inputValues.VaccineInfo){
            this.VaccineCount = (this.inputValues.VaccineInfo).length;
        }
        if(this.inputValues && this.inputValues.mainMessage) {
            this.messageCount = (this.inputValues.mainMessage).length;
        }
    }
    handleFile(event) {
        var fieldValue = event.target.value;
        if (fieldValue === 'Yes') {
            // this.showFileUpload = true;
            this.FileOther = false;
        } else  if(fieldValue === 'No') {
            this.FileOther = true;
            // this.showFileUpload = false;
            this.uploadedFileNames = '';
            this.uploadedFilesList = [];
            this.inputValues.uploadedFiles = [];
        }
    }
    handleInput(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
    
        this.inputValues[fieldName] = fieldValue;
    
        switch (fieldName) {
            case 'VmainMessage':
                this.VmessageCount = fieldValue.length;
            case 'uploadFile':
                this.inputValues.isEmailSelected = null;
                this.inputValues.isMailingSelected = null;  
                this.inputValues.isFaxSelected = null;
                this.inputValues.otherSendOptions = null;
                this.handleFile(event);
                break;
            case 'summary':
                this.charCount = fieldValue.length;
                break;
            case 'typeOfInformation':
                this.inputValues.PermissionGranted = null;
                this.inputValues.ItemTiming = null;
                this.inputValues.WhoGavePermission = null;
                this.inputValues.RoleOfPermissionGiver = null;
                this.inputValues.titleOfItem = null;
                this.inputValues.competitiveInfo = null;
                this.inputValues.isUpload = null;
                this.inputValues.VpermissionGranted = null;
                this.inputValues.mainMessage = null;
                this.inputValues.uploadFile = null;
                this.uploadedFileNames = '';
                this.uploadedFilesList = [];
                this.inputValues.uploadedFiles = null;
                this.uploadedFileNames = '';
                this.uploadedFilesList = [];
                // this.showFileUpload = false;
                this.activeSections = [fieldValue];
                this.reasonForNoFile= null;
                this.inputValues.ProgramAttendees = null;
                this.inputValues.CompanyName = null;
                this.inputValues.ProgramSponsor = null;
                this.inputValues.ProgramTiming = null;
                this.inputValues.ProgramTopic = null;
                this.inputValues.InfoTiming = null;
                this.inputValues.MainMessage = null;
                this.inputValues.EmployeeCount = null;
                this.inputValues.Region = null;
                this.inputValues.isEmailSelected = null;
                this.inputValues.isMailingSelected = null;  
                this.inputValues.isFaxSelected = null;
                this.inputValues.checkPermission = null;
                break;
            case 'VaccineInfo':
                this.VaccineCount = fieldValue.length;
                break;
            // case 'PermissionGranted':
            //     if (fieldValue === 'No') {
            //         this.inputValues.WhoGavePermission = null;
            //         this.inputValues.RoleOfPermissionGiver = null;
            //         this.inputValues.titleOfItem = null;
            //         this.inputValues.uploadFile = null;
            //         this.uploadedFileNames = '';
            //         this.uploadedFilesList = [];
            //         this.showFileUpload = false;
            //     }
            //     break;
            case 'VpermissionGranted':
                this.inputValues.otherSendOptions = null;
                if (fieldValue === 'No') {
                    this.inputValues.WhoGavePermission = null;
                    this.inputValues.RoleOfPermissionGiver = null;
                    this.inputValues.titleOfItem = null;
                    this.inputValues.uploadFile = null;
                    this.uploadedFileNames = '';
                    this.inputValues.isEmailSelected = null;
                    this.inputValues.isMailingSelected = null;
                    this.inputValues.isFaxSelected = null; 
                    this.uploadedFilesList = [];
                    // this.showFileUpload = false;
                } if (fieldValue === 'Yes'){
                    this.inputValues.isFaxSelected = null;
                    this.inputValues.showCompetitiveInfoQuestion = null;
                    this.inputValues.isEmailSelected = null;
                    this.inputValues.isMailingSelected = null;           
                }
            case 'mainMessage':
                this.messageCount = fieldValue.length;
                break;
                
        }
        this.updateFieldVisibility();
    }
    updateFieldVisibility() {
        const visibility = this.fieldVisibility;
        this.inputValues.isUpload = visibility.isUpload;
        this.inputValues.isVerbal = visibility.isVerbal;
        this.inputValues.isDetailPiece = visibility.isDetailPiece;
        this.inputValues.showPermissionFields = visibility.showPermissionFields;
        this.inputValues.isEducational = visibility.isEducational;
        this.inputValues.isSalesforce = visibility.isSalesforce;
        this.inputValues.isVaccines = visibility.isVaccines;
        this.inputValues.isOther = visibility.isOther;
        this.inputValues.showCompetitiveInfoQuestion = visibility.showCompetitiveInfoQuestion;
        this.inputValues.showNonCompetitiveInfoQuestion = visibility.showNonCompetitiveInfoQuestion;
        this.inputValues.iscompetitiveInfo = visibility.iscompetitiveInfo;
        this.inputValues.isnotcompetitiveInfo = visibility.isnotcompetitiveInfo;
        this.inputValues.isFaxSelected = visibility.isFaxSelected;
        this.inputValues.isEmailSelected = visibility.isEmailSelected;
        this.inputValues.isMailingSelected = visibility.isMailingSelected;
        this.inputValues.isnotcompetitiveInfo = visibility.isnotcompetitiveInfo;
        this.inputValues.checkPermission = visibility.checkPermission;
    }
    get accordionLabel() {
        return this.inputValues.typeOfInformation ? `${this.inputValues.typeOfInformation} Information` : 'Information';
    }
    get fieldVisibility() {
        const visibility = {
            checkPermission: false,
            isVerbal: false,
            showCompetitiveInfoQuestion: false,
            showNonCompetitiveInfoQuestion: false,
            isDetailPiece: false,
            iscompetitiveInfo: false,
            isnotcompetitiveInfo: false,
            showPermissionFields: false,
            isUpload: false,
            isEducational: false,
            isSalesforce: false,
            isVaccines: false,
            isOther: false, 
            isFaxSelected: false,
            isEmailSelected: false,
            isMailingSelected: false,     
        };
    
        const { competitiveInfo, typeOfInformation, VpermissionGranted, otherSendOptions,uploadFile } = this.inputValues;
        switch (typeOfInformation) {
            case 'Verbal':
                visibility.isVerbal = true;
                break;
            case 'Detail piece/Aid/Document/Email':
                visibility.isDetailPiece = true;
                visibility.checkPermission = true;
                if(uploadFile === 'Yes'){
                    visibility.isUpload = true;
                }else if(uploadFile === 'No'){
                    visibility.isUpload = false;
                    visibility.isEmailSelected = false;
                    visibility.isFaxSelected = false;
                    visibility.isMailingSelected = false;
                }

                if (VpermissionGranted === 'Yes') {
                    visibility.showPermissionFields = true;
                    visibility.showCompetitiveInfoQuestion = true;
                } else if (VpermissionGranted === 'No') {
                    visibility.showPermissionFields = false;
                    visibility.showCompetitiveInfoQuestion = false;
                }
                break;
            case 'Educational Program':
                visibility.isEducational = true;
                break;
            case 'Salesforce Activity':
                visibility.isSalesforce = true;
                break;
            case 'Vaccines/Pricing/Contracts':
                visibility.isVaccines = true;
                visibility.checkPermission = true;
                if(uploadFile === 'Yes'){
                    visibility.isUpload = true;
                }else if(uploadFile === 'No'){
                    visibility.isUpload = false;
                    visibility.isEmailSelected = false;
                    visibility.isFaxSelected = false;
                    visibility.isMailingSelected = false;
                }
                if (VpermissionGranted === 'Yes') {
                    visibility.showCompetitiveInfoQuestion = true;
                    visibility.showNonCompetitiveInfoQuestion = false;
                } else if (VpermissionGranted === 'No') {
                    visibility.showCompetitiveInfoQuestion = true;
                    visibility.showNonCompetitiveInfoQuestion = true;
                }
                if (competitiveInfo === 'Yes') {
                    visibility.iscompetitiveInfo = true;
                    visibility.isnotcompetitiveInfo = false;
                } else if (competitiveInfo === 'No') {
                    visibility.isnotcompetitiveInfo = true;
                    visibility.iscompetitiveInfo = false;
                }
                break;
            case 'Other':
                visibility.isOther = true;
                break;
        }
        // switch(uploadFile){

        //     case 'Yes':
        //         visibility.isUpload = true;
        //     case 'No':
        //         visibility.isUpload = false;
        // }
        switch (otherSendOptions) {
            case 'MNSC Fax':
                visibility.isFaxSelected = true;
                break;
            case 'MNSC E-mail':
                visibility.isEmailSelected = true;
                break;
            case 'MNSC Mailing Address':
                visibility.isMailingSelected = true;
                break;
        }   
        return visibility;
    }

    isValid() {
        let isValid = true;
        let invalidElement = null;
        const allInputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        allInputs.forEach(input => {
            if (input.required && !input.checkValidity()) {
                isValid = false;
                if (!invalidElement) {
                    invalidElement = input;
                }
            }
        });
        if (!isValid) {
            if (invalidElement) {
                invalidElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
                invalidElement.focus();
            }
            return false;
        }
        if (this.inputValues.uploadFile === 'Yes'&& this.uploadedFilesList.length === 0 && this.inputValues.otherSendOptions === null) {
                this.dispatchEvent(
                    new CustomEvent('showtoast', {
                        detail: { type: 'warning', message: 'Please attach a file to upload!' },
                        bubbles: true,
                        composed: true
                    })
                );
                return false;
        }
    
        return true;
    }

    handlePrevNext(event) {
        const choice = event.target.name;
        let isValid = true;
        let invalidElement = null;
        if (choice === 'Next') {
            const allInputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
            allInputs.forEach(input => {
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
            if ((this.inputValues.uploadFile === 'Yes' && this.uploadedFilesList.length === 0 && this.inputValues.otherSendOptions === null)) {
                this.dispatchEvent(
                    new CustomEvent('showtoast', {
                        detail: { type: 'warning', message: '"Please upload a file or choose an alternative method to send the document' },
                        bubbles: true,
                        composed: true
                    })
                );
                return;
            }
        } 
        // Dispatch the event with the stage inputs and action
        const stage3DetailsEvent = new CustomEvent("stagedetails", {
            detail: {
                stageInputs: this.inputValues, // Pass the input values directly
                action: choice, // Next or Previous
                isValid: isValid // Pass the validation status
            }
        });
    
        this.dispatchEvent(stage3DetailsEvent);
    }

    get acceptedFormats() {
        return ['.pdf', '.ppt', '.docx', '.xlsx', '.csv', '.xls', '.jpeg', '.doc', '.pptx', '.txt', '.csv', '.svg', '.rtf', '.png', '.jpg'];
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        const currentFileCount = this.uploadedFilesList.length;
        const maxFileCount = 5;
        const sizeLimit = 20 * 1024 * 1024; // 20 MB limit
        let totalSize = this.uploadedFilesList.reduce((acc, file) => acc + file.size * 1024 * 1024, 0); // Convert MB back to bytes
        const acceptedFormats = this.acceptedFormats;
    
        if (currentFileCount + uploadedFiles.length > maxFileCount) {
            this.dispatchEvent(
                new CustomEvent('showtoast', {
                    detail: { type: 'error', message: `You can only upload ${maxFileCount} files.` },
                    bubbles: true,
                    composed: true
                })
            );
            return;
        }
    
        let fileNames = '';
        const fileReadPromises = [];
    
        for (let i = 0; i < uploadedFiles.length; i++) {
            const file = uploadedFiles[i];
            const fileExtension = `.${file.name.split('.').pop()}`;
    
            if (!acceptedFormats.includes(fileExtension)) {
                this.dispatchEvent(
                    new CustomEvent('showtoast', {
                        detail: { type: 'error', message: `File ${file.name} is not an allowed format.` },
                        bubbles: true,
                        composed: true
                    })
                );
                return;
            }
    
            if (totalSize + file.size > sizeLimit) {
                this.dispatchEvent(
                    new CustomEvent('showtoast', {
                        detail: { type: 'error', message: `Total file size exceeds 20 MB limit.` },
                        bubbles: true,
                        composed: true
                    })
                );
                return;
            }
    
            totalSize += file.size;
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
                        size: (file.size / (1024 * 1024)).toFixed(2) // size in MB for display
                    });
                };
                reader.onerror = (error) => {
                    this.dispatchEvent(
                        new CustomEvent('showtoast', {
                            detail: { type: 'error', message: `Error reading ${file.name}.` },
                            bubbles: true,
                            composed: true
                        })
                    );
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
        this.dispatchEvent(
            new CustomEvent('showtoast', {
                detail: { type: 'success', message: `${fileNames} uploaded successfully` },
                bubbles: true,
                composed: true
            })
        );
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
}