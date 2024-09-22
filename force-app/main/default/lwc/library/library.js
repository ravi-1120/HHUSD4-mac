import { LightningElement, wire, api, track } from 'lwc';
import getLibraryCatalogs from '@salesforce/apex/MSD_CORE_ProductList.getLibraryCatalogs';
import getCatalogPerProdSavedCount from '@salesforce/apex/MSD_CORE_ProductList.getCatalogPerProdSaved';
import getProducts from '@salesforce/apex/MSD_CORE_ProductList.getProducts';
import getRequestsCount from '@salesforce/apex/MSD_CORE_RequestController.getRequestsCount';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import newlogo2 from '@salesforce/resourceUrl/bookmark1';
import newlogo3 from '@salesforce/resourceUrl/larrow';
import newlogo4 from '@salesforce/resourceUrl/boxarrow';
import newlogo5 from '@salesforce/resourceUrl/boxarrow';
import newlogo6 from '@salesforce/resourceUrl/like';
import newlogo7 from '@salesforce/resourceUrl/rarrow';
import arrow from '@salesforce/resourceUrl/rightarrow2';
import newlogo8 from '@salesforce/resourceUrl/cal';
import newlogo9 from '@salesforce/resourceUrl/bookmarkSelect';
import { createRecord } from 'lightning/uiRecordApi';
import libObject from '@salesforce/schema/MSD_CORE_Library__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ACTIVE from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Active__c';
import CATALOG_FIELD from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Catalog__c';
import PAYOR_FIELD from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Payor__c';
import Id from '@salesforce/user/Id';
import warrow from '@salesforce/resourceUrl/whitearrow';
import removeCatalogswithParent from '@salesforce/apex/MSD_CORE_ProductList.removeCatalogswithParent';
import USER_ID from "@salesforce/user/Id";
import lockicon from '@salesforce/resourceUrl/MSD_CORE_lock_Icon';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import cssfile from '@salesforce/resourceUrl/librarypagecss';
// import getprodInd from '@salesforce/apex/MSD_CORE_ProductList.getProdIndication';
import updatenotification from '@salesforce/apex/MSD_CORE_Notification.updateNotification';
import getnotificationcount from '@salesforce/apex/MSD_CORE_Notification.getNotificationCount';
import updateReadCheck from '@salesforce/apex/MSD_CORE_ProductDetail.updateReadCheck';                  //E2ESE-911
import generateSingedURL from '@salesforce/apex/MSD_CORE_ProductList.getcontentconnector';  //get ContentConnector
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import showproductsGenericNamewithBrand from '@salesforce/label/c.showproductsGenericNamewithBrand'; //Added by Sabari - To Show Generic Name with Brand
const requestType = ['Approved', 'Pending', 'Rejected'];
const higherlimit = 255;
const catConstant = 'cat';
const catdescConstant = 'catdesc';
export default class mfr_productDetails2 extends NavigationMixin(LightningElement) {

    tab1Bool;
    tab2Bool = true;
    tab3Bool;
    tab4Bool;
    tab5Bool;
    tab2Label = 'Saved '
    tab3Label = 'Appointments ';
    tab4Label = 'Pending requests ';
    tab5Label = 'Closed requests ';
    saveCSS = 'slds-tabs_default__item slds-is-active';
    activityCSS = 'slds-tabs_default__item';
    appointmentCSS = 'slds-tabs_default__item';
    pendingCSS = 'slds-tabs_default__item';
    closedCSS = 'slds-tabs_default__item';
    @track showPagination; // for Bug_Web_051 by Tausif on 06.03.2023 removed assignment due to Edge browser
    @track isproducts;
    tab3LabelCount = '';
    tab4LabelCount = '';
    tab5LabelCount = '';
    ApprovedCount = 0;
    PendingCount = 0;
    RejectedCount = 0;
    SavedCount = 0;
    lockimage = lockicon;
    Whitearrow = warrow;
    //activetabvalue = '2';
    showBrandnamewithGenericName = false;

    // ========  [tab1Label and tabsetOptions] Added for Mobile Screen Start == //

    tab1Label = 'Activity';

    @track isActivityBool = false;
    isSavedBool = false;
    isAppointmentsBool = false;
    isPendingRequestBool = false;
    isClosedRequestBool = false;
    mobTabvalue;
    @track tabsetOptions;
    @track productLabel = '';
    @track productName = '';
    @track catalogListData;


    handlePickListChange(event) {
        console.log("pick list changed");
        let tabValue = event.currentTarget.value;
        console.log("tab Value ===>" + tabValue);

        if (tabValue == 'Activity') {
            this.fireDataLayerEvent("content_switcher", '', "activity", '', 'detail__c', '/library/detail', '', this.productName, '', '', '');
            this.isActivityBool = true;
            this.isSavedBool = false;
            this.isAppointmentsBool = false;
            this.isPendingRequestBool = false;
            this.isClosedRequestBool = false;
        } else if (tabValue == 'Saved') {
            this.fireDataLayerEvent("content_switcher", '', 'saved', '', 'detail__c', '/library/detail', '', this.productName, this.totalCount, '', '');
            this.isActivityBool = false;
            this.isSavedBool = true;
            this.isAppointmentsBool = false;
            this.isPendingRequestBool = false;
            this.isClosedRequestBool = false;
        } else if (tabValue == 'Appointments') {
            this.fireDataLayerEvent("content_switcher", '', 'appointments', '', 'detail__c', '/library/detail', '', this.productName, '', this.ApprovedCount, '');
            this.isActivityBool = false;
            this.isSavedBool = false;
            this.isAppointmentsBool = true;
            this.isPendingRequestBool = false;
            this.isClosedRequestBool = false;
        } else if (tabValue == 'Pending requests') {
            this.fireDataLayerEvent("content_switcher", '', 'pending requests', '', 'detail__c', '/library/detail', '', this.productName, '', '', this.PendingCount);
            this.isActivityBool = false;
            this.isSavedBool = false;
            this.isAppointmentsBool = false;
            this.isPendingRequestBool = true;
            this.isClosedRequestBool = false;
        } else if (tabValue == 'Closed requests') {
            this.fireDataLayerEvent("content_switcher", '', 'closed requests', '', 'detail__c', '/library/detail', '', this.productName, '', '', this.RejectedCount);
            this.isActivityBool = false;
            this.isSavedBool = false;
            this.isAppointmentsBool = false;
            this.isPendingRequestBool = false;
            this.isClosedRequestBool = true;
        }
    }

