/* eslint-disable @lwc/lwc/no-inner-html */
import { LightningElement, track, api } from "lwc";
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import VeevaConstant from 'c/veevaConstant';

export default class veevaEMViewNextSteps extends LightningElement {

    @api objectApiName;
    @api recordId;

    @track pageCtrl;
    @track nextStepsText;
    @track nextStepsTitle;

    connectedCallback() {
        registerListener(VeevaConstant.PUBSUB_LAYOUT_READY, this.handleLayoutReady, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    async handleLayoutReady(pageCtrl) {
        this._setPageCtrl(pageCtrl);
        this.nextStepsText = pageCtrl.nextStepsContent;
        this.nextStepsTitle = pageCtrl.nextStepsTitle;
        this.setHTML();
    }

    renderedCallback() {
        this.setHTML();
    }

    setHTML() {
        const attachmentPoint = this.template.querySelector('.htmlContainer');
        if(attachmentPoint) {
            attachmentPoint.innerHTML = this.nextStepsText;
            this._innerHTMLSet = true;
        }
    }

    _setPageCtrl(pageCtrl) {
        if (!this.pageCtrl) {
            this.pageCtrl = pageCtrl;
        }
    }
}