import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import getdonationreqdetails from "@salesforce/apex/PDS_RequestDetailController.getdonationreqdetails";
import cancelRequest from "@salesforce/apex/PDS_RequestDetailController.cancelRequest";
import getContentDocuments from "@salesforce/apex/PDS_RequestDetailController.getContentDocuments";
import updateRecordStatus from "@salesforce/apex/PDS_RequestDetailController.updateRecordStatus";
import submitDeliveryDocuments from "@salesforce/apex/PDS_RequestDetailController.submitDeliveryDocuments";
import pdsMyRequestcss from '@salesforce/resourceUrl/pdsMyRequestcss';
import donationDate from '@salesforce/label/c.PDS_DonationDate';
import ngo from '@salesforce/label/c.PDS_NGO';
import country from '@salesforce/label/c.PDS_Country';
import quantity from '@salesforce/label/c.PDS_Quantity';
import localPartner from '@salesforce/label/c.PDS_LocalPartner';
import sap from '@salesforce/label/c.PDS_SAP';
import ndc from '@salesforce/label/c.PDS_NDC';
import batch from '@salesforce/label/c.PDS_Batch';
import exp from '@salesforce/label/c.PDS_Exp';
import donationInfo from '@salesforce/label/c.PDS_DonationInfo';
import indication from '@salesforce/label/c.PDS_Indication';
import donee from '@salesforce/label/c.PDS_Donee';
import dType from '@salesforce/label/c.PDS_DonationType';
import destination from '@salesforce/label/c.PDS_Destination';
import appName from '@salesforce/label/c.PDS_ApplicantName';
import appInst from '@salesforce/label/c.PDS_ApplicantInstitution';
import tabReq from '@salesforce/label/c.PDS_TabRequested';
import treatmentApp from '@salesforce/label/c.PDS_TreatmentApp';
import appDate from '@salesforce/label/c.PDS_ApprovalDate';
import taxInclusion from '@salesforce/label/c.PDS_TaxInclusion';
import ponumber from '@salesforce/label/c.PDS_PO';
import comments from '@salesforce/label/c.PDS_Comments';
import docs from '@salesforce/label/c.PDS_Documents';
import cancelReq from '@salesforce/label/c.PDS_CancelReq';
import cancelMsg from '@salesforce/label/c.PDS_CancelReqMessage';
import cancelBtn from '@salesforce/label/c.PDS_Cancel_Btn';
import editReq from '@salesforce/label/c.PDS_EditReq';
import back from '@salesforce/label/c.PDS_Back';
import mmop from '@salesforce/label/c.PDS_MMOP';
import cancelSuccess from '@salesforce/label/c.PDS_CancelRequestConfirmation';
import cancelError from '@salesforce/label/c.PDS_CancelRequestError';
import delconfirm from '@salesforce/label/c.PDS_DeliveryConfirmation';
import confirmbtn from '@salesforce/label/c.PDS_Confirm';
import popMsg from '@salesforce/label/c.PDS_DeliveryPopMsg';
import deliveryToastMessage from '@salesforce/label/c.PDS_confirmDeliveryMessage';

import getApplicationSettings from '@salesforce/apex/PDS_CustomMetadataHandler.getApplicationSettings';
import areaToUpload from '@salesforce/label/c.PDS_FileAreaUpload';
import documentTags from '@salesforce/label/c.PDS_Documenttags';
import uploadNewFile from '@salesforce/label/c.PDS_UploadNewFile';
import markAsDeliveredBtn from '@salesforce/label/c.PDS_MarkAsDelivered_Btn';
import uploadDocuments from '@salesforce/label/c.PDS_UploadDocuments';
import uploadDeliveryReceipt from '@salesforce/label/c.PDS_UploadDeliveryReceipt';
import uploadTaxLetter from '@salesforce/label/c.PDS_UploadTaxLetter';
import submitDocumentBtn from '@salesforce/label/c.PDS_SubmitDocument_Btn';
import documentsUplaodMsg from '@salesforce/label/c.PDS_DocumentsUploadMsg';
import reallocation from '@salesforce/label/c.PDS_OpenforRe_allocation';





