import { LightningElement, api, wire, track } from 'lwc';;
import { NavigationMixin } from 'lightning/navigation';

import newlogo2 from '@salesforce/resourceUrl/banner';
import newlogo6 from '@salesforce/resourceUrl/ActiveMHEE';
import newlogo7 from '@salesforce/resourceUrl/ArrowNew';
import newlogo9 from '@salesforce/resourceUrl/downarrow';
import uparrow from '@salesforce/resourceUrl/uparrowicon';
import getCatalogPerProdSaved from '@salesforce/apex/MSD_CORE_ProductList.getCatalogPerProdSaved';
import document from '@salesforce/resourceUrl/calender';
import cntuser from '@salesforce/resourceUrl/contact2';
import accounticon from '@salesforce/resourceUrl/account';
import phoneicon from '@salesforce/resourceUrl/phone';
import messageicon from '@salesforce/resourceUrl/MSD_CORE_Message';
import bookicon from '@salesforce/resourceUrl/booknew';
import warrow from '@salesforce/resourceUrl/whitearrow';
import accountmanagement from '@salesforce/label/c.MSD_CORE_AccountManagement';
import accountdesg from '@salesforce/label/c.MSD_CORE_AccountManagementDesg';
import accountphone from '@salesforce/label/c.MSD_CORE_AccountManagementPhone';
import accountmail from '@salesforce/label/c.MSD_CORE_AccountManagementEmail';
import noprofile from '@salesforce/resourceUrl/noprofile';
import newgetproductlist from '@salesforce/apex/MSD_CORE_ProductList.newgetproductlist';
import newgetproductlistActive from '@salesforce/apex/MSD_CORE_ProductList.newgetproductlistActive';
import USER_ID from "@salesforce/user/Id";
import getPrimaryExecutive from '@salesforce/apex/MSD_CORE_ProductList.getPrimaryExecutive';

import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getSiteNameAndAPIName';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import getActiveRequests from '@salesforce/apex/MSD_CORE_RequestController.getActiveRequestsTest';

import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';

export default class mSD_CORE_ActiveRequest extends NavigationMixin(LightningElement) {

    @api recordId;
    exeContacts = [];
    AE = { accountmanagement, accountdesg, accountphone, accountmail };

    noprofile = noprofile;
    logo5 = newlogo2;               //Banner image
    logo7 = newlogo6;               //Active icon
    logo8 = newlogo7;               //Arrow icon
    logo10 = newlogo9;               //Down Arrow icon

    docicon = document;             //Calender icon
    cntuser = cntuser;              //User icon
    accounticon = accounticon;
    phoneicon = phoneicon;          //Phone icon
    messageicon = messageicon;      //Message icon
    bookicon = bookicon;            //Browse icon
    warrow = warrow;                //White arrow icon

    products = [];                       //Products
    savedcon;                       //Saved Contact
    error;
    roleId;                         //Role Id
    userid = USER_ID;               //User id

    uparrowimg = uparrow;
    norecord = false;
    norecordlib = false;
    showPrimaryExecutive = false;
    primaryExecutive = [];
    @track primaryemail = '';
    proddata = [];
    products2 = [];
    showmore = false;
    showmore1 = false;

    @track actprod = [];
    actprod2 = [];
    @track showmoredisp = false;
    @track showmoredisp1 = false;

    nodatate = false;

    @track rqstAppointmentPage;
    @track rqstAppointmentPageApi;
    @track librarypage;
    @track librarypageapi;
    @track myContactspage;
    @track myContactspageapi;
    @track Requestdetailpage;
    @track Requestdetailpageapi;
    @track appointmentpage;
    @track appointmentpageapi;
    @track requestpage;
    @track requestpageapi;

    @track pageName = ''
    @track contactrole = '';

    @track pageapiname;
    @track pageurl;

    @track nodata;


    // For getting all Sites API Name and Url
    @wire(getActiveRequests)
    WiredgetActiveRequests({ error, data }) {
        console.log('Active Request::::95 data', { data });
        console.log('Active Request::::', { error });
        if (data) {
            console.log('line no 103:::::');
            this.recordsToDisplay = this.getRequestMappedValue(data);
            for (let i = 0; i < this.recordsToDisplay.length; i++) {

                if (this.actprod.length < 3) {
                    this.actprod.push(this.recordsToDisplay[i]);
                }
                else if (this.actprod.length >= 3) {
                    this.actprod2.push(this.recordsToDisplay[i]);
                }
            }
            if (this.actprod2.length > 0) {
                this.showmoredisp1 = true;
            }
            else {
                this.showmoredisp1 = false;
            }

            // Added for No Result --- Ravi Modi --- 21 March 2023
            if (this.actprod.length == 0) {
                this.nodata = true;
            } else {
                this.nodata = false;
            }

        }
        if (error) {
            console.log({ error });
        }
    }
    getRequestMappedValue(RequestData) {
        let _requestData = RequestData.map(
            record =>
                Object.assign({
                    "CreatedDate": record.CreatedDate,
                    "Id": record.Id,
                    "MHEE_Name__c": record.MHEE_Name__c,
                    "MSD_CORE_Resource_Type__c": record.MSD_CORE_Resource_Type__c,
                    "MSD_CORE_Source__c": record.MSD_CORE_Source__c,
                    "Name": record.Name,
                    "ScheduleFilter__c": record.ScheduleFilter__c != null ? this.displayDiseaseSchedule(record.ScheduleFilter__c) : ''
                }
                ));
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

    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log({ data });
        console.log({ error });
        if (data) {
            this.pageapiname = data.siteAPINames.Pipeline;
            this.pageurl = data.siteNames.Pipeline;
        }
        if (error) {
            console.log({ error });
        }
    }



