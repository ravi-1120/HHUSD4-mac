import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';
//Apex
import getApplicationSettings from '@salesforce/apex/PDS_CustomMetadataHandler.getApplicationSettings';
import getPicklistValues from '@salesforce/apex/PDS_Utility.getPicklistValues';
import getDoneeOptions from '@salesforce/apex/PDS_DonationRequestController.getDoneeOptions';
import getProductDetails from '@salesforce/apex/PDS_DonationRequestController.getProductDetails';
import submitDonationRequest from '@salesforce/apex/PDS_DonationRequestController.submitDonationRequest';
import getDonationRequestDetails from '@salesforce/apex/PDS_DonationRequestController.getDonationRequestDetails';
import getProgramAccessCheck from '@salesforce/apex/PDS_DashboardController.getRequestPage';
//Static Resource
import PDSApplicationForm from '@salesforce/resourceUrl/PDSApplicationForm';
//Lables
import draftMessage from '@salesforce/label/c.PDS_Draft_Saved_Msg';
import fwdAgentMsg from '@salesforce/label/c.PDS_FwdAgent';
import indication from '@salesforce/label/c.PDS_Indication';
import donee from '@salesforce/label/c.PDS_Donee';
import dType from '@salesforce/label/c.PDS_DonationType';
import country from '@salesforce/label/c.PDS_Country';
import destination from '@salesforce/label/c.PDS_Destination';
import applicantName from '@salesforce/label/c.PDS_ApplicantName';
import applicantInst from '@salesforce/label/c.PDS_ApplicantInstitution';
import tabletsRequested from '@salesforce/label/c.PDS_TabRequested';
import treatmentApproved from '@salesforce/label/c.PDS_TreatmentApp';
import approvalDate from '@salesforce/label/c.PDS_ApprovalDate';
import taxInclusion from '@salesforce/label/c.PDS_TaxInclusion';
import comments from '@salesforce/label/c.PDS_Comments';
import unit from '@salesforce/label/c.PDS_Unit';
import organization from '@salesforce/label/c.PDS_Organization';
import addressOne from '@salesforce/label/c.PDS_Addressone';
import addressTwo from '@salesforce/label/c.PDS_Addresstwo';
import addressThree from '@salesforce/label/c.PDS_Addressthree';
import stateTxt from '@salesforce/label/c.PDS_State';
import zipCode from '@salesforce/label/c.PDS_ZipCode';
import phoneOne from '@salesforce/label/c.PDS_PhoneOne';
import phoneTwo from '@salesforce/label/c.PDS_PhoneTwo';
import faxNumber from '@salesforce/label/c.PDS_FaxNumber';
import emailAddOne from '@salesforce/label/c.PDS_EmailAddressOne';
import emailAddTwo from '@salesforce/label/c.PDS_EmailAddressTwo';
import emailAddThree from '@salesforce/label/c.PDS_EmailAddressThree';
import product from '@salesforce/label/c.PDS_ProudctLabel';
import forwardingAgent from '@salesforce/label/c.PDS_Forwarding_Agent';
import applicationNumber from '@salesforce/label/c.PDS_ApplicationNumber';
import successContent from '@salesforce/label/c.PDS_SuccessContent';
import formHeading from '@salesforce/label/c.PDS_MDPFormHeading';
import uploadApplication from '@salesforce/label/c.PDS_UploadApplication';
import areaToUpload from '@salesforce/label/c.PDS_FileAreaUpload';
import documentTags from '@salesforce/label/c.PDS_Documenttags';
import uploadNewFile from '@salesforce/label/c.PDS_UploadNewFile';
import uploadApprovalLetter from '@salesforce/label/c.PDS_UploadApprovalLetter';
import consginee from '@salesforce/label/c.PDS_Consignee';
import finalRecepient from '@salesforce/label/c.PDS_FinalRecepient';
import shipNotify from '@salesforce/label/c.PDS_ShipNotify';
import cancelBtn from '@salesforce/label/c.PDS_Cancel_Btn';
import cancelReq from '@salesforce/label/c.PDS_CancelReq';
import goBackPopUp from '@salesforce/label/c.PDS_GoBackPopup';
import sendRequest from '@salesforce/label/c.PDS_SendRequest';
import discardChanges from '@salesforce/label/c.PDS_DiscardChanges';
import saveForLater from '@salesforce/label/c.PDS_SaveforLater';
import back from '@salesforce/label/c.PDS_Back';
import vReq from '@salesforce/label/c.PDS_viewReq';
import toDashboard from '@salesforce/label/c.PDS_BackToDashboard';
import consigneeName from '@salesforce/label/c.PDS_ConsigneeName';
import consigneeErrMsg from '@salesforce/label/c.PDS_ConsigneeErrorMsg';
import edit from '@salesforce/label/c.PDS_Edit';
import finalName from '@salesforce/label/c.PDS_FinalRecepientName';
import finalErrMsg from '@salesforce/label/c.PDS_FinalRecErrorMsg';
import shipName from '@salesforce/label/c.PDS_ShipNotifyName';
import shipErrMsg from '@salesforce/label/c.PDS_ShipNotifyErrorMsg';
import indicationErrMsg from '@salesforce/label/c.PDS_IndicationError';
import applicationNumErrorMsg from '@salesforce/label/c.PDS_ApplicationNumberErrorMsg';
import doneeErrorMsg from '@salesforce/label/c.PDS_DoneeErrorMsg';
import dTypeErrorMsg from '@salesforce/label/c.PDS_DonationTypeErrorMsg';
import countryErrorMsg from '@salesforce/label/c.PDS_CountryErrorMsg';
import applicantNameErrorMsg from '@salesforce/label/c.PDS_ApplicantNameErrorMsg';
import applicantInstErrorMsg from '@salesforce/label/c.PDS_ApplicantInstitutionErrorMsg';
import tabReqErrorMsg from '@salesforce/label/c.PDS_TabRequestedErrorMsg';
import tabReqValidErrorMsg from '@salesforce/label/c.PDS_TabRequestedValidErrorMsg';
import approvalDateErrMsg from '@salesforce/label/c.PDS_ApprovalDateErrorMsg';
import approvalDateValidErrMsg from '@salesforce/label/c.PDS_ApprovalDateValidErrorMsg';
import forwardingAgentErrMsg from '@salesforce/label/c.PDS_Forwarding_AgentErrorMsg';
import additionalInfoErrMsg from '@salesforce/label/c.PDS_AdditionalInfoErrMsg';
import stateErrorMsg from '@salesforce/label/c.PDS_StateErrMsg';
import orgErrorMsg from '@salesforce/label/c.PDS_OrgErrorMsg';
import unitErrorMsg from '@salesforce/label/c.PDS_UnitErrorMsg';
import addErrorMsg from '@salesforce/label/c.PDS_AddressError';
import zipErrorMsg from '@salesforce/label/c.PDS_ZipError';
import phoneErrorMsg from '@salesforce/label/c.PDS_PhoneErrorMsg';
import emailErrorMsg from '@salesforce/label/c.PDS_EmailErrorMsg';
import requestUpdate from '@salesforce/label/c.PDS_RequestUpdated';
import requestSubmitSuccess from '@salesforce/label/c.PDS_RequestSubmitSuccess';


