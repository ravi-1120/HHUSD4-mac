import {api, LightningElement, track, wire} from 'lwc';
import {VeevaMessageRequest} from "c/veevaMessageService";
import {getService} from 'c/veevaServiceFactory';
import EM_CATALOG_OBJECT from '@salesforce/schema/EM_Catalog_vod__c';
import AdminDataService from "c/adminDataService";
import {getObjectInfos, getPicklistValuesByRecordType} from 'lightning/uiObjectInfoApi';
import getConnectionFieldMapping from '@salesforce/apex/VeevaEmIntegrationAdminService.getConnectionFieldMapping';
import getConnectionValueMapping from '@salesforce/apex/VeevaEmIntegrationAdminService.getConnectionValueMapping';
import getSobjectRecordTypeInfo from '@salesforce/apex/RecordTypeInfoVod.getSobjectRecordTypeInfo';
import {deleteRecord, updateRecord} from 'lightning/uiRecordApi';
import VeevaToastEvent from 'c/veevaToastEvent';
import ID_FIELD from '@salesforce/schema/Connection_Field_Mapping_vod__c.Id';
import STATUS_FIELD from '@salesforce/schema/Connection_Field_Mapping_vod__c.Status_vod__c';

const VALUE_MAPPING = 'value_mapping';
const FIELD_MAPPING = 'field_mapping';
export {VALUE_MAPPING, FIELD_MAPPING};

export default class AdminMapping extends LightningElement {
    @api ctrl;
    @api adminMapppingDataSvc;
    @track messageMap = {};
    @track crmObjectRecordTypeId;
    @track crmObjectName;
    @track selectedRows = [];

    fieldMappingColumns;
    valueMappingColumns
    fieldMappingData;
    valueMappingData;
    fieldMappingObjectLabel = '';
    showFieldMappingModal = false;
    showValueMapping = false;
    modalRecordTypeId;
    modalTitle;
    modalCrmLookupFieldLabel;
    modalConnectionLookupFieldLabel;
    modalCtrl;

    @api selectedRowConnection;
    selectedFieldMappingRow;

    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;


    @wire(getObjectInfos, { objectApiNames: [ EM_CATALOG_OBJECT ]})
    objectInfos({ data }) {
        if (data) {
            const crmObjectInfo = this.ctrl.findCrmObjectInfo(data);
            this.crmObjectName = crmObjectInfo.apiName;
            this.fieldMappingObjectLabel = crmObjectInfo.label;
            this.crmObjectRecordTypeId = crmObjectInfo.defaultRecordTypeId;
        }
    }

    @wire(getPicklistValuesByRecordType, {objectApiName: "$crmObjectName", recordTypeId: "$crmObjectRecordTypeId"})
    crmObjectPicklistValues;

    @api get selectedConnection() {
        return this.selectedRowConnection;
    }
    set selectedConnection(value) {
        if(value && value.systemId !== this.selectedRowConnection?.systemId) {
            this.showValueMapping = false;
            this.selectedRowConnection = value;
            this.loadConnectionFieldMappings();
        }
    }

    async connectedCallback() {
        this.adminMapppingDataSvc = this.adminMapppingDataSvc ? this.adminMapppingDataSvc : new AdminDataService(getService('sessionSvc'), getService('messageSvc'));
        this.messageMap = await this.loadVeevaMessages();
        await this.init();
    }

