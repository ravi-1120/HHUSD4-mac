import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent }  from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord, createRecord, RecordFieldDataType } from 'lightning/uiRecordApi';
import SCHEDULER_OBJECT from '@salesforce/schema/Scheduler_Configuration__c';
import NAME_FIELD from '@salesforce/schema/Scheduler_Configuration__c.Name';
import ID_FIELD from '@salesforce/schema/Scheduler_Configuration__c.Id';
import { NavigationMixin } from 'lightning/navigation';
const FIELDS = [NAME_FIELD, ID_FIELD];
export default class SchedulerCreate extends NavigationMixin(LightningElement) {
    @api name;
    @api recordId;
    @api newScheduler = {
        name : ''
    };
    @api counter;
    nameChange(event) {
        console.log('in name change');
        this.name= event.target.value;

    }
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        console.log("Get Record in Create component"+this.recordId);
        if(data){
            console.log("Success Data"+data.fields.Name.value);
            this.name = data.fields.Name.value;
        }
        else if(error){
            console.log("Error Data"+error);
            this.name = null;
            this.recordId = null;
        }
    }
    handleCancel(){
        this.counter = 0;
        this.dispatchEvent(new CustomEvent('cancel', {
            detail: [this.counter, this.recordId]
        }));
        if(this.recordId && this.recordId!=null){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'Scheduler_Configuration__c',
                    actionName: 'view'
                }
            });
        }else{
                   this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Scheduler_Configuration__c',
                actionName: 'list'
            },
            state: {
               
                filterName: 'Recent' 
            }
        });
        }
    }
    handleNext(){
        console.log("counter"+this.counter);
        console.log("record ID"+this.recordId);
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        if (isInputsCorrect) {
            console.log(this.name);
            //console.log('Scheduler Object'+this.newScheduler.name);
            const recordInput = {
                apiName: SCHEDULER_OBJECT.objectApiName,
                fields: {
                    [NAME_FIELD.fieldApiName] : this.name
                }
            };
            const recordUpdateInput = {
                fields: {
                    [NAME_FIELD.fieldApiName] : this.name,
                    [ID_FIELD.fieldApiName] : this.recordId
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
            else{
                createRecord(recordInput)
                .then(account => {
                    console.log("response id"+account.id);
                    this.recordId = account.id;
                    console.log("After create, record ID"+this.recordId);
                    // code to execute if create operation is successful
                    this.counter = this.counter + 1;
                    this.dispatchEvent(new CustomEvent('next', {
                        detail: [this.counter, this.recordId]
                    }));
                })
                .catch(error => {
                    // code to execute if create operation is not successful
                    console.log(error);
                });

            }
            
        }
    }
}