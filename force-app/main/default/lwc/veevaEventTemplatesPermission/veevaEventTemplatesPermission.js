import { LightningElement, api } from 'lwc';
import { SERVICES, getService } from 'c/veevaServiceFactory';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import processNewChildEventRequest from '@salesforce/apex/VeevaEmEventTemplateService.processNewChildEventRequest';

export default class VeevaEventTemplatesPermission extends LightningElement {
  errorMessage;
  messageMap = {};

  // Input properties from flow
  @api parentEventId;

  // Output properties to flow
  @api exitEarly;
  @api eventRecordTypeId;
  @api eventRecordTypeDeveloperName;
  @api defaultFieldValues;

  connectedCallback() {
    this.init();
  }

  async init() {
    const [response] = await Promise.all([processNewChildEventRequest({ parentEventId: this.parentEventId }), this.getMessages()]);
    if (response.hasAccess) {
      this.eventRecordTypeId = response.eventRecordTypeId;
      this.eventRecordTypeDeveloperName = response.eventRecordTypeDeveloperName;
      this.defaultFieldValues = JSON.stringify(response.defaultFieldValues);
      this.dispatchEvent(new FlowNavigationNextEvent());
    } else if (!response.hasChildEventPermissions) {
      this.errorMessage = this.messageMap.noEventConfigLabel;
    } else if (response.noFLSEventFields) {
      this.errorMessage = this.messageMap.eventFieldsMissingLabel.replace('{0}', response.noFLSEventFields.join(', '));
    } else if (response.noFLSRelatedFields || response.noAccessRelatedObjects || response.noAccessRelatedRecordTypes) {
      this.errorMessage = this.messageMap.eventRelatedListMissingLabel
        .replace('{0}', response.noFLSRelatedFields?.join(', ') || '')
        .replace('{1}', response.noAccessRelatedObjects?.join(', ') || '')
        .replace('{2}', response.noAccessRelatedRecordTypes?.join(', ') || '');
    }
  }

  async getMessages() {
    this.messageMap = await getService(SERVICES.MESSAGE)
      .createMessageRequest()
      .addRequest('OK', 'Common', 'OK', 'okLabel')
      .addRequest(
        'NO_EVENT_CONFIG',
        'EVENT_MANAGEMENT',
        'You are not allowed to schedule this type of event during this time frame. Please contact your administrator.',
        'noEventConfigLabel'
      )
      .addRequest(
        'EVENT_FIELDS_MISSING',
        'EVENT_MANAGEMENT',
        'Unable to create the event because you are missing FLS for the following:\n\nObject Fields: {0}',
        'eventFieldsMissingLabel'
      )
      .addRequest(
        'EVENT_RELATED_LIST_MISSING',
        'EVENT_MANAGEMENT',
        'Unable to create the event because you are missing FLS for the following:\n\nObject Fields: {0}\n\nObjects: {1}\n\nRecord Types: {2}',
        'eventRelatedListMissingLabel'
      )
      .sendRequest();
  }

  exitFlow() {
    this.exitEarly = true;
    this.dispatchEvent(new FlowNavigationNextEvent());
  }
}