import { getPageController } from "c/veevaPageControllerFactory";

export default class EmVaultCrmValueMapingLookupController  {
    pageCtrl = getPageController('pageCtrl');
    selected = {};
    required = true;
    
    crmFieldType;
    picklistValues;
    recordTypeValues;
    booleanValues = ['true', 'false'];
    selectedFieldMapping;
    supportedDataType =['RecordType', 'Boolean', 'MultiPicklist', 'Picklist'];


    searchTerm(term) {
        return Promise.resolve(term);
    }

    search() {
        const searchResults = [];
        let searchPool = [];
        switch(this.crmFieldType) {
            case 'Boolean':
                searchPool = this.booleanValues;
                break;
            case 'MultiPicklist':
            case 'Picklist':
                this.picklistValues[this.selectedFieldMapping]?.values.forEach(picklist => searchPool.push(picklist.value));
                break;
            case 'RecordType':
                this.recordTypeValues.forEach(recordType => searchPool.push(recordType.developerName));
                break;
            default:
                break;
        }
        searchPool.forEach(key => {
                searchResults.push({
                    name: key,
                    id: key,
                    icon: 'utility:search',
                });
        });
        return Promise.resolve({records: searchResults});
    }


    getError() {
        return this.fieldError;
    }

    validate() {
        return true;
    }
}