import VeevaBaseSignatureModal from "c/veevaBaseSignatureModal";
import { api } from "lwc";
import {FlowAttributeChangeEvent,FlowNavigationNextEvent} from 'lightning/flowSupport';

export default class VeevaRequestSignatureModal extends VeevaBaseSignatureModal {
    title;
    mainMessage;
    secondMsg;
    isSigning = false;
    link;
    qrCodeSource;
    spinnerStyle = "spinner-relative spinner-margins";
    tenMinuteDifference = 600000;
    minuteDifference = 60000;
    params;
    @api errorEncounteredValue;
    @api exitRequestValue;
    @api reqSignatureFailed;
    @api recordIdValue;
    @api accountNameValue;
    @api accountIdValue;
    @api groupIdValue;
    @api objectApiNameValue;
    @api disclaimerValue;
    @api disclaimerHeaderValue;
    @api messageInvalidSignatureValue;
    @api signatureImgValue;
    @api signatureDateValue;
    @api signInIdValue;
    @api channelIdValue;
    @api recordTypeValue;
    @api selectedMethodValue;
    @api linkValue;
    async connectedCallback() {
        this.params = { accountIdValue: this.accountIdValue, accountNameValue: this.accountNameValue, groupIdValue: this.groupIdValue, 
            recordIdValue: this.recordIdValue, disclaimerValue: this.disclaimerValue, disclaimerHeaderValue: this.disclaimerHeaderValue, 
            messageInvalidSignatureValue: this.messageInvalidSignatureValue, recordTypeValue: this.recordTypeValue};
        this.setSignatureController(this.objectApiNameValue);
        await this.signatureController.fetchMetadata(this.params);
        await super.connectedCallback();
        await this.createChannelAndLink();
    }
    async buildSignatureMessageRequest() {
        this.msgRequest.addRequest('REQUESTING_ENGAGE', 'RemoteMeeting', 'Requesting...', 'requestingLabel');
        this.msgRequest.addRequest('PREPARING_REQUEST_ENGAGE', 'RemoteMeeting', 'A signature request is being prepared for {0}.', 'prepRequestLabel');
        this.msgRequest.addRequest('CANCEL_REQUEST_TITLE_ENGAGE', 'RemoteMeeting', 'Cancel Request', 'cancelRequestLabel');
        this.msgRequest.addRequest('SIGNING_ENGAGE', 'RemoteMeeting', 'Signing...', 'signingLabel');
        this.msgRequest.addRequest('WAITING_FOR_SIGNATURE_ENGAGE_ONLINE', 'RemoteMeeting', 'Waiting for {0} to complete the signing process.', 'waitForSignLabel');
        this.msgRequest.addRequest('SHARE_THIS_LINK_ENGAGE','RemoteMeeting','Share this link with the signee.', 'shareLinkMsgLabel');
        this.msgRequest.addRequest('COPY_LINK_ENGAGE', 'RemoteMeeting', 'Copy Link', 'copyLinkLabel');
        this.msgRequest.addRequest('QR_CODE', 'RemoteMeeting', 'QR Code', 'qrCodeLabel');
        this.msgRequest.addRequest('SCAN_QR_CODE', 'RemoteMeeting', 'Scan this QR code to sign using your own device', 'scanQrCodeLabel');
        this.msgRequest.addRequest('REQUEST_DETAILS', 'MEDICAL_INQUIRY', 'Request Details', 'requestDetailsLabel');
        this.msgRequest.addRequest('MED_INQ_ADDRESS', 'MEDICAL_INQUIRY', 'Address', 'addressLabel');
        this.msgRequest.addRequest('MED_INQ_FAX', 'MEDICAL_INQUIRY', 'Fax', 'faxLabel');
        this.msgRequest.addRequest('MED_INQ_PHONE', 'MEDICAL_INQUIRY', 'Phone', 'phoneLabel');
        this.msgRequest.addRequest('MED_INQ_EMAIL', 'MEDICAL_INQUIRY', 'Email', 'emailLabel');
    }
    setModalLabels() {
        if (this.selectedMethodValue === "shareLink") {
            this.title = this.signatureMessageMap.requestingLabel;
            this.mainMessage = this.signatureMessageMap.prepRequestLabel.replace('{0}', this.accountNameValue);
        } else {
            this.title = this.signatureMessageMap.qrCodeLabel;
            this.spinnerStyle = "spinner-relative";
            this.signatureController.isShareLink = false;
        }
    }
    async copyLinkToClipboard() {
        const linkTextArea = this.template.querySelector('.toCopy');
        linkTextArea.select();
        document.execCommand('copy');
    }
    cancelRequest() {
        // stop all polling
        this.signatureController.stopPollingEarly = true;
        if (this.signatureController.signInId) {
            this.dispatchEvent(new FlowAttributeChangeEvent('signInIdValue', this.signatureController.signInId));
        }
        if (this.signatureController.channelId) {
            this.dispatchEvent(new FlowAttributeChangeEvent('channelIdValue', this.signatureController.channelId));
        }
        const attribChange = new FlowAttributeChangeEvent('exitRequestValue', true);
        this.dispatchEvent(attribChange);
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    async createChannelAndLink() {
        try {
            await this.signatureController.createChannelAndLink(this.recordIdValue, this.linkValue, this.channelIdValue);
            this.dispatchEvent(new FlowAttributeChangeEvent('linkValue', this.signatureController.link));
            if (this.signatureController.isQrLoaded) {
                if (this.signatureController.qrCodeResult) {
                    this.qrCodeSource = this.signatureController.qrCodeResult;
                } else {
                    this.connectionLostError(this.createChannelAndLink);
                }
            }
            this.signatureController.errorTimeout = null;
            this.isSigning = true;
            if (this.signatureController.isShareLink) {
                this.title = this.signatureMessageMap.signingLabel;
                this.mainMessage = this.signatureMessageMap.waitForSignLabel.replace('{0}', this.accountNameValue);
                this.secondMsg = this.signatureMessageMap.shareLinkMsgLabel;
                this.spinnerStyle = "spinner-relative";
            }
            this.pollingStartTime = new Date().getTime();
            this.pollForChannel();
        } catch (e) {
            this.connectionLostError(this.createChannelAndLink);
        }
    }
    async pollForChannel() {
        try {
            if (!this.signInIdValue) {
                await this.signatureController.pollForChannel(this.channelIdValue);
            }
           this.signatureSendRequest();
        } catch(e) {
            if (!this.signatureController.stopPollingEarly) {
                this.connectionLostError(this.pollForChannel);
            }
        }
    }
    connectionLostError(retryFunction) {
        if (!this.signatureController.errorTimeout) {
            this.signatureController.errorTimeout = new Date().getTime();
            const attribChange= new FlowAttributeChangeEvent('errorEncounteredValue', true);
            this.dispatchEvent(attribChange);
            this.dispatchEvent(new FlowNavigationNextEvent());
        } else if (new Date().getTime() - this.signatureController.errorTimeout > this.minuteDifference) {
                // show signature failed error
                this.failedSignature();
        } else {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            window.setTimeout(retryFunction, 1000);
        }
    }
    async signatureSendRequest() {
        try {
            this.params.deliveryLabels = {'requestDetailsLabel': this.signatureMessageMap.requestDetailsLabel, 
                'addressLabel': this.signatureMessageMap.addressLabel, 'Email_vod': this.signatureMessageMap.emailLabel, 
                'Phone_vod': this.signatureMessageMap.phoneLabel, 'Fax_vod': this.signatureMessageMap.faxLabel}
            if (!this.signInIdValue) {
                await this.signatureController.signatureSendRequest(this.params);
            }
            this.pollForSignature(this.signInIdValue);
        } catch(e) {
            this.connectionLostError(this.signatureSendRequest);
        }
    }

    async pollForSignature(signInIdValue) {
        try {
            const result = await this.signatureController.pollForSignature(signInIdValue);
            if (result.data.sigStatus === 'FAILED' || result.data.sigStatus === 'DECLINED') {
                this.failedSignature();
            } else {
                // if successfully received, move on to next event
                this.dispatchEvent(new FlowAttributeChangeEvent('signatureImgValue', result.data.signature));
                this.dispatchEvent(new FlowAttributeChangeEvent('signatureDateValue', new Date().getTime().toString()));
                this.dispatchEvent(new FlowNavigationNextEvent());
            }
            
        } catch(e) {
            if (!this.stopPollingEarly) {
                this.connectionLostError(this.pollForSignature);
            }
        }

    }
    failedSignature() {
        const attribChange = new FlowAttributeChangeEvent('reqSignatureFailed', true);
        this.dispatchEvent(attribChange);
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}