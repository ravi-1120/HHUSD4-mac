import { LightningElement, track, wire, api } from 'lwc';
import getProposal from '@salesforce/apex/PDS_AddProductsController.getProposal';
import getProducts from '@salesforce/apex/PDS_AddProductsController.fetchActiveProducts';
import getFields from '@salesforce/apex/PDS_AddProductsController.getFields';
import createRelatedProducts from '@salesforce/apex/PDS_AddProductsController.createRelatedProducts';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import PDSExternalCSS from '@salesforce/resourceUrl/PDSExternalCSS';
import { loadStyle } from 'lightning/platformResourceLoader';
import addProducts from '@salesforce/label/c.PDS_Proposal_AddProducts';
import next from '@salesforce/label/c.PDS_Next';
import cancel from '@salesforce/label/c.PDS_Cancel';
import save from '@salesforce/label/c.PDS_Save';
import editProducts from '@salesforce/label/c.PDS_Proposal_EditProducts';
import showCount from '@salesforce/label/c.PDS_Proposal_SelectedCount';
import { refreshApex } from '@salesforce/apex';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class PdsAddProducts extends LightningElement {

    @api recordId;

    @track products = [];
    @track selectedProducts = [];
    @track filteredProducts = [];
    @track searchTerm = '';
    @track tableColumns = [];
    @track showSelected = 0;
    @track showProducts = false;
    @track step1 = true;
    @track step2 = false;
    @track nxtDisabled = true;
    @track editColumns = [];
    @track draftValues = [];
    @track draftValues1 = [];

    label = {
        addProducts,
        next,
        cancel,
        editProducts,
        showCount,
        save
    };

    errors = {};
    currentlySelectedData = [];
    relatedProducts = [];
    donationType = '';

    connectedCallback() {
        Promise.all([
            loadStyle(this, PDSExternalCSS)
        ])
        this.loadTableColumns();
        this.loadRelatedColumns();
        this.filteredProducts = '';
        this.products = '';
        console.log('recordId' + this.recordId);
        setTimeout(() => {
            getProposal({ recId: this.recordId })
                .then(result => {
                    this.donationType = result[0].PDS_Donation_Type__c;
                    this.loadProducts();
                })
                .catch(error => {
                    console.error('Error fetching fields', error);
                });
        }, 100);
    }

    loadTableColumns() {
        getFields({ productField: 'Product' })
            .then(result => {
                this.tableColumns = result.map(field => ({
                    label: field.label,
                    fieldName: field.fieldName,
                    type: field.type.toLowerCase()
                }));
            })
            .catch(error => {
                console.error('Error fetching fields', error);
            });
    }

    loadRelatedColumns() {
        getFields({ productField: 'RelatedProduct' })
            .then(result => {
                this.editColumns = result.map(field => ({
                    label: field.label,
                    fieldName: field.fieldName,
                    type: (field.fieldName == 'PDS_Expiration_Date__c') ? 'date-local' : ((field.fieldName == 'PDS_Batch_Number__c') ? 'text' : 'number'),
                    editable: true,
                }));
                console.log('Field Related data: ' + JSON.stringify(this.editColumns));
            })
            .catch(error => {
                console.error('Error fetching fields', error);
            });
    }

    loadProducts() {
        getProducts({ relatedId: this.recordId, donationType: this.donationType })
            .then(result => {
                this.products = result;
                this.filteredProducts = this.products;
                this.productIds = this.products.map(product => product.Id);
                console.log('Products productIds ' + this.productIds);
                console.log('Products Called ' + this.filteredProducts)
            })
            .catch(error => {
                console.error('Error fetching products', error);
            });
    }

    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filterProducts();
    }

    handleRowSelection(event) {
        console.log('120--'+JSON.stringify(event.detail));
        switch (event.detail.config.action) {
            case 'selectAllRows':
                for (let i = 0; i < event.detail.selectedRows.length; i++) {
                    let existingProduct = this.selectedProducts.filter(item => item.Id == event.detail.selectedRows[i].Id);
                    if (existingProduct == '') {
                        this.selectedProducts.push(event.detail.selectedRows[i]);
                    }
                    this.currentlySelectedData.push(event.detail.selectedRows[i]);
                }
                break;
            case 'deselectAllRows':
                this.selectedProducts = [];
                break;
            case 'rowSelect':
                let existingSelectedProduct = event.detail.selectedRows.filter(item => item.Id == event.detail.config.value);
                let existingProduct = this.selectedProducts.filter(item => item.Id == event.detail.config.value);
                if (existingProduct == '' && existingSelectedProduct != '') {
                    this.selectedProducts.push(existingSelectedProduct[0]);
                }
                break;
            case 'rowDeselect':
                this.selectedProducts = this.selectedProducts.filter(item => item.Id !== event.detail.config.value);
            default:
                break;
        }

        this.showSelected = this.selectedProducts.length;
        this.nxtDisabled = (this.selectedProducts.length > 0) ? false : true;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'deleteRow':
                this.deleteRow(row);
                break;
            case 'addRow':
                this.addNewRow(row);
                break;
            default:
                break;
        }
    }

    deleteRow(row) {
        this.selectedProducts = this.selectedProducts.filter(product => product.Id !== row.Id);
    }

    addNewRow(row) {
        const randomId = Math.random() * 10;
        const clickedRowIndex = this.selectedProducts.findIndex(item => item.Id === row.Id);
        const newRowIndex = clickedRowIndex + 1;
        const newRowWithIndexAndId = { ...row, Id: randomId };
        const updatedProducts = this.selectedProducts.map(product => {
            if (product.index >= newRowIndex) {
                return { ...product, index: newRowIndex };
            }
            return product;
        });
        updatedProducts.splice(newRowIndex, 0, newRowWithIndexAndId);
        this.selectedProducts = updatedProducts;
    }

    filterProducts() {
        this.filteredProducts = this.products.filter(product =>
            product.Name.toLowerCase().includes(this.searchTerm)
        );
    }

    handleNext() {
        console.log('this.donationType : ' + this.donationType);
        console.log(JSON.stringify(this.selectedProducts));
        let delField = {
            type: 'button-icon',
            fixedWidth: 50,
            typeAttributes: {
                iconName: 'utility:delete',
                name: 'deleteRow',
                title: 'Delete',
                variant: 'bare'
            }
        };

        let addField = {
            type: 'button-icon',
            fixedWidth: 50,
            typeAttributes: {
                iconName: 'utility:add',
                name: 'addRow',
                title: 'Add',
                variant: 'bare'
            }
        };

        let filteredArray = this.tableColumns.map(item => {
            let { editable, ...newItem } = item;
            return newItem;
        }).filter(item => item.fieldName === 'Name');

        if (this.donationType == 'Excess Product Donation') {
            this.editColumns = [...filteredArray, ...this.editColumns, delField, addField];
        } else {
            this.editColumns = [...filteredArray, ...this.editColumns, delField];
        }

        this.step1 = false;
        this.step2 = true;
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
    handleSave() {
        let updatedFields = this.template.querySelector('lightning-datatable[data-id="editTable"]').draftValues;
        updatedFields.forEach(draft => {
            const existingIndex = this.selectedProducts.findIndex(item => item.Id == draft.Id);
            this.selectedProducts[existingIndex] = { ...this.selectedProducts[existingIndex], ...draft };
        });
        console.log('this.selectedProducts: ' + JSON.stringify(this.selectedProducts));

        let rowError = {};
        let dataError = {};
        let title = 'Error!';
        let messages = ['Available Quantity is required.'];

        this.selectedProducts.forEach(row => {
            // if (!row.hasOwnProperty('PDS_Available_Quantity__c') || row.PDS_Available_Quantity__c === "") {
            //     let fieldNames = ['PDS_Available_Quantity__c'];
            //     rowError[row.Id] = this.showErrorMessage(title, messages, fieldNames);
            //     dataError['rows'] = rowError;
            // }
            if (row.PDS_Expiration_Date__c) {
                let expirationDate = new Date(row.PDS_Expiration_Date__c);
                let currentDate = new Date();
                if (expirationDate < currentDate) {
                    let fieldNames = ['PDS_Expiration_Date__c'];
                    let expirationError = 'Expiration Date cannot be the past date.';
                    if (!rowError.hasOwnProperty(row.Id)) {
                        rowError[row.Id] = this.showErrorMessage(title, [expirationError], fieldNames);
                    } else {
                        rowError[row.Id].messages.push(expirationError);
                        rowError[row.Id].fieldNames.push(...fieldNames);
                    }
                    dataError['rows'] = rowError;
                }
            }
          /*  if (this.donationType === 'Excess Product Donation') {
                if (!row.hasOwnProperty('PDS_Batch_Number__c') || !row.PDS_Batch_Number__c) {
                    let fieldNames = ['PDS_Batch_Number__c'];
                    let batchError = 'Batch Number is required.';
                    if (!rowError.hasOwnProperty(row.Id)) {
                        rowError[row.Id] = this.showErrorMessage(title, [batchError], fieldNames);
                    } else {
                        rowError[row.Id].messages.push(batchError);
                        rowError[row.Id].fieldNames.push(...fieldNames);
                    }
                    dataError['rows'] = rowError;
                }
                if (!row.hasOwnProperty('PDS_Expiration_Date__c') || !row.PDS_Expiration_Date__c) {
                    let fieldNames = ['PDS_Expiration_Date__c'];
                    let batchError = 'Expiration Date is required.';
                    if (!rowError.hasOwnProperty(row.Id)) {
                        rowError[row.Id] = this.showErrorMessage(title, [batchError], fieldNames);
                    } else {
                        rowError[row.Id].messages.push(batchError);
                        rowError[row.Id].fieldNames.push(...fieldNames);
                    }
                    dataError['rows'] = rowError;
                }
            }*/

        });

        this.errors = dataError;
        console.log('dataErrors: ' + JSON.stringify(this.errors));

        if (Object.keys(this.errors).length <= 0) {
            let baseId = "";
            this.selectedProducts.forEach(row => {
                if (!row.Id.includes(".")) {
                    baseId = row.Id;
                }
                row.Id = String(baseId);
                row.RecId = String(this.recordId);
            });

            this.relatedProducts = this.selectedProducts.map(({ Id: PDS_Product__c, PDS_Available_Quantity__c, PDS_Expiration_Date__c, RecId: PDS_Proposal__c, PDS_Batch_Number__c }) => ({ PDS_Product__c, PDS_Available_Quantity__c, PDS_Expiration_Date__c, PDS_Proposal__c, PDS_Batch_Number__c }));
            console.log('selectedProducts: ' + JSON.stringify(this.selectedProducts));
            createRelatedProducts({ records: this.relatedProducts, recId: this.recordId })
                .then(result => {
                    console.log('@@@result: ', result);
                    if (result == 'success') {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Success",
                                message: "Selected products have been added to the proposal.",
                                variant: "success",
                            }),
                        );
                        this.closeAction();
                    } else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: "Error",
                                message: "Duplicate products found with the same batch number.",
                                variant: "error",
                            }),
                        );
                    }
                })
                .catch(error => {
                    console.error('Error Creating Products', error);
                });
            console.log('this.selectedProducts2: ' + JSON.stringify(this.selectedProducts));
        }
    }


    handleCellChange(event) {
        const changedDraftValues = event.detail.draftValues;
        this.draftValues1 = [...this.draftValues1, ...changedDraftValues];
        //this.draftValues = event.detail.draftValues;
        // console.log('draftValues',draftValues); 

        // console.log('Draft values after update:', this.draftValues);
        // if (draftValues && Array.isArray(draftValues)) {
        //     const newErrors = {};

        //     draftValues.forEach(draftValue => {
        //         const rowId = draftValue.Id;

        //         if (!newErrors.rows) {
        //             newErrors.rows = {};
        //         }
        //         if (!newErrors.rows[rowId]) {
        //             newErrors.rows[rowId] = {
        //                 title: 'We found errors.',
        //                 messages: [],
        //                 fieldNames: []
        //             };
        //         }

        //         newErrors.rows[rowId].messages.push('Enter a valid amount.');

        //         newErrors.rows[rowId].fieldNames.push('PDS_Available_Quantity__c');
        //     });

        //     this.errors = newErrors;
        // }
    }
    showErrorMessage(title, messages, fieldNames) {
        let rowError = {};
        rowError['title'] = title;
        rowError['messages'] = messages;
        rowError['fieldNames'] = fieldNames;
        return rowError;
    }

    handleCancel(){
        this.draftValues = [];
    }
}