export default class PdsDonationRequest extends NavigationMixin(LightningElement) {

    //MDP Input Form Config
    productObj = { label: product, readonly: true };
    indicationObj = { label: indication, required: true, errorMsg: indicationErrMsg, name: 'indicationValue' };
    applicationNumberObj = { label: applicationNumber, required: true, errorMsg: applicationNumErrorMsg, maxlength: 20, name: 'applicationNumber' };
    doneeObj = { label: donee, required: true, errorMsg: doneeErrorMsg, name: 'doneeName' };
    donationTypeObj = { label: dType, required: true, errorMsg: dTypeErrorMsg, readonly: true, name: 'donationType' };
    countryObj = { label: country, required: true, errorMsg: countryErrorMsg, readonly: true, name: 'drCountry' };
    destinationObj = { label: destination, required: false, errorMsg: '', name: 'destinationValue' };
    applicantNameObj = { label: applicantName, required: true, errorMsg: applicantNameErrorMsg, maxlength: 100, name: 'applicantName' };
    applicantInsObj = { label: applicantInst, required: true, errorMsg: applicantInstErrorMsg, maxlength: 100, name: 'applicantIns' };
    tabletsReqObj = { label: tabletsRequested, required: true, validError: tabReqValidErrorMsg, errorMsg: tabReqErrorMsg, maxlength: 12, name: 'tabletsReq' };
    treatmentsApprovedObj = { label: treatmentApproved, required: false, errorMsg: '', name: 'treatmentsApproved' };
    approvalDateObj = { label: approvalDate, required: true, validError: approvalDateValidErrMsg, errorMsg: approvalDateErrMsg, name: 'approvalDate' };
    taxReportObj = { label: taxInclusion, required: false, errorMsg: '', name: 'taxValue' };
    fwdAgentObj = { label: forwardingAgent, required: false, errorMsg: forwardingAgentErrMsg, maxlength: 255, name: 'fwdAgent' };
    addInfoObj = { label: comments, required: false, errorMsg: additionalInfoErrMsg, maxlength: 2000, name: 'addInfoValue' };
    //Consignee
    csUnitObj = { label: unit, required: false, errorMsg: unitErrorMsg, maxlength: 50, readonly: true, name: 'csUnitValue' };
    csorganizationObj = { label: organization, required: false, errorMsg: orgErrorMsg, maxlength: 100, readonly: true, name: 'csOrgValue' };
    csAddress1 = { label: addressOne, required: false, errorMsg: addErrorMsg, maxlength: 100, readonly: true, name: 'csAdd1Value' };
    csAddress2 = { label: addressTwo, required: false, errorMsg: addErrorMsg, maxlength: 100, readonly: true, name: 'csAdd2Value' };
    csAddress3 = { label: addressThree, required: false, errorMsg: addErrorMsg, maxlength: 100, readonly: true, name: 'csAdd3Value' };
    cscountryObj = { label: country, required: false, errorMsg: countryErrorMsg, name: 'csCountryValue', readonly: true };
    csStateObj = { label: stateTxt, required: false, errorMsg: stateErrorMsg, maxlength: 50, readonly: true, name: 'csStateValue' };
    csZipCodeObj = { label: zipCode, required: false, errorMsg: zipErrorMsg, maxlength: 10, readonly: true, name: 'csZipValue' };
    csPhone1Obj = { label: phoneOne, required: false, errorMsg: phoneErrorMsg, maxlength: 15, readonly: true, name: 'csPhone1Value' };
    csPhone2Obj = { label: phoneTwo, required: false, errorMsg: phoneErrorMsg, maxlength: 15, readonly: true, name: 'csPhone2Value' };
    csFaxObj = { label: faxNumber, required: false, errorMsg: phoneErrorMsg, maxlength: 15, readonly: true, name: 'csFaxValue' };
    csEmail1Obj = { label: emailAddOne, required: false, errorMsg: emailErrorMsg, maxlength: 80, readonly: true, name: 'csEmail1Value' };
    csEmail2Obj = { label: emailAddTwo, required: false, errorMsg: emailErrorMsg, maxlength: 80, readonly: true, name: 'csEmail2Value' };
    csEmail3Obj = { label: emailAddThree, required: false, errorMsg: emailErrorMsg, maxlength: 80, readonly: true, name: 'csEmail3Value' };
    //Final Recipient
    frUnitObj = { label: unit, required: false, errorMsg: unitErrorMsg, maxlength: 50, readonly: true, name: 'frUnitValue' };
    frorganizationObj = { label: organization, required: false, errorMsg: orgErrorMsg, maxlength: 100, readonly: true, name: 'frOrgValue' };
    frAddress1 = { label: addressOne, required: false, errorMsg: addErrorMsg, maxlength: 100, readonly: true, name: 'frAdd1Value' };
    frAddress2 = { label: addressTwo, required: false, errorMsg: addErrorMsg, maxlength: 100, readonly: true, name: 'frAdd2Value' };
    frAddress3 = { label: addressThree, required: false, errorMsg: addErrorMsg, maxlength: 100, readonly: true, name: 'frAdd3Value' };
    frcountryObj = { label: country, required: false, errorMsg: countryErrorMsg, readonly: true, name: 'frCountryValue' };
    frStateObj = { label: stateTxt, required: false, errorMsg: stateErrorMsg, maxlength: 50, readonly: true, name: 'frStateValue' };
    frZipCodeObj = { label: zipCode, required: false, errorMsg: zipErrorMsg, maxlength: 10, readonly: true, name: 'frZipValue' };
    frPhone1Obj = { label: phoneOne, required: false, errorMsg: phoneErrorMsg, maxlength: 15, readonly: true, name: 'frPhone1Value' };
    frPhone2Obj = { label: phoneTwo, required: false, errorMsg: phoneErrorMsg, maxlength: 15, readonly: true, name: 'frPhone2Value' };
    frFaxObj = { label: faxNumber, required: false, errorMsg: phoneErrorMsg, maxlength: 15, readonly: true, name: 'frFaxValue' };
    frEmail1Obj = { label: emailAddOne, required: false, errorMsg: emailErrorMsg, maxlength: 80, readonly: true, name: 'frEmail1Value' };
    frEmail2Obj = { label: emailAddTwo, required: false, errorMsg: emailErrorMsg, maxlength: 80, readonly: true, name: 'frEmail1Value' };
    frEmail3Obj = { label: emailAddThree, required: false, errorMsg: emailErrorMsg, maxlength: 80, readonly: true, name: 'frEmail1Value' };
    //Ship Notify
    snUnitObj = { label: unit, required: false, errorMsg: unitErrorMsg, maxlength: 50, readonly: true, name: 'snUnitValue' };
    snorganizationObj = { label: organization, required: false, errorMsg: orgErrorMsg, maxlength: 100, readonly: true, name: 'snOrgValue' };
    snAddress1 = { label: addressOne, required: false, errorMsg: addErrorMsg, maxlength: 100, readonly: true, name: 'snAdd1Value' };
    snAddress2 = { label: addressTwo, required: false, errorMsg: addErrorMsg, maxlength: 100, readonly: true, name: 'snAdd2Value' };
    snAddress3 = { label: addressThree, required: false, errorMsg: addErrorMsg, maxlength: 100, readonly: true, name: 'snAdd3Value' };
    sncountryObj = { label: country, required: false, errorMsg: countryErrorMsg, readonly: true, name: 'snCountryValue' };
    snStateObj = { label: stateTxt, required: false, errorMsg: stateErrorMsg, maxlength: 50, readonly: true, name: 'snStateValue' };
    snZipCodeObj = { label: zipCode, required: false, errorMsg: zipErrorMsg, maxlength: 10, readonly: true, name: 'snZipValue' };
    snPhone1Obj = { label: phoneOne, required: false, errorMsg: phoneErrorMsg, maxlength: 15, readonly: true, name: 'snPhone1Value' };
    snPhone2Obj = { label: phoneTwo, required: false, errorMsg: phoneErrorMsg, maxlength: 15, readonly: true, name: 'snPhone2Value' };
    snFaxObj = { label: faxNumber, required: false, errorMsg: phoneErrorMsg, maxlength: 15, readonly: true, name: 'snFaxValue' };
    snEmail1Obj = { label: emailAddOne, required: false, errorMsg: emailErrorMsg, maxlength: 80, readonly: true, name: 'snEmail1Value' };
    snEmail2Obj = { label: emailAddTwo, required: false, errorMsg: emailErrorMsg, maxlength: 80, readonly: true, name: 'snEmail2Value' };
    snEmail3Obj = { label: emailAddThree, required: false, errorMsg: emailErrorMsg, maxlength: 80, readonly: true, name: 'snEmail3Value' };


