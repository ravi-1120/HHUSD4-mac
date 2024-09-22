import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import USER_ID from "@salesforce/user/Id";
import getApprovedAppointment from '@salesforce/apex/MSD_CORE_ProductList.getAppointmentPerUser';
import newlogo9 from '@salesforce/resourceUrl/downarrow';
import uparrow from '@salesforce/resourceUrl/uparrowicon';
import getUserInfo from '@salesforce/apex/MSD_CORE_ProductList.getUserInfo';
import newlogo7 from '@salesforce/resourceUrl/rightarrow2';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';

export default class MfrAppointmentdisplay extends NavigationMixin(LightningElement) {

    @track appointment = [];
    @track appointment1 = [];
    logo10 = newlogo9;               //Down Arrow icon
    @track showmore = false;
    @track appmore = false;
    uparrowimg = uparrow;
    @track setDefaultime;
    @track timezonetype;
    @track contactrole = '';
    norecord = false;
    logo8 = newlogo7;               //Arrow icon

    @wire(getUserInfo, { userId: USER_ID })
    wireuser({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            console.log('inside wire' + data);
            console.log(JSON.stringify(data));
            this.setDefaultime = data.TimeZoneSidKey;
            console.log('Upcoming appointments == this.setDefaultime' + this.setDefaultime);
            this.timezonetype = 'short';
        }
    }

    navigatepage(event) {

        var getnameval = event.currentTarget.dataset.name;
        
        if (getnameval == 'ProductList') {
            this.fireDataLayerEvent('button','','browse catalog', 'vertical','Productlistpage__c','/product-list-page',''); //RT-1053
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                    name: 'Productlistpage__c',
                    url: '/product-list-page'
                },
            });
        }
        else {
            var recId = event.currentTarget.dataset.id;
            var tabname = event.currentTarget.dataset.name;
            this.fireDataLayerEvent('button','','appointments', 'vertical','Productlistpage__c','/product-list-page',event.currentTarget.dataset.contentname);
            console.log('Tab name=' + tabname);
            console.log('Raviteja>>>>>' +event.currentTarget.dataset.contentname);
            /* this[NavigationMixin.Navigate]({
                 type: 'comm__namedPage',
                 attributes: {
                     name: 'schedule__c'
                 },
                 state: {
                     recordId: recId
                 }
             }); */

            var pageapi;
            var pagename;
            getSiteNameAndAPIName({ pageName: 'viewschedule' })
                .then((result) => {
                    console.log('getSiteNameAndAPIName-->' + JSON.stringify(result));
                    pageapi = result.siteName;
                    pagename = result.siteAPIName;
                    // pageapi = 'viewschedule__c';
                    // pagename = '/library/viewschedule';
                    this[NavigationMixin.Navigate]({
                        // type: 'comm__namedPage',
                        // attributes: {
                        //     name: pageapi,
                        //     url: pagename
                        // },
                        // state: {
                        //     recordId: recId
                        // }
                        type: 'standard__webPage',
                        attributes: {
                            name: pageapi,
                            url: pagename+'?recordId='+recId
                        }
                    });
                })
                .catch((error) => {
                    console.log('error-->' + error);
                    this.error = error;
                });
        }
    }

    connectedCallback() {
        console.log('--Inside the connected call back--');
        this.contactrole = sessionStorage.getItem('SFMC_Audience');
        // console.log('NNNN'+this.product);
        //this.appointmentCount=this.product;
        this.getAppointmentsPerProduct();
    }

    getAppointmentsPerProduct() {
        console.log('get Appointments 123');
        getApprovedAppointment({ userId: USER_ID })
            // getApprovedAppointment({userId: '0057X0000044lyIQAQ'})
            .then((result) => {
                console.log('Upcoming Appointment');
                console.log({ result });
                console.log(USER_ID);

                for (var key in result) {
                    console.log({ key });
                    if (key <= 2) {
                        this.appointment.push(result[key]);
                    } else {
                        console.log('else');
                        console.log({ key });
                        this.appointment1.push(result[key]);
                    }
                }
                if (this.appointment1.length > 0) {
                    this.appmore = true;
                }
                else {
                    this.appmore = false;
                }

                if (result == undefined || this.appointment.length == 0) {
                    this.norecord = true;
                }
                else {
                    this.norecord = false;
                }

                // this.appointment=result;
                console.log('this.appointment==>',this.appointment);
                var appotm = this.appointment;
                console.log({appotm});
                // this.products = result;
                // this.products = result.condata;
                // this.savedcon = result.savedcount;
                //console.log('this.products==>',this.products);
            })
            .catch((error) => {
                console.log(' Error in Get Appointments' + JSON.stringify(error));
                this.error = error;
            });
    }
    showmoreclk() {
        console.log('showmoreclk');
        this.showmore = true;
        console.log('this.showmore-->',this.showmore);
    }
    showlessclk() {
        this.showmore = false;
    }
    
    //data
    fireDataLayerEvent(category, action, label,module,linkedtext, linkedurl,contentname)  {  //RT-1053
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {
            detail: {               
                data_design_category: category,                
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: 'homepage',
                page_purpose:'homepage',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text:linkedtext,
                link_url:linkedurl,
                content_count:'',
                content_saved:'',
                content_appointments:'',
                content_requests:'',
                content_name:contentname, //RT-1053
                page_localproductname:'',                
                sfmc_id:USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'dashboard',
           },
           bubbles: true,
           composed: true
        }));
    }
}