import CANCELREQUEST from '@salesforce/label/c.PDS_Cancel_Request';


export default class PdsRequestDetail extends NavigationMixin(LightningElement) {

    @api recid;
    @track cancelpop = false;
    @track deliveredPop = false;
    @track showSpinner = false;
    @track documents = [];
    @track reqData = [];
    @track delivered = false;
    documentDataList = [];
    contentDocuments;
    deliveryDocuments;
    appTypeMsg;
    approvalTypeMsg;
    appSettings = [];
    fileFormats = [];
    uploadDeliveryReceipt;
    uploadTaxLetter;
    deliveryReceiptName;
    deliveryReceiptConfirmation;
    taxLetterName;
    taxLetterConfirmation;
    submitBtnStatus = true;
    cancelBtnStatus = true;
    deliveryReceiptErr = false;
    taxReceiptErr = false;
    @track donationRequestObj = {};



    label = {
        donationDate,
        ngo,
        country,
        quantity,
        localPartner,
        sap,
        ndc,
        batch,
        exp,
        donationInfo,
        indication,
        donee,
        dType,
        destination,
        appName,
        appInst,
        tabReq,
        treatmentApp,
        appDate,
        taxInclusion,
        ponumber,
        comments,
        docs,
        cancelReq,
        cancelMsg,
        editReq,
        cancelBtn,
        back,
        mmop,
        cancelSuccess,
        cancelError,
        areaToUpload,
        documentTags,
        uploadNewFile,
        markAsDeliveredBtn,
        uploadDocuments,
        uploadDeliveryReceipt,
        uploadTaxLetter,
        submitDocumentBtn,
        documentsUplaodMsg,
        CANCELREQUEST,
        delconfirm,
        confirmbtn,
        popMsg,
        deliveryToastMessage,
        reallocation
    };
    connectedCallback() {
        this.showSpinner = true;
        Promise.all([
            loadStyle(this, pdsMyRequestcss)
        ])
        this.getDonationReqDetails();
        this.getDocs();
        this.mdpAppSettingsMethod();
    }

