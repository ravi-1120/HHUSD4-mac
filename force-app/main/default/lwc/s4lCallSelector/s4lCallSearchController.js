import VeevaLayoutService from 'c/veevaLayoutService';
import VeevaUtils from 'c/veevaUtils';
import CALL2_OBJECT from '@salesforce/schema/Call2_vod__c';
import getUnsubmittedCallIdsForUser from '@salesforce/apex/S4LCallSearchController.getUnsubmittedCallIdsForUser';

const RECORDS_PER_PAGE = 50;
export default class S4lCallSearchController {

    hasEventFLS = false;

    constructor(userInterface, messageSvc) {
        this.uiApi = userInterface;
        this.messageSvc = messageSvc;
        this.callIds = []; // all qualify call ids
        this.callMap = {}; // call id -> data map
    }

    async getColumns(forQuery) {
        if (!this.columns) {
            const searchLayoutResponse = await this.uiApi.searchLayout(CALL2_OBJECT.objectApiName);
            await this.addEventFields(searchLayoutResponse);
            this.addDateField(searchLayoutResponse);
            this.columns = VeevaLayoutService.toSearchLayoutColumns(searchLayoutResponse, this.callObjectInfo, CALL2_OBJECT.objectApiName);
        }
        if (forQuery) {
            return this.columns;
        }
        if (!this.eventNameLabel && this.hasEventFLS) {
            this.eventNameLabel = await this.messageSvc.getMessageWithDefault('EM_QR_INBOUND_EVENT_NAME', 'EVENT_MANAGEMENT', 'Event Name');
        }
        const userVisibleColumns = [
            ...this.columns.filter(
                column =>
                  !column.queryFld.includes('EM_Event_vod') &&
                  !column.queryFld.includes('Medical_Event_vod') &&
                  !column.queryFld.includes('Call_Datetime_vod__c') &&
                  !column.queryFld.includes('Call_Date_vod__c')
            ),
            {
                label: this.callObjectInfo?.fields?.Call_Date_vod__c?.label,
                type: 'text',
                fieldName: 'Combined_Date_vod__c',
            }
        ];
        if (this.hasEventFLS) {
            userVisibleColumns.push({
                label: this.eventNameLabel,
                type: 'text',
                fieldName: 'Event_Display_Name_vod__c',
            });
        }
        return userVisibleColumns;
    }

    get offset() {
        return Object.keys(this.callMap).length;
    }

    async searchWithColumns() {
        if(!(this.callIds && this.callIds.length)) {
            this.callIds = await getUnsubmittedCallIdsForUser({todayOnly: false});
        }
        if(!this.columns) {
            this.columns = await this.getColumns(true);
        }
        const colFlds = this.columns.map(col => col.queryFld);
        let records = [];
        if (this.callIds && this.callIds.length > 0) {
            const {offset} = this;
            const toSearchIds = this.callIds.slice(offset, offset + RECORDS_PER_PAGE);
            const batchRecords = await this.queryRecordsByIds(toSearchIds, colFlds);
            if (batchRecords) {
                records = batchRecords.reduce((searchRecords, batchRecord) => {
                    if (batchRecord.id) {
                        searchRecords.push(this.toSearchRecord(batchRecord));
                        this.callMap[batchRecord.id] = batchRecord;
                    }
                    return searchRecords;
                }, []);
            }
        }
        return this.toResult(records);
    }

    async queryRecordsByIds(ids, fields) {
        // eslint-disable-next-line no-return-await
        return await this.uiApi.getBatchRecords(ids, fields);
    }

    toSearchRecord(record) {
        let result = { id: record.id, apiName: record.apiName, icon: VeevaUtils.getIconHardcoded(record.apiName) };
        const colFieldNames = this.columns.map(col => col.fieldName);
        const parsedValueObject = this.getQueryResultValueObject(record, colFieldNames);
        result = { ...result, ...parsedValueObject };
        result.name = result.Name || '';
        return result;
    }

