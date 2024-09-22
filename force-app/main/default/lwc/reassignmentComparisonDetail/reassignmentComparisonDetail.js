import { LightningElement, api } from 'lwc';
import ReassignmentDataService from 'c/reassignmentDataService';

export default class ReassignmentComparisonDetail extends LightningElement {
    @api detailDataSvc;    
    @api detailProcessId;

    currentStepIndex;
    allSteps = [];
    calculationSteps = [];
    showAlertDialog = false;
    showConfirmDialog = false;
    resultType = 'validRecord';
    widthIsSet = false;
    waiting = false;
    processStatus = '1'; // 1-running, 2-success, 3-failed, 4-interrupted

    get inProcessing () {
        return this.processStatus === '1';
    }

    get isFailed () {
        return this.processStatus === '3';
    }

    get processInfos () {
        const result = [];
        if (this.calculationSteps.length > 0 && this.calculationSteps.length < 5 && this.allSteps.length > 0) {
            this.currentStepIndex = this.calculationSteps.length - 1;
            this.calculationSteps.forEach((step, index) => {
                step.label = this.allSteps[index].label;
                step.info = this.allSteps[index].info? this.allSteps[index].info.replace('{0}', step.captureSnapshotDateTime ? step.captureSnapshotDateTime : this.noDataMsg) : '';
                result.push(step);
            })
            if (this.isFailed) {
                result[this.currentStepIndex].info = this.processExceptionMsg;
            } else {
                result[this.currentStepIndex].info = this.currentStepHintMsg.replace('{0}', result[this.currentStepIndex].label);
            }
        }
        return result.reverse();
    }

    get processSteps () {
        if (this.calculationSteps.length > 0 && this.allSteps.length > 0) {
            this.currentStepIndex = this.calculationSteps.length - 1;
            this.allSteps.forEach((step, index) => {
                /* eslint no-param-reassign: ["error", { "props": true, "ignorePropertyModificationsFor": ["step"] }] */
                if (index < this.currentStepIndex) {
                    step.status = 'finished';
                } else if (index === this.currentStepIndex) {
                    if (this.isFailed) {
                        step.status = 'error';
                    } else {
                        step.status = 'current';
                    }
                }
            })
        }
        return this.allSteps;
    }

    get validRecordSelected() {
        return  this.resultType === 'validRecord';
    }

    get weComDeleteUserSelected() {
        return this.resultType === 'weComDeleteUser';
    }

    get validRecordClass() {
        return this.validRecordSelected? 'selected slds-p-around_x-small' : 'slds-p-around_x-small';
    }

    get weComDeleteUserClass() {
        return this.weComDeleteUserSelected? 'selected slds-p-around_x-small' : 'slds-p-around_x-small';
    }

    get validResultClass() {
        return this.validRecordSelected? 'table-border-top' : 'table-border-top slds-hide';
    }

    get weComDeleteUserResultClass() {
        return this.weComDeleteUserSelected? '' : 'slds-hide';
    }

    get displayResult() {
        return this.processStatus === '2' && this.widthIsSet;
    }

    async connectedCallback() {
        await Promise.all([this.initMessagesAndSteps(), this.getProcessStatus()]);
        clearInterval(this.checkStatusInterval);
        if (this.calculationSteps.length < 5) {
            /* eslint-disable-next-line */
            this.checkStatusInterval = setInterval(() => {
                if (this.inProcessing) {
                    this.getProcessStatus();
                } else {
                    clearInterval(this.checkStatusInterval);
                }
            }, 5000)
        }
    }

    disconnectedCallback () {
        clearInterval(this.checkStatusInterval);
    }

