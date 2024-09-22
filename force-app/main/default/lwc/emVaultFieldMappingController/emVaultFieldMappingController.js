import CONNECTION_FIELD_MAPPING_OBJECT from '@salesforce/schema/Connection_Field_Mapping_vod__c';
import CONNECTION_PARENT_FIELD from '@salesforce/schema/Connection_Field_Mapping_vod__c.Connection_vod__c';
import CRM_OBJECT_FIELD from '@salesforce/schema/Connection_Field_Mapping_vod__c.CRM_Object_vod__c';
import RECORD_TYPE_ID_FIELD from '@salesforce/schema/Connection_Field_Mapping_vod__c.RecordTypeId';
import CRM_FIELD from '@salesforce/schema/Connection_Field_Mapping_vod__c.CRM_Field_vod__c';
import CONNECTION_FIELD from '@salesforce/schema/Connection_Field_Mapping_vod__c.Connection_Field_vod__c';
import STATUS_FIELD from '@salesforce/schema/Connection_Field_Mapping_vod__c.Status_vod__c';
import SYSTEM_MAPPING from '@salesforce/schema/Connection_Field_Mapping_vod__c.System_Mapping_vod__c';
import getSobjectRecordTypeInfo from '@salesforce/apex/RecordTypeInfoVod.getSobjectRecordTypeInfo';
import { FIELD_MAPPING } from 'c/adminMapping';
import EM_CATALOG_OBJECT from '@salesforce/schema/EM_Catalog_vod__c';
import AdminDataService from "c/adminDataService";
import {getService} from 'c/veevaServiceFactory';
import EmVaultValueMappingController from './controllers/emVaultValueMappingController';
import EmVaultConnectionFieldMappingLookupController from './controllers/emVaultConnectionFieldMappingLookupController';
import EmVaultCrmFieldMappingLookupController from './controllers/emVaultCrmFieldMappingLookupController';

export default class EmVaultFieldMappingController  {
    crmLookupCtrl = new EmVaultCrmFieldMappingLookupController();
    connectionLookupCtrl = new EmVaultConnectionFieldMappingLookupController();
    valueMappingCtrl = new EmVaultValueMappingController();
    mapping = FIELD_MAPPING;

    messageMap = {};
    vaultFieldMap = new Map();
    vaultLifeCycleStateMap = new Map();
    selectedConnection;
    blacklistedCrmFields = ['Id', 'Connection_vod__c'];
    adminMapppingDataSvc = new AdminDataService(getService('sessionSvc'), getService('messageSvc'));

    constructSaveBody(crmField, connectionField, recordTypeId) {
        const fields = {};
        fields[CONNECTION_PARENT_FIELD.fieldApiName] = this.selectedConnection?.sfId;
        fields[RECORD_TYPE_ID_FIELD.fieldApiName] = recordTypeId;
        fields[CRM_OBJECT_FIELD.fieldApiName] = 'EM_Catalog_vod';
        fields[CRM_FIELD.fieldApiName] = crmField;
        fields[CONNECTION_FIELD.fieldApiName] = connectionField;
        fields[STATUS_FIELD.fieldApiName] = 'Active_vod';
        fields[SYSTEM_MAPPING.fieldApiName] = false;
        return { apiName: CONNECTION_FIELD_MAPPING_OBJECT.objectApiName, fields };
    }

    getColumns(defaultColumns, messageMap) {
        this.messageMap = messageMap;
        const columns = [
            {
                fieldName: 'crmFieldColumn',
                type: 'text',
                hideDefaultActions: true,
                cellAttributes: { 
                    class: {
                        fieldName: `format`
                    },
                    alignment: 'left' 
                },
                sortable: true,
            },
            {
                fieldName: 'crmFieldTypeColumn',
                type: 'text',
                hideDefaultActions: true,
                cellAttributes: { 
                    class: {
                        fieldName: `format`
                    },
                    alignment: 'left' 
                },
                sortable: true,
                initialWidth: 80,
            },
            {
                fieldName: 'connectionFieldColumn',
                type: 'text',
                hideDefaultActions: true,
                cellAttributes: { 
                    class: {
                        fieldName: `format`
                    },
                    alignment: 'left' 
                },
                sortable: true,
            },
            {
                fieldName: 'connectionFieldTypeColumn',
                type: 'text',
                hideDefaultActions: true,
                cellAttributes: { 
                    class: {
                        fieldName: `format`
                    },
                    alignment: 'left' 
                },
                sortable: true,
                initialWidth: 80,
            },
            {
                fieldName: 'mappingTypeColumn',
                type: 'text',
                hideDefaultActions: true,
                cellAttributes: { 
                    class: {
                        fieldName: `format`
                    },
                    alignment: 'left' 
                },
                sortable: true,
            },
            {
                fieldName: 'actionColumn',
                hideDefaultActions: true,
                cellAttributes: { 
                    class: {
                        fieldName: `format`
                    },
                    alignment: 'left' 
                },
                type: 'button',
                typeAttributes: {label: {fieldName: 'actionColumn'}, name: 'viewValueMapping', variant: 'base'}
            },
            {
                type: 'action',
                typeAttributes: { rowActions: this.getRowActions },
            },
        ];
        return columns.map(column => ({...column, ...defaultColumns.find(defaultColumn => defaultColumn.fieldName === column.fieldName)}));
    }

