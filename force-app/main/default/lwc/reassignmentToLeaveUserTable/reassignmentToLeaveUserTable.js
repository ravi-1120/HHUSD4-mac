import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import USER_OBJECT from '@salesforce/schema/User';
import ID_FIELD from '@salesforce/schema/User.Id';
import NAME_FIELD from '@salesforce/schema/User.Name';

export default class ReassignmentToLeaveUserTable extends LightningElement {
    @api processId;
    @api tableDataSvc;

    data = [];
    columns = [];
    limit = 10;
    offset = 0;
    totalCount = 0;
    waiting = false;

    @wire(getObjectInfo, { objectApiName: USER_OBJECT})
    async getObject({data}) {
        if (data) {
            this.waiting = true;
            await this.setTableColumns(data.fields);
            this.waiting = false;
        }  
    }

    async connectedCallback() {
        this.waiting = true;
        await this.getTableData();
        this.waiting = false;
    }

    async setTableColumns(userObjectFields) {
        const {messageSvc} = this.tableDataSvc;
        const [repSalesforceStatus, repWecomStatus]
        = await Promise.all([
                messageSvc.getMessageWithDefault('REASSIGN_CRM_USER_STATUS', 'WeChat', 'CRM用户状态'),
                messageSvc.getMessageWithDefault('REASSIGN_WECOM_USER_STATUS', 'WeChat', '企业微信用户状态')
        ]);
        this.columns = [
            { label: userObjectFields[ID_FIELD.fieldApiName]?.label, fieldName: 'repUserId', hideDefaultActions: true},
            { label: userObjectFields[NAME_FIELD.fieldApiName]?.label, fieldName: 'repUserName', hideDefaultActions: true},
            { label: repSalesforceStatus, fieldName: 'repSalesforceStatus', hideDefaultActions: true},
            { label: repWecomStatus, fieldName: 'repWecomStatus', hideDefaultActions: true}
            ];   
    }

    async getTableData() {
        const path = `/comparison/${this.processId}/result?type=TO_LEAVE&limit=${this.limit}&offset=${this.offset}`;
        const response = await this.tableDataSvc.getTableData(path);
        if (response && response.payload) {
            this.data = response.payload;
            this.totalCount = response.metadata.count;
        }
    }

    async loadData (event) {
        const {offset} = event.detail.data;
        this.offset = offset;
        this.waiting = true;
        await this.getTableData();
        this.waiting = false;
    }
}