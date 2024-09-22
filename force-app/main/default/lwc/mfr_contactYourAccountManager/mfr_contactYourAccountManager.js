import { LightningElement, wire} from 'lwc';
import accounticon from '@salesforce/resourceUrl/account';
import phoneicon from '@salesforce/resourceUrl/phone';
// import messageicon from '@salesforce/resourceUrl/message';
import messageicon from '@salesforce/resourceUrl/message';
import phoneiconblack from '@salesforce/resourceUrl/phone1';;
import USER_ID from "@salesforce/user/Id";

import getExecutiveContacts from '@salesforce/apex/MSD_CORE_ProductList.getExecutiveContacts';
import getPrimaryExecutive from '@salesforce/apex/MSD_CORE_ProductList.getPrimaryExecutive';
import { getRecord } from 'lightning/uiRecordApi';
import contactYourAccountManager from '@salesforce/label/c.Mfr_contactYourAccountManager';
import contactYourAccountManager1 from '@salesforce/label/c.Mfr_contactYourAccountManager1';
import accountmanagement from '@salesforce/label/c.AccountManagement';
import accountphone from '@salesforce/label/c.AccountManagementPhone';
import accountmail from '@salesforce/label/c.AccountManagementEmail';
import isguest from '@salesforce/user/isGuest'

export default class Mfr_contactYourAccountManager extends LightningElement {
    AE = {accountmanagement, accountphone, accountmail};
    label={contactYourAccountManager,contactYourAccountManager1};
    accounticon = accounticon;
    phoneicon = phoneicon;
    messageicon = messageicon;
    phoneiconblack=phoneiconblack;

    
    @wire(getRecord, { recordId: '$mRecId'})
    metadatarecord;

    get mTitle() {
        return this.metadatarecord.data.fields.Title__c.value;
    }

    get mSubTitle() {
        return this.metadatarecord.data.fields.Sub_Title__c.value;
    }

    get mPhone() {
        return this.metadatarecord.data.fields.Phone__c.value;
    }

    get mEmail() {
        return this.metadatarecord.data.fields.Email__c.value;
    }
    get isGuestUser() {
        return isguest;
            
        } 
    @wire(getExecutiveContacts)
    wiredExecutiveContacts({ error, data }) {
        if (data) {
            this.exeContacts = data;
            console.log('Contacts'+ JSON.stringify(data));
        } 
        if(error){
            console.log('Error'+ JSON.stringify(error));
        }
    }
    
    @wire(getPrimaryExecutive, {'userId': USER_ID})
    wiredPrimaryExecutive({ error, data }) {
        if (data) {
            this.primaryExecutive = data;
            console.log('Primary Executive'+ JSON.stringify(data));
        } 
        if(error){
            console.log('Error'+ JSON.stringify(error));
        }
    }
}