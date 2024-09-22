import { getPageController } from "c/veevaPageControllerFactory";

export default class EmVaultConnectionValueMapingLookupController  {
    pageCtrl = getPageController('pageCtrl');
    selected = {};
    required = true;

    booleanValues = ['true', 'false'];
    vaultFields;
    lifeCycleStates = [];
    selectedFieldMapping;
    vaultFieldType;
    excludeFields;

    searchTerm(term) {
        return Promise.resolve(term);
    }

    async search() {
        const searchResults = [];
        let searchPool = [];
        switch(this.vaultFieldType) {
            case 'Boolean':
                this.booleanValues.forEach(booleanVal => {
                    if(!this.excludeFields.includes(booleanVal)) {
                        searchPool.push(booleanVal);
                    }
                });
                break;
            case 'MultiPicklist':
            case 'Picklist': {
                const matchedField = this.vaultFields.find(field => field.name === this.selectedFieldMapping);
                matchedField.picklistValues.forEach(picklist => {
                    if (!this.excludeFields.includes(picklist.name)) {
                        searchPool.push(picklist.name);
                    }
                });
                break;
            }
            case 'String':
                this.lifeCycleStates.forEach(lifeCycle => {lifeCycle.states.forEach(state => {
                    if(!this.excludeFields.includes(state.name)) {
                        searchPool.push(state.name);
                    }
                })});
                searchPool = [...new Set(searchPool.sort())];
                break;
            default:
                break;
        }
        searchPool.forEach(field => {
                searchResults.push({
                    name: `${field}`,
                    id: field,
                    icon: 'utility:search',
                });
        });
        return Promise.resolve({records: searchResults});
    }


     renderTextField() {
        this.showTextField = 'String' === this.vaultFieldType && 'status__v' !== this.selectedFieldMapping;
    }

    isDuplicateField(value) {
        return this.excludeFields.includes(value);
    }

    getError() {
        return this.fieldError;
    }

    validate() {
        return true;
    }

}