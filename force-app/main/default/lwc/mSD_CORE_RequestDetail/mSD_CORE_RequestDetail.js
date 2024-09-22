import { LightningElement, wire, track, api } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

import USER_ID from '@salesforce/user/Id';
import User_TimeZone from '@salesforce/schema/User.TimeZoneSidKey';

// Static Resource
import banner from '@salesforce/resourceUrl/PurpleBanner';
import calender from '@salesforce/resourceUrl/MSD_CORE_calendar';
import book from '@salesforce/resourceUrl/MSD_CORE_Book';
import progressbarcss from '@salesforce/resourceUrl/MSD_CORE_ProgressBar';
import cross from '@salesforce/resourceUrl/MSD_CORE_cross';
import edit from '@salesforce/resourceUrl/Editicon';

// Apex Class
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import getmeetingreqdetails from "@salesforce/apex/mSD_CORE_RequestDetail_Controller.getmeetingreqdetails";
import CancelMeetingRequest from "@salesforce/apex/mSD_CORE_RequestDetail_Controller.cancelMeetingRequest";
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import updateReadCheck from '@salesforce/apex/MSD_CORE_Notification.updateReadCheck';//RT
//import getunreadNotification from '@salesforce/apex/MSD_CORE_Notification.getMHEEUnreadNotificationCount';//RT

const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
const weekday = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
const monthShortNames = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

export default class MSD_CORE_RequestDetail extends NavigationMixin(LightningElement) {

