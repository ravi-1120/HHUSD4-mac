import { createRecord } from 'lightning/uiRecordApi';
import BaseCallService from 'c/baseCallService';
import CALL_CYCLE_ENTRY_OBJECT from '@salesforce/schema/Call_Cycle_Entry_vod__c';
import CALL_CYCLE_ENTRY_WEEK_FLD from '@salesforce/schema/Call_Cycle_Entry_vod__c.Week_vod__c';
import CALL_CYCLE_ENTRY_DAY_OF_WEEK_FLD from '@salesforce/schema/Call_Cycle_Entry_vod__c.Day_of_Week_vod__c';
import CALL_CYCLE_ENTRY_START_TIME_FLD from '@salesforce/schema/Call_Cycle_Entry_vod__c.Start_Time_vod__c';
import CALL_CYCLE_ENTRY_DURATION_FLD from '@salesforce/schema/Call_Cycle_Entry_vod__c.Duration_vod__c';
import CALL_CYCLE_ENTRY_ACCOUNT_FLD from '@salesforce/schema/Call_Cycle_Entry_vod__c.Account_vod__c';

export default class CallCycleEntryService extends BaseCallService {

    async createCallCycleEntry(eventInfo, accountInfo){
        let result;
        const rec = await this.ctrl.pageCtrl.uiApi.getRecord(accountInfo.id, ['Account.Do_Not_Call_vod__c','Account.RecordType.Name'], true);
        const doNotCall = this.doNotCall(accountInfo.id, rec);
        if (doNotCall) {
            return this.getErrorBody(this.translatedLabels.msgAccountNotValidated, false);
        }
        const validAccountCall = await this.validAccountCall(rec, eventInfo);
        if (!validAccountCall) {
            return this.getErrorBody(this.translatedLabels.msgAccountRestriction, false);
        }
        const startTime = eventInfo.date.toLocaleString('en-US', {hour: 'numeric', minute: 'numeric'})
        try{
        // create call cycle record
        result = await createRecord({
            apiName: CALL_CYCLE_ENTRY_OBJECT.objectApiName,
            fields: {
                [CALL_CYCLE_ENTRY_WEEK_FLD.fieldApiName]: eventInfo.week,
                [CALL_CYCLE_ENTRY_DAY_OF_WEEK_FLD.fieldApiName]: eventInfo.day,
                [CALL_CYCLE_ENTRY_START_TIME_FLD.fieldApiName]: startTime,
                [CALL_CYCLE_ENTRY_DURATION_FLD.fieldApiName]: eventInfo.duration,
                [CALL_CYCLE_ENTRY_ACCOUNT_FLD.fieldApiName]: accountInfo.id
            },
        });
    } catch(e) {
        const errorMessages = this.parseSFErrors(e);
        return this.getErrorBody(errorMessages, false);
    }
        return result;
    }
}