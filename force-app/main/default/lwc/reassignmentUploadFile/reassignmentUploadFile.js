import { LightningElement, api } from 'lwc';
import ReassignmentDataService from "c/reassignmentDataService";

const MAX_FILE_SIZE_10M = 10485760;

export default class ReassignmentUploadFile extends LightningElement {

    @api uploadDataSvc;

    fileName = '';
    fileUploaded;
    fileSize;
    exceedFileLimit = false;
    showDialog = false;
    uploadFailed = false;
    waiting = false;

    // messages
    title;
    helperText;
    exceedLimitError;
    downloadTmpMsg;
    startReassignmentMsg;
    uploadError;
    cancelLabel;
    confirmLabel;
    dialogMsg;
    templateName;

    async connectedCallback() {
        await this.initMessages();
    }

    async initMessages() {
        [this.title, this.helperText, this.exceedLimitError, this.downloadTmpMsg, this.startReassignmentMsg, this.uploadError, this.cancelLabel, this.dialogMsg, this.confirmLabel, this.templateName] 
        = await Promise.all([
            this.uploadDataSvc.messageSvc.getMessageWithDefault('UPLOAD_EXUSER_REASSIGNMENT_FILE', 'WeChat', '上传最新分配文件'),
            this.uploadDataSvc.messageSvc.getMessageWithDefault('EXUSER_TEMPLATE_DOWNLOAD_INSTRUCTION', 'WeChat', '请下载外部联系人分配文件模板，按照模板调整后导入'),
            this.uploadDataSvc.messageSvc.getMessageWithDefault('ONLY_SUPPORT_10M', 'WeChat', '只支持10M以内的文件'),
            this.uploadDataSvc.messageSvc.getMessageWithDefault('TEMPLATE_DOWNLOAD', 'WeChat', '下载模板'),
            this.uploadDataSvc.messageSvc.getMessageWithDefault('START_REASSIGNMENT', 'WeChat', '开始分配'),
            this.uploadDataSvc.messageSvc.getMessageWithDefault('UPLOAD_ERROR_REMINDER', 'WeChat', '上传过程出错，请重新上传文件后重试'),
            this.uploadDataSvc.messageSvc.getMessageWithDefault('CANCEL', 'Common', '取消'),
            this.uploadDataSvc.messageSvc.getMessageWithDefault('REASSIGNMENT_CANCEL_CONFIRMATION', 'WeChat', '确认取消?'),
            this.uploadDataSvc.messageSvc.getMessageWithDefault('OK', 'Common', '确定'),
            this.uploadDataSvc.messageSvc.getMessageWithDefault('EXUSER_REASSIGNMENT_FILE_TEMPLATE', 'WeChat', '外部联系人分配模板')
        ]);
        this.messages = [this.dialogMsg];
    }

    async downloadTemplate() {
        this.waiting = true;
        const file = await this.uploadDataSvc.getFileData(`/template`);
        this.waiting = false;
        ReassignmentDataService.saveBlob(file, `${this.templateName}.csv`);
    }

    handleFileChange(event) {
        if(event.target.files.length > 0) {
            this.initFileInfo();
            if (this.checkFile(event.target.files[0])) {
                [this.fileUploaded] = event.target.files;
                this.fileName = this.fileUploaded.name;
                this.fileSize = ReassignmentUploadFile.formatBytes(this.fileUploaded.size)
            } 
        }
    }

    initFileInfo () {
        this.uploadFailed = false;
        this.exceedFileLimit = false;
        this.fileUploaded = null;
        this.fileName = '';
        this.fileSize = 0;
    }

    checkFile (file) {
        const fileName = file.name;
        const nameArr = fileName.split('.')
        const fileExtension = `.${nameArr[nameArr.length - 1].toLowerCase()}`
        if (fileExtension !== '.csv' || file.size === 0) {
            this.uploadFailed = true;
            return false;
        }
        if (file.size > MAX_FILE_SIZE_10M) {
            this.exceedFileLimit = true;
            return false;
        }
        return true;
    }

    static formatBytes(bytes) {
        const k = 1024;
        const dm = 2;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        const sizeNum = parseFloat((bytes / k**i).toFixed(dm))

        return `${sizeNum} ${sizes[i]}`;
    }

    async doReassignment() {
        this.uploadFailed = false;
        this.waiting = true;
        const response = await this.uploadDataSvc.doReassignment(this.fileUploaded)
        this.waiting = false;
        if (response) {
            this.goToSummary();
        } else {
            this.uploadFailed = true;
        }
    }

    goToSummary () {
        this.dispatchEvent(new CustomEvent('changed', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: {status: 'summary'}
            }
        }))
    }

    cancel(){
        if (this.fileName) {
            this.showDialog = true;
        } else {
            this.goToSummary();
        }
    }

    dialogCancel () {
        this.showDialog = false;
    }
}