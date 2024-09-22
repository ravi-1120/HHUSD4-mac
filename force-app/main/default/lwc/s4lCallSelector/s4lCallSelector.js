/* eslint-disable no-console, prefer-destructuring, no-return-assign */

import { api, wire, LightningElement, track } from 'lwc';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';

import { getService } from 'c/veevaServiceFactory';
import S4lUtils from 'c/s4lUtils';

import CALL2_OBJECT from '@salesforce/schema/Call2_vod__c';
import CHILD_ACCOUNT_OBJECT from '@salesforce/schema/Child_Account_vod__c';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import MEDICAL_EVENT_OBJECT from '@salesforce/schema/Medical_Event_vod__c';
import EVENT_OBJECT from '@salesforce/schema/EM_Event_vod__c';

import getUnsubmittedCallIdsForUser from '@salesforce/apex/S4LCallSearchController.getUnsubmittedCallIdsForUser';
import getAttendeeChildCallIds from '@salesforce/apex/S4LCallSearchController.getAttendeeChildCallIds';
import validateAccountsOnCall from "@salesforce/apex/S4LAccountValidator.validateAccountsOnCall";

import S4lCallSearchController from "./s4lCallSearchController";

// uses unicode character U+2E31 '⸱'
const ADDRESS_SEPARATOR = ` ${String.fromCharCode(0x2E31)} `;
const CALL_FIELDS = [
    'Id', 'Account_vod__c', 'Account_vod__r.Formatted_Name_vod__c', 'Address_vod__c', 'Name',
    'Call_Date_vod__c', 'Call_Datetime_vod__c',
    'Child_Account_vod__c', 'Child_Account_vod__r.Parent_Child_Name_vod__c',
    'Medical_Event_vod__c', 'Medical_Event_vod__r.Name', 'Medical_Event_vod__r.Event_Display_Name_vod__c',
    'EM_Event_vod__c', 'EM_Event_vod__r.Name', 'EM_Event_vod__r.Event_Display_Name_vod__c'
];

export default class S4lCallSelector extends LightningElement {

    @api labels;
    @api isChildAccountEnabled;
    @api mcaId;

    @track showAll;
    @track options = [];
    @track selectedValue;

    @track enableInfiniteLoading;
    @track searchAllResults;

    @track loadingInitialResults;

    @track validityReported = false;
    @track validationMessage = '';

    loading = true;
    callObjectLabel = 'Call';
    showAttendeeViolationAlert = false;
    alertModalData = {isVisible: false};

    recordTypeUniqueActivityFlag = {};
    recordTypeHasSignForDetails = {};

    allowedCallFields = [];

    get isValid() {
        return !!this.selectedValue;
    }

    get comboboxClass() {
        return this.validityReported && !this.isValid? 'slds-has-error' : '';
    }

    @api checkValidity() {
        const isValid = this.isValid;
        if(isValid) {
            this.validationMessage = '';
        } else {
            this.validationMessage = this.labels.thisFieldIsRequired;
        }
        this.validityReported = true;
        return isValid;
    }

