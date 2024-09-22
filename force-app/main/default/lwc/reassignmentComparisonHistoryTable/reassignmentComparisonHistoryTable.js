import { LightningElement, api } from 'lwc';

export default class ReassignmentComparisonHistoryTable extends LightningElement {
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
        this.title = await this.tableDataSvc.messageSvc.getMessageWithDefault('REASSIGN_CALCULATION_HISTORY', 'WeChat', '系统计算分配文件记录');
    }

    async getTableColumns() {
        const {messageSvc} = this.tableDataSvc;
        const messages
            = await Promise.all([
                messageSvc.getMessageWithDefault('REASSIGN_OPERATION', 'WeChat', '操作'),
                messageSvc.getMessageWithDefault('REASSIGNMENT_START_TIME', 'WeChat', '开始时间'),
                messageSvc.getMessageWithDefault('REASSIGNMENT_FINISH_TIME', 'WeChat', '结束时间'),
                messageSvc.getMessageWithDefault('REASSIGNMENT_USER', 'WeChat', '用户'),
                messageSvc.getMessageWithDefault('REASSIGN_CALCULATION_STATUS', 'WeChat', '状态'),
                messageSvc.getMessageWithDefault('REASSIGN_VALID_RECORDS_SUM', 'WeChat', '可分配总数'),
                messageSvc.getMessageWithDefault('REASSIGN_VRECORDS_SUM_AUSER', 'WeChat', '在职分配总数'),
                messageSvc.getMessageWithDefault('REASSIGN_VRECORDS_SUM_INUSER', 'WeChat', '离职分配总数'),
                messageSvc.getMessageWithDefault('REASSIGN_WUSER_DELETE_SUM', 'WeChat', '待离职用户总数'),
                messageSvc.getMessageWithDefault('REASSIGN_CHECK', 'WeChat', '查看')
            ]);
        this.columns = [
            { label: messages[0], fieldName: 'checkDetail', initialWidth: 100, type: 'textWithAction', typeAttributes: { actionLabel: messages[9], action: 'goToDetail'}, hideDefaultActions: true },
            { label: messages[1], fieldName: 'formattedStartTime', initialWidth: 160, hideDefaultActions: true },
            { label: messages[2], fieldName: 'formattedEndTime', initialWidth: 160, hideDefaultActions: true },
            { label: messages[3], fieldName: 'operatorUserName', initialWidth: 200, hideDefaultActions: true },
            { label: messages[4], fieldName: 'statusText', initialWidth: 80, hideDefaultActions: true },
            { label: messages[5], fieldName: 'availableCount', hideDefaultActions: true },
            { label: messages[6], fieldName: 'onjobCount', wrapText: true, hideDefaultActions: true },
            { label: messages[7], fieldName: 'dimissionCount', wrapText: true,  hideDefaultActions: true },
            { label: messages[8], fieldName: 'toleaveCount', wrapText: true,hideDefaultActions: true }
        ];
    }

    async getTableData() {
        const path = `/comparison/list?limit=${this.limit}&offset=${this.offset}`;
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
                if (item.status === 1 || item.status === 2) {
                    item.checkDetail = {
                        id: item.processId,
                        text: ''
                    };
                }
            })
        }
        this.data = payload;
        this.totalCount = metadata.count;
    }

    async actionHandler(event) {
        const {action, recordId} = event.detail.data;
        if (action === 'goToDetail') {
            this.goToDetail(recordId);
        }
    }

    async loadData (event) {
        const {offset} = event.detail.data;
        this.offset = offset;
        this.waiting = true;
        await this.getTableData();
        this.waiting = false;
    }

    goToDetail(recordId) {
        this.dispatchEvent(new CustomEvent('actionclicked', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { action: 'goToDetail', recordId }
            }
        }));
    }
}