    labels = {
        draftMessage,
        fwdAgentMsg,
        indication,
        donee,
        dType,
        country,
        destination,
        applicantName,
        applicantInst,
        tabletsRequested,
        approvalDate,
        taxInclusion,
        comments,
        unit,
        organization,
        addressOne,
        addressTwo,
        addressThree,
        stateTxt,
        zipCode,
        phoneOne,
        phoneTwo,
        faxNumber,
        emailAddOne,
        emailAddTwo,
        emailAddThree,
        product,
        forwardingAgent,
        applicationNumber,
        successContent,
        formHeading,
        uploadApplication,
        areaToUpload,
        documentTags,
        uploadNewFile,
        uploadApprovalLetter,
        consginee,
        finalRecepient,
        shipNotify,
        cancelBtn,
        cancelReq,
        goBackPopUp,
        sendRequest,
        discardChanges,
        saveForLater,
        back,
        vReq,
        toDashboard,
        consigneeName,
        consigneeErrMsg,
        edit,
        finalName,
        finalErrMsg,
        shipName,
        shipErrMsg,
        indicationErrMsg,
        applicationNumErrorMsg,
        doneeErrorMsg,
        dTypeErrorMsg,
        countryErrorMsg,
        applicantInstErrorMsg,
        tabReqErrorMsg,
        approvalDateErrMsg,
        approvalDateValidErrMsg,
        unitErrorMsg,
        orgErrorMsg,
        addErrorMsg,
        zipErrorMsg,
        phoneErrorMsg,
        stateErrorMsg,
        requestUpdate
    };

