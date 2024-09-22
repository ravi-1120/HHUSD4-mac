import { LightningElement, wire, api } from 'lwc';
import getactivityDetail from '@salesforce/apex/MSD_CORE_Notification.getActivityDetail';
import downarrow from '@salesforce/resourceUrl/downarrow';
import rightarrow from '@salesforce/resourceUrl/rightarrow2';
import USER_ID from "@salesforce/user/Id";

export default class Mfr_activitySubDetail extends LightningElement {
    arrow = rightarrow;
    downarrow = downarrow;
    @api productID
    @api meetingRequest;
    @api activityID
    activityDetail;

    @wire(getactivityDetail, { userid: USER_ID, prodID: '$productID',parentNotificationID:'$activityID'})
    wiredgetactivityDetail(value) {
        console.log('wiredgetactivityDetail');
        console.log('Value of getactivityDetail-->',{ value });
        const { data, error } = value;
        if (data) {
            if (data == null) {
                console.log('Null');
            } else {
                try {
                    this.activityDetail = data;
                    console.log('this.activityDetail-->', this.activityDetail);
                } catch (error) {
                    console.log({ error });
                }
            }
        } else if (error) {
            this.error = error;
            console.log('error in getRequestsCount ' + JSON.stringify(this.error));
        }
    }

}