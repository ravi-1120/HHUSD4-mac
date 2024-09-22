import { LightningElement, api, track, wire } from "lwc";
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import VeevaToastEvent from "c/veevaToastEvent";
import { NavigationMixin } from 'lightning/navigation';
import myScheduleCalendarEventChannel from '@salesforce/messageChannel/MySchedule_Calendar_Event__c';
import { publish, MessageContext } from 'lightning/messageService';
import { loadStyle } from 'lightning/platformResourceLoader';
import CONVERT2CALL from '@salesforce/resourceUrl/convertToCall';

export default class ConvertToCall extends NavigationMixin(LightningElement) {
    
    @wire(MessageContext) messageContext;

    @api inputVars;
    @track show = false;
    consoleMode;
    recordId;

    async connectedCallback() {
        await loadStyle(this, CONVERT2CALL);
    }

    @api 
    showConvertToCallModal(recordId, consoleMode) {
        this.show = true;
        this.recordId = recordId;
        this.inputVars = [{ name: "mcaId", type: "String", value: recordId }];
        this.consoleMode = consoleMode;
    }

    onClose() {
        this.show = false;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    @api
    handleStatusChange(event) {
        if(event?.detail?.status === 'FINISHED') {
            const outputVariables = event?.detail?.outputVariables;
            const error = outputVariables.find(({name, value}) => name === 'error' && value);
            const createdCall = outputVariables.find(({name, value}) => name === 'createdCallId' && value);
           
            if (error) {
                this.dispatchEvent(VeevaToastEvent.error({message: error.value}));
            } else if (createdCall) {
                const methodSelection = outputVariables.find(({name, value}) => name === 'methodSelection' && value);
                let callMsg = '';
                
                if (methodSelection.value === 'createNewCall') {
                    callMsg = {event: {id: createdCall.value, objectType: 'Call2_vod__c'}, isTemporary: false, needsQueried: true, temporaryEventId: this.recordId};
                } else {
                    callMsg = {isTemporary: false, temporaryEventId: this.recordId};
                }
                publish(this.messageContext, myScheduleCalendarEventChannel, callMsg);
                this._openRecordPage(createdCall.value);
            }
            this.onClose();
        }
    }

    _openRecordPage(recordId) {
        const objectApiName = 'Call2_vod__c';
        this[this.consoleMode ? NavigationMixin.Navigate : NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId,
                objectApiName,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }
}