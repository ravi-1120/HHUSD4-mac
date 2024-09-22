import { LightningElement, api, wire} from 'lwc';
import getSchedulerLink from '@salesforce/apex/SchedulerController.getSchedulerLink';
import { NavigationMixin } from 'lightning/navigation';

export default class SchedulerSourceCode extends  NavigationMixin(LightningElement) {
    @api counter;
    @api recordId;
    iframeUrl;
    expCloudUrl;
    value = 'iframe';

    get options() {
        return [
            { label: 'iFrame', value: 'iframe' },
            { label: 'Source Link', value: 'source' },
        ];
    }

    handlePrevious(){
        console.log("counter"+this.counter);
        this.counter = this.counter - 1;
        this.dispatchEvent(new CustomEvent('previous', {
            detail: [this.counter, this.recordId]
        }));
    }

    handleClose(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Scheduler_Configuration__c',
                actionName: 'view'
            }
        });
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    handleCode(){
        getSchedulerLink({ //imperative Apex call
            schedulerId: this.recordId, 
            type : this.value
        })
        .then(site => {
            console.log("Source Link"+JSON.stringify(site));
            let expUrl=site.exp.SecureUrl.replace('vforcesite','');
            this.expCloudUrl = expUrl+"?schedulerId="+this.recordId;
            this.iframeUrl = "<iframe src=" + "\""+expUrl+"?schedulerId="+this.recordId+"\""+"></iframe>";
            console.log("iFrame"+this.iframeUrl);                    
        })
        .catch(error => {
            console.log('Error: '+error);
        });
    }

}