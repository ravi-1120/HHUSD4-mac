import { getPageController } from "c/veevaPageControllerFactory";

export default class EmVaultCrmFieldMappingLookupController  {
    pageCtrl = getPageController('pageCtrl');
    selected = {};
    nameField = '';
    required = true;

    crmObjectFields = {};
    excludeFields = [];
    defaultField = {RecordType: {dataType: 'RecordType'}}
    supportedDataType =['String', 'RecordType', 'Boolean', 'DateTime', 'Date', 'Email', 'MultiPicklist', 'Double', 'Percent', 'Phone', 'Picklist', 'TextArea', 'EncryptedString', 'Url'];

    searchTerm(term) {
        return Promise.resolve(term);
    }

    search() {
        const searchResults = [];
        this.crmObjectFields = {...this.defaultField, ...this.crmObjectFields};
        Object.keys(this.crmObjectFields).forEach(key => {
            const dataType = this.getFieldDataType(key);
            const fieldLength = this.crmObjectFields[key].length ? `(${  this.crmObjectFields[key].length })` : '';
            if(!this.excludeFields.includes(key) && this.supportedDataType.includes(dataType)) {
                searchResults.push({
                    name: `${ key  } (${  dataType  }) ${ fieldLength }`,
                    id: key,
                    type: dataType,
                    icon: 'utility:search',
                });
            }
        });
        return Promise.resolve({records: searchResults});
    }

    getFieldDataType(crmFieldName) {
        this.crmObjectFields = {...this.defaultField, ...this.crmObjectFields};
        return this.crmObjectFields[crmFieldName]?.dataType;
    }

    getMappingType(crmFieldMappingData, messageMap) {
        let mappingType;
        if(crmFieldMappingData.System_Mapping_vod__c) {
            mappingType = crmFieldMappingData.Status_vod__c === 'Inactive_vod' ? `${messageMap.systemMappingLabel  } (${  messageMap.inactiveLabel  })` : messageMap.systemMappingLabel;

        } else {
            mappingType = messageMap.customMappingLabel;
        }
        return mappingType;
    }

    getError() {
        return this.fieldError;
    }

    validate() {
        return true;
    }


}