    @track donationRequestObj = {};
    @track destinationValue;
    @track taxValue;
    @track indicationValue;
    @track applicationNumber;
    @track doneeName;
    @track doneeId;
    @track donationType;
    @track drCountry;
    @track applicantName;
    @track applicantIns;
    @track tabletsReq = '';
    @track treatmentsApproved;
    @track approvalDate;
    @track fwdAgent;
    @track addInfoValue;
    @track currentDate;
    @track donationApprovalDate;
    @track successScreen = false;
    @track mdpType = false;
    @track mmopType = false;
    @track consigneeValidation = '';
    @track frValidation = '';
    @track snValidation = '';
    @track uploadFileConfirmation = false;
    @track approvalLetterConfirmation = false;
    @track blockEle = true;
    productLineItemIds = [];
    uploadApprovalLetter;
    uploadApplication;
    requestSubmitDate;
    applicationFileURL = 'https://msdlogin--pdsdev--c.sandbox.vf.force.com/apex/PDSMDPApplication';
    allValid;
    appTypeMsg;
    approvalTypeMsg;
    appSettings = [];
    country = [];
    indication = [];
    donationTypes = [];
    destOptions = [];
    fileFormats = [];
    doneeList = [];
    prodList = [];
    showSpinner = false;
    saveForLaterEnable = false;
    goBackPopup = false;
    isEditForm = false;
    @track openConsigneeModal = false;
    @track openShipNotifyModal = false;
    @track openFinalRecModal = false;
    editFinalValue;
    editConsingeeValue;
    editShipValue;
    editRequestData;
    lineItemId;
    lineItemShippingStatus;
    successMsg;
    requestId;
    @track doneeEditName;
    @track scrollPercentage = 0;
    @track prodName;
    @track prodId;
    @track donationReqId;
    //Consignee
    @track csConsigneeValue = '';
    @track csUnitValue;
    @track csOrgValue;
    @track csAdd1Value;
    @track csAdd2Value
    @track csAdd3Value;
    @track csCountryValue;
    @track csStateValue;
    @track csZipValue;
    @track csPhone1Value;
    @track csPhone2Value;
    @track csFaxValue;
    @track csEmail1Value;
    @track csEmail2Value;
    @track csEmail3Value;
    //Final Recipient
    @track frContactValue = '';
    @track frUnitValue;
    @track frOrgValue;
    @track frAdd1Value;
    @track frAdd2Value
    @track frAdd3Value;
    @track frCountryValue;
    @track frStateValue;
    @track frZipValue;
    @track frPhone1Value;
    @track frPhone2Value;
    @track frFaxValue;
    @track frEmail1Value;
    @track frEmail2Value;
    @track frEmail3Value;
    //Ship Notify
    @track snContactValue = '';
    @track snUnitValue;
    @track snOrgValue;
    @track snAdd1Value;
    @track snAdd2Value
    @track snAdd3Value;
    @track snCountryValue;
    @track snStateValue;
    @track snZipValue;
    @track snPhone1Value;
    @track snPhone2Value;
    @track snFaxValue;
    @track snEmail1Value;
    @track snEmail2Value;
    @track snEmail3Value;
    @track contactListData = [];
    @track isSaveforLater = false;


    async connectedCallback() {
        this.showSpinner = true;
        await this.programAccessCheck();
        //let metaName = (this.mdpType) ? 'MDP' : 'MMOP';
        await this.getDoneeOptionsMethod('MDP');
        setTimeout(() => {
            window.scrollTo(0, 0);
        }, 0);

        const today = new Date();
        console.log('Before Async ' + today);
        const month = ('0' + (today.getMonth() + 1)).slice(-2);
        const day = ('0' + today.getDate()).slice(-2);
        const year = today.getFullYear();
        this.currentDate = `${year}-${month}-${day}`;
        this.updateDonationRequestObj();

        const path = window.location.pathname;
        if (path.includes('/edit')) {
            this.isEditForm = true;
            if (this.mdpType) await this.editFormData();
        } else {
            this.saveForLaterEnable = (this.mdpType) ? true : false;
        }

        this.getPicklistOptions('PDS_Contact__c', 'PDS_Shipping_Country__c', 'country');
        this.getPicklistOptions('PDS_Donation_Request__c', 'PDS_Indication__c', 'indication');
        this.getPicklistOptions('PDS_Donation_Request__c', 'PDS_Donation_Type__c', 'donationTypes');
        this.getPicklistOptions('PDS_Donation_Request__c', 'PDS_Destination__c', 'destOptions');
        window.addEventListener('scroll', this.handleScroll.bind(this));
        this.successMsg = (this.isEditForm) ? requestUpdate : requestSubmitSuccess;
    }

    async programAccessCheck() {
        const result = await getProgramAccessCheck({ userid: USER_ID });
        if (result) {
            if (result == 'MDP') {
                this.blockEle = false;
                this.mdpType = true;
                this.showSpinner = false;
                await this.mdpAppSettingsMethod();
            }
            if (result == 'MMOP') {
                this.blockEle = false;
                this.mmopType = true;
                this.showSpinner = false;
            }
        }
    }

    async editFormData() {
        console.log('Edit Form Called');
        this.showSpinner = true;

        const currentUrl = window.location.href;
        const urlParams = new URLSearchParams(new URL(currentUrl).search);
        let donationReqId = urlParams.get('id');
        this.requestId = donationReqId;

        try {
            const result = await getDonationRequestDetails({ donationRequestId: donationReqId });
            if (result) {
                this.editRequestData = result;
                this.saveForLaterEnable = (this.editRequestData.requestStatus == 'Draft') ? true : false;
                this.mapEditData();
                this.showSpinner = false;
            }
            console.log('getDonationRequestDetails Result' + JSON.stringify(result));
        } catch (error) {
            console.error('getDonationRequestDetails Error' + error);
        }
    }

