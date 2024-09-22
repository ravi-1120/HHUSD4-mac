/* eslint-disable @lwc/lwc/no-inner-html */

import { api, wire, LightningElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCampaignEmailPreviewData from '@salesforce/apex/AeCampaignEmailPreviewController.getCampaignEmailPreviewData';
import { getService } from 'c/veevaServiceFactory';
import addClassSpecifierToHtml from './htmlStyleFormatter';

const FIELDS=['Campaign_Activity_vod__c.Name'];

export default class aeCampaignEmailPreview extends LightningElement{
    @api recordId;
    documentName;
    documentId;
    isWaiting;
    showEmptyDesert;
    noTemplateMessage;
    linkUnaccessibleMessage;
    initialize = true;

    setValues(htmlValue, documentName, documentId) {
      this.documentName = documentName;
      this.documentId = documentId;
      this.attachmentPoint = this.template.querySelector('.htmlContainer');
      this.attachmentPoint.innerHTML = htmlValue;
    }
    
    async initComponent() {
      this.initialize = false;
      this.showEmptyDesert = false;
      await this.initMessages();
      this.template.addEventListener('click', this.handleClickEvent.bind(this));
    }

    async initMessages() {
      const messageSvc = getService('messageSvc');
      const messageRequest = messageSvc.createMessageRequest();
      messageRequest.addRequest('EMAIL_TEMPLATE_UNAVAILABLE', 'ApprovedEmail', 'Email template unavailable', 'noTemplateMessage');
      messageRequest.addRequest('APPROVED_EMAIL_URL_NOT_AVAILABLE', 'ApprovedEmail', 'Link is not accessible', 'linkUnaccessibleMessage');
      const messageMap = await messageRequest.sendRequest();
      this.noTemplateMessage = messageMap.noTemplateMessage;
      this.linkUnaccessibleMessage = messageMap.linkUnaccessibleMessage;
    }

    handleClickEvent(event) {
      if(event.target?.tagName?.toLowerCase() === 'a' || event.target?.parentElement?.tagName?.toLowerCase() === 'a') {
        event.preventDefault();
        this.dispatchEvent(
          new ShowToastEvent({
            variant: 'warning',
            message: this.linkUnaccessibleMessage,
          })
        );
      }
    }

    async updateComponent() {
      this.isWaiting = true;
      if(this.initialize) {
        await this.initComponent();
      }
      this.setValues("","","");
      if (this.recordId != null) {
        try {
          const response = await getCampaignEmailPreviewData({ recordId: this.recordId });
          if(response != null && response.length === 3 && response[0] !== '') {
            const html = addClassSpecifierToHtml(response[0], '.htmlContainer');
            this.setValues(html, response[1], response[2]);
            this.showEmptyDesert = false;
          }
          else {
            this.showEmptyDesert = true;
          }
        }
        catch(error){
          this.showEmptyDesert = true;;
        }
      }
      this.isWaiting = false;
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
      if(error) {
        this.setValues("","","");
      }
      else if (data) {
        this.updateComponent();
      }
    }
}