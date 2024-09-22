import { LightningElement, track, api, wire } from 'lwc';
import getCatalogs from '@salesforce/apex/MSD_CORE_ProductList.getCatalogs';
import getCatalogRecord from '@salesforce/apex/MSD_CORE_ProductList.getCatalogRecord';
import getAppointmentDetails from '@salesforce/apex/MSD_CORE_ProductList.getAppointmentDetails';

import getPdfDownloadLink from '@salesforce/apex/MSD_CORE_ProductList.getPdfDownloadLink';
import USER_ID from "@salesforce/user/Id";
import newlogo2 from '@salesforce/resourceUrl/like';
import newlogo3 from '@salesforce/resourceUrl/bookmark';
import newlogo4 from '@salesforce/resourceUrl/whitearrow';
import newlogo5 from '@salesforce/resourceUrl/whiteboxarrow';
import arrow from '@salesforce/resourceUrl/rightarrow2';
import crossmark from '@salesforce/resourceUrl/cross';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import radiocss from '@salesforce/resourceUrl/radiocss';
import bootstrap from '@salesforce/resourceUrl/BootStrap';
import DateTimeJS from '@salesforce/resourceUrl/DateTimeJS';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import createMeetRequest from '@salesforce/apex/MSD_CORE_ProductList.createMeetingRequest';
import {NavigationMixin} from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';

import bannerimg from '@salesforce/resourceUrl/banner';

export default class ViewAppointment extends LightningElement {
    currentPageReference = null;
    @api recId;

    value = '';
    @track today;
    @track count = 0;
    @track count1 = 0;
    @track templist = [];
    @track addattlst = [];
    @track hideRemoveDate = true;
    @track hideRemoveAttendee = true;
    @track showResponse = false;
    @track meetingRequests = [];
    @track meetingRequestNumber;
    @track tod;
    @track datevalue;
    @track emailVal;
    @track startTime;
    @track dateVal;
    @track timeVal;
    @track catalogName;
    @track catalofDescription;
    @track productname;
    @track catalogID;
    @track ProductpayerID;
    @track meetingstartdate;
    @track meetingattendee;
    @track meetingPreference;
  
    currentPageReference = null;
    urlStateParameters = null;
    sidearrow = arrow
    cross = crossmark;

    sectiondisplay = false;

    get backgroundStyle() {
        return `background-image:url(${bannerimg})`;
    }

