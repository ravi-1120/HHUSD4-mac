import { LightningElement, api } from 'lwc';

export default class ReassignmentPageHeader extends LightningElement {

    @api pageStatus;
    @api pageDataSvc;

    showDialog = false;
    showConfirmationDialog = false;
    msgLoaded = false;

    // veeva messages
    pageTitle;
    calculationMsg;
    uploadFileMsg;
    alertMsg;
    returnToPrevious;
    reassignRecordGenerateAlertMsg;

    get inSummary(){
        return this.pageStatus === 'summary';
    }

    get inDetail(){
        return this.pageStatus === 'detail';
    }

    async connectedCallback() {
        await this.initMessages();
    }

    async initMessages() {
        const {messageSvc} = this.pageDataSvc;
        [this.pageTitle, this.calculationMsg, this.uploadFileMsg, this.alertMsg, this.returnToPrevious, this.reassignRecordGenerateAlertMsg] = 
        await Promise.all([
            messageSvc.getMessageWithDefault('EXUSER_REASSIGNMENT', 'WeChat', '外部联系人重新分配'),
            messageSvc.getMessageWithDefault('REASSIGN_RECORD_GENERATE', 'WeChat', '系统计算分配文件'),
            messageSvc.getMessageWithDefault('IMPORT_EXUSER_REASSIGNMENT_FILE', 'WeChat', '导入最新分配文件'),
            messageSvc.getMessageWithDefault('ONGOING_REASSIGNMENT_JOB_ALERT', 'WeChat', '外部联系人分配中或计算中，请稍候'),
            messageSvc.getMessageWithDefault('RETURN_MESSAGE', 'Common', '返回前一页'),
            messageSvc.getMessageWithDefault('REASSIGN_RECORD_GENERATE_ALERT', 'WeChat', '是否确定开始系统计算分配文件，可能需要等待一段时间'),
        ]);
        this.alertMessages = [this.alertMsg];
        this.confirmationMessages = [this.reassignRecordGenerateAlertMsg];
        this.returnToPrevious = `<< ${this.returnToPrevious}`;
        this.msgLoaded = true;
    }

    goToSummary (){
        this.dispatchEvent(new CustomEvent('changed', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: {status: 'summary'}
            }
        }));
    }

    closeDialog () {
        this.showDialog = false;
    }

    async goToUpload () {
        const allowToUpload = await this.pageDataSvc.checkAllowToUpload(); 
        if (allowToUpload) {
            this.dispatchEvent(new CustomEvent('changed', {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {
                    data: {status: 'uploading'}
                }
            }));
        } else {
            this.showDialog = true;
        }    
    }

    async goToCalculate() {
        const allowToCalculate = await this.pageDataSvc.checkAllowToCalculate(); 
        if (allowToCalculate) {
            this.showConfirmationDialog = true;
        } else {
            this.showDialog = true;
        }    
    }

    async confirmCalculate () {
        this.showConfirmationDialog = false;
        const response = await this.pageDataSvc.doCalculationActon('start'); 
        if (response && response.processId) {
            this.dispatchEvent(new CustomEvent('changed', {
                composed: true,
                bubbles: true,
                cancelable: true,
                detail: {
                    data: {status: 'detail', recordId: response.processId}
                }
            }))
        } else {
            this.showDialog = true;
        }    
    }

    cancelCalculate() {
        this.showConfirmationDialog = false;
    }
}