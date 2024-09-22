import { api, LightningElement } from 'lwc';

export default class EmPopover extends LightningElement {

    @api nubbin;
    @api size;
    @api type = 'panel';
    @api fadeIn = false;

    get isPrompt() {
        return this.type === 'prompt';
    }

    get popoverClass() {
        let css = `em-popover slds-popover slds-popover_${this.type}`;
        if (this.size) {
            css += ` slds-popover_${this.size}`;
        } else {
            css += ' em-popover_size-hook';
        }
        if (this.nubbin) {
            css += ` slds-nubbin_${this.nubbin}`;
        }
        if (this.type === 'prompt') {
            css += ' em-prompt-top-center';
        }
        if (this.fadeIn) {
            css += ' fade-in';
        }
        return css;
    }

    close() {
        this.dispatchEvent(new CustomEvent('close'));
    }

}