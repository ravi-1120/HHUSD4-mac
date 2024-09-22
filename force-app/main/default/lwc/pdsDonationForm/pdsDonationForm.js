import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
//Static Resource
import pdsMagnify from '@salesforce/resourceUrl/pdsMagnify';
//Apex
import getRelatedProducts from '@salesforce/apex/PDS_DashboardController.getRelatedProducts';
import getApplicationSettings from '@salesforce/apex/PDS_CustomMetadataHandler.getApplicationSettings';
import getPicklistValues from '@salesforce/apex/PDS_Utility.getPicklistValues';
import submitDonationRequest from '@salesforce/apex/PDS_DonationRequestController.submitDonationRequest';
import getDoneeOptions from '@salesforce/apex/PDS_DonationRequestController.getDoneeOptions';
import getDonationRequestDetails from '@salesforce/apex/PDS_DonationRequestController.getDonationRequestDetails';
//Labels
import draftMessage from '@salesforce/label/c.PDS_Draft_Saved_Msg';
import saveForLater from '@salesforce/label/c.PDS_SaveforLater';
import cancelReq from '@salesforce/label/c.PDS_CancelReq';
import goBackPopUp from '@salesforce/label/c.PDS_GoBackPopup';
import cancelBtn from '@salesforce/label/c.PDS_Cancel_Btn';
import discardChanges from '@salesforce/label/c.PDS_DiscardChanges';
import sendRequest from '@salesforce/label/c.PDS_SendRequest';
import areaToUpload from '@salesforce/label/c.PDS_FileAreaUpload';
import uploadNewFile from '@salesforce/label/c.PDS_UploadNewFile';
import uploadProposal from '@salesforce/label/c.PDS_UploadProposal';
import downloadProposal from '@salesforce/label/c.PDS_DownloadProposal';
import edit from '@salesforce/label/c.PDS_Edit';
import del from '@salesforce/label/c.PDS_Delete';
import createForm from '@salesforce/label/c.PDS_CreateForm';
import productLimitExceed from '@salesforce/label/c.PDS_ProductSelectionExceeded';
import budgetLimitExceed from '@salesforce/label/c.PDS_BudgetLimitExceed';
import addAnotherCountry from '@salesforce/label/c.PDS_AddCountry';
import expiration from '@salesforce/label/c.PDS_ExpirationDate';
import batchNum from '@salesforce/label/c.PDS_BatchNumber';
import localPartner from '@salesforce/label/c.PDS_LocalPartner';
import selectCountry from '@salesforce/label/c.PDS_SelectCountry';
import quantity from '@salesforce/label/c.PDS_Quantity';
import enterQuantity from '@salesforce/label/c.PDS_EnterQuantity';
import sap from '@salesforce/label/c.PDS_SAP';
import ndc from '@salesforce/label/c.PDS_NDC';
import mmop from '@salesforce/label/c.PDS_MMOP';
import generateForm from '@salesforce/label/c.PDS_GenerateForm';
import searchProducts from '@salesforce/label/c.PDS_SearchforProduct';
import pleaseSpecify from '@salesforce/label/c.PDS_PleaseSpecify';
import country from '@salesforce/label/c.PDS_Country';
import batch from '@salesforce/label/c.PDS_Batch';
import exp from '@salesforce/label/c.PDS_Exp';
import select from '@salesforce/label/c.PDS_Select';
import back from '@salesforce/label/c.PDS_Back';
import quantityExceeds from '@salesforce/label/c.PDS_Quantityexceeds';
import forBatch from '@salesforce/label/c.PDS_QuantityexceedsforBatch';
import reduceQuantEntered from '@salesforce/label/c.PDS_ReduceQuantityEntered';
import donee from '@salesforce/label/c.PDS_Donee';
import dType from '@salesforce/label/c.PDS_DonationType';
import applicantName from '@salesforce/label/c.PDS_ApplicantName';
import ponumber from '@salesforce/label/c.PDS_PO';
import taxInclusion from '@salesforce/label/c.PDS_TaxInclusion';
import doneeErrorMsg from '@salesforce/label/c.PDS_DoneeErrorMsg';
import dTypeErrorMsg from '@salesforce/label/c.PDS_DonationTypeErrorMsg';
import minExpirationDating from '@salesforce/label/c.PDS_MinExpiriationDate';
import minExpirationDatingErrMsg from '@salesforce/label/c.PDS_MinExpiriationDateErrorMsg';
import applicantNameErrorMsg from '@salesforce/label/c.PDS_ApplicantNameErrorMsg';
import poErrorMsg from '@salesforce/label/c.PDS_POErrorMsg';
import qtyValidErrorMsg from '@salesforce/label/c.PDS_QtyValidError';

//Static Resource
import PDSApplicationForm from '@salesforce/resourceUrl/PDSApplicationForm';
import { loadStyle } from 'lightning/platformResourceLoader';
import PDSDashboardcss from '@salesforce/resourceUrl/PDSDashboardcss';


export default class PdsDonationForm extends NavigationMixin(LightningElement) {
    @api dtype;

    @track productOptions = [];
    @track isDropdownOpen = false;
    @track submitDisabled = true;
    @track allProducts;
    doneeList;
    donationTypes = [];
    minExpDating = [];
    fileFormats = [];
    saveForLaterEnable = false;
    showSpinner = false;
    appTypeMsg;
    dropdownMenu = false;
    @track fileConfirmation = false;
    @track goBackPopup = false;

