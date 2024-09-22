/* eslint-disable no-console */
/* eslint-disable no-use-before-define */
import { api, wire, LightningElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { getPageController } from "c/veevaPageControllerFactory";
import { getService } from 'c/veevaServiceFactory';
import { VeevaMessageRequest } from 'c/veevaMessageService';

import ID from "@salesforce/schema/Multichannel_Activity_vod__c.Id";
import SAVE_FOR_LATER from "@salesforce/schema/Multichannel_Activity_vod__c.Saved_For_Later_vod__c";
import CALL from "@salesforce/schema/Multichannel_Activity_vod__c.Call_vod__c";
import START_DATETIME from "@salesforce/schema/Multichannel_Activity_vod__c.Start_DateTime_vod__c";

import hasAllRequiredFLSToConvertACall from '@salesforce/apex/MCAConvertToCallController.hasAllRequiredFLSToConvertACall';

export default class S4lReconciliationMethodSelection extends LightningElement {

    // input
    @api mcaId;

    // output
    @api exitEarly = false;
    @api methodSelection;
    @api error = null;
    @api mcaDataMapStr = "{}";

    loading = true;
    reconciliationMethods = [];

    @wire(getRecord, { recordId: "$mcaId", fields: MCA_FIELDS })
    async getMultichannelActivityRecord({ error, data }) {
        if (data) {
            const mcaResult = data.fields;
            const mcaDataMap = this.convertMcaResultToMcaObject(mcaResult);
            const flsCheck = await hasAllRequiredFLSToConvertACall();
            if(flsCheck && this.isUnassignedPresentation(mcaDataMap)) {
                // load method selection structure
                this.getMessages().then(() => {
                    // populate the reconciliation methods
                    this.reconciliationMethods = this.getReconciliationMethods();
                    this.loading = false;
                });
            } else {
                const msgSvc = getService('messageSvc');
                if (!flsCheck) {
                    this.error = await msgSvc.getMessageWithDefault(
                        'INSUFFICIENT_PRIVILEGES', 'Common', 'Insufficient Privileges: You do not have the level of access necessary to perform the operation you requested. Please contact the owner of the record or your administrator if access is necessary.');
                } else {
                    this.error = await msgSvc.getMessageWithDefault(
                        'SELECT_UNASSIGNED_PRESENTATION', 'CLM', 'Please select an unassigned presentation');
                }
                this.goToNext();
            }
        } else if (error) {
            console.error(error);
        }
    }

    async getMessages() {
        const veevaMessageSvc = getPageController('messageSvc');
        const msgRequest = new VeevaMessageRequest();
        for (const [label, msg] of Object.entries(MESSAGES)) {
            msgRequest.addRequest(msg.key, msg.category, msg.defaultMessage, label);
        }
        this.labels = await veevaMessageSvc.getMessageMap(msgRequest);
    }

    getReconciliationMethods() {
        return [
            {
                value: RECONCILIATION_METHODS_NEW_CALL,
                label: this.labels.createNewCall,
                iconName: 'custom:custom14',
                defaultChecked: true
            },
            {
                value: RECONCILIATION_METHODS_EXISTING_CALL,
                label: this.labels.addToExistingCall,
                iconName: 'standard:person_account',
                defaultChecked: false
            }
        ];
    }

    convertMcaResultToMcaObject(mcaResult) {
        const result = {};
        if(mcaResult) {
            for(const field of MCA_FIELDS) {
                const fieldName = field.fieldApiName;
                if(mcaResult[fieldName]) {
                    result[fieldName] = mcaResult[fieldName].value;
                } else {
                    result[fieldName] = undefined;
                }
            }
        }
        return result;
    }

    isUnassignedPresentation(mca) {
        return mca[SAVE_FOR_LATER.fieldApiName] === true &&
            mca[CALL.fieldApiName] === null;
    }

    handleNext() {
        const selected = [...this.template.querySelectorAll('input[type="radio"][name="reconciliationMethod"]')].filter(radio => radio.checked);
        if(selected && selected.length) {
            const selectedOption = selected[0];
            this.selectMethod(selectedOption.value);
        }
    }

    handleCancel() {
        this.methodSelection = null;
        this.exitEarly = true;
        this.goToNext();
    }

    selectMethod(method) {
        this.methodSelection = method;
        this.goToNext();
    }

    goToNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

}

const RECONCILIATION_METHODS_NEW_CALL = 'createNewCall';
const RECONCILIATION_METHODS_EXISTING_CALL = 'addToExistingCall';

const MCA_FIELDS = [
    ID,
    SAVE_FOR_LATER,
    CALL,
    START_DATETIME
];

const MESSAGES = {
    convertToCall: {
        key: "CONVERT_TO_CALL",
        category: "CLM",
        defaultMessage: "Convert To Call"
    },
    createNewCall: {
        key: "CREATE_NEW_CALL",
        category: "CLM",
        defaultMessage: "Create New Call"
    },
    addToExistingCall: {
        key: "ADD_TO_EXISTING_CALL",
        category: "CLM",
        defaultMessage: "Add to Existing Call"
    },
    cancel: {
        key: "CANCEL",
        category: "Common",
        defaultMessage: "Cancel"
    },
    next: {
        key: "NEXT",
        category: "Common",
        defaultMessage: "Next"
    }
};