    @wire(getObjectInfos, { objectApiNames: [ CALL2_OBJECT, CHILD_ACCOUNT_OBJECT, ACCOUNT_OBJECT, MEDICAL_EVENT_OBJECT, EVENT_OBJECT ] })
    async wiredObjectInfo({ error, data }) {
        this.init().then(() => {
            if (data) {
                this.ctrl.callObjectInfo = data.results[0].result;
                this.callObjectLabel = this.ctrl.callObjectInfo.label;
                this.callObjectLabelPlural = this.ctrl.callObjectInfo.labelPlural;

                this.ctrl.childAccountObjectInfo = data.results[1].result;
                this.ctrl.accountObjectInfo = data.results[2].result;

                this.ctrl.medicalEventObjectInfo = data.results[3].result;
                this.ctrl.eventObjectInfo = data.results[4].result;

                // save fields that user has fls for
                const callFields = Object.keys(this.ctrl.callObjectInfo.fields);
                const childAccountFields = Object.keys(this.ctrl.childAccountObjectInfo.fields);
                const accountFields = Object.keys(this.ctrl.accountObjectInfo.fields);
                const medicalEventFields = this.ctrl.medicalEventObjectInfo.fields ? Object.keys(this.ctrl.medicalEventObjectInfo.fields) : [];
                const eventFields = this.ctrl.eventObjectInfo.fields ? Object.keys(this.ctrl.eventObjectInfo.fields) : [];
                for (const fieldName of CALL_FIELDS) {
                    if (callFields.includes(fieldName)) {
                        this.allowedCallFields.push(fieldName);
                    } else if (fieldName.includes('Child_Account_vod__r')) {
                        // exception for child account relationship fields
                        const childAccountRefFieldName = fieldName.split(".")[1];
                        if (childAccountFields.includes(childAccountRefFieldName)) {
                            this.allowedCallFields.push(fieldName);
                        }
                    } else if (fieldName.includes('Account_vod__r')) {
                        // exception for account relationship fields
                        const accountRefFieldName = fieldName.split(".")[1];
                        if (accountFields.includes(accountRefFieldName)) {
                            this.allowedCallFields.push(fieldName);
                        }
                    } else if (fieldName.includes('Medical_Event_vod__r') && callFields.includes('Medical_Event_vod__c')) {
                        const medicalEventRefFieldName = fieldName.split(".")[1];
                        if (medicalEventFields.includes(medicalEventRefFieldName)) {
                            this.allowedCallFields.push(fieldName);
                        }
                    } else if (fieldName.includes('EM_Event_vod__r') && callFields.includes('EM_Event_vod__c')) {
                        const eventRefFieldName = fieldName.split(".")[1];
                        if (eventFields.includes(eventRefFieldName)) {
                            this.allowedCallFields.push(fieldName);
                        }
                    }
                }
            }
            if (error) {
                console.error(`getObjectInfo error: ${error}`);
                this.setError(error);
            }
        }).finally(() => this.loading = false);

        // querying for today's call
        const callIds = await getUnsubmittedCallIdsForUser({todayOnly: true});
        this.todaysCall = [];
        if(callIds && callIds.length) {
            const qryFlds = this.allowedCallFields.map(fld => `Call2_vod__c.${fld}`);
            const calls = await this.ctrl.queryRecordsByIds(callIds, qryFlds);
            this.todaysCall = calls.map(call => this.toCallOption(this.ctrl.getQueryResultValueObject(call, CALL_FIELDS)));
        }
        this.setOptions();
    }

    async init () {
        this._uiApi = getService('userInterfaceSvc');
        this._uiApi.requests = [];
        this._messageSvc = getService('messageSvc');
        this.ctrl = new S4lCallSearchController(this._uiApi, this._messageSvc);
    }

    async connectedCallback() {
        this.showAll = false;
        this.enableInfiniteLoading = false;
        this.searchAllResults = [];
        this.additionalOptions = [];
        this.loadingInitialResults = true;

        this.picklistHintText = this.labels.selectACall; // picklist hint text
        this.fieldApiName = "Call2_vod__c.Name";
        this.selectedValue = null;

        // message used for bulleted list alert CANNOT_ADD_ATTENDEES_BECAUSE;;CLM
        this.attendeeViolationMessage = [this.labels.cannotAddAttendeeBecause.replace('{0}', '')];

    }

    setOptions() {
        let allOptions = [];
        allOptions = allOptions.concat(this.todaysCall);
        allOptions = allOptions.concat(this.additionalOptions);
        // try to eliminate duplicate calls records
        allOptions = allOptions.filter((opt, index) =>
            allOptions.findIndex(a => a.value === opt.value) === index
        );
        this.options = allOptions;
        this.options.push(this.showAllOption());
    }

    getCallLabel(call) {
        let label = '';
        if(call) {
            if (call.Name) {
                label = call.Name;
            }
            if(call.Account_vod__r && call.Account_vod__r.Formatted_Name_vod__c) {
                label = call.Account_vod__r.Formatted_Name_vod__c;
            } else if (call['Account_vod__r.Formatted_Name_vod__c']) {
                label = call['Account_vod__r.Formatted_Name_vod__c'];
            }
            if(this.isChildAccountEnabled && call.Child_Account_vod__r && call.Child_Account_vod__r.Parent_Child_Name_vod__c) {
                label = call.Child_Account_vod__r.Parent_Child_Name_vod__c;
            } else if(this.isChildAccountEnabled && call['Child_Account_vod__r.Parent_Child_Name_vod__c']) {
                label = call['Child_Account_vod__r.Parent_Child_Name_vod__c'];
            }
            if (call.EM_Event_vod__c) {
                if (call.EM_Event_vod__r && call.EM_Event_vod__r.Event_Display_Name_vod__c) {
                    label = call.EM_Event_vod__r.Event_Display_Name_vod__c;
                } else if (call['EM_Event_vod__r.Event_Display_Name_vod__c']) {
                    label = call['EM_Event_vod__r.Event_Display_Name_vod__c'];
                } else if (call.EM_Event_vod__r && call.EM_Event_vod__r.Name) {
                    label = call.EM_Event_vod__r.Name;
                } else if (call['EM_Event_vod__r.Name']) {
                    label = call['EM_Event_vod__r.Name'];
                }
            }
            if (call.Medical_Event_vod__c) {
                if (call.Medical_Event_vod__r && call.Medical_Event_vod__r.Event_Display_Name_vod__c) {
                    label = call.Medical_Event_vod__r.Event_Display_Name_vod__c;
                } else if (call['Medical_Event_vod__r.Event_Display_Name_vod__c']) {
                    label = call['Medical_Event_vod__r.Event_Display_Name_vod__c'];
                } else if (call.Medical_Event_vod__r && call.Medical_Event_vod__r.Name) {
                    label = call.Medical_Event_vod__r.Name;
                } else if (call['Medical_Event_vod__r.Name']) {
                    label = call['Medical_Event_vod__r.Name'];
                }
            }
        }
        return label;
    }

