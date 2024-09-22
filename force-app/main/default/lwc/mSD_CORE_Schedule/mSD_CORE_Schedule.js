import { LightningElement, track, wire, api } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { CurrentPageReference } from 'lightning/navigation';
import createMeetRequest from '@salesforce/apex/MSD_CORE_ProductList.createMeetingRequestMHEE';
import getmeetingreqdetails from "@salesforce/apex/mSD_CORE_RequestDetail_Controller.getmeetingreqdetails";
import deleteMeetingTimes from '@salesforce/apex/MSD_CORE_ProductList.deleteMeetingTimes';//By Tausif for Ticket 1015
import getstudyDetail from '@salesforce/apex/MSD_CORE_ProductList.getstudyDetail';
import banner from '@salesforce/resourceUrl/PurpleBanner';
import USER_ID from "@salesforce/user/Id";
import MSD_CORE_LeftArrow from '@salesforce/resourceUrl/MSD_CORE_LeftArrow';
import MSD_CORE_Plus from '@salesforce/resourceUrl/MSD_CORE_Plus';
import crossmark from '@salesforce/resourceUrl/cross';
import DateTimeJS from '@salesforce/resourceUrl/DateTimeJS';
import radiocss from '@salesforce/resourceUrl/radiocss';
import arrow from '@salesforce/resourceUrl/rightarrow2';
import { NavigationMixin } from 'lightning/navigation';
import getPrimaryExecutive from '@salesforce/apex/MSD_CORE_ProductList.getPrimaryExecutive';
import getUserDetails from '@salesforce/apex/MSD_CORE_ProductList.getUserDetails';
import uId from '@salesforce/user/Id';
import createMeetingTimes from '@salesforce/apex/MSD_CORE_ProductList.createMeetingTimes';
import getAEdetail from '@salesforce/apex/MSD_CORE_ProductList.getAEdetail';
import getUserInfo from '@salesforce/apex/MSD_CORE_ProductList.getUserInfo';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import MEETINGREQUEST from '@salesforce/schema/Meeting_Request_vod__c';
import callogo from '@salesforce/resourceUrl/calb';
import callogonew from '@salesforce/resourceUrl/calnewicon';
import MSD_CORE_ScheduleCSS from '@salesforce/resourceUrl/mSD_CORE_Schedule';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import FORM_FACTOR from '@salesforce/client/formFactor';//Rusheel-1017

// import lightningcss from '@salesforce/resourceUrl/lightningcss';
// import bootstrap from '@salesforce/resourceUrl/BootStrap';
const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];//By Tausif 1015
export default class MSD_CORE_Schedule extends NavigationMixin(LightningElement) {
    calicon = callogo;
    calnewicon = callogonew;
    bannerimg = banner;
    leftarrow = MSD_CORE_LeftArrow;
    plusicon = MSD_CORE_Plus;
    @track oncology = false;
    @track nononcology = false;
    @track urlStateParameters;
    @track typeval;
    @track diseaseval;
    @track prevPageval;
    @track templist = [];
    @track count = 0;
    @track meetingRequestNumber = '';
    @track meetingRequests = [];
    primaryExecutive = [];
    @track meetingRequestId;
    dateDuplicate = false;
    @track hideRemoveDate = true;
    todaysDate;
    @track showLoader = false;
    @track showResponse = false;
    @track showeditpopup= false;
    @track contactrole = '';
    cross = crossmark;
    sidearrow = arrow;
    userData = [];
    options = '';
    userId = USER_ID;
    //Requestvalue='';// Rusheel-1017-start By Tausif commented code & used in wiredgetschedulefilter with variable:ScheduleFilterLabel
    @track compound = '';
    compoundwarning;

    medicaltherapeutic;
    ipppresentation;

    @track siteAPINames;
    @track siteNames;

    @track oncoloae;
    @track nononcoloae;

    @track MRrecordtype;

    @track ScheduleFilters;

    @track recId;

    _handler;
    isEditable = false;//By Tausif For Ticket:1016
    containerCSS='container slds-p-top_large slds-p-bottom_xx-large';//By Tausif For Ticket:1016
    submitBttonLabel='Submit request';//By Tausif for Ticket 1016
    meetingPreference;//By Tausif for Ticket 1015
    ScheduleFilterLabel;//By Tausif for Ticket 1015
    ScheduleFilterRequestLabel;//By Tausif for Ticket 1015
    @track diseaesCollection;//By Tausif For Ticket:1016
    setCustomStaticCSS(){
        Promise.all([
            loadStyle(this, MSD_CORE_ScheduleCSS),
        ]).then(() => {
            console.log('Files loaded');
        });
    }

