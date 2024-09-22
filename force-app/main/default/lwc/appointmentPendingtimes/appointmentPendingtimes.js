import { LightningElement, api, track } from 'lwc';

export default class AppointmentPendingtime extends LightningElement {
    @api meetingtimes;
    @track displaytime = true;
    @api labelval = false;

    connectedCallback() {
        console.log('1' + JSON.stringify(this.meetingtimes));
        
        if (this.meetingtimes && this.meetingtimes.length === 1) {
            this.displaytime = false;
            this.labelval = false;
        } else if (this.meetingtimes && this.meetingtimes.length > 1) {
            this.displaytime = true;
        } else {
            this.labelval = false;
            this.displaytime = true;
        }

        // Format the meeting times
        if (this.meetingtimes) {
            this.meetingtimes = this.meetingtimes.map(meettime => {
                return {
                    ...meettime,
                    formattedDate: this.formatDate(meettime.MSD_CORE_Meeting_Date__c)
                };
            });
        }

        console.log('displaytime: ' + this.displaytime);
        console.log('labelval: ' + this.labelval);
    }

    formatDate(dateTimeStr) {
        const date = new Date(dateTimeStr);
        const options = {
            weekday: 'long',
            month: 'long',
            day: 'numeric'
        };
        return date.toLocaleDateString('en-US', options);
    }
}