import { LightningElement, api } from 'lwc';
import { createMessageContext, publish } from 'lightning/messageService';
import eventsManagementChannel from '@salesforce/messageChannel/Events_Management_Channel_vod__c';

export default class EmSpeakerNominationButton extends LightningElement {
  @api meta;
  @api pageCtrl;

  connectedCallback() {
    this.messageContext = createMessageContext();
  }

  get isMenu() {
    return this.meta.menu;
  }

  handleClick() {
    if (this.meta.name === 'SubmitForApproval') {
      this.launchSubmitForApprovalFlow();
    }
  }

  launchSubmitForApprovalFlow() {
    const payload = {
      flowName: 'VeevaSubmitForApprovalFlow',
      flowVariables: this.getFlowVariables(),
    };
    publish(this.messageContext, eventsManagementChannel, payload);
  }

  getFlowVariables() {
    const flowVariables = [
      {
        name: 'recordId',
        value: this.pageCtrl.record.id,
        type: 'String',
      },
    ];
    return flowVariables;
  }
}