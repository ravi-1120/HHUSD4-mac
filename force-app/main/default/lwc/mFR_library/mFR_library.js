import { LightningElement, wire, track } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import newgetproductlist from '@salesforce/apex/MSD_CORE_ProductList.newgetproductlist';
import getApprovedAppointment from '@salesforce/apex/MSD_CORE_ProductList.getAppointments';
import logo from '@salesforce/resourceUrl/rightarrow2';
//import logo1 from '@salesforce/resourceUrl/Ellipse';
import { NavigationMixin } from 'lightning/navigation';
import getApprovedPending from '@salesforce/apex/MSD_CORE_ProductList.getPending';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import { CurrentPageReference } from 'lightning/navigation';
import overlapcss from '@salesforce/resourceUrl/mfr_overlap';
import warrow from '@salesforce/resourceUrl/whitearrow';
import USER_ID from "@salesforce/user/Id";
import NavigateToDashboard from '@salesforce/label/c.NavigateToDashboard';
import prescribinginfo from '@salesforce/resourceUrl/prescribinginfo';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import getCatalogPerProdSaved from '@salesforce/apex/MSD_CORE_ProductList.getCatalogPerProdSaved';

export default class MFR_library extends NavigationMixin(LightningElement) {

    resarrow = logo;
    //Ellipse = logo1;
    products;
    pageProducts = [];
    savedcon;
    appcon;
    error;
    appointmentCount;
    pendingCount;
    currentPageReference = null;
    urlStateParameters = null;
    prodId;
    roleId;
    warrow = warrow; 
    pageNumber = 1;

    //Tausif Pagination
    totalCount = 0;
    pageSize = 6;
    @track showPagination;
    @track isproduct;
    presinfo = prescribinginfo;
    navigatedashboard;
    @track navigatelibrary;
    @track navigatelibraryname;
    @track navigateproduct;
    @track navigateproductname;
    @track pageNamelist;

    @track productName;

    @track selectedprodname;

    label = {
        NavigateToDashboard
    };

    @track contactrole = '';
    @track savedValue = '';

    //End Pagination
    connectedCallback() {
        // this.contactrole = sessionStorage.getItem('SFMC_Audience');
        this.getproductlist();
        this.getnames();
        this.getproductnames();
    }

