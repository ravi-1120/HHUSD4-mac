import { LightningElement, wire, api, track } from 'lwc';
import getRecords from '@salesforce/apex/PDS_CustomLookupController.getRecords';
import getRecordById from '@salesforce/apex/PDS_CustomLookupController.getRecordById';
import saveData from '@salesforce/apex/PDS_CustomLookupController.saveContacts';
import getPicklistValue from '@salesforce/apex/PDS_CustomLookupController.getPicklistValue';
import search from '@salesforce/label/c.PDS_Search';
import cancelBtn from '@salesforce/label/c.PDS_Cancel_Btn';
import showResults from '@salesforce/label/c.PDS_Show_Results';
import newContact from '@salesforce/label/c.PDS_New_Contact';
import contactName from '@salesforce/label/c.PDS_Contact_Name';
import unit from '@salesforce/label/c.PDS_Unit';
import organization from '@salesforce/label/c.PDS_Organization';
import addressOne from '@salesforce/label/c.PDS_Addressone';
import addressTwo from '@salesforce/label/c.PDS_Addresstwo';
import addressThree from '@salesforce/label/c.PDS_Addressthree';
import countryTxt from '@salesforce/label/c.PDS_Country';
import stateTxt from '@salesforce/label/c.PDS_State';
import zip from '@salesforce/label/c.PDS_ZipCode';
import phoneOne from '@salesforce/label/c.PDS_PhoneOne';
import phoneTwo from '@salesforce/label/c.PDS_PhoneTwo';
import faxNumber from '@salesforce/label/c.PDS_FaxNumber';
import emailAddOne from '@salesforce/label/c.PDS_EmailAddressOne';
import emailAddTwo from '@salesforce/label/c.PDS_EmailAddressTwo';
import emailAddThree from '@salesforce/label/c.PDS_EmailAddressThree';
import nameErrorMsg from '@salesforce/label/c.PDS_ContactNameErrMsg';
import orgErrorMsg from '@salesforce/label/c.PDS_OrgErrorMsg';
import unitErrorMsg from '@salesforce/label/c.PDS_UnitErrorMsg';
import addErrorMsg from '@salesforce/label/c.PDS_AddressError';
import countryErrorMsg from '@salesforce/label/c.PDS_CountryErrorMsg';
import zipErrorMsg from '@salesforce/label/c.PDS_ZipError';
import phoneErrorMsg from '@salesforce/label/c.PDS_PhoneErrorMsg';
import emailErrorMsg from '@salesforce/label/c.PDS_EmailErrorMsg';
import addTxt from '@salesforce/label/c.PDS_Add';
import editHeaderTxt from '@salesforce/label/c.PDS_EditPopHeader';
import updateBtnTxt from '@salesforce/label/c.PDS_UpdateBtnText';

export default class PdsCustomLookup extends LightningElement {
    @api objectName;
    @api required = 'false';
    @api label;
    @api erromsg;
    //@track searchKey = '';
    @api searchKey;
    @track records;
    @track error;
    @api createRecord = 'false';
    @track showDropdown = false;
    @track contacts = {};
    @track countryoption = [];
    @track editContactData;
    @track isshow = false;
    userName;
    street;
    addone;
    addtwo;
    country;
    state;
    zipcode;
    phone;
    fax;
    mobile;
    email;
    emailtwo;
    emailthree;
    unit;
    organization;
    recid;
    labels = {
        search,
        cancelBtn,
        showResults,
        newContact,
        contactName,
        unit,
        organization,
        addressOne,
        addressTwo,
        addressThree,
        countryTxt,
        stateTxt,
        zip,
        phoneOne,
        phoneTwo,
        faxNumber,
        emailAddOne,
        emailAddTwo,
        emailAddThree,
        nameErrorMsg,
        orgErrorMsg,
        unitErrorMsg,
        addErrorMsg,
        countryErrorMsg,
        zipErrorMsg,
        phoneErrorMsg,
        emailErrorMsg,
        addTxt,
        editHeaderTxt
    };

    // @api openModal() {
    //     console.log('openModal');
    //     this.isshow = true;
    // }
    localConList = {};
    initialLoad = true;
    allValid;
    requiredField;
    inputName;
    openpop;
    @track titleText = newContact;
    @track recordId;
    @track btnText = addTxt;

