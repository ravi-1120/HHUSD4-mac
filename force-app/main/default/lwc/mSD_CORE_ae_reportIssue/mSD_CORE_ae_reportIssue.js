import { LightningElement, track, api } from 'lwc';
import sendEmail from '@salesforce/apex/mSD_CORE_ae_sendEmail.sendEmail';
import FILESUPLOAD from '@salesforce/label/c.MSD_CORE_ae_Files_Uploaded';
import FILENAME from '@salesforce/label/c.MSD_CORE_ae_File_Name';
import FILESIZE from '@salesforce/label/c.MSD_CORE_ae_File_Size';
import DOWNLOAD from '@salesforce/label/c.MSD_CORE_ae_Download';
import DELETE from '@salesforce/label/c.MSD_CORE_ae_Delete';
import ALLFILES from '@salesforce/label/c.MSD_CORE_ae_ReportIssueFileInfo1';
import MAXFILES from '@salesforce/label/c.MSD_CORE_ae_ReportIssueFileInfo2';
import REPORTISSUE from '@salesforce/label/c.MSD_CORE_ae_An_Issue';
import REPORTISSUESTATEMENT1 from '@salesforce/label/c.MSD_CORE_ae_Report_an_Issue_statement';
import REPORTISSUESTATEMENT2 from '@salesforce/label/c.MSD_CORE_ae_Report_an_Issue_statement1';
import CONTINUE from '@salesforce/label/c.MSD_CORE_ae_Continue';


export default class MSD_CORE_ae_reportIssue extends LightningElement {

    label = {
        FILESUPLOAD,
        FILENAME,
        FILESIZE,
        DOWNLOAD,
        DELETE,
        MAXFILES,
        ALLFILES,
        REPORTISSUE,
        REPORTISSUESTATEMENT1,
        REPORTISSUESTATEMENT2,
        CONTINUE
    }

    @track isParentModal = false;
    @api showModal;
    uploadedFileNames = '';
    @track isChildModal = true;
    @track uploadedFilesList = [];
    @track inputValues = {
        name: '',
        email: '',
        message: ''
    };
    get acceptedFormats() {
        return ['.pdf', '.ppt', '.docx', '.jpg', '.jpeg', '.png'];
    }

    handleInput(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        this.inputValues[fieldName] = fieldValue;
    }
    showNotification(type, message) {
        this.template.querySelector('c-custom-toast').showToast(type, message);
    }

    handleSubmit(event) {
        let isValid = this.validateRequiredFields();
        if (isValid) {
            this.sendReport(event);
            this.showNotification('success', `Issue reported successfully!`);
            // this.handleClose();
        }
    }
    onBlur(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;   
        const validationRules = {
            'email': {
                isValid: fieldValue === '' || /\S+@\S+\.\S+/.test(fieldValue),
                errorMessage: "Invalid Email Address"
            },
        };
        const { isValid, errorMessage } = validationRules[fieldName];
        if (!isValid) {
            event.target.setCustomValidity(errorMessage);
            this.inputValues[fieldName] = ''; 
            event.target.value = '';
        } else {
            event.target.setCustomValidity('');
            this.inputValues[fieldName] = fieldValue;
        }
        event.target.reportValidity();
        const errorElement = this.template.querySelector(`[data-id="${fieldName}-error"]`);
        if (errorElement) {
            errorElement.textContent = isValid ? '' : errorMessage;
        }
    }

    sendReport(event) {
        event.preventDefault();
        const filesDataJson = JSON.stringify(this.uploadedFilesList);
        sendEmail({
            recipientEmail: this.inputValues.email,
            senderName: this.inputValues.name,
            messageBody: this.inputValues.message,
            filesDataJson: filesDataJson
        })
            .then(result => {
                if (result) {
                    // this.showNotification('success', 'Email Sent Successfully.');
                    this.inputValues = { name: '', email: '', message: '' };
                    this.uploadedFilesList = [];
                    this.uploadedFileNames = '';
                    this.showNotification('success', `Issue reported successfully!`);
                    this.template.querySelectorAll('lightning-input, lightning-input[type="email"], lightning-textarea').forEach(field => {
                        field.value = '';
                    });
                    // Inside your sendReport or handleSubmit method after successful submission
                    this.dispatchEvent(new CustomEvent('reportsubmitted', {
                        bubbles: true,
                        composed: true,
                        detail: { message: 'Issue reported successfully!' }
                    }));

                } else {
                    this.showNotification('error', 'Issue was not reported!');
                }
            })
            .catch(error => {
                console.log('Error', error);
                this.showNotification('error', `Issue was not reported!`);
            });
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length + this.uploadedFilesList.length > 3) {
            this.showNotification('error', 'You can only upload a maximum 3 files.');
            return;
        }

        let fileNames = '';
        const fileReadPromises = [];
        let totalSize = 0;
        //const sizeLimit = 20 * 1024 * 1024;  // 15 MB

        for (let i = 0; i < uploadedFiles.length; i++) {
            const file = uploadedFiles[i];
            if (!this.acceptedFormats.includes('.' + file.name.split('.').pop().toLowerCase())) {
                this.showNotification('error', `File format of ${file.name} is not allowed.`);
                return;
            }
    
            totalSize += file.size;
            if (totalSize > 3 * 1024 * 1024) { // Check total size limit
                this.showNotification('error', `Total file size exceeds 3 MB limit.`);
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
        });
        fileNames = fileNames.slice(0, -2);
        this.uploadedFileNames = fileNames;
        this.showNotification('success', `${fileNames} are uploaded successfully`);
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
    toggleModal() {
        this.isParentModal = false;
        this.handleClose();
    }

    validateRequiredFields() {
        const allRequiredFields = [...this.template.querySelectorAll('.requiredField')];
        let isValid = allRequiredFields.every(field => {
            return field.reportValidity();
        });
        return isValid;
    }
    // handleKeystroke(event) {
    //     var eleId = event.currentTarget.dataset.id;
    //     var currentElement = this.template.querySelector(`[data-id="${eleId}"]`);
    //     var firstElement = this.template.querySelector('[data-id="hcp-btn1"]');
    //     var lastElement = this.template.querySelector('[data-id="hcp-btn2"]');

    //     let isTabPressed = event.key === 'Tab' || event.keyCode === 9;
    //     if (!isTabPressed) return;

    //     if (event.shiftKey) {
    //         if (currentElement === firstElement) {
    //             lastElement.focus();
    //             event.preventDefault();
    //         }
    //     } else {
    //         if (currentElement === lastElement) {
    //             firstElement.focus();
    //             event.preventDefault();
    //         }
    //     }
    // }
    closepopup() {
        this.isChildModal = false;
        this.isParentModal = false;
        this.handleClose();
    }
    handleClose() {
        this.showNotification('success', `Issue reported successfully!`);
        this.isChildModal = false;
        this.isParentModal = false;
        this.showModal = false;
        this.dispatchEvent(new CustomEvent('close'));
    }
    handleContinue() {
        this.isChildModal = false;
        this.isParentModal = true;
    }
    handleShow() {
        this.isChildModal = true;
    }
}