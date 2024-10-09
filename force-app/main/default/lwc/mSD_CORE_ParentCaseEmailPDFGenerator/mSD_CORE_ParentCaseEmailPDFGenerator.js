import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generatePDFFromEmails from '@salesforce/apex/MSD_CORE_ParentCaseEmailPDFGenerator.generatePDFFromEmails';

export default class GenerateEmailPdf extends LightningElement {
    @api recordId;

    handleClick() {
        this.showToast('Processing', 'Generating PDF and processing attachments...', 'info');
        
        generatePDFFromEmails({ caseId: this.recordId })
            .then(result => {
                console.log('Debug Logs:', result.debugLogs);
                if (result.success) {
                    const message = this.formatMessage(result.message);
                    this.showToast('Success', message, 'success');
                    this.refreshView();
                } else {
                    this.showToast('Warning', result.message, 'warning');
                }
            })
            .catch(error => {
                console.error('Error in Apex call:', JSON.stringify(error));
                this.showToast('Error', 'An error occurred while processing: ' + error.body.message, 'error');
            });
    }

    formatMessage(message) {
        return `${message}
Please refresh the page to see the changes.`;
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }

    refreshView() {
        this.dispatchEvent(new CustomEvent('refreshview'));
    }
}