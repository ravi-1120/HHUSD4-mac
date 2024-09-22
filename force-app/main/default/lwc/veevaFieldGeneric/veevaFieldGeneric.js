import { LightningElement, api, track } from "lwc";

import { getService, SERVICES } from 'c/veevaServiceFactory';

export default class VeevaFieldGeneric extends LightningElement {
    @api ctrl;
    @api labelHidden;
    @track helpAlternativeText = '';

    messageService = getService(SERVICES.MESSAGE);

    get hideLabel() {
        return this.labelHidden || this.ctrl.meta?.labelHidden;
    }

    async connectedCallback() {
        // field displayed in subtitle does not require slds-form-element__static styling
        // Otherwise the font height and weight from slds-form-element__static are overriding the parent styles 
        if(!this.ctrl.meta?.subtitle) { 
            if (this.ctrl.actionView) {
                this.sldsText = 'slds-form-element__static';
            }
            else {
                this.sldsText = 'slds-form-element__static slds-p-top_xx-small';
            }
        }

        const helpMessage = await this.messageService.getMessageWithDefault('HELP', 'COMMON', 'Help');

        this.helpAlternativeText = `${helpMessage} ${this.ctrl.meta?.label}`;
    }
}