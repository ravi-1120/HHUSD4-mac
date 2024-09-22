import { LightningElement, api, track } from 'lwc';

export default class PdsToastMessage extends LightningElement {

    @track type;
    @track message;
    @track showToastMsg = false;
    @api autoCloseTime = 1000;

    @api
    showToast(message) {
        this.message = message;
        this.showToastMsg = true;
        setTimeout(() => {
            this.closeModel();
        }, this.autoCloseTime);
    }

    label = {
        close: 'Close',
    }

    closeModel() {
        this.showToastMsg = false;
        this.message = '';
    }
}