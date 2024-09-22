import { LightningElement, api } from 'lwc';
import ReassignmentDataService from 'c/reassignmentDataService';


export default class ReassignmentProcessHistoryTable extends LightningElement {

    @api tableDataSvc;

    title;
    data = [];
    columns = [];
    limit = 10;
    offset = 0;
    totalCount = 0;
    waiting = false;

    async connectedCallback() {
        this.waiting = true;
        await Promise.all([this.getMsgs(), this.getTableColumns(), this.getTableData()]);
        this.waiting = false;
    }

    async getMsgs() {
        [this.title, this.errorSummaryMsg, this.rejectedUserMsg]
        = await Promise.all([
            this.tableDataSvc.messageSvc.getMessageWithDefault('REASSIGNMENT_RECORDS', 'WeChat', '外部联系人重新分配记录'),
            this.tableDataSvc.messageSvc.getMessageWithDefault('REASSIGNMENT_ERROR_SUMMARY', 'WeChat', '异常情况汇总'),
            this.tableDataSvc.messageSvc.getMessageWithDefault('REJECTED_EXUSER', 'WeChat', '拒绝分配外部联系人')
        ]);
    }
    
    async getTableColumns() {
        const {messageSvc} = this.tableDataSvc
        const [startTimeMessage, finishTimeMessage, userMessage, statusMessage, totalMessage, successFailMessage, errorSummaryMessage, downloadDetailsMessage]
            = await Promise.all([
                messageSvc.getMessageWithDefault('REASSIGNMENT_START_TIME', 'WeChat', '开始时间'),
                messageSvc.getMessageWithDefault('REASSIGNMENT_FINISH_TIME', 'WeChat', '结束时间'),
                messageSvc.getMessageWithDefault('REASSIGNMENT_USER', 'WeChat', '用户'),
                messageSvc.getMessageWithDefault('REASSIGNMENT_STATUS', 'WeChat', '状态'),
                messageSvc.getMessageWithDefault('REASSIGNMENT_TOTAL', 'WeChat', '分配总数'),
                messageSvc.getMessageWithDefault('REASSIGNMENT_SUCCESS_FAIL', 'WeChat', '分配成功/拒绝'),
                messageSvc.getMessageWithDefault('REASSIGNMENT_ERROR_SUMMARY', 'WeChat', '异常情况汇总'),
                messageSvc.getMessageWithDefault('DOWNLOAD_DETAILS', 'WeChat', '下载详情')
            ]);
        this.columns = [
            { label: startTimeMessage, fieldName: 'formattedStartTime', initialWidth: 160, hideDefaultActions: true},
            { label: finishTimeMessage, fieldName: 'formattedEndTime', initialWidth: 160, hideDefaultActions: true},
            { label: userMessage, fieldName: 'operationUser', initialWidth: 200,hideDefaultActions: true},
            { label: statusMessage, fieldName: 'status', initialWidth: 80, hideDefaultActions: true},
            { label: totalMessage, fieldName: 'totalProcessed', initialWidth: 100, hideDefaultActions: true},
            { label: successFailMessage, fieldName: 'reassigmentDetail',wrapText: true, type: 'textWithAction', typeAttributes: {actionLabel: downloadDetailsMessage, action:'downloadDeniedList'}, initialWidth: 300, hideDefaultActions: true},
            { label: errorSummaryMessage, fieldName: 'errorSummary',wrapText: true, type: 'textWithAction', typeAttributes: {actionLabel: downloadDetailsMessage, action:'downloadException'}, hideDefaultActions: true }
        ];   
    }

    async getTableData() {
        const path = `?limit=${this.limit}&offset=${this.offset}`;
        const response = await this.tableDataSvc.getTableData(path);
        if (response && response.payload) {
            this.processData(response);
        }
    }

    processData(response) {
        const {metadata, payload} = response;
        if (payload.length > 0) {
            payload.forEach(item => {
                /* eslint no-param-reassign: ["error", { "props": true, "ignorePropertyModificationsFor": ["item"] }] */
                if (item.hasDeniedList) {
                    item.reassigmentDetail = {
                        id: item.id,
                        text: item.reassignedMessage
                    };
                } else {
                    item.reassigmentDetail = {
                        id: '',
                        text: item.reassignedMessage
                    };
                }
                if (item.hasExceptionList) {
                    item.errorSummary = {
                        id: item.id,
                        text: item.exceptionMessage
                    };
                } else {
                    item.errorSummary = {
                        id: '',
                        text: item.exceptionMessage
                    };
                }
            })
        }
        this.data = payload;
        this.totalCount = metadata.count;
    }

    async loadData (event) {
        const {offset} = event.detail.data;
        this.offset = offset;
        this.waiting = true;
        await this.getTableData();
        this.waiting = false;
    }

    async actionHandler(event) {
        event.stopPropagation();
        const {action, recordId} = event.detail.data;
        let path;
        switch (action) {
            case 'downloadException':
                path = `/${recordId}/exception-list`;
                break;
            case 'downloadDeniedList':
                path = `/${recordId}/denied-list`;
                break;
            default:
        }
        if (path) {
            this.waiting = true;
            const file = await this.tableDataSvc.getFileData(path);
            const fileName = this.getFileName(action);
            ReassignmentDataService.saveBlob(file, fileName);
            this.waiting = false;
        }
    }

    getFileName (type) {
        let category; 
        switch(type) {
            case 'downloadException':
                category = this.errorSummaryMsg;
                break;
            case 'downloadDeniedList':
                category = this.rejectedUserMsg; 
                break; 
            default:
        }
        const tempDate = new Date();
        tempDate.setMinutes(tempDate.getMinutes() - tempDate.getTimezoneOffset());
        const dateTimeStr = tempDate.toISOString().substring(0, 19).replace('T', '_').replace(/:/g, '-');
        return `${category}_${dateTimeStr}.csv`;
    }
}