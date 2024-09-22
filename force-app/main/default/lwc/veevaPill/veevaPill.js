import { api, LightningElement } from 'lwc';

export default class VeevaPill extends LightningElement {

    @api label;
    @api value;
    @api removable;
    @api icon;
    @api iconShape;
    @api variant;
    @api src;

    get canRemove() {
        return this.removable ?? true;
    }

    get pillClass() {
        let css = 'slds-pill';
        if (this.variant === 'round') {
            css += ' rounded';
        }
        return css;
    }

    get hasIcon() {
        return this.src || this.icon;
    }
    
    handleRemove() {
        this.dispatchEvent(new CustomEvent('remove', {
            detail: {
                value: this.value
            }
        }));
    }
}