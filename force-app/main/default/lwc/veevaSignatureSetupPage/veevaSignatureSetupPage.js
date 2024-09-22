import { api, wire} from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { MessageContext } from 'lightning/messageService';
import MEDICAL_INQUIRY from '@salesforce/schema/Medical_Inquiry_vod__c';
import LOCATION from '@salesforce/schema/Medical_Inquiry_vod__c.Location_vod__c';
import VeevaBaseSignatureModal from 'c/veevaBaseSignatureModal';
import {FlowAttributeChangeEvent, FlowNavigationNextEvent,} from 'lightning/flowSupport';

export default class VeevaSignatureSetupPage extends VeevaBaseSignatureModal {

    @wire(MessageContext)
    messageContext;
    signatureMethods = [];
    metadata;
    displayAccountName;
    @api objectApiNameValue;
    @api recordIdValue;
    @api exitSetupValue;
    @api setupConnectionErrorValue;
    @api shareLinkFlsValue;
    @api qrCodeFlsValue;
    @api groupIdValue;
    @api accountIdValue;
    @api messageInvalidSignatureValue;
    @api disclaimerValue;
    @api disclaimerHeaderValue;
    @api accountNameValue;
    @api selectedMethodValue;
    @api childIdsValue;
    prodLogo;
    isLogoLoading = true;
    isLogoAvailable = true;
    params;

    @wire(getObjectInfo, { objectApiName: MEDICAL_INQUIRY })
    wireObjectInfo(result) {
        if (result.data) {
            this.locationNameLabel = result.data.fields[LOCATION.fieldApiName]?.label;
        }
    }

    async connectedCallback() {
        super.connectedCallback();
        this.params = { recordIdValue: this.recordIdValue, groupIdValue: this.groupIdValue, accountIdValue: this.accountIdValue};
        this.setSignatureController(this.objectApiNameValue);
        await this.signatureController.fetchMetadata(this.params);
        this.disclaimerLanguage = this.signatureController.disclaimerLanguage;
        this.displayAccountName = (this.signatureController.salutation ? `${this.signatureController.salutation} ` : "") + this.accountNameValue + (this.signatureController.credentials ? `, ${this.signatureController.credentials}` : "");
        this.displayLocationName = this.signatureController.signaturePageLocationName || '';
        if (this.signatureController.childIds) {
            this.dispatchAttrib("childIdsValue", this.signatureController.childIds.join())
        }
        this.setLogo(this.signatureController.logo);
        this.setSignatureOptions();
    }
    async buildSignatureMessageRequest() {
        this.msgRequest.addRequest('SIGNATURE_SET_UP','Common','Signature Set Up', 'signatureSetUpLabel');
        this.msgRequest.addRequest('DISPLAY_IMAGE', 'Common', 'Display Image', 'displayImageLabel');
        this.msgRequest.addRequest('ACCOUNT_DETAILS', 'iPad', 'Account Details', 'accountDetailsLabel');
        this.msgRequest.addRequest('SAMPLE_RECEIPT_GROUP_TYPE', 'SAMPLES_MGMT', 'Receipt', 'sampleReceiptLabel');
        this.msgRequest.addRequest('TITLE_SIGNATURE_METHOD', 'RemoteMeeting', 'Signature Method', 'signatureMethodLabel');
        this.msgRequest.addRequest('SHARE_LINK_SIGNATURE_METHOD', 'RemoteMeeting', 'Share Link', 'shareLinkLabel');
        this.msgRequest.addRequest('QR_CODE', 'RemoteMeeting', 'QR Code', 'qrCodeLabel');
        this.msgRequest.addRequest('CANCEL_ENGAGE', 'RemoteMeeting', 'Cancel', 'cancelLabel');
        this.msgRequest.addRequest('NEXT', 'Common', 'Next', 'nextLabel');
        this.msgRequest.addRequest('LANGUAGE', 'Common', 'Language', 'languageLabel');
        this.msgRequest.addRequest('SIGNEE', 'Common', 'Signee', 'signeeLabel');
    }
    selectMethod(event) {
        if (event.detail.value === "shareLink") {
            this.dispatchAttrib("selectedMethodValue", "shareLink");
        }
        else {
            this.dispatchAttrib("selectedMethodValue", "qrCode");
        }
    }
   async handleNext() {
    await this.next();
    this.dispatchEvent(new FlowNavigationNextEvent());
   }
   async next() {
    try {
        const result = await this.signatureController.next(this.disclaimerLanguage, this.objectApiNameValue);
        this.dispatchAttrib('disclaimerValue', result.disclaimer);
        this.dispatchAttrib('disclaimerHeaderValue', result.disclaimerHeader);
        this.dispatchAttrib('messageInvalidSignatureValue', result.errorMessage);

    } catch (e) {
        this.dispatchAttrib('setupConnectionErrorValue', true);
    }
    }
   async handleClose() {
       this.dispatchAttrib('exitSetupValue', true);
       this.dispatchEvent(new FlowNavigationNextEvent());
   }
   dispatchAttrib(variable, value) {
       const attrib = new FlowAttributeChangeEvent(variable, value);
       this.dispatchEvent(attrib);
   }
   selectLanguage(event) {
       this.disclaimerLanguage = event.detail.value;
   }
   setSignatureOptions() {
       const signatureOptions = [];
       if (this.shareLinkFlsValue) {
           signatureOptions.push( {
               label: this.signatureMessageMap.shareLinkLabel,
               value: "shareLink"
           })
           this.signatureValue = "shareLink";
       }
       if (this.qrCodeFlsValue) {
           signatureOptions.push({
               label: this.signatureMessageMap.qrCodeLabel,
               value: "qrCode"
           });
           if (!this.signatureValue) {
               this.signatureValue = "qrCode";
            }
       }
       this.signatureMethods = signatureOptions;
       this.dispatchAttrib('selectedMethodValue', this.signatureValue);
   }
   setLogo(image) {
       if (image) {
           this.prodLogo = image;
       } else {
           this.isLogoAvailable = false;
       }
       this.isLogoLoading = false;
   }
}