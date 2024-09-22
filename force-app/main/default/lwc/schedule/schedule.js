import { LightningElement, track, api, wire } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import getCatalogs from '@salesforce/apex/MSD_CORE_ProductList.getCatalogs';
import CATALOG_FIELD from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Catalog__c';
import PAYOR_FIELD from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Payor__c';
import PRODUCTPAYOR_FIELD from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Product_Payor__c';
import ACTIVE from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Active__c';
import libObject from '@salesforce/schema/MSD_CORE_Library__c';
import getCatalogRecord from '@salesforce/apex/MSD_CORE_ProductList.getCatalogRecord';
import getPdfDownloadLink from '@salesforce/apex/MSD_CORE_ProductList.getPdfDownloadLink';
import USER_ID from "@salesforce/user/Id";
import removeCatalogs from '@salesforce/apex/MSD_CORE_ProductList.removeCatalogs';
import newlogo2 from '@salesforce/resourceUrl/like';
import newlogo3 from '@salesforce/resourceUrl/bookmark';
import newlogo4 from '@salesforce/resourceUrl/whitearrow';
import newlogo5 from '@salesforce/resourceUrl/whiteboxarrow';
import newlogo9 from '@salesforce/resourceUrl/bookmarkSelect';
import arrow from '@salesforce/resourceUrl/rightarrow2';
import crossmark from '@salesforce/resourceUrl/cross';
import plus from '@salesforce/resourceUrl/plusicon';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import radiocss from '@salesforce/resourceUrl/radiocss';
import bootstrap from '@salesforce/resourceUrl/BootStrap';
import DateTimeJS from '@salesforce/resourceUrl/DateTimeJS';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import callogo from '@salesforce/resourceUrl/calb';
import uId from '@salesforce/user/Id';
import lightningcss from '@salesforce/resourceUrl/lightningcss';

import createMeetRequest from '@salesforce/apex/MSD_CORE_ProductList.createMeetingRequest';
import createMeetingTimes from '@salesforce/apex/MSD_CORE_ProductList.createMeetingTimes';
import getMeetingRequest from '@salesforce/apex/MSD_CORE_ProductList.getMeetingRequest';
import getUserDetails from '@salesforce/apex/MSD_CORE_ProductList.getUserDetails';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import getPrimaryExecutive from '@salesforce/apex/MSD_CORE_ProductList.getPrimaryExecutive';
import bannerimg from '@salesforce/resourceUrl/darkbanner';
import getUserInfo from '@salesforce/apex/MSD_CORE_ProductList.getUserInfo';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import mfrdomainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
import showproductsGenericNamewithBrand from '@salesforce/label/c.showproductsGenericNamewithBrand'; //Added by Sabari - To Show Generic Name with Brand

import NavigateToProduct from '@salesforce/label/c.NavigateToProduct';      //Custom label for navigation to dashboard page
const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const higherlimit = 255;
export default class Schedule extends NavigationMixin(LightningElement) {
    currentPageReference = null;
    @api recId;
    @api hcplink;
    @track showLoader = false;
    @track showheading = false;
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
    @track meetingRequestId;
    @track tod;
    @track datevalue;
    @track emailVal;
    @track startTime;
    @track dateVal;
    @track timeVal;
    @track catalogName;
    @track catalofDescription;
    @track library;
    @track noTitle = false;
    @track productname;
    @track catalogID;
    @track ProductpayerID;
    @track meetingId;
    @track pageVal;
    @track prevPage;
    @track mTimes = [];
    @track attendeeList = [];
    @track meetingUpdate = false;

    userId = uId;
    dateDuplicate = false;
    calicon = callogo;
    _handler;

    navigateback;

    existingAppointmentTimes = [];

    loadedMeetingTimes = false;
    loadedAttendeeList = false;
    showBrandnamewithGenericName = false;	   //Added by Sabari - To Show Generic Name with Brand

    currentPageReference = null;
    urlStateParameters = null;
    sidearrow = arrow
    cross = crossmark;
    plusicon = plus;
    pdfDownloadLink; 
    medicalguide;
    patientInformationLink; //Added by Sabari - : [E2ESE-1770] Patient Information button
    instructionsforuselink;
    instructionsforuselabel;
    sectiondisplay = false;
    primaryExecutive = [];
    @track productid = '';

    @track navigateprod;
    @track navigateprodname;
    @track navigateproddetails;
    @track navigateproddetailsname;
    @track navigatelibrary;
    @track navigatelibraryname;
    @track navigateview;
    @track navigateviewname;
    @track navigatedashboard;
    @track navigatedashboardname;
    @track contactrole = '';
    @track viewRequestHref = '#';
    @track notviewUponReq = true;              //For View Upon Request

    contactpageurl = mfrdomainurl +'/my-contacts';

    isShow = false;
    sourceTextBox;
    shortDescription;
    isReadMore = false;

    get backgroundStyle() {
        return `background-image:url(${bannerimg})`;
    }

    label = {
        NavigateToProduct
    }