    @wire(getPrimaryExecutive, { 'userId': USER_ID })
    wiredPrimaryExecutive({ error, data }) {
        if (data) {
            console.log({data});
            this.primaryExecutive = data;
            console.log('Primary Executive' + JSON.stringify(data));
        }
        if (error) {
            console.log('Error' + JSON.stringify(error));
        }
    }

    // Ravi Teja + Tausif
    @wire(getmeetingreqdetails, { 'requestid': '$recId' })
    wiredgetmeetingreqdetails({ error, data }) {
        if (data) {
            console.log('getmeetingreqdetails-->',data);
            if(FORM_FACTOR === 'Small'){
                this.ScheduleFilterLabel =data.MHEE_Name__c  +':...';
            }else{
                this.ScheduleFilterLabel =data.MHEE_Name__c +': '+ this.displayDiseaseSchedule(data.ScheduleFilter__c);//By Tausif replace Variable from testing to ScheduleFilters
            }
            this.ScheduleFilterRequestLabel = data.MHEE_Name__c +': '+ this.displayDiseaseSchedule(data.ScheduleFilter__c);//By Tausif replace Variable from testing to ScheduleFilters
            this.ScheduleFilters = this.displayDiseaseSchedule(data.ScheduleFilter__c);
            //this.diseaesCollection = data[0].ScheduleFilter__c.split(',');
            this.diseaesCollection = data.ScheduleFilter__c.split(',');
            this.meetingPreference=data.MSD_CORE_Meeting_preference__c;
            this.displayCalendarDate(data);
        }
        if (error) {
            console.log('Error in getmeetingreqdetails--->' ,error);
        }
    }