    //Added to get saved count
    handleRescount(event) {
        this.savedValue = event.detail;
        console.log('this.savedValue>>', this.savedValue);
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

    getnames() {
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

    @wire(getSiteNameAndAPIName, { pageName: 'Dashboard' })
    wiredgetSiteNameAndAPIName(value) {
        console.log('Wired Count');
        console.log(value);
        const { data, error } = value;
        if (data) {
            console.log('apiname' + data.siteAPIName)
            this.navigatedashboard = data.siteAPIName;
        } else if (error) {
            this.error = error;
            console.log('error in getSiteNameAndAPIName ' + JSON.stringify(this.error));
        }
        console.log(this.data);
        console.log(this.navigatedashboard);
        console.log(this.data.siteAPIName);
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, overlapcss)
        ]).then(() => {
        })
            .catch(error => {
                console.log(error.body.message);
            });

    }

    handledashboard() {
        this.fireDataClickEvent("top_nav_breadcrumb", '', 'Dashboard', 'navigation', 'Home', this.navigatedashboard, '');
    }
    // GET All Product from Product Payor
    getproductlist() {
        newgetproductlist({ userId: USER_ID })
            .then((result) => {
                console.log('Get Product List-->', { result });
                this.products = result.condata;
                this.productName = result.condata[0].Name;
                this.fireOnLoadEvent();
                //Tausif             
                this.totalCount = 0; //this.products.length;
                if(this.products.length > 0){
                    this.isproduct = true;

                    for(var i=0; i < this.products.length; i++) {
                        if(this.products[i].Libraries__r != undefined) {
                            this.totalCount ++;
                        }
                        else if(this.products[i].Meeting_Requests__r != undefined) {
                            this.totalCount ++;
                        }
                    }

                    console.log('products count is '+this.totalCount);
                    if (this.totalCount <= this.pageSize) {
                        this.showPagination = false;
                    } else {
                        this.showPagination = true;
                    }
                } else if(this.products.length === 0){
                    this.isproduct = false;
                    this.showPagination = false;
                }
                //End Tausif

                this.savedcon = result.savedcount;
                if (this.savedcon == 0) {
                    this.isData = false;
                    this.isproduct = false;
                } else {
                    this.isData = true;
                    this.isproduct = true;
                }

                if(this.showPagination) {
                    for(var i = 0; i < this.pageSize; i++) {
                        this.pageProducts.push(this.products[i]);
                    }
                }
                else {
                    this.pageProducts = this.products;
                }
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }

    getAppointmentsPerProduct(productId) {
        console.log('get Appointments 123');
        var count = 0;
        getApprovedAppointment({ recId: productId, userId: USER_ID })
            .then((result) => {
                console.log('GET Appointments---' + JSON.stringify(result));
                console.log('GET Appointments SIZE---' + result.length);
                this.appointmentCount = result.length;
                count = this.appointmentCount;
                this.count = this.result.length;
                console.log('this.count',this.count );
                console.log('this.appointmentCountt',this.appointmentCount );
                this.appcon = result.appcount;
                if (this.appcon == 0) {
                    this.isData = false;
                } else {
                    this.isData = true;
                }
                return count;
            })
            .catch((error) => {
                console.log(' Error in Get Appointments' + JSON.stringify(error));
                this.error = error;
            });
    }
    getPendingPerProduct(productId) {
        console.log('get Pending 123');
        var count = 0;
        getApprovedPending({ recId: productId, userId: USER_ID })
            .then((result) => {
                console.log('GET Pending---' + JSON.stringify(result));
                console.log('GET Pending SIZE---' + result.length);
                // this.pendingCount = result.length;
                count = result.length;
                if (this.count == 0) {
                    this.isData = false;
                } else {
                    this.isData = true;
                }
                // this.products = result;
                // this.products = result.condata;
                // this.savedcon = result.savedcount;
                //console.log('this.products==>',this.products);
            })
            .catch((error) => {
                console.log(' Error in Get Pending' + JSON.stringify(error));
                this.error = error;
            });
        return count;
    }

    navigate(event) {

        console.log('navigate : ', { event });
        var prodId = event.currentTarget.dataset.id;
        console.log({ prodId });
        console.log('this.navigatelibraryname : ', this.navigatelibraryname);
        this.selectedprodname = event.currentTarget.dataset.prodname;
        if (this.navigatelibraryname != undefined || this.navigatelibrary != undefined) {
            this.fireDataLayerEvent('button', '', 'view activity', '', this.navigatelibraryname, this.navigatelibrary, '', '', '');
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                // attributes: {
                //     name: this.navigatelibraryname,
                //     url: this.navigatelibrary
                // },
                // state: {
                //     recordId: prodId,
                //     tab: 'Activity'
                // }
                type: 'standard__webPage',
                attributes: {
                    name: this.navigatelibraryname,
                    url: this.navigatelibrary + '?recordId=' + prodId + '&tab=Activity'
                }
            });
        }
    }

    navigatepage(event) {

        console.log({ event });
        var getnameval = event.currentTarget.dataset.name;

        console.log("Get name" + getnameval);
        console.log("Get name1" + this.navigateproductname);
        console.log("Get name2" + this.navigateproduct);

        if (getnameval == 'ProductList') {
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                    name: this.navigateproductname,
                    url: this.navigateproduct
                },
            });
        }
    }


    handleGAEventSaved(event) {
        console.log('handleGAEventSaved==>', { event });
        this.fireDataLayerEvent('button', '', 'view resources', '', this.navigatelibraryname, this.navigatelibrary, event.detail, '', '');
    }
    handleGAEventApp(event) {
        this.fireDataLayerEvent('button', '', 'view appointments', '', this.navigatelibraryname, this.navigatelibrary, '', event.detail, '');
    }
    handleGAEventReq(event) {
        this.fireDataLayerEvent('button', '', 'view request', '', this.navigatelibraryname, this.navigatelibrary, '', '', event.detail);
    }

    redirectpage(event) {
        var prodname = event.currentTarget.dataset.name;
        console.log({ prodname });

        this.selectedprodname = event.currentTarget.dataset.prodname;
        console.log('selectedprodname-->' + this.selectedprodname);
        var prodId;
        var tabname;
        if (prodname == 'Save') {
            prodId = event.currentTarget.dataset.id;
            tabname = 'Save';
            let mfrres = this.template.querySelectorAll('c-mfrproduct-res-count');
            if (mfrres) {
                for (var key in mfrres) {
                    if (mfrres[key].product == prodId) {
                        mfrres[key].callGoogleEvent();
                    }
                }
            }
            console.log({ event });
        } else if (prodname == 'Request') {
            prodId = event.currentTarget.dataset.id;
            tabname = 'Request';
            let mfrres = this.template.querySelectorAll('c-mfr-pendingcount');
            if (mfrres) {
                for (var key in mfrres) {
                    if (mfrres[key].product == prodId) {
                        mfrres[key].callGoogleEvent();
                    }
                }
            }
            console.log({ event });
        } else if (prodname == 'Appointment') {
            prodId = event.currentTarget.dataset.id;
            tabname = 'Appointment';
            let mfrres = this.template.querySelectorAll('c-mfr-appointmentcount');
            if (mfrres) {
                for (var key in mfrres) {
                    if (mfrres[key].product == prodId) {
                        mfrres[key].callGoogleEvent();
                    }
                }
            }
            console.log({ event });
        } else if (prodname == 'Pending') {
            prodId = event.currentTarget.dataset.id;
            tabname = 'Pending';

            let mfrres = this.template.querySelectorAll('c-mfr-pendingcount');
            if (mfrres) {
                for (var key in mfrres) {
                    if (mfrres[key].product == prodId) {
                        mfrres[key].callGoogleEvent();
                    }
                }
            }
            console.log({ event });
        }

        if (this.navigatelibraryname != undefined || this.navigatelibrary != undefined) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    name: this.navigatelibraryname,
                    url: this.navigatelibrary + '?recordId=' + prodId + '&tab=' + tabname
                }
            });
        }
    }

    handlePreInfo(event) {
        this.fireDataClickEvent("link", '', event.currentTarget.dataset.prodlabel, '', event.currentTarget.dataset.urltext, event.currentTarget.dataset.prodpath, event.currentTarget.dataset.prodname);
    }

    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, countsave, countappo, countreq) {
        console.log('event triggered');
        try {
            this.dispatchEvent(new CustomEvent('datalayerevent', {
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
                    content_saved: countsave,
                    content_appointments: countappo,
                    content_requests: countreq,
                    content_name: '',
                    page_localproductname: this.selectedprodname,//this.productName,
                    sfmc_id: USER_ID,
                    sfmc_audience: this.contactrole,
                    page_url: location.href,
                    page_title: 'library',
                },
                bubbles: true,
                composed: true
            }));
        } catch (error) {
            console.log('ERROR IN FIre EVENT-->', { error });
        }
    }

    fireOnLoadEvent() {
        console.log('EVENT TRIGGERED');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                data_design_category: '',
                data_design_action: '',
                data_design_label: '',
                data_design_module: '',
                page_type: 'resources',
                page_purpose: 'product resources',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'library__c',
                link_url: '/library',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: this.productName,
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'library',
            },
            bubbles: true,
            composed: true
        }));
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
                content_name: '',
                page_localproductname: prdtname,
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'library',
            },
            bubbles: true,
            composed: true
        }));
    }

    handleCustomEvent(event) {
        this.pageProducts = [];
        this.pageNumber = event.detail;
        var endCount = (this.pageNumber * this.pageSize);
        if(this.totalCount < endCount) {
            endCount = this.totalCount;
        }
        var startCount = ((this.pageNumber -1) * this.pageSize);
        for(var i = startCount; i < endCount; i++) {
            this.pageProducts.push(this.products[i]);
        }
    }
    handleLinkClick(event) {
        if(event.currentTarget.dataset.prodname == 'pi.pdf' ) {
            this.fireDataLayerEvent("link", '', event.currentTarget.dataset.prodname, '', event.currentTarget.dataset.prodlabel, event.currentTarget.dataset.prodpath, '', event.currentTarget.dataset.value);// RT GA bug
        }else {
            this.fireDataLayerEvent("link", '', event.currentTarget.dataset.prodlabel, '', event.currentTarget.dataset.prodlabel, event.currentTarget.dataset.prodpath, '', event.currentTarget.dataset.value);// RT GA bug
        }
    }
}