    @track mmopRequest = {};
    appSettings = [];
    donationType;
    proposalId;
    pdsMagnify = pdsMagnify;
    searchKey = '';
    @track noResultsFound = true;
    currentDate;
    mmopType = true;
    requestStatus;
    shippingStatus;
    lineItemShippingStatus;
    prodId;
    lineItemId;
    drCountry;
    tabletsReq;
    localPartner;
    productsPage = false;
    requestPage = false;
    initialLoad = true;
    countryOptions = [];
    totalValue = 0.00;
    @track budgetError = false;
    @track maxProductsError = false;
    @track validationResults = [];
    @track isExcessProduct = false;
    isSpecialReq = false;
    toCompare;
    editMMOPRequestData;

    labels = {
        draftMessage,
        saveForLater,
        cancelReq,
        goBackPopUp,
        cancelBtn,
        discardChanges,
        sendRequest,
        areaToUpload,
        uploadNewFile,
        uploadProposal,
        downloadProposal,
        edit,
        del,
        createForm,
        productLimitExceed,
        budgetLimitExceed,
        addAnotherCountry,
        expiration,
        batchNum,
        localPartner,
        selectCountry,
        quantity,
        enterQuantity,
        sap,
        ndc,
        mmop,
        generateForm,
        searchProducts,
        pleaseSpecify,
        country,
        quantity,
        sap,
        ndc,
        batch,
        exp,
        select,
        back,
        quantityExceeds,
        forBatch,
        reduceQuantEntered,
        donee,
        dType,
        applicantName,
        ponumber,
        taxInclusion,
        doneeErrorMsg,
        dTypeErrorMsg,
        minExpirationDating,
        minExpirationDatingErrMsg,
        poErrorMsg,
        qtyValidErrorMsg
    };

    doneeObj = { label: donee, required: false, errorMsg: doneeErrorMsg, name: 'doneeName' };
    donationTypeObj = { label: dType, required: false, errorMsg: dTypeErrorMsg, readonly: true, name: 'donationType' };
    minExpDateObj = { label: minExpirationDating, required: false, errorMsg: minExpirationDatingErrMsg, readonly: false, name: 'minExpDating' };
    applicantNameObj = { label: applicantName, required: false, errorMsg: applicantNameErrorMsg, maxlength: 100, name: 'applicantName' };
    poNumberObj = { label: ponumber, required: false, errorMsg: poErrorMsg, maxlength: 20, name: 'poNumber' };
    taxReportObj = { label: taxInclusion, required: false, errorMsg: '', name: 'taxValue' };


    async connectedCallback() {
        setTimeout(() => {
            window.scrollTo(0, 0);
        }, 100);
        Promise.all([
            loadStyle(this, PDSDashboardcss)
        ])
        await this.mmopAppSettingsMethod();
        await this.getDoneeOptionsMethod('MMOP');
        this.getPicklistOptions('PDS_Product_Line_Item__c', 'PDS_Country__c', 'countryOptions');
        this.getPicklistOptions('PDS_Donation_Request__c', 'PDS_Donation_Type__c', 'donationTypes');
        this.getPicklistOptions('PDS_Donation_Request__c', 'PDS_Minimum_Expiration_Dating__c', 'minExpDating');

        const today = new Date();
        const month = ('0' + (today.getMonth() + 1)).slice(-2);
        const day = ('0' + today.getDate()).slice(-2);
        const year = today.getFullYear();
        this.currentDate = `${year}-${month}-${day}`;
        const path = window.location.pathname;
        if (path.includes('/edit')) {
            this.isEditForm = true;
            await this.editMMOPData();
        } else {
            //this.saveForLaterEnable = (this.mdpType) ? true : false;
        }
        window.addEventListener('scroll', this.handleScroll.bind(this));
    }

    async editMMOPData() {
        console.log('MMOP Edit Form Called');
        this.showSpinner = true;

        const currentUrl = window.location.href;
        const urlParams = new URLSearchParams(new URL(currentUrl).search);
        let donationReqId = urlParams.get('id');

        try {
            const result = await getDonationRequestDetails({ donationRequestId: donationReqId });
            if (result) {
                this.editMMOPRequestData = result;
                this.donationType = this.editMMOPRequestData.donationType;
                this.isSpecialReq = (this.donationType == 'Disaster Response' || this.donationType == 'Special Request') ? true : false;
                this.mmopRequest.proposalId = result.proposalId;
                this.getDonationProducts();
                this.showSpinner = false;
            }
            console.log('getDonationRequestDetails Result MMOP' + JSON.stringify(result));
        } catch (error) {
            console.error('getDonationRequestDetails Error MMOP' + error);
        }
    }