    getCallSubLabel(call) {
        let subLabel = '';
        if(call.Call_Datetime_vod__c) {
            subLabel += call.Call_Datetime_vod__c;
        } else if (call.Call_Date_vod__c){
            subLabel += call.Call_Date_vod__c;
        }
        if(call.Address_vod__c) {
            subLabel += ADDRESS_SEPARATOR + call.Address_vod__c;
        }
        return subLabel;
    }

    toCallOption(call) {
        return {
            value: call.Id,
            label: this.getCallLabel(call),
            subLabel: this.getCallSubLabel(call),
            icon: 'custom:custom14',
            data: call
        };
    }

    showAllOption() {
        return {
            value: 'showAllCall',
            label: this.labels.showAllCalls
        }
    }

    // handle select from Today's Call (direct dropdown option)
    async handleSelectCall(event) {
        const selected = event.detail.value;
        if(selected === 'showAllCall') {
            if(!this.columns) {
                // trying to only load the column onces when needed
                this.columns = await this.ctrl.getColumns(false);
            }
            this.showAll = true;
            if(this.loadingInitialResults) {
                this.showAllCallSearch(false).then(() => this.loadingInitialResults = false);
            }
        } else {
            this.emitLoadingCallEvent();
            this.setSelectedCall(selected);
        }
    }

    async handleLoadMore() {
        this.showAllCallSearch(true);
    }

    async showAllCallSearch(isLoadMore) {
        this.isLoadMore = isLoadMore;
        const response = await this.ctrl.searchWithColumns();
        this.searchAllResults = this.searchAllResults.concat(response.records);
        this.enableInfiniteLoading = response.hasMore;
        this.isLoadMore = false;
    }

    // handle select from Show All Calls modal
    async handleRowSelection(e) {
        const selectedCallId = e.detail.id;
        this.emitLoadingCallEvent();
        // get call data for picklist option if the call is not already in the options array
        if(!this.isCallAlreadyInOption(selectedCallId)) {
            await this.getCallData(selectedCallId);
        }
        this.setSelectedCall(selectedCallId);
    }

    emitLoadingCallEvent() {
        this.dispatchEvent(new CustomEvent("loadingcall"));
    }

    async setSelectedCall(callId) {
        this.validationMessage = '';
        this.validityReported = false;
        Promise.all([
            validateAccountsOnCall({mcaId: this.mcaId, callIds: [callId]}),
            this.fetchSupplementaryCallInformation(callId),
            getAttendeeChildCallIds({callId})
        ]).then(([selectedCallValidationResult, callInfo, childCallIds]) =>
            this.postSelectCall(callId, selectedCallValidationResult, callInfo, childCallIds)
        ).finally(() => {
            this.showAll = false;
        });
    }

