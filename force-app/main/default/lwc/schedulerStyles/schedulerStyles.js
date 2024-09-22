import { LightningElement, api, wire} from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
//import SCHEDULER_OBJECT from '@salesforce/schema/Scheduler_Configuration__c';
import COLOR_FIELD from '@salesforce/schema/Scheduler_Configuration__c.Color__c';
import BGCOLOR_FIELD from '@salesforce/schema/Scheduler_Configuration__c.Background_Color__c';
import ID_FIELD from '@salesforce/schema/Scheduler_Configuration__c.Id';
//import { getSObjectValue } from '@salesforce/apex';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
const FIELDS = [
    COLOR_FIELD,BGCOLOR_FIELD
];
export default class SchedulerStyles extends LightningElement {
    @api counter;
    @api recordId;
    @api bgColor;
    @api color;
    _wiredConfigData;
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    retrieveConfig(wireResult){
    const { data, error } = wireResult;
    this._wiredConfigData = wireResult;
    if(data){
        console.log("OppData", JSON.stringify(data));
        this.bgColor = getFieldValue(data, BGCOLOR_FIELD) ;
        this.color =   getFieldValue(data, COLOR_FIELD) ;
    }
    if(error) {
        console.error(error)
    }
}
   

connectedCallback() {
console.log('calling refresh')
refreshApex(this._wiredConfigData);
}
    colorChange(event) {
        console.log("color change"+event.target.value);
        this.color= event.target.value;

    }
    bgcolorChange(event) {
        console.log("Back ground color change"+event.target.value);
        this.bgColor = event.target.value; 

    }
    handleNext(){
        const recordUpdateInput = {
            fields: {
                [BGCOLOR_FIELD.fieldApiName] : this.bgColor,
                [ID_FIELD.fieldApiName] : this.recordId,
                [COLOR_FIELD.fieldApiName] : this.color
            }
        };
        if(this.recordId){
            updateRecord(recordUpdateInput)
            .then(() => {
                this.counter = this.counter + 1;
                this.dispatchEvent(new CustomEvent('next', {
                    detail: [this.counter, this.recordId]
                }));
                
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
        }
    }

    handlePrevious(){
        console.log("counter"+this.counter);
        // code to execute if create operation is successful
        this.counter = this.counter - 1;
        this.dispatchEvent(new CustomEvent('previous', {
            detail: [this.counter, this.recordId]
        }));
    }
}