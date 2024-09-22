import { LightningElement } from "lwc";
import { VeevaMessageRequest } from "c/veevaMessageService";
import { getService } from 'c/veevaServiceFactory';
import { getSignatureController } from 'c/veevaSignatureControllerFactory';
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";


export default class VeevaBaseSignatureModal extends LightningElement {
    msgRequest;
    messageSvc = getService('messageSvc');
    signatureMessageMap;
    hasLoadedMsg = false;
    signatureController;
    async connectedCallback() {
        this.msgRequest = new VeevaMessageRequest();
        this.buildSignatureMessageRequest();
        this.signatureMessageMap = await this.messageSvc.getMessageMap(this.msgRequest);
        this.setModalLabels();
        this.hasLoadedMsg = true;
    }
    buildSignatureMessageRequest() {
        // override in child
    }
    async setModalLabels() {
        // override in child
    }
    setSignatureController(name) {
        if (name) {
            this.signatureController = getSignatureController(name);
        }
    }
    async refreshRecord(recordId) {
        await notifyRecordUpdateAvailable([{recordId}]);
    }
}