    @api
    get validMessage() {
        return this.valerrorMsg;
    }
    set validMessage(value) {
        this.checkValidity(value);
    }

    @api
    get recId() {
        return this.recId;
    }
    set recId(value) {
        this.sendEditData(value);
    }

    // @api
    // get openpopup() {
    //     return this.openpopup;
    // }
    // set openpopup(value) {
    //     console.log('openpopup ' + value);
    //     this.isshow = value;
    // }
    @api openpopup = false;

    @api
    get myconlist() {
        return this.myconlist;
    }
    set myconlist(value) {
        console.log('conList ' + JSON.stringify(value));
        this.editContactData = value;
        if (this.editContactData != '' && this.editContactData != undefined) {
            this.titleText = editHeaderTxt;
            this.btnText = updateBtnTxt;
            this.userName = this.editContactData.name ? this.editContactData.name : '';
            this.unit = this.editContactData.unit ? this.editContactData.unit : '';
            this.organization = this.editContactData.organization ? this.editContactData.organization : '';
            this.street = this.editContactData.street ? this.editContactData.street : '';
            this.addone = this.editContactData.addone ? this.editContactData.addone : '';
            this.addtwo = this.editContactData.addtwo ? this.editContactData.addtwo : '';
            this.country = this.editContactData.country ? this.editContactData.country : '';
            this.state = this.editContactData.state ? this.editContactData.state : '';
            this.zipcode = this.editContactData.zipcode ? this.editContactData.zipcode : '';
            this.phone = this.editContactData.phone ? this.editContactData.phone : '';
            console.log('this.phone097865------>'+this.phone);
            this.mobile = this.editContactData.mobile ? this.editContactData.mobile : '';
            this.fax = this.editContactData.fax ? this.editContactData.fax : '';
            this.email = this.editContactData.email ? this.editContactData.email : '';
            this.emailtwo = this.editContactData.emailtwo ? this.editContactData.emailtwo : '';
            this.emailthree = this.editContactData.emailthree ? this.editContactData.emailthree : '';
            this.isshow = this.editContactData.openpopup ? this.editContactData.openpopup : '';
        }
        console.log('this.editContactData' + JSON.stringify(this.editContactData));
    }




    renderedCallback() {
        this.initialLoad = false;
        //console.log('this.openpopup'+this.openpopup); 
        //this.isshow = (this.openpopup == false ? false : true);
        // if(this.myconlist) {
        //     console.log('myconlist data:', JSON.stringify(this.myconlist));
        // }

    }

    checkValidity() {
        console.log('Validity Called');
        var ele = this.template.querySelector('.con-search');
        if (!this.initialLoad && ele != undefined) {
            ele.reportValidity();
        }
    }
    connectedCallback() {
        this.requiredField = (this.required == 'false' ? false : true);
        this.createRecord1 = (this.createRecord == 'false' ? false : true);
        // console.log('this.openpopup'+this.openpopup);   
        // this.isshow = (this.openpopup == false ? false : true);
        getRecords({ searchKey: '', objectName: this.objectName })
            .then(result => {
                this.records = result;
                this.error = undefined;
                console.log('this.records' + JSON.stringify(this.records));
            })
            .catch(error => {
                this.error = error;
                this.records = undefined;
            });
    }
    async sendEditData(value) {
        try {
            console.log('sendEditData ' + value);
            const result = await getRecordById({ pdsContactId: value });
            if (result.length == 0) {
                this.userName = '';
                this.unit = '';
                this.organization = '';
                this.street = '';
                this.addone = '';
                this.addtwo = '';
                this.country = '';
                this.state = '';
                this.zipcode = '';
                this.phone = '';
                this.mobile = '';
                this.fax = '';
                this.email = '';
                this.emailtwo = '';
                this.emailthree = '';
            }
            if (result.length > 0) {
                this.recordId = value;
                console.log('recordId' + this.recordId);
                this.contacts = {};
                this.passContactEventData(result[0]);
                console.log('sendEditData Result ' + JSON.stringify(result));
            }
        } catch (error) {
            console.error('sendEditData Error ' + error);
        }
    }

    handleSearchKeyChange(event) {  
        this.searchKey = event.target.value;
        if (this.searchKey.length > 0 || this.searchKey.length == 0) {
            this.showDropdown = true;
            this.handleSearch();
        }
        else {
            this.showDropdown = false;
            // this.checkValidity();
            // var ele = this.template.querySelector('.con-search');
            // ele.reportValidity();

        }
        if (this.searchKey == '') {
            this.passContactEventData('');
        }
    }


