import { LightningElement, api, wire, track } from 'lwc';
import getResourceDetails from '@salesforce/apex/MSD_CORE_ResourceController.getResourceDetails';
import getUserProfileName from '@salesforce/apex/HEQ_HeaderController.getUserProfileName';
import FileDetails from '@salesforce/apex/MSD_CORE_ResourceController.FileDetails';

export default class MSD_CORE_ResourceDetail extends LightningElement {
    @track profileName;
    @track resourceDetails = {};
    @track fieldNames = [];
    @track displayedFields = [];
    topicId;
    connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        let topicIdval = urlParams.get('topicId');
        this.topicId = topicIdval.split('-');
        this.getUserData();
        this.fetchFileDetails();
    }

    getUserData() {
        getUserProfileName()
            .then(profileName => {
                this.profileName = profileName;
                console.log('Profile Name:', this.profileName);
                // this.fetchResourceDetails();
            })
            .catch(error => console.error('Error getting profile name:', error));
    }
    fetchFileDetails() {
        FileDetails({ recordId: this.topicId[0] })
        .then(result => {
            console.log('result>>>',result);
            if (result && result.length > 0) {
                const detail = result[0];
                this.topicDetails = {
                    title: detail.Title,
                    topic: this.addspacing(detail.MSD_CORE_Topic__c),
                    therapeuticArea: this.addspacing(detail.MSD_CORE_Therapeutic_Area__c),
                    expirationDate: this.formatDate(detail.MSD_CORE_Expiration_Date__c),
                    fileType: detail.FileType,
                    contentSize: (detail.ContentSize / (1024 * 1024)).toFixed(2) +' MB',
                    Fulfillment: this.addspacing(detail.MSD_CORE_Fulfillment_Method__c),
                    Intendeduse: this.addspacing(detail.MSD_CORE_Intended_use__c),
                    ApprovedRoleForDelivery: this.addspacing(detail.MSD_CORE_Approved_role_for_Delivery__c),
                    Language: this.addspacing(detail.MSD_CORE_Language__c),
                    ReadingGradelevel: this.addspacing(detail.MSD_CORE_Reading_Grade_level__c),
                    Resourcecode: detail.MSD_CORE_Resource_Code__c
                };
                this.prepareDisplayedFields();
            } else {
                this.topicDetails = null;
            }
            console.log('Topic Details:', JSON.stringify(this.topicDetails));
            console.log('formate date::',this.formatDate(result[0].MSD_CORE_Expiration_Date__c),);
        })
        .catch(error => {
            console.error('Error fetching topic details:', error);
        });
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        const day = ('0' + date.getDate()).slice(-2); 
        const month = ('0' + (date.getMonth() + 1)).slice(-2); 
        const year = date.getFullYear();
        return `${month}/${day}/${year}`;
    }

    addspacing(value) {
        if (value) {
            return value.replace(/;/g, '; ');
        }
        return value;
    }

    // fetchResourceDetails() {
    //     const metadataType = 'MSD_CORE_Resource_Configs__mdt';
    //     const fieldNames = ['MSD_CORE_Resource_Fields__c', 'MSD_CORE_Profile__c'];

    //     console.log('Fetching resource details with profile name:', this.profileName);

    //     getResourceDetails({ metadataType, recordApiName: this.profileName, fieldNames })
    //         .then(result => {
    //             console.log('Fetched Resource Details:', JSON.stringify(result));
    //             this.resourceDetails = result;
    //             if (result.MSD_CORE_Resource_Fields__c) {
    //                 this.fieldNames = result.MSD_CORE_Resource_Fields__c.split(',');
    //                 this.prepareDisplayedFields();
    //             }
    //         })
    //         .catch(error => {
    //             console.error('Error fetching resource details:', error);
    //         });
    // }

    prepareDisplayedFields() {
        const fieldMappingforAE = {
            'Expiry Date': 'expirationDate',
            'File Name': 'title',
            'File Size': 'contentSize',
            'File Type': 'fileType',
            'Topics': 'topic',
            'Therapeutic Area': 'therapeuticArea',
            'Fulfilment Method': 'Fulfillment',
            'Intended Use': 'Intendeduse',
            'Approved Role(s) for Delivery': 'ApprovedRoleForDelivery'
        };
        const fieldMappingforCustomer = {
            'Expiry Date': 'expirationDate',
            'File Name': 'title',
            'File Size': 'contentSize',
            'File Type': 'fileType',
            'Topics': 'topic',
            'Therapeutic Area': 'therapeuticArea',
            'Fulfilment Method': 'Fulfillment',
            'Intended Use': 'Intendeduse',
            'Approved Role(s) for Delivery': 'ApprovedRoleForDelivery',
            'Language': 'Language',
            'Reading Grade Level': 'ReadingGradelevel',
            'Resource Code': 'Resourcecode'
        };
        let fieldMapping;
        if (this.profileName == 'HEQ - Account Exe') {
            fieldMapping =  fieldMappingforAE;
        } else {
            fieldMapping =  fieldMappingforCustomer;
        }
        this.displayedFields = Object.entries(fieldMapping).map(([label, fieldName]) => {
            return {
                label,
                value: this.topicDetails[fieldName] || 'N/A'
            };
        });

        console.log('Displayed Fields:', JSON.stringify(this.displayedFields));
    }
}