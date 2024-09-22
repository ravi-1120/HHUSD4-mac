import { LightningElement, api, wire, track} from 'lwc';
//import { ShowToastEvent }  from 'lightning/platformShowToastEvent';
import createScheduleRequest from '@salesforce/apex/ScheduleRequest.createScheduleRequest';
import { NavigationMixin } from 'lightning/navigation';

export default class SchedulerAdmin extends NavigationMixin(LightningElement) {
    @api recordId;
    @api page = 0;
    currentStep = "0";
    page0 = true;
    page1 = false;
    page2 = false;
    page3 = false;
    page4 = false;
    page5 = false;
    page6 = false;
    isTemplateFromPrevious = false;

    @wire(createScheduleRequest)
    newScheduler;

    handleNext(event){
        const factor = event.detail;
        this.page = factor[0];
        this.recordId = factor[1];
        console.log('In Next, Parent record ID'+this.recordId);
        this.currentStep = this.page.toString();
        
        if(this.page === 0){
            this.page0 = true;
            this.page1 = false;
            this.page2 = false; 
            this.page3 = false;
            this.page4 = false;
            this.page5 = false;
            this.page6 = false;
        }
        else if(this.page === 1){
           this.page0 = false;
           this.page1 = true;
           this.page2 = false; 
           this.page3 = false;
           this.page4 = false;
           this.page5 = false;
           this.page6 = false;
        }
        else if(this.page === 2){
            this.page0 = false;
            this.page1 = false;
            this.page2 = true;
            this.page3 = false;
            this.page4 = false;
            this.page5 = false;
            this.page6 = false;
        }
        else if(this.page === 3){
            this.page0 = false;
            this.page1 = false;
            this.page2 = false;
            this.page3 = true;
            this.page4 = false;
            this.page5 = false;
            this.page6 = false;
        }
        else if(this.page === 4){
            this.page0 = false;
            this.page1 = false;
            this.page2 = false;
            this.page3 = false;
            this.page4 = true;
            this.page5 = false;
        }
        else if(this.page === 5){
            this.page0 = false;
            this.page1 = false;
            this.page2 = false;
            this.page3 = false;
            this.page4 = false;
            this.page5 = true;
            this.page6 = false;
        }
        else if(this.page === 6){
            this.page0 = false;
            this.page1 = false;
            this.page2 = false;
            this.page3 = false;
            this.page4 = false;
            this.page5 = false;
            this.page6 = true;
        }
        else {
            this.page0 = true;
            this.page1 = false;
            this.page2 = false; 
            this.page3 = false;
            this.page4 = false;
            this.page5 = false;
            this.page6 = false;
        }        
    }

    handlePrevious(event){
        const factor = event.detail;
        this.page = factor[0];
        this.recordId = factor[1];
        console.log('In Previous, Parent record ID'+this.recordId);
        console.log("previous"+this.page);
        this.currentStep = this.page.toString();
        if(this.page === 0){
            this.page0 = true;
            this.page1 = false;
            this.page2 = false; 
            this.page3 = false;
            this.page4 = false;
            this.page5 = false;
            this.page6 = false;
        }
        else if(this.page === 1){
           this.page0 = false;
           this.page1 = true;
           this.page2 = false; 
           this.page3 = false;
           this.page4 = false;
           this.page5 = false;
           this.page6 = false;
           this.isTemplateFromPrevious = true;
        }
        else if(this.page === 2){
            this.page0 = false;
            this.page1 = false;
            this.page2 = true;
            this.page3 = false;
            this.page4 = false;
            this.page5 = false;
            this.page6 = false;
        }
        else if(this.page === 3){
            this.page0 = false;
            this.page1 = false;
            this.page2 = false;
            this.page3 = true;
            this.page4 = false;
            this.page5 = false;
            this.page6 = false;
        }
        else if(this.page === 4){
            this.page0 = false;
            this.page1 = false;
            this.page2 = false;
            this.page3 = false;
            this.page4 = true;
            this.page5 = false;
        }
        else if(this.page === 5){
            this.page0 = false;
            this.page1 = false;
            this.page2 = false;
            this.page3 = false;
            this.page4 = false;
            this.page5 = true;
            this.page6 = false;
        }
        else if(this.page === 6){
            this.page0 = false;
            this.page1 = false;
            this.page2 = false;
            this.page3 = false;
            this.page4 = false;
            this.page5 = false;
            this.page6 = true;
        }
        else {
            this.page0 = true;
            this.page1 = false;
            this.page2 = false; 
            this.page3 = false;
            this.page4 = false;
            this.page5 = false;
            this.page6 = false;
        }
    }
}