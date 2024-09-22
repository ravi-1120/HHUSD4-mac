import { LightningElement, api, wire,track} from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent }  from 'lightning/platformShowToastEvent';

import SCHEDULER_OBJECT from '@salesforce/schema/Scheduler_Configuration__c';
import CHANNELS_FIELD from '@salesforce/schema/Scheduler_Configuration__c.Communication_Channels__c';
import ID_FIELD from '@salesforce/schema/Scheduler_Configuration__c.Id';
import updateCommunicationChannels from '@salesforce/apex/SchedulerPayloadGenerator.updateCommunicationChannels';
//import { getSObjectValue } from '@salesforce/apex';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';

const FIELDS = [
    CHANNELS_FIELD
];


export default class SchedulerChannels extends LightningElement {
    @api counter;
    @api recordId;
    @api selectedChannels = [];
    channelsPicklist=[];
    @track channels;

    // to get the default record type id, if you dont' have any recordtypes then it will get master
    @wire(getObjectInfo, { objectApiName: SCHEDULER_OBJECT })
    schedulerMetadata;
    
    // now get the industry picklist values
    @wire(getPicklistValues,
        {
            recordTypeId: '$schedulerMetadata.data.defaultRecordTypeId', 
            fieldApiName: CHANNELS_FIELD
        }

    )

    retrievePicklist(wireResult){
        this.channelsPicklist=wireResult;
        console.log("channelsPicklist", JSON.stringify(this.channelsPicklist));
        //console.log("this.channelsPicklist.data.values", JSON.stringify(this.channelsPicklist.data));
        if(this.channelsPicklist && this.channelsPicklist.data && this.channelsPicklist.data.values){
            for( let i=0; i<this.channelsPicklist.data.values.length; i++){
                var picklistV=this.channelsPicklist.data.values[i];
                console.log("picklistV", picklistV);
                if(this.channels!=null && this.channels!=undefined && this.channels.indexOf(picklistV.value) !== -1){
                    this.updatedChannels.push({value:picklistV.value,label:picklistV.label, salect:true});
                    this.selectedChannels.push(picklistV.label);
                }else{
                    this.updatedChannels.push({value:picklistV.value,label:picklistV.label, salect:false});
                }
            }
            console.log('updatedChannels  ', this.updatedChannels)
        }
    }
    
    _wiredConfigData;
    @track updatedChannels=[] ;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    retrieveConfig(wireResult){
        const { data, error } = wireResult;
        this._wiredConfigData = wireResult;
        if(data){
            console.log("OppData", JSON.stringify(data));
            this.channels = getFieldValue(data, CHANNELS_FIELD) ;
            console.log("channels", this.channels);
            console.log("channelsPicklist", this.channelsPicklist);
            if(this.channelsPicklist && this.channelsPicklist.data && this.channelsPicklist.data.values){
                this.updatedChannels=[];
                for( let i=0; i<this.channelsPicklist.data.values.length; i++){
                    var picklistV=this.channelsPicklist.data.values[i];
                    console.log("picklistV", picklistV);
                    if(this.channels!=null && this.channels!=undefined && this.channels.indexOf(picklistV.value) !== -1){
                        this.updatedChannels.push({value:picklistV.value,label:picklistV.label, salect:true});
                        this.selectedChannels.push(picklistV.label);
                    }else{
                        this.updatedChannels.push({value:picklistV.value,label:picklistV.label, salect:false});
                    }
                }
            }
        }else{
            if(this.channelsPicklist && this.channelsPicklist.data && this.channelsPicklist.data.values){
            for( let i=0; i<this.channelsPicklist.data.values.length; i++){
                    var picklistV=this.channelsPicklist.data.values[i];
                    this.updatedChannels.push({value:picklistV.value,label:picklistV.label, salect:false});
                }
            }
        }
        if(error) {
            console.error(error)
        }
    }

    @api ready = false;
    connectedCallback() {
        this.ready = true;
        refreshApex(this._wiredConfigData);
    }

    channelsChange(event){
        if(event.target.checked){
            this.selectedChannels.push(event.target.label);
        }
        else if(!event.target.checked){
            let pos = this.selectedChannels.indexOf(event.target.label);
            let deletedItem = this.selectedChannels.splice(event.target.label, 1);
        }
        console.log("1 - channels selected" + this.selectedChannels);
    }

    handleNext(){
        const recordUpdateInput = {
            fields: {
                [CHANNELS_FIELD.fieldApiName] : this.selectedChannels.join(";"),
                [ID_FIELD.fieldApiName] : this.recordId
            }
        };
        if(this.recordId){
            updateRecord(recordUpdateInput)
            .then(() => {
                updateCommunicationChannels({recordId : this.recordId})
                .then(() => {
                    this.counter = this.counter + 1;
                    this.dispatchEvent(new CustomEvent('next', {
                        detail: [this.counter, this.recordId]
                    }));
                });  
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
        console.log("previous event"+this.counter);
        this.dispatchEvent(new CustomEvent('previous', {
            detail: [this.counter, this.recordId]
        }));
    }
}