    getnames() {
        getSiteNameAndAPIName({ pageName: 'ProductList' })
            .then((result) => {
                console.log({ result });
                this.navigateprod = result.siteAPIName;
                this.navigateprodname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }

    getnames2() {
        getSiteNameAndAPIName({ pageName: 'productdetail' })
            .then((result) => {
                console.log({ result });
                this.navigateproddetails = result.siteAPIName;
                this.navigateproddetailsname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }

    getnames3() {
        getSiteNameAndAPIName({ pageName: 'Librarydetail' })
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

    getnames4() {
        getSiteNameAndAPIName({ pageName: 'viewschedule' })
            .then((result) => {
                console.log({ result });
                this.navigateview = result.siteAPIName;
                this.navigateviewname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }
    getnames5() {
        getSiteNameAndAPIName({ pageName: 'Dashboard' })
            .then((result) => {
                console.log({ result });
                this.navigatedashboard = result.siteAPIName;
                this.navigatedashboardname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }

    product() {
        this.fireDataClickEvent("top_nav_breadcrumb", "", 'Products', "navigation", this.navigateprodname, this.navigateprod, this.productName, 'account management', 'account management');

        if (this.navigateprodname != undefined || this.navigateprod != undefined) {
            this[NavigationMixin.Navigate]({
                //type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                    name: this.navigateprodname,
                    url: this.navigateprod
                },
            });
        }
    }

    backbutton() {
        this.fireDataClickEvent("top_nav_breadcrumb", "", this.productName, "navigation", 'schedule_1__c', '/schedule', this.productName, 'account management', 'account management');

        var navigateurl = this.navigateproddetails + '?recordId=';
        navigateurl += this.productid;
        window.location.replace(navigateurl);
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('IIIII');
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            console.log('urlStateParameters' + JSON.stringify(this.urlStateParameters));
            this.recId = this.urlStateParameters.recordId;
            // this.productid = this.urlStateParameters.prodid;
            this.meetingId = this.urlStateParameters.mId ? this.urlStateParameters.mId : '';
            this.pageVal = this.urlStateParameters.page;
            this.prevPage = this.urlStateParameters.prevPage;
            console.log('this.recId' + this.recId);
        }
    }

    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        console.log({ value });
        const { data, error } = value;
        if (data) {
            console.log({ data });
            this.contactrole = data;
        }
        if (error) {
            console.log({ error });
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

    @wire(getPrimaryExecutive, { 'userId': USER_ID })
    wiredPrimaryExecutive({ error, data }) {
        if (data) {
            this.primaryExecutive = data;
            console.log('Primary Executive' + JSON.stringify(data));
        }
        if (error) {
            console.log('Error' + JSON.stringify(error));
        }
    }

    bookmarklogo = newlogo2;
    bookmarkSelect = newlogo9;
    logo2 = newlogo3;
    logo3 = newlogo4;
    logo4 = newlogo5;
    @api productName;
    @api productLabel;
    @api productDescription;
    @api genericname;
    @api dosage;
    userData = [];
    todaysDate;


    @track footer = false;

    // get todaysDate() {
    //     var today = new Date();
    //     return today.toISOString();
    // }
    handleGA(){
        this.fireDataLayerEvent("link", 'step_0', "contact merck", "registration_flow", 'mycontacts', '/my-contacts','account management','registration');
    }
    handlehcp() {
        this.fireDataClickEvent('link', '', 'HCP site', '', 'schedule__c', '/schedule', this.productName, 'account management', 'account management');
    }

    handlepipdf() {
        this.fireDataClickEvent('button', '', 'pi.pdf', '', 'schedule__c', '/schedule', this.productName, 'account management', 'account management');
    }

    handlemeguide() {
        this.fireDataClickEvent('button', '', 'mi.pdf', '', 'schedule__c', '/schedule', this.productName, 'account management', 'account management');
    }

    handlemepatinfpdf() {
        this.fireDataClickEvent('button', '', 'patinf.pdf', '', 'schedule__c', '/schedule', this.productName, 'account management', 'account management');
    }
    //Added by Sabari - : [E2ESE-1770] Patient Information button

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


    get timezoneoption() {
        return [

            { label: 'EST', value: 'America/New_York' },
        ]
    }

    // Bookmark Remove
    handlerBookMarkRemove(event) {

        console.log('Book Mark Remove');
        console.log({ event });
        const selectedRemovalId = event.currentTarget.dataset.id;
        for (let i = 0; i < this.products.length; i++) {
            if (this.products[i].Id == selectedRemovalId) {
                this.products[i].showSpinner = true;
            }
        }
        console.log({ selectedRemovalId });
        removeCatalogs({ recId: selectedRemovalId, userId: USER_ID })
            .then(result => {

                console.log('Book Mark Remove');
                console.log({ result });
                this.library = null;
                this.fireDataLayerEvent('bookmark', '', 'remove resource','', 'schedule_1__c', '/schedule', this.catalogName, this.productName); //RT GA bug
                //this.refreshCatalog();
                //this.products = [];
                //this.catalogList();
                //this.changeBookMarkColor(selectedRemovalId, 'gray')
            })
            .catch(error => {
                console.log({ error });
                //eval("$A.get('e.force:refreshView').fire();");
                // window.location.reload(true);
            });

        //this.bookmarkimg = false;
    }

    // For Book Mark
    handlerBookMark(event) {

        console.log('Handle Book Mark');
        console.log({ event });
        const selectedRecordId = event.currentTarget.dataset.id;
        /* for(let i=0 ; i< this.products.length; i++){
             if(this.products[i].Id == selectedRecordId){
                 this.products[i].showSpinner=true;
             }
         }*/
        this.catalogId = selectedRecordId;
        console.log('this.catalogId-->', this.catalogId);
        // this.insertCatlogAction(this.catalogId, event);
        this.insertCatlogAction(event.currentTarget.dataset.id, event);
        //this.library='added';
    }

    // Insert Catloag
    insertCatlogAction(selectedRecordId, event) {

        console.log('Insert Catalog');

        this.catlog = selectedRecordId;
        //  this.active = true;

        const fields = {};
        fields[CATALOG_FIELD.fieldApiName] = this.catlog;
        //  fields[ACTIVE.fieldApiName] = this.active;
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
                this.fireDataLayerEvent('bookmark', '', 'save resource','', 'schedule_1__c', '/schedule', this.catalogName, this.productName); //RT GA bug
                //   this.libraryId = libraryobj.id;
                // this.refreshCatalog();
                this.library = 'added';
                //this.products = [];
                //this.catalogList();
                // this.changeBookMarkColor(selectedRecordId, 'green')
                /* this.dispatchEvent(
                     new ShowToastEvent({
                         title: 'Success',
                         message: 'Library record has been created',
                         variant: 'success',
                     }),
                 ); */
                //this.bookmarkimg = true;
            })
            .catch(error => {
                console.log('Error');
                console.log({ error });
                // eval("$A.get('e.force:refreshView').fire();");
                // window.location.reload(true);
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

                //   this.updateRecordView();
            }
            );
    }
    get options() {
        return [
            { label: 'Virtual', value: 'Virtual meeting' },
            { label: 'In-person', value: 'In-Person meeting' },
        ];
    }

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


    connectedCallback() {
        this.notviewUponReq = true;
        this.load();
        this.getnames();
        this.getnames2();
        this.getnames3();
        this.getnames4();
        this.getnames5();
        this.sectiondisplay = false;
        // Disable Past Date

        setTimeout(() => {
            console.log(['Timeout']);
            var bodydiv = this.template.querySelector(".innerbody");
            // console.log();
            var bb = bodydiv.scrollHeight;
            console.log('bb', bb);
            var getdiv = this.template.querySelector(".mfrsf");
            var distanceToTop = getdiv.getBoundingClientRect().top;
            console.log('distanceToTop', distanceToTop);
            var scrolldiv = distanceToTop - window.innerHeight;
            console.log({ scrolldiv });
            this.dispatchEvent(new CustomEvent('getdetailsdata', { bubbles: true, detail: scrolldiv }));
        }, 3000);
        sessionStorage.setItem("SelectedValue", false);
        document.addEventListener('click', this._handler = this.closeCalendar.bind(this));
    }

    // @wire(getCatalogRecord, { recId: '$recId' })
    // wiredgetCatalogRecord(value) {

    //     try{
    //         console.log('Wired Method CATALOG');
    //         console.log({value});
    //         const { data, error } = value;
    //         console.log({data});
    //         var result = data;
    //         console.log({result});
    //         if (result) {
    //             this.productid = result.MSD_CORE_Product_Payor__c;
    //             console.log('this.productid-->', this.productid);
    //             this.catalogName = result.Name;
    //             this.catalofDescription = result.MSD_CORE_Description__c;
    //             this.productname = result.MSD_CORE_Product_Payor__r.Name;
    //             this.catalogID = this.recId;
    //             this.ProductpayerID = result.MSD_CORE_Product_Payor__c;
    //             this.productName = result.MSD_CORE_Product_Payor__r.Name;
    //             this.productDescription = result.MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c;
    //             this.pdfDownloadLink = result.MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c;
    //             this.hcplink = result.MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c;
    //         } else if(error){
    //             console.log({error})
    //         }

    //         var today = new Date();
    //         this.todaysDate = today.toISOString().substring(0, 16);
    //         console.log('this.todayDateTime>>>' + this.todaysDate);

    //         //call the apex controller to get the details for the Catalog
    //         var d = new Date();
    //         this.today = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();
    //         this.catalogList();
    //         this.templist.push(this.count);
    //         this.addattlst.push(this.count1);

    //         if (this.meetingId) {
    //             this.meetingUpdate = true;
    //             getMeetingRequest({ mId: this.meetingId })
    //                 .then(result => {
    //                     console.log('JSON on load' + JSON.stringify(result.data));
    //                     if (result) {
    //                         if (result.data.MSD_CORE_Meeting_preference__c) {
    //                             this.template.querySelector('.radiobtncls').value = result.data.MSD_CORE_Meeting_preference__c;
    //                         }
    //                         if (result.data.MSD_CORE_Resource__c) {
    //                             this.catalogName = result.data.MSD_CORE_Resource__r.Name;
    //                             this.catalofDescription = result.data.MSD_CORE_Resource__r.MSD_CORE_Description__c;
    //                         }

    //                         if (result.data.MSD_CORE_Meeting_Times__r) {
    //                             this.mTimes = result.data.MSD_CORE_Meeting_Times__r;
    //                             for (let i = 0; i < (result.data.MSD_CORE_Meeting_Times__r.length - 1); i++) {
    //                                 this.templist.push(i);
    //                             }

    //                         }

    //                         if (result.data.MSD_CORE_attendee__c) {
    //                             this.attendeeList = result.data.MSD_CORE_attendee__c.split(',');
    //                             let attendees = result.data.MSD_CORE_attendee__c.split(',');
    //                             for (let i = 0; i < (attendees.length - 1); i++) {
    //                                 this.addattlst.push(i);
    //                             }

    //                         }


    //                     }
    //                 }).catch(error => {
    //                     console.log('Inside Error' + error);
    //                 });
    //         }
    //     } catch(error){
    //         console.log({error});
    //     }

    // }

    load() {
        console.log('enteredload');
        var today = new Date();
        this.todaysDate = today.toISOString().substring(0, 16);
        console.log('this.todayDateTime>>>' + this.todaysDate);

        //call the apex controller to get the details for the Catalog
        var d = new Date();
        this.today = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();
        this.catalogList();
        // this.templist.push(this.count);

        this.templist.push({ id: 'inputbox' + this.count, value: this.count, calval: '', drpid: 'dropdown' + this.count, caltime: '' });
        this.addattlst.push(this.count1);
        getCatalogRecord({ recId: this.recId, userId: USER_ID })
            .then(result => {
                console.log({ result });
                if (result) {
                    this.productid = result.MSD_CORE_Product_Payor__c;
                    console.log('this.productid-->', this.productid);
                    if (result.MSD_CORE_Delivery_Framework__c == 'View upon Request') {
                        this.notviewUponReq = false;
                        console.log("View upon"+this.notviewUponReq);
                    }
                    if (result.MSD_CORE_Content_Type__c == 'Coming Soon') {
                        this.showheading = true;
                        console.log('headingis' + this.showheading);
                    }
                    this.catalogName = result.MSD_CORE_Resource_Title__c;
                    this.catalofDescription = result.MSD_CORE_Description__c;
                    this.shortDescription = (result.MSD_CORE_Description__c != null && result.MSD_CORE_Description__c != '') ? result.MSD_CORE_Description__c.length > higherlimit ? this.doSubstring(result.MSD_CORE_Description__c, 0, higherlimit) : result.MSD_CORE_Description__c : '';
                    this.shortDescription = this.shortDescription.trim();
                    this.isReadMore = (result.MSD_CORE_Description__c != null && result.MSD_CORE_Description__c != '') ? (result.MSD_CORE_Show_Read_More__c === true && result.MSD_CORE_Description__c.length > higherlimit) ? true : false : false;
                    this.productname = result.MSD_CORE_Product_Payor__r.Name;
                    if(result.MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c){
                        this.noTitle = true;
                    }
                    this.catalogID = this.recId;
                    this.ProductpayerID = result.MSD_CORE_Product_Payor__c;
                    this.productName = result.MSD_CORE_Product_Payor__r.Name;
                    this.productLabel = result.MSD_CORE_Product_Payor__r.MSD_CORE_Product_Labeling__c;
                    this.productDescription = result.MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c;
                    this.genericname = result.MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c;
                    this.dosage = result.MSD_CORE_Product_Payor__r.MSD_CORE_Dosage_Form_and_Strength__c;
                    this.pdfDownloadLink = result.MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c;
                    this.patientInformationLink = result.MSD_CORE_Product_Payor__r.MSD_CORE_Patient_information__c; //Added by Sabari - : [E2ESE-1770] Patient Information button
                    this.medicalguide = result.MSD_CORE_Product_Payor__r.MSD_CORE_Medication_Guide__c;
                    this.hcplink = result.MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c;
                    this.instructionsforuselink = result.MSD_CORE_Product_Payor__r.MSD_CORE_Instructions_For_Use_Link__c;
                    this.instructionsforuselabel = result.MSD_CORE_Product_Payor__r.MSD_CORE_Instructions_For_Use_Label__c;
                    console.log('myresult11-->' + JSON.stringify(result));
                    console.log('USER_ID-->' + USER_ID);
                    this.fireOnLoadEvent();
                    if (result.Libraries__r)
                        this.library = result.Libraries__r;
                    console.log('LIB-->' + this.library);
                }
            }).catch(error => {
                console.log('Inside Error');
                this.error = error;
                //this.products = undefined;
            });
        if (this.meetingId) {
            this.meetingUpdate = true;
            getMeetingRequest({ mId: this.meetingId })
                .then(result => {
                    console.log('JSON on load' + JSON.stringify(result.data));
                    if (result) {
                        if (result.data.MSD_CORE_Meeting_preference__c) {
                            this.template.querySelector('.radiobtncls').value = result.data.MSD_CORE_Meeting_preference__c;
                        }
                        if (result.data.MSD_CORE_Resource__c) {
                            this.catalogName = result.data.MSD_CORE_Resource__r.Name;
                            this.catalofDescription = result.data.MSD_CORE_Resource__r.MSD_CORE_Description__c;
                        }

                        if (result.data.MSD_CORE_Meeting_Times__r) {
                            this.mTimes = result.data.MSD_CORE_Meeting_Times__r;
                            this.count = -1
                            for (let i = 0; i < (result.data.MSD_CORE_Meeting_Times__r.length - 1); i++) {
                                // this.templist.push(i);
                                let meetingDay = result.data.Meeting_Times__r[i].MSD_CORE_Meeting_Date__c + ' ' + result.data.Meeting_Times__r[i].MSD_CORE_Time_Slot__c
                                console.log(' meetingDay ' + meetingDay);
                                let dt = new Date(meetingDay);
                                let calDate = months[dt.getMonth()] + ' ' + dt.getDate() + ', ' + dt.getFullYear();
                                console.log('calDate ' + calDate);
                                this.templist.push({ id: 'inputbox' + i, value: i, calval: calDate, drpid: 'dropdown' + i, caltime: '' });
                                console.log('templist==>', this.templist);
                                this.count += 1;
                            }

                        }

                        if (result.data.MSD_CORE_attendee__c) {
                            this.attendeeList = result.data.MSD_CORE_attendee__c.split(',');
                            let attendees = result.data.MSD_CORE_attendee__c.split(',');
                            for (let i = 0; i < (attendees.length - 1); i++) {
                                this.addattlst.push(i);
                            }
                        }
                    }
                }).catch(error => {
                    console.log('Inside Error' + error);
                });
        }
    }

    @api
    hidefooter(detaildata) {
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

    renderedCallback() {

        
        /* Added by Sabari - For Keytruda Launch */
        let brandswithGenericName = showproductsGenericNamewithBrand.split(',');
        if(brandswithGenericName.includes(this.productLabel))
        {
            this.showBrandnamewithGenericName = true;
        }

        console.log('this.loadedAttendeeList' + this.loadedAttendeeList);
        if (this.attendeeList && !(this.loadedAttendeeList)) {
            let attendees = this.attendeeList;

            let emailAddress = this.template.querySelectorAll('lightning-input[data-id="attendee"]');
            for (let i = 0; i < attendees.length; i++) {
                if (emailAddress[i]) {
                    if (attendees[i]) {
                        emailAddress[i].value = attendees[i];
                    }
                }

            }
            //this.loadedAttendeeList = true;
        }

        Promise.all([
            loadStyle(this, lightningcss),
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




    handleDate(event) {
        var d = new Date();
        var dt = d.getTime();
        console.log(JSON.stringify(event.target.id));
        console.log('Today Date' + dt);
        let selectedDate = Date.parse(event.target.value);
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
                    times[i].value = 'No preference';
                }
                this.template.querySelector('c-custom-toast').showToast('error', 'Date cannot be empty');
                validdate = false;
                return validdate;
            } else {
                console.log('ELSE');
                if (dates[i] && times[i]) {
                    let dValues = formatteddate.split('-');
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

                    let dt = new Date(dValues[0], dValues[1], dValues[2], tValues[0], tValues[1], 0);
                    datelst.push(dt.toString());
                    validdate = true;
                }
            }
            // this.fireDataLayerEvent("date/time", "step_1", "Time (Optional)", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
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

    handleTimezone() {

    }


    catalogList() {
        getCatalogs({ prodId: this.recId, userId: USER_ID })
            .then(result => {
                console.log('106-cataloglist');
                let record = result;
                console.log('result--' + JSON.stringify(result));
                this.products = record.map(row => ({
                    ...row,
                    isViewInMeeting: row.MSD_CORE_Delivery_Framework__c === 'View in Meeting',
                    isViewImmediately: row.MSD_CORE_Delivery_Framework__c === 'View Immediately',
                    isViewUponRequest: row.MSD_CORE_Delivery_Framework__c === 'View upon Request'
                }));
                console.log('106-cataloglist' + JSON.stringify(this.products));
                //this.products = result;
                this.error = undefined;
                this.productName = result[0].MSD_CORE_Product_Payor__r.Name;
                this.productLabel = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Product_Labeling__c;
                this.productDescription = result[0].MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c;
            })
            .catch(error => {
                this.error = error;
                //this.products = undefined;
            });
    }

    addnewdate(event) {
        try {
            let dates = this.template.querySelectorAll('.Date');
            var allowDate = true;
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
                this.templist.push({ id: 'inputbox' + this.count, value: this.count, calval: '', drpid: 'dropdown' + this.count, caltime: '' });
            }
            this.fireDataLayerEvent("button", "step_1", "add date", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);

        }
        catch (error) {
            console.log('error' + JSON.stringify(error));
        }


        //}
    }
    addnewatte() {

        let validationsList = this.handlerEmailValidation();
        console.log('validationsList--' + JSON.stringify(validationsList));
        if (!validationsList.includes(false)) {
            if (this.addattlst.length <= 3) {
                this.count1 += 1;
                this.addattlst.push(this.count1);
            } else {
                this.template.querySelector('c-custom-toast').showToast('error', 'Only 4 attendees are allowed');
            }

        }
        this.fireDataLayerEvent("button", "step_3", "add attendee", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);

    }
    removedate(event) {
        let tobeDeletedID = event.currentTarget.dataset.id
        this.removeDatafromTempList(tobeDeletedID);

        /*   var indx = event.target.dataset.value;
        if (this.templist.length > 1) {
              this.templist.splice(indx, 1);
          }*/
        this.dateDuplicate = false;
        this.fireDataLayerEvent("date/time", "step_1", "date/time removed", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
    }
    removefield(event) {
        var indx = event.target.dataset.value;
        if (this.addattlst.length > 1) {
            this.addattlst.splice(indx, 1);
        }
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

                //if (emailVal.match(emailRegex) || emailVal == "" || !emailVal) {
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
                }

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
        // this.fireDataLayerEvent("button", '', "schedule appointment", '', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
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

        if (meetingPreferenceValidation) {

        }
        console.log('111-->' + dates.length);
        console.log('111-->' + dates[0].value);
        var valid = this.handleTime();
        if (valid) {
            if (dates.length > 0 && dates[0].value != null && dates[0].value != undefined && dates[0].value != '') {
                //   if ( dates.length > 0 && dates[0].value != null && dates[0].value != undefined && dates[0].value != '' && times.length > 0 && times[0].value != null && times[0].value != undefined && times[0].value != '') {
                if (!meetingPreferenceValidation) {

                    let response = this.handlerEmailValidation();
                    if (!response.includes(false) && !this.dateDuplicate) {
                        let MeetingRequest = {};

                        let emailAddress = this.template.querySelectorAll('lightning-input[data-id="attendee"]');

                        emailAddress.forEach(item => {
                            if (item.value) {
                                this.emailVal = this.emailVal ? this.emailVal + ', ' + item.value : item.value;
                            }
                        });
                        MeetingRequest.MSD_CORE_Status__c = 'Pending';
                        MeetingRequest.MSD_CORE_Time_zone__c = this.setDefaultime;
                        MeetingRequest.MSD_CORE_Source__c = 'MFR';
                        //let startDate = new Date(dValues[0], dValues[1], dValues[2], tValues[0], tValues[1], 0  );
                        //MeetingRequest.Start_DateTime_vod__c = startDate;
                        MeetingRequest.MSD_CORE_Meeting_preference__c = this.template.querySelector('.radiobtncls').value;
                        MeetingRequest.MSD_CORE_attendee__c = this.emailVal;
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
                        if (this.userData[0].AccountId) {
                            MeetingRequest.Account_vod__c = this.userData[0].AccountId;
                        }
                        if (this.primaryExecutive[0].Id) {
                            MeetingRequest.Assignee_vod__c = this.primaryExecutive[0].Id;
                        }


                        this.meetingRequests.push(MeetingRequest);
                        //this.showResponse = true;
                        this.showLoader = true;
                        createMeetRequest({ request: JSON.stringify(this.meetingRequests) })
                            .then(result => {
                                console.log('Result' + JSON.stringify(result));
                                this.meetingRequestNumber = result.message;
                                this.meetingRequestId = result.data.Id;

                                this.viewRequestHref = this.navigateview + '?recordId=' + `${this.meetingRequestId}`;

                                //let meetingTime = { MSD_CORE_Meeting_Date__c, MSD_CORE_Time_Slot__c };
                                let meetingTimes = [];
                                for (let i = 0; i < dates.length; i++) {
                                    var localDate = new Date(dates[i].value).toLocaleString("en-US", {
                                        localeMatcher: "best fit",
                                        timeZoneName: "short"
                                    });

                                    console.log(localDate);

                                    let formatteddate = this.getformattedDate(localDate);
                                    console.log({formatteddate});
                                    if (dates.length > 0) {
                                        this.dateVal = formatteddate;
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

                                    meetingTime.MSD_CORE_Meeting_Date__c = formatteddate;
                                    meetingTime.MSD_CORE_Meeting_Request__c = result.data.Id;
                                    if (times[i].value == null || times[i].value == '') {
                                        meetingTime.MSD_CORE_TimeSlot__c = 'No preference';
                                    } else {
                                        meetingTime.MSD_CORE_TimeSlot__c = times[i].value;
                                    }

                                    //meetingTime.MSD_CORE_Time_Slot__c =times[i].value!='No Preference'? times[i].value[0]+':'+times[i].value[1] : '00:00AM';
                                    meetingTime.MSD_CORE_Time_Slot__c = tValues[0] + ':' + tValues[1];
                                    meetingTimes.push(meetingTime);
                                    console.log('Strinrequest' + JSON.stringify(meetingTimes));

                                }

                                console.log('meetingTimes-->',{meetingTimes});

                                createMeetingTimes({ request: JSON.stringify(meetingTimes) })
                                    .then(result => {

                                    })
                                    .catch(e => {
                                        // this.showLoader=false;
                                        console.log('error' + JSON.stringify(e));
                                    }).finally(() => {
                                        //this.showLoader=false;
                                        this.showResponse = true;
                                        console.log('Finally2');
                                    })
                                    //debugger;
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

        this.fireDataLayerEvent("button", "step_4", "submit request", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
        //}
    }

    closeResponse(event) {
        var dtname = event.currentTarget.dataset.name;
        console.log('dtname>>>>>'+dtname);
        this.fireDataClickEvent("button", "", dtname, 'modal', 'schedule_1__c', '/schedule', this.productName, 'registration', 'registration'); // RT GA bug
        this.showResponse = false;
        console.log('Inside Close response' + this.ProductpayerID);
        if (this.prevPage == 'productdetail') {
            /*let toNavigateUrl = '/product/productdetail?recordId=' + `${this.ProductpayerID}` + '&page=' + this.pageVal + '';*/
            let toNavigateUrl = this.navigateproddetails + '?recordId=' + `${this.ProductpayerID}` + '&page=' + this.pageVal + '';
            console.log('entered' + toNavigateUrl)
            this.navigateToNewRecordPage(toNavigateUrl);
            console.log(this.navigateproddetails,'+toNavigateUrl');
            //this.fireDataClickEvent("button", "", 'back to screen_X', 'modal', 'productdetail__c','/product/productdetail' , this.productName, '', '');//RT-N-1053
        }
        if (this.prevPage == 'librarydetail') {
            let toNavigateUrl = this.navigatelibrary + '?recordId=' + `${this.ProductpayerID}` + '&page=' + this.pageVal + '';
            console.log('entered' + toNavigateUrl)
            this.navigateToNewRecordPage(toNavigateUrl);
        }
    }

    editclick() {
        this.sectiondisplay = true;
        setTimeout(() => {
            this.populateAppointments()
        }, 500);
    }
    cancelclick() {
        this.sectiondisplay = false;
    }


    handlerOnclickProduct(event) {
        this.prodId = event.currentTarget.dataset.id;
        alert(this.prodId);
        let toNavigateUrl = '/librarydetails?recordId=' + `${this.prodId}`;
        console.log('entered')
        this.navigateToNewRecordPage(toNavigateUrl);
    }

    viewRequest(event) {
        this.load();
        this.fireDataLayerEvent("button", "", "view request", "modal", 'schedule_1__c', '/schedule', this.catalogName, this.productName, 'registration', 'registration'); // already there RT
        let toNavigateUrl = this.navigateview + '?recordId=' + `${this.meetingRequestId}`;
        console.log('meeting request Id')
        //this.navigateToNewRecordPage(toNavigateUrl);
        window.open(toNavigateUrl, "_self");
    }


    navigateToNewRecordPage(url) {
        console.log('toNavigateUrl==' + url);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }


    navigatepage(event) {

        console.log('Navigate');
        console.log({ event });
        var getnameval = event.currentTarget.dataset.name;
        console.log("Get name" + getnameval);

        if (getnameval == 'ProductList') {
            this.fireDataClickEvent("button", "", "browse catalog", "", this.navigateprodname, this.navigateprod, this.productName, 'registration', 'registration'); //RT-N-1053
            if (this.navigateprodname != undefined || this.navigateprod != undefined) {
                this[NavigationMixin.Navigate]({
                    //type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: this.navigateprodname,
                        url: this.navigateprod
                    },
                });
            }
        } else if (getnameval == 'Dashboard') {
            this.fireDataClickEvent("button", "", "go to dashboard", "modal", this.navigatedashboardname, this.navigatedashboard, this.productName, 'account management', 'account management'); //RT-N-1053
            var recId = event.currentTarget.dataset.id;
            console.log({ recId });
            window.location.replace(this.navigatedashboard);
        } else {
            console.log('else');
        }

    }


    @wire(getPrimaryExecutive, { userId: USER_ID })
    wiredPrimaryExecutive({ error, data }) {
        console.log('-->wiredPrimaryExecutive<--');
        console.log({ data });

        if (data) {
            this.primaryExecutive = data;

            console.log('Primary Executive' + JSON.stringify(data));
            console.log('Primary executive data = ' + this.primaryExecutive);

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
                _tempList.push({ id: currentItem.id, value: currentItem.value, calval: selectedDate, drpid: currentItem.drpid, caltime: currentItem.caltime });

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
            if (currentItem.id == this.sourceTextBox) {
                if (currentItem.calval != '' && currentItem.calval != null && currentItem.calval != undefined && currentItem.calval.length > 0) {
                    caldate = new Date(currentItem.calval);
                } else {
                    caldate = new Date();
                }
            }
        });

        /*let objCalenderTextBox = this.template.querySelector('[data-id="' + this.sourceTextBox + '"]');
        let caldate = '';
        if (objCalenderTextBox.value != '' && objCalenderTextBox.value != null && objCalenderTextBox.value != undefined && objCalenderTextBox.value.length > 0) {
            caldate = new Date(objCalenderTextBox.value);
        } else {
            caldate = new Date();
        }*/
        console.log({ caldate });
        let objparameter = { isShow: this.isShow, sourceTextBox: this.sourceTextBox, calday: caldate.getDate(), calmonth: caldate.getMonth(), calyear: caldate.getFullYear(), apicss: this.sourceTextBox.slice(-1), pagename: 'schedule' };
        console.log({ objparameter });
        console.log('Show Calendar');
        this.template.querySelector('c-lightning-calendar').passcalenderparameter(objparameter);
        event.stopPropagation();
        this.fireDataLayerEvent("date/time", "step_1", "Date", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
        return false;
    }
    setTopCordinate(eve) {
        let cordinate = 0;
        return cordinate;
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
        let passParameterObj = { isShow: false }
        this.template.querySelector('c-lightning-calendar').doCloseCalendar(passParameterObj);
    }
    // For Read More Functionality
    doSubstring(description, lowerlimit, higherlimit) {
        let _description = description.substring(lowerlimit, higherlimit);
        return _description;
    }
    handleReadMore(event) {
        this.isReadMore = false;
        this.fireDataLayerEvent("link", '', "Read more", '', 'schedule_1__c', '/schedule', this.catalogName, this.productName);// RT-N-2023
    }

    // Added New Method For Event
    handleMeetingPref() {
        this.fireDataLayerEvent("radio", "step_2", "Meeting preference", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
        this.fireDataLayerEvent("radio selection", "step_2", this.template.querySelector('.radiobtncls').value, 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
    }

    // Added New Method For Event
    handleAddAttendees() {
        this.fireDataLayerEvent("label", "step_3", "Additional attendee email address (optional)", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
    }

    // Event
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, resName, prdtName) {

        this.dispatchEvent(new CustomEvent('datalayereventbrandcontent', {
            detail: {
                // event_category: category,
                // event_action: action,
                // event_label: label,
                // page_type: 'registration',
                // page_purpose: 'registration',
                // page_audience: 'payor',
                // page_marketname: 'united_states',
                // page_region: 'us',
                // page_contentclassification: 'non-commercial',
                // page_localproductname: prdtName,
                // content_name: resName
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'registration',
                page_purpose: 'registration',
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
                content_name: resName,
                page_localproductname: prdtName,
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'schedule',
            },
            bubbles: true,
            composed: true
        }));
    }
    populateAppointments() {
        console.log('this.loadedMeetingTimes' + this.loadedMeetingTimes);
        console.log('this.mTimes' + this.mTimes);
        if (this.mTimes && !(this.loadedMeetingTimes)) {
            console.log('Inside Meeting Times');

            let dates = this.template.querySelectorAll('.Date');
            let times = this.template.querySelectorAll('.Time');
            for (let i = 0; i < this.mTimes.length; i++) {

                let dt = new Date(this.mTimes[i].MSD_CORE_Meeting_Date__c);
                dates[i].value = months[dt.getMonth()] + ' ' + dt.getDate() + ', ' + dt.getFullYear();

                times[i].value = this.mTimes[i].MSD_CORE_Time_Slot__c;
                let appDate = {
                    count: i,
                    Id: this.mTimes[i].Id,
                    meetingDate: this.mTimes[i].MSD_CORE_Meeting_Date__c,
                    meetingTime: this.mTimes[i].MSD_CORE_Time_Slot__c,
                }
                this.existingAppointmentTimes.puth(appDate);
            }
            console.log('existingAppointmentTimes' + JSON.stringify(this.existingAppointmentTimes));

        }
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
            _itemList.push({ id: 'inputbox' + ctr, value: ctr, calval: currentItem.calval, drpid: 'dropdown' + ctr, caltime: currentItem.caltime });
            ctr++;
        });
        this.count = ctr - 1;
        this.templist = [];
        this.templist = JSON.parse(JSON.stringify(_itemList));
        console.log('this.templist resetTempList' + JSON.stringify(this.templist));
    }

    //Google Analytics Event
    fireOnLoadEvent() {
        console.log('EVENT TRIGGERED');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                data_design_category: '',
                data_design_action: '',
                data_design_label: '',
                data_design_module: '',
                page_type: 'registration',
                page_purpose: 'registration',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'schedule_1__c',
                link_url: '/schedule',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: this.productName,
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'schedule',
            },
            bubbles: true,
            composed: true
        }));
    }

    fireDataClickEvent(category, action, label, module, linkedtext, linkedurl, prdtname, pagetype, pagepurpose) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: pagetype,
                page_purpose: pagepurpose,
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
                content_name: this.catalogName,
                page_localproductname: prdtname,
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'schedule',

            },
            bubbles: true,
            composed: true
        }));
    }

    handleTimeOption(event) {
        let toBeSelectedID = event.currentTarget.dataset.id
        let selectedValue = this.template.querySelector('[data-id="' + toBeSelectedID + '"]').value;
        let _tempList = [];
        this.templist.forEach(currentItem => {
            if (currentItem.drpid != toBeSelectedID) {
                _tempList.push(currentItem);
            } else {
                _tempList.push({ id: currentItem.id, value: currentItem.value, calval: currentItem.calval, drpid: currentItem.drpid, caltime: selectedValue });

            }
        });
        console.log('_tobeDeletedID ' + toBeSelectedID)
        this.templist = [];
        this.templist = JSON.parse(JSON.stringify(_tempList));
        console.log('this.templist toBeSelectedID' + JSON.stringify(this.templist));
        this.fireDataLayerEvent("date/time", "step_1", "Time", 'form', 'schedule_1__c', '/schedule', this.catalogName, this.productName);
    }
    handleTimeOptionClick(event) {
        console.log('handleTimeOptionClick');
        // RM --- 24 Feb 2023 --- Bug_Web_043  
        this.dateDuplicate = false;
        let passParameterObj = { isShow: false }
        this.template.querySelector('c-lightning-calendar').doCloseCalendar(passParameterObj);
    }

    // Added For View Upon Request
    hsForViewuponreq() {

        let MeetingRequest = {};

        MeetingRequest.MSD_CORE_Status__c = 'Pending';
        MeetingRequest.MSD_CORE_Source__c = 'MFR';
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
        if (this.userData[0].AccountId) {
            MeetingRequest.Account_vod__c = this.userData[0].AccountId;
        }
        if (this.primaryExecutive[0].Id) {
            MeetingRequest.Assignee_vod__c = this.primaryExecutive[0].Id;
        }
        this.meetingRequests.push(MeetingRequest);
        this.showLoader = true;
        createMeetRequest({ request: JSON.stringify(this.meetingRequests) })
            .then(result => {
                console.log('Result In hsForViewuponreq::::>',{result});
                this.meetingRequestNumber = result.message;
                this.meetingRequestId = result.data.Id;
                this.showLoader = false;
                this.showResponse = true;
            })
            .catch(error => {
                this.showLoader = false;
                console.log('Error In hsForViewuponreq::::>',{error});
            })
            this.fireDataLayerEvent("button", '', "submit request", '', 'schedule_1__c', '/schedule', this.catalogName, this.productName);     
    }
}