import { api, LightningElement } from 'lwc';

export default class SelectionDetailsPopoverColumn extends LightningElement {

    @api typeAttributes;
    @api label;
    @api icon;

    handleClick(event) {
        const rect = event.target.getBoundingClientRect();
        this.dispatchEvent(new CustomEvent('openpopover', { 
            bubbles: true, 
            composed: true, 
            detail: { 
                record: {
                    id: this.typeAttributes.id,
                    name: this.label
                },
                x: rect.left + event.target.clientWidth,
                y: rect.top + event.target.clientHeight / 2
            }
        }));
    }
}