    mapEditData() {
        console.log('mapEditData Called');
        let reqData = this.editRequestData;
        this.donationReqId = reqData.donationReqId;
        this.destinationValue = reqData.destinationValue;
        this.indicationValue = reqData.indicationValue;
        this.taxValue = reqData.taxValue;
        this.applicationNumber = reqData.applicationNumber;
        this.doneeId = reqData.doneeId;
        this.doneeName = reqData.doneeId;
        this.donationType = reqData.donationType;
        this.applicantName = reqData.applicantName;
        this.applicantIns = reqData.applicantIns;
        this.approvalDate = reqData.approvalDate;
        this.fwdAgent = reqData.fwdAgent;
        this.addInfoValue = reqData.addInfoValue;
        this.csConsigneeValue = reqData.consignee;
        this.frContactValue = reqData.finalRecipient;
        this.snContactValue = reqData.shipNotify;
        this.requestStatus = reqData.requestStatus;
        this.shippingStatus = reqData.shippingStatus;
        this.proposalDocName = reqData.proposalDocName;
        this.approvalLetterName = reqData.approvalLetterName;
        if (reqData.productLineItems.length > 0) {
            console.log('reqData Lenght entered' + reqData.productLineItems.length);
            this.lineItemId = reqData.productLineItems[0].lineItemId;
            this.tabletsReq = reqData.productLineItems[0].tabletsReq;
            this.drCountry = reqData.productLineItems[0].country;
            this.lineItemShippingStatus = reqData.productLineItems[0].shippingStatus;
            this.prodId = reqData.productLineItems[0].productId;
        }
        this.treatmentsAppMethod();
        this.updateDonationRequestObj();
        this.uploadFileConfirmation = (this.proposalDocName) ? true : false;
        this.approvalLetterConfirmation = (this.approvalLetterName) ? true : false;
        console.log('Edit Initialization ' + JSON.stringify(this.donationRequestObj));

        if (this.proposalDocName) {
            this.fileTypeError('uploadApplication', false, this.proposalDocName, '');
        }
        if (this.approvalLetterName) {
            this.fileTypeError('uploadApprovalLetter', false, this.approvalLetterName, '');
        }
    }

    handleScroll(event) {
        if (this.saveForLaterEnable) {
            const windowHeight = window.innerHeight;
            const documentHeight = document.documentElement.scrollHeight;
            const scrollTop = window.scrollY;
            this.scrollPercentage = (scrollTop / (documentHeight - windowHeight)) * 100;

            if (this.scrollPercentage >= 98) {
                this.template.querySelector('.floating-button').classList.add('bottom-expanded');
                this.template.querySelector('.floating-button').classList.remove('bottom');
            } else {
                this.template.querySelector('.floating-button').classList.add('bottom');
                this.template.querySelector('.floating-button').classList.remove('bottom-expanded');
            }
        }
    }

    async getPicklistOptions(objectApiName, fieldApiName, fieldName) {
        try {
            const data = await getPicklistValues({ objectApiName: objectApiName, fieldApiName: fieldApiName });
            if (data) this[fieldName] = data;
        } catch (error) {
            console.error('getPicklistOptions ' + { error });
        }
    }

    async getDoneeOptionsMethod(programName) {
        try {
            const data = await getDoneeOptions({ programName: programName });
            if (data) this.doneeList = data;
            console.log('getDoneeOptionsMethod Result' + JSON.stringify(data));
        } catch (error) {
            console.error('getDoneeOptionsMethod ' + { error });
        }
    }

    async getProductDetailsMethod(productId) {
        try {
            const data = await getProductDetails({ productId: productId });
            if (data) {
                this.prodList = data;
                this.prodName = this.prodList[0].label;
                this.prodId = this.prodList[0].value;
            }
            console.log('getProductDetailsMethod Result' + this.prodName);
        } catch (error) {
            console.error('getProductDetailsMethod ' + { error });
        }
    }

    async mdpAppSettingsMethod() {
        console.log('mdpAppSettingsMethod Called');
        try {
            const data = await getApplicationSettings({ flowDeveloperName: 'MDP_Flow_Settings' });
            if (data) {
                this.appSettings = data;
                console.log('appSettingsResult ' + JSON.stringify(data));
                this.drCountry = this.appSettings.pds_default_country__c;
                this.destinationValue = this.appSettings.pds_default_destination__c;
                this.formulaCalc = this.appSettings.pds_treatments_formula__c;
                this.donationType = this.appSettings.pds_donation_type__c;
                this.taxValue = this.appSettings.pds_default_tax_inclusion__c;
                this.getProductDetailsMethod(this.appSettings.pds_product_id__c);
                const domain = window.location.hostname;
                // this.applicationFileURL = domain+'/'+this.appSettings.pds_application_file_url;
                // if (this.appSettings.pds_accepted_file_formats__c != null && this.appSettings.pds_accepted_file_formats__c.contains(',')) {
                const fileFormatsString = this.appSettings.pds_accepted_file_formats__c;
                this.fileFormats = fileFormatsString.split(',');
                // }
                console.log('fileFormats ' + this.fileFormats);
            }
        } catch (error) {
            console.error({ error });
        }
    }

    treatmentsAppMethod() {
        if (this.tabletsReq != undefined && this.tabletsReq != '' && this.tabletsReq >= 0) {
            console.log('treatmentsAppMethod Called' + typeof (this.tabletsReq));
            const formulaWithValues = this.appSettings.pds_treatments_formula__c.replace(/\ba\b/g, this.tabletsReq).replace(/b/g, this.appSettings.pds_mdp_bottle_size__c).replace(/c/g, this.appSettings.pds_treatment_authorization_cap__c);
            console.log('Formula ' + formulaWithValues);
            console.log('Formula ' + this.appSettings.pds_treatments_formula__c);
            // this.treatmentsApproved = Math.round(eval(formulaWithValues));
            try {
                this.treatmentsApproved = Math.round(eval(formulaWithValues));
                console.log(this.treatmentsApproved + 'this.treatmentsApproved');
            } catch (e) {
                console.error('Error evaluating formula: ' + e);
            }
        }
    }

    handleCombobox(event) {
        const { value, name } = event.target;
        this[name] = value;
        event.target.reportValidity();
        console.log('handleCombobox ' + value);
    }