    handleSearch() {
        getRecords({ searchKey: this.searchKey, objectName: this.objectName })
            .then(result => {
                this.records = result;
                this.error = undefined;
                this.showDropdown = true;
                // if (this.searchKey.length <= 0) {
                //     this.showDropdown = true;
                // }
                console.log('this.records' + JSON.stringify(this.records));
            })
            .catch(error => {
                this.error = error;
                this.records = undefined;
            });
    }

    // handleSelectRecord(event) {
    //     const selectedRecordId = event.currentTarget.dataset.id;
    //     //const selectedRecordId = event.target.closest('li').dataset.id;
    //     const selectedRecord = this.records.find(record => record.Id === selectedRecordId);
    //     if (selectedRecord) {
    //         this.searchKey = selectedRecord.Name;
    //         this.userName = selectedRecord.Name;
    //         this.street = selectedRecord.PDS_Shipping_Street__c;
    //         this.addone = selectedRecord.PDS_Address_2__c;
    //         this.addtwo = selectedRecord.PDS_Address_3__c;
    //         this.country = selectedRecord.PDS_Shipping_Country__c;
    //         this.state = selectedRecord.PDS_Shipping_State__c;
    //         this.zipcode = selectedRecord.PDS_Shipping_Postal_Code__c;
    //         this.phone = selectedRecord.PDS_Phone__c;
    //         this.fax = selectedRecord.PDS_Fax_Number__c;
    //         this.mobile = selectedRecord.PDS_Phone_2__c;
    //         this.email = selectedRecord.PDS_Email__c;
    //         this.emailtwo = selectedRecord.PDS_Email_Address_2__c;
    //         this.emailthree = selectedRecord.PDS_Email_Address_3__c;
    //         this.unit = selectedRecord.PDS_Unit__c;
    //         this.organization = selectedRecord.PDS_Organization__c;
    //         console.log('this.street' + this.street);
    //         console.log('this.searchKey' + this.searchKey);
    //         this.showDropdown = false;
    //         // this.checkValidity();             
    //         this.validMessage = (this.searchKey) ? ' ' : this.erromsg;
    //         console.log('validMessage---->'+this.validMessage);
    //         // this.handlevalidate();   
    //         this.passContactEventData(selectedRecord);
    //     } 

    // }

    handleSelectRecord(event) {
        console.log('searchKey---->' + JSON.stringify(this.searchKey));
        console.log('records------>' + JSON.stringify(this.records));
        const selectedRecordId = event.currentTarget.dataset.id;
        console.log('selectedRecordId----->' + JSON.stringify(selectedRecordId));
        //const selectedRecordId = event.target.closest('li').dataset.id;
        const selectedRecord = this.records.find(record => record.Id === selectedRecordId);
        console.log('selectedRecord----->' + JSON.stringify(selectedRecord));

        if (selectedRecord) {
            this.searchKey = selectedRecord.Name;
            console.log('this.searchKey----->' + JSON.stringify(this.searchKey));
            this.userName = selectedRecord.Name;
            console.log('this.searchKey----->' + JSON.stringify(this.userName));
            this.street = selectedRecord.PDS_Shipping_Street__c;
            this.addone = selectedRecord.PDS_Address_2__c;
            this.addtwo = selectedRecord.PDS_Address_3__c;
            this.country = selectedRecord.PDS_Shipping_Country__c;
            this.state = selectedRecord.PDS_Shipping_State__c;
            this.zipcode = selectedRecord.PDS_Shipping_Postal_Code__c;
            //this.phone = selectedRecord.PDS_Phone__c;
            this.phone = this.formatPhoneNumber(selectedRecord.PDS_Phone__c);
            console.log('this.phone------->'+this.phone);
            this.fax = selectedRecord.PDS_Fax_Number__c;
            this.mobile = selectedRecord.PDS_Phone_2__c;
            this.email = selectedRecord.PDS_Email__c;
            this.emailtwo = selectedRecord.PDS_Email_Address_2__c;
            this.emailthree = selectedRecord.PDS_Email_Address_3__c;
            this.unit = selectedRecord.PDS_Unit__c;
            this.organization = selectedRecord.PDS_Organization__c;
            console.log('this.street' + this.street);
            console.log('this.searchKey' + this.searchKey);
            this.showDropdown = false;
            // this.checkValidity();             
            this.validMessage = (this.searchKey) ? ' ' : this.erromsg;
            console.log('validMessage---->' + this.validMessage);
            var ele = this.template.querySelector('.con-search');
            ele.reportValidity('');
            // this.handlevalidate();   
            this.passContactEventData(selectedRecord);
        }
        else {
            var ele = this.template.querySelector('.con-search');
        }

    }