    // bannerimage = Bannerimg;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('IIIII');
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            console.log('urlStateParameters' + JSON.stringify(this.urlStateParameters));
            this.recId = this.urlStateParameters.recordId;
            console.log('this.recId' + this.recId);
        }
    }

    bookmarklogo = newlogo2;
    logo2 = newlogo3;
    logo3 = newlogo4;
    logo4 = newlogo5;
    @api productName;
    @api productDescription;

    todaysDate;
    // get todaysDate() {
    //     var today = new Date();
    //     return today.toISOString();
    // }
    

    get timeoption() {
        return [
            { label: '12:00 AM', value: '00:00' },
            { label: '01:00 AM', value: '01:00' },
            { label: '02:00 AM', value: '02:00' },
            { label: '03:00 AM', value: '03:00' },
            { label: '04:00 AM', value: '04:00' },
            { label: '05:00 AM', value: '05:00' },
            { label: '06:00 AM', value: '06:00' },
            { label: '07:00 AM', value: '07:00' },
            { label: '08:00 AM', value: '08:00' },
            { label: '09:00 AM', value: '09:00' },
            { label: '10:00 AM', value: '10:00' },
            { label: '11:00 AM', value: '11:00' },
            { label: '12:00 PM', value: '12:00' },
            { label: '01:00 PM', value: '13:00' },
            { label: '02:00 PM', value: '14:00' },
            { label: '03:00 PM', value: '15:00' },
            { label: '04:00 PM', value: '16:00' },
            { label: '05:00 PM', value: '17:00' },
            { label: '06:00 PM', value: '18:00' },
            { label: '07:00 PM', value: '19:00' },
            { label: '07:00 PM', value: '20:00' },
            { label: '09:00 PM', value: '21:00' },
            { label: '10:00 PM', value: '22:00' },
            { label: '11:00 PM', value: '23:00' },
        ]
    }


    get options() {
        return [
            { label: 'Virtual meeting', value: 'Virtual meeting' },
            { label: 'In-person meeting', value: 'In-person meeting' },
        ];
    }

    

    connectedCallback() {

        this.sectiondisplay = false;
        // Disable Past Date

        var today = new Date();
        this.todaysDate = today.toISOString().substring(0, 16);
        console.log('this.todayDateTime>>>'+this.todaysDate);
      
        //call the apex controller to get the details for the Catalog
        var d = new Date();
        this.today = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();
        this.catalogList();
        this.templist.push(this.count);
        this.addattlst.push(this.count1);
      //  getAppointmentDetails(String appointmentID)

        getAppointmentDetails({appointmentID:this.recId}).then(result=>{
            console.log('Inside Result Appointment Details'+JSON.stringify(result));
              console.log('000');
               console.log('000'+result[0].MFR_Resource__r.Name);
              this.catalogName =result[0].MFR_Resource__r.Name;
               console.log('1');
                    this.catalofDescription = result[0].MFR_Resource__r.Description__c;
                     console.log('2');
                    this.productname = result[0].Product_Payor__r.Name;
                     console.log('3');
                   // if(result.Product_Payor__r.Product_Description__c)
                     console.log('0');
                     //this.productDescription = result.Product_Payor__r.Product_Description__c;
                  //   if(result.Product_Payor__r.Product_Description__c)
                     console.log('4');
                       this.productName = result[0].Product_Payor__r.Name;
                        console.log('1111');
                        this.meetingstartdate=result[0].Start_DateTime_vod__c;
                         console.log('0000');
    this.meetingattendee=result[0].attendee__c;
     console.log('2222');
    this.meetingPreference=result[0].Meeting_preference__c;
        }

        ).catch(error=>{
            console.log('Inside Error');
            this.error=error;
        });
       /* getCatalogRecord({ recId: this.recId })
            .then(result => {
                console.log('JSON on load' + JSON.stringify(result));
                if (result) {
                    this.catalogName = result.Name;
                    this.catalofDescription = result.Description__c;
                    this.productname = result.Product_Payor__r.Name;
                    this.catalogID = this.recId;
                    this.ProductpayerID = result.Product_Payor__c;
                    this.productName = result.Product_Payor__r.Name;
                    this.productDescription = result.Product_Payor__r.Product_Description__c;
                }
            }).catch(error => {
                console.log('Inside Error');
                this.error = error;
                //this.products = undefined;
            });*/
    }

    renderedCallback() {

        Promise.all([
            loadStyle(this, bootstrap),
            loadScript(this, DateTimeJS),
        ]).then(() => {
            console.log('Files loaded');
        })
            .catch(error => {
                console.log(error.body.message);
            });
        Promise.all([
            loadStyle(this, radiocss)
        ]).then(() => {
        })
            .catch(error => {
                console.log(error.body.message);
            });

        if (this.templist.length === 1 && this.templist.length > 0) {
            this.hideRemoveDate = true;
        } else {
            this.hideRemoveDate = false;
        }

        if (this.addattlst.length === 1 && this.addattlst.length > 0) {
            this.hideRemoveAttendee = true;
        } else {
            this.hideRemoveAttendee = false;
        }
    }
    handleDate(event) {
        var d = new Date();
        var dt = d.getTime();
        console.log(JSON.stringify(event.target.id));
        console.log('Today Date' + dt );
        let selectedDate = Date.parse(event.target.value);
        console.log('Selected Date' + selectedDate);
         
        if (selectedDate < dt ) {
          let dates = this.template.querySelectorAll('.Date');
          let times = this.template.querySelectorAll('.time_cls.Time');
          dates.forEach(e=> { 
              if(e.id == event.target.id ){
                  e.value='';
                  this.template.querySelector('c-custom-toast').showToast('error', 'Date must be in future..');
              }
          });

          times.forEach(e=> { 
              if(e.id == event.target.id ){
                  e.value='';
              }
          });
        }
    }

    handleTime(event){
     /*   var d = new Date();
          let dates = this.template.querySelectorAll('.Date');
        let times = this.template.querySelectorAll('.Time');
        dates.forEach(dt =>{
            console.log('Today Date' + d.getTime() );
            console.log('Selected Time' + Date.parse(event.target.value));
            if(dt.id == event.target.id ){
                let dValues = this.dt.value.split('-');
                let tValues = this.event.target.value.split(':');
                  let startDate = new Date(dValues[0], dValues[1], dValues[2], tValues[0], tValues[1], 0  );
                  if (startDate < d.getTime() ) {
                            this.template.querySelector('c-custom-toast').showToast('error', 'Date must be in present or in future..');
                        }
              }
        }); */
    }
    catalogList() {
        getCatalogs({ prodId: this.recId, userId: USER_ID })
            .then(result => {
                console.log('106-cataloglist');
                let record = result;
                console.log('result--' + JSON.stringify(result));
                this.products = record.map(row => ({
                    ...row,
                    isViewInMeeting: row.Delivery_Framework__c === 'View in Meeting',
                    isViewImmediately: row.Delivery_Framework__c === 'View Immediately',
                    isViewUponRequest: row.Delivery_Framework__c === 'View upon Request'
                }));
                console.log('106-cataloglist' + JSON.stringify(this.products));
                //this.products = result;
                this.error = undefined;
                this.productName = result[0].Product_Payor__r.Name;
                this.productDescription = result[0].Product_Payor__r.Product_Description__c;
            })
            .catch(error => {
                this.error = error;
                //this.products = undefined;
            });
    }

    addnewdate(event) {

       // let validationsList = this.handlerDateValidation();
       // console.log('validationsListsss--' + JSON.stringify(validationsList));
       // if (!validationsList.includes(false)) {
           try{
               let dates = this.template.querySelectorAll('.Date');
                var allowDate = false;
                    var d = new Date();
                dates.forEach(e=> {
                    if(!allowDate){
                        if (!e.value ) {
                            this.template.querySelector('c-custom-toast').showToast('error', 'Date cannot be empty'); 
                        }else{
                            allowDate = true;
                        }
                    }
                });
                if(this.templist.length > 2){
                    this.template.querySelector('c-custom-toast').showToast('error', 'Maximum 3 appointment times allowed'); 
                }
                if(allowDate && this.templist.length <= 2){
                    this.count += 1;
                    this.templist.push(this.count);
                }
                

           }
           catch(error){
               console.log('error'+ JSON.stringify(error));
           }
           
            
        //}
    }
    addnewatte() {
        let validationsList = this.handlerEmailValidation();
        console.log('validationsList--' + JSON.stringify(validationsList));
        if (!validationsList.includes(false)) {
            this.count1 += 1;
            this.addattlst.push(this.count1);
        }
    }
    removedate(event) {
        var indx = event.target.dataset.value;
        if (this.templist.length > 1) {
            this.templist.splice(indx, 1);
        }
    }
    removefield(event) {
        var indx = event.target.dataset.value;
        if (this.addattlst.length > 1) {
            this.addattlst.splice(indx, 1);
        }
    }

    handlerEmailValidation() {
        let validations = [];
        var flag = true;
        const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        let emails = this.template.querySelectorAll('lightning-input[data-id="attendee"]');
        
            emails.forEach(currentItem => {
            let emailAddress = currentItem.value;
           // let emailAddress = this.template.getElementsByClassName("'"+"."+currentItem+"'");
            console.log('currentItems--'+JSON.stringify(emailAddress));
            var emailVal = emailAddress;
            flag = true;
            if (emailVal.match(emailRegex)) {
                validations.push(flag);
            } else {
                flag = false;
                currentItem.focus();
                validations.push(flag);
                this.template.querySelector('c-custom-toast').showToast('error', 'Please provide proper email address (for example, john@gmail.com)');
            } 
         }); 
         

        return validations;
    }

    handlerDateValidation() {
        /*let validations = [];
        let formclass = this.template.querySelectorAll(".Date");
        console.log('formclass----' + JSON.stringify(formclass));
        var today = new Date();
        var dd = today.getDate();
        var mm = today.getMonth() + 1;
        var yyyy = today.getFullYear();
        if (dd < 10) {
            dd = '0' + dd;
        }
        if (mm < 10) {
            mm = '0' + mm;
        }
        var todayFormattedDate = yyyy + '-' + mm + '-' + dd;
        var flag = true;
        formclass.forEach(element => {
            console.log(todayFormattedDate + 'element----' + element.value);
            console.log('compare----' + element.value > todayFormattedDate);
            flag = true;
            if (element.value != '' && element.value != null && element.value >= todayFormattedDate) {
                validations.push(flag);
            } else {
                console.log(todayFormattedDate + 'else----' + element.value);
                flag = false;
                element.focus();
                validations.push(flag);
                this.template.querySelector('c-custom-toast').showToast('error', 'Date must be in present or in future..');
            }

        });
        return validations; */

        

    }

    showToast(theTitle, theMessage, theVariant) {
        console.log('theTitle-' + theTitle + '-theMessage-' + theMessage + '-theVariant-' + theVariant);
        const event = new ShowToastEvent({
            title: theTitle,
            message: theMessage,
            variant: theVariant
        });
        console.log('event-' + event);
        this.dispatchEvent(event);
    }

    handleSubmit() {


        let emailAddress = this.template.querySelectorAll('lightning-input[data-id="attendee"]');

        emailAddress.forEach(item => {
            this.emailVal = this.emailVal ? this.emailVal + ',' + item.value : item.value;
        });

        let dates = this.template.querySelectorAll('.Date');
        let times = this.template.querySelectorAll('.Time');
        let meetingPreference = this.template.querySelectorAll('.radiobtncls');
        let meetingPreferenceValidation = true;
        meetingPreference.forEach(e => {
                if(meetingPreferenceValidation){
                    if(e.value){
                        meetingPreferenceValidation = false;
                    }
                }
        });
        
        if(meetingPreferenceValidation){
             
        }
        console.log('111-->' + dates.length);
        console.log('111-->' + dates[0].value);
        if (dates.length > 0 && dates[0].value != null && dates[0].value != undefined && dates[0].value != '' && times.length > 0 && times[0].value != null && times[0].value != undefined && times[0].value != '') {
            if(!meetingPreferenceValidation)
            {
            if (dates.length > 0) {
                this.dateVal = dates[0].value;
            }
            let times = this.template.querySelectorAll('.Time');
            if (times.length > 0) {
               this.timeVal = times[0].value;
            }
            console.log('Date' + this.dateVal);
            console.log('Time' + this.timeVal);
            let dValues = this.dateVal.split('-');
            let tValues = this.timeVal.split(':');
            let response = this.handlerEmailValidation();
            if(!response.includes(false)){
                 let MeetingRequest = {};
                    MeetingRequest.MFR_Status__c = 'Pending';
                    let startDate = new Date(dValues[0], dValues[1], dValues[2], tValues[0], tValues[1], 0  );
                    MeetingRequest.Start_DateTime_vod__c = startDate;
                    MeetingRequest.Meeting_preference__c = this.template.querySelector('.radiobtncls').value;
                    MeetingRequest.attendee__c = this.emailVal;
                    if (this.ProductpayerID) {
                        MeetingRequest.Product_Payor__c = this.ProductpayerID;
                    }

                    if (this.catalogID) {
                        MeetingRequest.Catalog__c = this.catalogID;
                    }
                    this.meetingRequests.push(MeetingRequest);
                    this.showResponse = true;

                    createMeetRequest({ request: JSON.stringify(this.meetingRequests) })
                        .then(result => {
                            console.log('Result' + JSON.stringify(result));
                            this.meetingRequestNumber = result.message;
                        })
                        .catch(error => {
                            console.log('error' + JSON.stringify(error));
                        });
            }
            }
            else{
this.template.querySelector('c-custom-toast').showToast('error', 'Please select meeting preference');
            }
        }
        else {
this.template.querySelector('c-custom-toast').showToast('error', 'Plese select atleaast one Date and Time');
            console.log('Else');
           

        }

        //}
    }

    closeResponse() {
        this.showResponse = false;
    }

    editclick(){
        this.sectiondisplay = true;
    }
    cancelclick(){
        this.sectiondisplay = false;
    }


    handlerOnclickProduct(event){
        this.prodId = event.currentTarget.dataset.id;
        alert(this.prodId);
        let toNavigateUrl = '/librarydetails?recordId='+`${this.prodId}`;
        console.log('entered')
        this.navigateToNewRecordPage(toNavigateUrl);
    }

    navigateToNewRecordPage(url) {
        console.log('toNavigateUrl=='+url);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }


    navigatepage(event){
        
        var getnameval = event.currentTarget.dataset.name;
        console.log("Get name"+getnameval);

        if (getnameval == 'ProductList') {
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                 type: 'standard__webPage',
                attributes: {
                    name: 'Productlistpage__c',
                    url: '/s/product-list-page'
                }
            });
        } else if (getnameval == 'Library') {
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                 type: 'standard__webPage',
                attributes: {
                    name: 'library__c',
                    url: '/s/library'
                }
            });
        } else if (getnameval == 'Librarydetail') {
            var recId = event.currentTarget.dataset.id;
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                 type: 'standard__webPage',
                attributes: {
                    name: 'detail__c',
                    url: '/s/library/detail'+ '?recordId=' + recId
                }
                // state: {
                //     recordId: recId
                // }
            });
        } else if (getnameval == 'Dashboard') {
            var recId = event.currentTarget.dataset.id;
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                 type: 'standard__webPage',
                attributes: {
                    name: 'Home',
                    url: '/s/'+ '?recordId=' + recId
                }
                // state: {
                //     recordId: recId
                // }
            });
        }else {
            console.log('else');
        }
        
    }

}