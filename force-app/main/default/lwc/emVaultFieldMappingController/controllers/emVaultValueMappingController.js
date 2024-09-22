import CONNECTION_FIELD_MAPPING_PARENT_FIELD from '@salesforce/schema/Connection_Value_Mapping_vod__c.Connection_Field_Mapping_vod__c';
import RECORD_TYPE_ID_FIELD from '@salesforce/schema/Connection_Value_Mapping_vod__c.RecordTypeId';
import CRM_VALUE_FIELD from '@salesforce/schema/Connection_Value_Mapping_vod__c.CRM_Value_vod__c';
import CONNECTION_VALUE_FIELD from '@salesforce/schema/Connection_Value_Mapping_vod__c.Connection_Value_vod__c';
import CONNECTION_VALUE_MAPPING_OBJECT from '@salesforce/schema/Connection_Value_Mapping_vod__c';
import {VALUE_MAPPING} from "c/adminMapping";
import EmVaultConnectionValueMappingLookupController from './emVaultConnectionValueMappingLookupController';
import EmVaultCrmValueMappingLookupController from './emVaultCrmValueMappingLookupController';

export default class EmVaultValueMappingController  {
    crmLookupCtrl = new EmVaultCrmValueMappingLookupController();
    connectionLookupCtrl = new EmVaultConnectionValueMappingLookupController();
    mapping = VALUE_MAPPING;

    selectedFieldMapping;

    columns = [
        {
            fieldName: 'crmValueColumn',
            type: 'text',
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' },
            sortable: true,
        },
        {
            fieldName: 'connectionValueColumn',
            type: 'text',
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' },
            sortable: true,
        },
        {
            fieldName: 'actions',
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' },
            fixedWidth: 80,
        },
    ];

    constructSaveBody(crmField, connectionField, recordTypeId) {
        const fields = {};
        fields[CONNECTION_FIELD_MAPPING_PARENT_FIELD.fieldApiName] = this.selectedFieldMapping?.sfId;
        fields[RECORD_TYPE_ID_FIELD.fieldApiName] = recordTypeId;
        fields[CRM_VALUE_FIELD.fieldApiName] = crmField;
        fields[CONNECTION_VALUE_FIELD.fieldApiName] = connectionField;
        return { apiName: CONNECTION_VALUE_MAPPING_OBJECT.objectApiName, fields };
    }

    getColumns(defaultColumns) {
        return this.columns.map(column => ({...column, ...defaultColumns.find(defaultColumn => defaultColumn.fieldName === column.fieldName)}));
    }

    populateMappingModalData (selectedFieldMappingRow, messageMap) {
        this.selectedFieldMapping = selectedFieldMappingRow;
        this.crmLookupCtrl.selectedFieldMapping = selectedFieldMappingRow.crmFieldColumn;
        this.crmLookupCtrl.crmFieldType = selectedFieldMappingRow.crmFieldTypeColumn;
        this.connectionLookupCtrl.selectedFieldMapping = selectedFieldMappingRow.connectionFieldColumn;
        this.connectionLookupCtrl.vaultFieldType = selectedFieldMappingRow.connectionFieldTypeColumn;
        this.crmLookupCtrl.fieldError = messageMap.requiredFieldErrorLabel;
        this.connectionLookupCtrl.disabled = true;
        this.connectionLookupCtrl.fieldError = messageMap.requiredFieldErrorLabel;
        this.connectionLookupCtrl.renderTextField();
    }
}