    async postSelectCall(callId, selectedCallValidationResult, callInfo, childCallIds) {
        const isPersonAccount = callInfo.accountIsPersonAccount;
        const hasAttendees = childCallIds && childCallIds.length;
        let hasError = false;
        // validation against base call failed
        if(selectedCallValidationResult && Object.keys(selectedCallValidationResult).length > 0) {
            let alertData;
            const resultArr = Object.values(selectedCallValidationResult);
            const primaryAccountValidationResult = resultArr[0];
            if(isPersonAccount && !hasAttendees) {
                // person call & primary account failed validation, use itemized error message
                alertData = S4lUtils.constructModalDataForAccountAlert(this.labels, primaryAccountValidationResult);
            } else {
                // non-person call & primary account failed validation, use error message CANNOT_ADD_CALL_TO_ACCOUNT;;CLM
                alertData = S4lUtils.constructModalData(this.labels.cannotRecordCall,
                    S4lUtils.substituteMessage(this.labels.cannotAddCallToAccount,
                        [primaryAccountValidationResult.accountFormattedName]));
            }
            this.showGeneralAlert(alertData, this.closeGeneralAlert);
            hasError = true;
        } else if(hasAttendees && !callInfo.isUniqueActivity) {
            // run validation against attendees
            // skip attendees from UA call; they will be checked only if they're selected as attendee later
            const childrenValidationResult = await validateAccountsOnCall({mcaId: this.mcaId, callIds: [...childCallIds]});
            if(childrenValidationResult != null && Object.keys(childrenValidationResult).length > 0) {
                // if any attendee(s) failed validation, use error message CANNOT_ADD_ATTENDEES_BECAUSE;;CLM + attendee name(s) in bulleted list
                this.violatedAttendeeNames = Object.values(childrenValidationResult).map(res => res.accountFormattedName);
                this.showAttendeeViolationAlert = true;
                hasError = true;
            }
        }
        if(hasError) {
            this.selectedValue = null;
            this.dispatchEvent(new CustomEvent("error"));
        } else {
            this.selectedValue = callId;
            this.dispatchEvent(new CustomEvent("selectcall", { detail: {callInfo} }));
        }
    }

    async fetchSupplementaryCallInformation(callId) {
        // asynchronous fetch supplementary call information
        const supplementaryCallInfo = {};
        if(callId) {
            supplementaryCallInfo.id = callId;

            const call = await this._uiApi.getRecord(callId, [
                "Call2_vod__c.Account_vod__c",
                "Call2_vod__c.Account_vod__r.IsPersonAccount",
            ]);
            if(call && call.fields) {

                const callRecordTypeId = call.recordTypeId;
                supplementaryCallInfo.recordTypeId = call.recordTypeId;

                let recordTypeIsUniqueActivity = this.recordTypeUniqueActivityFlag[callRecordTypeId];
                if(recordTypeIsUniqueActivity === null || recordTypeIsUniqueActivity === undefined) {
                    recordTypeIsUniqueActivity = await S4lUtils.doesLayoutHasUniqueActivityField(this._uiApi, callRecordTypeId);
                    this.recordTypeUniqueActivityFlag[callRecordTypeId] = recordTypeIsUniqueActivity;
                }
                supplementaryCallInfo.isUniqueActivity = recordTypeIsUniqueActivity;
                let recordTypeIsSignForDetails = this.recordTypeHasSignForDetails[callRecordTypeId];
                if(recordTypeIsSignForDetails === null || recordTypeIsSignForDetails === undefined) {
                    recordTypeIsSignForDetails = await S4lUtils.doesLayoutHaveSDSectionSignal(this._uiApi, callRecordTypeId);
                    this.recordTypeHasSignForDetails[callRecordTypeId] = recordTypeIsSignForDetails;
                }
                supplementaryCallInfo.isSD = recordTypeIsSignForDetails;

                supplementaryCallInfo.accountId = call.fields.Account_vod__c? call.fields.Account_vod__c.value : null;
                const account = call.fields.Account_vod__r;
                if(account && account.value && account.value.fields) {
                    supplementaryCallInfo.accountIsPersonAccount = account.value.fields.IsPersonAccount? account.value.fields.IsPersonAccount.value : false;
                }
            }
        }
        return supplementaryCallInfo;
    }

    showGeneralAlert(modalData, onCloseHandler) {
        this.alertModalData = {
            title: modalData.title,
            messages: [modalData.message],
            onCloseHandler,
            isVisible: true
        };
    }

    closeGeneralAlert() {
        this.alertModalData = {isVisible: false};
    }

    closeAttendeeViolationAlert() {
        this.showAttendeeViolationAlert = false;
    }

    async getCallData(callId) {
        const qryFlds = this.allowedCallFields.map(fld => `Call2_vod__c.${fld}`);
        const callResult = await this._uiApi.getRecord(callId, qryFlds);
        const uiCallData = this.ctrl.getQueryResultValueObject(callResult, CALL_FIELDS);
        this.additionalOptions.push(this.toCallOption(uiCallData));
        this.setOptions();
    }

    handleSearchClose(e) {
        e.stopPropagation();
        this.showAll = false;
        this.selectedValue = null;
    }

    isCallAlreadyInOption(callId) {
        return this.options.findIndex((option) => option.value === callId) >= 0;
    }

}
export { S4lCallSearchController };