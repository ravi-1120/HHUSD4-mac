import {api, LightningElement, track, wire} from 'lwc';
import {VeevaMessageRequest} from "c/veevaMessageService";
import {getService} from 'c/veevaServiceFactory';
import CONNECTION_OBJECT from '@salesforce/schema/Connection_vod__c';
import AdminDataService from "c/adminDataService";
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import getConnection from '@salesforce/apex/VeevaEmIntegrationAdminService.getConnection';
import createSystemMappings from '@salesforce/apex/VeevaEmIntegrationAdminService.createSystemMappings';
import getSobjectRecordTypeInfo from '@salesforce/apex/RecordTypeInfoVod.getSobjectRecordTypeInfo';
import integrationAdminChannel from '@salesforce/messageChannel/Integration_Admin_Channel_vod__c';
import SYNC_SETTINGS_FIELD from '@salesforce/schema/Connection_vod__c.Sync_Settings_vod__c';
import { subscribe, unsubscribe, publish, MessageContext } from 'lightning/messageService';
import VeevaToastEvent from 'c/veevaToastEvent';

export default class AdminConnection extends LightningElement {
    @api systemType;
    @api ctrl;

    @track selectedRows = [];
    @track messageMap = {};
    @track actionRow;
    @track vaultConnections;

    @wire(getObjectInfo, { objectApiName: CONNECTION_OBJECT })
    objectInfo;

    @wire(MessageContext)
    messageContext;

    subscription = null;
    rowSelection;
    connectionDataSvc;
    connectionColumns;
    connectionData;
    isEdit;
    showConnectionModal = false;
    showDeleteConnection = false;
    showSpinner = false;
    deleteConfirmation;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
    showValidateMappings = false;
    showDownloadReport = false;
    mappingToValidate;
    syncSettingsPicklistValues = [];

    async connectedCallback() {
        this.subscribeToChannel();
        this.connectionDataSvc = new AdminDataService(getService('sessionSvc'), getService('messageSvc'));
        this.messageMap = await this.loadVeevaMessages();
        await this.init();
        this.validateAllConnection();
    }

    disconnectedCallback() {
        this.unsubscribeToChannel();
    }

