import { api, wire } from 'lwc';
import EmBaseRelatedList from 'c/emBaseRelatedList';
import { createMessageContext, publish } from 'lightning/messageService';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { CurrentPageReference } from 'lightning/navigation';
import EmEventConstant from 'c/emEventConstant';

export default class EmDetailTabPage extends EmBaseRelatedList {
  @wire(CurrentPageReference)
  pageRef;

  @api objectApiName;
  @api recordId;
  activeTab;
  detailLabel;
  showSpinner = true;

  constructor() {
    super();

    const messageService = getService(SERVICES.MESSAGE);
    messageService.getMessageWithDefault('PAGE_LAYOUT_TITLE', 'Common', 'Details').then(result => {
      this.detailLabel = result;
    });
  }

  handleMessage(message) {
    if (message?.relatedListTab) {
      this.setRelatedListTab(message.relatedListTab);
    } else {
      super.handleMessage(message);
    }
  }

  setRelatedListTab(relatedListTab) {
    this.activeTab = relatedListTab;
    // Needs timeout below to allow active tab reactivity to be registered
    // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
    setTimeout(() => {
      this.activeTab = false;
    }, 200);
  }

  renderedCallback() {
    if (this.pageRef?.state?.c__action === EmEventConstant.ATTENDEE_RECONCILIATION) {
      this.attendeeReconcilation();
    }
  } 

  attendeeReconcilation() {
    const payload = {
      key: EmEventConstant.ATTENDEE_RECONCILIATION,
      eventId: this.recordId,
    };
    publish(createMessageContext(), eventsManagementChannel, payload);
  }

  // eslint-disable-next-line class-methods-use-this
  handleActive(event) {
    const relatedList = event.target.querySelector('c-veeva-related-list-table');
    if (relatedList) {
      relatedList.resetRecords();
    }
  }

  handleHideSpinner() {
    this.showSpinner = false;
  }
}