    // ====For Mobile Screen End
    @api tabname;

    @track recId;
    bookmark1 = newlogo2;
    arrow1 = newlogo3;
    logo3 = newlogo4;
    logo4 = newlogo5;
    @track like = newlogo6;
    rarrow = newlogo7;
    sidearrow = arrow
    cal = newlogo8;
    loggedInUserId = Id;
    @track bookmarkSelect = newlogo9;
    usrId = USER_ID;
    roleId;
    @track bookmarkimg = false;

    @api productName;
    @api productDescription;
    @track productdosage;
    @track productgeneric = '';
    @api aboutProduct;
    @track products = [];
    @api hcplink;
    error;
    page = 1; //this is initialize for 1st page
    items = []; //it contains all the records.
    startingRecord = 1; //start record position per page
    endingRecord = 0; //end record position per page
    pageSize = 6; //default value we are assigning
    totalRecountCount = 0; //total record count received from all retrieved records
    totalPage = 0; //total number of page is needed to display all records
    pdfDownloadLink;
    currentPageReference = null;
    urlStateParameters = null;
    catalogId;
    catlog = '';
    active = false;
    Name;
    library = {};
    pagenationlistItems = [];
    prescribinginfo;
    patientinfo; //Added by Sabari - : [E2ESE-1770] Patient Information button
    medicalguide;
    instructionforuselabel;
    instructionforuselink;
    value;
    pageNumber = 1
    @track totalCount;
    @track footer = false;
    @track productnameforga;
    @track NavigateToDashboard;
    @track NavigateToDashboardapi;
    @track NavigateToLibrary;
    @track NavigateToLibraryapi;
    @track prodlstpage;
    @track prodlstpageapi;
    @track librarypage;
    @track librarypageapi;
    @track contactrole = '';
    // RM --- 23 Feb 2023 --- Bug_Web_036 
    @track scheduelepageapi;
    @track scheduelepage;


    productList() { window.open('/s/product-list-page', '_blank').focus(); }


    // Get Product Indication
    /*
    getproductIndication() {
        getprodInd({ prodId: this.recId })
            .then(result => {
                this.infoval = result.MSD_CORE_Information_About_Product__c;
                this.safetyinfo = result.MSD_CORE_Selected_Safety_Information__c;
            })
            .catch(error => {
                console.log({ error });
            })
    }*/

    //Added by Tausif to get Saved Count on wire
    @wire(getCatalogPerProdSavedCount, { recId: '$recId', userId: USER_ID })
    wiredgetCatalogPerProdSavedCount(value) {
        console.log('Wired wiredgetCatalogPerProdSavedCount', value);
        const { data, error } = value;
        if (data) {
            this.totalCount = data.length;
            this.setPaginationVisibility();//Bug_Web_051 by Tausif-Added
            this.mobPickValueandLabels('wiredgetCatalogPerProdSavedCount count ', this.totalCount);
        } else if (error) {
            this.error = error;
            console.log('error in wiredgetCatalogPerProdSavedCount ' + JSON.stringify(this.error));
        }
    }

    //End Tausif
    @wire(getRequestsCount, { product: '$recId', userid: USER_ID })
    wiredgetRequestsCount(value) {
        console.log('Wired Count');
        console.log({ value });
        const { data, error } = value;
        if (data) {
            this.setRequestCount(data);
        } else if (error) {
            this.error = error;
            console.log('error in getRequestsCount ' + JSON.stringify(this.error));
        }
    }
    @wire(getProducts, { prodId: '$recId' })
    wiredgetProducts(value) {
        console.log('Get Product');
        console.log({ value });
        const { data, error } = value;
        console.log({ data });
        if (data) {
            console.log({ data });
            this.prescribinginfo = data[0].MSD_CORE_Prescribing_Information__c;
            this.patientinfo = data[0].MSD_CORE_Patient_information__c; //Added by Sabari - : [E2ESE-1770] Patient Information button
            this.medicalguide = data[0].MSD_CORE_Medication_Guide__c;
            this.productName = data[0].Name;
            this.productLabel = data[0].MSD_CORE_Product_Labeling__c;
            this.productDescription = data[0].MSD_CORE_Product_Description__c;
            this.productdosage = data[0].MSD_CORE_Dosage_Form_and_Strength__c;
            this.productgeneric = data[0].MSD_CORE_Generic_Name__c;
            this.aboutProduct = data[0].MSD_CORE_Information_About_Product__c;
            this.hcplink = data[0].MSD_CORE_HCP_site__c;
            this.instructionforuselabel = data[0].MSD_CORE_Instructions_For_Use_Label__c;
            this.instructionforuselink = data[0].MSD_CORE_Instructions_For_Use_Link__c;
        } else if (error) {
            console.log({ error });
        }
    }
    // FOR LOADING CSS FILE FROM STATIC RESOURCES
    renderedCallback() {

        /* Added by Sabari - For Keytruda Launch */
        let brandswithGenericName = showproductsGenericNamewithBrand.split(',');
        if(brandswithGenericName.includes(this.productLabel))
        {
            this.showBrandnamewithGenericName = true;
        }

        console.log('Rendered call back');
        Promise.all([
            loadStyle(this, cssfile),
        ]).then(() => {
            console.log('Files loaded!!');
        })
            .catch(error => {
                console.log(error.body.message);
            });

         /* Added by Sabari to add the new line in Catalog description */
        let finddescelements = this.template.querySelectorAll('.updatedesc');
        finddescelements.forEach((element)=>{
            const datavalue = element.getAttribute("data-value");
            console.log('inside rendered '+datavalue);
            element.innerHTML = datavalue;
        });

        let findjobelements = this.template.querySelectorAll('.updatejobcd');
        findjobelements.forEach((element)=>{
            const jobvalueparts = element.getAttribute("data-value").split(/<br>\s*<br>/);
            if(jobvalueparts.length >=2){
            const jobid = jobvalueparts[jobvalueparts.length-1].trim();
            if(jobid!==""){
            let subelement = element.querySelector('.jobid');
            if(subelement){
                subelement.innerHTML = '<br>'+jobid;
            }
            }
            }
        });
        
    }
    setRequestCount(meetingRequestsData) {
        let requests = this.getRequestMappedValue(meetingRequestsData);
        console.log({ requests });
        try {
            requestType.forEach(record => {
                console.log('MEETING REQUEST');
                console.log({ record });
                let results = requests.filter(row => {
                    return row.Status == record;
                });

                if (record == 'Approved') {
                    results.forEach(record => {
                        this.ApprovedCount += parseInt(record.expr0);
                    });

                }
                else if (record == 'Pending') {
                    results.forEach(record => {
                        this.PendingCount += parseInt(record.expr0);
                    });
                }
                else if (record == 'Rejected') {
                    results.forEach(record => {
                        this.RejectedCount += parseInt(record.expr0);
                    });
                } else if (record == 'Saved') {
                    results.forEach(record => {
                        this.SavedCount += parseInt(record.expr0);
                    });
                }
            });

            this.tab3LabelCount = this.ApprovedCount;
            this.tab4LabelCount = this.PendingCount;
            this.tab5LabelCount = this.RejectedCount;
            this.mobPickValueandLabels(); /*RT 02-03-2023 Bug_Mbl_015*/
        } catch (error) {
            console.log('exception in setRequestCount ' + error)
        }
    }
    connectedCallback() {
        console.log('Connected Call back');
        console.log('this.recId 111 : ' + this.recId);
        console.log('productName--->', this.productName);
        console.log('productName--->', this.productnameforga);
        this.contactrole = sessionStorage.getItem('SFMC_Audience');
        // this.getproductIndication();
        this.getnotification();
        this.gesitename();

        // RM --- 23 Feb 2023 --- Bug_Web_036 
        this.getScheduleappointmentpagedetail();

        sessionStorage.setItem("SelectedValue", false);
        let library_sesson = sessionStorage.getItem('SelectedValue');
        console.log({ library_sesson });

        console.log(':::::::::::::::::::::::tabnamme>>>>>>>>>>>...', this.tabname);
        setTimeout(() => {
            let bodydiv = this.template.querySelector(".scrolldiv");
            console.log({ bodydiv });
            let bb = bodydiv.scrollHeight;
            console.log({ bb });
            let getdiv = this.template.querySelector(".mfrsf");
            console.log({ getdiv });
            let distanceToTop = getdiv.getBoundingClientRect().top;
            console.log({ distanceToTop });
            let test = distanceToTop - bb;
            let scrolldiv = distanceToTop - window.innerHeight;
            console.log({ scrolldiv });
            this.dispatchEvent(new CustomEvent('getdetailsdata', { bubbles: true, detail: scrolldiv }));
        }, 3000);
    }

