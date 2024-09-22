import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getService, SERVICES } from "c/veevaServiceFactory";
import VeevaToastEvent from 'c/veevaToastEvent';
import SPEAKER_EMAIL_FIELD from '@salesforce/schema/EM_Speaker_vod__c.Email_vod__c';
import SPEAKER_PORTAL_ACCOUNT_CREATION_DATE_FIELD from '@salesforce/schema/EM_Speaker_vod__c.Portal_Account_Creation_Date_vod__c';
import SPEAKER_ID_FIELD from '@salesforce/schema/EM_Speaker_vod__c.Id';
import SPEAKER_SEND_SPEAKER_REGISTRATION_EMAIL_FIELD from '@salesforce/schema/EM_Speaker_vod__c.Send_Speaker_Registration_Email_vod__c';

export default class EmSendSpeakerRegistration extends LightningElement {

  @api recordId;
  @track messageMap = {};
  @track speakerData;

  @wire(getRecord, { recordId: '$recordId', fields: [SPEAKER_EMAIL_FIELD, SPEAKER_PORTAL_ACCOUNT_CREATION_DATE_FIELD] })
  async wiredObjectDetails({ error, data }) {
      if (data) {
          this.speakerData = data;
      } else if (error) {
        this.dispatchEvent(VeevaToastEvent.error(error));
        this.dispatchEvent(new CloseActionScreenEvent());
      }
  }

  connectedCallback() {
    this.getMessages();
  }

  async getMessages() {
    const messageService = getService(SERVICES.MESSAGE);
    const msgRequest = messageService.createMessageRequest();
    msgRequest.addRequest('REGISTRATION_BUTTON_CONFIRMATION', 'SPEAKER_PORTAL', 'A registration email will be sent to {0}. Do you wish to continue?', 'registrationButtonConfirmationLabel');
    msgRequest.addRequest('REGISTRATION_BUTTON_CONFIRMATION_NULL', 'SPEAKER_PORTAL', 'There is no email entered for this speaker. Please enter a valid email address to continue.', 'registrationButtonConfirmationNullLabel');
    msgRequest.addRequest('REGISTRATION_EMAIL_SUCCESS', 'SPEAKER_PORTAL', 'Your request to send a registration email is being processed.', 'registrationEmailSuccessLabel');
    msgRequest.addRequest('REGISTRATION_EMAIL_HAVE_EXISTING_ACCOUNT', 'SPEAKER_PORTAL', 'A speaker portal account already exists for this speaker. A registration email will not be sent.', 'registrationEmailHaveExistingAccountLabel');
    msgRequest.addRequest('OK', 'Common', 'OK', 'okLabel');
    msgRequest.addRequest('YES', 'Common', 'Yes', 'yesLabel');
    msgRequest.addRequest('NO', 'Common', 'No', 'noLabel');
    this.messageMap = await msgRequest.sendRequest();
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  handleSubmit() {
    const fields = {};
    fields[SPEAKER_ID_FIELD.fieldApiName] = this.recordId;
    fields[SPEAKER_SEND_SPEAKER_REGISTRATION_EMAIL_FIELD.fieldApiName] = true;
    const recordInput = { fields };
    updateRecord(recordInput).then(() => {
      this.dispatchEvent(VeevaToastEvent.successMessage(this.messageMap.registrationEmailSuccessLabel));
      this.dispatchEvent(new CloseActionScreenEvent());
    })
    .catch(error => {
      this.dispatchEvent(VeevaToastEvent.error(error));
      this.dispatchEvent(new CloseActionScreenEvent());
    });
  }

  get loading() {
    return !this.speakerData || Object.keys(this.messageMap).length === 0;
  }

  get errorScreen() {
    return !getFieldValue(this.speakerData, SPEAKER_EMAIL_FIELD) || getFieldValue(this.speakerData, SPEAKER_PORTAL_ACCOUNT_CREATION_DATE_FIELD);
  }

  get message() {
    let message = '';
    if (getFieldValue(this.speakerData, SPEAKER_PORTAL_ACCOUNT_CREATION_DATE_FIELD)) {
      message = this.messageMap.registrationEmailHaveExistingAccountLabel;
    } else if (!getFieldValue(this.speakerData, SPEAKER_EMAIL_FIELD)) {
      message = this.messageMap.registrationButtonConfirmationNullLabel;
    } else {
      message = this.messageMap.registrationButtonConfirmationLabel || '';
      message = message.replace('{0}', getFieldValue(this.speakerData, SPEAKER_EMAIL_FIELD));
    }
    return message;
  }
}