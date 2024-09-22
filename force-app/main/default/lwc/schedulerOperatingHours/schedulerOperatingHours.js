import { LightningElement, wire, track,api } from 'lwc';
import getTemplatesMapping from '@salesforce/apex/BusinessRulesController.getTemplatesMapping';
import getHolidays from '@salesforce/apex/BusinessRulesController.getHolidays';
import addHolidaysByGroup from '@salesforce/apex/BusinessRulesController.addHolidaysByGroup';

export default class SchedulerOperatingHours extends LightningElement {
    @api counter;
    @api recordId;
    @track templatesMapping;
    holidaysList;
    groupId;
    showHolidayModal = false;
    timeoutId;
    showSpinner = false;
    initialTimeoutId;

    @wire(getTemplatesMapping)
    templatesMap({data,error}){
        if(data){
            console.log("Templates mapping"+JSON.stringify(data));
            this.templatesMapping = data;
            this.showSpinner = true;
            let tempSpin = false
            clearTimeout(this.initialTimeoutId);
            this.initialTimeoutId = setTimeout(this.handleSpinner.bind(this, tempSpin), 6000);
        }
        else if(error){
            console.log("Error Data" + error);
        }
    }

    handleSpinner(showspin){
        this.showSpinner = showspin;
    }

    handleHolidays(event){
        this.showSpinner = true;
        let groupId = event.currentTarget.dataset.groupId;
        this.groupId = groupId;
        console.log('group Id'+ groupId);
        let tempHolidayModal = true;
        getHolidays({groupId : groupId})
        .then((result) =>{
            this.holidaysList = result;
            tempHolidayModal = true;
            clearTimeout(this.timeoutId);
            this.timeoutId = setTimeout(this.handleHolidayModal.bind(this, tempHolidayModal), 7000);
        })
        .catch((error)=>{
            console.log('Error=>' + JSON.stringify(error.message));
            tempHolidayModal = false;
            this.showSpinner = false;
        }) 
    }

    handleHolidayModal(tempHolidayModal){
        this.showSpinner = false;
        this.showHolidayModal = tempHolidayModal;
    }
    
    handleClose(event){
        var detail = event.detail;
        this.showHolidayModal = detail.checkModal;
    }
    
    handleNext(){
        console.log("counter"+this.counter);
        addHolidaysByGroup({recordId: this.recordId})
        .then((result)=>{
            console.log("success"+result);
        })
        .catch((error)=>{
            console.log("error"+error);
        })
        // code to execute if create operation is successful
        this.counter = this.counter + 1;
        this.dispatchEvent(new CustomEvent('next', {
            detail: [this.counter, this.recordId]
        }));
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