    handlehcp(event) {
        this.fireDataClickEvent("link", '', "HCP site", '', 'HCP site', this.hcplink, this.productName);
    }
    handlemed(event) {
        this.fireDataClickEvent("link", '', "mg.pdf", '', 'Medication Guide', this.medicalguide, this.productName);
    }
    handlepipdf(event) {
        console.log('this.productName : ' + this.productName);
        this.fireDataClickEvent("button", '', "pi.pdf", '', 'Prescribing Info', this.prescribinginfo, this.productName);
    }
    handlepatinfpdf(event) {
        console.log('this.productName : ' + this.productName);
        this.fireDataClickEvent("button", '', "patinf.pdf", '', 'Patient Info', this.patientinfo, this.productName);
    }
    handleclickevent(event) {

        if (event.target.dataset.name == 'Dashboard') {
            this.fireDataClickEvent("top_nav_breadcrumb", '', event.target.dataset.name, 'navigation', 'Dashboard', this.NavigateToDashboard, this.productName);
        }
        else if (event.target.dataset.name == 'Library') {
            this.fireDataClickEvent("top_nav_breadcrumb", '', event.target.dataset.name, 'navigation', 'Library', this.NavigateToLibrary, this.productName);
        }
    }
    mobtabredirecton() {

        console.log(this.tabname);

        let tabValue = this.tabname;
        // this.mobTabvalue = tabValue;

        if (tabValue == 'Activity') {
            this.isActivityBool = true;
            this.isSavedBool = false;
            this.isAppointmentsBool = false;
            this.isPendingRequestBool = false;
            this.isClosedRequestBool = false;

            // this.mobTabvalue = tabValue;
            /*RT o2-03-2023 Bug_Mbl_015*/
        } else if (tabValue == 'Save') {
            this.isActivityBool = false;
            this.isSavedBool = true;
            this.isAppointmentsBool = false;
            this.isPendingRequestBool = false;
            this.isClosedRequestBool = false;

            // this.mobTabvalue = tabValue + ' ('+ this.SavedCount + ')';

        } else if (tabValue == 'Appointment') {
            this.isActivityBool = false;
            this.isSavedBool = false;
            this.isAppointmentsBool = true;
            this.isPendingRequestBool = false;
            this.isClosedRequestBool = false;

            // this.mobTabvalue = tabValue + ' ('+ this.ApprovedCount + ')';
        } else if (tabValue == 'Request') {
            this.isActivityBool = false;
            this.isSavedBool = false;
            this.isAppointmentsBool = false;
            this.isPendingRequestBool = true;
            this.isClosedRequestBool = false;

            // this.mobTabvalue = tabValue + ' ('+ this.PendingCount + ')';
        } else if (tabValue == 'Closed') {
            this.isActivityBool = false;
            this.isSavedBool = false;
            this.isAppointmentsBool = false;
            this.isPendingRequestBool = false;
            this.isClosedRequestBool = true;

            // this.mobTabvalue = tabValue + ' ('+ this.RejectedCount + ')';
        }

        this.value = this.tabname;
    }