    formatPhoneNumber(value) {
    const cleaned = ('' + value).replace(/\D/g, '');
    const match = cleaned.match(/^(\d{3})(\d{3})(\d{4})$/);

    if (match) {
        return `${match[1]}-${match[2]}-${match[3]}`;
    }

    return value;
    }

    hideDropdown(event) {
        setTimeout(() => {
            this.showDropdown = false;
            var ele = this.template.querySelector('.con-search');
            ele.reportValidity();

        }, 400);
    }

    passContactEventData(selectedRecord) {
        if (selectedRecord == '') {
            const clearSelectedRecord = new CustomEvent('pdscontactdata', {
                detail: {
                    id: '',
                    name: '',
                    street: '',
                    addone: '',
                    addtwo: '',
                    country: '',
                    state: '',
                    zipcode: '',
                    phone: '',
                    fax: '',
                    mobile: '',
                    email: '',
                    emailtwo: '',
                    emailthree: '',
                    unit: '',
                    organization: '',
                    fieldName: this.label ?? ''
                }
            });
            this.dispatchEvent(clearSelectedRecord);
        } else {
            this.searchKey = selectedRecord.Name;
            const selectedRecordEvent = new CustomEvent('pdscontactdata', {
                detail: {
                    id: selectedRecord.Id ?? '',
                    name: selectedRecord.Name ?? '',
                    street: selectedRecord.PDS_Shipping_Street__c ?? '',
                    addone: selectedRecord.PDS_Address_2__c ?? '',
                    addtwo: selectedRecord.PDS_Address_3__c ?? '',
                    country: selectedRecord.PDS_Shipping_Country__c ?? '',
                    state: selectedRecord.PDS_Shipping_State__c ?? '',
                    zipcode: selectedRecord.PDS_Shipping_Postal_Code__c ?? '',
                    //phone: selectedRecord.PDS_Phone__c ?? '',
                    phone: this.formatPhoneNumber(selectedRecord.PDS_Phone__c)?? '',
                    fax: selectedRecord.PDS_Fax_Number__c ?? '',
                    mobile: selectedRecord.PDS_Phone_2__c ?? '',
                    email: selectedRecord.PDS_Email__c ?? '',
                    emailtwo: selectedRecord.PDS_Email_Address_2__c ?? '',
                    emailthree: selectedRecord.PDS_Email_Address_3__c ?? '',
                    unit: selectedRecord.PDS_Unit__c ?? '',
                    organization: selectedRecord.PDS_Organization__c ?? '',
                    fieldName: this.label ?? ''
                }
            });
            this.dispatchEvent(selectedRecordEvent);
        }
    }
    handleOpenModal() {
        this.titleText = newContact;
        this.btnText = addTxt;
        this.recordId = null;
        this.userName = '';
        this.unit = '';
        this.organization = '';
        this.street = '';
        this.addone = '';
        this.addtwo = '';
        this.country = '';
        this.state = '';
        this.zipcode = '';
        this.phone = '';
        this.mobile = '';
        this.fax = '';
        this.email = '';
        this.emailtwo = '';
        this.emailthree = '';
        this.isshow = true;
        console.log('handleOpenModal:::');
    }