    async loadVeevaMessages() {
        const {messageSvc} = this.connectionDataSvc;
        const msgRequest = new VeevaMessageRequest();
        msgRequest.addRequest('CONNECTIONS', 'EVENT_MANAGEMENT', 'Connections', 'connectionCardTitle');
        msgRequest.addRequest('NEW', 'Common', 'New', 'newButtonLabel');
        msgRequest.addRequest('APPROVED_EMAIL_ADMIN_PAGE_VURL', 'ApprovedEmail', 'Vault URL', 'vaultUrlLabel');
        msgRequest.addRequest('VAULT_CON_WHERE_CLAUSE', 'EVENT_MANAGEMENT', 'WHERE Clause', 'whereClauseLabel');
        msgRequest.addRequest('VAULT_CON_USER', 'EVENT_MANAGEMENT', 'Vault User', 'vaultUserLabel');
        msgRequest.addRequest('EM_QR_LAST_MODIFIED', 'EVENT_MANAGEMENT', 'Last Modified', 'lastModLabel');
        msgRequest.addRequest('ACTIONS', 'TABLET', 'Actions', 'actionsLabel');
        msgRequest.addRequest('Edit', 'Common', 'Edit', 'editButtonLabel');
        msgRequest.addRequest('VALIDATE_CREDENTIALS', 'EVENT_MANAGEMENT', 'Validate Credentials', 'validateCredentialsLabel');
        msgRequest.addRequest('VALIDATE_MAPPINGS', 'EVENT_MANAGEMENT', 'Validate Mappings', 'validateMappingsLabel');
        msgRequest.addRequest('DELETE', 'Common', 'Delete', 'deleteButtonLabel');
        msgRequest.addRequest('NEW_CONNECTION', 'EVENT_MANAGEMENT', 'New Connection', 'newConnectionTitle');
        msgRequest.addRequest('LOGIN_EDIT_CONNECTION', 'Common', 'Edit Connection', 'editConnectionTitle');
        msgRequest.addRequest('PASSWORD', 'CLM', 'Password', 'passwordLabel');
        msgRequest.addRequest('CANCEL', 'Common', 'Cancel', 'cancelButtonLabel');
        msgRequest.addRequest('SAVENEW', 'CallReport', 'Save and New', 'saveNewButtonLabel');
        msgRequest.addRequest('SAVE', 'Common', 'Save', 'saveButtonLabel');
        msgRequest.addRequest('LOGIN_DELETE_CONNECTION', 'Common', 'Delete Connection', 'deleteConnectionTitle');
        msgRequest.addRequest('DELETE_CONNECTION_WARNING', 'EVENT_MANAGEMENT',
        'Are you sure you want to delete this connection? \n\n Deleting this connection will remove the configuration settings, all associated mappings, and will expire all synced Vault content in CRM.',
         'deleteWarningMsg');
        msgRequest.addRequest('VAULT_CON_VALID_CRED', 'EVENT_MANAGEMENT', 'Credentials are valid for {0}', 'validCredLabel');
        msgRequest.addRequest('VAULT_CON_INVALID_CRED', 'EVENT_MANAGEMENT', 'Credentials are invalid for {0}', 'invalidCredLabel');
        msgRequest.addRequest('ADMIN_PAGE_ERROR', 'EVENT_MANAGEMENT', 'There was a problem displaying {0} records. Error: {1}', 'adminPageError');
        msgRequest.addRequest('GEN_SAVE_ERROR', 'EVENT_MANAGEMENT', 'We were unable to save the record', 'genericPopoverErrorLabel');
        msgRequest.addRequest('ENTER_A_VALUE', 'EVENT_MANAGEMENT', 'Enter a value', 'requiredFieldErrorLabel');
        msgRequest.addRequest('VALIDATE_MAPPINGS', 'EVENT_MANAGEMENT', 'Validating Mappings', 'validatingMappingsTitle');
        msgRequest.addRequest('FAILED_VALIDATIONS', 'EVENT_MANAGEMENT', '{0} Problem(s) Found', 'failedValidationTitle');
        msgRequest.addRequest('DOWNLOAD_REPORT', 'EVENT_MANAGEMENT', 'Download Report', 'downloadReportTitle');
        msgRequest.addRequest('FAILED_VALIDATIONS_TEXT', 'EVENT_MANAGEMENT', 'Click the download button to view the full report', 'downloadPageText');
        msgRequest.addRequest('CVENT_GENERAL_DELETE_ERROR', 'EVENT_MANAGEMENT', 'An error occurred while attempting to delete this record.', 'deleteErrorLabel');
        msgRequest.addRequest('DISABLED', 'EVENT_MANAGEMENT', 'Disabled', 'disabledLabel');
        msgRequest.addRequest('ENABLED', 'EVENT_MANAGEMENT', 'Enabled', 'enabledLabel');
        return messageSvc.getMessageMap(msgRequest);
    }

    async init() {
        this.connectionColumns = this.populateColumns();
        await this.loadConnections();
        const rtInfo = await getSobjectRecordTypeInfo({ objectApiName: CONNECTION_OBJECT.objectApiName});
        this.connectionRecordTypeId = rtInfo.find(rt => 'Connection_vod' === rt.developerName)?.id;
        this.selectedRows = this.connectionData[0]?.sfId ? [this.connectionData[0]?.sfId] : [];
        const systemId = this.connectionData[0]?.systemId ?? '';
        const sfId = this.connectionData[0]?.sfId ?? '';
        this.rowSelection = {systemId, sfId};
        this.messageMap.syncSettingsLabel = this.objectInfo?.data?.fields?.Sync_Settings_vod__c?.label || 'Last Sync Status';
        const uiApi = getService('userInterfaceSvc');
        const syncSettingsPicklistInfos = await uiApi.getPicklistValues(this.connectionRecordTypeId, CONNECTION_OBJECT.objectApiName, SYNC_SETTINGS_FIELD.fieldApiName);
        syncSettingsPicklistInfos?.values?.forEach(picklist => {
            this.syncSettingsPicklistValues.push({
                label: picklist.label,
                value: picklist.value,
            })
        });
    }