    async loadVeevaMessages() {
        const {messageSvc} = this.adminMapppingDataSvc;
        const msgRequest = new VeevaMessageRequest();
        msgRequest.addRequest('EMCATALOG_MAPPINGS', 'EVENT_MANAGEMENT', '{0} Mappings', 'fieldMappingCardTitle')
        .addRequest('FIELD_MAPPING', 'Multichannel', 'Field Mappings', 'fieldMappingTitle')
        .addRequest('EMCATALOG_FIELD', 'EVENT_MANAGEMENT', '{0} Field', 'crmFieldColumnLabel')
        .addRequest('CRM_FIELD_TYPE', 'Multichannel', 'CRM Field Type', 'crmFieldTypeColumnLabel')
        .addRequest('VAULT_DOCUMENT_FIELD', 'EVENT_MANAGEMENT', 'Vault Document Field', 'vaultFieldColumnLabel')
        .addRequest('VAULT_FIELD_TYPE', 'EVENT_MANAGEMENT', 'Vault Field Type', 'vaultFieldTypeColumnLabel')
        .addRequest('MAPPING_TYPE', 'EVENT_MANAGEMENT', 'Mapping Type', 'mappingTypeColumnLabel')
        .addRequest('SYSTEM_MAPPING', 'EVENT_MANAGEMENT', 'System', 'systemMappingLabel')
        .addRequest('Custom', 'Analytics', 'Custom', 'customMappingLabel')
        .addRequest('INACTIVE_LABEL', 'Scheduler', 'Inactive', 'inactiveLabel')
        .addRequest('ACTIONS', 'TABLET', 'Actions', 'actionColumnLabel')
        .addRequest('NEW', 'Common', 'New', 'newLabel')
        .addRequest('ACTIVATE_MAPPING', 'EVENT_MANAGEMENT', 'Activate Mapping', 'activateMappingLabel')
        .addRequest('INACTIVATE_MAPPING', 'EVENT_MANAGEMENT', 'Inactivate Mapping', 'inactivateMappingLabel')
        .addRequest('PASSWORD', 'CLM', 'Password', 'passwordLabel')
        .addRequest('CANCEL', 'Common', 'Cancel', 'cancelButtonLabel')
        .addRequest('SAVE_AND_NEW', 'EVENT_MANAGEMENT', 'Save and New', 'saveNewButtonLabel')
        .addRequest('SAVE', 'Common', 'Save', 'saveButtonLabel')
        .addRequest('DELETE', 'Common', 'Delete', 'deleteButtonLabel')
        .addRequest('CVENT_PICKLISTMAPPING_MODAL_TITLE', 'EVENT_MANAGEMENT', 'Value Mappings', 'valueMappingTitle')
        .addRequest('NEW_FIELD_MAPPING', 'EVENT_MANAGEMENT', 'New Connection Field Mapping', 'newFieldMappingModalTitle')
        .addRequest('ADMIN_PAGE_ERROR', 'EVENT_MANAGEMENT', 'There was a problem displaying {0} records. Error: {1}', 'adminPageError')
        .addRequest('SELECT_VAULT_DOCUMENT_FIELD', 'EVENT_MANAGEMENT', 'Select Vault Document Field...', 'connectionLookupFieldPlaceholder')
        .addRequest('SELECT_EMCATALOG_FIELD', 'EVENT_MANAGEMENT', 'Select {0} Field...', 'crmLookupFieldPlaceholder')
        .addRequest('DELETE_MAPPING', 'EVENT_MANAGEMENT', 'Delete Mapping', 'deleteMappingButtonLabel')
        .addRequest('CVENT_VIEWMAPPINGS_NAV', 'EVENT_MANAGEMENT', 'View Mappings', 'viewMappingText')
        .addRequest('CRM_VALUE', 'EVENT_MANAGEMENT', 'CRM Value', 'crmValueFieldLabel')
        .addRequest('VAULT_VALUE', 'EVENT_MANAGEMENT', 'Vault Value', 'vaultValueFieldLabel')
        .addRequest('NEW_VALUE_MAPPING', 'EVENT_MANAGEMENT', 'New Value Mapping', 'newValueMappingModalTitle')
        .addRequest('SELECT_CRM_VALUE', 'EVENT_MANAGEMENT', 'Select CRM Value...', 'selectCrmValueLabel')
        .addRequest('SELECT_VAULT_VALUE', 'EVENT_MANAGEMENT', 'Select Vault Value...', 'selectVaultValueLabel')
        .addRequest('GEN_SAVE_ERROR', 'EVENT_MANAGEMENT', 'We were unable to save the record', 'genericPopoverErrorLabel')
        .addRequest('ENTER_A_VALUE', 'EVENT_MANAGEMENT', 'Enter a value', 'requiredFieldErrorLabel');
        return messageSvc.getMessageMap(msgRequest);
    }

    async init() {
        this.fieldMappingColumns = this.populateFieldMappingColumns();
        this.valueMappingColumns = this.populateValueMappingColumns();
        const fieldMappingRecordTypeInfo = await getSobjectRecordTypeInfo({ objectApiName: 'Connection_Field_Mapping_vod__c'});
        const valueMappingRecordTypeInfo = await getSobjectRecordTypeInfo({ objectApiName: 'Connection_Field_Mapping_vod__c'});
        this.connectionFieldMappingRecordTypeId = fieldMappingRecordTypeInfo.find(rt => 'Field_Mapping_vod' === rt.developerName)?.id;
        this.connectionValueMappingRecordTypeId = valueMappingRecordTypeInfo.find(rt => 'Value_Mapping_vod' === rt.developerName)?.id;
        await this.loadConnectionFieldMappings();
    }

    populateFieldMappingColumns() {
        const defaultColumns = this.getDefaultFieldMappingColumns();
        return this.ctrl.getColumns(defaultColumns, this.messageMap);
    }

    populateValueMappingColumns() {
        const defaultColumnAction = this.getDefaultValueMappingColumnAction();
        const defaultColumns = this.getDefaultValueMappingColumns(defaultColumnAction);
        return this.ctrl.valueMappingCtrl.getColumns(defaultColumns, this.messageMap);
    }

