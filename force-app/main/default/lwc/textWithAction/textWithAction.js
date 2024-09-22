import { LightningElement, api } from 'lwc';

export default class TextWithAction extends LightningElement {
    @api text;
    @api actionLabel;
    @api action;
    @api recordId;

    actionHandler() {
        this.dispatchEvent(new CustomEvent('actionclicked', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { action: this.action, recordId: this.recordId }
            }
        }));
    }
}