    // GET AE Detail
    @wire(getAEdetail, { 'userId': USER_ID })
    wiredgetAEdetail({ error, data }) {
        if (data) {
            console.log({data});
            for(var key in data){
                if(data[key].type == 'Oncology'){
                    this.oncoloae = data[key].usridval;
                    console.log('this.aeuserdata--->Onco',this.oncoloae);
                }else {
                    this.nononcoloae = data[key].usridval;
                    console.log('this.aeuserdata--->NonOnco',this.nononcoloae);
                }
            }
        }
        if (error) {
            console.log({error});
        }
    } 

    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({error, data}) {
        console.log({data});
        console.log({error});
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
        }
        if (error) {
            console.log({error});
        } 
    }

    // Get Record Type Value
    @wire(getObjectInfo, { objectApiName: MEETINGREQUEST })
    Function({error,data}){
       if(data){
        console.log('*****MEETING REQUEST RECORD TYPE****');
        console.log({data});
        var RecordType = data.fields.RecordTypeId.value;
        console.log({RecordType});

         const rtis = data.recordTypeInfos;
         const rtInfo= Object.keys(rtis).find(rti => rtis[rti].name === 'MHEE Meeting Request');
         console.log({rtInfo});
         this.MRrecordtype = rtInfo;
         console.log('this.MRrecordtype-->',this.MRrecordtype);

       }else if(error){
        console.log({error});
        }
     };

    @wire(getUserDetails, { 'userId': uId })
    wiredUserDetails({ error, data }) {
        if (data) {
            this.userData = data;
            console.log('Primary Executive' + JSON.stringify(data));
        }
        if (error) {
            console.log('Error' + JSON.stringify(error));
        }
    }

    @wire(getUserInfo, { userId: USER_ID })
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

    get options() {
        return [
            { label: 'New', value: 'new' },
            { label: 'In Progress', value: 'inProgress' },
            { label: 'Finished', value: 'finished' },
        ];
    }

    get meetingoption() {
        if(this.isEditable != undefined && this.isEditable){//By Tausif for Ticket: 1015
            return [
                { label: 'Virtual meeting', value: 'Virtual' },
                { label: 'In-person meeting', value: 'In-Person' },
            ];
        }else{
        return [
            { label: 'In-Person', value: 'In-Person' },
            { label: 'Virtual', value: 'Virtual' },
        ];
    }
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

    handleDate(event) {
        var a = event.target.value;
        console.log({a});

        var b = event.target.id;
        //Added this condition for ios popup error **Start**
        if(!event.target.value) {
            return;
        }
        //**End**
        this.fireDataLayerEvent('date/time', 'step_1_edit', 'Date',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added


        var d = new Date();
        console.log({d});
        var dt = d.getTime();
        console.log(JSON.stringify(event.target.id));
        console.log('Today Date' + dt);
        let selectedDate = Date.parse(event.target.value);
        //let selectedDate = new Date(event.target.value + 'T' + d.toISOString().split('T')[1]);
        console.log('Selected Date' + selectedDate);

        if (selectedDate < dt) {
            let dates = this.template.querySelectorAll('.Date');
            let times = this.template.querySelectorAll('.time_cls.Time');
            dates.forEach(e => {
                if (e.id == event.target.id) {
                    e.value = '';
                    this.template.querySelector('c-custom-toast').showToast('error', 'Date must be in future');
                }
            });

            times.forEach(e => {
                if (e.id == event.target.id) {
                    e.value = '';
                }
            });
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(CurrentPageReference) {
        if (CurrentPageReference) {
            this.urlStateParameters = CurrentPageReference.state;
            this.recId = this.urlStateParameters.recordId;
            console.log('record id >>>>>>>>', this.recId);
            this.typeval = this.urlStateParameters.type;
            this.diseaseval = this.urlStateParameters.disease;
            console.log('this.diseaseval-->',this.diseaseval);
            this.phaseType = this.urlStateParameters.ptype;
            this.isEditable = (this.urlStateParameters.action != undefined && this.urlStateParameters.action=='edit')? true: false;
            this.prevPageval = this.urlStateParameters.prevPage;
            this.setContainerCSS();//By Tausif 1016
        }
    }
 
    @wire(getstudyDetail, { prodId: '$recId' })
    wiredgetstudyDetail(value) {
        console.log('getstudyDetail-->');
        console.log({ value });
        const { data, error } = value;
        // console.log(data.length);
        console.log(':::getstudyDetail DATA:::');
        console.log({ data });
        if (data) {
            this.compound = data[0]?.MSD_CORE_Compound__c;
            this.compoundwarning = data[0]?.MSD_CORE_Compound_Warning__c;
            this.medicaltherapeutic = data[0]?.Medical_Therapeutic_Areas__r[0]?.Id;
            this.ipppresentation = data[0]?.MSD_CORE_Related_Presentation__c;

            console.log('data>>',data[0]?.MSD_CORE_Compound__c);
            console.log(data[0]?.MSD_CORE_Compound_Warning__c);
            console.log('hello>>'+this.compound);
            console.log(this.compoundwarning);
        } else if (error) {
            console.log({ error });
        }
    }

    renderedCallback() {
        Promise.all([        
            loadScript(this, DateTimeJS),
            loadStyle(this, radiocss),
        ]).then(() => {
            console.log('Files loaded');
        });

        if (this.templist.length === 1 && this.templist.length > 0) {
            this.hideRemoveDate = true;
        } else {
            this.hideRemoveDate = false;
        }

        // if(this.compound && this.contactrole){
        //     this.fireOnLoadEvent();
        // }
    }

    connectedCallback() {
        // Rusheel-1017-start
       /* if(FORM_FACTOR === 'Small'){By Tausif commented code & used in wiredgetschedulefilter with variable:ScheduleFilterLabel
            this.Requestvalue = '#0000089:...';
        }else{
            this.Requestvalue = '#0000089:Cardiovascular disease MK-2060 (+1 more)';
        } */
        // Rusheel-1017-end
        //Set default date
        this.setCustomStaticCSS();
        console.log('USER_ID-->',USER_ID);
        var today = new Date();
        this.todaysDate = today.toISOString().substring(0, 16);
        console.log('this.todayDateTime>>>' + this.todaysDate);
        
        setTimeout(() => {
            let scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions);

            if (!this.isEditable) {
                this.fireOnLoadEvent(this.diseaseval);
            } else {
                this.fireOnLoadEvent(this.ScheduleFilters); 
            }
            //const topDiv = this.template.querySelector('.bannercls');
            //topDiv.scrollIntoView();
        }, 2000);
        if (this.typeval == 'Oncology') {
            this.oncology = true;
        } else {
            this.nononcology = true;
        }
        //this.templist.push(this.count);
        if(!this.isEditable){//By Tausif -1016
            
            this.templist.push({ id: 'inputbox' + this.count, value: this.count, calval: '',drpid:'dropdown'+ this.count,caltime:'' });
        }
        let elements = this.template.querySelectorAll('.datecls');
        console.log({elements});
        document.addEventListener('click', this._handler = this.closeCalendar.bind(this));
        sessionStorage.setItem("SFMC_ID",USER_ID );
        this.contactrole = sessionStorage.getItem("SFMC_Audience");
    }

    handleChange(event) {
        var selectedval = event.target.value;
        console.log({ selectedval });
    }

    handleTime() {
        try {
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
                if (dates[i].value == null || dates[i].value == '') {
                    console.log('NuLL');
                    if (times[i].value == null || times[i].value == '') {
                        times[i].value = 'No preference';
                    }
                    this.template.querySelector('c-custom-toast').showToast('error', 'Date cannot be empty');
                    //this.showLoader = false;
                    validdate = false;
                    return validdate;
                } else {
                    console.log('ELSE');
                    if (dates[i] && times[i]) {
                        let dValues = new Date(dates[i].value);
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

                        let dt = new Date(dValues.getMonth(), dValues.getDate(), dValues.getFullYear(), tValues[0], tValues[1], 0);
                        datelst.push(dt.toString());
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
            // return validdate;
        } catch (error) {
            console.log({error});
        }
        return validdate;
    }
    //createMeetRequest({ request })
    handleSubmit(event) {
        console.log('Handle Submit');
        if (this.isEditable) {
            this.fireDataLayerEvent('button', 'step_3_edit', 'submit request',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added   
        } else {
            this.fireDataLayerEvent('button', 'step_3', 'submit request',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added   
        }
        // this.showLoader = true;
        //this.showResponse = true;
        //this.showeditpopup = true; //RT
       /* if(this.isEditable){
            // console.log('this.options-->',this.options);
            // console.log('this.options-->',this.diseaesCollection);
            // console.log('this.options-->',this.diseaesCollection.length);
            // let ln = this.diseaesCollection.length - 1;
            // console.log('LNNN-->',ln);
            // this.testing = this.diseaesCollection[0] + ' (+'+ ln +' more)';
            // console.log('Testing--->',this.testing);
            this.showeditpopup = true;
        }*/
        console.log('this.options' + this.options);
        if (!this.isEditable && this.options.length==0) {//Tausif for Ticket:1015
            console.log('No filter value selected');
            //this.showLoader = false;
            this.template.querySelector('c-custom-toast').showToast('error', 'Please select the filter');
        }
        else {
            let dates = this.template.querySelectorAll('.Date');
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

            console.log('111-->' + dates.length);
            console.log('111-->' + dates[0].value);
            var valid = this.handleTime();
            console.log({valid});
            if (valid) {
                if (dates.length > 0 && dates[0].value != null && dates[0].value != undefined && dates[0].value != '') {
                    if (!meetingPreferenceValidation) {

                        if (!this.dateDuplicate) {
                            let MeetingRequest = {};
                            if(this.isEditable){ // By Tausif for Ticket 1015
                                MeetingRequest.id = this.recId;
                            }
                            MeetingRequest.MSD_CORE_Source__c = 'MHEE';
                            MeetingRequest.MSD_CORE_Status__c = 'Pending';
                            MeetingRequest.MSD_CORE_Time_zone__c = this.setDefaultime;

                            MeetingRequest.MSD_CORE_Meeting_preference__c = this.template.querySelector('.radiobtncls').value;
                            
                            if (this.ProductpayerID) {
                                MeetingRequest.MSD_CORE_Product_Payor__c = this.ProductpayerID;
                            }
                            if (this.userId) {
                                MeetingRequest.MSD_CORE_Payor__c = this.userId;
                            }
                            if (this.userData[0].AccountId) {
                                MeetingRequest.Account_vod__c = this.userData[0].AccountId;
                            }
                            // if (this.primaryExecutive[0].Id) {
                            if(this.typeval == 'Oncology'){
                                MeetingRequest.Assignee_vod__c = this.oncoloae;
                            }else {
                                MeetingRequest.Assignee_vod__c = this.nononcoloae;
                            }
                            console.log('MeetingRequest.Assignee_vod__c--->',MeetingRequest.Assignee_vod__c);
                            if (this.options) {
                                MeetingRequest.ScheduleFilter__c = this.options;
                            }

                            console.log('this.medicaltherapeutic-->', this.medicaltherapeutic);
                            if (this.medicaltherapeutic) {
                                console.log(':::medicaltherapeutic:::');
                                MeetingRequest.Medical_Therapeutic_Area__c	 = this.medicaltherapeutic;
                            }
                            console.log('this.ipppresentation-->', this.ipppresentation);
                            if (this.ipppresentation) {
                                MeetingRequest.MSD_CORE_IPP_Presentation_Title__c = this.ipppresentation;
                            }

                            // MeetingRequest.recordtypeId = '0127X000000c19MQAQ';
                            MeetingRequest.recordtypeId = this.MRrecordtype;
                            this.meetingRequests.push(MeetingRequest);
                            //this.showResponse = true;
                            console.log('this.meetingRequests==>', this.meetingRequests);
                            this.showLoader = true;
                            createMeetRequest({ request: JSON.stringify(this.meetingRequests) })
                                .then(result => {
                                  /*  if(this.isEditable){
                                        this.deleteMeetingTimes();
                                         dates = this.template.querySelectorAll('.Date');
                                    }*/
                                    deleteMeetingTimes({ requestID: result.data.Id })
                                    .then(res => {
                                        
                                    console.log(':::createMeetRequest:::');
                                    console.log({ result });
                                    console.log('Result' + JSON.stringify(result));
                             
                                    this.meetingRequestNumber = result.message;
                                    this.meetingRequestId = result.data.Id;
                                    //let meetingTime = { MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c };
                                    let meetingTimes = [];
                                    for (let i = 0; i < dates.length; i++) {
                                        if (dates.length > 0) {
                                            // this.dateVal = dates[i].value;
                                            this.dateVal = this.getformattedDate(dates[i].value);
                                        }

                                        let times = this.template.querySelectorAll('.Time');
                                        if (times.length > 0) {
                                            this.timeVal = times[i].value;
                                        }
                                        console.log('Date' + this.dateVal);
                                        console.log('Time' + this.timeVal);
                                        let dValues = this.dateVal.split('-');
                                        //let tValues = this.timeVal.split(':');
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
                                            //    if(tValues==undefined||tValues[0] == 'No preference'){
                                            tValues[0] = '00';
                                            tValues[1] = '00';
                                        } else {
                                            let timestamp = tValues[1].split(' ');
                                            tValues[1] = timestamp[0];
                                        }
                                        let meetingTime = {};
                                        // meetingTime.MSD_CORE_Meeting_Date__c = dates[i].value;
                                        meetingTime.MSD_CORE_Meeting_Date__c = this.getformattedDate(dates[i].value);
                                        meetingTime.MSD_CORE_Meeting_Request__c = result.data.Id;
                                        // meetingTime.MSD_CORE_TimeSlot__c = times[i].value;
                                        if (times[i].value == null || times[i].value == '') {
                                            meetingTime.MSD_CORE_TimeSlot__c = 'No preference';
                                        } else {
                                            meetingTime.MSD_CORE_TimeSlot__c = times[i].value;
                                        }
                                        //meetingTime.MSD_CORE_Time_Slot__c =times[i].value!='No Preference'? times[i].value[0]+':'+times[i].value[1] : '00:00AM';
                                        meetingTime.MSD_CORE_Time_Slot__c = tValues[0] + ':' + tValues[1];
                                        meetingTimes.push(meetingTime);
                                        console.log({ meetingTimes });
                                        console.log('Strinrequest' + JSON.stringify(meetingTimes));
                                    }

                                    createMeetingTimes({ request: JSON.stringify(meetingTimes) })
                                        .then(result => {

                                        })
                                        .catch(e => {
                                            this.showLoader=false;
                                            console.log('Error In Meeting Times==>',{e});
                                        }).finally(() => {
                                            this.showLoader=false;
                                           // this.showResponse = true;
                                            if(this.isEditable){
                                                this.showeditpopup = true;
                                            }else {
                                                this.showResponse = true;
                                            }
                                            console.log('Finally2');
                                        })
                                    })       
                                })
                                .catch(error => {
                                    this.showLoader = false;
                                    console.log('error' + JSON.stringify(error));
                                })
                                .finally(() => {
                                    this.showLoader = false;
                                    console.log('Finally1');
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
           // this.showLoader = false;
        }
        //}
    }
    //this following method is to show the study details and +more. RT
    displayDiseaseSchedule(scheduleFilter) {
        console.log('HELLLOOOOO');
        let _schedule = '';
        let _counter = 0;
        let objschedule = scheduleFilter.split(',');
        console.log({objschedule});
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
    getformattedDate(_Date) {
        let dt = new Date(_Date);
        let month = dt.getMonth() + 1;
        return dt.getFullYear() + '-' + month + '-' + dt.getDate();
    }
    closeResponse(event) {
        this.showResponse = false;
        this.showeditpopup = false; //RT
        this.navigateback();
        this.fireDataLayerEvent('button', '', 'back to screen_X',  'modal', 'ScheduleAppointment__c', '/scheduleappointment'); //RT GA 1122
        
    }

    navigateback(event) {
        console.log('prevPage : '+this.prevPageval);
        /** E2ESE-1021 - redirect to previous page */
        if (this.prevPageval == 'pipeline'){
            this.fireDataLayerEvent('button', '', 'back',  '', this.siteAPINames.Pipeline, this.siteNames.Pipeline); //RT GA 1122
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    name: this.siteAPINames.Pipeline,
                    url: this.siteNames.Pipeline
                },
            });
        }
        if(this.prevPageval == 'studydetail'){
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    name: this.siteAPINames.StudyDetail,
                    url: this.siteNames.StudyDetail+ '?recordId='+ this.recId
                },
            });
        }
    }

    handleNavigate(){
        // this[NavigationMixin.Navigate]({
        //     //type: 'comm__namedPage',
        //     type: 'standard__webPage',
        //     attributes: {
        //         name: this.siteAPINames.Dashboard,
        //         url: this.siteNames.Dashboard
        //     },
        // });
        window.location.href = this.siteNames.Dashboard;
        //window.location.assign(this.siteNames.Dashboard);
        this.fireDataLayerEvent('button', '', 'go to dashboard',  'modal', this.siteAPINames.Dashboard, this.siteNames.Dashboard); //RT GA bug
    }
    // Rusheel-Jira-1030-start
    viewRequest(event){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.siteAPINames.RequestDetail,
                url: this.siteNames.RequestDetail+ '?recordId='+ this.meetingRequestId
            },
        });
        this.fireDataLayerEvent('link', '', 'view Request',  'modal', this.siteAPINames.RequestDetail, this.siteNames.RequestDetail+ '?recordId='+ this.recId); //RT GA bug
    }

    // Rusheel-Jira-1030-end
    viewRequestedit(event){
       /* this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.siteAPINames.RequestDetail,
                url: this.siteNames.RequestDetail+ '?recordId='+ this.recId
            },
        });*/
       location.assign(this.siteNames.RequestDetail+ '?recordId='+ this.recId); //Raviteja
       this.fireDataLayerEvent('link', '', 'view Request',  'modal', this.siteAPINames.RequestDetail, this.siteNames.RequestDetail+ '?recordId='+ this.recId); //RT GA bug
    }
    addnewdate(event) {
        console.log('Add Date');
        if (this.isEditable) {
            this.fireDataLayerEvent('button', 'step_1_edit', 'add date',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        } else{
            this.fireDataLayerEvent('button', 'step_1', 'add date',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        }
        try {
            let dates = this.template.querySelectorAll('.Date');
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
            if (this.templist.length > 2) {
                this.template.querySelector('c-custom-toast').showToast('error', 'Maximum 3 appointment times allowed');
            }
            if (allowDate && this.templist.length <= 2 && (!this.dateDuplicate)) {
                this.count += 1;
                //this.templist.push(this.count);
                this.templist.push({ id: 'inputbox' + this.count, value: this.count, calval: '',drpid:'dropdown'+this.count,caltime:'' });
            }
        }
        catch (error) {
            console.log('error' + JSON.stringify(error));
        }
    }

    removedate(event) {
        if (this.isEditable) {
            this.fireDataLayerEvent('date/time', 'step_1_edit', 'date/time removed',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        } else {
            this.fireDataLayerEvent('date/time', 'step_1', 'date/time removed',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        }
        /*  var indx = event.target.dataset.value;        
        if (this.templist.length > 1) {
            this.templist.splice(indx, 1);
        }*/
        let tobeDeletedID = event.currentTarget.dataset.id
        
        this.removeDatafromTempList(tobeDeletedID);
        this.dateDuplicate = false;
    }

    handleOptions(event) {
        this.options = event.detail;
        console.log('options-->' , this.options);
        // if(this.options.indexOf(',') > -1){
        //     this.fireDataLayerEvent('date/time', 'step_1', this.options,  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        // }
    }

    handleMeetingPref(event){        
        if (this.isEditable) {
            this.fireDataLayerEvent('radio', 'step_2_edit', 'Meeting preference',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
            this.fireDataLayerEvent('radio selection', 'step_2_edit', event.target.value,  'form','ScheduleAppointment__c','/scheduleappointment'); //Event Added
        } else {
            this.fireDataLayerEvent('radio', 'step_2', 'Meeting preference',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
            this.fireDataLayerEvent('radio selection', 'step_2', event.target.value,  'form','ScheduleAppointment__c','/scheduleappointment'); //Event Added
        }
    }

    handleTimeClick(){
        if (this.isEditable) {
            this.fireDataLayerEvent('date/time', 'step_1_edit', 'Meeting Time',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        } else {
            this.fireDataLayerEvent('date/time', 'step_1', 'Meeting Time',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        }
    }

    handleselecteddate(event) {
        console.log('Selected Date-=>', event.detail.selectedDate);
        console.log('Source Control-=>', event.detail.sourceControl);
        let textBoxID = '[data-id="' + event.detail.sourceControl + '"]';
        let textObj = this.template.querySelector(textBoxID);
        let contname = this.compound;
        console.log('contname>>>'+contname);
        if (this.isEditable) {
            this.fireDataLayerEvent('date/time', 'step_1_edit', 'Date',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        } else{
            this.fireDataLayerEvent('date/time', 'step_1', 'Date',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        }
      
        if(this.isDateAllowed(event.detail.selectedDate)){
            textObj.value = event.detail.selectedDate;
            this.setCalendarDateToTempList(event.detail.sourceControl,event.detail.selectedDate);
        }else{
            this.template.querySelector('c-custom-toast').showToast('error', 'Date must be in future');
        }
    }
    isDateAllowed(selectedDate){
        let today = new Date();
        let date =new Date(selectedDate);
        if (date.getDate() === today.getDate() && date.getFullYear() === today.getFullYear() && date.getMonth() === today.getMonth()) {
            return false;
        }else{
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

    showCalendar(event) {
        let top = this.setTopCordinate(event);
         if (event.currentTarget.dataset.id.indexOf('inputbox') > -1) {
             this.sourceTextBox = event.currentTarget.dataset.id;
         } else {
             this.sourceTextBox = 'inputbox' + event.currentTarget.dataset.id;
         }
 
        console.log('this.sourceTextBox-->', this.sourceTextBox);
        this.isShow = this.isShow ? false : true;
 
        console.log('this.templist-->', JSON.stringify(this.templist));
        let caldate = '';
        this.templist.forEach(currentItem => {
            if(currentItem.id == this.sourceTextBox){
                if (currentItem.calval != '' && currentItem.calval != null && currentItem.calval != undefined && currentItem.calval.length > 0) {
                    caldate = new Date(currentItem.calval);
                } else {
                    caldate = new Date();
                }
            }
        });

        //  let objCalenderTextBox = this.template.querySelector('[data-id="' + this.sourceTextBox + '"]');
        //  let caldate = '';
        //  if (objCalenderTextBox.value != '' && objCalenderTextBox.value != null && objCalenderTextBox.value != undefined && objCalenderTextBox.value.length > 0) {
        //      caldate = new Date(objCalenderTextBox.value);
        //  } else {
        //      caldate = new Date();
        //  }
        console.log({ caldate });
        let objparameter = { isShow: this.isShow, sourceTextBox: this.sourceTextBox, calday: caldate.getDate(), calmonth: caldate.getMonth(), calyear: caldate.getFullYear(), apicss: this.sourceTextBox.slice(-1), pagename: 'mhe' };
        console.log({ objparameter });
        console.log('Show Calendar');
        this.template.querySelector('c-lightning-calendar').passcalenderparameter(objparameter);
        event.stopPropagation();         
        return false;
     }
    setTopCordinate(eve){
        let cordinate =0 ;
        return cordinate;
    }

    ignoreCalendarClose(event) {
        console.log("Click Outside of Calendar")
        event.stopPropagation();
        return false;
    }

    handlenavigatedashboard(){
        this.fireDataClickEvent("top_nav_breadcrumb",'','Dashboard','navigation',this.siteAPINames.Dashboard,this.siteNames.Dashboard); //RT GA 1122
    }

    handlenavigatepipeline(){
        this.fireDataClickEvent("top_nav_breadcrumb",'','Pipeline information','navigation',this.siteAPINames.Pipeline,this.siteNames.Pipeline); //RT GA 1122
    }
    handlenavigatephaseType(event){
        let phasetype = event.currentTarget.dataset.name;
        console.log('phasetype>>'+phasetype);
        this.fireDataClickEvent("top_nav_breadcrumb",'',phasetype,'navigation',this.siteAPINames.Pipeline,this.siteNames.Pipeline); //RT GA 1122
    }
    handlenavigatediseaseval(event){
        let disease = event.currentTarget.dataset.name;
        console.log('disease>>'+disease);
        this.fireDataClickEvent("top_nav_breadcrumb",'',disease,'navigation',this.siteAPINames.Pipeline,this.siteNames.Pipeline); //RT GA 1122
    }
    removeDatafromTempList(_tobeDeletedID) {
        let _tempList = [];
        this.templist.forEach(currentItem => {
            if (currentItem.id != _tobeDeletedID) {
                _tempList.push(currentItem);
            }
        });
        console.log('_tobeDeletedID ' + _tobeDeletedID)
        this.templist = [];
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
        this.count = ctr-1;
        this.templist = [];
        this.templist = JSON.parse(JSON.stringify(_itemList));
        console.log('this.templist resetTempList' + JSON.stringify(this.templist));
    }
    closeCalendar() {
        let passParameterObj = { isShow: false }
        this.template.querySelector('c-lightning-calendar').doCloseCalendar(passParameterObj);
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
        if(this.isEditable){
            this.fireDataLayerEvent('date/time', 'step_1_edit', 'Time',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        }else{
            this.fireDataLayerEvent('date/time', 'step_1', 'Time',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //Event Added
        }
        
    }
    handleTimeOptionClick(event){
        console.log('handleTimeOptionClick');
        // RM --- 24 Feb 2023 --- Bug_Web_045 
        this.dateDuplicate = false;
        let passParameterObj = { isShow: false }
            this.template.querySelector('c-lightning-calendar').doCloseCalendar(passParameterObj);
    }

    fireDataClickEvent(category, action, label,module,linkedtext, linkedurl) {
        console.log('event triggered');
        let contentname = '';
        if (!this.isEditable) {
            contentname = this.diseaseval;
            console.log('is non editable');
        } else {
            contentname = this.ScheduleFilters;
            console.log('is non editable');
        }
       this.dispatchEvent(new CustomEvent('fireDataClickEvent', {
          
           detail: {               
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: 'resources',
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
                content_name:contentname,//this.compound,
                page_localproductname:'',                
                sfmc_id:USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'scheduleappointment',
           },
           bubbles: true,
           composed: true
       }));
    }

    fireDataLayerEvent(category, action, label,module,linkedtext, linkedurl) {
        console.log('event triggered');
        let contentname = '';
        if (!this.isEditable) {
            contentname = this.diseaseval;
            console.log('is non editable');
        } else {
            contentname = this.ScheduleFilters;
           console.log('is editable');
        }
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {
           detail: {               
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: 'resources',
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
                content_name:contentname,//this.compound,
                page_localproductname:'',                
                sfmc_id:USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'scheduleappointment',
            },
            bubbles: true,
            composed: true
        }));
    }

    //Google Analytics Event
    fireOnLoadEvent(contentval) {
        console.log('EVENT TRIGGERED');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                    data_design_category: '',
                    data_design_action: '',
                    data_design_label: '',
                    data_design_module:'', 
                    page_type: 'resources',
                    page_purpose:'appointment',
                    page_audience: 'payor',
                    page_marketname: 'united_states',
                    page_region: 'us',
                    page_contentclassification: 'non-commercial',
                    link_text:'ScheduleAppointment__c',
                    link_url:'/scheduleappointment',
                    content_saved:'',
                    content_appointments:'',
                    content_requests:'',
                    content_name:contentval,//this.compound,
                    page_localproductname: '',
                    content_count:'',
                    sfmc_id: USER_ID,
                    sfmc_audience:this.contactrole,
                    page_url: location.href,
                    page_title: 'scheduleappointment',  
            },
            bubbles: true,
            composed: true
        }));
    }
    setContainerCSS(){//By Tausif 1016
        if(this.isEditable){
            this.containerCSS='containerEdit slds-p-top_large slds-p-bottom_xx-large';
            this.setControlLabel()
        }
    }
    setCalendarDates(){//By Tausif 1016
        this.templist =[];
        this.templist.push({ id: 'inputbox0', value:0, calval: 'October 19, 2021',drpid:'dropdown0',caltime:'09:00AM - 10:00AM' });
        this.templist.push({ id: 'inputbox1', value:1, calval: 'October 19, 2021',drpid:'dropdown1',caltime:'09:00AM - 10:00AM' });
    }
    handleCancel(event){//By Tausif 1016
        this.fireDataLayerEvent('button', 'step_3_edit', 'cancel changes',  'form', 'ScheduleAppointment__c', '/scheduleappointment'); //RT GA bug
        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    name: this.siteAPINames.RequestDetail,
                    url: this.siteNames.RequestDetail + '?recordId=' + this.recId
                }
            });
        } catch (error) {
            console.log('Error in handleCancel-->',{error});
        }
    }
    setControlLabel(){//By Tausif 1016
        this.submitBttonLabel='Submit changes';
    }

    displayCalendarDate(meetingRequest){//By Tausif 1016
        if (meetingRequest.Meeting_Times__r) {
            this.templist = [];
            this.count =-1
            for (let i = 0; i < (meetingRequest.Meeting_Times__r.length); i++) {
                let s = new Date(meetingRequest.Meeting_Times__r[i].MSD_CORE_Meeting_Date__c);
                let dt = new Date(s.toISOString().slice(0, -1));
                //let dt = new Date(meetingRequest.Meeting_Times__r[i].MSD_CORE_Meeting_Date__c);
                let _timeSheduled = meetingRequest.Meeting_Times__r[i].MSD_CORE_TimeSlot__c;
                let calDate = months[dt.getMonth()] + ' ' + dt.getDate() + ', ' + dt.getFullYear()  ;
                this.templist.push({ id: 'inputbox' + i, value: i, calval: calDate,drpid:'dropdown'+ i,caltime:_timeSheduled});
                this.count += 1;
            }
        }
    }
    deleteMeetingTimes(){
        deleteMeetingTimes({ requestID: this.recId })
        .then(res => {
            console.log('Meeting Times deleted');
        })
    }
   
}