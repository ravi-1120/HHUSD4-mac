import { LightningElement, api } from "lwc";
import { VeevaMessageRequest } from 'c/veevaMessageService';
import { loadStyle } from 'lightning/platformResourceLoader';
import REASON from '@salesforce/resourceUrl/reasonModal';

export default class ReasonModal extends LightningElement {
    @api messageSvc;
    @api uiApi;
    @api skipButton;
    @api callBackFn;
    @api recordType;
    

    newValue;
    skipLabel;
    doneLabel;
    msgChooseReason;
    options;
    doneButton = true;
    loaded = false;
    noReasonProvided = 'No_Reason_Provided_vod';
    noReasonFound = false;

    async connectedCallback() {
        await loadStyle(this, REASON);
        await this.loadMessages();
        await this.getPicklistValues();
        if (!this.noReasonFound) {
            this.skipButton = false;
        }
        this.loaded = true;
    }

    async loadMessages() {
        const msgRequest = new VeevaMessageRequest();

        msgRequest.addRequest('SKIP', 'Common', 'Skip', 'skipLabel');
        msgRequest.addRequest('DONE', 'Common', 'Done', 'doneLabel');
        msgRequest.addRequest('CHOOSE_REASON', 'Scheduler', 'Choose a reason:', 'chooseReasonLabel');

        const msgMap = await this.messageSvc.getMessageMap(msgRequest);
        this.msgChooseReason = msgMap.chooseReasonLabel;

        this.skipLabel = msgMap.skipLabel;
        this.doneLabel = msgMap.doneLabel;
    }

    async getPicklistValues() {
        const pickListValues = await this.uiApi.getPicklistValues(this.recordType, 'Meeting_Request_vod__c', 'Decline_Reason_vod__c');
        const pickListDict = [];
        for (let i = 0; i < pickListValues.values.length; i++) {
            const item = {};
            if (pickListValues.values[i].value !== this.noReasonProvided) {
                item.label = pickListValues.values[i].label;
                item.value = pickListValues.values[i].value;
                pickListDict.push(item);
            } else {
                this.noReasonFound = true;
            }
            
        }
        this.options = pickListDict;
    }

    handleReasonModalSkip() {
        this.callBackFn(this.noReasonProvided);
        this.handleReasonModalClose();
    }

    handleReasonModalDone() {
        this.callBackFn(this.newValue);
        this.handleReasonModalClose();
    }

    handleChange(event) {
        const newValue = event.detail.value;
        this.newValue = newValue;
        this.doneButton = false;
    }

    handleReasonModalClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}