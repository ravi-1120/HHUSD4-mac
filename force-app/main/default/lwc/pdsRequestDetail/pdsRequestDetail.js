import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import getdonationreqdetails from "@salesforce/apex/PDS_RequestDetailController.getdonationreqdetails";
import cancelRequest from "@salesforce/apex/PDS_RequestDetailController.cancelRequest";
import getContentDocuments from "@salesforce/apex/PDS_RequestDetailController.getContentDocuments";
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
import CANCELREQUEST from '@salesforce/label/c.PDS_Cancel_Request';


export default class PdsRequestDetail extends NavigationMixin(LightningElement) {

    @api recid;
    @track cancelpop = false;
    @track showSpinner = false;
    @track documents = [];
    @track reqData = [];
    documentDataList = [];
    contentDocuments;
    label ={
       donationDate ,
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
       CANCELREQUEST
    };
    connectedCallback() {
        this.showSpinner = true;
        Promise.all([
            loadStyle(this, pdsMyRequestcss)
        ])
        this.getDonationReqDetails();
        this.getDocs();
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
            'Need Additional Details': { iconName: 'utility:info_alt', divLabelClass: 'closed-cls', iconLabelClass: 'closed-icon' }
        };

        let statusInfo = statusMapping[data.PDS_Donation_Request_Status__c] || { iconName: '', divLabelClass: '', iconLabelClass: '' };

        let products = [];
        if (data.Product_Line_Items__r) {
            products = data.Product_Line_Items__r.map(item => ({
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
            }));
        }
        console.log('products' + JSON.stringify(products));
        let date = data.PDS_Request_Submit_Date__c ? new Intl.DateTimeFormat('en-US').format(new Date(data.PDS_Request_Submit_Date__c)) : '';
        let approvalDate = data.PDS_Approval_Date__c ? new Intl.DateTimeFormat('en-US').format(new Date(data.PDS_Approval_Date__c)) : '';
        let returndata = {
            RequestId: data.Id,
            reqName: data.Name,
            status: data.PDS_Donation_Request_Status__c,
            divlabelStatus: statusInfo.divLabelClass,
            iconlabelStatus: statusInfo.iconLabelClass,
            iconName: statusInfo.iconName,
            donationDate:date,
            doneeName: data.PDS_Donee__r ? data.PDS_Donee__r.Name : '',
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
            statusCheckMMOP:data.RecordType.Name == 'MMOP'&& (data.PDS_Donation_Request_Status__c == 'Draft' || data.PDS_Donation_Request_Status__c == 'Pending' || data.PDS_Donation_Request_Status__c == 'Need Additional Details'),
            statusCheckMDP: data.RecordType.Name == 'MDP'&& (data.PDS_Donation_Request_Status__c == 'Draft' || data.PDS_Donation_Request_Status__c == 'Pending' || data.PDS_Donation_Request_Status__c == 'Reviewed' || data.PDS_Donation_Request_Status__c == 'Need Additional Details')
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
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            name: 'My_Requests__c',
                            url: '/my-requests'
                        },
                    });
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                console.log('Error in cancelRequest-->', { error });
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
}