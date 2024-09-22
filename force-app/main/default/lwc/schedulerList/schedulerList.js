/*import { LightningElement, api, wire } from 'lwc';
import SCHEDULER_OBJECT from '@salesforce/schema/Scheduler_Configuration__c';
import NAME_FIELD from '@salesforce/schema/Scheduler_Configuration__c.Name';
import getAdminSchedulers from '@salesforce/apex/SchedulerController.getAdminSchedulers';
import createScheduleRequest from '@salesforce/apex/ScheduleRequest.createScheduleRequest';
const actions = [
    { label: 'Show details', name: 'show_details' },
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

const COLUMNS = [
    { label: 'Name', fieldName: NAME_FIELD.fieldApiName, type: 'text' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
];*/

export default class SchedulerList extends LightningElement {
    /*columns = COLUMNS;
    showAdminComponent = false;
    @wire(getAdminSchedulers)
    schedules;
    @wire(createScheduleRequest)
    newScheduler;

    @api schedulerObj = {
        name: 'Test Name',

    }
    
    handleClick(){
        this.showAdminComponent = true;
        console.log("new Scheduler Obj "+this.schedulerObj);
    }
    @api ready = false;
    connectedCallback() {
        setTimeout(() => {
            this.ready = true;
        }, 500);
    }*/
}