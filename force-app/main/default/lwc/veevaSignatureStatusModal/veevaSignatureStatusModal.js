import { api } from "lwc";
import SIGNATURE_FAILED_ICON from '@salesforce/resourceUrl/signature_failed_vod';
import SIGNATURE_CAPTURED_ICON from '@salesforce/resourceUrl/signature_captured_vod';
import VeevaBaseSignatureModal from "c/veevaBaseSignatureModal";
import {FlowNavigationNextEvent, FlowAttributeChangeEvent} from 'lightning/flowSupport';

export default class VeevaSignatureStatusModal extends VeevaBaseSignatureModal {
    showError = true;
    headerStyle = "error";
    
    icon = SIGNATURE_FAILED_ICON;
    title;
    message;
    @api type = "sigFailed";
    @api accountNameValue;
    @api channelIdValue;
    @api signInIdValue;
    @api linkValue;
    @api errorEncounteredValue;
    async connectedCallback() {
        super.connectedCallback();
        this.setSignatureController("signatureController");
        if (this.type === "sigFailed" || this.type === "connectionError") {
            await this.cancelRequests();
            this.dispatchEvent(new FlowAttributeChangeEvent('linkValue', ''));
            this.dispatchEvent(new FlowAttributeChangeEvent('signInIdValue', ''));
            this.dispatchEvent(new FlowAttributeChangeEvent('channelIdValue', ''));
            this.dispatchEvent(new FlowAttributeChangeEvent('errorEncounteredValue', ''));
        }
    }
    async buildSignatureMessageRequest() {
        this.msgRequest.addRequest('SIGNATURE_CAPTURE_FAILED_ENGAGE', 'RemoteMeeting', 'Signature Capture Failed', 'sigCaptureFailedLabel');
        this.msgRequest.addRequest('UNABLE_RECEIVE_SIGNATURE_ENGAGE', 'RemoteMeeting', 'Unable to retrieve the signature.  Please try again.', 'unableReceiveLabel');
        this.msgRequest.addRequest('ERROR', 'CallReport', 'Error', 'errorLabel');
        this.msgRequest.addRequest('ERROR_LOST_CONNECTION', 'CallReport', 'Your internet connection was lost. Connect and try again.', 'connectionLostLabel');
        this.msgRequest.addRequest('SIGNATURE_CAPTURED_ENGAGE', 'RemoteMeeting', 'Signature Captured!', 'sigCapturedLabel');
        this.msgRequest.addRequest('SIGNEE_HAS_SIGNED_ENGAGE', 'RemoteMeeting', '{0} has reviewed and signed.', 'hasSignedLabel');
    }
    setModalLabels() {
        let msg;
        if (this.type === "sigFailed") {
            this.title = this.signatureMessageMap.sigCaptureFailedLabel;
            msg = this.signatureMessageMap.unableReceiveLabel;
        }
        else if (this.type === "connectionError") {
            this.title = this.signatureMessageMap.errorLabel;
            msg = this.signatureMessageMap.connectionLostLabel;
        }
        else if (this.type === "sigCaptured") {
            this.title = this.signatureMessageMap.sigCapturedLabel;
            msg = this.signatureMessageMap.hasSignedLabel.replace('{0}', this.accountNameValue);
            this.headerStyle = "success";
            this.icon = SIGNATURE_CAPTURED_ICON;
        }
        this.message = [msg];
        if (this.headerStyle === "success") {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            window.setTimeout(() => {this.dispatchEvent(new FlowNavigationNextEvent())}, 2000);
        }
    }
    async cancelRequests() {
        if (this.channelIdValue) {
            await this.signatureController.closeChannel(this.channelIdValue);
        }
        if (this.signInIdValue) {
            await this.signatureController.cancelEngageRequest(this.signInIdValue);
        }
    }
    handleClose() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
    
}