    get taxOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }


    //     handleUserInput(event) {
    //       const { value, name } = event.target;

    //     if (name === 'tabletsReq') {
    //         if(value === ''){
    //             event.target.setCustomValidity('');
    //             this.tabletsReq = '';
    //         }
    //         const trimmedValue = value.replace(/^0+/, '');
    //         const numberValue = Number(trimmedValue);
    //         if (trimmedValue !== '' && numberValue > 0) {
    //             this.tabletsReq = trimmedValue;
    //             console.log('Tablets Req ' + this.tabletsReq);
    //             this.treatmentsAppMethod();
    //             event.target.setCustomValidity('');
    //         }else {
    //             this.tabletsReq = '';
    //             event.target.setCustomValidity('Please enter Valid Value');
    //             event.target.reportValidity();
    //             event.target.setCustomValidity('');
    //         }
    //     } else if (name === 'approvalDate') {
    //         this[name] = value;
    //     } else {
    //         this[name] = value;
    //     }

    //     this.updateDonationRequestObj();
    //     console.log('handleUserInput ' + JSON.stringify(this.donationRequestObj));
    // }
    handleUserInput(event) {
        const { value, name } = event.target;

        if (name === 'tabletsReq') {
            if (value === '') {
                event.target.setCustomValidity('');
                this[name] = '';
            } else {
                const parsedValue = parseInt(value, 10);
                if (isNaN(parsedValue) || parsedValue <= 0) {
                    event.target.setCustomValidity('Please Enter a Valid Value');
                    event.target.reportValidity();
                    this[name] = '';
                    return;
                } else {
                    event.target.setCustomValidity('');
                    this[name] = parsedValue;   
                    event.target.value = parsedValue;
                    this.treatmentsAppMethod();
                }
                this[name] = parsedValue;
                event.target.value = parsedValue;
                event.target.setCustomValidity('');
                 //this.treatmentsAppMethod();
            }
        } else if (name === 'approvalDate') {
            this[name] = value;
        } else {
            this[name] = value;
        }

        this.updateDonationRequestObj();
        console.log('handleUserInput ' + JSON.stringify(this.donationRequestObj));
    }

    // handleUserInput() {
    //         const { value, name } = event.target;
    //         if (name == 'tabletsReq') {
    //             this.tabletsReq = value;
    //             console.log('Tablets Req ' + this.tabletsReq);
    //             this.treatmentsAppMethod();
    //         } else if (name == 'approvalDate') {
    //             // const date = new Date(value);
    //             // this[name] = date.toLocaleDateString('en-US');
    //             this[name] = value;
    //         } else {
    //             this[name] = value;
    //         }

    //         this.updateDonationRequestObj();
    //         console.log('handleUserInput ' + JSON.stringify(this.donationRequestObj));  
    //     }

    handleRadioChange() {
        const { value, name } = event.target;
        this[name] = value;
        this.updateDonationRequestObj();
        console.log('handleRaidoChange ' + JSON.stringify(this.donationRequestObj));
    }

    //Donation Request Object
    updateDonationRequestObj() {
        console.log('FwdAgent ' + this.fwdAgent);
        console.log('FwdAgent Label ' + this.labels.fwdAgentMsg);

        this.donationRequestObj = {
            donationReqId: this.donationReqId,
            recordTypeName: 'MDP',
            destinationValue: this.destinationValue ?? '',
            taxValue: this.taxValue ?? '',
            indicationValue: this.indicationValue ?? '',
            applicationNumber: this.applicationNumber ?? '',
            doneeId: this.doneeName ?? '',
            donationType: this.donationType ?? '',
            applicantName: this.applicantName ?? '',
            applicantIns: this.applicantIns ?? '',
            approvalDate: this.approvalDate ?? '',
            fwdAgent: (this.fwdAgent != undefined) ? this.fwdAgent : this.labels.fwdAgentMsg,
            addInfoValue: this.addInfoValue ?? '',
            consignee: this.csConsigneeValue ?? '',
            finalRecipient: this.frContactValue ?? '',
            shipNotify: this.snContactValue ?? '',
            requestSubmitDate: this.currentDate ?? '',
            requestStatus: this.requestStatus ? this.requestStatus : this.appSettings.pds_request_status__c,
            shippingStatus: this.shippingStatus ? this.shippingStatus : this.appSettings.pds_shipping_status__c,
            approver: this.appSettings.pds_approver_username__c,
            reviewer: this.appSettings.pds_reviewer_username__c,
            updateNotify: 'No Changes',
            // productId: this.prodId ?? '',
            // country: this.drCountry ?? '',
            // tabletsReq: this.tabletsReq ?? 0,
            productLineItems: [
                {
                    lineItemId: this.lineItemId,
                    productId: this.prodId ?? '',
                    country: this.drCountry ?? '',
                    tabletsReq: this.tabletsReq ?? 0,
                    shippingStatus: this.lineItemShippingStatus ? this.lineItemShippingStatus : this.appSettings.pds_shipping_status__c,
                },
            ],
            proposalDocument: this.uploadApplication ?? '',
            proposalDocName: this.proposalDocName ?? '',
            approvalLetter: this.uploadApprovalLetter ?? '',
            approvalLetterName: this.approvalLetterName ?? ''
        };
    }

    async submitRequest() {
        this.allValid = [
            ...this.template.querySelectorAll('lightning-input,lightning-combobox,lightning-textarea,lightning-radio-group'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        this.consigneeValidation = (this.csConsigneeValue != '') ? 'Error' : ' ';
        this.frValidation = (this.csConsigneeValue != '') ? 'Error' : ' ';
        this.snValidation = (this.csConsigneeValue != '') ? 'Error' : ' ';

        console.log('Consignee' + this.csConsigneeValue);
        console.log('Final Recipient' + this.frContactValue);
        if (this.allValid && this.csConsigneeValue != '' && this.frContactValue != '') {
            this.showSpinner = true;
            try {
                this.updateDonationRequestObj();
                this.donationRequestObj.requestStatus = (this.donationRequestObj.requestStatus == 'Draft') ? this.appSettings.pds_request_status__c : this.requestStatus;
                if(this.isSaveforLater == true && this.donationRequestObj.requestStatus != 'Pending'){
                    this.donationRequestObj.requestStatus = 'Pending';
                } 
                this.donationRequestObj.productLineItems[0].lineItemId = null;

                //Check for request changes before submit
                if (this.isEditForm) {
                    let updateNfy = '';
                    if (this.editRequestData.productLineItems[0].tabletsReq != this.donationRequestObj.productLineItems[0].tabletsReq) {
                        updateNfy = 'Change in Quantity' + '\n';
                    }
                    if (this.editRequestData.productLineItems[0].country != this.donationRequestObj.productLineItems[0].country) {
                        updateNfy += 'Change in Country';
                    }
                    this.donationRequestObj.updateNotify = updateNfy;
                }

                // this.productLineItemIds.forEach((productLineItemId, index) => {
                //     console.log('productLineItemId Success ' + productLineItemId);
                //     if (index < this.donationRequestObj.productLineItems.length) {
                //         this.donationRequestObj.productLineItems[index].lineItemId = productLineItemId;
                //     }
                // });
                console.log('submitDonationRequest Request ' + JSON.stringify(this.donationRequestObj));
                const data = await submitDonationRequest({ requestString: JSON.stringify(this.donationRequestObj) });
                if (data) {
                    this.donationReqId = data.donationRequest.Id;
                    this.requestId = data.donationRequest.Id;
                    console.log('submitDonationRequest Response ' + JSON.stringify(data));
                    this.successScreen = true;
                    this.mdpType = false;
                    this.saveForLaterEnable = false;
                    this.showSpinner = false;
                    setTimeout(() => {
                        window.scrollTo(0, 0);
                    }, 0);
                }
            } catch (error) {
                console.error('submitDonationRequest Error ' + JSON.stringify(error));
            }
        } else {
            const firstInvalidInput = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, lightning-radio-group')]
                .find(inputCmp => !inputCmp.checkValidity());
            if (firstInvalidInput) {
                firstInvalidInput.focus();
            }
        }
    }


    handleBackButton() {
        this.goBackPopup = true;
    }

    onPopupCancel() {
        this.goBackPopup = false;
    }

    navigateToDashboard() {
        this.showSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'Home',
                url: '/'
            }
        });
    }

    navigateBackToDashboard() {
        this.showSpinner = true;
        if (this.isEditForm) {
            var name = 'Request_Detail__c';
            var url = '/my-requests/request-detail' + '?id=' + this.donationReqId;
        } else {
            var name = 'Home';
            var url = '/'
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: name,
                url: url
            }
        });
    }

    navigateToRequestDetail() {
        this.showSpinner = true;
        var name = 'Request_Detail__c';
        var url = '/my-requests/request-detail' + '?id=' + this.requestId;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: name,
                url: url
            }
        });
    }


    handleEdit(event) {
        const { name } = event.currentTarget.dataset;

        if (name == 'Consignee') {
            this.editConsingeeValue = {
                id: this.csConsigneeValue,
                name: this.csNameValue,
                street: this.csAdd1Value,
                addone: this.csAdd2Value,
                addtwo: this.csAdd3Value,
                country: this.csCountryValue,
                state: this.csStateValue,
                zipcode: this.csZipValue,
                phone: this.csPhone1Value,
                fax: this.csFaxValue,
                mobile: this.csPhone2Value,
                email: this.csEmail1Value,
                emailtwo: this.csEmail2Value,
                emailthree: this.csEmail3Value,
                unit: this.csUnitValue,
                organization: this.csOrgValue,
                fieldName: name,
                openpopup: true
            };
            this.openConsigneeModal = true;
            console.log('openConsigneeModal' + this.openConsigneeModal);
        } else if (name == 'Final Recipient') {
            this.editFinalValue = {
                id: this.frContactValue,
                name: this.frNameValue,
                street: this.frAdd1Value,
                addone: this.frAdd2Value,
                addtwo: this.frAdd3Value,
                country: this.frCountryValue,
                state: this.frStateValue,
                zipcode: this.frZipValue,
                phone: this.frPhone1Value,
                fax: this.frFaxValue,
                mobile: this.frPhone2Value,
                email: this.frEmail1Value,
                emailtwo: this.frEmail2Value,
                emailthree: this.frEmail3Value,
                unit: this.frUnitValue,
                organization: this.frOrgValue,
                fieldName: name,
                openpopup: true
            };
            this.openFinalRecModal = true;
        } else if (name == 'Ship Notify') {
            this.editShipValue = {
                id: this.snContactValue,
                name: this.snNameValue,
                street: this.snAdd1Value,
                addone: this.snAdd2Value,
                addtwo: this.snAdd3Value,
                country: this.snCountryValue,
                state: this.snStateValue,
                zipcode: this.snZipValue,
                phone: this.snPhone1Value,
                fax: this.snFaxValue,
                mobile: this.snPhone2Value,
                email: this.snEmail1Value,
                emailtwo: this.snEmail2Value,
                emailthree: this.snEmail3Value,
                unit: this.snUnitValue,
                organization: this.snOrgValue,
                fieldName: name,
                openpopup: true
            };
            this.openShipNotifyModal = true;
        }
    }

    handleContactData(event) {
        const { fieldName, id, name, street, addone, addtwo, unit, organization, country, state, zipcode, phone, fax, mobile, email, emailtwo, emailthree } = event.detail;
        this.contactListData = event.detail;
        console.log('this.contactListData' + JSON.stringify(this.contactListData));
        console.log('ContactData ' + JSON.stringify(event.detail));
        if (fieldName == consigneeName) {
            this.csConsigneeValue = id;
            this.csUnitValue = unit;
            this.csNameValue = name;
            this.csOrgValue = organization;
            this.csAdd1Value = street;
            this.csAdd2Value = addone;
            this.csAdd3Value = addtwo;
            this.csCountryValue = country;
            this.csStateValue = state;
            this.csZipValue = zipcode;
            this.csPhone1Value = phone;
            this.csPhone2Value = mobile;
            this.csFaxValue = fax;
            this.csEmail1Value = email;
            this.csEmail2Value = emailtwo;
            this.csEmail3Value = emailthree;
        } else if (fieldName == finalName) {
            this.frContactValue = id;
            this.frUnitValue = unit;
            this.frNameValue = name;
            this.frOrgValue = organization;
            this.frAdd1Value = street;
            this.frAdd2Value = addone;
            this.frAdd3Value = addtwo;
            this.frCountryValue = country;
            this.frStateValue = state;
            this.frZipValue = zipcode;
            this.frPhone1Value = phone;
            this.frPhone2Value = mobile;
            this.frFaxValue = fax;
            this.frEmail1Value = email;
            this.frEmail2Value = emailtwo;
            this.frEmail3Value = emailthree;
        } else if (fieldName == shipName) {
            this.snContactValue = id;
            this.snNameValue = name;
            this.snUnitValue = unit;
            this.snOrgValue = organization;
            this.snAdd1Value = street;
            this.snAdd2Value = addone;
            this.snAdd3Value = addtwo;
            this.snCountryValue = country;
            this.snStateValue = state;
            this.snZipValue = zipcode;
            this.snPhone1Value = phone;
            this.snPhone2Value = mobile;
            this.snFaxValue = fax;
            this.snEmail1Value = email;
            this.snEmail2Value = emailtwo;
            this.snEmail3Value = emailthree;
        }
    }

    fileTypeError(fieldLabel, valid, fileName, msg) {
        const element = this.template.querySelector('.' + fieldLabel);
        if (element && valid) {
            element.style.display = 'block';
            element.style.color = '#9A151C';
            if (fieldLabel == 'uploadApplication') {
                this.appTypeMsg = (msg != '') ? msg : 'Incorrect file type selected';
            } else {
                this.approvalTypeMsg = (msg != '') ? msg : 'Incorrect file type selected';
            }
        } else if (element && !valid) {
            element.style.display = 'block';
            element.style.color = '#000000E0';
            this.fileTypeMsg = fileName;
            if (fieldLabel == 'uploadApplication') {
                this.appTypeMsg = fileName;
            } else {
                this.approvalTypeMsg = fileName;
            }
        }
    }

    handleFileInput(event) {
        try {
            const file = event.target.files[0];
            if (!file) {
                return;
            }

            const fieldLabel = event.target.name;
            const maxSizeInBytes = this.appSettings.pds_maximum_file_size_allowed__c;
            const fileExtension = file.name.split('.').pop().toLowerCase();

            // Check file size
            if (file.size > maxSizeInBytes) {
                this[fieldLabel] = '';
                this.fileTypeError(fieldLabel, true, file.name, 'File size exceeds the maximum allowed size');
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
            if (fieldLabel === 'uploadApplication') {
                this.proposalDocName = file.name;
                this.uploadFileConfirmation = true;
            }
            if (fieldLabel === 'uploadApprovalLetter') {
                this.approvalLetterName = file.name;
                this.approvalLetterConfirmation = true;
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
            this.uploadFileConfirmation = false;
            this.approvalLetterConfirmation = false;
            console.error('File Read Error', e);
        }
    }



    handleDownload() {
        var downloadLink = document.createElement('a');
        var downloadUrl = PDSApplicationForm;
        downloadLink.download = this.appSettings.pds_application_file_name__c;

        downloadLink.href = downloadUrl;
        document.body.appendChild(downloadLink);

        try {
            //window.open(downloadUrl, "_blank");
            downloadLink.click();
        }
        catch (e) {
            console.log(e);
        }
    }

    async saveForLater() {
        this.showSpinner = true;
        console.log('Save for Later');
        try {
            this.updateDonationRequestObj();
            this.donationRequestObj.requestStatus = 'Draft';
            this.donationRequestObj.productLineItems[0].lineItemId = '';
            if (this.donationRequestObj.productLineItems[0].tabletsReq == '') {
                this.donationRequestObj.productLineItems[0].tabletsReq = 0;
            }
            console.log('submitDonationRequest Before ' + JSON.stringify(this.donationRequestObj));
            // this.productLineItemIds.forEach((productLineItemId, index) => {
            //     console.log('productLineItemId Success ' + productLineItemId);
            //     if (index < this.donationRequestObj.productLineItems.length) {
            //         this.donationRequestObj.productLineItems[index].lineItemId = productLineItemId;
            //     }
            // });
            const data = await submitDonationRequest({ requestString: JSON.stringify(this.donationRequestObj) });
            if (data) {
                this.donationReqId = data.donationRequest.Id;
                this.isSaveforLater = (this.donationReqId != null && this.donationReqId != undefined) ? true : false;
                this.productLineItemIds = data.productLineItemIds;
                try {
                    this.showSpinner = false;
                    this.template.querySelector('c-pds-Toast-Message').showToast(this.labels.draftMessage);
                } catch (error) {
                    console.error('Toast Message Error' + error);
                }
                console.log('donationReqId Success ' + this.donationReqId);
                console.log('submitDonationRequest Success ' + JSON.stringify(data));
                console.log('submitDonationRequest Success Final Data ' + JSON.stringify(this.donationRequestObj));
            }
        } catch (error) {
            console.error('Reached submitDonationRequest catch block');
            console.error('submitDonationRequest Error ' + JSON.stringify(error));
            this.showSpinner = true;
        }
    }

    handleMMOPsubmit(event) {
        console.log('handleMMOPSubmt ' + event.detail);
        this.mmopType = false;
        this.successScreen = true;
        this.showSpinner = false;
        this.requestId = event.detail;

        if (this.isEditForm) {
            const currentUrl = window.location.href;
            const urlParams = new URLSearchParams(new URL(currentUrl).search);
            this.requestId = urlParams.get('id');
        }

        setTimeout(() => {
            window.scrollTo(0, 0);
        }, 0);
    }
}