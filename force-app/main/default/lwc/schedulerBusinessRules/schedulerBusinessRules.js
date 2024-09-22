import { LightningElement, api, wire, track } from 'lwc';
import getSelectedTemplates from '@salesforce/apex/BusinessRulesController.getSelectedTemplates';
import getCallRouting from '@salesforce/apex/BusinessRulesController.getCallRouting';
import { getRecord, RecordFieldDataType } from 'lightning/uiRecordApi';
import JSON_PAYLOAD_FIELD from '@salesforce/schema/Scheduler_Configuration__c.JSON_Payload__c';
import ID_FIELD from '@salesforce/schema/Scheduler_Configuration__c.Id';
const FIELDS = [JSON_PAYLOAD_FIELD, ID_FIELD];


export default class SchedulerBusinessRules extends LightningElement {
    @api counter;
    @api recordId;
    @api ready = false;
    templateNames = [];
    index = 0;
    hasRendered = false;
    routingResponse;
    showRoutingResponse = false;
    products = [];
    disableGetRouting = false;
    timeoutId;

    //validate if the payload is already available with the dynamic routing response - disable generate routing button
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        console.log("Get Record in BusinessRules component" + this.recordId);
        if (data) {
            let schedulerPayload = JSON.parse(data.fields.JSON_Payload__c.value);
            console.log('payload-->' + JSON.stringify(schedulerPayload));
            if (schedulerPayload.assignmentGroups != undefined && schedulerPayload.assignmentGroups.length > 0) {
                console.log('assignmentGroups-->' + JSON.stringify(schedulerPayload.assignmentGroups));
                let assignmentGroupsObj = {};
                assignmentGroupsObj.assignmentGroups = schedulerPayload.assignmentGroups;
                this.routingResponse = assignmentGroupsObj;
                console.log(JSON.stringify(this.routingResponse));
                this.showRoutingResponse = true;
                this.disableGetRouting = true;
            }
        }else if (error) {
            console.log("Error Data" + error);
            this.showRoutingResponse = false;
            this.disableGetRouting = false;
        }
    }

    @wire(getSelectedTemplates, { recordId: '$recordId' })
    templateData({ data, error }) {
        if (data !== undefined) {
            console.log('data' + JSON.stringify(data));
            this.templateNames = data.templates;
            this.products = data.products;
            console.log('templateNames' + JSON.stringify(this.templateNames));
            this.ready = true;
        } else {
            console.log('IN getTemplates ERROR' + JSON.stringify(error));
        }
    }

    handleDynamicRoutingLogic() {
        if (this.templateNames != undefined) {
            console.log('templates-->' + this.templateNames);
            this.ready = false;
            
            getCallRouting({ appointmentTemplates: this.templateNames, products: this.products, recordId: this.recordId })
            .then((result) => {
                this.ready = true;
                console.log('result--> ' + result);
                this.routingResponse = JSON.parse(result);
                this.showRoutingResponse = true;
                this.disableGetRouting = true;
            })
            .catch((error) => {
                this.ready = true;
                console.log('error-->' + JSON.stringify(error));
            });
        }
    }

    handleNext() {
        this.selectedRecords = [];
        let selectedRows = this.template.querySelectorAll('lightning-input');
        // code to execute if create operation is successful
        this.ready = false;
        var tempCounter = this.counter + 1;
        clearTimeout(this.timeoutId);
        this.timeoutId = setTimeout(this.captureEvent.bind(this, tempCounter), 6000);

    }

    captureEvent(tempCounter) {
        console.log('tempCounter-->'+tempCounter);
        this.counter = this.counter + 1;
        this.ready = true;
        this.dispatchEvent(new CustomEvent('next', {
            detail: [tempCounter, this.recordId]
        }));
    }

    handlePrevious() {
        console.log("counter" + this.counter);
        // code to execute if create operation is successful
        this.counter = this.counter - 1;
        this.dispatchEvent(new CustomEvent('previous', {
            detail: [this.counter, this.recordId]
        }));
    }

}