    bannerimg = banner;
    calenderimg = calender;
    Bookimg = book;
    crossimg = cross;
    editimg = edit;
    @track cancelreq_pop = false;
    @track meetingId;
    @track notificationId;
    @track siteAPINames;
    @track siteNames;
    @track meetingReqData = [];                 //For Meeting Request data
    @track reqProgress = '';
    @track USER_Time_zone;
    @track contactrole = '';
    @track pendingRequests;
    //@track notiCount;
    isPending = false;//Need to display Preferred appointment times for pending by Tausif
    //get user timezone
    @wire(getRecord, { recordId: USER_ID, fields: [User_TimeZone] })
    userdetails({ data, error }) {
        if (data) {
            console.log('Result in user details-->', { data });
            this.USER_Time_zone = data.fields.TimeZoneSidKey.value;
        } else if (error) {
            console.log('ERROR in user details-->', { error });
        }
    }
    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        console.log({ value });
        const { data, error } = value;
        if (data) {
            console.log({ data });
            this.contactrole = data;
            console.log('raviteja>>>>>', data);
        }
        if (error) {
            console.log({ error });
        }
    }


    // Rendered CallBack
    renderedCallback() {
        Promise.all([
            loadStyle(this, progressbarcss)
        ]).then(() => {
            console.log('External CSS Loaded Successfully');
        })
            .catch(error => {
                console.log('Error In Loading CSS==>', { error });
            });
        this.addCSSForAndroid();
        //refreshApex(this.notiCount);//RT
    }

    // Connected Call back
    connectedCallback() {
        //this.fireOnLoadEvent();
        document.body.scrollTop = document.documentElement.scrollTop = 0;
        this.updateRead();
        /* try {
         } catch (error) {
             console.log('Error in ConnectedCallback-->',{error});
         }*/

    }

   

    //Apply CSS for Android Device
    addCSSForAndroid() {
        try {
            var userAgent = window.navigator.userAgent;
            if (/Android/.test(userAgent)) {
                let statuscls = this.template.querySelector('.status_txt');
                if (statuscls) {
                    statuscls.classList.add('androidStatus')
                }
            }
        } catch (error) {
            console.log('Error in addCSSForAndroid-->', { error });
        }
    }

    //get recordid from parameter
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.meetingId = currentPageReference.state.recordId;
            this.notificationId = currentPageReference.state.nid; //RT 
            console.log('notificationId>>>>>',this.notificationId);//RT
        }
    }
    //RT
     updateRead() {
         
        updateReadCheck({meetid: this.notificationId})
        .then((result) => {
            console.log('Result of updateReadCheck==>',{result});
            //refreshApex(this.notiCount);
        })
        .catch((error) => {
            console.log('Error of updateReadCheck==>',{error});
        });   
    }

    /*//RT
     getNotificationCount() {
        getunreadNotification({ userid: USER_ID })
            .then((result) => {
                console.log({ result });
                if (result> 0) {
                    this.notiCount = result;
                }
            })
            .catch((error) => {
                console.log({ error });
            })
    }*/

    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log('sites Data-->', { data });
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
            this.pendingRequests = data.siteNames.RequestAppointment+  '?tab=Pending requests';
        } else if (error) {
            console.log('ERROR in Getting Sites Name-->', { error });
        }
    }

    // Getting Meeting Request Data
    @wire(getmeetingreqdetails, { requestid: '$meetingId' })
    wiredgetmeetingreqdetails(value) {
        console.log('Meeting Request Value -->', { value });
        const { data, error } = value;
        if (data) {
            this.reqProgress = data.MSD_CORE_Request_Progress__c;
            this.meetingReqData = this.getFormattedData(data);
            console.log('meetingReq Formatted data--->', this.meetingReqData);
            this.fireOnLoadEvent();
            setTimeout(() => {
                let statusbgcls = this.template.querySelector('.status_txt');
                if (data.MSD_CORE_Status__c == 'Pending') {
                    statusbgcls.classList.add('pendingbgcls');
                } else if (data.MSD_CORE_Status__c == 'Closed' || data.MSD_CORE_Status__c == 'Rejected') { // RM -- 27 April 2023
                    statusbgcls.classList.add('closedbgcls')
                } else if (data.MSD_CORE_Status__c == 'Approved') {
                    statusbgcls.classList.add('schedulebgcls')
                }
                this.setPrefferedTimeVisibility(data.MSD_CORE_Status__c);//Need to display Preferred appointment times for pending by Tausif
            }, 500);
            this.template.querySelector("c-m-s-d_-c-o-r-e_-request-bar").updateStatusBar(this.reqProgress);
        } else if (error) {
            console.log('Meeting Request Error--->', { error });
        }
    }

    // Get Formatted Data
    getFormattedData(datavalue) {
        let returndata =
        {
            RequestId: datavalue.Id,
            RequestName: datavalue.MHEE_Name__c,
            Status: (datavalue.MSD_CORE_Status__c != null && datavalue.MSD_CORE_Status__c == 'Approved') ? 'Scheduled' : (datavalue.MSD_CORE_Status__c != null && (datavalue.MSD_CORE_Status__c == 'Rejected' || datavalue.MSD_CORE_Status__c == 'Closed')) ? 'Closed' : 'Pending',
            Preference: datavalue.MSD_CORE_Meeting_preference__c,
            Resoulution: datavalue.MSD_CORE_Request_Resolution__c,
            appointments: datavalue.Meeting_Times__r != null ? this.getappointmentDataFormate(datavalue.Meeting_Times__r) : '',
            MeetSFName: datavalue.ScheduleFilter__c != null ? this.getMeetSFName(datavalue.ScheduleFilter__c) : '',
            ScheduleFilter: datavalue.ScheduleFilter__c != null ? datavalue.ScheduleFilter__c.split(',') : '',
            scheduledDate: datavalue.CreatedDate,//Rusheel
            completionDate: datavalue.MSD_CORE_Completion_Date__c,//Rusheel
            executiveFname: datavalue.Assignee_vod__r.FirstName,//Rusheel
            executiveLname: datavalue.Assignee_vod__r.LastName,//Rusheel
            setDefaultime: datavalue.Start_DateTime_vod__c,//Rusheel
            isPendingReq: datavalue.MSD_CORE_Status__c == 'Pending' ? true : false,
            isScheduleReq: datavalue.MSD_CORE_Status__c == 'Approved' ? true : false,
            isClosedReq: (datavalue.MSD_CORE_Status__c == 'Rejected' || datavalue.MSD_CORE_Status__c == 'Closed') ? true : false,
            isClosed: datavalue.MSD_CORE_Status__c == 'Closed' && datavalue.MSD_CORE_Request_Resolution__c == 'Resolved' ? true : false,
            isCancelled: ((datavalue.MSD_CORE_Request_Resolution__c == 'Request cancelled' && datavalue.MSD_CORE_Status__c == 'Closed') || datavalue.MSD_CORE_Status__c == 'Rejected') ? true : false,
            isscheduled: (datavalue.MSD_CORE_Status__c == 'Closed' && datavalue.MSD_CORE_Request_Progress__c == 'Appointment Scheduled') ? true : false,
            isPendingCanceled: ((datavalue.MSD_CORE_Status__c == 'Closed' && datavalue.MSD_CORE_Request_Resolution__c == 'Request cancelled' && datavalue.MSD_CORE_Request_Progress__c=='Request Submitted')) ? true : false,
            isscheduledCanceled: (datavalue.MSD_CORE_Status__c == 'Closed' && datavalue.MSD_CORE_Request_Resolution__c == 'Request cancelled' && datavalue.MSD_CORE_Request_Progress__c == 'Appointment Scheduled') ? true : false,
            StartTime: datavalue.Start_DateTime_vod__c,
            RequestProgress: datavalue.MSD_CORE_Request_Progress__c,
        }
        console.log(returndata.isscheduledCancel+'isscheduledCancel');
        console.log(returndata.isPendingCancel+'isisPendingCancel');
        return returndata;
    }

    // Formatted Schedule Formate Data
    getMeetSFName(sfdata) {
        let returndata = '';
        try {
            let counterval = 0;
            let formattedsfdata = sfdata.split(',');
            if (formattedsfdata) {
                if (formattedsfdata.length == 1) {
                    returndata = formattedsfdata[0];
                } else {
                    formattedsfdata.forEach(element => {
                        if (returndata.length == 0) {
                            returndata = element;
                        } else {
                            counterval += 1;
                        }
                    });
                    returndata = returndata + ' (+' + counterval + ' more)';
                }
            }
        } catch (error) {
            console.log('ERROR in getMeetSFName-->', { error });
        }
        return returndata;
    }

    // Formatted Appointment Time Data
    getappointmentDataFormate(appDate) {
        let returnData = [];
        try {
            returnData = appDate.map(
                rec =>
                    Object.assign(
                        { "meetingDate": this.getDayDisplay(rec.MSD_CORE_Meeting_Date__c) + ', ' + this.getFullMonth(rec.MSD_CORE_Meeting_Date__c) + ' ' + this.getDay(rec.MSD_CORE_Meeting_Date__c) + ', ' + this.getYear(rec.MSD_CORE_Meeting_Date__c) },
                        { "meetingTime": rec.MSD_CORE_TimeSlot__c }
                    )
            );
        } catch (error) {
            console.log('ERROR in getappointmentDataFormate-->', { error });
        }
        return returnData;
    }

    // Navigate to Dashboard Page
    navigateToDashboard(event) {
        let contname = event.currentTarget.dataset.name;
        this.fireDataClickEvent('button', '', 'modal', 'Go to Dashboard', 'RequestDetail__c', '/requestappointment/requestdetail', contname);//RT-N-1053
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.siteAPINames.Dashboard,
                url: this.siteNames.Dashboard
            },
        });
    }

    viewRequestDetail(event) {
        this.cancelreq_pop = false;
        let contname = event.currentTarget.dataset.cont;
        this.fireDataClickEvent('link', '', 'modal', 'view Request', 'RequestDetail__c', '/requestappointment/requestdetail', contname);//RT-N-1053
    }

    // Cancel Meeting Request
    cancelMeetingReq(event) {
        console.log('this.meetingReqData.Status : ',this.meetingReqData.Status);
        CancelMeetingRequest({ requestid: this.meetingId, status: this.meetingReqData.Status })
            .then((result) => {
                console.log('Result in CancelMeetingRequest--->', { result });
                location.reload();
            })
            .catch((error) => {
                console.log('Error in CancelMeetingRequest-->', { error });
            });
        let contname = event.currentTarget.dataset.name;
        this.fireDataClickEvent('button', '', 'modal', 'Cancel Request', 'RequestDetail__c', '/requestappointment/requestdetail', contname);//RT-N-1053 
    }

    // Open Modal Popup
    openmodalpopup(event) {
        let contname = event.currentTarget.dataset.cname;
        this.fireDataClickEvent('button', '', '', 'cancel Request', 'RequestDetail__c', '/requestappointment/requestdetail', contname);//RT-N-1053
        this.cancelreq_pop = true;
    }

    // Close Modal Popup
    closemodalpopup(event) {
        this.cancelreq_pop = false;
        let contname = event.currentTarget.dataset.name;
        this.fireDataClickEvent('button', '', 'modal', 'back to screen_X', 'RequestDetail__c', '/requestappointment/requestdetail', contname);//RT-N-1053
    }

    // Formatted Date Day Value
    getDayDisplay(date) {
        let s = new Date(date);
        const d = new Date(s.toISOString().slice(0, -1));
        return weekday[d.getDay()];
    }

    // Formatted Day Value
    getDay(date) {
        let s = new Date(date);
        const d = new Date(s.toISOString().slice(0, -1));
        return d.getDate();
    }

    // Formatted Month Value
    getFullMonth(date) {
        let s = new Date(date);
        const d = new Date(s.toISOString().slice(0, -1));
        return monthNames[d.getMonth()];
    }

    // Formatted Month Value
    getMonth(date) {
        let s = new Date(date);
        const d = new Date(s.toISOString().slice(0, -1));
        return monthShortNames[d.getMonth()];
    }

    // Formatted Year Value
    getYear(date) {
        let s = new Date(date);
        const d = new Date(s.toISOString().slice(0, -1));
        return d.getFullYear();
    }
    // Redirect for Edit - For Pending Request-US-1016-Tausif
    handleRequestEdit(event) {
        let contname = event.currentTarget.dataset.cname;
        console.log('conname>>'+contname);
        this.fireDataClickEvent('button', '', '', 'edit Request',this.siteAPINames.Schedule, this.siteNames.Schedule + '?recordId=' + this.meetingId + '&type=nononcology&disease=&action=edit', contname);//RT-N-1053
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.siteAPINames.Schedule,
                url: this.siteNames.Schedule + '?recordId=' + this.meetingId + '&type=nononcology&disease=&action=edit'// + diseaseval + '&ptype=' + this.phaseType
            }
        })
    }
    //RT
    dashnavclick(event){
        
        let labelname = event.currentTarget.dataset.name;
        console.log('labelname>>>',labelname);
    this.fireDataClickEvent('top_nav_breadcrumb', '', 'navigation', labelname,'Home', 'merckmhee/', '');
    }
    reqappnavclick(event){
        let labelname = event.currentTarget.dataset.name;
        console.log('labelname>>>',labelname);
    this.fireDataClickEvent('top_nav_breadcrumb', '', 'navigation', labelname,'RequestAppointment__c', '/requestappointment', '');
    }
    //Google Analytics Event
    // RT-N-1053
    fireOnLoadEvent() {
        console.log('EVENT TRIGGERED');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                // event_category: category,
                // event_action: action,
                // page_type: 'menu',
                // page_purpose:'notifications',
                // page_audience: 'payor',
                // page_marketname: 'united_states',
                // page_region: 'us',
                // page_contentclassification: 'non-commercial',
                data_design_category: '',
                data_design_action: '',
                data_design_label: '',
                data_design_module: '',
                page_type: 'resources',
                page_purpose: 'appointment',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'RequestDetail__c',
                link_url: '/requestappointment/requestdetail',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: this.meetingReqData.MeetSFName,
                page_localproductname: '',
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'RequestDetail',
            },
            bubbles: true,
            composed: true
        }));
    }
    //RT GA bug
    fireDataClickEvent(category, action, module, label, linkedtext, linkedurl, contname) {
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
                data_design_module: module,
                page_type: 'resources',
                page_purpose: 'appointment',
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
                page_title: 'RequestDetail',
            },
            bubbles: true,
            composed: true
        }));
    }

    //Need to display Preferred appointment times for pending by Tausif
    setPrefferedTimeVisibility(meetingStatus) {
        this.isPending = meetingStatus == 'Pending' ? true : false;
    }
}