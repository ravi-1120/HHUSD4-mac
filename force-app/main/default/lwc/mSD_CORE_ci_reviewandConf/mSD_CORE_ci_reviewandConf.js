import { LightningElement,api,track,wire } from 'lwc';
import FILENAME from '@salesforce/label/c.MSD_CORE_ae_File_Name';
import FILESIZE from '@salesforce/label/c.MSD_CORE_ae_File_Size';
import FILESUPLOAD from '@salesforce/label/c.MSD_CORE_ae_Files_Uploaded';
import DOWNLOAD from '@salesforce/label/c.MSD_CORE_ae_Download';
import DELETE from '@salesforce/label/c.MSD_CORE_ae_Delete';
import uploadFile from '@salesforce/label/c.MSD_CORE_Detail_uploadFile';
import MainMessage from '@salesforce/label/c.MSD_CORE_Verbal_MainMessage';
import submitCaseDetails from '@salesforce/apex/MSD_CORE_ci_CaseController.createRequestCase';

export default class MSD_CORE_ci_reviewandConf extends LightningElement {
    @api caseDetails;
    @track isLoading = false;
    @track stage2 = {};
    @track stage3 = {};
    @track stage4 = [];
    @track stage5 = {};
    @track stage6 = {};
    @track activeSections = ['1', '2', '3', '4', '5', '6'];
    ProductCatalog;
    isVerbal;
    isEducational;
    isDetailPiece;
    showPermissionFields;
    isSalesforce;
    uploadedFilesList = null;
    isVaccines;
    isOther;
    label = {
        FILENAME,
        FILESIZE,
        FILESUPLOAD,
        DOWNLOAD,
        DELETE,
        uploadFile,
        MainMessage
    };
    connectedCallback() {
        this.token = '';
        this.handleCaseDetail();
    }
    get hasUploadedFiles() {
        return this.uploadedFilesList && this.uploadedFilesList.length > 0;
    }
    handleCaseDetail() {
        console.log('The Final Case Details for Submitting the Case are:', JSON.stringify(this.caseDetails));
        this.stage1 = { ...this.caseDetails.stage1 };
        this.stage2 = { ...this.caseDetails.stage2 };
        this.stage3 = { ...this.caseDetails.stage3 };
        this.stage4 = { ...this.caseDetails.stage4 };
        this.ProductCatalog = this.stage2.ProductCatalog || false;
        this.isVerbal = this.stage3.isVerbal || false;
        this.isDetailPiece = this.stage3.isDetailPiece || false;
        this.showPermissionFields = this.stage3.showPermissionFields || false;
        this.isEducational = this.stage3.isEducational || false;
        this.isSalesforce = this.stage3.isSalesforce || false;
        this.isVaccines = this.stage3.isVaccines || false;
        this.isUpload = this.stage3.isUpload || false;
        this.isOther = this.stage3.isOther || false;
        this.showCompetitiveInfoQuestion = this.stage3.showCompetitiveInfoQuestion || false;
        if (this.stage3.uploadedFiles) {
            this.uploadedFilesList = [...this.stage3.uploadedFiles];
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
    handleSubmit() {
        this.isLoading = true;
        submitCaseDetails({ caseDetails: this.caseDetails })
            .then(result => {
                this.isLoading = false;
                if (result.isSuccess) {
                    this.message = `Case created successfully with case number: ${result.caseNumber}`;
                    this.dispatchEvent(new CustomEvent('submitsuccess', {
                        detail: { caseNumber: result.caseNumber }
                    }));
                    this.dispatchEvent(
                        new CustomEvent('showtoast', {
                            detail: { type: 'success', message: this.message },
                            bubbles: true,
                            composed: true
                        })
                    );
                    // this.showToast('Success', this.message, 'success');
                } else {
                    this.message = `Error: ${result.errorMessage}`;
                    this.dispatchEvent(
                        new CustomEvent('showtoast', {
                            detail: { type: 'error', message: this.message },
                            bubbles: true,
                            composed: true
                        })
                    );
                }
            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = error?.message || 'Unknown error occurred';
                this.message = errorMessage;
                this.dispatchEvent(
                    new CustomEvent('showtoast', {
                        detail: { type: 'error', message: errorMessage },
                        bubbles: true,
                        composed: true
                    })
                );
            });
    }

}