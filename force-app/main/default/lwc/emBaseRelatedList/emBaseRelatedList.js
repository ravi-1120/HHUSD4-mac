import { api, wire, track, LightningElement } from 'lwc';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import EmEventConstant from 'c/emEventConstant';
import VeevaUtils from 'c/veevaUtils';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';

const ADDITIONAL_META = {
  CombinedAttachments: {
    objectApiName: 'ContentDocument',
    veevaMessageLabel: ['NOTES_ATTACHMENTS', 'Lightning', 'Notes & Attachments'],
  },
  AttachedContentDocuments: {
    objectApiName: 'ContentDocument',
    veevaMessageLabel: ['FILES', 'Lightning', 'Files'],
  },
  AttachedContentNotes: {
    objectApiName: 'ContentNote',
    veevaMessageLabel: ['NOTES', 'Lightning', 'Notes'],
  },
  OpenActivities: {
    field: 'WhatId',
    objectApiName: 'Task',
  },
  ActivityHistories: {
    field: 'WhatId',
    objectApiName: 'Task',
  },
};

const RELATIONSHIP_MAPPING = {
  RelatedNoteList: 'CombinedAttachments',
  RelatedFileList: 'AttachedContentDocuments',
  RelatedContentNoteList: 'AttachedContentNotes',
  RelatedActivityList: 'OpenActivities',
  RelatedHistoryList: 'ActivityHistories',
};

export default class EmBaseRelatedList extends LightningElement {
  @api objectApiName;
  @api recordId;

  @track relatedLists = [];

  @wire(MessageContext)
  messageContext;
  subscription = null;

  get hasRelatedLists() {
    return this.relatedLists.length > 0;
  }

  connectedCallback() {
    registerListener(EmEventConstant.POPULATE_RELATED_LIST_TABS, this.populateRelatedLists, this);
    this.subscribeToChannel();
  }

  disconnectedCallback() {
    unregisterAllListeners(this);
    this.unsubscribeToChannel();
  }

  subscribeToChannel() {
    if (!this.subscription) {
      this.subscription = subscribe(this.messageContext, eventsManagementChannel, message => this.handleMessage(message));
    }
  }

  unsubscribeToChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  async populateRelatedLists(payload) {
    this.pageCtrl = payload.pageCtrl;
    this.relatedLists = await this.processRelatedLists(payload.relatedLists);
  }

  handleMessage(msg) {
    if (msg.key === EmEventConstant.REFRESH_PARENT_RECORD && msg.parentId === this.recordId) {
      this.refreshParentRecord(msg);
    } else if (msg.key === EmEventConstant.REFRESH_RELATED_LIST && msg.parentId === this.recordId && msg.relationship) {
      const relatedListTables = this.template.querySelectorAll('c-veeva-related-list-table');
      Array.from(relatedListTables)
        .find(relatedList => relatedList?.meta?.relationship === msg.relationship)
        ?.refreshRecords();
    } else if (msg.key === EmEventConstant.REFRESH_RELATED_LISTS && msg.eventId === this.pageCtrl?.eventId && msg.objectApiName) {
      const relatedListTables = this.template.querySelectorAll('c-veeva-related-list-table');
      Array.from(relatedListTables)
        .filter(relatedList => relatedList?.meta?.objectApiName === msg.objectApiName)
        .forEach(relatedList => relatedList?.refreshRecords());
    }
  }

  async refreshParentRecord(payload) {
    const { poll, fieldsToPoll, POLL_DELAY, MAX_ATTEMPTS } = payload;
    const parentRecord = this.pageCtrl.record;
    if (poll) {
      const getRecord = async () =>
        this.pageCtrl.uiApi.getRecord(
          parentRecord.id,
          fieldsToPoll.map(field => `${parentRecord.apiName}.${field}`),
          false
        );
      const isValid = record => {
        const wasRecordUpdated = () => fieldsToPoll.some(field => parentRecord.fields[field]?.value !== record.fields[field]?.value);
        return wasRecordUpdated();
      };
      await VeevaUtils.poll(getRecord, isValid, POLL_DELAY, MAX_ATTEMPTS);
    }
    getRecordNotifyChange([{ recordId: parentRecord.id }]);
  }

  async processRelatedLists(relatedLists) {
    const processedRls = await Promise.all(relatedLists.map(rl => this.processRelatedList(rl)));
    return processedRls.filter(relatedList => relatedList.objectApiName !== null);
  }

  async processRelatedList(rl) {
    const relationship = RELATIONSHIP_MAPPING[rl.relationship] ?? rl.relationship;
    const processedRl = {
      ...rl,
      relationship,
      ...ADDITIONAL_META[relationship],
    };
    if (processedRl.veevaMessageLabel) {
      processedRl.label = await this.pageCtrl.getMessageWithDefault(...processedRl.veevaMessageLabel);
      delete processedRl.veevaMessageLabel;
    }
    return processedRl;
  }
}