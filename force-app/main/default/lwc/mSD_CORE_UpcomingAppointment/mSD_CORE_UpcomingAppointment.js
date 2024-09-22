import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import USER_ID from "@salesforce/user/Id";

import newlogo9 from '@salesforce/resourceUrl/downarrow';
import uparrow from '@salesforce/resourceUrl/uparrowicon';
import getUserInfo from '@salesforce/apex/MSD_CORE_ProductList.getUserInfo';
import newlogo7 from '@salesforce/resourceUrl/rightarrow2';
import document from '@salesforce/resourceUrl/calender';
import arrow from '@salesforce/resourceUrl/rightarrow2';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import getApprovedAppointment from '@salesforce/apex/MSD_CORE_RequestController.getupcomingappointments';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import getPrimaryExecutive from '@salesforce/apex/MSD_CORE_Dashboard.getPrimaryExecutive';
import noprofile from '@salesforce/resourceUrl/noprofile';
//import phone from '@salesforce/resourceUrl/MSD_CORE_Phone';
import phoneblue from '@salesforce/resourceUrl/Mheenewphoneiconblue';
import phonewhite from '@salesforce/resourceUrl/Mheenewphoneiconwhite'; 
import message from '@salesforce/resourceUrl/MSD_CORE_Message';
import MheeMsgWhiteicon from '@salesforce/resourceUrl/MheeMsgWhiteicon'; 
import MheeMsgblueicon from '@salesforce/resourceUrl/MheeMsgblueicon';

export default class MSD_CORE_UpcomingAppointment extends NavigationMixin(LightningElement) {

    @track appointment = [];
    @track appointment1 = [];
    logo10 = newlogo9;               //Down Arrow icon
    docicon = document;             //Calender icon
    noprofile = noprofile;
    //phoneicon = phone;
    phoneblue = phoneblue;
    phonewhite = phonewhite;
   // @track phoneiconchange;
    messageicon = message;
    MheeMsgblueicon = MheeMsgblueicon;
    MheeMsgWhiteicon = MheeMsgWhiteicon;

    @track showmore = false;
    @track appmore = false;
    uparrowimg = uparrow;
    @track setDefaultime;
    @track timezonetype;
    @track contactrole = '';

    @track showPrimaryExecutive = false;
    @track primaryExecutive;

    norecord = false;
    logo8 = newlogo7;               //Arrow icon
    rightarrow = arrow;             //Right Arrow
    @track nodata;
    @track siteAPINames;
    @track siteNames;

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
    @wire(getContactRole, { userId:USER_ID })
    wiredgetContactRole(value) {
        console.log({value});
        const { data, error } = value;
        if(data) {
            console.log({data});
            this.contactrole = data;
            console.log('raviteja>>>>>',data);
        }
        if(error) {
            console.log({error});
        }
    }
    onbuttonhover(event){
        //this.phoneiconchange = this.phonewhite;
        // const itemId = event.target.dataset.id;
        // const item = this.primaryExecutive.find(i => i.id === parseInt(itemId, 10));
        // console.log('item>>>>' + item);
        // if (item) {
        //     const img = this.template.querySelector(`img[data-id="${itemId}"]`);
        //     // img.src = item.hoverImgSrc;
        //     img.src = this.phonewhite;
        //     console.log('itemfound');
        // }
        // console.log('itemnotfound');
    }
    onButtonOut(){
        //this.phoneiconchange = this.phoneicon;
    }
    @wire(getPrimaryExecutive, { userId: USER_ID })
    wiredPrimaryExecutive({ error, data }) {
        console.log({ data });
        if (data) {
            this.primaryExecutive = data.map(row => ({
                    ...row,
                    Email: this.getEmailBody(row.Email),
                    fullPhotoURL: row.FullPhotoUrl, //<!--Mukesh-->
                    MediumPhotoUrl: row.MediumPhotoUrl, //<!--Mukesh-->
                    primaryemail: this.getprimaryemail(row.Email),
                    isPicturePresent:this.hasProfilePicture(row.FullPhotoUrl),
                    formatNumber:this.getFormattedPhnNumber(row.Phone), //<!--Mukesh-->
                    formatEmail:this.getFormattedEmail(row.Email),//<!--Mukesh-->
                    isPhoneAvailable:this.hasPhoneNumber(row.Phone),//<!--Mukesh-->
                    isEmailAvailable:this.hasEmail(row.Email),//<!--Mukesh--> 
                    // typeofAE: row.Title.includes('Non') ? (this.typeofAE === 'NON-Oncology') : (this.typeofAE === 'Oncology')
                    typeofAE: row.Title.includes('Non') ? 'NON-Oncology' : 'Oncology',
                    bordercls: row.Title.includes('Non') ? 'slds-size_12-of-12 slds-grid slds-wrap slds-p-top_medium slds-p-bottom_medium bordercls2' : 'slds-size_12-of-12 slds-grid slds-wrap slds-p-top_medium slds-p-bottom_medium bordercls1',
                    mycontactbtn: row.Title.includes('Non') ? 'mycontactbtn2 primaryinfophone hoverphone' : 'mycontactbtn1 primaryinfophone',
                    mycontactbtnemail: row.Title.includes('Non') ? 'mycontactbtn2 slds-m-left_small primaryinfoemail hoveremail' : 'mycontactbtn1 slds-m-left_small primaryinfoemail',
                    hyplink: row.Title.includes('Non') ? 'hyplink2' : 'hyplink1',
                    phoneiconchange: row.Title.includes('Non') ? this.phoneblue : this.phonewhite,
                    messageicon: row.Title.includes('Non') ? this.MheeMsgblueicon : this.MheeMsgWhiteicon,
                }));
            if (this.primaryExecutive.length > 0) {
                this.showPrimaryExecutive = true;
            } else {
                this.showPrimaryExecutive = false;
            }
            console.log('Primary Executive' + JSON.stringify(data));
            console.log('Primary executive data = ' + this.primaryExecutive);
        }
        if (error) {
            console.log({error});
        }
                        
    }

