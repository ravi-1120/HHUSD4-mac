import { LightningElement, api, track } from 'lwc';
import EmNextApproverController from 'c/emNextApproverController';
import EmEventConstant from 'c/emEventConstant';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { getService, SERVICES } from 'c/veevaServiceFactory';
import VeevaPageController from 'c/veevaPageController';
import EM_SPEAKER_NOMINATION from '@salesforce/schema/EM_Speaker_Nomination_vod__c';
import USER from '@salesforce/schema/User';
import { VeevaMessageRequest } from 'c/veevaMessageService';

export default class NextApproverModal extends LightningElement {
  @track model = {};
  @track display = false;

  // Output properties to flow
  @api exitEarly;
  @api nextApproverId;

  approverCtrl = {};
  messageService;
  uiApi;
  messageMap = {};
  userObjectInfo;

  connectedCallback() {
    this.init();
  }

  async init() {
    this.messageService = getService(SERVICES.MESSAGE);
    this.uiApi = getService(SERVICES.UI_API);
    [this.userObjectInfo] = await Promise.all([this.uiApi.objectInfo(USER.objectApiName), this.getMessages()]);
    this.approverCtrl = this.nextApproverCtrl();
    this.display = true;
  }

  async getMessages() {
    const msgRequest = new VeevaMessageRequest();
    msgRequest.addRequest('NEXT_APPROVER', 'EVENT_MANAGEMENT', 'Approver', 'nextApproverLabel');
    msgRequest.addRequest('SUBMIT_FOR_APPROVAL', 'Common', 'Submit for Approval', 'submitLabel');
    msgRequest.addRequest('Queue', 'Common', 'Queue', 'queueLabel');
    this.messageMap = await this.messageService.getMessageMap(msgRequest);
  }

  finishFlow() {
    this.exitEarly = true;
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  goToNext() {
    this.dispatchEvent(new FlowNavigationNextEvent());
  }

  nextApproverCtrl() {
    const veevaDataService = getService(SERVICES.DATA);
    const metaStore = getService(SERVICES.META);

    const pageCtrl = new VeevaPageController(veevaDataService, this.uiApi, this.messageService, metaStore);
    pageCtrl.record = { apiName: EM_SPEAKER_NOMINATION.objectApiName };

    const meta = {
      required: true,
      editable: true,
      label: this.messageMap.nextApproverLabel,
      objectList: [
        { value: 'User', label: this.userObjectInfo?.label || 'User', defaultValue: false, field: 'NextApprover' },
        { value: 'Group', label: this.messageMap.queueLabel, defaultValue: false, field: 'Queue' },
      ],
    };

    return new EmNextApproverController(EM_SPEAKER_NOMINATION.objectApiName, meta, pageCtrl, this.model);
  }

  get disableButton() {
    return !this.nextApproverId;
  }

  handleChange() {
    this.nextApproverId = this.model[EmEventConstant.APPROVER_ID];
  }
}