    getDefaultFieldMappingColumns() {
        const crmFieldColumnLabel = this.crmFieldColumnLabel();
        return [
            { label: crmFieldColumnLabel, fieldName: 'crmFieldColumn'},
            { label: this.messageMap.crmFieldTypeColumnLabel, fieldName: 'crmFieldTypeColumn'},
            { label: this.messageMap.vaultFieldColumnLabel, fieldName: 'connectionFieldColumn'},
            { label: this.messageMap.vaultFieldTypeColumnLabel, fieldName: 'connectionFieldTypeColumn'},
            { label: this.messageMap.mappingTypeColumnLabel, fieldName: 'mappingTypeColumn'},
            { label: this.messageMap.actionColumnLabel, fieldName: 'actionColumn'},
        ];
    }

    getDefaultValueMappingColumnAction() {
        return  [
            { label: this.messageMap.deleteButtonLabel, name: 'deleteValueMapping' },
        ];
    }

    getDefaultValueMappingColumns(actions) {
        return [
            { label: this.messageMap.crmValueFieldLabel, fieldName: 'crmValueColumn'},
            { label: this.messageMap.vaultValueFieldLabel, fieldName: 'connectionValueColumn'},
            { label: this.messageMap.actionColumnLabel, fieldName: 'actions', type: 'action', typeAttributes: { rowActions: actions },},
        ];
    }


    get cardTitle() {
        return this.messageMap.fieldMappingCardTitle?.replace('{0}', this.fieldMappingObjectLabel);
    }

    crmFieldColumnLabel() {
        return this.messageMap.crmFieldColumnLabel?.replace('{0}', this.fieldMappingObjectLabel);
    }

    get crmLookupFieldPlaceholder() {
        return this.messageMap.crmLookupFieldPlaceholder?.replace('{0}', this.fieldMappingObjectLabel);
    }

    displayFieldMappingModal() {
        this.ctrl.populateMappingModalData(this.selectedRowConnection, this.messageMap);
        this.modalRecordTypeId = this.connectionFieldMappingRecordTypeId;
        this.modalTitle = this.messageMap.newFieldMappingModalTitle;
        this.modalConnectionLookupFieldLabel = this.messageMap.vaultFieldColumnLabel;
        this.modalCrmLookupFieldLabel = this.crmFieldColumnLabel();
        this.modalCtrl = this.ctrl;
        this.showFieldMappingModal = true;
    }

    displayValueMappingModal() {
        this.ctrl.valueMappingCtrl.populateMappingModalData(this.selectedFieldMappingRow, this.messageMap);
        this.modalRecordTypeId = this.connectionValueMappingRecordTypeId;
        this.modalTitle = this.messageMap.newValueMappingModalTitle;
        this.modalConnectionLookupFieldLabel = this.messageMap.vaultValueFieldLabel;
        this.modalCrmLookupFieldLabel = this.messageMap.crmValueFieldLabel;
        this.modalCtrl = this.ctrl.valueMappingCtrl;
        this.showFieldMappingModal = true;
    }

    closeModal() {
        this.showFieldMappingModal = false;
    }

    saveFieldMapping(event) {
        this.showFieldMappingModal = false;
        if(FIELD_MAPPING === event.detail) {
            this.loadConnectionFieldMappings();
        }else if(VALUE_MAPPING === event.detail) {
            this.loadConnectionValueMappings();
        }
    }