    populateColumns() {
        const defaultColumnAction = this.getDefaultColumnAction();
        const columnActions = this.ctrl.getColumnActions(defaultColumnAction);
        const defaultColumns = this.getDefaultColumns(columnActions);
        return this.ctrl.getColumns(defaultColumns);
    }

    getDefaultColumnAction() {
        return  [
            { label: this.messageMap.editButtonLabel, name: 'edit' },
            { label: this.messageMap.validateCredentialsLabel, name: 'validateCredentials' },
            { label: this.messageMap.validateMappingsLabel, name: 'validateMappings' },
            { label: this.messageMap.deleteButtonLabel, name: 'delete' },
        ];
    }

    getDefaultColumns(actions) {
        return [
            { label: this.messageMap.vaultUrlLabel, fieldName: 'systemId'},
            { label: this.messageMap.whereClauseLabel, fieldName: 'additionalParameters'},
            { label: this.messageMap.vaultUserLabel, fieldName: 'adminUser'},
            { label: this.messageMap.lastModLabel, fieldName: 'lastModDate'},
            { label: this.objectInfo?.data?.fields?.Last_Sync_Date_vod__c.label ?? 'Last Sync Date', fieldName: 'lastSyncDate'},
            { label: this.objectInfo?.data?.fields?.Last_Sync_Status_vod__c.label ?? 'Last Sync Status', fieldName: 'lastSyncStatus'},
            { label: this.messageMap.actionsLabel,
                fieldName: 'actions',
                typeAttributes: { rowActions: actions },
            },
        ];
    }

    async fetchConnectionCRMData() {
        try {
            this.vaultConnections = await getConnection({ type: this.ctrl.connectionType });
        } catch (error) {
            const msg = this.messageMap.adminPageError.replace('{0}', this.objectInfo.data.label).replace('{1}', error?.body?.message);
            const obj = {message: msg};
            this.dispatchEvent(VeevaToastEvent.error(obj));
            this.vaultConnections = [];
        }
    }

    async loadConnections() {
        await this.fetchConnectionCRMData();
        const sfData = this.vaultConnections?.map(data => {
            const connection = {};
            connection.systemId= data.Connection_URL_vod__c;
            connection.sfId= data.Id;
            connection.lastSyncDate= data.Last_Sync_Date_vod__c;
            connection.lastSyncStatus = data.Last_Sync_Status_vod__c;
            connection.syncSettings = data.Sync_Settings_vod__c?.split(';');
            return connection;
        }) ?? [];
        const tempMcData = await this.getMCConnectionData();
        const mcData =  Array.isArray(tempMcData) ? tempMcData.map(obj =>
            ({ ...obj, additionalParameters: JSON.parse(obj?.additionalParameters ?? '{}')?.whereClause ?? ''})) : [];
        this.connectionData = mcData.length ? sfData.map((sf) => ({ ...sf, ...mcData.find((mc) => mc.systemId === sf.systemId) })) : sfData;
    }

    displayNewConnectionModal() {
        this.isEdit = false;
        this.actionRow = {};
        this.showConnectionModal = true;
    }

    async getMCConnectionData() {
        return this.connectionDataSvc.readVerifyCredential('read', this.systemType);
     }

    async validateAllConnection() {
        const connectionsTocheck = this.connectionData.map(data=>data.systemId);
        connectionsTocheck.forEach(this.validateRowConnection, this);
    }

