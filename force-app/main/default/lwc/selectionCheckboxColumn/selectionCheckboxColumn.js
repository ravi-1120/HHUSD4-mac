import { api, LightningElement } from 'lwc';

export default class SelectionCheckboxColumn extends LightningElement {

    @api typeAttributes;
    @api checked;

    handleChange(event) {
        this.dispatchEvent(new CustomEvent('customrowselection', {
            detail: {
                id: this.typeAttributes.id,
                checked: event.detail.checked
            },
            bubbles: true,
            composed: true
        }));
    }
}