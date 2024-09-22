import CONNECTION_OBJECT from '@salesforce/schema/Connection_vod__c';
import URL_FIELD from '@salesforce/schema/Connection_vod__c.Connection_URL_vod__c';
import TYPE_FIELD from '@salesforce/schema/Connection_vod__c.Type_vod__c';
import EXTERNAL_ID_FIELD from '@salesforce/schema/Connection_vod__c.External_ID_vod__c';
import SYNC_SETTINGS from '@salesforce/schema/Connection_vod__c.Sync_Settings_vod__c';
import RECORD_TYPE_ID_FIELD from '@salesforce/schema/Connection_vod__c.RecordTypeId';
import ID_FIELD from '@salesforce/schema/Connection_vod__c.Id';
import VeevaUtils from 'c/veevaUtils';
import EmVaultFieldMappingController from "c/emVaultFieldMappingController";
import { EM_VAULT, getAdminHistoryTableController} from "c/adminHistoryTableControllerFactory";


export default class EmVaultConnectionController {
    fieldMappingController = new EmVaultFieldMappingController();
    historyTableController = getAdminHistoryTableController(EM_VAULT);
    connectionType = 'EM_Vault_Document_Sync_vod';
    modalFields = ['systemId', 'username', 'password', 'additionalParameters'];
    mcTaskName = 'EM_VAULT_INTEGRATION';
    columns = [
        {
            fieldName: 'systemId',
            type: 'text',
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' },
            sortable: true,
        },
        {
            fieldName: 'additionalParameters',
            type: 'text',
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' },
            sortable: true,
            wrapText: true,
        },
        {
            fieldName: 'adminUser',
            type: 'text',
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' },
            sortable: true,
        },
        {
            fieldName: 'lastModDate',
            type: 'date',
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' },
            sortable: true,
            typeAttributes:{
                year: "2-digit",
                month: "2-digit",
                day: "2-digit",
                hour: "2-digit",
                minute: "2-digit",
                second: "2-digit",
            },
        },
        {
            fieldName: 'lastSyncDate',
            type: 'date',
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' },
            sortable: true,
            typeAttributes:{
                year: "2-digit",
                month: "2-digit",
                day: "2-digit",
                hour: "2-digit",
                minute: "2-digit",
                second: "2-digit",
            },
        },
        {
            fieldName: 'lastSyncStatus',
            type: 'text',
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' },
            sortable: true,
        },
        {
            fieldName: 'actions',
            type: 'action',
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' },
            fixedWidth: 80,
        },
    ];
    actions = [
        { name: 'edit' },
        { name: 'validateCredentials' },
        { name: 'validateMappings' },
        { name: 'delete' },
    ];


    constructSaveMcBody(elements) {
        const urlParam = {};
        elements.forEach(element => {
            urlParam[element.name] = this.parseMcFieldValue(element.name, element.value);
        })
        return new URLSearchParams(urlParam).toString();
    }

    parseMcFieldValue(name, value) {
        let fieldValue;
        if('additionalParameters' === name) {
            fieldValue = JSON.stringify({whereClause: value ?? ''});
        } else {
            fieldValue = value ?? '';
        }
        return fieldValue;
    }

    constructSaveCrmBody(systemId, recordTypeId, syncSettings) {
        const fields = {};
        fields[URL_FIELD.fieldApiName] = systemId;
        fields[RECORD_TYPE_ID_FIELD.fieldApiName] = recordTypeId;
        fields[TYPE_FIELD.fieldApiName] = this.connectionType;
        fields[EXTERNAL_ID_FIELD.fieldApiName] = `${systemId}_${this.connectionType}`;
        fields[SYNC_SETTINGS.fieldApiName] = syncSettings?.join(';');
        return { apiName: CONNECTION_OBJECT.objectApiName, fields };
    }

    constructUpdateCrmBody(systemId, sfId, syncSettings) {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = sfId;
        fields[URL_FIELD.fieldApiName] = systemId;
        fields[SYNC_SETTINGS.fieldApiName] = syncSettings?.join(';');
        return { fields };
    }

    getColumnActions(defaultColumnAction) {
        return  this.actions.map(action => ({...action, ...defaultColumnAction.find(defaultAction => defaultAction.name === action.name)}));
    }

    getColumns(defaultColumns) {
        return this.columns.map(column => ({...column, ...defaultColumns.find(defaultColumn => defaultColumn.fieldName === column.fieldName)}));
    }

    async validateMappings(systemId, connectionDataSvc) {
        const response = await connectionDataSvc.runMcTask(this.mcTaskName, 3, systemId);
        this.jobId = response?.data?.results?.[0]?.jobId ?? '';
        if(this.jobId) {
            const record = await this.pollingJobStatus(this.jobId, connectionDataSvc, 'em');
            this.errorCount = record?.data?.[0]?.Fail ?? '0';
            return this.isJobCompleted(record);
        }
        return false;
    }

    async pollingJobStatus(jobId, connectionDataSvc, recordType) {
        const pollingJob = async () =>
            connectionDataSvc.getJobStatus(recordType, '10', 'record', jobId);
        const isDone = record => this.isJobCompleted(record);
        return VeevaUtils.poll(pollingJob, isDone, 3000, 20);
    }

    isJobCompleted(record) {
        const status = record?.status ?? '';
        return status === 'SUCCESS';
    }

    getFileName (mappingToValidate) {
        const vaultUrlFileName = mappingToValidate?.systemId?.replace(/(^\w+:|^)\/\//, '');
        let fileName = 'MappingValidation.csv';
        if(vaultUrlFileName) {
            fileName = `${vaultUrlFileName}_${fileName}`;
        }
        return fileName;
    }

    async deleteConnection(systemId, connectionDataSvc) {
        const response = await connectionDataSvc.runMcTask(this.mcTaskName, 4, systemId);
        this.jobId = response?.data?.results?.[0]?.jobId ?? '';
        if(this.jobId) {
            const record = await this.pollingJobStatus(this.jobId, connectionDataSvc, 'em-integration');
            return this.isJobCompleted(record) && '0' === record?.data?.[0]?.Errors;
        }
        return false;
    }
}