    mapMMOPEditData() {
        try {
            console.log('mapEditData Called' + JSON.stringify(this.editMMOPRequestData));
            let reqData = this.editMMOPRequestData;
            this.mmopRequest.recordTypeName = 'MMOP',
                this.mmopRequest.donationReqId = reqData.donationReqId;
            this.mmopRequest.taxValue = reqData.taxValue ?? this.appSettings.pds_default_tax_inclusion__c;
            this.mmopRequest.doneeId = reqData.doneeId;
            this.mmopRequest.doneeName = reqData.doneeId;
            this.mmopRequest.donationType = reqData.donationType;
            this.mmopRequest.applicantName = reqData.applicantName;
            this.mmopRequest.requestStatus = reqData.requestStatus;
            this.mmopRequest.shippingStatus = reqData.shippingStatus;
            this.mmopRequest.proposalDocName = reqData.proposalDocName;
            this.proposalDocName = reqData.proposalDocName;
            this.mmopRequest.proposalId = reqData.proposalId;
            this.mmopRequest.minExpDate = reqData.minExpDate;
            this.mmopRequest.poNumber = reqData.poNumber;
            this.mmopRequest.totalValue = reqData.totalValue.toFixed(2);
            this.totalValue = reqData.totalValue.toFixed(2);
            this.mmopRequest.approver = reqData.approver ? reqData.approver : this.appSettings.pds_approver_username__c;
            this.mmopRequest.reviewer = reqData.reviewer ? reqData.reviewer : this.appSettings.pds_reviewer_username__c;

            const productDict = {};
            this.allProducts.forEach(product => {
                productDict[product.productId] = product;
            });
            console.log('Line 160' + JSON.stringify(productDict));

            const productsListMap = {};

            reqData.productLineItems.forEach(item => {
                console.log('Line 165' + JSON.stringify(item));


                const productId = item.productId;
                if (productDict[productId]) {
                    const productDetails = productDict[productId];
                    console.log('Line 169' + JSON.stringify(productDetails));

                    if (!productsListMap[productId]) {
                        productsListMap[productId] = {
                            productId: productDetails.productId,
                            prodName: productDetails.productName,
                            sapCode: productDetails.productSap,
                            availableQty: productDetails.availableQty,
                            isColdChain: productDetails.isColdChain,
                            productPrice: productDetails.productPrice ? parseFloat(productDetails.productPrice).toFixed(2) : productDetails.productPrice,
                            ndcNumber: productDetails.ndcNumber,
                            productLineItems: []
                        };
                    }

                    let formattedExpDate = '';
                    if (item.expDate) {
                        const date = new Date(item.expDate);
                        formattedExpDate = date.toLocaleDateString('en-US');
                    }

                    let totalPrice = '0.00';
                    if (item.tabletsReq && !isNaN(item.tabletsReq)) {
                        totalPrice = (productDetails.productPrice * Number(item.tabletsReq)).toFixed(2);
                    }

                    productsListMap[productId].productLineItems.push({
                        lineItemId: item.lineItemId,
                        productId: productDetails.productId,
                        tabletsReq: item.tabletsReq ?? '',
                        country: item.country ?? '',
                        actualSalePrice: productDetails.productPrice,
                        actualproductPrice: productDetails.actualProductPrice,
                        totalPrice: totalPrice,
                        localPartner: item.localPartner ?? '',
                        batchNumber: item.batchNumber ?? '',
                        expDate: item.expDate ?? '',
                        expDateUS: formattedExpDate ?? '',
                        showDropdown: false,
                        shippingStatus: item.shippingStatus ?? "Pending",
                        batchNumbers: productDetails.batchNumbers ?? undefined
                    });
                }
            });

            this.mmopRequest.productsList = Object.values(productsListMap);
            this.toCompare = JSON.parse(JSON.stringify(this.mmopRequest.productsList));
            console.log('Line 188' + JSON.stringify(this.mmopRequest.productsList));

            this.fileConfirmation = (this.proposalDocName) ? true : false;
            console.log('Doc Name ' + this.mmopRequest.proposalDocName);
            if (this.mmopRequest.proposalDocName) {
                this.fileTypeError('uploadProposal', false, this.mmopRequest.proposalDocName, '');
            }
            this.checkTotalProducts();

            console.log('getDonationRequestDetails Result MMOP Mapped Data' + JSON.stringify(this.mmopRequest));
        } catch (error) {
            console.error('mapData Error ', error.message);
        }
    }

    async getPicklistOptions(objectApiName, fieldApiName, fieldName) {
        try {
            const data = await getPicklistValues({ objectApiName: objectApiName, fieldApiName: fieldApiName });
            if (data) this[fieldName] = data;
            console.log('Picklist Options ' + JSON.stringify(this.donationTypes));
        } catch (error) {
            console.error('getPicklistOptions ' + { error });
        }
    }

    async getDoneeOptionsMethod(programName) {
        console.log('getDoneeOptionsMethod MMOP ');
        try {
            const data = await getDoneeOptions({ programName: programName });
            if (data) this.doneeLists = data;
            console.log('getDoneeOptionsMethod MMOP Result' + JSON.stringify(data));
        } catch (error) {
            console.error('getDoneeOptionsMethod ' + JSON.stringify(error));
        }
    }

    setupMMOPObject() {
        this.mmopRequest = {
            donationReqId: '',
            recordTypeName: 'MMOP',
            requestSubmitDate: new Date(),
            doneeId: '',
            donationType: this.donationType ?? '',
            applicantName: '',
            minExpDate: '',
            poNumber: '',
            proposalDocument: '',
            proposalDocName: '',
            proposalId: this.proposalId,
            totalValue: this.totalValue ?? 0.00,
            taxValue: this.appSettings.pds_default_tax_inclusion__c,
            requestStatus: this.requestStatus ? this.requestStatus : this.appSettings.pds_request_status__c,
            shippingStatus: this.shippingStatus ? this.shippingStatus : this.appSettings.pds_shipping_status__c,
            approver: this.appSettings.pds_approver_username__c,
            reviewer: this.appSettings.pds_reviewer_username__c,
            productsList: [
            ],
        }
        console.log('setupMMOPObject ' + JSON.stringify(this.mmopRequest));
    }