    async initMessagesAndSteps() {
        [this.title, this.stopCalculationMsg, this.downloadZipMsg, this.preCrmDataGetStepMsg, this.curCrmDataGetStepMsg,
        this.curWecomDataGetStepMsg, this.dataGenerateStepMsg, this.generateFinishStepMsg, this.currentStepHintMsg,
        this.preCrmDataMsg, this.curCrmDataMsg, this.curWecomDataMsg, this.processCannotCancelMsg, this.confirmAbortMsg, 
        this.wuserDeleteRemindMsg, this.validRecordMsg, this.weComDeleteUserMsg, this.processExceptionMsg, this.noDataMsg] 
        = await Promise.all([
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_RECORD_GENERATE', 'WeChat', '系统计算分配文件'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_AUTO_CANCEL', 'WeChat', '终止计算'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_RECORDS_DOWNLOAD', 'WeChat', '下载文件压缩包'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_PRE_CRM_DATA_GET', 'WeChat', '提取初始数据'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_CUR_CRM_DATA_GET', 'WeChat', '获取当前数据'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_CUR_WECOM_DATA_GET', 'WeChat', '获取WeCom最新数据'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_DATA_GENERATE', 'WeChat', '计算分配数据'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_GENERATE_FINISH', 'WeChat', '计算完成'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_CURRENT_STEP_HINT', 'WeChat', '正在{0}，请稍后...'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_PRE_CRM_DATA', 'WeChat', '初始数据：{0} 数据'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_CUR_CRM_DATA', 'WeChat', '当前数据：{0} 数据'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_CUR_WECOM_DATA', 'WeChat', 'WeCom最新数据：{0} 数据'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_AUTO_CANNOT_CANCEL', 'WeChat', '计算已完成，无法终止'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_AUTO_CANCEL_REMIND', 'WeChat', '本次计算数据将被删除，是否确认终止计算？'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_WUSER_DELETE_REMIND', 'WeChat', '以下用户需先从企业微信离职后，再执行外部联系人重新分配'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_VALID_RECORDS', 'WeChat', '可分配'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_WECOM_USER_DELETE', 'WeChat', '待离职用户'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('REASSIGN_RECORD_GENERATE_ERROR', 'WeChat', '系统计算分配文件过程出现异常，流程已中止'),
            this.detailDataSvc.messageSvc.getMessageWithDefault('NONE', 'Common', '无')
        ]);
        this.confirmMsgs = [this.confirmAbortMsg];
        this.allSteps = [
            { label: this.preCrmDataGetStepMsg, value: 0, info: this.preCrmDataMsg},
            { label: this.curCrmDataGetStepMsg, value: 1, info: this.curCrmDataMsg},
            { label: this.curWecomDataGetStepMsg, value: 2, info: this.curWecomDataMsg},
            { label: this.dataGenerateStepMsg, value: 3},
            { label: this.generateFinishStepMsg, value: 4}
        ];
        this.setResultContainerWidth();
    }

    setResultContainerWidth() {
        const progressBarContainer = this.template.querySelector(".detail-process-container");
        const resultContainerWidth = progressBarContainer.getBoundingClientRect().width;
        progressBarContainer.style.maxWidth = `${resultContainerWidth}px`;
        progressBarContainer.style.overflowX = 'scroll';
        this.widthIsSet = true;
    }

    async getProcessStatus() {
        const calculationStatus = await this.detailDataSvc.getCalculationStatus(this.detailProcessId);
        if (calculationStatus) {
            this.processStatus = calculationStatus.processStatus;
            this.calculationSteps = calculationStatus.steps || [];
            if (this.isFailed) {
                this.openAlertDialog(this.processExceptionMsg);
            }
        }
    }

    clickStopBtn() {
        this.showConfirmDialog = true;
    }

    closeConfirmDialog() {
        this.showConfirmDialog = false;
    }

    closeAlertDialog() {
        this.showAlertDialog = false;
        if (this.isFailed) {
            this.goToSummary();
        }
    }

    openAlertDialog(msg) {
        this.alertMsgs = [msg];
        this.showAlertDialog = true;
    }

    goToSummary() {
        this.dispatchEvent(new CustomEvent('changed', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: {status: 'summary'}
            }
        })); 
    }

    async stopCalculation() {
        this.showConfirmDialog = false;
        this.waiting = true;
        const response = await this.detailDataSvc.doCalculationActon('stop'); 
        this.waiting = false;
        if (response && response.actionFeedBack === 'ACCEPTED') {
            this.goToSummary();
        } else {
            // Get process status immediately to get the latest status.
            if (this.inProcessing) {
                this.getProcessStatus();        
            }
            this.openAlertDialog(this.processCannotCancelMsg);
        }
    }

    selectValidRecord() {
        this.resultType = 'validRecord';
    }

    selectWeComDeleteUser() {
        this.resultType = 'weComDeleteUser';
    } 

    async downloadResult() {
        this.waiting = true;
        const path = `/comparison/${this.detailProcessId}/calculation-result`;
        const result = await this.detailDataSvc.getFileDataWithName(path, `application/zip`);
        if (result) {
            const [blob, name] = result
            ReassignmentDataService.saveBlob(blob, name);
        }
        this.waiting = false;
    }
}