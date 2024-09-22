import { api, wire, LightningElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import VeevaMessageService from 'c/veevaMessageService';

import ID from "@salesforce/schema/Multichannel_Activity_vod__c.Id";
import SAVE_FOR_LATER from "@salesforce/schema/Multichannel_Activity_vod__c.Saved_For_Later_vod__c";
import CALL from "@salesforce/schema/Multichannel_Activity_vod__c.Call_vod__c";
import START_DATETIME from "@salesforce/schema/Multichannel_Activity_vod__c.Start_DateTime_vod__c";

export default class ConvertToCallMethodSelectionVod extends LightningElement {

    // input
    @api mcaId;

    // output
    @api exitEarly = false;
    @api methodSelection;
    @api error = null;
    @api mcaDataMapStr = "{}";

    preloading = true;

    startTime = new Date().getTime();

    constructor() {
        super();
    }

    @wire(getRecord, { recordId: "$mcaId", fields: MCA_FIELDS })
    async getMultichannelActivityRecord({ error, data }) {
        if (data) {
            let mcaResult = data.fields;
            let mcaDataMap = this.convertMcaResultToMcaObject(mcaResult);
            this.mcaDataMapStr = JSON.stringify(mcaDataMap);
            if(this.isUnassignedPresentation(mcaDataMap)) {
                // future: load method selection component
                // for now: load the 'create a new call' method by default
                this.preloading = false;
                this.methodSelection = RECONCILIATION_METHODS_NEW_CALL;
                this.goToNext();
            } else {
                let msgSvc = new VeevaMessageService();
                this.error = await msgSvc.getMessageWithDefault(
                    'SELECT_UNASSIGNED_PRESENTATION', 'CLM', 'Please select an unassigned presentation');
                this.goToNext();
            }
        } else if (error) {
            console.error(error);
        }
    }

    convertMcaResultToMcaObject(mcaResult) {
        let result = {};
        if(mcaResult) {
            for(const field of MCA_FIELDS) {
                let fieldName = field.fieldApiName;
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

    goToNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

}

const RECONCILIATION_METHODS_NEW_CALL = 'createNewCall';

const MCA_FIELDS = [
    ID,
    SAVE_FOR_LATER,
    CALL,
    START_DATETIME
];