import ReferenceController from "c/referenceController";
import MedInqConstant from "c/medInqConstant";
import getParentAccounts from '@salesforce/apex/MedicalInquiryLocationService.getParentAccounts';
import getPrimaryParentId from '@salesforce/apex/MedicalInquiryLocationService.getPrimaryParentId';
import template from './medicalInquiryLocationController.html';

export default class MedicalInquiryLocationController extends ReferenceController {
    initTemplate() {
        this.veevaFieldReference = true;
        this.template = template;
        return this;
    }

    async savedLocation() {
        const locationId = this.data.fields[MedInqConstant.LOCATION].value;
        if (locationId) { 
            const locations = await this.search();
            const location = locations.find(l => l.Id === locationId);
            return location;
        }
        return null;
    }

    async search(term) {
        const searchTerm = term || '';
        let locations = [];
        if (this.data.fields[MedInqConstant.ACCOUNT].value) {
            const primaryParentId = await getPrimaryParentId({accountId: this.data.fields[MedInqConstant.ACCOUNT].value});
            locations = await getParentAccounts({accountId: this.data.fields[MedInqConstant.ACCOUNT].value});
            locations = locations.map(location => this.toSearchRecord(location, primaryParentId));
            locations = locations.filter(searchItem => searchItem.name.toLowerCase().indexOf(searchTerm.toLowerCase()) !== -1);
        }
        return locations;
    }

    toSearchRecord(account, primaryParentId) {
        return {
            Id: account.Id,
            name: account.Name,
            accountIdentifier: account.Account_Identifier_vod__c,
            address: account.Address_vod__r ? this.formatAddress(account.Address_vod__r[0]) : null,
            primaryParent: account.Id === primaryParentId
        }
    }

    formatAddress(address) {
        let addressText = '';
        if (address) {
            addressText = address.Name;
            if (address.Address_line_2_vod__c) {
                addressText += `, ${  address.Address_line_2_vod__c}`;
            }
            if (address.City_vod__c) {
                addressText += `, ${  address.City_vod__c}`;
            }
            if (address.State_vod__c) {
                addressText += `, ${  address.State_vod__c}`;
            }
            if (address.Zip_vod__c) {
                addressText += ` ${  address.Zip_vod__c}`;
            }
        }
        return addressText;
    }
}