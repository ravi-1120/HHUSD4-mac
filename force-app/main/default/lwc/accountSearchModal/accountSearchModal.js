import { LightningElement, api, track } from "lwc";
import { getService, SERVICES } from 'c/veevaServiceFactory';
import { NavigationMixin } from 'lightning/navigation';
import { VeevaMessageRequest } from 'c/veevaMessageService';
import CreateCallDataFormatter from "c/createCallDataFormatter";
import CreateCallService from "c/createCallService";

export default class AccountSearchModal extends NavigationMixin(LightningElement) {

    @track showAccountSearch;
    @track headerDate;
    @track selected;
    @track okButtonDisabled = true;
    
    @api ctrl;
    @api hasClickedOk;
    eventInfo;
    createCallService;
    uiApi = getService(SERVICES.UI_API);

    async connectedCallback() {
        const messageSvc = getService('messageSvc');
        this.messageSvc = messageSvc;
        const msgRequest = new VeevaMessageRequest();
        msgRequest.addRequest('CANCEL', 'Common', 'Cancel', 'msgCancel');
        msgRequest.addRequest('OK', 'Common', 'Ok', 'msgOk');
        msgRequest.addRequest('ADD_TO', 'Callplan', 'Add To', 'msgCallplanAddTo');
        msgRequest.addRequest('ACCOUNT_NOT_VALIDATED', 'CallReport', 'Account Not Validated', 'msgAccountNotValidated');
        msgRequest.addRequest('SCHEDULE_ACCOUNT_RESTRICTION_ERROR', 'Callplan', 'This Account could not be scheduled due to configured restrictions by the account types.', 'msgAccountRestriction');
        msgRequest.addRequest('CALL_BACKDATE_WARNING', 'CallReport', 'You may not save a call more than {0} days in the past.', 'backdateMsg');        
        msgRequest.addRequest('Error', 'Common', 'Error', 'msgError');
        msgRequest.addRequest('SELECT_ASSOCIATED_ACCOUNT', 'Scheduler', 'Select Associated Account', 'msgSelectAcct');
        msgRequest.addRequest('DONE', 'Common', 'Done', 'msgDone');

        const msgMap = await messageSvc.getMessageMap(msgRequest);

        this.msgCancel = msgMap.msgCancel;
        this.msgOk = msgMap.msgOk;
        this.msgCallplanAddTo = msgMap.msgCallplanAddTo;
        this.msgDone = msgMap.msgDone;
        this.msgSelectAcct = msgMap.msgSelectAcct;

        this.createCallService = new CreateCallService({
            translatedLabels: {
                backdateMsg: msgMap.backdateMsg,
                msgError: msgMap.msgError,
                msgAccountRestriction: msgMap.msgAccountRestriction,
                msgAccountNotValidated: msgMap.msgAccountNotValidated,
            },
            ctrl: this.ctrl,
            messageService: this.messageSvc
        })
    }

    @api async showAccountSearchModal(info) {
        this.hasClickedOk = false;
        this.okBtnLabel = this.msgOk;
        if (info?.eventType !== 'call-cycle-calendar-entry') {
            this.headerDate = CreateCallDataFormatter.adjustStartTime(info, true);
            const backdateCheck = this.createCallService.checkDateIsWithinBackdateLimit(info);
            if (backdateCheck.error) {
                this.dispatchEvent(new CustomEvent('createcallerror', {detail: backdateCheck}))
                return;
            }
        } else {
            this.headerDate = info.date;
        }
        this.eventInfo = info;
        this.showAccountSearch = true;
    }

    @api async showAccountSearchModalMeetingRequest(info, callBackFn) {
        this.hasClickedOk = false;
        this.okBtnLabel = this.msgDone;
        this.msgCallplanAddTo = this.msgSelectAcct;

        this.eventInfo = info;
        this.showAccountSearch = true;
        this.callBackFn = callBackFn;
    }

    @api
    handleCancel() {
        this.selected = {};
        this.okButtonDisabled = true;
        this.showAccountSearch = false;
    }

    handleAccountSelected(event) {
        this.selected = event.detail;
        this.okButtonDisabled = false;
    }

    handleSearchCleared() {
        this.okButtonDisabled = true;
        this.selected = {};
    }

    async createEvent(){
        if (this.hasClickedOk) {
            return;
        }
        this.hasClickedOk = true;
        if (this.eventInfo?.eventType === 'call-cycle-calendar-entry') {
            this.createCallCycleEntry();
        } else if (this.eventInfo?.eventType === 'meeting-request') {
            this.createCallFromMeetingRequest();
        } else {
            this.createCall();
        }
    }

    createCallCycleEntry(){
        this.eventInfo.account = this.selected?.Formatted_Name_vod__c;
        this.eventInfo.name = this.selected?.Formatted_Name_vod__c;
        this.dispatchEvent(new CustomEvent('createcallcycleentry',
        { detail: { eventInfo: this.eventInfo, accountInfo: this.selected } } ));
    }

    async createCall() {
        this.eventInfo.duration = 30;
        
        const tempEventRes = await this.createCallService.buildTempEvent(this.eventInfo, this.selected);
        if (!tempEventRes?.event) {
            this.dispatchEvent(new CustomEvent('createcallerror', {detail: tempEventRes}));
            this.hasClickedOk = false;
            return null; 
        }
        this.dispatchEvent(new CustomEvent('handlecalendarevent', {detail: tempEventRes}))
        this.showAccountSearch = false;
        const result = await this.createCallService.createCallResult(this.eventInfo, this.selected, tempEventRes.event.id, false);
        if (result.error) {
            this.showAccountSearch = true;
            result.isModal = true;
            result.errorMessage = result.error;
            this.dispatchEvent(new CustomEvent('createcallerror', {detail: result}));
        } else if (result.success && result.events.length === 1 && result.events[0].id) {
            this.dispatchEvent(new CustomEvent('newrecordtoast', {detail: result}))
        }
        this.dispatchEvent(new CustomEvent('handlecalendarevent', {detail: result}));
        return result;
    }

    async createCallFromMeetingRequest() {
        this.eventInfo.duration = 30;

        // remove meeting request event
        this.dispatchEvent(new CustomEvent('handlecalendarevent', {detail: {isTemporary: false, temporaryEventId: this.eventInfo.meetingRequestId}}));
        const response = await this.createCall();
        this.dispatchEvent(new CustomEvent('focusnewevent', {detail: {id: response.event.id}}));
        this.callBackFn(response);
    }

    get showEventDate() {
        if (this.eventInfo?.eventType === 'call-cycle-calendar-entry') {
            return true;
        }
        return false;
    }

    get showEventWeekDay() {
        if (this.eventInfo?.eventType !== 'call-cycle-calendar-entry' && this.eventInfo?.eventType !== 'meeting-request') {
            return true;
        }
        return false;
    }

    @api
    disableOkButton() {
        this.okButtonDisabled = true;
    }
}