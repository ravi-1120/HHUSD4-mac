import { LightningElement, track, api } from 'lwc';
import getnotificationcount from '@salesforce/apex/MSD_CORE_Notification.getNotificationCount';

export default class Mfr_notificationcount extends LightningElement {

    @api product;
    @api type;
    @api userid;
    productcount;
    connectedCallback(){
        console.log('Connected Call Back');
        this.getnotification();
    }

    // GET Notification List
    getnotification(){
        console.log('<----------:::getnotificationlist:::-------->');
        console.log('product===>',this.product);
        getnotificationcount({prodid: this.product, userid: this.userid})
        .then((result) => {
            console.log('<-------:::Get Notification Result:::------>');
            console.log({result});
            if (this.type == 'Total') {
                this.productcount = result.total;
            }else if (this.type == 'Closed') {
                this.productcount = result.closed;   
            }else if (this.type == 'Appointments') {
                this.productcount = result.appointment;   
            }else if (this.type == 'Save') {
                this.productcount = '0';
            }
        })
        .catch((error) => {
            console.log('<-------:::Get Notification ERROR:::------>');
            console.log({error});
        })
    }

}