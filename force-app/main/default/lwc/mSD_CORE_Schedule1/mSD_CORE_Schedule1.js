import { LightningElement } from 'lwc';

import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

import banner from '@salesforce/resourceUrl/PurpleBanner';
import MSD_CORE_LeftArrow from '@salesforce/resourceUrl/MSD_CORE_LeftArrow';
import MSD_CORE_Plus from '@salesforce/resourceUrl/MSD_CORE_Plus';

import DateTimeJS from '@salesforce/resourceUrl/DateTimeJS';
import radiocss from '@salesforce/resourceUrl/radiocss';
import { NavigationMixin } from 'lightning/navigation';
export default class MSD_CORE_Schedule1 extends NavigationMixin(LightningElement) {

    bannerimg = banner;
    leftarrow = MSD_CORE_LeftArrow;
    plusicon = MSD_CORE_Plus;

    get options() {
        return [
            { label: 'New', value: 'new' },
            { label: 'In Progress', value: 'inProgress' },
            { label: 'Finished', value: 'finished' },
        ];
    }

    get meetingoption() {
        return [
            { label: 'In-Person', value: 'In-Person' },
            { label: 'Virtual', value: 'Virtual' },
        ];
    }

    get timeoption() {
        return [
            { label: 'No preference', value: 'No preference' },
            { label: '09:00 AM - 10:00 AM EST', value: '09:00AM - 10:00AM' },
            { label: '10:00 AM - 11:00 AM EST', value: '10:00AM - 11:00AM' },
            { label: '11:00 AM - 12:00 PM EST', value: '11:00AM - 12:00PM' },
            { label: '12:00 PM - 01:00 PM EST', value: '12:00PM - 01:00PM' },
            { label: '01:00 PM - 02:00 PM EST', value: '01:00PM - 02:00PM' },
            { label: '02:00 PM - 03:00 PM EST', value: '02:00PM - 03:00PM' },
            { label: '03:00 PM - 04:00 PM EST', value: '03:00PM - 04:00PM' },
            { label: '04:00 PM - 05:00 PM EST', value: '04:00PM - 05:00PM' },
            { label: '05:00 PM - 06:00 PM EST', value: '05:00PM - 06:00PM' },
            { label: '06:00 PM - 07:00 PM EST', value: '06:00PM - 07:00PM' },
            { label: '07:00 PM - 08:00 PM EST', value: '07:00PM - 08:00PM' },
            { label: '08:00 PM - 09:00 PM EST', value: '08:00PM - 09:00PM' },
            { label: '09:00 PM - 10:00 PM EST', value: '09:00PM - 10:00PM' },
        ]
    }

    renderedCallback() {
        Promise.all([
            loadScript(this, DateTimeJS),
            loadStyle(this, radiocss),
        ]).then(() => {
            console.log('Files loaded');
        })
    }

    handleChange(event) {
        var selectedval = event.target.value;
        console.log({ selectedval });
    }

    navigateback(){
         this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'pipeline__c',
                },
            });
    }
}