    @wire(CurrentPageReference)
    wiredStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.donationType = currentPageReference.state.name;
            this.proposalId = currentPageReference.state.pid;
            this.mmopRequest.proposalId = this.proposalId;
            this.isExcessProduct = (this.donationType == 'Excess Product Donation') ? true : false;
            this.isSpecialReq = (this.donationType == 'Disaster Response' || this.donationType == 'Special Request') ? true : false;
            if (this.donationType != '') this.getDonationProducts();
        }
        console.log('this.donationType' + JSON.stringify(this.donationType));
    }

    async mmopAppSettingsMethod() {
        console.log('mmopAppSettingsMethod Called');
        try {
            const data = await getApplicationSettings({ flowDeveloperName: 'MMOP_Flow_Settings' });
            if (data) {
                this.appSettings = data;
                console.log('mmopAppSettingsResult ' + JSON.stringify(data));
                this.setupMMOPObject();
                const fileFormatsString = this.appSettings.pds_accepted_file_formats__c;
                this.fileFormats = fileFormatsString?.includes(',') ? fileFormatsString.split(',') : fileFormatsString;
            }
        } catch (error) {
            console.error({ error });
        }
    }

    get taxOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }

    handleChange(event) {
        console.log('Handle Change');
        this.searchKey = event.target.value;
        this.isDropdownOpen = true;
        if (this.searchKey) {
            this.productOptions = this.allProducts
                .filter(product => product.productName.toLowerCase().includes(this.searchKey.toLowerCase()));
        } else {
            this.productOptions = this.allProducts;
        }
        //this.noResultsFound = (this.productOptions.length>0) ? false : true;
    }

    selectedProduct(event) {
        console.log('Selected Product ' + event.currentTarget.dataset.id + ':::' + event.currentTarget.dataset.sap + '::::' + event.currentTarget.dataset.iscold);
        const { id, sap, price, name, ndc, iscold, acs } = event.currentTarget.dataset;
        let excessProduct = '';
        if (id != '') {
            this.noResultsFound = false;
            let productExists = this.mmopRequest.productsList.some(product => product.productId === id);

            if (this.donationType == 'Excess Product Donation') {
                excessProduct = this.productOptions.find(product => product.productId === id);
            }
            if (!productExists) {
                let product = {
                    productId: id ?? '',
                    prodName: name ?? '',
                    sapCode: sap ?? '',
                    isColdChain: (iscold == "true") ? true : false,
                    productPrice: price ? parseFloat(price).toFixed(2) : '',
                    actualProductPrice: acs ? parseFloat(acs).toFixed(2) : '',
                    ndcNumber: ndc ?? '',
                    productLineItems: [{
                        lineItemId: this.generateUniqueId(),
                        productId: id,
                        tabletsReq: '',
                        country: '',
                        totalPrice: '0.00',
                        actualSalePrice: price,
                        actualproductPrice: acs,
                        localPartner: '',
                        batchNumber: '',
                        expDate: '',
                        showDropdown: false,
                        shippingStatus: this.appSettings.pds_shipping_status__c,
                        batchNumbers: excessProduct.batchNumbers ?? undefined
                    }],
                };
                this.mmopRequest.productsList.push(product);
                this.submitDisabled = false;
                this.productsPage = true;
                this.saveForLaterEnable = true;
            }
            this.calculateBudget();
            if(this.mmopRequest.productsList.length > 0){
                this.checkValidCountry();
            }
            console.log('selectedProduct ' + JSON.stringify(this.mmopRequest));
        }
    }

    addCountry(event) {
        try{
            this.checkValidCountry();
            let excessProduct = '';
            const prodId = event.currentTarget.dataset.id;
            const { price, acs } = event.currentTarget.dataset;
            
            const product = this.mmopRequest.productsList.find(prod => prod.productId === prodId);
            console.log('add Country ' + acs + ':::' + product.actualProductPrice + JSON.stringify(product));
            if (this.donationType == 'Excess Product Donation') {
                excessProduct = this.productOptions.find(product => product.productId === prodId);
            }

            if (product) {
                const lineItemId = this.generateUniqueId();
                product.productLineItems.push({
                    lineItemId: lineItemId,
                    productId: prodId,
                    tabletsReq: '',
                    totalPrice: '0.00',
                    actualSalePrice: price,
                    actualproductPrice: acs,
                    country: '',
                    batchNumber: '',
                    expDate: '',
                    localPartner: '',
                    showDropdown: false,
                    shippingStatus: this.appSettings.pds_shipping_status__c,
                    batchNumbers: excessProduct.batchNumbers ?? undefined
                });
            } else {
                console.error(`Product with ID ${prodId} not found in products list.`);
            }
        }catch(e){
            console.error('error' + e.message);
        }
    }

    checkValidCountry() {
        this.allValid = [
            ...this.template.querySelectorAll('lightning-input,lightning-combobox,lightning-textarea,lightning-radio-group'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
    }

    generateUniqueId() {
        return 'lineItem_' + Math.random().toString(36).substr(2, 9);
    }

    handleDeleteLineItem(event) {
        const { id, prodid, del } = event.currentTarget.dataset;
        const productIndex = this.mmopRequest.productsList.findIndex(product => product.productId === prodid);

        if (productIndex !== -1) {
            const product = this.mmopRequest.productsList[productIndex];

            product.productLineItems.forEach((lineItem, index) => {
                if (lineItem.lineItemId === id) {
                    product.productLineItems.splice(index, 1);

                    if (product.productLineItems.length === 0) {
                        this.mmopRequest.productsList.splice(productIndex, 1);
                    }
                }
            });
        } else {
            console.error(`Product with ID ${prodid} not found.`);
        }

        this.checkTotalProducts(del);
        this.calculateBudget();
        this.calculateAvailableQty();
    }


    handleDeleteProduct() {
        const { id } = event.currentTarget.dataset;

        const productIndex = this.mmopRequest.productsList.findIndex(product => product.productId === id);

        if (productIndex !== -1) {
            this.mmopRequest.productsList.splice(productIndex, 1);
        } else {
            console.error(`Product with ID ${id} not found in products list.`);
        }

        this.checkTotalProducts();
        this.calculateBudget();
        this.calculateAvailableQty();
    }

    checkTotalProducts(del) {
        console.log('del ' + del);
        let dele = (del == "true") ? true : false;
        if (this.mmopRequest.productsList.length === 0) {
            this.noResultsFound = true;
            this.requestPage = false;
            this.budgetError = false;
            this.productsPage = false;
            this.saveForLaterEnable = false;
            this.submitDisabled = true;
        } else if (dele || this.isEditForm) {
            this.noResultsFound = false;
            this.requestPage = false;
            this.productsPage = true;
            this.submitDisabled = false;
            this.saveForLaterEnable = (this.editMMOPRequestData.requestStatus == 'Draft') ? true : false;
        }
    }

    getDonationProducts() {
        console.log('donationType '+this.donationType);
        console.log(' ProposalId'+this.proposalId);
        this.proposalId = this.proposalId ?? this.mmopRequest.proposalId;
        getRelatedProducts({donationType:this.donationType, proposalId: this.proposalId })
            .then(result => {
                if (this.donationType == 'Excess Product Donation') {
                    this.excessProductList(result);
                } else {
                    this.productOptions = result;
                    this.allProducts = result;
                    if (this.isEditForm) this.mapMMOPEditData();
                }
                console.log('getRelatedProducts Result ', JSON.stringify(result));
            })
            .catch(error => {
                console.error('getRelatedProducts Error: ', JSON.stringify(error));
            });
    }

    excessProductList(data) {
        let productList = [];
        let processedProducts = new Map();

        data.forEach(product => {
            if (!processedProducts.has(product.productId)) {
                processedProducts.set(product.productId, true);

                let newProduct = {
                    productId: product.productId,
                    productName: product.productName,
                    productPrice: product.productPrice.toFixed(2),
                    actualProductPrice: product.actualProductPrice.toFixed(2),
                    productSap: product.productSap,
                    isColdChain: product.isColdChain,
                    ndcNumber: product.ndcNumber,
                    batchNumbers: [],
                    expDateMap: {},
                    availableQty: {},
                };

                if (product.batchNumber) {
                    newProduct.batchNumbers.push({
                        label: product.batchNumber,
                        value: product.batchNumber
                    });
                    newProduct.expDateMap[product.batchNumber] = product.expDate;
                    newProduct.availableQty[product.batchNumber] = product.availableQty;
                }

                productList.push(newProduct);
            } else {
                let existingProduct = productList.find(item => item.productId === product.productId);

                if (product.batchNumber) {
                    existingProduct.batchNumbers.push({
                        label: product.batchNumber,
                        value: product.batchNumber
                    });
                    existingProduct.expDateMap[product.batchNumber] = product.expDate;
                    existingProduct.availableQty[product.batchNumber] = product.availableQty;
                }
            }
        });
        this.productOptions = productList;
        this.allProducts = productList;
        if (this.isEditForm) this.mapMMOPEditData();
        console.log('Excess Products ' + JSON.stringify(productList));
    }

    handleUserData(event) {
        const { name, value } = event.target;
        const { id, lineitem, price } = event.currentTarget.dataset;

        const product = this.mmopRequest.productsList.find(product => product.productId === id);
        const lineItem = product?.productLineItems.find(item => item.lineItemId === lineitem);

        if (lineItem) {
            if (name === 'tabletsReq') {
                if (value === '') {
                    event.target.setCustomValidity('');
                    lineItem[name] = '';
                } else {
                    const parsedValue = parseInt(value, 10);
                    if (isNaN(parsedValue) || parsedValue === 0) {
                        event.target.setCustomValidity('Please Specify a Valid Value');
                        event.target.reportValidity();
                        return;
                    } else {
                        event.target.setCustomValidity('');
                    }
                    lineItem[name] = parsedValue;

                    const totalPrice = parsedValue * price;
                    const formattedTotalPrice = totalPrice.toFixed(2);
                    lineItem['totalPrice'] = parseFloat(formattedTotalPrice).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });

                    // Update the input field value to reflect the parsed value without leading zeros
                    event.target.value = parsedValue;
                }
            } else if (name == 'batchNumber' && this.donationType == 'Excess Product Donation') {
                lineItem[name] = value;
                this.calculateAvailableQty();
                let exProduct = this.allProducts.find(item => item.productId === id);
                if (exProduct) {
                    const date = new Date(exProduct.expDateMap[value]);
                    lineItem['expDate'] = exProduct.expDateMap[value];
                    lineItem['expUSDate'] = date.toLocaleDateString('en-US') ?? '';
                }
            } else {
                lineItem[name] = value;
            }
        } else {
            console.error(`Line item with ID ${lineitem} not found in products list.`);
        }

        event.target.reportValidity();
    }

    calculateAvailableQty() {
        if (!this.mmopRequest.productsList) {
            console.error("No products found in mmopRequest.");
            return [];
        }
        this.validationResults = [];
        this.allProducts.forEach(product => {
            const calculatedQuantities = {};

            for (const reqProduct of this.mmopRequest.productsList.filter(reqProduct => reqProduct.productId === product.productId)) {
                if (reqProduct.productLineItems) {
                    for (const lineItem of reqProduct.productLineItems) {
                        const { batchNumber, tabletsReq } = lineItem;
                        if (batchNumber && tabletsReq) {
                            calculatedQuantities[batchNumber] = (calculatedQuantities[batchNumber] || 0) + parseInt(tabletsReq);
                        }
                    }
                }
            }

            const productValidationResults = [];
            for (const [batchNumber, calculatedQty] of Object.entries(calculatedQuantities)) {
                const validationQty = product.availableQty[batchNumber];
                const result = validationQty != null ? calculatedQty <= validationQty : true;
                if (!result) {
                    productValidationResults.push({
                        batchNumber,
                        result,
                        validationQty: validationQty || 0
                    });
                } else {
                    const indexToRemove = this.validationResults.findIndex(item => item.batchNumber === batchNumber);
                    if (indexToRemove !== -1) {
                        this.validationResults.splice(indexToRemove, 1);
                    }
                }
            }

            this.validationResults.push(...productValidationResults);
        });

        console.log("Validation Results:", JSON.stringify(this.validationResults));
    }


    get hasValidationResults() {
        return this.validationResults.length > 0;
    }

    handleQuantityBlur() {
        this.calculateBudget();
        this.calculateAvailableQty();
    }

    calculateBudget() {
        console.log('calculateBudget ' + JSON.stringify(this.mmopRequest));

        if (this.isEditForm) {
            this.changeNotification();
        }

        let totalValue = 0.00;
        this.mmopRequest.productsList.forEach(product => {
            product.productLineItems.forEach(lineItem => {
                if (lineItem.totalPrice !== '') {
                    const totalPriceWithoutCommas = lineItem.totalPrice.replace(/,/g, '');
                    totalValue += parseFloat(totalPriceWithoutCommas);
                    totalValue = parseFloat(totalValue.toFixed(2));
                    this.mmopRequest.totalValue = totalValue;
                    this.totalValue = totalValue.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                }
            });
        });

        const numericTotalValue = parseFloat(this.totalValue.replace(/,/g, ''));
        if (numericTotalValue > this.appSettings.pds_mmop_annual_allotment_budget__c && this.mmopRequest.donationType == 'Annual Allotment') {
            this.budgetError = true;
            // this.submitDisabled = true;
        } else {
            this.budgetError = false;
            //  this.submitDisabled = false;
        }

        this.maxProductsError = (((this.mmopRequest?.productsList?.length ?? 0) > this.appSettings.pds_max_products_allowed_aa__c) && this.mmopRequest.donationType == 'Annual Allotment') ? true : false;
    }

    get errorClass() {
        let errorClass;
        errorClass = this.budgetError ? 'error' : '';
        return errorClass;
    }

    hideDropdown() {
        setTimeout(() => {
            this.isDropdownOpen = false;
        }, 300);
    }

    handleFocus() {
        if (this.productOptions.length > 0) {
            this.isDropdownOpen = true;
        }
    }

    // handleSelection(event) {
    //     this.searchKey = event.currentTarget.dataset.value;
    //     this.productOptions = [];
    //     this.isDropdownOpen = false;
    // }

    get getContainerClass() {
        return 'slds-combobox_container';
        //return 'slds-combobox_container slds-has-inline-listbox';
    }

    get getDropdownClass() {
        let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ';
        css += this.isDropdownOpen ? 'slds-is-open' : 'slds-combobox-lookup';
        return css;
    }
    get getListboxClass() {
        return 'slds-listbox slds-listbox_vertical slds-dropdown slds-dropdown_fluid';
    }

    navigateToDashboard() {
        if (this.requestPage) {
            this.showSpinner = true;
            this.requestPage = false;
            this.productsPage = true;
            this.dropdownMenu = false;
            this.showSpinner = false;
            this.closeAllDropdowns();
            setTimeout(() => {
                window.scrollTo(0, 0);
            }, 100);
            return;
        } else {
            if (this.noResultsFound) {
                this.onPopupProceed();
            } else {
                this.goBackPopup = true;
            }
        }
    }

    cancelToDashboard() {
        if (this.noResultsFound) {
            this.onPopupProceed();
        } else {
            this.goBackPopup = true;
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





    handleCombobox(event) {
        const { value, name } = event.target;
        if (name == 'doneeName') {
            this.mmopRequest.doneeId = value;
        } else if (name == 'donationType') {
            this.mmopRequest.donationType = value;
        } else if (name == 'minExpDating') {
            this.mmopRequest.minExpDate = value;
        }
        event.target.reportValidity();
        console.log('handleCombobox ' + value);
    }

    handleRadioChange() {
        const { value, name } = event.target;
        this.mmopRequest.taxValue = value;
    }

    handleUserInput() {
        const { value, name } = event.target;
        if (name == 'applicantName') {
            this.mmopRequest.applicantName = value;
        } else if (name == 'poNumber') {
            this.mmopRequest.poNumber = value;
        }
    }

    async submitRequest() {
        this.allValid = [
            ...this.template.querySelectorAll('lightning-input,lightning-combobox,lightning-textarea,lightning-radio-group'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (this.isEditForm) {
            this.changeNotification();
        }

        if (this.allValid && !this.budgetError && this.validationResults.length <= 0 && !this.maxProductsError && this.mmopRequest?.productsList?.length > 0 && this.mmopRequest.productsList?.some(product => product.productLineItems?.length > 0)) {
            this.showSpinner = true;

            if (this.requestPage == true) {
                try {
                    this.mmopRequest.requestStatus = (this.mmopRequest.requestStatus == 'Draft') ? 'Pending' : this.mmopRequest.requestStatus;
                    if (this.mmopRequest.totalValue > this.appSettings.pds_threshold_value_approval_1__c && this.donationType != 'Annual Allotment') {
                        this.mmopRequest.approver = this.appSettings.pds_approver_2_username__c;
                    } else {
                        this.mmopRequest.approver = this.appSettings.pds_approver_username__c;
                    }
                    let mmopsaveRequest = { ...this.mmopRequest };
                    mmopsaveRequest.productLineItems = mmopsaveRequest.productsList.flatMap(product => product.productLineItems);
                    mmopsaveRequest.productLineItems = mmopsaveRequest.productLineItems.map(productLineItem => {
                        if (productLineItem.lineItemId) {
                            return {
                                ...productLineItem,
                                lineItemId: null
                            };
                        } else {
                            return productLineItem;
                        }
                    });
                    delete mmopsaveRequest.productsList;
                    console.log('submitDonationRequest MMOP Request ' + JSON.stringify(mmopsaveRequest));

                    const data = await submitDonationRequest({ requestString: JSON.stringify(mmopsaveRequest) });
                    if (data) {
                        console.log('submitDonationRequest MMOP Response ' + JSON.stringify(data));
                        this.saveForLaterEnable = false;
                        const mmopsubmitEvent = new CustomEvent('mmopsubmit', {
                            detail: data.donationRequest.Id
                        });
                        this.dispatchEvent(mmopsubmitEvent);
                        this.requestPage = false;
                        this.showSpinner = false;
                    }
                } catch (e) {
                    console.log('submitDonationRequest MMOP ' + JSON.stringify(e));
                }
            } else {
                console.log('Request Submitted');
                this.productsPage = false;
                this.requestPage = true;
                this.showSpinner = false;
                setTimeout(() => {
                    window.scrollTo(0, 0);
                    if (this.mmopRequest.proposalDocName) {
                        this.fileTypeError('uploadProposal', false, this.mmopRequest.proposalDocName, '');
                    }
                }, 100);
            }
        } else {
            const firstInvalidInput = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, lightning-radio-group')]
                .find(inputCmp => !inputCmp.checkValidity());
            if (firstInvalidInput) {
                firstInvalidInput.focus();
            }
            // else {
            //     setTimeout(() => {
            //         window.scrollTo(0, 0);
            //     }, 100);
            // }
        }
    }

    changeNotification() {
        const changes = new Set();

        const currentLineItemsMap = new Map();
        this.toCompare.forEach(product => {
            if (product.productLineItems) {
                product.productLineItems.forEach(lineItem => {
                    currentLineItemsMap.set(lineItem.lineItemId, lineItem);
                });
            }
        });

        this.mmopRequest.productsList.forEach(newProduct => {
            const currentProduct = this.toCompare.find(product => product.productId === newProduct.productId);

            if (!currentProduct) {
                changes.add("Products added");
            } else {
                if (newProduct.productLineItems && newProduct.productLineItems.length > 0) {
                    newProduct.productLineItems.forEach(newLineItem => {
                        const currentLineItem = currentLineItemsMap.get(newLineItem.lineItemId);

                        if (!currentLineItem) {
                            changes.add("Products added");
                        } else {
                            if (Number(currentLineItem.tabletsReq) !== Number(newLineItem.tabletsReq)) {
                                changes.add("Change in Quantity");
                            }
                            if (currentLineItem.country !== newLineItem.country) {
                                changes.add("Change in Country");
                            }
                            if (currentLineItem.localPartner !== newLineItem.localPartner) {
                                changes.add("Change in Local Partner");
                            }
                        }
                    });
                }
            }
        });

        currentLineItemsMap.forEach(currentLineItem => {
            if (!this.mmopRequest.productsList.some(newProduct =>
                newProduct.productLineItems.some(item => item.lineItemId === currentLineItem.lineItemId))) {
                changes.add("Products deleted");
            }
        });

        const mmopProductIds = new Set(this.mmopRequest.productsList.map(product => product.productId));
        this.toCompare.forEach(product => {
            if (!mmopProductIds.has(product.productId)) {
                changes.add("Products deleted");
            }
        });

        this.mmopRequest.updateNotify = changes.size > 0 ? Array.from(changes).join('\n') : 'No Changes';
        console.log('calculateBudget Compare' + JSON.stringify(this.mmopRequest));
    }


    get getClassName() {
        return (this.isSpecialReq) ? 'slds-p-right_large inputField-mb' : '';
    }

    get getPOClassName() {
        return (this.isSpecialReq) ? '' : 'slds-p-right_large inputField-mb';
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

    async saveForLater() {
        this.showSpinner = true;
        console.log('Save for Later');
        try {
            this.mmopRequest.requestStatus = 'Draft';

            if (this.mmopRequest.totalValue > this.appSettings.pds_threshold_value_approval_1__c && this.donationType != 'Annual Allotment') {
                this.mmopRequest.approver = this.appSettings.pds_approver_2_username__c;
            } else {
                this.mmopRequest.approver = this.appSettings.pds_approver_username__c;
            }
            // Replace temoporary Id's if actual Id exists
            let mmopsaveRequest = JSON.parse(JSON.stringify(this.mmopRequest));
            mmopsaveRequest.productLineItems = mmopsaveRequest.productsList.flatMap(product => product.productLineItems);
            mmopsaveRequest.productLineItems = mmopsaveRequest.productLineItems.map(productLineItem => {
                if (productLineItem.lineItemId) {
                    productLineItem.lineItemId = '';
                }
                if (productLineItem.tabletsReq == '') productLineItem.tabletsReq = 0;
                if (productLineItem.actualproductPrice == '') productLineItem.actualproductPrice = 0;
                if (productLineItem.actualSalePrice == '') productLineItem.actualSalePrice = 0;

                return productLineItem;
            });

            delete mmopsaveRequest.productsList;

            console.log('saveForLater Before Save ' + JSON.stringify(mmopsaveRequest));

            const data = await submitDonationRequest({ requestString: JSON.stringify(mmopsaveRequest) });
            if (data) {
                console.log('mmopReq before ' + JSON.stringify(this.mmopRequest));
                this.mmopRequest.donationReqId = data.donationRequest.Id;

                //Map the new Ids to existing lineItems
                // this.mmopRequest.productsList.forEach((product) => {
                //     const productId = product.productId;
                //     const lineItemIds = data.productToLineItemsMap[productId];

                //     if (!lineItemIds) {
                //         console.error(`No line item IDs found for product ${productId}`);
                //         return;
                //     }

                //     product.productLineItems.forEach((lineItem, index) => {
                //         const lineItemId = lineItemIds[index];
                //         if (!lineItemId) {
                //             console.error(`No ID found for line item at index ${index} of product ${productId}`);
                //             return;
                //         }
                //         lineItem.lineItemId = lineItemId;
                //     });
                // });

                console.log('mmopReq ' + JSON.stringify(this.mmopRequest));
                console.log('saveForLater Success ' + JSON.stringify(data));

                try {
                    this.showSpinner = false;
                    this.template.querySelector('c-pds-Toast-Message').showToast(this.labels.draftMessage);
                } catch (error) {
                    console.error('Toast Message Error' + error);
                }
            }
        } catch (error) {
            console.error('saveForLater Error ' + JSON.stringify(error));
            this.showSpinner = true;
        }
    }

    // handleInputFileClick(event) {
    //     if (this.mmopRequest.proposalDocName) {
    //         event.preventDefault();
    //         this.fileConfirmation = true;
    //         return;   
    //     }
    // }

    // get fileConfirmation(){
    //     return (this.mmopRequest.proposalDocName) ? true : false;
    // }

    handleFileInput(event) {
        try {
            const file = event.target.files[0];
            if (!file) {
                return;
            }

            let fieldLabel = event.target.name;
            const maxSizeInBytes = this.appSettings.pds_maximum_file_size_allowed__c;
            if (file.size > maxSizeInBytes) {
                this.mmopRequest.uploadProposal = '';
                this.fileTypeError(fieldLabel, true, file.name, 'File size exceeds the maximum allowed size');
                return;
            }

            console.log('File type:', event.target.name);
            const fileExtension = file.name.split('.').pop().toLowerCase();
            console.log('File type:', fileExtension);
            if (!this.fileFormats.includes(fileExtension)) {
                this.mmopRequest.proposalDocument = '';
                console.error('Invalid file type.');
                this.fileTypeError(fieldLabel, true, file.name, '');
                return;
            }
            if (fieldLabel == 'uploadProposal') {
                this.mmopRequest.proposalDocName = fileExtension;
                this.fileConfirmation = (this.mmopRequest.proposalDocName) ? true : false;
            }

            const reader = new FileReader();
            reader.onload = () => {
                const fileContents = reader.result;
                const base64String = btoa(String.fromCharCode.apply(null, new Uint8Array(fileContents)));
                console.log('File Data ' + base64String);
                this.mmopRequest.proposalDocument = base64String;
                this.fileTypeError(fieldLabel, false, file.name, '');
                console.log(`File Contents for ${fieldLabel}:`, this[fieldLabel]);
            };
            reader.onerror = () => {
                console.error('Error reading file');
                this.fileTypeError(fieldLabel, true, file.name, '');
            };

            reader.readAsArrayBuffer(file);
        } catch (e) {

        }
    }

    fileTypeError(fieldLabel, valid, fileName, msg) {
        console.log('FieldLabel ' + fieldLabel);
        console.log('valid ' + valid);
        console.log('fileName ' + fileName);
        console.log('msg ' + msg);

        const element = this.template.querySelector('.' + fieldLabel);
        if (element && valid) {
            element.style.display = 'block';
            element.style.color = '#9A151C';
            if (fieldLabel == 'uploadProposal') {
                this.appTypeMsg = (msg != '') ? msg : 'Incorrect file type selected';
            } else {
                this.approvalTypeMsg = (msg != '') ? msg : 'Incorrect file type selected';
            }
        } else if (element && !valid) {
            console.log('else if TypeError');
            element.style.display = 'block';
            element.style.color = '#000000E0';
            this.fileTypeMsg = fileName;
            if (fieldLabel == 'uploadProposal') {
                this.appTypeMsg = fileName;
            } else {
                this.approvalTypeMsg = fileName;
            }
        }
    }

    handledropdownMenu(event) {
        const { lineid, id } = event.currentTarget.dataset;

        this.mmopRequest.productsList = this.mmopRequest.productsList.map(product => {
            if (product.productId === id) {
                product.productLineItems = product.productLineItems.map(lineItem => {
                    return lineItem.lineItemId === lineid
                        ? { ...lineItem, showDropdown: !lineItem.showDropdown }
                        : { ...lineItem, showDropdown: false };
                });
            } else {
                product.productLineItems = product.productLineItems.map(lineItem => ({
                    ...lineItem,
                    showDropdown: false
                }));
            }
            return product;
        });
    }

    onPopupCancel() {
        this.goBackPopup = false;
    }

    onPopupProceed() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'Home',
                url: '/'
            }
        });
    }

    closeAllDropdowns() {
        this.mmopRequest.productsList = this.mmopRequest.productsList.map(({ productLineItems, ...rest }) => ({
            ...rest,
            productLineItems: productLineItems.map(lineItem => ({
                ...lineItem,
                showDropdown: false
            }))
        }));
    }
}