    getEmailBody(emailfieldval) {
        var emailval=emailfieldval;
        var width = screen.width;
        var emailname   = emailval.substring(0, emailval.lastIndexOf("@"));
        var domain = emailval.substring(emailval.lastIndexOf("@") +1);
        console.log('Email--> '+emailname);
        console.log('Email--> '+domain);        
        var finalemail;                    
        if (width < 768) {
            if(emailname.length>=8)
            {
                let newemailname=emailname.substring(0,6)+'....'+'@'+domain;  
                this.primaryemail=newemailname;
                finalemail = newemailname;                                                        
            }
            else
            {
                this.primaryemail=emailname;                
                finalemail =  emailval;                
            }
        }
        else{
            if(emailname.length>=25)
            {
                let newemailname=emailname.substring(0,21)+'....'+'@'+domain;  
                this.primaryemail=newemailname;
                finalemail = newemailname;                                            
            }
            else
            {
                this.primaryemail=emailval;
                finalemail = emailval;
            }
        }
        console.log({finalemail});                            
        return finalemail;
    }

    getprimaryemail(email) {
        this.primaryemail=email;
        return this.primaryemail;
    }

    preventAction(event) {
        event.preventDefault(); // Prevents the default action (navigation)
    }

    hasProfilePicture(photourl){
        if(photourl.indexOf('/profilephoto/005/F')>-1){
            return false;
        }else{
            return true;
        }
    }

    getFormattedPhnNumber(phnNumber){
       let formattedNumber="tel:";
       formattedNumber+=phnNumber;
       console.log('EVENT TRIGGERED Recent chnages '+ formattedNumber );
       return formattedNumber;
     }

     
     getFormattedEmail(email){
       let formattedemail="mailto:";
       formattedemail+=email;
       console.log('EVENT TRIGGERED Recent chnages '+ formattedemail );
       return formattedemail;
     }

     hasPhoneNumber(phoneNumber){
        if(phoneNumber===null){
            return false;
        }
        return true;
    }

     hasEmail(email){
        if(email===null){
            return false;
        }
        return true;
    }

