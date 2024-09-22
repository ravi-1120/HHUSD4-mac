import { api, LightningElement } from 'lwc';

export default class S4lBulletedListAlert extends LightningElement {

    @api title;

    @api message;
    @api listItems;

    @api cancelLabel;
    @api continueLabel;

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleContinue() {
        this.dispatchEvent(new CustomEvent('continue'));
    }

}