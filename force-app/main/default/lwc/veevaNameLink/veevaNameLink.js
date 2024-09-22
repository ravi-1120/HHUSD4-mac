import { LightningElement, api } from 'lwc';

export default class VeevaNameLink extends LightningElement {
    @api recordId;
    @api name;
    @api veevaIcon = false;

    handleClick() {
        this.dispatchEvent(new CustomEvent('rowselection', {
            bubbles: true, composed: true, cancelable: true,
            detail: {
                selectedRows: [{id: this.recordId}]
            }            
        }));
    }
}