    // Method Name:         WiredgetSiteNameAndAPIName
    // Method Use:          For getting all Sites API Name and Url
    // Developer Name:      Ravi Modi
    // Created Date:        21th March 2023
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log('sites Data-->', { data });
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
        } else if (error) {
            console.log('ERROR in Getting Sites Name-->', { error });
        }
    }

    navigatepage(event) {
        var contname = event.currentTarget.dataset.contname;
        var getnameval = event.currentTarget.dataset.name;
        //this.fireDataLayerEvent('button','','appointments', 'vertical','Productlistpage__c','/product-list-page');
        if (getnameval == 'upcomingAppointment') {
            this.fireDataClickEvent('button','','vertical','view all appointments','RequestAppointment__c' , '/requestappointment' + '?tab=appointment','');//RT-N-1053
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                    name: 'RequestAppointment__c',
                    url: '/requestappointment' + '?tab=Appointments'
                },
            });

            /* this[NavigationMixin.Navigate]({
                 // type: 'comm__namedPage',
                 // attributes: {
                 //     name: this.librarydetailpageapi,
                 //     url: this.librarydetailpage
                 // },
                 // state: {
                 //     recordId: recId,
                 //     tab: tabname
                 // }
                 
                 type: 'standard__webPage',
                 attributes: {
                     name: 'RequestAppointment__c',
                     url: this.Requestdetailpage + '?recordId=' + recId + '&tab=' + tabname
                 }
             });*/
        }
        else {
            var recId = event.currentTarget.dataset.id;
            var tabname = event.currentTarget.dataset.name;
            this.fireDataClickEvent('button','','vertical','appointments','RequestAppointment__c' ,'/requestappointment' + '/requestdetail?recordId=' + recId,contname);//RT-N-1053
            console.log('Tab name=' + tabname);
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                    name: 'RequestAppointment__c',
                    url: '/requestappointment' + '/requestdetail?recordId=' + recId
                },
            });
        }
    }

    connectedCallback() {
        console.log('--Inside the connected call back--');
        // this.contactrole = sessionStorage.getItem('SFMC_Audience');
        // console.log('NNNN'+this.product);
        //this.appointmentCount=this.product;
        this.getAppointmentsPerProduct();
    }

    getAppointmentsPerProduct() {
        console.log('get Appointments 123');
        getApprovedAppointment()
            // getApprovedAppointment({userId: '0057X0000044lyIQAQ'})
            .then((result) => {
                console.log('Upcoming Appointment');
                console.log({ result });
                console.log(USER_ID);
                let recordsToDisplay = this.getRequestMappedValue(result);
                console.log('line no 117::::::::' + recordsToDisplay);
                for (var key in recordsToDisplay) {
                    console.log({ key });
                    if (key <= 2) {
                        this.appointment.push(recordsToDisplay[key]);
                    } else {
                        console.log('else');
                        console.log({ key });
                        this.appointment1.push(recordsToDisplay[key]);
                    }
                }
                if (this.appointment1.length > 0) {
                    this.appmore = true;
                }
                else {
                    this.appmore = false;
                }

                if (recordsToDisplay == undefined || this.appointment.length == 0) {
                    this.norecord = true;
                }
                else {
                    this.norecord = false;
                }

                // Added for No Result --- Ravi Modi --- 21 March 2023
                if (this.appointment.length == 0) {
                    this.nodata = true;
                } else {
                    this.nodata = false;
                }

                var appotm = this.appointment;
                console.log({ appotm });
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
        console.log('this.showmore-->', this.showmore);
        this.fireDataClickEvent('button','','vertical','Show more','Home' ,'/merckmhee/','');//RT GA bug
    }
    showlessclk() {
        this.showmore = false;
        this.fireDataClickEvent('button','','vertical','Show less','home' ,'/merckmhee/','');//RT GA bug
    }
    getRequestMappedValue(RequestData) {
        console.log('line no 165::::::::' + RequestData);
        let _requestData = RequestData.map(
            record =>
                Object.assign({
                    "CreatedDate": record.CreatedDate,
                    "Id": record.Id,
                    "MHEE_Name__c": record.MHEE_Name__c,
                    //"MSD_CORE_Resource_Type__c": record.MSD_CORE_Resource_Type__c,
                    "Start_DateTime_vod__c": record.Start_DateTime_vod__c,
                    "FirstName": record.Assignee_vod__r.FirstName,
                    "LastName": record.Assignee_vod__r.LastName,
                    "AssigneeName": record.Assignee_vod__r.Name,
                    "MSD_CORE_Source__c": record.MSD_CORE_Source__c,
                    "Name": record.Name,
                    "ScheduleFilter__c": record.ScheduleFilter__c != null ? this.displayDiseaseSchedule(record.ScheduleFilter__c) : ''
                }
                ));
        console.log('line no 181::::::::');
        return _requestData;
    }
    displayDiseaseSchedule(scheduleFilter) {
        let _schedule = '';
        let _counter = 0;
        let objschedule = scheduleFilter.split(',');
        if (objschedule) {
            if (objschedule.length == 1) {
                _schedule = objschedule[0];
            } else {
                objschedule.forEach(element => {
                    if (_schedule.length == 0) {
                        _schedule = element;
                    } else {
                        _counter += 1;
                    }
                });
                _schedule = _schedule + ' (+' + _counter + ' more)';
            }
        }
        return _schedule;
    }

    // Method Name:         navigatetopipeline
    // Method Use:          Navigate to Pipeline Page
    // Developer Name:      Ravi Modi
    // Created Date:        21th March 2023
    navigatetopipeline() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.siteAPINames.Pipeline,
                url: this.siteNames.Pipeline
            }
        });
        this.fireDataClickEvent('button','','vertical','browse pipeline information',this.siteAPINames.Pipeline ,this.siteNames.Pipeline,'');//RT GA 1122
    }

    //data analytics
    //RT GA bug
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl,contname) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {
            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'Appointments',
                page_purpose: 'Appointments',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: linkedtext,
                link_url: linkedurl,
                content_count: '',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: contname,
                page_localproductname: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'dashboard',
            },
            bubbles: true,
            composed: true
        }));
    }
    //RT GA bug
    fireDataClickEvent(category, action,module, label,linkedtext,linkedurl,contname) {
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {
            detail: {
                 // event_category: category,
                 // event_action: action,
                 // event_label: label,
                 // module:module,
                 // page_type: 'menu',
                 // page_purpose:'notifications',
                 // page_audience: 'payor',
                 // page_marketname: 'united_states',
                 // page_region: 'us',
                 // page_contentclassification: 'non-commercial',
                 data_design_category: category,
                 data_design_action: action,
                 data_design_label: label,
                 data_design_module:module,
                 page_type: 'Homepage',
                 page_purpose:'Homepage',
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
                 content_name:contname,
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