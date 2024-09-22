import LOCALE from '@salesforce/i18n/locale';

export default class BaseCallService {
    ctrl;

    allowedCallRecordSettingsMap;
    availableProfileCallRecordTypes;
    accountInfoMap;

    constructor({translatedLabels, ctrl, messageService}) {
        this.ctrl = ctrl;
        this.messageService = messageService;
        this.translatedLabels = translatedLabels;
    }

    async fetchAccountsInfoForValidation(accountIds){
        this.accountInfoMap = {};
        const accountRecs = await this.ctrl.pageCtrl.uiApi.getBatchRecords(accountIds, ['Account.Do_Not_Call_vod__c','Account.RecordType.Name'], true); 
        accountRecs.forEach(accountRecord => {
            this.accountInfoMap[accountRecord.id] = accountRecord;
        });
    }

    async getAvailableCallRecordTypesForProfile() {
        this.availableProfileCallRecordTypes = [];
        const availableRecordTypeIds = Object.values(this.ctrl.pageCtrl.objectInfo.recordTypeInfos).filter(rt => rt.available && !rt.master).map(rt => rt.recordTypeId); 
        const recs = await this.ctrl.pageCtrl.uiApi.getBatchRecords(availableRecordTypeIds, ['RecordType.Name'], true); 
        for (const rec of recs) {
            this.availableProfileCallRecordTypes.push(rec.fields.Name.value);
        }
    }

    async getCallRecordSettings(val) {
        this.allowedCallRecordSettingsMap = {};
        if (val && val.length !== 0) {
            const messageValue = await this.getSettingsFromMessage(val);
            if (messageValue.length !== 0) {
                this.allowedCallRecordSettingsMap = this.parseAccountValues(messageValue);
            }
        }
    }

    async validAccountCall(record, callInfo) {
        if (!this.allowedCallRecordSettingsMap) {
            await this.getCallRecordSettings(callInfo.allowedCallRecordTypeSettings);
        }
        if (!this.availableProfileCallRecordTypes) {
            await this.getAvailableCallRecordTypesForProfile();
        }
        const accountType = record.fields.RecordType.value.fields.Name.value;
        return this.validAccount(accountType);
    }

    async validAccount(accountType) {
        if (JSON.stringify(this.allowedCallRecordSettingsMap) === "{}") {
            return true;
        }
        // check if account type set in allowed call record setting
        const acctCallRecordList = this.allowedCallRecordSettingsMap[accountType];
        if (acctCallRecordList) {
            // iterate through allowed call record types to see if one of the types is available to the profile
            return acctCallRecordList.some(callType => this.availableProfileCallRecordTypes.includes(callType));
        } 
        return true;
    }

    doNotCall(accountId, record) {
        if (accountId === undefined) {
            return true;
        }
        
        const values = record.fields.Do_Not_Call_vod__c || {};
        if ('Yes_vod' === values.value) {
            return true;
        }
        return false;
    }

    async getSettingsFromMessage(setting) {
        if (setting === undefined) {
            return '';
        }
        const splitString = setting.split(';;').map(element => element.trim());
        if (splitString.length === 2) {
            const key = splitString[0].trim();
            const category = splitString[1].trim();
            const messageValue = await this.messageService.getMessageWithDefault(key, category, ''); 
            if (messageValue.length !== 0) {
                return messageValue.trim();
            }
        }
        return setting;
    }

    parseAccountValues(setting) {
        const settingsAcctToType = {};
        const groups = setting.split(';;').map(element => element.trim()).filter(element => element !== '');
        for (let n = 0; n < groups.length; n++) {
            const split = groups[n].split(',').map(element => element.trim());
            const accountType = split[0];
            const allowed = [];
            for (let i = 1; i < split.length; i++) {
                const callType = split[i];
                if(callType.length > 0) {
                    allowed.push(split[i]);
                }
            }
            settingsAcctToType[accountType] = allowed;
        }
        return settingsAcctToType;
    }

    getErrorBody(errorMessage, fromSchedulerPane = false) {
        return { error: true, isModal: true, errorMessage, isTemporary: true, fromSchedulerPane };
    }

    generateErrorInfo(preCreateCallErrors, createCallErrors, failedPreCheckCalls) {
        const numErrors = preCreateCallErrors.filter(error => error).length;
        let errorDescriptions = [];
        if (numErrors > 0 && preCreateCallErrors) {
            errorDescriptions = preCreateCallErrors.map((error, i) => {
                if (error) {
                    const timeFormatOptions = {hour: 'numeric'};
                    if (failedPreCheckCalls[i].startDate.getMinutes() !== 0) { 
                        timeFormatOptions.minute = 'numeric';
                    }
                    const str = `${failedPreCheckCalls[i].name} | ${failedPreCheckCalls[i].startDate.toLocaleDateString(LOCALE, {weekday:'long'})}, ${failedPreCheckCalls[i].startDate.toLocaleString(LOCALE, timeFormatOptions)}`;
                    return [str, error, ''];
                }
                return null;
            });
        }
        if (createCallErrors.length > 0) {
            errorDescriptions.push(createCallErrors.map(x => [x, '']));
        }
        if (errorDescriptions.length > 0) {
            errorDescriptions.unshift('');
        }
        const errorHeader = this.translatedLabels.callsCannotBeCreatedLabel.replace('{0}', numErrors > 1 ? this.translatedLabels.Call2_vod__c.labelPlural : this.translatedLabels.Call2_vod__c.label);
        return errorDescriptions.length > 0 ? {errorDescriptions: errorDescriptions.flat(2), errorHeader} : null;
    }

    parseSFErrors(e){
        const errorMessages = [];
        if (e.body?.output?.errors != null || e.body?.output?.fieldErrors != null) {                
            const fieldMessageMap = new Map();
            // Assign record type errors
            e.body.output.errors?.forEach(customError => {
                errorMessages.push(customError.message);
            });

            // Assign field errors
            Object.values(e.body.output?.fieldErrors).forEach(fieldErrorArray => {        
                fieldErrorArray.forEach(fieldError => {
                if (!fieldMessageMap.has(fieldError.fieldLabel)) {
                    fieldMessageMap.set(fieldError.fieldLabel, fieldError.message);
                } else {
                    fieldMessageMap.set(fieldError.fieldLabel, `${fieldMessageMap.get(fieldError.fieldLabel)}\n${fieldError.message}`);
                }
                });
            });
            Array.from(fieldMessageMap.values()).forEach(fieldError => errorMessages.push(fieldError));            
        } else {
            errorMessages.push(e.body?.message);
        }
        return errorMessages;
    }
}