    @wire(CurrentPageReference)
    wiredStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recid = currentPageReference.state.id;
        }
        console.log('recordid' + this.recid);
    }

    getDonationReqDetails() {
        getdonationreqdetails({ requestid: this.recid })
            .then(data => {
                console.log('Request data -->', data);
                this.reqData = this.getFormattedData(data);
                console.log('this.reqData' + JSON.stringify(this.reqData));
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                console.log('Request error--->', { error });
            });
    }

    
    getFormattedData(data) {

        let statusMapping = {
            'Pending': { iconName: 'utility:clock', divLabelClass: 'pending-cls', iconLabelClass: 'pending-icon' },
            'Draft': { iconName: 'utility:note', divLabelClass: 'pending-cls', iconLabelClass: 'pending-icon' },
            'Approved': { iconName: 'utility:success', divLabelClass: 'prod-ordered-cls', iconLabelClass: 'prod-ordered-icon' },
            'Products Ordered': { iconName: 'utility:success', divLabelClass: 'prod-ordered-cls', iconLabelClass: 'prod-ordered-icon' },
            'Closed': { iconName: 'utility:clear', divLabelClass: 'closed-cls', iconLabelClass: 'closed-icon' },
            'Reviewed': { iconName: 'utility:preview', divLabelClass: 'reviewed-cls', iconLabelClass: 'reviewed-icon' },
            'Need Additional Details': { iconName: 'utility:info_alt', divLabelClass: 'closed-cls', iconLabelClass: 'closed-icon' },
            'Cancelled': { iconName: 'utility:clear', divLabelClass: 'cancelled-cls', iconLabelClass: 'cancelled-icon' },

        };

        let statusInfo = statusMapping[data.PDS_Donation_Request_Status__c] || { iconName: '', divLabelClass: '', iconLabelClass: '' };
        let products = [];
        if (data.Product_Line_Items__r) {
            products = data.Product_Line_Items__r.map(item => ({
                plid: item.Id, 
                prodNames: item.PDS_Product__r.Name,
                countries: item.PDS_Country__c,
                quantities: item.PDS_Quantity_Requested__c,
                saps: item.PDS_Product__r.PDS_SAP_Code__c,
                localpartners: item.PDS_Local_Partner__c,
                tabletsreqs: item.PDS_Tablets_Requested__c,
                treatmentsapps: item.PDS_Treatments_Approved__c,
                coldchains: item.PDS_Product__r.PDS_Cold_Chain__c,
                ndcnumber: item.PDS_Product__r.PDS_NDC_Number__c,
                // exp: item.PDS_Expiration_Date__c,
                exp: item.PDS_Expiration_Date__c ? new Intl.DateTimeFormat('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' }).format(new Date(item.PDS_Expiration_Date__c)) : '',
                batch: item.PDS_Batch_Number__c,
                isDelivered: item.PDS_Shipping_Status__c == 'Delivered',
                donreqId:item.PDS_Donation_Request__c,
                statusDelivered:item.PDS_Shipping_Status__c == 'In-Transit' && data.PDS_Donation_Request_Status__c=='Products Ordered',
            }));
        }
        console.log('products' + JSON.stringify(products));
        let date = data.PDS_Request_Submit_Date__c ? new Intl.DateTimeFormat('en-US').format(new Date(data.PDS_Request_Submit_Date__c)) : '';
        let approvalDate = data.PDS_Approval_Date__c ? new Intl.DateTimeFormat('en-US').format(new Date(data.PDS_Approval_Date__c)) : '';
        // let statusMDPDelivered = data.PDS_Donation_Request_Status__c === 'Products Ordered' && data.Product_Line_Items__r && data.Product_Line_Items__r.some(item => item.PDS_Shipping_Status__c === 'In-Transit');
        let returndata = {
            RequestId: data.Id,
            reqName: data.Name,
            status: data.PDS_Donation_Request_Status__c,
            divlabelStatus: statusInfo.divLabelClass,
            iconlabelStatus: statusInfo.iconLabelClass,
            iconName: statusInfo.iconName,
            donationDate:date,
            doneeName: data.PDS_Donee__r ? data.PDS_Donee__r.Formatted_Name_vod__c : '',
            prodName: data.Product_Line_Items__r.length > 0 ? data.Product_Line_Items__r[0].PDS_Product__r.Name : '',
            coldchain: data.Product_Line_Items__r[0].PDS_Product__r.PDS_Cold_Chain__c,
            country: data.Product_Line_Items__r.length > 0 ? data.Product_Line_Items__r[0].PDS_Country__c : '',
            quantity: data.Product_Line_Items__r.length > 0 ? data.Product_Line_Items__r[0].PDS_Quantity_Requested__c : '',
            sap: data.Product_Line_Items__r.length > 0 ? data.Product_Line_Items__r[0].PDS_Product__r.PDS_SAP_Code__c : '',
            localpartner: data.Product_Line_Items__r.length > 0 ? data.Product_Line_Items__r[0].PDS_Local_Partner__c : '',
            indication: data.PDS_Indication__c,
            donationType: data.PDS_Donation_Type__c,
            destination: data.PDS_Destination__c,
            applicantName: data.PDS_Applicant_Name__c,
            applicantInst: data.PDS_Applicant_Institution__c,
            tabletsreq: data.Product_Line_Items__r.length > 0 ? data.Product_Line_Items__r[0].PDS_Tablets_Requested__c : '',
            treatmentsapp: data.Product_Line_Items__r.length > 0 ? data.Product_Line_Items__r[0].PDS_Treatments_Approved__c : '',
            approvaldate: approvalDate,
            taxreport: data.PDS_Tax_Report_Inclusion__c ? 'Yes' : 'No',
            comments: data.PDS_Additional_Information__c,
            statusCheck: data.PDS_Donation_Request_Status__c == 'Draft' || data.PDS_Donation_Request_Status__c == 'Pending' || data.PDS_Donation_Request_Status__c == 'Reviewed' || data.PDS_Donation_Request_Status__c == 'Need Additional Details',
            isMDPrectype: data.RecordType.Name == 'MDP',
            isMMOPrectype: data.RecordType.Name == 'MMOP',
            proposalName: data.PDS_Proposal__r ? data.PDS_Proposal__r.Name : '',
            products: products,
            poNumber: data.PDS_PO_Number__c,
            isExcess: data.PDS_Donation_Type__c == 'Excess Product Donation',
            statusCheckMMOP:data.RecordType.Name == 'MMOP'&& (data.PDS_Donation_Request_Status__c == 'Draft' || data.PDS_Donation_Request_Status__c == 'Pending'|| data.PDS_Donation_Request_Status__c == 'Reviewed' || data.PDS_Donation_Request_Status__c == 'Approved' || (data.PDS_Donation_Request_Status__c == 'Products Ordered' && data.PDS_Shipping_Status__c !=='Delivered') || (data.PDS_Donation_Request_Status__c == 'Closed' && data.PDS_Open_For_ReAllocation__c== true)),
            statusCheckMMOPcancel:data.RecordType.Name == 'MMOP'&& (data.PDS_Donation_Request_Status__c == 'Draft' || data.PDS_Donation_Request_Status__c == 'Pending'|| data.PDS_Donation_Request_Status__c == 'Reviewed' || data.PDS_Donation_Request_Status__c == 'Approved'),
            statusCheckMDP: data.RecordType.Name == 'MDP'&& (data.PDS_Donation_Request_Status__c == 'Draft' || data.PDS_Donation_Request_Status__c == 'Pending' || data.PDS_Donation_Request_Status__c == 'Reviewed' || data.PDS_Donation_Request_Status__c == 'Need Additional Details'),
            isDelivered: data.PDS_Donation_Request_Status__c == 'Products Ordered',
            prodlineitemId: data.Product_Line_Items__r.length > 0 ? data.Product_Line_Items__r[0].Id : '',
            statusMDPDelivered:data.PDS_Donation_Request_Status__c === 'Products Ordered' && data.Product_Line_Items__r.length > 0 && data.Product_Line_Items__r[0].PDS_Shipping_Status__c === 'In-Transit',
            isProductsOrdered:data.RecordType.Name == 'MMOP'&& (data.PDS_Donation_Request_Status__c === 'Products Ordered' && data.PDS_Shipping_Status__c === 'In-Transit'),
            openForReallocation:data.PDS_Donation_Request_Status__c == 'Closed' && data.PDS_Open_For_ReAllocation__c == true,
        };
        console.log('returndata' + JSON.stringify(returndata));
        return returndata;
    }

    getDocs() {
        getContentDocuments({ requestId: this.recid })
            .then(result => {
                if (result) {
                    //this.contentDocuments = result;
                    this.contentDocuments = Object.keys(result).map(key => ({ name: key, url: result[key].fileData, fileType: result[key].fileType.toLowerCase() }));
                    console.log('content docs: ', this.contentDocuments);
                    console.log('content docs: ', JSON.stringify(this.contentDocuments));
                    console.log('content docs Result : ', JSON.stringify(result));
                } else {
                    console.error('No data');
                }
            })
            .catch(error => {
                console.error('Error: ', error);
            });

    }
    mdpAppSettingsMethod(){
        getApplicationSettings({ flowDeveloperName: 'MMOP_Flow_Settings' })
        .then(result => {
            this.appSettings = result;
            const fileFormatsString = this.appSettings.pds_accepted_file_formats__c;
            this.fileFormats = fileFormatsString.split(',');
            console.log('fileFormats ' + this.fileFormats);

        })
        .catch(error => {
            console.error('Error: ', error);
         });
    }



     handleFileInput(event) {
        try {
            this.cancelBtnStatus = false;
            const file = event.target.files[0];
            console.log('file is there');
            if (!file) {            console.log(' no file is there');

                return;
            }

            const fieldLabel = event.target.name;
            const maxSizeInBytes = this.appSettings.pds_maximum_file_size_allowed__c;
            const fileExtension = file.name.split('.').pop().toLowerCase();
                        console.log('fieldLabel '+fieldLabel);
                        console.log('fileExtension '+fileExtension);
                        console.log('maxSizeInBytes '+maxSizeInBytes);

            // Check file size
            if (file.size > maxSizeInBytes) {
                this[fieldLabel] = '';
                this.fileTypeError(fieldLabel, true, file.name, 'File size exceeds the maximum allowed size');
                                        console.log('File size exceeds ');

                return;
            }

            // Check file type
            if (!this.fileFormats.includes(fileExtension)) {
                this[fieldLabel] = '';
                console.error('Invalid file type.');
                this.fileTypeError(fieldLabel, true, file.name, '');
                return;
            }

            // Handle specific field actions
            if (fieldLabel === 'uploadDeliveryReceipt') {

                this.deliveryReceiptName = file.name;
                this.deliveryReceiptConfirmation = true;
            }
            if (fieldLabel === 'uploadTaxLetter') {
                this.taxLetterName = file.name;
                this.taxLetterConfirmation = true;
            }

            // Read the file
            const reader = new FileReader();
            reader.onload = () => {
                const fileContents = reader.result;
                const base64String = btoa(new Uint8Array(fileContents)
                    .reduce((data, byte) => data + String.fromCharCode(byte), ''));
                this[fieldLabel] = base64String;
                this.fileTypeError(fieldLabel, false, file.name, '');
                console.log(`File Contents for ${fieldLabel}:`, this[fieldLabel]);
            };
            reader.onerror = () => {
                console.error('Error reading file');
                this.fileTypeError(fieldLabel, true, file.name, 'Error reading file');
            };

            reader.readAsArrayBuffer(file);
        } catch (e) {
            this.deliveryReceiptConfirmation = false;
            this.taxLetterConfirmation = false;
            console.error('File Read Error', e);
        }
    }

    fileTypeError(fieldLabel, valid, fileName, msg) {
        const element = this.template.querySelector('.' + fieldLabel);
        if (element && valid) {
            element.style.display = 'block';
            element.style.color = '#9A151C';
            if (fieldLabel == 'uploadDeliveryReceipt') {
                this.appTypeMsg = (msg != '') ? msg : 'Incorrect file type selected';
                this.deliveryReceiptErr = true;
            } else {
                this.approvalTypeMsg = (msg != '') ? msg : 'Incorrect file type selected';
                this.taxReceiptErr = true;

            }
        } else if (element && !valid) {
            element.style.display = 'block';
            element.style.color = '#000000E0';
            this.fileTypeMsg = fileName;
            if (fieldLabel == 'uploadDeliveryReceipt') {
                this.appTypeMsg = fileName;
                this.deliveryReceiptErr = false;
            } else {
                this.approvalTypeMsg = fileName;
                 this.taxReceiptErr = false;

            }
        }
        
        this.submitBtnStatus = this.deliveryReceiptErr || this.taxReceiptErr;

    }


    navigateEdit() {
        this.showSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'edit__c',
                url: '/donation-request/edit' + '?id=' + this.recid
            },
        });
    }
    backClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'My_Requests__c',
                url: '/my-requests'
            },
        });
    }
    cancelRequest() {
        this.cancelpop = true;
    }
    onCancel() {
        this.cancelpop = false;
    }
    oncancelRequest() {
        this.showSpinner = true;
        console.log('this.Status : ', this.recid);
        cancelRequest({ requestid: this.recid })
            .then((result) => {
                if (result === 'Request Cancelled') {
                    console.log('Result in cancelRequest--->', { result });
                    this.cancelpop = false;
                    this.template.querySelector('c-pds-Toast-Message').showToast(this.label.cancelSuccess);
                    setTimeout(() => {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                name: 'My_Requests__c',
                                url: '/my-requests'
                            }
                        });
                    }, 3000);
                }
                
            })
            .catch((error) => {
                console.log('Error in cancelRequest-->', { error });
                this.template.querySelector('c-pds-Toast-Message').showToast(this.label.cancelError);

            });
    }

    fileTypeToExtension = {
        'pdf': 'pdf',
        'JPEG': 'jpg',
        'png': 'png',
        'word': 'doc',
        'word_x': 'docx',
        'excel_x': 'xlsx',
        'excel': 'xls'
    };

    openDocument(event) {
        const { filename, url, type } = event.target.dataset;
        console.log('Type of document ' + type);
        const base64String = url.split(',')[1];
        const binaryString = atob(base64String);
        let fileType = (type == 'pdf') ? 'application/pdf' : 'application/octet-stream';

        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        const blob = new Blob([bytes], { type: fileType });

        const blobUrl = URL.createObjectURL(blob);

        if (type == 'pdf') {
            window.open(blobUrl, '_blank');
            // const link = document.createElement('a');
            // link.href = blobUrl;
            // link.target = '_blank';
            // link.click();
        } else {
            const link = document.createElement('a');
            link.href = blobUrl;
            link.target = '_blank';
            link.download = filename + '.' + this.fileTypeToExtension[type.toLowerCase()];
            link.click();
        }
    }

    cancelDocuments(){

        const uploadTaxLetterElement = this.template.querySelector('.' + 'uploadTaxLetter');
        if (uploadTaxLetterElement) {
            uploadTaxLetterElement.style.display = 'block';
            uploadTaxLetterElement.style.color = '';
        }
        const uploadDeliveryReceiptElement = this.template.querySelector('.' + 'uploadDeliveryReceipt');
        if (uploadDeliveryReceiptElement) {
            uploadDeliveryReceiptElement.style.display = 'block';
            uploadDeliveryReceiptElement.style.color = '';
        }
        this.appTypeMsg ='';
        this.approvalTypeMsg='';
        this.deliveryReceiptName = '';
        this.deliveryReceiptConfirmation = false;
        this.taxLetterName = '';
        this.taxLetterConfirmation = false;
        this.uploadDeliveryReceipt = '';
        this.uploadTaxLetter = '';
        this.submitBtnStatus = true;
        this.cancelBtnStatus = true;
        this.fileTypeMsg ='';
        const files = this.template.querySelectorAll('.slds-file-selector__dropzone');
        files.forEach(function(fileInput) {
            fileInput.querySelector('.fileInput').value = '';
        });
    }
    submitDocuments(){
        this.showSpinner = true;
        this.donationRequestObj = {
            id : this.recid,
            doneName : this.reqData.doneeName,
            authorizationNumber : this.reqData.reqName,
            deliveryReceipt : this.uploadDeliveryReceipt ?? '',
            deliveryReceiptName : this.deliveryReceiptName ?? '',
            taxLetter : this.uploadTaxLetter ?? '',
            taxLetterName : this.taxLetterName ?? '',
        };
        console.log(JSON.stringify(this.donationRequestObj));
        submitDeliveryDocuments({donationReqDocuments : this.donationRequestObj})
        .then(result=>{
            console.log('Success'+result);
            if(result === 'Success'){
                this.showSpinner = false;
                this.template.querySelector('c-pds-Toast-Message').showToast(this.label.documentsUplaodMsg);
                this.showSpinner = true;
                this[NavigationMixin.GenerateUrl]({
                    type: 'standard__webPage',
                    attributes: {
                        url: window.location.href,
                    }
                }).then(url => {
                window.location.href = url;
            });
            }
        })
        .catch(error=>{
            console.log('error');

        }
        )
    }
    
    markDelivered(){
        this.deliveredPop = true;
    }
    onDelCancel(){
        this.deliveredPop = false;
    }
    onConfirm() {
        this.showSpinner = true;
        updateRecordStatus({ recordId:this.recid})
            .then(() => {
                this.deliveredPop = false;
                this.template.querySelector('c-pds-Toast-Message').showToast(this.label.deliveryToastMessage);
                this.showSpinner = false;
                setTimeout(() => {
                    location.reload();
                }, 3000);
            })
            .catch(error => {
                this.showToast('Error', 'Failed to update record: ' + error.body.message, 'error');
            });
    }
}