    async saveNewFieldMapping(event) {
        this.saveFieldMapping(event);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            if(FIELD_MAPPING === event.detail) {
                this.displayFieldMappingModal();
            }else if(VALUE_MAPPING === event.detail) {
                this.displayValueMappingModal();
            }
        }, 500);
    }

    async fetchCrmFieldMappingData() {
        const sfId = this.selectedRowConnection?.sfId;
        if(sfId) {
            try {
                this.fieldMappingData = await getConnectionFieldMapping({ connection: sfId });
            } catch (error) {
                this.showMappingError(error);
            }
        }
    }

    async fetchCrmValueMappingData() {
        const sfId = this.selectedFieldMappingRow?.sfId;
        if(sfId) {
            try {
                this.valueMappingData = await getConnectionValueMapping({ fieldMapping: sfId });
            } catch (error) {
                this.showMappingError(error);
            }
        }
    }

    showMappingError(error) {
        const msg = this.messageMap.adminPageError.replace('{0}', this.fieldMappingObjectLabel).replace('{1}', error?.body?.message);
        const obj = {message: msg};
        this.dispatchEvent(VeevaToastEvent.error(obj));
        this.vaultConnections = [];
    }

    async loadConnectionFieldMappings() {
        this.fieldMappingLoading = true;
        await this.fetchCrmFieldMappingData();
        const sfId = this.selectedRowConnection?.systemId;
        if (sfId) {
            await this.ctrl.fetchConnectionFieldMappingData(sfId);
        }
        const mappedCrmFields = [];
        const mappedConnectionFields = [];
        this.fieldMappingData = this.fieldMappingData?.map(data => {
            const fieldMapping = {};
            fieldMapping.sfId = data.Id;
            fieldMapping.crmFieldColumn = data.CRM_Field_vod__c;
            fieldMapping.crmFieldTypeColumn = this.ctrl.getCrmFieldType(data.CRM_Field_vod__c);
            fieldMapping.connectionFieldColumn = data.Connection_Field_vod__c;
            if(!data.System_Mapping_vod__c || 'Active_vod' === data.Status_vod__c) {
                mappedCrmFields.push(data.CRM_Field_vod__c);
                mappedConnectionFields.push(data.Connection_Field_vod__c);
            }
            fieldMapping.connectionFieldTypeColumn = this.ctrl.getConnectionFieldType(data.Connection_Field_vod__c);
            fieldMapping.mappingTypeColumn = this.ctrl.getMappingType(data, this.messageMap);
            fieldMapping.isSystemType = data.System_Mapping_vod__c;
            fieldMapping.isActive = data.Status_vod__c;
            fieldMapping.format = 'Inactive_vod' === fieldMapping.isActive ? 'slds-chat-message__text_sneak-peek' : '';
            fieldMapping.actionColumn = this.ctrl.viewMappingText(fieldMapping.crmFieldTypeColumn, this.messageMap.viewMappingText);
            return fieldMapping;
        }) ?? [];
        this.ctrl.populateMappedFields(mappedCrmFields, mappedConnectionFields);
        this.fieldMappingLoading = false;
    }

    async loadConnectionValueMappings() {
        this.valueMappingLoading = true;
        await this.fetchCrmValueMappingData();
        await this.ctrl.populateValueMappingCtrl(this.crmObjectPicklistValues.data.picklistFieldValues);
        await this.ctrl.fetchConnectionValueMappingData(this.selectedRowConnection?.systemId);
        const mappedVaultValues = [];
        this.valueMappingData = this.valueMappingData?.map(data => {
            const valueMapping = {};
            valueMapping.sfId = data.Id;
            valueMapping.crmValueColumn = data.CRM_Value_vod__c;
            valueMapping.connectionValueColumn = data.Connection_Value_vod__c;
            mappedVaultValues.push(data.Connection_Value_vod__c);
            return valueMapping;
        }) ?? [];
        this.ctrl.populateMappedValues(mappedVaultValues);
        this.valueMappingLoading = false;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const {row} = event.detail;
        switch (actionName) {
            case 'deleteFieldMapping':
                this.deleteRow(row, FIELD_MAPPING);
                break;
            case 'deleteValueMapping':
                this.deleteRow(row, VALUE_MAPPING);
                break;
            case 'activate':
                this.activateFieldMapping(row);
                break;
            case 'inactivate':
                this.inactivateFieldMapping(row);
                break;
            case 'viewValueMapping':
                this.selectedFieldMappingRow = row;
                this.loadConnectionValueMappings();
                this.selectedRows = [this.selectedFieldMappingRow?.sfId];
                this.showValueMapping = true;
                break;
            default:
                break;
        }
    }

    deleteRow(row, mapping) {
        deleteRecord(row.sfId)
        .then(() => {
            if(FIELD_MAPPING === mapping) {
                this.loadConnectionFieldMappings();
                if(row.sfId === this.selectedFieldMappingRow?.sfId) {
                    this.showValueMapping = false;
                }
            } else if(VALUE_MAPPING === mapping) {
                this.loadConnectionValueMappings();
            }
        })
    }

    activateFieldMapping(row) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = row.sfId;
        fields[STATUS_FIELD.fieldApiName] = 'Active_vod';
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.loadConnectionFieldMappings();
            })
    }

    inactivateFieldMapping(row) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = row.sfId;
        fields[STATUS_FIELD.fieldApiName] = 'Inactive_vod';
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.loadConnectionFieldMappings();
            })
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? x => primer(x[field])
            : x => x[field];

        return (a, b) => {
            const value1 = key(a);
            const value2 = key(b);
            if (value1 || value2) {
                if (!value1) {
                    return reverse * -1;
                }
                return !value2 ? reverse * 1 : reverse * value1.toString().localeCompare(value2.toString());
            }
            return 0;

        };
    }

    handleSort(event, data) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
        return cloneData;
    }

    onHandleFieldMappingSort(event) {
        this.fieldMappingData = this.handleSort(event, this.fieldMappingData);
    }

    onHandleValueMappingSort(event) {
        this.valueMappingData = this.handleSort(event, this.valueMappingData);
    }
    
    get hasConnection() {
        return this.selectedRowConnection && Object.keys(this.selectedRowConnection).length && this.selectedRowConnection.systemId;
    }
}