    gesitename() {
        getSiteNameAndAPIName({ pageName: 'Dashboard' })
            .then((result) => {
                console.log({ result });
                this.NavigateToDashboard = result.siteAPIName;
                this.NavigateToDashboardapi = result.siteName;
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
        getSiteNameAndAPIName({ pageName: 'Library' })
            .then((result) => {
                console.log({ result });
                this.NavigateToLibrary = result.siteAPIName;
                this.NavigateToLibraryapi = result.siteName;
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });

        getSiteNameAndAPIName({ pageName: 'ProductList' })
            .then((result) => {
                this.prodlstpage = result.siteAPIName;
                this.prodlstpageapi = result.siteName;
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
        getSiteNameAndAPIName({ pageName: 'Librarydetail' })
            .then((result) => {
                this.librarypage = result.siteAPIName;
                this.librarypageapi = result.siteName;
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
    }

    @api
    hidefooter(detaildata) {
        if (detaildata == 'true') {
            this.footer = true;

            // this.template.querySelector('.fixed_cls').style.display = 'block'; 
        } else {
            this.footer = false;
            // this.template.querySelector('.fixed_cls').style.display = 'none'; 
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
        if (pageOffset == 0) {
            // this.footer = true;
            this.footer = false;
        }
    }

    // GET Notification Count
    getnotification() {
        console.log("GET Notification Count");

        getnotificationcount({ userid: USER_ID })
            .then((result) => {
                console.log('<<::::getnotificationcount result::::>>');
                console.log({ result });
                let saved = result.saved;
                let app = result.appointment;
                let act = result.activity;
                let closed = result.closed;

                console.log({ saved });
                console.log({ app });
                console.log({ act });
                console.log({ closed });
                console.log(this.tabname);

                let reddot = this.template.querySelector('.librarytab_cls');
                console.log({ reddot });
                if (reddot != null) {


                    if (saved != 0 && this.tabname != 'Save') {
                        reddot.classList.add('sav');
                    }
                    if (app != 0 && this.tabname != 'Appointment') {
                        reddot.classList.add('app');
                    }
                    if (act != 0 && this.tabname != 'Save') {
                        reddot.classList.add('act');
                    }
                    if (closed != 0) {
                        reddot.classList.add('clo');
                    }
                }
            })
            .catch((error) => {
                console.log('<<::::getnotificationcount error::::>>');
                console.log({ error });
            })
    }

    handleTabClick(event) {
        let buttonClicked = event.target.value;
        switch (buttonClicked) {
            case '1':
                this.tab1Bool = true;
                this.tab2Bool = false;
                this.tab3Bool = false;
                this.tab4Bool = false;
                this.tab5Bool = false;
                break;
            case '2':
                this.tab1Bool = false;
                this.tab2Bool = true;
                this.tab3Bool = false;
                this.tab4Bool = false;
                this.tab5Bool = false;
                break;
            case '3':
                this.tab1Bool = false;
                this.tab2Bool = false;
                this.tab3Bool = true;
                this.tab4Bool = false;
                this.tab5Bool = false;
                break;
            case '4':
                this.tab1Bool = false;
                this.tab2Bool = false;
                this.tab3Bool = false;
                this.tab4Bool = true;
                this.tab5Bool = false;
                break;
            case '5':
                this.tab1Bool = false;
                this.tab2Bool = false;
                this.tab3Bool = false;
                this.tab4Bool = false;
                this.tab5Bool = true;
                break;
        }
        setTimeout(() => {
            let bodydiv = this.template.querySelector(".scrolldiv");
            let bb = bodydiv.scrollHeight;
            let getdiv = this.template.querySelector(".mfrsf");
            let distanceToTop = getdiv.getBoundingClientRect().top;
            let scrolldiv = distanceToTop - bb;
            console.log({ scrolldiv });
            this.dispatchEvent(new CustomEvent('getdetailsdata', { bubbles: true, detail: scrolldiv }));
        }, 1000);

        let reddot = this.template.querySelector('.librarytab_cls');
        console.log({ reddot });


        let labelval;
        if (this.tab1Bool) {
            labelval = 'Activity';
            reddot.classList.remove('act');
        } else if (this.tab2Bool) {
            labelval = 'Saved';
            reddot.classList.remove('sav');
        } else if (this.tab3Bool) {
            labelval = 'Appointments';
            reddot.classList.remove('app');
        } else if (this.tab4Bool) {
            console.log('<<::::Tab4Bool::::>>');
        } else if (this.tab5Bool) {
            labelval = 'Closed';
            reddot.classList.remove('clo');
        } else {
            console.log('<<::::ELSE::::>>');
        }

        console.log({ labelval });
        if (labelval == 'Activity') {
            this.updatenotification(labelval);
            this.updatenotification('');

        } else {
            this.updatenotification(labelval);
        }

        let test = this.template.querySelector('.slds-tabs_default__item');
        console.log({ test });
        test.classList.add('test');

    }

    updatenotification(labelval) {
        updatenotification({ userid: USER_ID, label: labelval, prodId: this.recId })
            .then((result) => {
                console.log('::::RESULT updatenotification::::');
                console.log(labelval);
                console.log(this.productName);
                console.log(this.recId);
                console.log({ result });
                const payload = {
                    operator: labelval,
                    constant: 1
                };


                // publish(this.messageContext, SAMPLEMC, payload);
            })
            .catch((error) => {
                console.log('::::ERROR updatenotification::::');
                console.log({ error });
            })
    }

    pagenationlist(count) {
        console.log('count--' + count);
        this.pagenationlistItems = [];
        for (let i = 1; i <= count; i++) {
            this.pagenationlistItems.push({
                i
            });
        }
        console.log('pagenationlistItems-->' + JSON.stringify(this.pagenationlistItems));
    }

    handlePaginationClick(event) {
        const selectedRecordId = event.target.dataset.id;
        this.page = selectedRecordId;
        //alert(selectedRecordId);
        this.displayRecordPerPage(this.page);
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            console.log('urlStateParameters' + JSON.stringify(this.urlStateParameters));
            this.recId = this.urlStateParameters.recordId;
            console.log('this.recId' + this.recId);
            this.tabname = this.urlStateParameters.tab;
            this.setTabVisibility(this.getTabIndex(this.urlStateParameters.tab));
            console.log('this.tabname' + this.tabname);
        }
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    handlerBookMark(event) {
        const selectedRecordId = event.currentTarget.dataset.id;
        const cname = event.currentTarget.dataset.cname;
        this.catalogId = selectedRecordId;
        this.fireDataLayerEvent('bookmark', '', 'save resource', '', 'detail__c', '/library/detail', cname, this.productName, '', '', '');
        this.insertCatlogAction(this.catalogId);
        this.template.querySelector("c-child-web-component").handleValueChange();
    }

    getcatacount() {
        getCatalogPerProdSaved({ recId: this.recId, userId: USER_ID })
            .then((result) => {
                console.log('<<<::::getCatalogPerProdSaved::::>>>');
                console.log({ result });
                this.totalCount = result.length;
            })
            .catch(error => {
                console.log({ error });
            });
    }

    // added for genrating picklist for mobile view
    mobPickValueandLabels() {
        let savedLabel = 'Saved (' + this.totalCount + ')';
        let appointmentsLabel = 'Appointments (' + this.ApprovedCount + ')';
        let pendingLabel = 'Pending requests (' + this.PendingCount + ')';
        let closedLabel = 'Closed requests (' + this.RejectedCount + ')';

        console.log('savedLabel >>>>>>>>>>>>>>>>>>>>>>>>>', savedLabel);
        this.tabsetOptions = [
            { label: 'Activity', value: 'Activity' },
            { label: savedLabel, value: 'Saved' },
            { label: appointmentsLabel, value: 'Appointments' },
            { label: pendingLabel, value: 'Pending requests' },
            { label: closedLabel, value: 'Closed requests' }
        ];

        this.mobTabvalue = savedLabel;
        let mtbValue = this.tabname;

        if (mtbValue == 'Activity') {
            this.mobTabvalue = 'Activity';
        } else if (mtbValue == 'Saved') {
            this.mobTabvalue = savedLabel;
        } else if (mtbValue == 'Appointment') {
            this.mobTabvalue = appointmentsLabel;
        } else if (mtbValue == 'Request') {
            this.mobTabvalue = pendingLabel;
        } else if (mtbValue == 'Closed') {
            this.mobTabvalue = closedLabel;
        }
    }


    // For Get the Resource data
    @wire(getLibraryCatalogs, { prodId: '$recId', userId: USER_ID, pageSize: '$pageSize', pageNumber: '$pageNumber' })
    wiredgetLibraryCatalogs(value) {

        console.log('===Get Catalog Values===');
        console.log({ value });
        this.catalogListData = value;
        const { data, error } = value;
        if (data != null) {
          if(data.length > 0){
            this.isproducts = true;
            try {
                console.log('Data coming in '+ this.products);
                this.products = data.map(row => ({
                    ...row,
                    isViewInMeeting: row.MSD_CORE_Delivery_Framework__c === 'View in Meeting',
                    isViewImmediately: row.MSD_CORE_Delivery_Framework__c === 'View Immediately',
                    isViewUponRequest: row.MSD_CORE_Delivery_Framework__c === 'View upon Request',
                    isCustomLeaveBehind: row.MSD_CORE_Leave_Behind__c === 'Custom Leave Behind',
                    isStaticLeaveBehind: row.MSD_CORE_Leave_Behind__c === 'Static Leave Behind',
                    isNoLeaveBehind: row.MSD_CORE_Leave_Behind__c === 'No Leave Behind',
                    isExpirationDateIn10Days: this.checkExpirationDateisIn10Days(row.MSD_CORE_Expiration_Date__c),
                    showFormattedDate: this.getFormattedDate(row.MSD_CORE_Expiration_Date__c),

                }));

                console.log('Data loaded '+ this.products);
                this.mobtabredirecton();/*RT 23-03-2023 Bug_Mbl_015*/
                console.log('this.products--->', this.products);
                this.setshortDescription();
                this.showRecordsDetailsLabel(this.products);
                this.productName = data[0].MSD_CORE_Product_Payor__r.Name;
                this.productnameforga = data[0].MSD_CORE_Product_Payor__r.Name;
                console.log('productnameforga-->', this.productnameforga);
                this.productDescription = data[0].MSD_CORE_Product_Payor__r.MSD_CORE_Product_Description__c;
                this.productgeneric = data[0].MSD_CORE_Product_Payor__r.MSD_CORE_Generic_Name__c;
                console.log('productgeneric-->'+this.productgeneric);
                this.aboutProduct = data[0].MSD_CORE_Product_Payor__r.MSD_CORE_Information_About_Product__c;
                this.hcplink = data[0].MSD_CORE_Product_Payor__r.MSD_CORE_HCP_site__c;
                this.pdfDownloadLink = data[0].MSD_CORE_Product_Payor__r.MSD_CORE_Prescribing_Information__c;
                console.log('this.pdfDownloadLink==>', this.pdfDownloadLink);

                if (this.productName) {
                    this.fireOnLoadEvent(this.productName);
                }
            } catch (error) {
                console.log('ERROR IN CATALOG');
                console.log({ error });
            }} else if(data.length === 0 || data.length == 0){
                this.isproducts = false;
            }
        } else if (error) {
            this.isproducts = false;
            console.log('Null');
        }
    }


    // Check Expiration Date is in 10 Days ----------- Ravi Modi
    checkExpirationDateisIn10Days(dateval) {
        if (dateval) {
            let todaysdate = new Date();
            todaysdate.setDate(todaysdate.getDate() + 10);
            /* RM --- 24 Feb 2023 --- Bug_Web_042 */
            let datecheck = todaysdate.getDate();
            if (datecheck <= 9) {
                datecheck = '0' + datecheck;
            } else {
                datecheck = datecheck;
            }
            let formatedate = todaysdate.getFullYear() + '-' + todaysdate.toLocaleString('default', { month: '2-digit' }) + '-' + datecheck;
            return dateval < formatedate;
        } else {
            return false;
        }
    }

    // Return Formatted date ----------- Ravi Modi
    getFormattedDate(dateval) {
        let formattedDate;
        try {
            if (dateval) {
                let getdate = new Date(dateval);
                formattedDate = 'Expires on ' + getdate.toLocaleString('default', { month: 'long' }) + ' ' + getdate.getDate() + ', ' + getdate.getFullYear();
            } else {
                formattedDate = '';
            }
        } catch (error) {
            console.log('ERROR in Formatted Date', { error });
        }
        return formattedDate;
    }

    handlePagination(event) {
        console.log('Handle Pagination');
        console.log({ event });
        console.log('handlePagination', event.detail.pageNo);
        this.pageNumber = event.detail.pageNo;
        console.log('this.pageNumber-->', this.pageNumber);
    }
    handleCustomEvent(event) {
        console.log('Handle CustomEvent');
        console.log({ event });
        console.log('handlePagination library---- ', event.detail);
        this.pageNumber = event.detail;
        console.log('this.pageNumber-->', this.pageNumber);
        document.body.scrollTop = document.documentElement.scrollTop = 0;
        return refreshApex(this.catalogListData);
    }

    handleVisitUrl(event) {
        let linkId = event.currentTarget.dataset.id;
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

    insertCatlogAction(selectedRecordId) {
        console.log(selectedRecordId + '==this.loggedInUserId==' + this.loggedInUserId);
        console.log('122-@@@' + libObject.objectApiName);
        this.catlog = selectedRecordId;
        this.active = true;

        console.log('126-@@@' + libObject.objectApiName);
        const fields = {};
        fields[CATALOG_FIELD.fieldApiName] = this.catlog;
        fields[ACTIVE.fieldApiName] = this.active;
        fields[PAYOR_FIELD.fieldApiName] = this.loggedInUserId;
        console.log('131-@@@' + libObject.objectApiName);
        console.log('132-@@@' + fields);
        const recordInput = { apiName: libObject.objectApiName, fields };
        console.log('134-@@@' + recordInput);
        createRecord(recordInput)
            .then(libraryobj => {
                console.log('id entered1');
                this.libraryId = libraryobj.id;
                console.log('id entered');
                this.products = [];
                console.log('139-completed calling');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Library record has been created',
                        variant: 'success',
                    }),
                );
                this.bookmarkimg = true;
                return refreshApex(this.catalogListData);
            })
            .catch(error => {
                console.log('error');
                eval("$A.get('e.force:refreshView').fire();");
                window.location.reload(true);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            })
            .finally(() => {
                updateRecordView();
                console.log('165-finished update');
            }

            );
    }

    handlerBookMarkRemove(event) {
        const selectedRemovalId = event.currentTarget.dataset.id;
        let cname = event.currentTarget.dataset.cname;
        console.log({ cname });
        this.fireDataLayerEvent('bookmark', '', 'remove resource', '', 'detail__c', '/library/detail', cname, this.productName, '', '', '');
        console.log('loggedInUserId->'+this.loggedInUserId);
        removeCatalogswithParent({ recId: selectedRemovalId, userId: Id })
            .then((result) => {
                console.log('Result in removeCatalogs-->', { result });
                this.products = [];
                this.template.querySelector("c-appointments").refreshevent();

                return refreshApex(this.catalogListData);
            })
            .catch((error) => {
                this.error = error;
                console.log('Error in removeCatalogs-->', { error });
                /* RM --- 24 Feb 2023 --- Bug_Web_042 */
                window.location.reload(true);
            });

        this.bookmarkimg = false;
    }

    showRecordsDetailsLabel(data) {
        this.items = data;
        this.totalRecountCount = data.length;
        this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
        this.pagenationlist(this.totalPage);
        if (this.totalPage === 0) {
            this.page = 0;
        }
        this.data = this.items.slice(0, this.pageSize);
        this.endingRecord = this.pageSize;
        this.error = undefined;
    }

    //previous handler
    previousHandler() {
        console.log('previous click');
        if (this.page > 1) {
            this.page = this.page - 1;
            this.displayRecordPerPage(this.page);
        }
    }

    firstPageHandler() {
        this.page = 1;
        this.displayRecordPerPage(this.page);
    }

    //clicking on next button this method will be called
    nextHandler() {
        console.log('next click');
        if ((this.page < this.totalPage) && this.page !== this.totalPage) {
            if (typeof this.page == 'string') {
                this.page = parseInt(this.page);
            }
            this.page = this.page + 1;
            this.displayRecordPerPage(this.page);
        }
    }

    lastPageHandler() {
        this.page = this.totalPage;
        this.displayRecordPerPage(this.page);
    }

    displayRecordPerPage(page) {
        this.startingRecord = ((page - 1) * this.pageSize);
        this.endingRecord = (this.pageSize * page);

        this.endingRecord = (this.endingRecord > this.totalRecountCount)
            ? this.totalRecountCount : this.endingRecord;

        this.products = this.items.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
    }

    updateRecordView() {
        console.log('updateRecordview called');
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
        }, 100);
    }
    getRequestMappedValue(RequestData) {
        let _requestData = RequestData.map(
            record =>
                Object.assign({
                    "Status": (record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Approved') ? 'Approved'
                        : (record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Pending') ? 'Pending'
                            : (record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Rejected') ? 'Rejected'
                                : (record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Saved') ? 'Saved'
                                    : (record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Closed') ? 'Rejected' : 'NULL'
                },
                    record
                )
        );
        return _requestData;
    }

    // RM --- 23 Feb 2023 --- Bug_Web_036 
    getScheduleappointmentpagedetail() {
        getSiteNameAndAPIName({ pageName: 'Schedule' })
            .then((result) => {
                console.log('Schedule Page -->', { result });
                if (result) {
                    this.scheduelepageapi = result.siteName;
                    this.scheduelepage = result.siteAPIName;
                }
            })
            .catch((error) => {
                console.log('Get Site Name Error-->', { error });
                this.error = error;
            });
    }

    // RM --- 23 Feb 2023 --- Bug_Web_036 
    scheduleClick(event) {
        let prodId = event.currentTarget.dataset.id;
        let cname = event.currentTarget.dataset.cname;
        let urlval = this.scheduelepage + '?recordId=' + prodId + '&page=' + this.page + '&prevPage=librarydetail';
        console.log({ urlval });
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.scheduelepageapi,
                url: urlval
            }
        });

        console.log('event.currentTarget.dataset.btnname-->', event.currentTarget.dataset.btnname);
        if (event.currentTarget.dataset.btnname == 'Schedule appointment') {
            this.fireDataLayerEvent('button', '', 'Schedule Appointment', '', this.scheduelepageapi, this.scheduelepage, cname, this.productName, '', '', '');
        } else {
            this.fireDataLayerEvent('button', '', 'Request access', '', this.scheduelepageapi, this.scheduelepage, cname, this.productName, '', '', '');//RT GA bug
        }
    }

    navigatepage(event) {

        console.log('Navigate');
        console.log({ event });
        let getnameval = event.currentTarget.dataset.name;
        console.log("Get name" + getnameval);
        let brandnm = event.currentTarget.dataset.brand;
        if (getnameval == 'ProductList') {
            this.fireDataClickEvent("button", '', "browse catalog", '', this.prodlstpageapi, this.prodlstpage, brandnm); //RT GA bug
            if (this.prodlstpageapi != undefined || this.prodlstpage != undefined) {
                this[NavigationMixin.Navigate]({
                    // type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: this.prodlstpageapi,
                        url: this.prodlstpage
                    },
                });
            }
        } else if (getnameval == 'Library') {
            if (this.NavigateToLibraryapi != undefined || this.NavigateToLibrary != undefined) {
                this[NavigationMixin.Navigate]({
                    // type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: this.NavigateToLibraryapi,
                        url: this.NavigateToLibrary
                    },
                });
            }
        } else if (getnameval == 'Librarydetail') {
            let recId = event.currentTarget.dataset.id;
            if (this.librarypageapi != undefined || this.librarypage != undefined) {
                this[NavigationMixin.Navigate]({
                    // type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: this.librarypageapi,
                        url: this.librarypage + '?recordId=' + recId
                    }
                });
            }
        } else if (getnameval == 'Dashboard') {
            let recId = event.currentTarget.dataset.id;
            console.log({ recId });
            if (this.NavigateToDashboardapi != undefined || this.NavigateToDashboard != undefined) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        name: this.NavigateToDashboardapi,
                        url: this.NavigateToDashboard + '?recordId=' + recId
                    }
                });
            }
        } else {
            console.log('else');
        }
    }

    setPaginationVisibility() {//Bug_Web_051 by Tausif-Added

        this.showPagination = this.totalCount <= 6 ? false : true;

    }

    handleClick(event) {

        let urlval = event.currentTarget.dataset.name;
        console.log({ urlval });
        let prescheck = event.currentTarget.dataset.check;
        console.log({ prescheck });
        let cname = event.currentTarget.dataset.cname;
        console.log({ cname });

        // ----------- START ----------- E2ESE-911 ----------- Ravi Modi ----------- 12/20/2022
        let catalogId = event.currentTarget.dataset.id;
        console.log({ catalogId });
        let readcheck = event.currentTarget.dataset.read;
        console.log({ readcheck });
        if (readcheck) {
            updateReadCheck({ catalogid: catalogId })
                .then(result => {
                    console.log('Result In updateReadCheck-->', { result });
                    return refreshApex(this.catalogListData);
                })
                .catch(error => {
                    console.log('Error In updateReadCheck-->', { error });
                })
        }
        // ----------- END ----------- E2ESE-911 ----------- Ravi Modi ----------- 12/20/2022


        if (prescheck == 'true') {
            this.fireDataLayerEvent('button', '', 'View resource', '', 'contentconnector', urlval, cname, this.productName, '', '', '');
            window.open(urlval);
        } else if (prescheck == 'false') {
            generateSingedURL({ docurl: urlval })
                .then(result => {
                    console.log({ result });
                    this.fireDataLayerEvent('button', '', 'View resource', '', 'contentconnector', result, cname, this.productName, '', '', '');
                    window.open(result);
                })
                .catch(error => {
                    console.log({ error });
                });
        }
    }

    handleTabClicked(event) {
        if (event.currentTarget.dataset.id != undefined) {
            console.log('event.currentTarget.dataset.name>>>', event.currentTarget.dataset.name);
            if (event.currentTarget.dataset.name == 'saved') {
                this.fireDataLayerEvent("content_switcher", '', 'saved', '', 'detail__c', '/library/detail', '', this.productName, this.totalCount, '', '');
            }
            else if (event.currentTarget.dataset.name == 'appointments') {
                this.fireDataLayerEvent("content_switcher", '', 'appointments', '', 'detail__c', '/library/detail', '', this.productName, '', this.ApprovedCount, '');
            }
            else if (event.currentTarget.dataset.name == 'pending requests') {
                this.fireDataLayerEvent("content_switcher", '', 'pending requests', '', 'detail__c', '/library/detail', '', this.productName, '', '', this.PendingCount);
            }
            else if (event.currentTarget.dataset.name == 'closed requests') {
                this.fireDataLayerEvent("content_switcher", '', 'closed requests', '', 'detail__c', '/library/detail', '', this.productName, '', '', this.RejectedCount);
            } else if (event.currentTarget.dataset.name == 'activity') {
                this.fireDataLayerEvent("content_switcher", '', 'activity', '', 'detail__c', '/library/detail', '', this.productName, '', '', '');
            }
            // this.fireDataLayerEvent( 'content_switcher','',event.currentTarget.dataset.name,'','','', this.productName,'','','');
            let tabName = event.currentTarget.dataset.id
            let tabval = event.currentTarget.dataset.name;
            console.log({ tabval });
            this.template.querySelector(".slds-is-active").className = 'slds-tabs_default__item';
            event.currentTarget.className = 'slds-tabs_default__item slds-is-active';
            console.log('TAB NAME ' + tabName);
            this.setTabVisibility(tabName);
        }
    }
    getTabIndex(tabName) {
        let indexID = 0;
        switch (tabName) {

            case 'Activity':
                indexID = "1";
                this.saveCSS = 'slds-tabs_default__item';
                this.activityCSS = 'slds-tabs_default__item slds-is-active';
                this.appointmentCSS = 'slds-tabs_default__item';
                this.pendingCSS = 'slds-tabs_default__item';
                this.closedCSS = 'slds-tabs_default__item';
                break;
            case 'Saved':
                indexID = "2";
                this.saveCSS = 'slds-tabs_default__item slds-is-active';
                this.activityCSS = 'slds-tabs_default__item';
                this.appointmentCSS = 'slds-tabs_default__item';
                this.pendingCSS = 'slds-tabs_default__item';
                this.closedCSS = 'slds-tabs_default__item';
                break;
            case 'Appointment':
                indexID = "3";
                this.saveCSS = 'slds-tabs_default__item';
                this.activityCSS = 'slds-tabs_default__item';
                this.appointmentCSS = 'slds-tabs_default__item slds-is-active';
                this.pendingCSS = 'slds-tabs_default__item';
                this.closedCSS = 'slds-tabs_default__item';
                break; s
            case 'Request':
                indexID = "4";
                this.saveCSS = 'slds-tabs_default__item';
                this.activityCSS = 'slds-tabs_default__item';
                this.appointmentCSS = 'slds-tabs_default__item';
                this.pendingCSS = 'slds-tabs_default__item slds-is-active';
                this.closedCSS = 'slds-tabs_default__item';
                break;
            case 'Closed':
                indexID = '5';
                this.saveCSS = 'slds-tabs_default__item';
                this.activityCSS = 'slds-tabs_default__item';
                this.appointmentCSS = 'slds-tabs_default__item';
                this.pendingCSS = 'slds-tabs_default__item';
                this.closedCSS = 'slds-tabs_default__item slds-is-active';
                break;
        }
        return indexID;
    }
    setTabVisibility(tabName) {
        switch (tabName) {
            case '1':
                this.tab1Bool = true;
                this.tab2Bool = false;
                this.tab3Bool = false;
                this.tab4Bool = false;
                this.tab5Bool = false;
                break;
            case '2':
                this.tab1Bool = false;
                this.tab2Bool = true;
                this.tab3Bool = false;
                this.tab4Bool = false;
                this.tab5Bool = false;
                break;
            case '3':
                this.tab1Bool = false;
                this.tab2Bool = false;
                this.tab3Bool = true;
                this.tab4Bool = false;
                this.tab5Bool = false;
                break; s
            case '4':
                this.tab1Bool = false;
                this.tab2Bool = false;
                this.tab3Bool = false;
                this.tab4Bool = true;
                this.tab5Bool = false;
                console.log('Request4 ', tabName);
                break;
            case '5':
                this.tab1Bool = false;
                this.tab2Bool = false;
                this.tab3Bool = false;
                this.tab4Bool = false;
                this.tab5Bool = true;
                break;
        }
        setTimeout(() => {
            let bodydiv = this.template.querySelector(".scrolldiv");
            let bb = bodydiv.scrollHeight;
            let getdiv = this.template.querySelector(".mfrsf");
            let distanceToTop = getdiv.getBoundingClientRect().top;
            let scrolldiv = distanceToTop - bb;
            console.log({ scrolldiv });
            this.dispatchEvent(new CustomEvent('getdetailsdata', { bubbles: true, detail: scrolldiv }));
        }, 1000);

        let labelval;
        if (this.tab1Bool) {
            labelval = 'Activity';
        } else if (this.tab2Bool) {
            labelval = 'Saved';
        } else if (this.tab3Bool) {
            labelval = 'Appointments';
        } else if (this.tab4Bool) {
            console.log('<<::::Tab4Bool::::>>');
        } else if (this.tab5Bool) {
            labelval = 'Closed';
        } else {
            console.log('<<::::ELSE::::>>');
        }

        console.log({ labelval });
        if (labelval == 'Activity') {
            this.updatenotification(labelval);
            this.updatenotification('');

        } else {
            this.updatenotification(labelval);
        }
    }

    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, contentname, prdtName, savedcnt, appcnt, pendcnt) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventbrand', {
            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'resources',
                page_purpose: 'product detail',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: linkedtext,
                link_url: linkedurl,
                content_count: '',
                content_saved: savedcnt,
                content_appointments: appcnt,
                content_requests: pendcnt,
                content_name: contentname,
                page_localproductname: prdtName,
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'library detail',
            },
            bubbles: true,
            composed: true
        }));
    }
    // For Read More Functionality
    setshortDescription() {
        let _product = this.products;
        this.products = _product.map(
            record => Object.assign({ "isReadMore": (record.MSD_CORE_Description__c != null && record.MSD_CORE_Description__c != '') ? (record.MSD_CORE_Show_Read_More__c === true && record.MSD_CORE_Description__c.length > higherlimit) ? true : false : false },
                { "shortDescription": (record.MSD_CORE_Description__c != null && record.MSD_CORE_Description__c != '') ? record.MSD_CORE_Description__c.length > higherlimit ? this.doSubstring(record.MSD_CORE_Description__c, 0, higherlimit) : record.MSD_CORE_Description__c : '' },
                { "catalogID": catConstant + record.Id },
                { "catalogDesID": catdescConstant + record.Id },
                record
            )
        );
    }

    // For Read More Functionality
    doSubstring(description, lowerlimit, higherlimit) {
        let _description = description.substring(lowerlimit, higherlimit);
        return _description;
    }

    // For Read More Functionality
    handleReadMore(event) {

        const selectedRecordId = event.currentTarget.dataset.id;
        console.log('selectedRecordId' + selectedRecordId);
        let catID = 'catdesc' + selectedRecordId.substr(3);
        console.log('catID' + catID);

        let newID = '[data-id="' + catID + '"]';
        console.log('newID' + newID);
        let divObj = this.template.querySelector(newID);
        divObj.innerHTML = this.getCatalogDescription(selectedRecordId.substr(3));
        console.log('divObj.innerHTML' + divObj.innerHTML);
        for (let i = 0; i < this.products.length; i++) {
            if (this.products[i]?.catalogID == selectedRecordId) {
                this.products[i].isReadMore = false;
            }

        }

    }

    // For Read More Functionality
    getCatalogDescription(recordID) {
        let _description;
        let _catalogList = this.products;
        _catalogList.forEach(item => {
            if (item.Id == recordID) {
                _description = item.MSD_CORE_Description__c;
            }
        });
        return _description;
    }

    handleLinkClick(event) {
        if(event.currentTarget.dataset.prodname == 'pi.pdf' ) {
            this.fireDataLayerEvent("link", '', event.currentTarget.dataset.prodname, '', event.currentTarget.dataset.prodlabel, event.currentTarget.dataset.prodpath, '', event.currentTarget.dataset.value);// RT GA bug
        }else {
            this.fireDataLayerEvent("link", '', event.currentTarget.dataset.prodlabel, '', event.currentTarget.dataset.prodlabel, event.currentTarget.dataset.prodpath, '', event.currentTarget.dataset.value);// RT GA bug
        }
    }

    fireDataClickEvent(category, action, label, module, linkedtext, linkedurl, prdtname) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'resources',
                page_purpose: 'product resources',
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
                content_name: '', // RT-1053
                page_localproductname: prdtname,
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'library detail',

            },
            bubbles: true,
            composed: true
        }));
    }

    fireOnLoadEvent(prodname) {
        console.log('EVENT TRIGGERED');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                data_design_category: '',
                data_design_action: '',
                data_design_label: '',
                data_design_module: '',
                page_type: 'resources',
                page_purpose: 'product detail',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'detail__c',
                link_url: '/library/detail',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: prodname,
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'library detail',
            },
            bubbles: true,
            composed: true
        }));
    }
}