import { LightningElement,api,track,wire } from 'lwc';
import USER_ID from "@salesforce/user/Id";
import getUserInfo from '@salesforce/apex/MSD_CORE_ProductList.getUserInfo';
const monthShortNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
export default class AppointmentPendingtime extends LightningElement {
    @api meetingtimes;
    @track displaytime;
    @track date;
    @track month;
    @track time;
    @track setDefaultime;
    @track timezonetype;
    @track calText;

    @wire(getUserInfo, {userId: USER_ID}) 
    wireuser({error,data}) {
        if (error) {
            this.error = error; 
        } else if (data) {
            console.log('inside wire'+data);
            console.log(JSON.stringify(data));
            this.setDefaultime=data.TimeZoneSidKey;
            console.log('this.setDefaultime'+this.setDefaultime);
            this.timezonetype='short';
        }
    }

    connectedCallback() {
        console.log('meetingtimes : ',this.meetingtimes);
        this.displaytime = true;
        if(this.meetingtimes){
            console.log(this.meetingtimes.length);
            if(this.meetingtimes.length == 1){
                // this.date = this.meetingtimes[0].MSD_CORE_Meeting_Date__c;
                // this.month = this.meetingtimes[0].MSD_CORE_Meeting_Date__c;

                // Start of Resolve Date ISSUE
                let dt = new Date(this.meetingtimes[0].MSD_CORE_Meeting_Date__c);
                dt = dt.toISOString().split('T')[0];
                this.date = dt.split('-')[2];
                this.month = monthShortNames[dt.split('-')[1]-1];
                // End of Resolve Date ISSUE
                
                this.time = this.meetingtimes[0].MSD_CORE_Time_Slot__c;
            }else{
                this.displaytime = false;
                this.calText = 'Multiple Dates Preferred';
            }
        }else{
            /** RR - E2ESE-1011 */
            this.displaytime = false;
            this.calText = 'No appointment needed';
        }
    }

    getDay(date) {
        let d = new Date(date);
        return d.getDay();
    }
    getMonth(date) {
        let d = new Date(date);
        return monthShortNames[d.getMonth()];
    }
    getYear(date) {
        let d = new Date(date);
        return d.getFullYear();
    }
    getFullMonth(date) {
        let d = new Date(date);
        return monthNames[d.getMonth()];
    }
    getTime(date) {
        let d = new Date(date);
        let time = d.toLocaleTimeString('en-US');
        let AMPM = time.substring(time.length - 2, time.length);
        let tempTime = time.substring(0, 5);
        return tempTime + ' ' + AMPM;
    }
}