    getQueryResultValueObject(record, fields) {
        const result = {};
        const resultFields = record.fields;
        const eventName = this.findEventName(record);
        fields.forEach((qryFldName) => {
            const fieldPt = qryFldName.split('.');
            if(fieldPt.length > 0) {
                const fldName = fieldPt[0];
                let valueObject = resultFields[fldName];
                if(fieldPt.length > 1 && valueObject && valueObject.value && valueObject.value.fields) {
                    const refFldName = fieldPt[1];
                    const refFldValueObj = valueObject.value.fields[refFldName];
                    if(refFldValueObj) {
                        valueObject = refFldValueObj;
                    }
                }
                if(valueObject) {
                    result[qryFldName] = valueObject.displayValue || valueObject.value;
                }
            }
        });
        if (eventName != null) {
            result.Event_Display_Name_vod__c = eventName;
        }
        result.Combined_Date_vod__c = record.fields?.Call_Datetime_vod__c?.displayValue ?? record.fields?.Call_Date_vod__c?.displayValue;
        return result;
    }
    
    findEventName(record) {
        if (record.fields?.Medical_Event_vod__c?.value != null) {
            const medicalEventFields = record.fields.Medical_Event_vod__r?.value?.fields;
            return medicalEventFields?.Event_Display_Name_vod__c?.value ?? medicalEventFields?.Name?.value;
        }
        
        if (record.fields?.EM_Event_vod__c?.value != null) {
            const eventFields = record.fields.EM_Event_vod__r?.value?.fields
            return eventFields?.Event_Display_Name_vod__c?.value ?? eventFields?.Name?.value;
        }
        return null;
    }

    toResult(result) {
        return {
            records: result,
            hasMore: this.offset < this.callIds.length
        };
    }

    async addEventFields(searchLayoutResponse) {
        if (this.callObjectInfo?.fields) {
            const callFields = Object.keys(this.callObjectInfo.fields);
            if (this.eventObjectInfo?.fields && callFields.includes('EM_Event_vod__c')) {
                const eventFields = Object.keys(this.eventObjectInfo.fields);
                if (eventFields.includes('Name')) {
                    searchLayoutResponse.searchColumns.push({
                        name: 'Call2_vod__c.EM_Event_vod__c',
                    });
                    searchLayoutResponse.searchColumns.push({
                        name: 'EM_Event_vod__r.Name',
                    });
                    this.hasEventFLS = true;
                    if (eventFields.includes('Event_Display_Name_vod__c')) {
                        searchLayoutResponse.searchColumns.push({
                            name: 'EM_Event_vod__r.Event_Display_Name_vod__c',
                        });
                    }
                }
            }
            if (this.medicalEventObjectInfo?.fields && callFields.includes('Medical_Event_vod__c')) {
                const medicalEventFields = Object.keys(this.medicalEventObjectInfo.fields);
                if (medicalEventFields.includes('Name')) {
                    searchLayoutResponse.searchColumns.push({
                        name: 'Call2_vod__c.Medical_Event_vod__c',
                    });
                    searchLayoutResponse.searchColumns.push({
                        name: 'Medical_Event_vod__r.Name',
                    });
                    this.hasEventFLS = true;
                    if (medicalEventFields.includes('Event_Display_Name_vod__c')) {
                        searchLayoutResponse.searchColumns.push({
                            name: 'Medical_Event_vod__r.Event_Display_Name_vod__c',
                        });
                    }
                }
            }
        }
    }
    
    addDateField(searchLayoutResponse) {
        if (this.callObjectInfo?.fields) {
            if (Object.keys(this.callObjectInfo.fields).includes('Call_Date_vod__c')) {
                searchLayoutResponse.searchColumns.push({
                    name: 'Call2_vod__c.Call_Date_vod__c',
                });
            }
        }
    }
}