    async validateRowConnection(systemId, showSuccessToast) {
        const validateResponse = await this.connectionDataSvc.readVerifyCredential('validate', this.systemType, systemId);
        if(validateResponse === '' && showSuccessToast === true) {
            const msg = this.messageMap.validCredLabel.replace('{0}', systemId);
            this.dispatchEvent(VeevaToastEvent.successMessage(msg));
        } else if(validateResponse !== '') {
            const msg = this.messageMap.invalidCredLabel.replace('{0}', systemId);
            const obj = {message: msg};
            this.dispatchEvent(VeevaToastEvent.error(obj));
        }
    }

    closeConnectionModal() {
        this.showConnectionModal = false;
    }

    async saveConnectionModal(event) {
        this.showConnectionModal = false;
        const {sfId, systemId} = event.detail;
        if(!this.isEdit && 'EM_Vault_Document_Sync_vod' === this.ctrl.connectionType) {
            try {
                await createSystemMappings({ connection: sfId });
            } catch (error) {
                const msg = this.messageMap.adminPageError.replace('{0}', this.objectInfo.data.label).replace('{1}', error?.body?.message);
                const obj = {message: msg};
                this.dispatchEvent(VeevaToastEvent.error(obj));
            }
        }
        await this.loadConnections();
        this.selectedRows = [sfId];
        this.rowSelection = {systemId, sfId};
    }

    async saveAndNewConnection(event) {
        await this.saveConnectionModal(event);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {}, 500);
        this.showConnectionModal = true;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const {row} = event.detail;
        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                break;
            case 'edit':
                this.editRow(row);
                break;
            case 'validateCredentials':
                this.validateRowCredential(row);
                break;
            case 'validateMappings':
                this.validateMappings(row);
                break;
            default:
                break;
        }
    }

    deleteRow(row) {
        this.actionRow = row;
        this.deleteConfirmation = this.messageMap.deleteWarningMsg.split(/\r?\n|\r|\n/g);
        this.showDeleteConnection = true;
    }

    editRow(row) {
        this.actionRow = row;
        this.isEdit = true;
        this.showConnectionModal = true;
    }

    validateRowCredential(row) {
        this.validateRowConnection(row.systemId, true);
    }

    async deleteConnection() {
        this.showDeleteConnection = false;
        this.showSpinner = true;
        const deleteResult = await this.ctrl.deleteConnection(this.actionRow.systemId, this.connectionDataSvc);
        if(deleteResult) {
            if(this.rowSelection?.systemId === this.actionRow.systemId) {
                this.rowSelection = {};
            }
            this.loadConnections();
            const payload = {
                type: 'deleteConnection',
            };
            publish(this.messageContext, integrationAdminChannel, payload);
        } else {
            const obj = {message: this.messageMap.deleteErrorLabel};
            this.dispatchEvent(VeevaToastEvent.error(obj));
        }
        this.showSpinner = false;
    }

    cancelDelete(event) {
        event.stopPropagation();
        this.showDeleteConnection = false;
    }

    get recordTypeId() {
        return this.connectionRecordTypeId;
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

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.connectionData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.connectionData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    handleRowSelection(event) {
        const systemId = event.detail.selectedRows[0]?.systemId ?? '';
        const sfId = event.detail.selectedRows[0]?.sfId ?? '';
        this.rowSelection = {systemId, sfId}
    }

    async validateMappings(row) {
        this.mappingToValidate = row;
        this.showValidateMappings = true;
        const result = await this.ctrl.validateMappings(row.systemId, this.connectionDataSvc);
        if(result) {
            this.showDownloadReport = true;
        } else {
            this.closeValidateMappings();
        }
    }

    closeValidateMappings() {
        this.showValidateMappings = false;
        this.showDownloadReport = false;
    }

    async downloadReport(event) {
        const file = await this.connectionDataSvc.getMcJobCsvFile(event.detail, 'em-validation');
        const fileName = this.ctrl.getFileName(this.mappingToValidate);
        this.connectionDataSvc.saveBlob(file, fileName);
    }

    subscribeToChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, integrationAdminChannel, message => this.handleMessage(message));
        }
    }

    unsubscribeToChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(msg) {
        if (msg.type === 'sync') {
            this.loadConnections();
        }
    }
}