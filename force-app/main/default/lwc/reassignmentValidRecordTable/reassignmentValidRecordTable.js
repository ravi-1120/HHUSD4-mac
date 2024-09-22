import { LightningElement, api, wire } from 'lwc';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import SOCIAL_IDENTITY_OBJECT from '@salesforce/schema/Social_Identity_vod__c';
import ID_FIELD from '@salesforce/schema/Account.Id';
import FORMATTED_NAME_FIELD from '@salesforce/schema/Account.Formatted_Name_vod__c';
import PRIMARY_PARENT_FIELD from '@salesforce/schema/Account.Primary_Parent_vod__c';
import ACCOUNT_IDENTIFIER_FIELD from '@salesforce/schema/Account.Account_Identifier_vod__c';
import UNION_ID_FIELD from '@salesforce/schema/Social_Identity_vod__c.Union_ID_vod__c';
import NICK_NAME_FIELD from '@salesforce/schema/Social_Identity_vod__c.Nick_Name_vod__c';

export default class ReassignmentValidRecordTable extends LightningElement {
    @api processId;
    @api tableDataSvc;

    data = [];
    columns = [];
    limit = 10;
    offset = 0;
    totalCount = 0;
    waiting = false;

    @wire(getObjectInfos, { objectApiNames: [ACCOUNT_OBJECT, SOCIAL_IDENTITY_OBJECT]})
    async getObjects({ data }) {
        if (data && data.results.length > 0) {
            this.waiting = true;
            const objectInfos = data.results;
            await this.setTableColumns(objectInfos[0].result.fields, objectInfos[1].result.fields);
            this.waiting = false;
        }
    }

    async connectedCallback() {
        this.waiting = true;
        await this.getTableData();
        this.waiting = false;
    }

    async setTableColumns(accountObjectFields, socialIdentifierFields) {
        const {messageSvc} = this.tableDataSvc;
        const [externalUserIdMsg, oldUserIdMsg, oldUserNameMsg, newUserIdMsg, newUserNameMsg, 
                oldUserTerMsg, newUserTerMsg, calculationTypeMsg, oldUserStatusMsg, exUserIsDeclinedMsg, exUserDeclinedTimeMsg]
        = await Promise.all([
                messageSvc.getMessageWithDefault('REASSIGN_EXTERNAL_USER_ID', 'WeChat', 'External User ID'),
                messageSvc.getMessageWithDefault('REASSIGN_OLD_USER_ID', 'WeChat', '旧用户编码'),
                messageSvc.getMessageWithDefault('REASSIGN_OLD_USER_NAME', 'WeChat', '旧用户姓名'),
                messageSvc.getMessageWithDefault('REASSIGN_NEW_USER_ID', 'WeChat', '新用户编码'),
                messageSvc.getMessageWithDefault('REASSIGN_NEW_USER_NAME', 'WeChat', '新用户姓名'),
                messageSvc.getMessageWithDefault('REASSIGN_OLD_USER_TER', 'WeChat', '旧用户区域'),
                messageSvc.getMessageWithDefault('REASSIGN_NEW_USER_TER', 'WeChat', '新用户区域'),
                messageSvc.getMessageWithDefault('REASSIGN_CALCULATE_TYPE', 'WeChat', '计算类型'),
                messageSvc.getMessageWithDefault('REASSIGN_OLD_USER_STATUS', 'WeChat', '旧用户状态'),
                messageSvc.getMessageWithDefault('REASSIGN_EXUSER_ISDECLINED', 'WeChat', '客户上次是否拒绝分配'),
                messageSvc.getMessageWithDefault('REASSIGN_EXUSER_DECLINED_TIME', 'WeChat', '客户上次拒绝时间')
        ]);
        this.columns = [
            { label: accountObjectFields[ID_FIELD.fieldApiName]?.label, fieldName: 'accountId'},
            { label: accountObjectFields[FORMATTED_NAME_FIELD.fieldApiName]?.label, fieldName: 'accountFormattedName', initialWidth: 140},
            { label: socialIdentifierFields[UNION_ID_FIELD.fieldApiName]?.label, fieldName: 'unionId'},
            { label: externalUserIdMsg, fieldName: 'externalUserId', initialWidth: 140},
            { label: socialIdentifierFields[NICK_NAME_FIELD.fieldApiName]?.label, fieldName: 'accountWechatNickName'},
            { label: accountObjectFields[PRIMARY_PARENT_FIELD.fieldApiName]?.label, fieldName: 'accountPrimaryParentName', initialWidth: 120},
            { label: accountObjectFields[ACCOUNT_IDENTIFIER_FIELD.fieldApiName]?.label, fieldName: 'accountIdentifier', initialWidth: 140},
            { label: oldUserIdMsg, fieldName: 'oldRepUserId'},
            { label: oldUserNameMsg, fieldName: 'oldRepUserName'},
            { label: newUserIdMsg, fieldName: 'newRepUserId'},
            { label: newUserNameMsg, fieldName: 'newRepUserName'},
            { label: oldUserTerMsg, fieldName: 'oldRepTerritoryName'},
            { label: newUserTerMsg, fieldName: 'newRepTerritoryName'},
            { label: calculationTypeMsg, fieldName: 'computeType'},
            { label: oldUserStatusMsg, fieldName: 'repSalesforceStatus'},
            { label: exUserIsDeclinedMsg, fieldName: 'accountWecomLastReassignmentAcceptStatus', initialWidth: 160},
            { label: exUserDeclinedTimeMsg, fieldName: 'accountWecomLastReassignmentActionTime', initialWidth: 160}
            ];   

            this.columns.forEach(column => {
                Object.assign(column, {
                    hideDefaultActions: true,  
                    wrapText: true
                })
                if (typeof column.initialWidth === 'undefined') {
                    Object.assign(column, {
                        initialWidth: 100
                    })
                }
            })
    }

    async getTableData() {
        const path = `/comparison/${this.processId}/result?type=REASSIGNABLE&limit=${this.limit}&offset=${this.offset}`;
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