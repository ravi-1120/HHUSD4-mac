import { LightningElement, track, api, wire } from 'lwc';
import getCatalogs from '@salesforce/apex/MSD_CORE_ProductList.getCatalogs';
import getCatalogRecord from '@salesforce/apex/MSD_CORE_ProductList.getCatalogRecord';
import getPdfDownloadLink from '@salesforce/apex/MSD_CORE_ProductList.getPdfDownloadLink';
import getProducts from '@salesforce/apex/MSD_CORE_ProductList.getProducts';
import USER_ID from "@salesforce/user/Id";
import CATALOG_FIELD from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Catalog__c';
import PAYOR_FIELD from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Payor__c';
import PRODUCTPAYOR_FIELD from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Product_Payor__c';
import removeCatalogs from '@salesforce/apex/MSD_CORE_ProductList.removeCatalogs';
import ACTIVE from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Active__c';
import libObject from '@salesforce/schema/MSD_CORE_Library__c';
import newlogo9 from '@salesforce/resourceUrl/bookmarkSelect';
import { createRecord } from 'lightning/uiRecordApi';
//import timeZoneId from "@salesforce/user/TimeZoneSidKey";
//import TimeZoneSidKey from '@salesforce/schema/User.TimeZoneSidKey';
import { getRecord } from 'lightning/uiRecordApi';
import newlogo2 from '@salesforce/resourceUrl/like';
import newlogo3 from '@salesforce/resourceUrl/prescribeimg';
import newlogo4 from '@salesforce/resourceUrl/whitearrow';
import newlogo5 from '@salesforce/resourceUrl/whiteboxarrow';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import radiocss from '@salesforce/resourceUrl/radiocss';
import plus from '@salesforce/resourceUrl/plusicon';
import banner from '@salesforce/resourceUrl/banner';
import { refreshApex } from '@salesforce/apex';
// import bootstrap from '@salesforce/resourceUrl/BootStrap';
import lightningcss from '@salesforce/resourceUrl/lightningcss';
import DateTimeJS from '@salesforce/resourceUrl/DateTimeJS';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAppointmentDetails from '@salesforce/apex/MSD_CORE_ProductList.getAppointmentDetails';
import arrow from '@salesforce/resourceUrl/rightarrow2';
import crossmark from '@salesforce/resourceUrl/cross';
import createMeetRequest from '@salesforce/apex/MSD_CORE_ProductList.createMeetingRequest';
import uId from '@salesforce/user/Id';
import createMeetingTimes from '@salesforce/apex/MSD_CORE_ProductList.createMeetingTimes';
import deleteMeetingTimes from '@salesforce/apex/MSD_CORE_ProductList.deleteMeetingTimes';
import getMeetingRequest from '@salesforce/apex/MSD_CORE_ProductList.getMeetingRequest';
import getmeetingtime from '@salesforce/apex/MSD_CORE_ProductList.getmeetingtime';
import updatemeetstatus from '@salesforce/apex/MSD_CORE_ProductList.updatemeetstatus';
import createtimemeet from '@salesforce/apex/MSD_CORE_ProductList.createtimemeet';
import { deleteRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import defaultTimeZone from '@salesforce/label/c.defaulttimezone';
import time from '@salesforce/label/c.timezone';
import getPrimaryExecutive from '@salesforce/apex/MSD_CORE_ProductList.getPrimaryExecutive';
import LOCALE from '@salesforce/i18n/locale';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import getUserInfo from '@salesforce/apex/MSD_CORE_ProductList.getUserInfo';

import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import NavigateToDashboard from '@salesforce/label/c.NavigateToDashboard';      //Custom label for navigation to dashboard page
import NavigateToLibrary from '@salesforce/label/c.NavigateToLibrary';          //Custom label for navigation to library page
import showproductsGenericNamewithBrand from '@salesforce/label/c.showproductsGenericNamewithBrand'; //Added by Sabari - To Show Generic Name with Brand

import bannerimg from '@salesforce/resourceUrl/banner';
import callogo from '@salesforce/resourceUrl/calendargreen';
import boxarrow from '@salesforce/resourceUrl/boxarrow';
import rightarrow from '@salesforce/resourceUrl/browseimg';
import reqlogo from '@salesforce/resourceUrl/browse';
import personlogo from '@salesforce/resourceUrl/person';
import edit from '@salesforce/resourceUrl/Editicon';
import cancel from '@salesforce/resourceUrl/cancelicon';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import mfrdomainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
import bookmark from '@salesforce/resourceUrl/bookmark';
const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const higherlimit = 255;

export default class Scheduled extends NavigationMixin(LightningElement) {

    logo5 = banner;
    bookmarkSelect = newlogo9;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('IIIII');
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            console.log('urlStateParameters' + JSON.stringify(this.urlStateParameters));
            this.recId = this.urlStateParameters.recordId;
            this.meetingId = this.urlStateParameters.recordId;
        }
    }
    currentPageReference = null;
    @api recId;
    @track cmsshowheader = false;
    @track meetingcard;
    @track library;
    @track setDefaultime;
    @track timezonetype;
    @track showLoader = false;
    value = '';
    @track hcplink;
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
    @track noTitle = false;
    @track catalofDescription;
    @track productname;
    @track catalogId1;
    @track ProductpayerID;
    @track datevalidation;
    @track meetingstartdate;
    @track meetingcompletiondate;
    @track meetingshareddate;
    @track meetingattendee;
    @track meetingPreference;
    @track requestId;
    @track requestcreateddate;
    @track requestcreatedtime;
    @track requestStatus;
    @track requestProgress;
    @track editflag;
    @track cancelflag;
    @track attendeeList = [];
    @track displaystatus;
    @track headerstatus = '';
    @track resolution;
    @track resolutionflag;
    @track pathpresentationFlag;
    @track meetingPreference;
    @track pathapprovedFlag = false;
    @track pathpendingFlag = false;
    @track pathclosedFlag = false;
    @track pathdefaultFlag = false;
    @track pathrejectedFlag = false;
    // @track isNLB =false;
    // @track isnotNLB =false;
    @track meetingRequestId;
    @track meetingId;
    @track mTimes = [];
    @track attendeeList = [];
    @track meetingUpdate = false;
    userId = uId;
    timezone = time;
    @track prescribinginfo;
    @track medicationguide;
    @track patientInfo;
    @track instructionforuselabel;
    @track instructionforuselink;
    
    plusicon = plus;
    label = {
        NavigateToDashboard,
        NavigateToLibrary
    }
    @track productid;
    contactpageurl = mfrdomainurl +'/my-contacts';
    presinfo = bookmark;
    counttest = 0;
    catalogdata = [];
    loadedMeetingTimes = false;
    loadedAttendeeList = false;
    currentPageReference = null;
    urlStateParameters = null;
    sidearrow = arrow
    cross = crossmark;
    showBrandnamewithGenericName = false;

    cancelbtndis = false;
    sectiondisplay = false;
    appointmentData = [];
    calicon = callogo;
    hcpicon = boxarrow;
    righticon = rightarrow;
    reqicon = reqlogo;
    personicon = personlogo;
    editicon = edit;
    cancelicon = cancel;
    pdfdownloadlink;
    pendigtime = false
    timedisplay;
    @track timeslots = [];
    dateDuplicate = false;
    @track isNLB;

    @track isViewUponRequest = true;              //For View Upon Request

    bool = false;
    requestobj = [];

    footer = false;
    scrollcount;
    showAttendees = true;

    dissablebtn = false;
    // bannerimage = Bannerimg;

    isShow = false;
    sourceTextBox;
    shortDescription;
    isReadMore = false;
    get backgroundStyle() {
        return `background-image:url(${bannerimg})`;
    }

    @wire(getUserInfo, { userId: USER_ID })
    // @wire(getUserInfo, {userId: '0057e00000THDhYAAX'}) //RAVI
    wireuser({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            console.log('inside wire' + data);
            console.log(JSON.stringify(data));
            this.setDefaultime = data.TimeZoneSidKey;
            console.log('this.setDefaultime' + this.setDefaultime);
            this.timezonetype = 'short';
        }

    }


    bookmarklogo = newlogo2;
    logo2 = newlogo3;
    logo3 = newlogo4;
    logo4 = newlogo5;
    @api productName;
    @api productLabel;
    @api productDescription;
    @api genericname;
    @api dosage;
    navigatelibrarydetail;
    navigatelibrarydetailname;
    navigatelibrary;
    navigatelibraryname;
    navigatedashboard;
    navigatedashboardname;
    navigateproduct;
    navigateproductname;
    todaysDate;
    @track selectedStep = 'Step1';
    @track catalogID;
    _handler;
    @track contactrole = '';

    selectStep1() {
        console.log('INside Step1');
        this.selectedStep = 'Step1';
    }

    selectStep2() {
        console.log('INside Step2');
        this.selectedStep = 'Step2';
    }

    selectStep3() {
        console.log('INside Step3');
        this.selectedStep = 'Step3';
    }

    selectStep4() {
        console.log('INside Step4');
        this.selectedStep = 'Step4';
    }


    get timeoption() {
        return [
            { label: 'No preference', value: 'No preference' },
            { label: '09:00 AM - 10:00 AM', value: '09:00AM - 10:00AM' },
            { label: '10:00 AM - 11:00 AM', value: '10:00AM - 11:00AM' },
            { label: '11:00 AM - 12:00 PM', value: '11:00AM - 12:00PM' },
            { label: '12:00 PM - 01:00 PM', value: '12:00PM - 01:00PM' },
            { label: '01:00 PM - 02:00 PM', value: '01:00PM - 02:00PM' },
            { label: '02:00 PM - 03:00 PM', value: '02:00PM - 03:00PM' },
            { label: '03:00 PM - 04:00 PM', value: '03:00PM - 04:00PM' },
            { label: '04:00 PM - 05:00 PM', value: '04:00PM - 05:00PM' },
            { label: '05:00 PM - 06:00 PM', value: '05:00PM - 06:00PM' },
            { label: '06:00 PM - 07:00 PM', value: '06:00PM - 07:00PM' },
            { label: '07:00 PM - 08:00 PM', value: '07:00PM - 08:00PM' },
            { label: '08:00 PM - 09:00 PM', value: '08:00PM - 09:00PM' },
            { label: '09:00 PM - 10:00 PM', value: '09:00PM - 10:00PM' },
        ]
    }


    get options() {
        return [
            { label: 'Virtual', value: 'Virtual meeting' },
            { label: 'In-person', value: 'In-Person meeting' },
        ];
    }
    // @wire(getProducts, { prodId: '$recId' })
    //     wiredgetProducts(value) {
    //         console.log(this.recId);
    //         console.log('Get Product');
    //         console.log({ value });
    //         const { data, error } = value;
    //         if (data) {
    //             console.log({ data });
    //             this.prescribinginfo = data[0].MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c;
    //             console.log('this.prescribinginfo--->', this.prescribinginfo);
    //             this.productName = data[0].MSD_CORE_Product_Payor__r.Name;
    //             this.productDescription = data[0].MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c;
    //             this.aboutProduct = data[0].MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c;
    //             this.hcplink = data[0].MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c;
    //         } else if (error) {
    //             console.log({ error });
    //         }
    //     }

    @wire(getContactRole, { userId:USER_ID })
    wiredgetContactRole(value) {
        console.log({value});
        const { data, error } = value;
        if(data) {
            console.log({data});
            this.contactrole = data;
        }
        if(error) {
            console.log({error});
        }
    }
    handleGA(){
        this.fireDataLayerEvent("link", 'step_0', "contact merck", "registration_flow", 'mycontacts', '/my-contacts','account management','registration');
    }
    handleclickevent(event){
        var msg = event.target.dataset.name;
        console.log({msg});
        this.fireDataClickEvent("top_nav_breadcrumb", '', msg, "navigation",'viewschedule__c','/library/viewschedule'); 
    }
    // Get Time Value
    getmeetingtimevalue() {

        getmeetingtime({ appointmentID: this.recId })
            .then(result => {
                console.log('In scheduled comp');
                console.log({ result });
                this.timedisplay = result;
                this.timeslots = [];
                for (let i = 0; i < this.timedisplay.length; i++) {
                    let tmslot = {};

                    tmslot.MSD_CORE_Meeting_Date__c = this.timedisplay[i].meetingdate;
                    let tsl = this.timedisplay[i].timeslot;
                    let tsl1 = tsl.replaceAll('AM', ' AM');
                    let tsl2 = tsl1.replaceAll('PM', ' PM');
                    tmslot.MSD_CORE_TimeSlot__c = tsl2;
                    this.timeslots.push(tmslot);
                }
                console.log('this.timeslots>>>', this.timeslots);
            })
            .catch(error => {
                console.log({ error });
            })
    }
    connectedCallback() {

        // // RAVI
        // this.recId = 'a8F7e00000014ldEAA';       //RAVI
        // this.meetingId = 'a8F7e00000014ldEAA';
        // console.log('this.recId' + this.recId);
        this.isViewUponRequest = true;
        document.addEventListener('click', this._handler = this.closeCalendar.bind(this));
        this.load();
        this.getlibrarydetailnames();
        this.getlibrarynames();
        this.getproductnames();
        this.getdashboardnames();
        setTimeout(() => {
            var bodydiv = this.template.querySelector(".container");
            var bb = bodydiv.scrollHeight;
            var getdiv = this.template.querySelector(".mfrsf");
            var distanceToTop = getdiv.getBoundingClientRect().top;
            var scrolldiv = distanceToTop - bb;
            console.log({ scrolldiv });
            this.dispatchEvent(new CustomEvent('getdetailsdata', { bubbles: true, detail: scrolldiv }));
        }, 3000);
        sessionStorage.setItem("SelectedValue", false);
       
    }
    getlibrarydetailnames() {
        getSiteNameAndAPIName({ pageName: 'Librarydetail' })
            .then((result) => {
                console.log({ result });
                this.navigatelibrarydetail = result.siteAPIName;
                this.navigatelibrarydetailname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }
    getproductnames() {
        getSiteNameAndAPIName({ pageName: 'ProductList' })
            .then((result) => {
                console.log({ result });
                this.navigateproduct = result.siteAPIName;
                this.navigateproductname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }
    getlibrarynames() {
        getSiteNameAndAPIName({ pageName: 'Library' })
            .then((result) => {
                console.log({ result });
                this.navigatelibrary = result.siteAPIName;
                this.navigatelibraryname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }
    getdashboardnames() {
        getSiteNameAndAPIName({ pageName: 'Dashboard' })
            .then((result) => {
                console.log('DASHBOARD--->',{ result });
                this.navigatedashboard = result.siteAPIName;
                this.navigatedashboardname = result.siteName;
                console.log('this.navigatedashboard--->',this.navigatedashboard);
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }

    load() {

        console.log('Test defaultime Zone--> ' + defaultTimeZone);
        this.headerstatus = '';
        this.editflag = false;
        this.cancelflag = false;
        this.pathpresentationFlag = false;
        this.pathapprovedFlag = false;
        this.pathpendingFlag = false;
        this.pathclosedFlag = false;
        this.pathdefaultFlag = true;
        this.sectiondisplay = false;
        // this.isNLB = false;
        // this.isnotNLB = false;

        // Disable Past Date

        var today = new Date();
        this.todaysDate = today.toISOString().substring(0, 10);
        console.log('this.todayDateTime>>>', this.todaysDate);

        this.datevalidation = false;

        //call the apex controller to get the details for the Catalog
        var d = new Date();
        this.templist.push({ id: 'inputbox' + this.count, value: this.count, calval: '',drpid:'dropdown'+ this.count,caltime:'' });

        console.log('this.templist-->', this.templist);
        this.addattlst.push(this.count1);
        //Get Appointment Details

        this.getmeetingtimevalue();
        this.onloadcall();

        getAppointmentDetails({ appointmentID: this.recId }).then(result => {
            this.appointmentData = result;
            console.log({ result });
            this.productid = result[0].MSD_CORE_Product_Payor__c;
            console.log('Inside Result Appointment Details 111' + JSON.stringify(result));
            console.log('0001111');
            if (result[0].MSD_CORE_Resource__r && result[0].MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c) {
                console.log('000' + result[0].MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c);
                this.catalogName = result[0].MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c;
                console.log('this.catalogName->'+this.catalogName+'-->'+this.requestId);
                if(result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c){
                    this.noTitle = true;
                }
            }

            if (result[0].MSD_CORE_Resource__r && result[0].MSD_CORE_Resource__r.Id) {
                console.log('000' + result[0].MSD_CORE_Resource__r.Id);
                //Call to get the Library information//
                this.catalogId1 = result[0].MSD_CORE_Resource__r.Id;
                console.log('this.catalogId1-->' + this.catalogId1);
                getCatalogRecord({ recId: this.catalogId1, userId: USER_ID })
                    .then(result => {
                        console.log({ result });
                        if (result) {
                            if (result.MSD_CORE_Delivery_Framework__c == 'View upon Request') {
                                this.isViewUponRequest = false;
                            }
                            if(result.MSD_CORE_Leave_Behind__c == 'No Leave Behind') {
                                console.log('noleavebehind');
                                this.isNLB = true;
                                
                            }
                            if (result.MSD_CORE_Content_Type__c == 'Coming Soon') {
                                this.cmsshowheader = true;
                                console.log('headingis' + this.cmsshowheader);
                                this.meetingcard = 'noaroundpad';
                            }else{
                                this.meetingcard = 'multiplerow';
                            }
                            this.library = result.Libraries__r;
                        }
                    }).catch(error => {
                        console.log('Inside Error');
                        this.error = error;
                    });
                //end of lib information
            }
            console.log('1');
            if (result[0].MSD_CORE_Resource__r && result[0].MSD_CORE_Resource__r.MSD_CORE_Description__c) {
                this.catalofDescription = result[0].MSD_CORE_Resource__r.MSD_CORE_Description__c;
                this.shortDescription = (result[0].MSD_CORE_Resource__r.MSD_CORE_Description__c != null && result[0].MSD_CORE_Resource__r.MSD_CORE_Description__c != '') ? result[0].MSD_CORE_Resource__r.MSD_CORE_Description__c.length > higherlimit ? this.doSubstring(result[0].MSD_CORE_Resource__r.MSD_CORE_Description__c, 0, higherlimit) : result[0].MSD_CORE_Resource__r.MSD_CORE_Description__c : '';
                this.isReadMore = (result[0].MSD_CORE_Resource__r.MSD_CORE_Description__c != null && result[0].MSD_CORE_Resource__r.MSD_CORE_Description__c != '') ? (result[0].MSD_CORE_Resource__r.MSD_CORE_Show_Read_More__c === true && result[0].MSD_CORE_Resource__r.MSD_CORE_Description__c.length > higherlimit) ? true : false : false;
            } else {
                this.shortDescription = '';
                this.isReadMore = false;

            }
            console.log('2');
            if (result[0].MSD_CORE_Product_Payor__r && result[0].MSD_CORE_Product_Payor__r.Name)
                this.productname = result[0].MSD_CORE_Product_Payor__r.Name;

            this.prescribinginfo = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c;
            this.medicationguide = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Medication_Guide__c;
            this.patientInfo = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Patient_information__c;
            this.instructionforuselabel = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Instructions_For_Use_Label__c;
            this.instructionforuselink = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Instructions_For_Use_Link__c;

            this.hcplink = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c;
            console.log('3');
            // if(result.Product_Payor__r.Product_Description__c)
            console.log('0');
            if (result[0].MSD_CORE_Product_Payor__c) {
                if (result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c)
                    this.MSD_CORE_productDescription = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c;
                console.log("ProdDesc: " + this.MSD_CORE_productDescription);
            }

            //   if(result.Product_Payor__r.Product_Description__c)
            console.log('4');
            if (result[0].MSD_CORE_Product_Payor__r.Name)
                this.productName = result[0].MSD_CORE_Product_Payor__r.Name;
            if (result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Product_Labeling__c)
                this.productLabel = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Product_Labeling__c;
                
            if (result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c)
                this.genericname = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c;

            if (result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Dosage_Form_and_Strength__c)
                this.dosage = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Dosage_Form_and_Strength__c;

            console.log("Gename: " + this.genericname);
            console.log("Dosinfo: " + this.dosage);

            console.log('1111');
            if (result[0].Start_DateTime_vod__c)
                this.meetingstartdate = result[0].Start_DateTime_vod__c;
            if (result[0].MSD_CORE_Completion_Date__c)
                this.meetingcompletiondate = result[0].MSD_CORE_Completion_Date__c;
            if (result[0].MSD_CORE_Shared_Date__c)
                this.meetingshareddate = result[0].MSD_CORE_Shared_Date__c;
            
            console.log('0000');
            if (result[0].MSD_CORE_attendee__c)
                this.meetingattendee = result[0].MSD_CORE_attendee__c;
            if (result[0].MSD_CORE_attendee__c) {
                let emaillet = result[0].MSD_CORE_attendee__c.split(',');
                for (let i = 0; i < emaillet.length; i++) {
                    let emailval = emaillet[i];
                    let emailname = emailval.substring(0, emailval.lastIndexOf("@"));
                    let domain = emailval.substring(emailval.lastIndexOf("@") + 1);
                    let newemailname = emailname.length > 8 ? (emailname.substring(0, 8) + '....' + '@' + domain) : (emailname + '@' + domain);

                    this.attendeeList.push(newemailname);
                }
            }
            console.log('this.attendeeList-->' + this.attendeeList);
            console.log('2222');
            if (result[0].MSD_CORE_Meeting_preference__c)
                this.meetingPreference = result[0].MSD_CORE_Meeting_preference__c;
            if (result[0].Name)
                this.requestId = result[0].Name;
            if (result[0].CreatedDate) {
                this.requestcreateddate = result[0].CreatedDate;
                console.log('before  locale' + this.requestcreateddate);
            }
            if (result[0].MSD_CORE_Status__c)
                this.requestStatus = result[0].MSD_CORE_Status__c;
            if (result[0].MSD_CORE_Request_Progress__c)
                this.requestProgress = result[0].MSD_CORE_Request_Progress__c;
            if (result[0].MSD_CORE_Request_Resolution__c) {
                this.resolution = result[0].MSD_CORE_Request_Resolution__c;
            }
            console.log('Inside Resolution' + this.resolution);

            this.fireOnLoadEvent();

        }
        ).catch(error => {
            console.log('INside view appointment Error');
            console.log({ error });
            this.error = error;
        });
    }

    @api
    hidefooter(detaildata) {
        console.log('Hide Footer');
        if (detaildata == 'true') {
            this.footer = true;
        } else {
            this.footer = false;
        }
    }

    @api
    showHideFooter(pageOffset) {
        let elem = this.template.querySelector('c-mfr_-safety');
        let hideFooterOffset = 0;
        if (elem) {
            hideFooterOffset = elem.offsetTop - window.innerHeight + 100;
            hideFooterOffset = (hideFooterOffset > 0) ? hideFooterOffset : 0;
        }

        this.footer = pageOffset > hideFooterOffset;
    }

    getTime(date) {
        let d = new Date(date);
        let time = d.toLocaleTimeString('en-US', { timeZone: this.defaultTimeZone });
        let AMPM = time.substring(time.length - 2, time.length);
        let tempTime = time.substring(0, 5);
        return tempTime + ' ' + AMPM;

    }
    get setStatusHeader() {
        if (this.requestStatus == 'Approved') {
            this.headerstatus = 'Scheduled';
        }
        else if (this.requestStatus == 'Pending') {
            this.headerstatus = 'Pending';
            this.pendigtime = true;
        }
        else if (this.requestStatus == 'Rejected') {
            this.headerstatus = 'Rejected';
        }
        else if (this.requestStatus == 'Closed') {
            this.headerstatus = 'Closed';
        }
    }


    progressStatus() {
        if(this.isViewUponRequest == true){
            if (this.requestProgress == 'Appointment Scheduled') {
                this.pathapprovedFlag = true;
                this.pathpendingFlag = false;
                this.pathclosedFlag = false;
                // this.isNLB = false;
                // this.isnotNLB = false;
                this.pathdefaultFlag = false;
                this.pathpresentationFlag = false;
                this.pathrejectedFlag = false;
                console.log("Request Progress ==" + this.requestProgress);
                console.log("Flag ==" + this.pathapprovedFlag);
            }
            else if (this.requestProgress == 'Request Submitted') {
                this.pathapprovedFlag = false;
                this.pathpendingFlag = true;
                this.pathclosedFlag = false;
                // this.isNLB = false;
                // this.isnotNLB = false;
                this.pathdefaultFlag = false;
                this.pathpresentationFlag = false;
                this.pathrejectedFlag = false;
                console.log("Request Progress ==" + this.requestProgress);
                console.log("Flag ==" + this.pathpendingFlag);
            }
            else if (this.requestProgress == 'Presentation Attended') {
                this.pathapprovedFlag = false;
                this.pathpendingFlag = false;
                this.pathclosedFlag = false;
                // this.isNLB = false;
                // this.isnotNLB = false;
                this.pathdefaultFlag = false;
                this.pathpresentationFlag = true;
                this.pathrejectedFlag = false;
                console.log("Request Progress ==" + this.requestProgress);
                console.log("Flag ==" + this.pathpresentationFlag);
            }
            else if (this.requestProgress == 'Received post-presentation materials') {
                this.pathapprovedFlag = false;
                this.pathpendingFlag = false;
                this.pathclosedFlag = true;
                // this.isNLB = true;
                // this.isnotNLB = true;
                this.pathdefaultFlag = false;
                this.pathpresentationFlag = false;
                this.pathrejectedFlag = false;
                console.log("Request Progress ==" + this.requestProgress);
                console.log("Flag ==" + this.pathclosedFlag);
            }
            else {
                this.pathapprovedFlag = false;
                this.pathpendingFlag = true;
                this.pathclosedFlag = false;
                // this.isNLB = false;
                // this.isnotNLB = false;
                this.pathdefaultFlag = false;
                this.pathpresentationFlag = false;
                this.pathrejectedFlag = false;
                console.log("Request Progress ==" + this.requestProgress);
                console.log("Default flag");
            }
        }else{
                if (this.requestProgress == 'Resource received') {
                this.pathapprovedFlag = false;
                this.pathpendingFlag = false;
                this.pathclosedFlag = true;
                // this.isNLB = false;
                // this.isnotNLB = false;
                this.pathdefaultFlag = false;
                this.pathpresentationFlag = false;
                this.pathrejectedFlag = false;
                console.log("Request Progress ==" + this.requestProgress);
                console.log("Flag ==" + this.pathclosedFlag);
            }else{
                this.pathapprovedFlag = false;
                this.pathpendingFlag = true;
                this.pathclosedFlag = false;
                // this.isNLB = false;
                // this.isnotNLB = false;
                this.pathdefaultFlag = false;
                this.pathpresentationFlag = false;
                this.pathrejectedFlag = false;
                console.log("Request Progress ==" + this.requestProgress);
                console.log("Flag ==" + this.pathpendingFlag);
            }
        }
        
    }

    get setStatusCSS() {
        console.log('CSS11-->' + this.requestStatus);
        console.log('CSS22-->' + this.resolution);

        this.resolutionflag = false;
        if (this.requestStatus) {
            if ((this.requestStatus == 'Approved') && (this.requestProgress == 'Received post-presentation materials')) {
                console.log('Inside Approved');
                this.displaystatus = 'Scheduled';
                this.cancelflag = false;
                this.editflag = false;
                this.progressStatus();
            
                console.log("Request Approved Progress Status == " + this.requestProgress);

                return 'schedule-appointment__Scheduled-Approved';
            }
            else if (this.requestStatus == 'Approved') {
                console.log('Inside Approved');
                this.displaystatus = 'Scheduled';
                this.cancelflag = true;

                // For Disabling Cancel Request Button
                if (this.appointmentData[0].Start_DateTime_vod__c) {
                    const todaydate = new Date();
                    const startdate = new Date(this.appointmentData[0].Start_DateTime_vod__c);
                    if (startdate < todaydate && this.appointmentData[0].MSD_CORE_Status__c == 'Approved') {
                        this.dissablebtn = true;
                    } else {
                        this.dissablebtn = false;
                    }
                }

                this.editflag = false;
                this.progressStatus();
                
                console.log("Request Approved Progress Status == " + this.requestProgress);

                return 'schedule-appointment__Scheduled-Approved';
            }
            else if (this.requestStatus == 'Pending') {
                console.log('Inside Pending');
                this.selectStep1();
                this.cancelflag = true;

                // For Disabling Cancel Request Button
                if (this.appointmentData[0].Start_DateTime_vod__c) {
                    const todaydate = new Date();
                    const startdate = new Date(this.appointmentData[0].Start_DateTime_vod__c);
                    if (startdate < todaydate && this.appointmentData[0].MSD_CORE_Status__c == 'Approved') {
                        this.dissablebtn = true;
                    } else {
                        this.dissablebtn = false;
                    }
                }


                if( this.isViewUponRequest) {
                    this.editflag = true;
                }
                else {
                    this.editflag = false;
                }
                this.displaystatus = 'Pending';
                this.progressStatus();
              
                console.log("Request Pending Progress Status == " + this.requestProgress);

                return 'schedule-appointment__Scheduled-Pending';
            }
            else if (this.requestStatus == 'Rejected') {
                console.log('Inside Rejected');
                this.cancelflag = false;
                this.editflag = false;
                this.displaystatus = 'Rejected';
                this.resolutionflag = true;
                this.progressStatus();
                
                console.log("Request Rejected Progress Status == " + this.requestProgress);
                return 'schedule-appointment__Scheduled-Rejected';
            }
            else if (this.requestStatus == 'Closed' && this.resolution == 'Resolved') {
                console.log('Inside Closed Resolved and Closed');
                this.displaystatus = 'Closed';
                this.resolutionflag = true;
                this.cancelflag = false;
                this.editflag = false;
                this.progressStatus();
                
                console.log("Request Closed Progress Status == " + this.requestProgress);
                return 'schedule-appointment__Scheduled-Rejected';
            }
            else if (this.requestStatus == 'Closed' && this.resolution == 'Request cancelled') {
                console.log('Inside Default closed & Request Cancelled');
                this.displaystatus = 'Closed';
                this.resolutionflag = true;
                this.cancelflag = false;
                this.editflag = false;
                this.progressStatus();
                console.log("Request Closed Progress Status == " + this.requestProgress);
                return 'schedule-appointment__Scheduled-Rejected';
            }
            else {
                console.log('Inside Default closed');
                this.displaystatus = 'Closed';
                this.resolutionflag = true;
                this.cancelflag = false;
                this.editflag = false;
                this.progressStatus();
                console.log("Request Default Progress Status == " + this.requestProgress);
                return 'schedule-appointment__Scheduled-Rejected';
            }
        }


    }

    backbutton(event) {
        console.log('Backbutton');        
        var tabname = '';
        if (this.headerstatus == 'Scheduled') {
            tabname = 'Appointment';
        } else if (this.headerstatus == 'Pending') {
            tabname = 'Request';
        } else if (this.headerstatus == 'Closed') {
            tabname = 'Closed';
        }
        console.log('this.productid-->', this.productid);
        var navigateurl = this.navigatelibrarydetail + '?recordId=';
        navigateurl += this.productid;
        if (tabname != '') {
            navigateurl += '&tab=' + tabname;
        }
        console.log({ navigateurl });
        this.fireDataClickEvent("top_nav_breadcrumb", '', event.target.dataset.name, "navigation",'viewschedule__c',navigateurl);
        window.location.replace(navigateurl);
    }
    populateAppointments() {
        if (this.sectiondisplay && this.mTimes && !(this.loadedMeetingTimes)) {
            console.log('Inside Meeting Times');

            let dates = this.template.querySelectorAll('.Date');
            let times = this.template.querySelectorAll('.Time');
            for (let i = 0; i < this.mTimes.length; i++) {

                if (dates) {

                    let dt = new Date(this.mTimes[i].MSD_CORE_Meeting_Date__c);
                    // dates[i].value = dt.toLocaleString('default', {month: 'short',}) + ' ' + dt.getDate() + ', ' + dt.getFullYear();
                    dates[i].value = months[dt.getMonth()] + ' ' + dt.getDate() + ', ' + dt.getFullYear();
                    console.log('dates[i].value---==>', dates[i].value);
                }
                if (times) {
                    times[i].value = this.mTimes[i].MSD_CORE_TimeSlot__c;
                    console.log('TTT' + times[i].value);
                }
            }
        }
    }

    renderedCallback() {
        /* Added by Sabari - For Keytruda Launch */
        let brandswithGenericName = showproductsGenericNamewithBrand.split(',');
        if(brandswithGenericName.includes(this.productLabel))
        {
            this.showBrandnamewithGenericName = true;
        }
        console.log('this.loadedMeetingTimes' + this.loadedMeetingTimes);
        console.log('this.mTimes', this.mTimes);

        console.log('this.loadedAttendeeList' + this.loadedAttendeeList);
        if (this.sectiondisplay && this.attendeeList && !(this.loadedAttendeeList)) {
            let attendees = this.attendeeList;

            let emailAddress = this.template.querySelectorAll('lightning-input[data-id="attendee"]');
            for (let i = 0; i < attendees.length; i++) {
                emailAddress[i].value = attendees[i];
            }
            this.loadedAttendeeList = true;
        }

        if (this.attendeeList.length > 0) {
            this.showAttendees = true;
        } else {
            this.showAttendees = false;
        }

        Promise.all([
            // loadStyle(this, bootstrap),
            loadStyle(this, lightningcss),
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

      
        if (this.attendeeList.length === 1 && this.attendeeList.length > 0) {
            this.hideRemoveAttendee = true;
        } else {
            this.hideRemoveAttendee = false;
        }

        /* Added by Sabari to add the new line in Catalog description */
        let finddescelement = this.template.querySelector('.updatedesc');
        if(finddescelement){
          const datavalue = finddescelement.getAttribute("data-value");
          console.log('inside rendered '+datavalue);
          finddescelement.innerHTML = datavalue;
        }

        if(this.catalofDescription){
            const jobvalueparts = this.catalofDescription.split(/<br>\s*<br>/);
            if(jobvalueparts.length >=2){
                const jobid = jobvalueparts[jobvalueparts.length-1].trim();
                if(jobid!==""){
                    let subelement = this.template.querySelector('.jobid');
                    if(subelement){
                        subelement.innerHTML = '<br>'+jobid;
                    }
                }
            }
        }

    }
 

    handleDateTime(event) {
        this.dateDuplicate = false;
    }
    catalogList() {
        getCatalogs({ prodId: this.recId, userId: USER_ID })
            .then(result => {
                this.catalogdata = result;
                console.log('106-cataloglist');
                console.log({ result });
                let record = result;
                console.log('result--' + JSON.stringify(result));
                this.products = record.map(row => ({
                    ...row,
                    isViewInMeeting: row.MSD_CORE_Delivery_Framework__c === 'View in Meeting',
                    isViewImmediately: row.MSD_CORE_Delivery_Framework__c === 'View Immediately',
                    isViewUponRequest: row.MSD_CORE_Delivery_Framework__c === 'View upon Request',
                }));
                console.log('106-cataloglist' + JSON.stringify(this.products));
                this.error = undefined;
                this.productName = result[0].MSD_CORE_Product_Payor__r.Name;
                this.productLabel = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Product_Labeling__c;
                
                this.productDescription = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c;
                this.genericname = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c;
                this.dosage = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Dosage_Form_and_Strength__c;
                this.aboutProduct = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c;
                this.hcplink = result.MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c;
                this.prescribinginfo = result.MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c;
                this.medicationguide = result.MSD_CORE_Product_Payor__r.MSD_CORE_Medication_Guide__c;
                this.patientInfo = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Patient_information__c;
                this.instructionforuselabel = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Instructions_For_Use_Label__c;
                this.instructionforuselink = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Instructions_For_Use_Link__c;

                console.log('this.pdfDownloadLink==>', this.prescribinginfo);
                console.log("Generic name: " + this.genericname);
                console.log("Dosage : " + this.dosage);

                this.showRecordsDetailsLabel(this.products);
                this.displayRecordPerPage(this.page);
            })
            .catch(error => {
                this.error = error;
            });
    }
    handleVisitUrl(event) {
        var linkId = event.currentTarget.dataset.id;
        console.log(event.currentTarget.dataset.id);
        console.log(event.target.dataset.id);
        if (this.products.length > 0) {
            this.products.forEach(ele => {
                console.log(JSON.stringify(ele));
                if (ele.Id == linkId) {
                    console.log('url-->' + ele.MSD_CORE_HCP_site__c);
                    window.open(ele.MSD_CORE_HCP_site__c, '__blank');
                }
            });
        }

    }
    addnewdate(event) {

        try {
            this.isShow = false;
            this.bool = true;
            let dates = this.template.querySelectorAll('.Date');
            console.log('dates-->', { dates });
            let allowDate = true;
            var d = new Date();
            dates.forEach(e => {
                if (allowDate) {
                    if (!e.value) {
                        allowDate = false;
                        this.template.querySelector('c-custom-toast').showToast('error', 'Date cannot be empty');
                    } 
                }
            });
            if (this.templist.length >= 3) {
                this.template.querySelector('c-custom-toast').showToast('error', 'Maximum 3 appointment times allowed');
            }
            if (allowDate && this.templist.length < 3 && (!this.dateDuplicate)) {
                this.count += 1;
                this.templist.push({ id: 'inputbox' + this.count, value: this.count, calval: '',drpid:'dropdown'+this.count,caltime:'' });
            }
        }
        catch (error) {
            console.log('error' + JSON.stringify(error));
        }
        this.fireDataLayerEvent('button', 'step_1_edit','add date','form','viewschedule__c','/library/viewschedule',this.catalogName,this.productName); //RT-N-1053
    }
    
    addnewatte() {
        this.loadedAttendeeList = true;
        let validationsList = this.handlerEmailValidation();
        console.log({ validationsList });

        console.log('attendeeList--->', this.attendeeList);
        console.log('attendeeList--->', this.attendeeList.length);
        if (!validationsList.includes(false)) {
            if (this.attendeeList.length <= 3) {
                console.log('iff');
                this.count1 += 1;
                this.attendeeList.push('');
                console.log('this.attendeeList-->', this.attendeeList);
            } else {
                this.template.querySelector('c-custom-toast').showToast('error', 'only 4 attendees are allowed');
            }

            console.log('--this.attendeeList-->', this.attendeeList);
        }
        this.fireDataLayerEvent('button', 'step_3_edit','add attendee','form','viewschedule__c','/library/viewschedule',this.catalogName,this.productName); //RT Analytics bug
    }

    removedate(event) {
        let tobeDeletedID = event.currentTarget.dataset.id
        this.loadedMeetingTimes = true;
        var indx = event.target.dataset.value;
        this.removeDatafromTempList(tobeDeletedID);
        this.fireDataLayerEvent('date/time', 'step_1_edit','date/time Removed','form','viewschedule__c','/library/viewschedule',this.catalogName,this.productName); //RT-N-1053
    }

    removeDatafromTempList(_tobeDeletedID) {
        console.log('_tobeDeletedID ' + _tobeDeletedID)
        let _tempList = [];
        this.templist.forEach(currentItem => {
            if (currentItem.id != _tobeDeletedID) {
                _tempList.push(currentItem);
            }
        });
        this.templist = [];
        console.log('_tempList' + JSON.stringify(_tempList));
        this.templist = JSON.parse(JSON.stringify(_tempList));
        console.log('this.templist _tobeDeletedID' + JSON.stringify(this.templist));
        this.resetTempList();
    }

    resetTempList() {
        let _itemList = [];
        let ctr = 0;
        this.templist.forEach(currentItem => {
            _itemList.push({ id: 'inputbox' + ctr, value: ctr, calval: currentItem.calval,drpid:'dropdown'+ctr,caltime: currentItem.caltime });
            ctr++;
        });
        this.count =ctr-1;
        this.templist = [];
        this.templist = JSON.parse(JSON.stringify(_itemList));
        console.log('this.templist resetTempList' + JSON.stringify(this.templist));
    }
    
    removefield(event) {
        console.log('Remove Fiele');
        this.loadedAttendeeList = true;
        var indx = event.target.dataset.value;
        console.log({ indx });

        console.log('attendeeList==>', this.attendeeList);
        if (this.attendeeList.length > 1) {
            this.attendeeList.splice(indx, 1);
        }
        console.log('this.addattlst-->', this.attendeeList);
        this.fireDataLayerEvent('button', 'step_3_edit','attendee removed','form','viewschedule__c','/library/viewschedule',this.catalogName,this.productName); //RT GA bug
    }

    handleTime() {

        var validdate = [];
        console.log('Handle Time');
        this.loadedMeetingTimes = true;
        let dates = this.template.querySelectorAll('.Date');
        let times = this.template.querySelectorAll('.Time');
        let datelst = [];
        console.log({ dates });
        console.log({ times });
        for (let i = 0; i < dates.length; i++) {
            console.log('Times' + times[i]);
            console.log('dates[i].value==>', dates[i].value);

            let formatteddate = '';
            if (dates[i] != undefined || dates[i] != null) {
                formatteddate = this.getformattedDate(dates[i].value);
            }
            console.log({ formatteddate });

            if (formatteddate == null || formatteddate == '' || formatteddate == undefined || formatteddate == 'NaN-NaN-NaN') {
                console.log('NuLL');
                if (times[i].value == null || times[i].value == '') {
                    times[i].value = 'No preference:No preference';
                }
                this.template.querySelector('c-custom-toast').showToast('error', 'Date cannot be empty');
                validdate = false;
                return validdate;
            } else {
                console.log('ELSE');
                if (dates[i] && times[i]) {
                    let dValues = formatteddate.split('-');
                    console.log({ dValues });
                    let tValues;
                    if (times[i].value != undefined && times[i].value.includes(':')) {
                        tValues = times[i].value.split(':');
                        console.log('Inside if');
                    }
                    else {
                        var defaultval = 'No preference:No preference';
                        tValues = defaultval.split(':');
                    }

                    if (times[i].value == undefined || tValues[0] == 'No preference') {
                        console.log('INSIDE Actual');
                        tValues[0] = '00';
                        tValues[1] = '00';
                    } else {
                        let timestamp = tValues[1].split(' ');
                        tValues[1] = timestamp[0];
                        if (tValues[1] == '00PM') {
                            tValues[0] = tValues[0] + 12;
                            tValues[1] = '00';
                        }
                        if (tValues[1] == '00AM') {
                            tValues[1] = '00';
                        }
                    }

                    console.log('dValues[0]-->', dValues[0]);
                    let dt = new Date(dValues[0], dValues[1], dValues[2], tValues[0], tValues[1], 0);
                    datelst.push(dt.toString());
                    console.log({ datelst });
                    validdate = true;
                }

            }
        }
        const unique = Array.from(new Set(datelst));
        if (datelst.length != unique.length) {
            this.dateDuplicate = true;
            this.template.querySelector('c-custom-toast').showToast('error', 'Date and Time must be unique');
            validdate = false;
            return validdate;
        } else {
            this.dateDuplicate = false;
            validdate = true;
        }
        return validdate;
    }

    handlerEmailValidation() {

        console.log('EMail Validation!!!');
        let validations = [];
        var flag = true;
        const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        let emails = this.template.querySelectorAll('lightning-input[data-id="attendee"]');
        var emaillist = [];

        emails.forEach(currentItem => {

            let emailAddress = currentItem.value;
            console.log('currentItems--' + JSON.stringify(emailAddress));
            var emailVal = emailAddress;
            console.log({ emailVal });
            console.log('emailVal==>', emailVal);
            flag = true;

            // To check Email is Null or Not
            if (emailVal != null || emailVal != '') {

                if (emailAddress) {
                    if (emailVal.match(emailRegex)) {
                        emaillist.push(emailVal);
                        validations.push(flag);
                    } else {
                        flag = false;
                        currentItem.focus();
                        validations.push(flag);
                        this.template.querySelector('c-custom-toast').showToast('error', 'Invalid e-mail');

                    }
                } else {
                    emaillist.push(emailVal);
                    validations.push(true);
                }

            } else if (emailVal = "") {
                emaillist.push(emailVal);
                validations.push(true);
            } else {
                this.template.querySelector('c-custom-toast').showToast('error', 'Please Enter Email Address');
            }
        })
        //For Duplicate EMail Validation

        function getUnique(array) {
            var uniqueArray = [];

            // Loop through array values
            for (var value of array) {
                console.log({ value });
                if (uniqueArray.indexOf(value) === -1) {
                    uniqueArray.push(value);
                }
            }
            return uniqueArray;
        }

        var uniqueNames = getUnique(emaillist);

        if (uniqueNames.length != emaillist.length) {
            flag = false;
            validations.push(flag);
            this.template.querySelector('c-custom-toast').showToast('error', 'Duplicate Email Found!');
        } else {
            flag = true;
            validations.push(flag);
        }

        //
        return validations;
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

        console.log('<--handleSubmit-->');

        let dates = this.template.querySelectorAll('.Date');
        console.log({ dates });
        let times = this.template.querySelectorAll('.Time');
        let meetingPreference = this.template.querySelectorAll('.radiobtncls');
        let meetingPreferenceValidation = true;
        meetingPreference.forEach(e => {
            if (meetingPreferenceValidation) {
                if (e.value) {
                    meetingPreferenceValidation = false;
                }
            }
        });

        if (meetingPreferenceValidation) {

        }

        var valid = this.handleTime();
        console.log({ valid });

        if (valid) {
            if (dates.length > 0 && dates[0].value != null && dates[0].value != undefined && dates[0].value != '' && times.length > 0 && times[0].value != null && times[0].value != undefined && times[0].value != '') {
                if (!meetingPreferenceValidation) {

                    let response = this.handlerEmailValidation();
                    if (!response.includes(false) && !this.dateDuplicate) {
                        let MeetingRequest = {};
                        let emailAddress = this.template.querySelectorAll('lightning-input[data-id="attendee"]');

                        emailAddress.forEach(item => {
                            if (item.value) {
                                this.emailVal = this.emailVal ? this.emailVal + ',' + item.value : item.value;
                            }
                        });
                        MeetingRequest.MSD_CORE_Status__c = 'Pending';
                        MeetingRequest.MSD_CORE_Meeting_preference__c = this.template.querySelector('.radiobtncls').value;
                        MeetingRequest.MSD_CORE_attendee__c = this.emailVal ? this.emailVal : '';
                        if (this.ProductpayerID) {
                            MeetingRequest.MSD_CORE_Product_Payor__c = this.ProductpayerID;
                        }
                        if (this.meetingId) {
                            MeetingRequest.Id = this.meetingId;
                        }
                        if (this.userId) {
                            MeetingRequest.MSD_CORE_Payor__c = this.userId;
                        }
                        if (this.catalogID) {
                            MeetingRequest.MSD_CORE_Resource__c = this.catalogID;
                        }
                        this.meetingRequests.push(MeetingRequest);
    

                        this.requestobj.recordId = this.recId;
                        this.requestobj.attendee = this.emailVal;;
                        this.requestobj.meetingPreference = this.template.querySelector('.radiobtncls').value;
                        console.log('this.requestobj==>', this.requestobj);
                        var req = JSON.stringify(this.requestobj);
                        console.log({ req });

                        this.counttest += this.counttest;
                        console.log('this.counttest-->', this.counttest);


                        console.log('Create MEet');
                        console.log('Meeting Request->', this.meetingRequests);
                        console.log('JSON.stringify(this.meetingRequests)--->', JSON.stringify(this.meetingRequests));

                        this.showLoader = true;
                        createMeetRequest({ request: JSON.stringify(this.meetingRequests) })
                            .then(result => {
                                deleteMeetingTimes({ requestID: result.data.Id })
                                .then(res => {
                               
                                console.log('::Create MEET Request::');
                                console.log({ result });
                                console.log('Result' + JSON.stringify(result));
                                this.meetingRequestNumber = result.data.Name;
                                this.meetingRequestId = result.data.Id;
                                let meetingTimes = [];
                                for (let i = 0; i < dates.length; i++) {
                                    let formatteddate = this.getformattedDate(dates[i].value);
                                    if (dates.length > 0) {
                                        this.dateVal = formatteddate;
                                    }

                                    if (times.length > 0) {
                                        this.timeVal = times[i].value;
                                    }
                                    if (!this.timeVal) {
                                        this.timeVal = 'No preference:No preference'
                                    }
                                    console.log('Date' + this.dateVal);
                                    console.log('Time' + this.timeVal);
                                    let dValues = this.dateVal.split('-');
                                    let tValues = this.timeVal.split(':');
                                    if (tValues[0] == 'No preference') {
                                        tValues[0] = '00';
                                        tValues[1] = '00';
                                    } else {
                                        let timestamp = tValues[1].split(' ');
                                        tValues[1] = timestamp[0];
                                    }
                                    let meetingTime = {};
                                    meetingTime.MSD_CORE_Meeting_Date__c = formatteddate;
                                    console.log('meetingTime.MSD_CORE_Meeting_Date__c==>', meetingTime.MSD_CORE_Meeting_Date__c);
                                    meetingTime.MSD_CORE_Meeting_Request__c = result.data.Id;
                                    meetingTime.MSD_CORE_Time_Slot__c = times[i].value;
                                    console.log('meetingTime.MSD_CORE_Time_Slot__c--=>', meetingTime.MSD_CORE_Time_Slot__c);
                                    meetingTime.MSD_CORE_TimeSlot__c = times[i].value;
                                    if (meetingTime.MSD_CORE_TimeSlot__c == null || meetingTime.MSD_CORE_TimeSlot__c == '') {
                                        meetingTime.MSD_CORE_TimeSlot__c = 'No preference';
                                    }
                                    
                                    meetingTime.MSD_CORE_Time_Slot__c = tValues[0] + ':' + tValues[1];
                                    meetingTimes.push(meetingTime);
                                    console.log('meetingTime===>', meetingTime);

                                }
                            
                                createMeetingTimes({ request: JSON.stringify(meetingTimes) })
                                    .then(result => {
                                        console.log('::createMeetingTimes::');
                                        console.log({ result });
                                    })
                                    .catch(e => {
                                        console.log('::::createMeetingTimes ERROR::::');
                                        console.log({ e });
                                        console.log('error meeting times' + JSON.stringify(e));
                                    });
                                    
                                })
                                .catch(error => {

                                    console.log('Error While deleting Meeting Time');
                                    console.log({ error });
                                    console.log('error' + JSON.stringify(error));
                                }).finally(() => {
                                    this.showResponse = true;
                                    this.showLoader = false;
                                    console.log('Finally2');
                                })
    
                            })
                            .catch(error => {

                                console.log('::::Create MEet Request ERROR::::');
                                console.log({ error });
                                console.log('error' + JSON.stringify(error));
                            }).finally(() => {
                                this.showResponse = true;
                                this.showLoader = false;
                                console.log('Finally2');
                            })
                    }
                }
                else {
                    this.showLoader = false;
                    this.template.querySelector('c-custom-toast').showToast('error', 'Please specify Meeting Preference');
                }
            }
            else {
                this.showLoader = false;
                this.template.querySelector('c-custom-toast').showToast('error', 'Plese select atleast one Date');
                console.log('Else');
            }
        }

        console.log('::END::');
        this.fireDataLayerEvent('button', 'step_4_edit', 'submit request','form','viewschedule__c','/library/viewschedule',this.catalogName,this.productName); //RT-N-1053
        //}
    }

    closeResponse() {
        this.showResponse = false;
    }

    cancelbtn() {
        console.log('Cancel Btn');
        this.cancelbtndis = false;
        this.sectiondisplay = false;

        //reset values
        this.templist = [];
        this.addattlst = [];
        this.attendeeList = [];
        this.connectedCallback();
        this.fireDataLayerEvent('button', 'step_4_edit', 'cancel request','form','viewschedule__c','/library/viewschedule',this.catalogName,this.productName);//RT GA bug
        let containerChoosen = this.template.querySelector('.schedulebody');
        console.log({ containerChoosen });
        containerChoosen.scrollIntoView();
    }

    editclick() {
        console.log('EDIT CLICK');
        this.cancelbtndis = true;
        this.fireDataLayerEvent('button', '', 'edit request','','viewschedule__c','/library/viewschedule',this.catalogName,this.productName);
        this.sectiondisplay = true;
        console.log('this.meetingId-->', this.meetingId);
        if (this.meetingId) {
            this.meetingUpdate = true;
            getMeetingRequest({ mId: this.meetingId })
                .then(result => {
                    this.catalogdata = result;
                    console.log('<-----------------::::getMeetingRequest::::----------------->');
                    console.log({ result });
                    console.log('JSON on load' + JSON.stringify(result.data));
                    try {
                        if (result) {
                            console.log({ result });
                            if (result.data.MSD_CORE_Meeting_preference__c) {
                                this.meetingPreference = result.data.MSD_CORE_Meeting_preference__c;
                            }
                            if (result.data.MSD_CORE_Resource__c) {
                                this.catalogName = result.data.MSD_CORE_Resource__r.Name;
                                this.catalofDescription = result.data.MSD_CORE_Resource__r.MSD_CORE_Description__c;
                                this.shortDescription = (result.MSD_CORE_Description__c != null && result.MSD_CORE_Description__c != '') ? result.MSD_CORE_Description__c.length > higherlimit ? this.doSubstring(result.MSD_CORE_Description__c, 0, higherlimit) : result.MSD_CORE_Description__c : '';
                                this.isReadMore = (result.MSD_CORE_Description__c != null && result.MSD_CORE_Description__c != '') ? (result.MSD_CORE_Show_Read_More__c === true && result.MSD_CORE_Description__c.length > higherlimit) ? true : false : false;
                            }

                            if (result.data.Meeting_Times__r) {
                                console.log('<-----------------::::Meeting Time::::----------------->');
                                this.mTimes = result.data.Meeting_Times__r;
                                console.log('--->this.mTimes=-->', this.mTimes);
                                console.log('Length-->', result.data.Meeting_Times__r.length);
                                this.templist = [];
                                this.count =-1
                                for (let i = 0; i < (result.data.Meeting_Times__r.length); i++) {
                                    console.log('::::log FOR::::');
                                    console.log({ i });

                                    // let meetingDay = result.data.Meeting_Times__r[i].MSD_CORE_Meeting_Date__c + ' ' + this.getTimeFormat(result.data.Meeting_Times__r[i].MSD_CORE_Time_Slot__c);
                                    let meetingDay = result.data.Meeting_Times__r[i].MSD_CORE_Meeting_Date__c;
                                    console.log(' meetingDay - ' + meetingDay);
                                    // let dt = new Date(meetingDay);

                                    // Start of Resolve Date ISSUE
                                    let dt = new Date(result.data.Meeting_Times__r[i].MSD_CORE_Meeting_Date__c);
                                    dt = dt.toISOString().split('T')[0];
                                    let _timeSheduled = result.data.Meeting_Times__r[i].MSD_CORE_TimeSlot__c;
                                    let calDate = months[dt.split('-')[1]-1] + ' ' + dt.split('-')[2] + ', ' + dt.split('-')[0];
                                    // End of Resolve Date ISSUE

                                    console.log('calDate ' + calDate);
                                    console.log('_timeSheduled ' + _timeSheduled);
        
                                    this.templist.push({ id: 'inputbox' + i, value: i, calval: calDate,drpid:'dropdown'+ i,caltime:_timeSheduled});

                                    console.log('templist==>', this.templist);
                                    this.count += 1;
                                }

                                for (let i = 0; i < (result.data.Meeting_Times__r.length); i++) {
                                    console.log('::For 2::');
                                    let meetingReq = {
                                        Id: i,
                                        mId: this.mTimes[i].Id,
                                    }
                                    console.log({ meetingReq });
                                }
                            }

                            if (result.data.MSD_CORE_attendee__c) {
                                console.log(':::Attendee;::');
                                console.log('this.attendeeList--->', this.attendeeList);
                                this.attendeeList = result.data.MSD_CORE_attendee__c.split(',');
                                let attendees = result.data.MSD_CORE_attendee__c.split(',');
                                for (let i = 0; i < (attendees.length - 1); i++) {
                                    console.log({ i });
                                    console.log('::::FOR::::');
                                    this.addattlst.push(i);
                                }
                                console.log('addattlst====>', this.addattlst);
                                console.log('===>this.attendeeList--->', this.attendeeList);

                            } else {
                                console.log('::::Attendee Not Availabel::::');
                                this.addattlst.push('0');
                                this.attendeeList.push('');
                            }
                        }

                        console.log('templis=---=>', this.templist);
                    } catch (error) {
                        console.log('REsult ERROR');
                        console.log({ error });
                    }
                }).catch(error => {
                    console.log('<-----------------::::getMeetingRequest ERROR::::----------------->');
                    console.log({ error });
                    console.log('Inside Error' + error);
                });
            console.log('--->templis=---=>', this.templist);
        }
        setTimeout(() => {
            let containerChoosen = this.template.querySelector('.appointmenttime');
            console.log({ containerChoosen });
            containerChoosen.scrollIntoView();
            this.populateAppointments();
        }, 1200);
    }

    formatAMPM(date) {
        var hours = date.getHours();
        var minutes = date.getMinutes();
        var ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        hours = hours < 10 ? '0'+hours : hours;
        minutes = minutes < 10 ? '0'+minutes : minutes;
        var strTime = hours + ':' + minutes +  ampm;
        return strTime;
    }
      
    getTimeFormat(time){
        if(time.indexOf('AM')>-1){
            return time.replace('AM',' AM');
        }else if(time.indexOf('PM')>-1){
            return time.replace('PM',' PM');
        }else{
            return time;
        }
    }
    cancelclick() {
        this.sectiondisplay = false;
        this.fireDataLayerEvent('button', 'step_4_edit', 'cancel request','','viewschedule__c','/library/viewschedule',this.catalogName,this.productName);        
        var model = this.template.querySelector('c-mfr_cancelrequest');

        console.log({ model });
        model.openModel();
    }

    navigatepage(event) {
        console.log({ event });
        var getnameval = event.currentTarget.dataset.name;
        this.load();

        if (getnameval == 'Dashboard') {
            window.location.replace(this.navigatedashboard);
        }
        console.log('Navigate');
        console.log({ event });
        var getnameval = event.currentTarget.dataset.name;
        console.log("Get name" + getnameval);
        console.log("Get name1" + this.navigateproductname);
        console.log("Get name2" + this.navigateproduct);

        if (getnameval == 'ProductList') {
            this.fireDataClickEvent('button', '', "browse catalog",'','viewschedule__c','/library/viewschedule');
            this[NavigationMixin.Navigate]({
                //type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                    name: this.navigateproductname,
                    url: this.navigateproduct
                },
            });
        }
    }

    // Called on load
    onloadcall() {
        this.requestobj = {};
        this.requestobj.recordId = '';
        this.requestobj.attendee = '';
        this.requestobj.meetingPreference = '';
    }

    handlehcp(){
        this.fireDataClickEvent('link', '', 'HCP site','','viewschedule__c','/library/viewschedule');        
    }

    handlepipdf(){
        this.fireDataClickEvent('button', '', 'pi.pdf','','viewschedule__c','/library/viewschedule');        
    }
    
    handlemgpdf(){
        this.fireDataClickEvent('button', '', 'mg.pdf','','viewschedule__c','/library/viewschedule');        
    }


    // Bookmark Remove
    handlerBookMarkRemove(event) {

        console.log('Book Mark Remove');
        this.fireDataLayerEvent('bookmark', '', 'remove resource','','viewschedule__c','/library/viewschedule',this.catalogName,this.productName);
        console.log({ event });
        const selectedRemovalId = event.currentTarget.dataset.id;
        console.log({ selectedRemovalId });
        removeCatalogs({ recId: selectedRemovalId, userId: USER_ID })
            .then(result => {

                console.log('Book Mark Remove');
                console.log({ result });
                this.library = null;
            })
            .catch(error => {
                console.log({ error });
            });
    }

    // For Book Mark
    handlerBookMark(event) {
        console.log('Handle Book Mark');
        this.fireDataLayerEvent('bookmark', '', 'save resource','','viewschedule__c','/library/viewschedule',this.catalogName,this.productName);
        console.log({ event });
        const selectedRecordId = event.currentTarget.dataset.id;
        this.catalogId1 = selectedRecordId;
        console.log('this.catalogId-->', this.catalogId1);
        this.insertCatlogAction(event.currentTarget.dataset.id, event);
    }

    // Insert Catloag
    insertCatlogAction(selectedRecordId, event) {
        console.log('Insert Catalog');
        this.catlog = selectedRecordId;
        //  this.active = true;
        const fields = {};
        fields[CATALOG_FIELD.fieldApiName] = this.catlog;
        fields[ACTIVE.fieldApiName] = true;
        fields[PAYOR_FIELD.fieldApiName] = USER_ID;
        fields[PAYOR_FIELD.fieldApiName] = USER_ID;
        fields[PRODUCTPAYOR_FIELD.fieldApiName] = this.productid;
        console.log('this.productid----->' + this.productid);
        console.log('libObject.objectApiName-->', libObject.objectApiName);

        const recordInput = { apiName: libObject.objectApiName, fields };
        console.log({ recordInput });
        console.log('Create Record');
        createRecord(recordInput)
            .then(libraryobj => {
                console.log('REsult');
                console.log('libraryobj-->', libraryobj);
                console.log({ libraryobj });
                this.library = 'added';
          
            })
            .catch(error => {
                console.log('Error');
                console.log({ error });
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            })
            .finally(() => {
                console.log('Finally');
            });
    }

    viewRequest(event) {
        var msg = event.target.dataset.name;        
        this.fireDataLayerEvent('button', '', msg,'modal','viewschedule__c','/library/viewschedule',this.catalogName,this.productName);
        this.load();
        location.reload();
    }

    @wire(getPrimaryExecutive, { userId: USER_ID })
    wiredPrimaryExecutive({ error, data }) {
        console.log('-->wiredPrimaryExecutive<--');
        console.log({ data });
        if (data) {
            this.primaryExecutive = data;
            console.log('Primary Executive' + JSON.stringify(data));
            console.log('Primary executive Name = ' + this.primaryExecutive.Name);
        }
        if (error) {
            console.log('Error' + JSON.stringify(error));
        }
    }

    handleselecteddate(event) {
        console.log('Selected Date-=>', event.detail.selectedDate);
        console.log('Source Control-=>', event.detail.sourceControl);
        let textBoxID = '[data-id="' + event.detail.sourceControl + '"]';
        let textObj = this.template.querySelector(textBoxID);
            
        if (this.isDateAllowed(event.detail.selectedDate)) {
            textObj.value = event.detail.selectedDate;
            this.setCalendarDateToTempList(event.detail.sourceControl, event.detail.selectedDate);
        } else {
            this.template.querySelector('c-custom-toast').showToast('error', 'Date must be in future');
        }
    }
    isDateAllowed(selectedDate) {
        let today = new Date();
        let date = new Date(selectedDate);
        if (date.getDate() === today.getDate() && date.getFullYear() === today.getFullYear() && date.getMonth() === today.getMonth()) {
            return false;
        } else {
            return true;
        }
    }
    setCalendarDateToTempList(sourceControl, selectedDate) {
        let _tempList = [];
        this.templist.forEach(currentItem => {
            if (currentItem.id != sourceControl) {
                _tempList.push(currentItem);
            } else {
                _tempList.push({ id: currentItem.id, value: currentItem.value, calval: selectedDate,drpid:currentItem.drpid,caltime:currentItem.caltime });
              
            }
        });
        this.templist = [];
        this.templist = _tempList;
    }
    getCalDateFromTempList(textBoxID){
        let _calDate = '';
        this.templist.forEach(currentItem => {
            if(currentItem.id==textBoxID){
                _calDate =currentItem.calval;
            }
        });
        return _calDate
    }
    showCalendar(event) {
       console.log('#### showCalendar clicked');
        if (event.currentTarget.dataset.id.indexOf('inputbox') > -1) {
            this.sourceTextBox = event.currentTarget.dataset.id;
        } else {
            this.sourceTextBox = 'inputbox' + event.currentTarget.dataset.id;
        }

        console.log('#### this.sourceTextBox-->', this.sourceTextBox);
        this.isShow = this.isShow ? false : true;

        // let objCalenderTextBox = this.template.querySelector('[data-id="' + this.sourceTextBox + '"]');
        let caldate = '';
        /*console.log('#### this.objCalenderTextBox value-->', objCalenderTextBox.value);
        if (objCalenderTextBox.value != '' && objCalenderTextBox.value != null && objCalenderTextBox.value != undefined && objCalenderTextBox.value.length > 0) {
            caldate = new Date(objCalenderTextBox.value);
        } else {
             let _caldate= this.getCalDateFromTempList(this.sourceTextBox);
             if(_caldate!='' ){
                caldate = new Date(_caldate);
             }else{
                caldate = new Date();
             }
        }*/

        this.templist.forEach(currentItem => {
            if(currentItem.id == this.sourceTextBox){
                if (currentItem.calval != '' && currentItem.calval != null && currentItem.calval != undefined && currentItem.calval.length > 0) {
                    caldate = new Date(currentItem.calval);
                } else {
                    caldate = new Date();
                }
            }
        });

        console.log({ caldate });
        let objparameter = { isShow: this.isShow, sourceTextBox: this.sourceTextBox, calday: caldate.getDate(), calmonth: caldate.getMonth(), calyear: caldate.getFullYear(), apicss: this.sourceTextBox.slice(-1), pagename: 'schedule' };
        console.log({ objparameter });
        console.log('Show Calendar');
        this.template.querySelector('c-lightning-calendar').passcalenderparameter(objparameter);
        event.stopPropagation();
        this.fireDataLayerEvent('date/time', 'step_1_edit','date','form','viewschedule__c','/library/viewschedule',this.catalogName,this.productName); //RT GA bug
        return false;
    }

    getformattedDate(_Date) {

        let dt = new Date(_Date);
        let month = dt.getMonth() + 1;
        return dt.getFullYear() + '-' + month + '-' + dt.getDate();
    }
    ignoreCalendarClose(event) {
        console.log("Click Outside of Calendar")
        event.stopPropagation();
        return false;
    }
    disconnectedCallback() {
        document.removeEventListener('click', this._handler);
    }
    closeCalendar() {
        console.log('closeCalendar');
        let passParameterObj = { isShow: false }
        if(this.template.querySelector('c-lightning-calendar')){
            this.template.querySelector('c-lightning-calendar').doCloseCalendar(passParameterObj);
        }
    }
    // For Read More Functionality
    doSubstring(description, lowerlimit, higherlimit) {
        if (description) {
            let _description = description.substring(lowerlimit, higherlimit);
            return _description.trim(); // Trimming the result to remove any trailing whitespace
        }
        return '';
    }

    handleReadMore(event) {
        this.isReadMore = false;
    }

    fireDataLayerEvent(category, action, label,module,linkedtext,linkedurl,resourcename, prodname) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventbrandcontent', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: 'product',
                page_purpose:'appointment',
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
                content_name:resourcename,
                page_localproductname:prodname,
                sfmc_id:USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'viewschedule',
            },
            bubbles: true,
            composed: true
        }));
    }

    fireDataClickEvent(category, action, label,module,linkedtext, linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {
          
           detail: {               
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: 'product',
                page_purpose:'appointment',
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
                content_name:'',
                page_localproductname:this.productName,
                sfmc_id:USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'viewschedule',

           },
           bubbles: true,
           composed: true
        }));
    }

   //Google Analytics Event
    fireOnLoadEvent() {
        console.log('EVENT TRIGGERED');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
        detail: {
            data_design_category: '',
            data_design_action: '',
            data_design_label: '',
            data_design_module:'',
            page_type: 'product',
            page_purpose:'appointment',
            page_audience: 'payor',
            page_marketname: 'united_states',
            page_region: 'us',
            page_contentclassification: 'non-commercial',
            link_text:'viewschedule__c',
            link_url:'/library/viewschedule',
            content_count:'',
            content_saved:'',
            content_appointments:'',
            content_requests:'',
            content_name:this.catalogName,
            page_localproductname:this.productName,                
            sfmc_id:USER_ID,
            sfmc_audience: this.contactrole,
            page_url: location.href,
            page_title: 'viewschedule',              
        },
        bubbles: true,
        composed: true
        }));
    }
    handleTimeOption(event){
        let toBeSelectedID = event.currentTarget.dataset.id
        let selectedValue = this.template.querySelector('[data-id="' + toBeSelectedID + '"]').value;
        let _tempList = [];
        this.templist.forEach(currentItem => {
            if (currentItem.drpid != toBeSelectedID) {
                _tempList.push(currentItem);
            }else{
                _tempList.push({ id: currentItem.id, value: currentItem.value, calval: currentItem.calval,drpid:currentItem.drpid,caltime:selectedValue });
            }
        });
        console.log('_tobeDeletedID ' + toBeSelectedID)
        this.templist = [];
        this.templist = JSON.parse(JSON.stringify(_tempList));
        console.log('this.templist toBeSelectedID' + JSON.stringify(this.templist));
    }
    Radioclick(event){
        console.log('Ravi teja radio click');
        console.log(event);
        console.log('value--->',event.target.value);
        if(event.target.value == 'Virtual meeting'){
            this.fireDataLayerEvent("radio", "step_2_edit", "Meeting preference", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
            this.fireDataLayerEvent('radio selection', 'step_2_edit', 'In-Person meeting','form','viewschedule__c','/library/viewschedule',this.catalogName,this.productName); //RT GA bug

        }
        else{
            this.fireDataLayerEvent("radio", "step_2_edit", "Meeting preference", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
            this.fireDataLayerEvent('radio selection', 'step_2_edit', 'Virtual meeting','form','viewschedule__c','/library/viewschedule',this.catalogName,this.productName); //RT GA bug
        }
    }
    handleAddAttendees() {
        this.fireDataLayerEvent("label", "step_3_edit", "Additional attendee email address (optional)", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
    }
    handleTimeOptionClick(event){
        console.log('handleTimeOptionClick');
        // RM --- 24 Feb 2023 --- Bug_Web_043  
        this.dateDuplicate = false;
        let passParameterObj = { isShow: false }
        this.template.querySelector('c-lightning-calendar').doCloseCalendar(passParameterObj);
        this.fireDataLayerEvent('date/time', 'step_1_edit','Time','form','viewschedule__c','/library/viewschedule',this.catalogName,this.productName); //RT GA bug
    }

    handleLinkClick(event) {
        if(event.currentTarget.dataset.prodname == 'pi.pdf' ) {
            this.fireDataLayerEvent("link", '', event.currentTarget.dataset.prodname, '', event.currentTarget.dataset.prodlabel, event.currentTarget.dataset.prodpath, '', event.currentTarget.dataset.value);// RT GA bug
        }else {
            this.fireDataLayerEvent("link", '', event.currentTarget.dataset.prodlabel, '', event.currentTarget.dataset.prodlabel, event.currentTarget.dataset.prodpath, '', event.currentTarget.dataset.value);// RT GA bug
        }
    }
}