import VeevaBaseSignatureModal from "c/veevaBaseSignatureModal";
import { api } from "lwc";
import { FlowAttributeChangeEvent,FlowNavigationNextEvent,} from 'lightning/flowSupport';

export default class VeevaReviewSignatureModal extends VeevaBaseSignatureModal {
    logoImg;
    signatureImg;
    selectedShareLink = false;
    selectedQrCode = false;
    @api requestAgainValue;
    @api cancelReviewValue;
    @api signatureFailedValue;
    @api signatureViewValue;
    @api signatureDateValue;
    @api selectedMethodValue;
    @api accountIdValue;
    @api groupIdValue;
    @api recordIdValue;
    @api objectApiValue;
    @api disclaimerValue;
    @api childIdsValue;
    isLogoAvailable = true;
    params;
    async connectedCallback() {
        this.params = {recordIdValue: this.recordIdValue, accountIdValue: this.accountIdValue, groupIdValue: this.groupIdValue}
        this.setSignatureController(this.objectApiValue);
        await super.connectedCallback();
        await this.signatureController.fetchMetadata(this.params);
        this.setLogo(this.signatureController.logo);
        this.signatureImg = this.signatureViewValue;
    }
    async buildSignatureMessageRequest() {
        this.msgRequest.addRequest('ACCEPT_ENGAGE', 'RemoteMeeting', 'Accept', 'acceptLabel');
        this.msgRequest.addRequest('REQUEST_AGAIN_ENGAGE', 'RemoteMeeting', 'Request Again', 'requestAgainLabel');
        this.msgRequest.addRequest('REVIEW_SIGNATURE_ENGAGE', 'RemoteMeeting', 'Review Signature', 'reviewSigLabel');
    }
    async handleNext() {
        await this.signatureController.acceptSignature(this.selectedMethodValue, this.recordIdValue, 
            this.signatureViewValue.replace('data:image/png;base64,',""), this.signatureDateValue, this.disclaimerValue, this.childIdsValue);
        await this.refreshRecord(this.recordIdValue);
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
    handleRequestAgain() {
        this.dispatchEvent(new FlowAttributeChangeEvent('requestAgainValue', true));
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
    handleCancel() {
        this.dispatchEvent(new FlowAttributeChangeEvent('cancelReviewValue', true));
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
    setLogo(image) {
        if (image) {
            this.logoImg = image;
        } else {
            this.isLogoAvailable = false;
        }
    }
}