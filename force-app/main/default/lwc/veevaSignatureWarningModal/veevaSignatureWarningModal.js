import {api} from "lwc";
import VeevaBaseSignatureModal from "c/veevaBaseSignatureModal";
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class VeevaSignatureWarningModal extends VeevaBaseSignatureModal {
    isWarning;
    isCancel;
    isRequestAgain;
    isGoBack;

    @api warningType;
    @api goBackValue;
    @api goAnywayValue;
    @api cancelReviewValue;
    @api cancelRequestAgainValue;
    @api requestAgainErrorValue;
    @api signInIdValue;
    @api channelIdValue;
    @api recordIdValue;
    
    @api linkValue;
    async connectedCallback() {
        super.connectedCallback();
        this.setSignatureController("signatureController");
    }
    async buildSignatureMessageRequest() {
        if (this.warningType === "cancelRequest") {
            this.msgRequest.addRequest('CANCEL_REQUEST_TITLE_ENGAGE', 'RemoteMeeting', 'Cancel Request', 'cancelRequestLabel');
            this.msgRequest.addRequest('CONFIRM_CANCEL_SIGNATURE_ENGAGE', 'RemoteMeeting', 'Are you sure you want to cancel?  The signee will lose progress.', 'confirmCancelLabel');
            this.msgRequest.addRequest('GO_BACK', 'Common', 'Go Back', 'goBackLabel');
        }
        else {
            this.msgRequest.addRequest('WARNING_ENGAGE', 'RemoteMeeting', 'Warning', 'warningLabel');
            this.msgRequest.addRequest('CANCEL_ENGAGE', 'RemoteMeeting', 'Cancel', 'cancelLabel');
            if (this.warningType === "goBack") {
                this.msgRequest.addRequest('GO_ANYWAY', 'Common', 'Go Anyway', 'goAnywayLabel');
                this.msgRequest.addRequest('BACK_SIGNATURE_LOST_ENGAGE', 'RemoteMeeting', 'If you go back, the captured signature will be lost.', 'backSigLabel');
            }
            else {
                this.msgRequest.addRequest('REQUEST_AGAIN_ENGAGE', 'RemoteMeeting', 'Request Again', 'requestAgainLabel');
                this.msgRequest.addRequest('REQUEST_AGAIN_CONFIRM_ENGAGE', 'RemoteMeeting', 'If you request again, the captured signature will be lost.', 'requestAgainConfirmLabel');
            }
        }
    }
    setModalLabels() {
        if (this.warningType === "cancelRequest") {
            this.title = this.signatureMessageMap.cancelRequestLabel;
            this.message = this.signatureMessageMap.confirmCancelLabel;
            this.isCancel = true;
        }
        else {
            if (this.warningType === "goBack") {
                this.message = this.signatureMessageMap.backSigLabel;
                this.isGoBack = true;
            }
            else {
                this.message = this.signatureMessageMap.requestAgainConfirmLabel
                this.isRequestAgain = true;
            }
            this.title = this.signatureMessageMap.warningLabel;
            this.isWarning = true;
        }
    }
    async goNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
    async handleCancel() {
        this.cancelRequests();
        this.goNext();
    }
    async handleGoAnyway() {
        this.dispatchEvent(new FlowAttributeChangeEvent('goAnywayValue', true));
        await this.cancelRequests();
        this.clearRequestValues();
        this.goNext();
    }
    handleGoBack() {
        this.dispatchEvent(new FlowAttributeChangeEvent('goBackValue', true));
        this.goNext();
    }
    async cancelRequests() {
        if (this.channelIdValue) {
            await this.signatureController.closeChannel(this.channelIdValue);
        }
        if (this.signInIdValue) {
            await this.signatureController.cancelEngageRequest(this.signInIdValue);
        }
    }
    async handleRequestAgain() {
        try { 
            await this.cancelRequests();
            this.clearRequestValues();
            this.dispatchEvent(new FlowAttributeChangeEvent('cancelRequestAgainValue', true));
            this.dispatchEvent(new FlowNavigationNextEvent());
        } catch (e) {
            this.dispatchEvent(new FlowAttributeChangeEvent('requestAgainErrorValue', true));
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
    }
    clearRequestValues() {
        this.dispatchEvent(new FlowAttributeChangeEvent('linkValue', ''));
        this.dispatchEvent(new FlowAttributeChangeEvent('signInIdValue', ''));
        this.dispatchEvent(new FlowAttributeChangeEvent('channelIdValue', ''));
    }
}