    handleCloseModal(event) {
        this.openpopup = false;
        this.isshow = false;
    }
    // hideDropdown(event) {
    //     setTimeout(() => {
    //         this.showDropdown = false;
    //         this.checkValidity();
    //     }, 300);
    // }
    @wire(getPicklistValue, { objectType: 'PDS_Contact__c', selectedField: 'PDS_Shipping_Country__c' })
    WiredgetCountryPicklistValue({ error, data }) {
        if (data) {
            console.log('Result of WiredgetCountryPicklistValue-->', { data });
            let option = [];
            data.forEach(r => {
                option.push({
                    attributes: null,
                    label: r,
                    validFor: '',
                    value: r,
                });
            });
            this.countryoption = option;
        } if (error) {
            console.log('ERROR in WiredgetCountryPicklistValue-->', { error });
        }
    }
    handleChange(event) {
        const fieldName = event.target.dataset.name;
        const fieldValue = event.target.value;
        if (fieldName === 'name') {
            this.userName = fieldValue;
        } else if (fieldName === 'street') {
            this.street = fieldValue;
        } else if (fieldName === 'addone') {
            this.addone = fieldValue;
        }
        else if (fieldName === 'addtwo') {
            this.addtwo = fieldValue;
        }
        else if (fieldName === 'country') {
            this.country = fieldValue;
        }
        else if (fieldName === 'state') {
            this.state = fieldValue;
        }
        else if (fieldName === 'zipcode') {
            this.zipcode = fieldValue;
        }
        // else if (fieldName === 'phone') {
        //     //this.phone = fieldValue;
        //     this.phone = this.formatPhoneNumber(fieldValue);
        //     console.log('handlephone----->'+this.phone);
        // }
        // else if (fieldName === 'mobile') {
        //     this.mobile = fieldValue;
        // }
        else if (fieldName === 'fax') {
            this.fax = fieldValue;
        }
        else if (fieldName === 'email') {
            this.email = fieldValue;
        }
        else if (fieldName === 'emailtwo') {
            this.emailtwo = fieldValue;
        }
        else if (fieldName === 'emailthree') {
            this.emailthree = fieldValue;
        } else if (fieldName === 'unit') {
            this.unit = fieldValue;
        } else if (fieldName === 'organization') {
            this.organization = fieldValue;
        }

        const inputName = event.target.dataset.name;
        let inputValue = event.target.value.replace(/\D/g, ''); 

        if (inputValue.length > 6) {
            inputValue = inputValue.replace(/(\d{3})(\d{3})(\d{0,4})/, '$1-$2-$3');
        } else if (inputValue.length > 3) {
            inputValue = inputValue.replace(/(\d{3})(\d{0,3})/, '$1-$2');
        }

        event.target.value = inputValue;
        
        if (inputName === 'phone') {
            this.phone = inputValue;
        } else if (inputName === 'mobile') {
            this.mobile = inputValue;
        }

    }
    handlenext() {
        this.contacts.name = this.userName ?? '';
        this.contacts.street = this.street ?? '';
        this.contacts.addone = this.addone ?? '';
        this.contacts.addtwo = this.addtwo ?? '';
        this.contacts.country = this.country ?? '';
        this.contacts.state = this.state ?? '';
        this.contacts.zipcode = this.zipcode ?? '';
        this.contacts.phone = this.phone ?? '';
        this.contacts.mobile = this.mobile ?? '';
        this.contacts.fax = this.fax ?? '';
        this.contacts.email = this.email ?? '';
        this.contacts.emailtwo = this.emailtwo ?? '';
        this.contacts.emailthree = this.emailthree ?? '';
        this.contacts.fieldName = this.label ?? '';
        this.contacts.unit = this.unit ?? '',
            this.contacts.organization = this.organization ?? '',
            this.handleValidation();
    }
    handleValidation() {
        // var consigneeValidity = this.template.querySelector('.con-search').checkValidity();
        this.allValid = [
            ...this.template.querySelectorAll('lightning-input:not(.con-search),lightning-combobox'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (this.allValid) {
            this.handleSave();
        }
    }

    handleSave() {
        this.contacts.id = this.recordId;
        console.log('this.contacts Save Before' + JSON.stringify(this.contacts));
        saveData({ recordData: JSON.stringify(this.contacts) })
            .then(result => {
                // Handle success
                console.log('result' + JSON.stringify(result));
                console.log('Data saved successfully');
                this.isshow = false;
                this.recid = result[0].Id;
                this.contacts.id = this.recid;
                this.searchKey = result[0].Name;
                setTimeout(() => {
                    this.checkValidity();
                }, 600);
                this.showDropdown = false;
                const saveddrecordevent = new CustomEvent('pdscontactdata', {
                    detail: this.contacts
                });
                this.dispatchEvent(saveddrecordevent);
                console.log('this.contacts' + JSON.stringify(this.contacts));
            })
            .catch(error => {
                // Handle error
                console.error('Error saving data:', error);
            });
    }

}