import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

import USER_ID from "@salesforce/user/Id";

import arrow from '@salesforce/resourceUrl/rightarrow2';
import requestCardCSS from '@salesforce/resourceUrl/requestCardCSS';

import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames'; // Getting Page name
import getUserInfo from '@salesforce/apex/MSD_CORE_ProductList.getUserInfo';
import getRequest from '@salesforce/apex/MSD_CORE_RequestController.getMHHERequest';
import logo from '@salesforce/resourceUrl/logo';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';

const monthNames = ["January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
];
const monthShortNames = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
    "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
];
const weekday = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

export default class MSD_CORE_RequestCard extends NavigationMixin(LightningElement) {
    
    @track recordsToDisplay = [];
    @api requestType
    @api totalCount
    @track total = 0;
    @track pageSize = 6
    @track contactrole = '';
    setDefaultime;
    timezonetype;
    pageNumber = 1
    isLoading = false;
    userId = USER_ID;
    error;
    rightarrow = arrow;
    sortBy = '';
    searchFilter = '';
    isSearch = false;
    @track forNoResult;

    @wire(getUserInfo, { userId: USER_ID })
    wireuser({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            console.log('inside wire' + data);
            this.setDefaultime = data.TimeZoneSidKey;
            console.log('this.setDefaultime' + this.setDefaultime);
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

    @wire(getRequest, { requestType: '$requestType', pageSize: '$pageSize', pageNumber: '$pageNumber', userid: USER_ID, sortBy: '$sortBy', searchFilter: '$searchFilter' })
    wiredGetRequest(value) {
        console.log('Wired Called');
        console.log({ value });
        const { data, error } = value;
        if (data) {
            this.setCountOnSearch(data.MeetingCount);
            if(data.MeetingCount == 0 && this.searchFilter != ''){
                this.forNoResult = true;
            } else {
                this.forNoResult = false;
            }
            this.recordsToDisplay = this.getRequestMappedValue(data.MeetingRequestList);
            console.log('In wiredGetRequest : this.recordsToDisplay', JSON.stringify(this.recordsToDisplay));
        } else if (error) {
            this.error = error;
            console.log(this.error);
        }
    }
    setCountOnSearch(totalCount) {
        if (totalCount > -1) {
            this.total = totalCount;
        } else {
            this.total = this.totalCount;
        }
        if (this.total > 0 && this.isSearch) {
            this.callDoPaginationAPI(this.total);
        }
        this.isSearch = false;
    }
    callDoPaginationAPI(totalCount) {
        if (this.template.querySelector("c-do-pagination")) {
            this.template.querySelector("c-do-pagination").passAPICall(totalCount);
        }
        console.log('callDoPaginationAPI');
    }
    // For getting all Sites API Name and Url
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

    get isNotShow() {
        return this.totalCount > 0 ? false : true;
    }
    get pending() {
        return this.requestType == 'Pending' ? true : false;
    }
    get closed() {
        return this.requestType == 'Closed' ? true : false;
    }
    get appointment() {
        return this.requestType == 'Approved' ? true : false;
    }
    get setStatusCSS() {
        if (this.requestType == 'Approved') {
            return 'schedule-appointment__Scheduled-Approved';
        }
        else if (this.requestType == 'Pending') {
            return 'schedule-appointment__Scheduled-Pending';
        }
        else {
            return 'schedule-appointment__Scheduled-Rejected';
        }

    }

    getRequestMappedValue(RequestData) {
        let _requestData = RequestData.map(
            record =>
                Object.assign({ "Status": (record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Approved') ? 'Scheduled' : (record.MSD_CORE_Status__c != null && (record.MSD_CORE_Status__c == 'Rejected' || record.MSD_CORE_Status__c == 'Closed')) ? 'Closed' : 'Pending' },
                    { "IsMultipleAppointment": ((record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Pending') && (record.Meeting_Times__r != null && record.Meeting_Times__r.length > 1)) ? true : false },
                    { "Day": ((record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Pending') && (record.Meeting_Times__r != null && record.Meeting_Times__r.length > 0)) ? this.getDay(record.Meeting_Times__r[0].MSD_CORE_Meeting_Date__c) : record.Start_DateTime_vod__c != null ? this.getDay(record.Start_DateTime_vod__c) : '' },//Modifed for Bug_Web_048 by Tausif
                    { "Month": ((record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Pending') && (record.Meeting_Times__r != null && record.Meeting_Times__r.length > 0)) ? this.getMonth(record.Meeting_Times__r[0].MSD_CORE_Meeting_Date__c) : record.Start_DateTime_vod__c != null ? this.getMonth(record.Start_DateTime_vod__c) : '' }, //Modifed for Bug_Web_048 by Tausif
                    { "Time": ((record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Pending') && (record.Meeting_Times__r != null && record.Meeting_Times__r.length > 0)) ? this.getTimeValueSplit(record.Meeting_Times__r[0].MSD_CORE_Time_Slot__c ): record.Start_DateTime_vod__c != null ? this.getTime(record.Start_DateTime_vod__c) : '' }, //Modifed for Bug_Web_048 by Tausif
                    { "SubmittedDate": this.getSubmittedDate(record.CreatedDate) },
                    { "Attendees": record.MSD_CORE_attendee__c != null ? this.breakLineAttendee(record.MSD_CORE_attendee__c) : '' },
                    { "ScheduleFilter": record.ScheduleFilter__c != null ? this.displayDiseaseSchedule(record.ScheduleFilter__c) : '' },
                    { "appointments": record.Meeting_Times__r != null ? this.displayAppointment(record.Meeting_Times__r) : '' },
                    record
                )

        );
        return _requestData;
    }
    getDay(date) {
        let d = new Date(date);
        // let localDateValue = new Date(d).toLocaleString("en-US", { timeZone: this.setDefaultime });//Commenting code for Time-Zone  Issue
        // let localDate = new Date(localDateValue);//Commenting code for Time-Zone  Issue
        return d.getDate();
    }
    getMonth(date) {//Modified this mehod for bug Bug_Web_048 by Tausif
        let d = new Date(date);
        // let localDateValue = new Date(d).toLocaleString("en-US", { timeZone: this.setDefaultime });;//Commenting code for Time-Zone  Issue
        // let localDate = new Date(localDateValue);;//Commenting code for Time-Zone  Issue
        return monthShortNames[d.getMonth()];
    }
    getYear(date) {//Modified this mehod for bug Bug_Web_048 by Tausif
        let d = new Date(date);
        // let localDateValue = new Date(d).toLocaleString("en-US", { timeZone: this.setDefaultime });;//Commenting code for Time-Zone  Issue
        // let localDate = new Date(localDateValue);;//Commenting code for Time-Zone  Issue
        return d.getFullYear();
    }
    getFullMonth(date) {//Modified this mehod for bug Bug_Web_048 by Tausif
        let d = new Date(date);
        // let localDateValue = new Date(d).toLocaleString("en-US", { timeZone: this.setDefaultime });//Commenting code for Time-Zone  Issue
        // let localDate = new Date(localDateValue);;//Commenting code for Time-Zone  Issue
        return monthNames[d.getMonth()];
    }
    getTime(date) {//Modified this mehod for bug Bug_Web_048 by Tausif
        let objDate = new Date(date);
        let localDateValue = new Date(objDate).toLocaleString("en-US", { timeZone: this.setDefaultime });
        console.log('localDateValue  ', localDateValue);
        return this.formatAMPM(localDateValue);

    }

    getTimeValueSplit(strTime) {
        let timeval = strTime;
        if(timeval.endsWith('AM')){
            timeval = timeval.slice(0, -2);
            timeval = timeval+ ' AM';
        }
        if(timeval.endsWith('PM')){
            timeval = timeval.slice(0, -2);
             timeval = timeval+ ' PM';
        }
        return timeval;
    }
    getDayDisplay(date) {//Modified this mehod for bug Bug_Web_048 by Tausif
        const d = new Date(date);
        // let localDateValue = new Date(d).toLocaleString("en-US", { timeZone: this.setDefaultime });;//Commenting code for Time-Zone  Issue
        //  let localDate = new Date(localDateValue);;//Commenting code for Time-Zone  Issue
        return weekday[d.getDay()];
    }
    displayAppointment(appontments) {
        let _appointments = [];
        appontments.forEach(element => {
            let str ={};
            str.value =  this.getDayDisplay(element.MSD_CORE_Meeting_Date__c) + ', ' + this.getFullMonth(element.MSD_CORE_Meeting_Date__c) + ' ' + this.getDay(element.MSD_CORE_Meeting_Date__c) + ', ' + this.getTimeValueSplit(element.MSD_CORE_Time_Slot__c);
            _appointments.push(str);
        });
        return _appointments;
    }

    getSubmittedDate(date) {
        return 'Submitted ' + this.getFullMonth(date) + ' ' + this.getDay(date) + ', ' + this.getYear(date) + ' at ' + this.getTime(date);
    }
    breakLineAttendee(attendeeDetail) {
        let _attendees = '';
        let objattendeeDetail = attendeeDetail.split(',');
        if (objattendeeDetail) {
            if (objattendeeDetail.length == 1) {
                _attendees = objattendeeDetail[0];
            } else {

                objattendeeDetail.forEach(element => {
                    if (_attendees.length == 0) {
                        _attendees = element;
                    } else {
                        _attendees = _attendees + ',#' + element;
                    }
                });

            }
        }
        return _attendees.split('#');
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
    viewRequest(event) {
        try {
            var recId = event.currentTarget.dataset.id;
            var contname = event.currentTarget.dataset.mname;
            console.log('contname:::::::::'+contname);
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    name: this.siteAPINames.RequestDetail,
                    url: this.siteNames.RequestDetail + '?recordId=' + recId
                }
            });
            this.fireDataClickEvent('button','','','view request',this.siteAPINames.RequestDetail, this.siteNames.RequestDetail + '?recordId=' + recId,contname);//RT-N-1053
        } catch (error) {
            console.log('Error in viewRequest-->', { error });
        }
        
    }
    get showPagination() {
        /*  if (this.isSearch) {
              return this.total > 6  ? true : false;
          } else {*/
        return this.total <= 6 ? false : true;
        //}
    }
    get sortoptions() {
        if (this.requestType == 'Approved') {
            return [
                { label: 'Appointment date', value: 'Start_DateTime_vod__c' },
                { label: 'Date submitted', value: 'CreatedDate' },
                { label: 'Date modified', value: 'LastModifiedDate' },
            ];
        }
        if (this.requestType == 'Pending') {
            return [
                { label: 'Date submitted', value: 'CreatedDate' },
                { label: 'Date modified', value: 'LastModifiedDate' },
            ];
        }
        if (this.requestType == 'Closed') {
            return [
                { label: 'Close date', value: 'LastModifiedDate' },
                { label: 'Date submitted', value: 'CreatedDate' },
                { label: 'Resolution', value: 'MSD_CORE_Request_Resolution__c' },
            ];
        }
    }
    get selectFieldOption() {
        if (this.requestType == 'Approved') {
            return 'Start_DateTime_vod__c';
        }
        if (this.requestType == 'Pending') {
            return 'CreatedDate';
        }
        if (this.requestType == 'Closed') {
            return 'LastModifiedDate';
        }

    }
    handleCustomEvent(event) {
        // this.isSearch = false;
        console.log('Handle CustomEvent');
        this.pageNumber = event.detail;
        console.log('this.pageNumber-->', this.pageNumber);
        this.doScrolup();
    }
    connectedCallback() {
        Promise.all([
            loadStyle(this, requestCardCSS),
        ]).then(() => {
            console.log('Files loaded');
        });
        this.setDefaultSortField();
    }
    setDefaultSortField() {
        if (this.requestType == 'Approved') {
            this.sortBy = 'Start_DateTime_vod__c';
        }
        if (this.requestType == 'Pending') {
            this.sortBy = 'CreatedDate';
        }
        if (this.requestType == 'Closed') {
            this.sortBy = 'LastModifiedDate';
        }
    }
    handleSortBY(event) {
        //this.isSearch = false;
        this.sortBy = event.detail.value;
        this.fireDataClickEvent('sort','','',this.sortBy,'RequestAppointment__c', '/requestappointment','');//RT-N-1053  
    }
    handleSearch(event) {
        this.isSearch = true;
        let searchValue = this.template.querySelector('[data-id="searchClicnicalTrial"]').value;
        console.log('searchValue ', searchValue)
        this.searchFilter = searchValue;
        /* if(searchValue.length>0){
             this.isSearch = true;
         }else{
             this.isSearch = false;
         }*/
         this.fireDataClickEvent('search','','',searchValue,'RequestAppointment__c', '/requestappointment','');//RT-N-1053  
    }
    doScrolup() {
        document.body.scrollTop = document.documentElement.scrollTop = 0;
    }
    resetSearch() {
        this.template.querySelector('[data-id="searchClicnicalTrial"]').value = '';
        this.searchFilter = '';
    }

    formatAMPM(DateValue) {//added for Bug_Web_048 by Tausif
        let date = new Date(DateValue);
        let hours = date.getHours();
        let minutes = date.getMinutes();
        let ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        minutes = minutes < 10 ? '0' + minutes : minutes;
        let strTime = hours + ':' + minutes + ' ' + ampm;
        return strTime;
    }

    // Method Name:         navigatetopipeline
    // Method Use:          Navigate to Pipeline Page
    // Developer Name:      Ravi Modi
    // Created Date:        16th March 2023
    navigatetopipeline() {
        this.fireDataClickEvent('button','','',"browse pipeline information",this.siteAPINames.Pipeline, this.siteNames.Pipeline,'');//RT GA 1122 
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.siteAPINames.Pipeline,
                url: this.siteNames.Pipeline
            }
        });
    }
    //google analytics 
    //RT-N-1053
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
                 page_type: 'resources', // RT UAT bug
                 page_purpose:'product resources', // RT UAT bug
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
                 page_title: 'notification',
            },
            bubbles: true,
            composed: true
        }));
    }
}