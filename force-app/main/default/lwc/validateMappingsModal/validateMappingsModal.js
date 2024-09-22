import { LightningElement, api } from 'lwc';

export default class ValidateMappingsModal extends LightningElement {
    @api size;
    @api modalMessageMap;
    @api ctrl;
    @api mappingToValidate;
    showReport = false;

    async handleOnClick() {
        this.dispatchEvent(new CustomEvent('download', { detail: this.ctrl.jobId }));
    }

    closeDialog() {
        if(this.showReport) {
            this.showReport = false;
            this.dispatchEvent(new CustomEvent('close'));
        }
    }

    get modalTitle() {
        let modalTitle;
        if(this.showReport){
            modalTitle = this.modalMessageMap.failedValidationTitle.replace('{0}', this.ctrl.errorCount ?? 0);;
        } else {
            modalTitle = this.modalMessageMap.validatingMappingsTitle;
        }
        return modalTitle;
    }

    @api get showDownloadReport() {
        return this.showReport;
    }

    set showDownloadReport(value) {
        this.showReport = value;
    }
}