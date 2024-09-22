import CreateCallDataFormatter from 'c/createCallDataFormatter';
import BaseCallService from 'c/baseCallService';
import VeevaCalendarEvent from './veevaCalendarEvent';

export default class CreateCallService extends BaseCallService {

    async applyCallCycle(cycleIds, calendarMode, applyByWeek, clickDate) {
        return this.ctrl.pageCtrl.applyCallCycle(cycleIds, calendarMode, applyByWeek, clickDate);
    }

    async populateValidationLists(allowedCallRecordTypeSettings) {
        const validationListPromises = [];
        if (!this.allowedCallRecordSettingsMap) {
            const getCallRecordSettingsPromise = this.getCallRecordSettings(allowedCallRecordTypeSettings);
            validationListPromises.push(getCallRecordSettingsPromise);
        }
        if (!this.availableProfileCallRecordTypes) {
            const getAvailableCallRecordTypesForProfilePromise = this.getAvailableCallRecordTypesForProfile();
            validationListPromises.push(getAvailableCallRecordTypesForProfilePromise);
        }
        return Promise.all(validationListPromises);
    }

    async getTempEvent(callInfo, accountInfo, fromSchedulerPane = false) {
        const backdateCheck = this.checkDateIsWithinBackdateLimit(callInfo);
        if (backdateCheck.error) {
            return backdateCheck;
        }
        if (!this.allowedCallRecordSettingsMap) {
            await this.getCallRecordSettings(callInfo.allowedCallRecordTypeSettings);
        }
        if (!this.availableProfileCallRecordTypes) {
            await this.getAvailableCallRecordTypesForProfile();
        }
        return this.buildTempEvent(callInfo, accountInfo, fromSchedulerPane);
    }

    checkDateIsWithinBackdateLimit(eventInfo) {
        const { backdateLimit } = eventInfo;
        if (backdateLimit === undefined || backdateLimit === null || backdateLimit < 0) { // if backdate limit is negative, we do not enforce the setting
            return true;
        }
        // set the earliest possible call datetime
        const backdateLimitDate = new Date();
        backdateLimitDate.setDate(new Date().getDate() - backdateLimit);
        backdateLimitDate.setHours(0);
        backdateLimitDate.setMinutes(0);
        backdateLimitDate.setSeconds(0);
        backdateLimitDate.setMilliseconds(0);
        
        if (eventInfo.date < backdateLimitDate) {
            return this.getErrorBody(this.translatedLabels.backdateMsg.replace('{0}', backdateLimit));
        }
        return true;
    }

    async createCallResult(callInfo, accountInfo, temporaryEventId, showErrorModal = true) {
        if (callInfo.view === 'month') {
            callInfo.date = new Date(CreateCallDataFormatter.adjustStartTime(callInfo, false));
        }
        let result = await this.ctrl.pageCtrl.createCall(accountInfo, callInfo);
        result = {...result, event : null, isTemporary: false, temporaryEventId };

        if (result.success && result.events?.length) {
            result.event = new VeevaCalendarEvent(result.events[0]);
            result.needsQueried = true; // setting a flag so we know to requery a call of the same id to get all popover info
        } else if (result.error) {
            if (showErrorModal) { // showErrorModal = false to put error modal on top of account search modal
                const message = /message='(?<errorMessage>.*)'/; // The error response string is specific to Classic My Schedule Angular alert.
                const matchGroup = result.error.match(message);
                const msg = matchGroup?.groups?.errorMessage || result.error;
                return {...result, error: true, isModal: true, errorMessage: msg};
            }
        } else {
            return {...result, error: true, isModal: false, errorMessage: this.translatedLabels.errorLabel};
        }
        return result;
    }

    async buildTempEvent(callInfo, accountInfo, fromSchedulerPane = false) {
        const adjustedTempDate = new Date(CreateCallDataFormatter.adjustStartTime(callInfo, true));
        const personAccountId = accountInfo.id.includes(':') ? accountInfo.id.split(':')[0] : accountInfo.id;

        let accountRecord = this.accountInfoMap?.[personAccountId];
        if (!accountRecord){
            accountRecord = await this.ctrl.pageCtrl.uiApi.getRecord(personAccountId, ['Account.Do_Not_Call_vod__c','Account.RecordType.Name'], true);
            if (accountRecord?.length === 0) {
                return { error: true, forwardToRecord: true, recordId: personAccountId, fromSchedulerPane }
            }
        }

        const doNotCall = this.doNotCall(personAccountId, accountRecord);
        if (doNotCall) {
            return this.getErrorBody(this.translatedLabels.msgAccountNotValidated, fromSchedulerPane);
        }
        const validAccountCall = await this.validAccountCall(accountRecord, callInfo);
        if (!validAccountCall) {
            return this.getErrorBody(this.translatedLabels.msgAccountRestriction, fromSchedulerPane);
        }

        let formattedName;
        if (accountInfo.displayedName) {
            formattedName = accountInfo.displayedName;
        } else if (accountInfo.LastName) {
            formattedName = `${accountInfo.LastName}, ${accountInfo.FirstName}`;
        } else {
            formattedName = accountInfo.Name;
        }
        const tempEvent = VeevaCalendarEvent.getTempCallEvent(adjustedTempDate, formattedName, callInfo.duration);
        const res = { event : tempEvent, isTemporary : true, fromSchedulerPane, temporaryEventId: tempEvent.id, callCycleId: callInfo.callCycleId };
        return res;
    }
}