    getRowActions = (row, doneCallback) => {
        const actions = [];
            if (!row.isSystemType) {
                actions.push({
                    'label': this.messageMap.deleteMappingButtonLabel,
                    'name': 'deleteFieldMapping'
                });
            } else if('Active_vod' === row.isActive){
                actions.push({
                    'label': this.messageMap.inactivateMappingLabel,
                    'name': 'inactivate'
                });
            } else {
                actions.push({
                    'label': this.messageMap.activateMappingLabel,
                    'name': 'activate'
                });
            }
            doneCallback(actions);
    }

    findCrmObjectInfo (data) {
        const crmObjectInfo = data.results.find(element => element.result.apiName === EM_CATALOG_OBJECT.objectApiName);
        this.crmLookupCtrl.crmObjectFields = crmObjectInfo.result.fields;
        return crmObjectInfo.result;
    }

    populateMappingModalData (selectedRowConnection, messageMap) {
        this.selectedConnection = selectedRowConnection;
        this.crmLookupCtrl.fieldError = messageMap.requiredFieldErrorLabel;
        this.connectionLookupCtrl.disabled = true;
        this.connectionLookupCtrl.fieldError = messageMap.requiredFieldErrorLabel;
    }

    async fetchConnectionFieldMappingData(systemId) {
        if(!this.vaultFieldMap.has(systemId)) {
            const vaultFields = await this.adminMapppingDataSvc.retrieveVaultFieldsAndStates('EM', systemId, false);
            if(vaultFields && vaultFields.data && vaultFields.data.fields) {
                this.vaultFieldMap.set(systemId, vaultFields.data.fields);
                this.connectionLookupCtrl.vaultFields = vaultFields.data.fields;
            } else {
                this.connectionLookupCtrl.vaultFields = [];
            }
        } else {
            this.connectionLookupCtrl.vaultFields = this.vaultFieldMap.get(systemId);
        }
    }


    populateMappedFields(mappedCrmFields, mappedConnectionFields) {
        this.crmLookupCtrl.excludeFields = [... this.blacklistedCrmFields, ...mappedCrmFields];
        this.connectionLookupCtrl.excludeFields = mappedConnectionFields;
    }

    populateMappedValues(mappedVaultValues) {
        this.valueMappingCtrl.connectionLookupCtrl.excludeFields = mappedVaultValues;
    }

    getCrmFieldType(crmField) {
        return this.crmLookupCtrl.getFieldDataType(crmField);
    }

    getConnectionFieldType(connectionField) {
        return this.connectionLookupCtrl.getFieldDataType(connectionField);
    }

    getMappingType(data, messageMap) {
        return this.crmLookupCtrl.getMappingType(data, messageMap);
    }

    viewMappingText(crmFieldType, viewMappingText) {
        return this.valueMappingCtrl?.crmLookupCtrl?.supportedDataType?.includes(crmFieldType) ? viewMappingText : '';
    }

    async populateValueMappingCtrl(crmPicklistValues) {
        this.valueMappingCtrl.crmLookupCtrl.picklistValues = crmPicklistValues;
        this.valueMappingCtrl.crmLookupCtrl.recordTypeValues= await getSobjectRecordTypeInfo({ objectApiName: EM_CATALOG_OBJECT.objectApiName});
        this.valueMappingCtrl.connectionLookupCtrl.vaultFields = this.connectionLookupCtrl.vaultFields;
    }

    async fetchConnectionValueMappingData(systemId) {
        if(!this.vaultLifeCycleStateMap.has(systemId)) {
            const vaultLifeCycleStates = await this.adminMapppingDataSvc.retrieveVaultFieldsAndStates('EM', systemId, true);
            if(vaultLifeCycleStates && vaultLifeCycleStates.data) {
                this.vaultLifeCycleStateMap.set(systemId, vaultLifeCycleStates.data);
                this.valueMappingCtrl.connectionLookupCtrl.lifeCycleStates = vaultLifeCycleStates.data;
            }
        } else {
            this.valueMappingCtrl.connectionLookupCtrl.lifeCycleStates = this.vaultLifeCycleStateMap.get(systemId);
        }
    }
}