    showmoreclk() {
        this.showmore = true;
    }
    showlessclk() {
        this.showmore = false;
    }
    showmoreclk1() {
        console.log('Show more true');
        this.showmore1 = true;
        this.fireDataClickEvent('button','','vertical','show more',this.rqstAppointmentPage , this.rqstAppointmentPageApi,'');//RT-N-1053
    }
    showlessclk1() {
        console.log('showless>>');
        this.showmore1 = false;
        this.fireDataClickEvent('button','','vertical','show less',this.rqstAppointmentPage , this.rqstAppointmentPageApi,'');//RT-N-1053
    }


    connectedCallback() {

        sessionStorage.setItem("SFMC_ID", USER_ID);
        console.log('COnnected Callback');
        // console.log(this.AE.accountmail);

        // this.fireOnLoadEvent();

        this.getsitename();
        // this.pageviewevents();
    }
    getsitename() {

        getSiteNameAndAPIName({ pageName: 'RequestAppointment' })
            .then((result) => {
                console.log('lineno 151 result::::::' + result);
                this.rqstAppointmentPage = result.siteName;
                this.rqstAppointmentPageApi = result.siteAPIName;
                console.log('line no 154;;' + this.rqstAppointmentPageApi);
                console.log('line no 155;;' + this.rqstAppointmentPage);
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });

        getSiteNameAndAPIName({ pageName: 'RequestDetail' })
            .then((result) => {
                console.log('lineno 151 result::::::' + result);
                this.Requestdetailpage = result.siteAPIName;
                this.Requestdetailpageapi = result.siteName;
                console.log('line no 154;;' + this.rqstAppointmentPageApi);
                console.log('line no 155;;' + this.rqstAppointmentPage);
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
    }

    // Method Name:         navigatetopipeline
    // Method Use:          Navigate to Pipeline Page
    // Developer Name:      Ravi Modi
    // Created Date:        21th March 2023
    navigatetopipeline() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.pageapiname,
                url: this.pageurl
            }
        });
        this.fireDataClickEvent('button','','',"browse pipeline information",this.pageapiname , this.pageurl,'');//RT GA 1122
    }


    // Navigate Pages
    navigatepage(event) {

        var getnameval = event.currentTarget.dataset.name;
        console.log({ getnameval });
        console.log('event.currentTarget.dataset-->', event.currentTarget.dataset);
        var contname = event.currentTarget.dataset.contname;
        console.log('contentname>>>>>>'+contname);
        var recId = '';
        var tabname = '';
        if (getnameval == 'Request') {
            recId = event.currentTarget.dataset.id;
            tabname = event.currentTarget.dataset.name;
            // }
            // else if (getnameval == 'Request') {
            this.fireDataClickEvent('button','','vertical','view request',this.Requestdetailpageapi , this.Requestdetailpage + '?recordId=' + recId + '&tab=' + tabname, contname);//RT-N-1053   
            if (this.Requestdetailpageapi != undefined && this.Requestdetailpage != undefined)
                //this.fireDataLayerEvent('button','','library','vertical', this.librarydetailpageapi,this.librarydetailpage);
                this[NavigationMixin.Navigate]({
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
                        name: this.Requestdetailpageapi,
                        url: this.Requestdetailpage + '?recordId=' + recId + '&tab=' + tabname
                    }
                });
        }

        if (getnameval == 'RequestAppointment') {

            this.fireDataClickEvent('button','','vertical','view all requests',this.rqstAppointmentPage , this.rqstAppointmentPageApi,'');//RT-N-1053
            if (this.rqstAppointmentPageApi != undefined && this.rqstAppointmentPage != undefined) {
                this[NavigationMixin.Navigate]({
                    //type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: this.rqstAppointmentPage,
                        url: this.rqstAppointmentPageApi+ '?tab=Pending requests'
                    },
                });

            }
        }

    }
    // google analytics events
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