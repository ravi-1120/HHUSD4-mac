import { getPageController } from "c/veevaPageControllerFactory";

export default class EmVaultConnectionFieldMapingLookupController  {
    pageCtrl = getPageController('pageCtrl');
    selected = {};
    required = true;

    vaultFields = [];
    selectedCrmFieldType;
    excludeFields = [];
    supportedDataType = {
        Email: ['String'],
        String: ['String', 'Boolean', 'DateTime', 'Date', 'Picklist', 'Number', 'URL'],
        Boolean: ['String', 'Boolean', 'Picklist'],
        DateTime: ['DateTime'],
        Date: ['Date'],
        MultiPicklist: ['MultiPicklist'],
        Double: ['Number'],
        Percent: ['Number'],
        Phone: ['Number', 'String', 'ExactMatchString'],
        Picklist: ['Boolean', 'Picklist', 'String'],
        TextArea: ['String', 'Boolean', 'DateTime', 'Date', 'Picklist', 'Number', 'URL'],
        EncryptedString: ['String', 'Boolean', 'DateTime', 'Date', 'Picklist', 'Number', 'URL'],
        Url: ['URL', 'String'],
        RecordType: ['String', 'Boolean', 'Picklist'],
    }

    searchTerm(term) {
        return Promise.resolve(term);
    }

    async search() {
        const searchResults = [];
        this.vaultFields.forEach(field => {
            const maxLength = field.maxLength ? `(${  field.maxLength  })` : '';
            const type = field.repeating ? `Multi${  field.type}` : field.type;
            if(!this.excludeFields.includes(field.name) && this.supportedDataType[this.selectedCrmFieldType].includes(type)) {
                searchResults.push({
                    name: `${field.name} (${type}) ${maxLength}`,
                    id: field.name,
                    type,
                    icon: 'utility:search',
                });
            }
        });
        return Promise.resolve({records: searchResults});
    }

     getFieldDataType(connectionFieldName) {
        const fieldObj = this.vaultFields.find(field => field.name === connectionFieldName);
        let fieldDataType = fieldObj?.type ?? '';
        if (fieldDataType && fieldObj?.repeating) {
            fieldDataType = `Multi${fieldDataType}`;
        }
        return fieldDataType;
     }

    getError() {
        return this.fieldError;
    }

    validate() {
        return true;
    }

    isDuplicateField() {
        return false;
    }

}