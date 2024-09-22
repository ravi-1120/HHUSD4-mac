import { LightningElement, track } from 'lwc';
import processApproval from '@salesforce/apex/PDS_DonationRequestController.processApproval';
import approvalMsg from '@salesforce/label/c.PDS_ApprovalSuccess';
import rejectedMsg from '@salesforce/label/c.PDS_ApprovalReject';
import invalidErrormsg from '@salesforce/label/c.PDS_ApprovalinvalidLink';

export default class PdsDonationApprovalProcess extends LightningElement {

    @track message = '';
    approved = false;
    rejected = false;

    connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        const status = urlParams.get('status');
        const recordId = urlParams.get('prid');

        if (status && recordId) {
            this.handleApprovalProcess(status, recordId);
        } else {
            this.message = invalidErrormsg;
        }
    }

    async handleApprovalProcess(status, recordId) {
        try {
            const result = await processApproval({ status, recordId });
            if (result == 'approve') {
                this.message = approvalMsg;
                this.approved = true;
            }else if (result == 'reject') {
                this.message = rejectedMsg;
                this.rejected = true;
            }else if (result == 'processed'){
                this.message = invalidErrormsg;
            }else {
                this.message = invalidErrormsg;
            }
            console.log('Result: '+ JSON.stringify(result));     
        } catch (error) {
            console.error('Process Error ' + error.body.message);
            this.message = invalidErrormsg;
        }
    }
}