import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { createRecord } from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';


import USER_ID from '@salesforce/user/Id';          //User Id

// Apex Method
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';       //Get All Site Value
import getCatalogs from '@salesforce/apex/MSD_CORE_ProductDetail.getCatalogsByOffset';                  //Get Catalog Record
import getProduct from '@salesforce/apex/MSD_CORE_ProductDetail.getproduct';                            //Get Product Record
import getProductfilter from '@salesforce/apex/MSD_CORE_ProductDetail.getproductFilter';                //Get Filter Record
import getCatalogsFilter from '@salesforce/apex/MSD_CORE_ProductDetail.getCatalogsFilter';
import removeCatalogs from '@salesforce/apex/MSD_CORE_ProductDetail.removeCatalogs';
import generateSingedURL from '@salesforce/apex/MSD_CORE_ProductDetail.getcontentconnector';            //get ContentConnector
import updateReadCheck from '@salesforce/apex/MSD_CORE_ProductDetail.updateReadCheck';                  //E2ESE-911

// Static Resource
import banner from '@salesforce/resourceUrl/darkbanner';
import bookmark from '@salesforce/resourceUrl/bookmark';
import hcpicon from '@salesforce/resourceUrl/hcp';
import bookmarkSelect from '@salesforce/resourceUrl/bookmarkSelect';
import like from '@salesforce/resourceUrl/like';
import cal from '@salesforce/resourceUrl/cal';
import rarrow from '@salesforce/resourceUrl/rarrow';
import lockicon from '@salesforce/resourceUrl/MSD_CORE_lock_Icon';
import productDetailCSS from '@salesforce/resourceUrl/productDetailCSS';
import crossmark from '@salesforce/resourceUrl/cross';

// Custom Label
import preinfo from '@salesforce/label/c.PrescribingInformation';       //Label for Prescribing Information
import mediguide from '@salesforce/label/c.MedicationGuide';            //Label for Medical Guide
import hcpsite from '@salesforce/label/c.HCPsite';                      //Label for HCP Site
import patientinfo from '@salesforce/label/c.MSD_CORE_PatientInformation'; //Added by Sabari - : [E2ESE-1770] Patient Information button
import showproductsGenericNamewithBrand from '@salesforce/label/c.showproductsGenericNamewithBrand'; //Added by Sabari - To Show Generic Name with Brand

// Object and Field
import LIBRARY from '@salesforce/schema/MSD_CORE_Library__c';
import ACTIVE from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Active__c';
import CATALOG_FIELD from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Catalog__c';
import PAYOR_FIELD from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Payor__c';
import PRODUCTPAYOR_FIELD from '@salesforce/schema/MSD_CORE_Library__c.MSD_CORE_Product_Payor__c';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import productdetail from '@salesforce/resourceUrl/productdetail';

const higherlimit = 250;
const mobileHigherLimit = 100;
const catConstant = 'cat';
const catdescConstant = 'catdesc';


export default class mfr_productDetails extends NavigationMixin(LightningElement) {

    @track siteApiName;
    @track siteName;
    @track catalog = [];
    @track product = [];
    @track catalogListData;
    @track prodrecId;
    @track optionslst = [];
    @track footer = false;
    @track displayDescflag = false;
    @track descriptions = [];
    @track navigateToProductList;
    @track showheader;
    showPagination;
    showBrandnamewithGenericName = false; // Added by Sabari - To Show Generic Name with Brand
    pageNumber = 1;
    pageSize = 6;
    totalCount;
    startingRecord = 1;         //start record position per page
    endingRecord = 0;           //end record position per page
    totalRecountCount = 0;      //total record count received from all retrieved records
    totalPage = 0;              //total number of page is needed to display all records
    bool = false;
    pagenationlistItems = [];
    @track productName;
    // Images
    presinfo = bookmark;
    hcpimg = hcpicon;
    bookmarkSelect = bookmarkSelect;
    like = like;
    cal = cal;
    rarrow = rarrow;
    lockimage = lockicon;
    accordianClass = 'fixed_cls';
    modalClass = 'slds-modal slds-fade-in-open slds-modal_medium popupmod';
    backdropClass = 'slds-backdrop slds-backdrop_open';

    @track contactrole = '';

    isShowModal = false;
    cross = crossmark;

    // Custom Label
    label = {
        preinfo,
        mediguide,
        hcpsite,
        patientinfo
    }

    // Get Banner Image in Bacground
    get backgroundStyle() {
        return `background-image:url(${banner})`;
    }

    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        const { data, error } = value;
        if (data) {
            this.contactrole = data;
        }
        if (error) {
            console.log({ error });
        }
    }

    // Get Record Id from Parameter
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            var urlStateParameters = currentPageReference.state;
            this.prodrecId = urlStateParameters.recordId;
        }
    }

    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        if (data) {
            this.siteName = data.siteAPINamesdebuglog;
            this.siteApiName = data.siteNames;
            this.navigateToProductList = this.siteName.ProductList;
        }
        if (error) {
            console.log({ error });
        }
    }

    // For Getting the Product detail
    @wire(getProduct, { prodId: '$prodrecId' })
    wiredgetProduct(value) {
        const { data, error } = value;
        if (data) {
            this.product = data;
            if(this.product.Name == 'GARDASIL®9' && this.product.MSD_CORE_Show_Popup__c) {
                this.isShowModal = true;
                this.accordianClass = 'fixed_cls accordn';
                this.modalClass = 'slds-modal slds-fade-in-open slds-modal_medium popupmod mzindex';
                this.backdropClass = 'slds-backdrop slds-backdrop_open bzindex';
            }
        } else if (error) {
            console.log({ error });
        }
    }

    // For Getting Product Filter
    @wire(getProductfilter, { prodId: '$prodrecId' })
    // @wire(getProductfilter, {prodId: 'a8M7X0000004V6BUAU'})
    wiredgetProductfilter(value) {
        const { data, error } = value;
        if (data) {
            for (var i = 0; i < data.length; i++) {
                let option = {
                    //label: data[i].Name,
                    label: data[i].MSD_CORE_description__c,
                    value: data[i].MSD_CORE_description__c,
                    show: true,
                    //description: data[i].description__c,
                    // description: data[i].MSD_CORE_description__c,
                    description: data[i].MSD_CORE_Content_Details__c,
                };
                this.optionslst.push(option);
            }
            if (this.optionslst.length > 0) {
                this.optionlistFlag = true;
            }
        } else if (error) {
            console.log({ error });
        }
    }

    // For Get the Resource data
    @wire(getCatalogs, { prodId: '$prodrecId', userId: USER_ID, pageSize: '$pageSize', pageNumber: '$pageNumber' })
    // @wire(getCatalogs, { prodId: 'a8M7X0000004V6BUAU', userId: '0057X0000049jPGQAY', pageSize: '$pageSize', pageNumber: '$pageNumber' })
    wiredgetCatalogs(value) {
        this.catalogListData = value;
        const { data, error } = value;

        if (data != null) {
            try {
                this.totalCount = data.catalogcount;
                if (this.totalCount <= this.pageSize) {
                    this.showPagination = false;
                } else {
                    this.showPagination = true;
                }
                this.catalog = data.cataloglst.map(row => ({
                    ...row,
                    isComingSoon: row.MSD_CORE_Content_Type__c === 'Coming Soon',
                    isViewInMeeting: row.MSD_CORE_Delivery_Framework__c === 'View in Meeting',
                    isViewImmediately: row.MSD_CORE_Delivery_Framework__c === 'View Immediately',
                    isViewUponRequest: row.MSD_CORE_Delivery_Framework__c === 'View upon Request',
                    isCustomLeaveBehind: row.MSD_CORE_Leave_Behind__c === 'Custom Leave Behind',
                    isStaticLeaveBehind: row.MSD_CORE_Leave_Behind__c === 'Static Leave Behind',
                    isNoLeaveBehind: row.MSD_CORE_Leave_Behind__c === 'No Leave Behind',
                    isExpirationDateIn10Days: this.checkExpirationDateisIn10Days(row.MSD_CORE_Expiration_Date__c),
                    showFormattedDate: this.getFormattedDate(row.MSD_CORE_Expiration_Date__c),
                    cardBgColorCss: row.MSD_CORE_Content_Type__c === 'Coming Soon' ? 'slds-grid slds-wrap slds-p-horizontal_large bg_cls bgwhite' : (row.MSD_CORE_Delivery_Framework__c === 'View Immediately' ? 'slds-grid slds-wrap slds-p-horizontal_large bg_cls bgwhite' : 'slds-grid slds-wrap slds-p-horizontal_large bg_cls bggray'),
                    lcardBgColorCss: row.MSD_CORE_Content_Type__c === 'Coming Soon' ? 'slds-card bgwhite' : (row.MSD_CORE_Delivery_Framework__c === 'View Immediately' ? 'slds-card bgwhite' : 'slds-card bggray'),
                    isHeader: row.MSD_CORE_Content_Type__c === 'Coming Soon' ? (this.showheader = true) : (this.showheader = false),
                    divrunpad: 'slds-var-p-around_x-small shadow_cls',
                })); 
                
                this.setshortDescription();
                this.showRecordsDetailsLabel(this.catalog);
            } catch (error) {
                console.log('ERROR IN CATALOG');
                console.log({ error });
            }
        } else if (error) {
            console.log('Null');
        }
    }

    // Check Expiration Date is in 10 Days ----------- Ravi Modi
    checkExpirationDateisIn10Days(dateval) {
        if (dateval) {
            var todaysdate = new Date();
            todaysdate.setDate(todaysdate.getDate() + 10);
            let datecheck = todaysdate.getDate();
            /* RM --- 23 Feb 2023 --- Bug_Web_042 */
            if(datecheck <=9){
                datecheck = '0'+datecheck;
            } else{
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

    connectedCallback() {
        this.loadCustomCSS();
        sessionStorage.setItem("SelectedValue", false);
    }
    
    loadCustomCSS(){
        Promise.all([
            loadStyle(this, productDetailCSS)
        ]).then(() => {
            console.log('CSS file :productDetailCSS loaded');
        })
        .catch(error => {
            console.log(error.body.message);
        });

    }
    renderedCallback() {
        /* Added by Sabari to add the new line in Catalog description */
        let finddescelements = this.template.querySelectorAll('.updatedesc');
        finddescelements.forEach((element)=>{
            const datavalue = element.getAttribute("data-value");
            element.innerHTML = datavalue;
        });

        /* Added by Sabari - For Keytruda Launch */
        let brandswithGenericName = showproductsGenericNamewithBrand.split(',');
        if(brandswithGenericName.includes(this.product.MSD_CORE_Product_Labeling__c))
        {
            this.showBrandnamewithGenericName = true;
        }

        /* Added by Sabari -MFRUS-95 */
        let finddosageele = this.template.querySelector('.set_dosage');
        if(finddosageele){
            let dosage  = '';
            if (finddosageele.getAttribute("data-value")){
            dosage = finddosageele.getAttribute("data-value").split(" mg/ml").join("&nbsp;mg/ml").split(" mg").join("&nbsp;mg");
            }
            const name = finddosageele.getAttribute("data-name");
            
            if(name+dosage){  
            // Modified by Sabari - To Show Generic Name with Brand
            finddosageele.innerHTML= name != null ? name.trim()+' '+dosage.trim() : dosage.trim();  
            } 
        }

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
            };
        });
        
        if (this.totalCount && this.product) {
            this.fireOnLoadEvent();
        }
    }

    handleproduct() {
        this.fireDataClickEvent("top_nav_breadcrumb", "", 'Products', "navigation", this.siteApiName.ProductList, this.siteName.ProductList, this.product.Name);
    }

    // For Book Mark
    handlerBookMark(event) {
        const selectedRecordId = event.currentTarget.dataset.id;
        this.fireDataLayerEvent('bookmark', '', 'save resource', '', 'productdetail__c', '/product/productdetail', event.currentTarget.dataset.name, this.product.Name);
        const fields = {};
        fields[CATALOG_FIELD.fieldApiName] = selectedRecordId;
        fields[ACTIVE.fieldApiName] = true;
        fields[PAYOR_FIELD.fieldApiName] = USER_ID;
        fields[PRODUCTPAYOR_FIELD.fieldApiName] = this.prodrecId;
        
        const recordInput = { apiName: LIBRARY.objectApiName, fields };
      
        // Add Spinner
        let tempCatslog = JSON.parse(JSON.stringify(this.catalog));
        for (var key in tempCatslog) {
            if (tempCatslog[key].Id == selectedRecordId) {
                Object.assign(tempCatslog[key], { Libraries__r: 'Test' });
            }
        }
        this.catalog = tempCatslog;
        this.bool = true;

        createRecord(recordInput)
            .then(libraryobj => {
                let tempCatslog = JSON.parse(JSON.stringify(this.catalog));
                for (var key in tempCatslog) {
                    if (tempCatslog[key].Id == selectedRecordId) {
                        tempCatslog[key]['Libraries__r'] = selectedRecordId;
                        this.bool = false;
                    }
                }
                this.catalog = tempCatslog;
                
                //to update the saved count value in library of Dashboard Page
                let paramValue = 'FireCount';
                let fireevent = new CustomEvent('productupdate',{detail : selectedRecordId});
                this.dispatchEvent(fireevent);
                // Event Closed
            })
            .catch(error => {
                console.log({ error });
            }
            );
    }

    // Bookmark Remove
    handlerBookMarkRemove(event) {
        this.fireDataLayerEvent('bookmark', '', 'remove resource', '', 'productdetail__c', '/product/productdetail', event.currentTarget.dataset.name, this.product.Name);
        if (this.bool == false) {
            const selectedRemovalId = event.currentTarget.dataset.id;
            let tempCatslog = JSON.parse(JSON.stringify(this.catalog));
            for (var key in tempCatslog) {
                if (tempCatslog[key].Id == selectedRemovalId) {
                    delete tempCatslog[key].Libraries__r;
                }
            }
            this.catalog = tempCatslog;
            removeCatalogs({ recId: selectedRemovalId, userId: USER_ID })
                // removeCatalogs({ recId: selectedRemovalId, userId: '0057X0000049jPGQAY' })
                .then(result => {
                    //to update the saved count value in library of Dashboard Page
                let paramValue = 'FireCount';
                let fireevent = new CustomEvent('productupdate',{detail : selectedRemovalId});
                this.dispatchEvent(fireevent);
                // Event Closed
                })
                .catch(error => {
                    console.log({ error });
                });
        }
    }

    // Handle Option for Specific Product Picklist Value
    handleOptions() {
        let multiSelectPicklist = this.template.querySelector('c-multi-select-picklist-lwc');
        if (multiSelectPicklist) {
            multiSelectPicklist.options = this.optionslst;
        }
    }

    // Call for Keyturda Product only
    onclickDescriptions() {
        //if true
        if (this.displayDescflag == false) {
            this.displayDescflag = true;
        }
        else
            this.displayDescflag = false;
    }

    // Handle Description for Specific Product Picklist Value
    handleDescription(event) {
        let id = event.target.dataset.id;
        for (let i = 0; i < this.descriptions.length; i++) {
            if (this.descriptions[i].label == id) {

                if (this.descriptions[i].show == false) {
                    this.descriptions[i].show = true;
                } else {
                    this.descriptions[i].show = false;
                }
            }
        }
    }

    // Call only for Keyturda Product
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

    // Pagination List
    pagenationlist(count) {
        this.pagenationlistItems = [];
        for (var i = 1; i <= count; i++) {
            this.pagenationlistItems.push({ i });
        }
    }

    //previous handler
    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1;
            this.displayRecordPerPage(this.page);
        }
    }

    // First Page of Products
    firstPageHandler() {
        this.page = 1;
        this.displayRecordPerPage(this.page);
    }

    //clicking on next button this method will be called
    nextHandler() {
        if ((this.page < this.totalPage) && this.page !== this.totalPage) {
            if (typeof this.page == 'string') {
                this.page = parseInt(this.page);
            }
            this.page = this.page + 1;
            this.displayRecordPerPage(this.page);
        }
    }

    // For Last Page of Product
    lastPageHandler() {

        this.page = this.totalPage;
        this.displayRecordPerPage(this.page);
    }

    // Handle Page click
    handlePaginationClick(event) {

        const selectedRecordId = event.target.dataset.id;
        this.page = selectedRecordId;
        this.displayRecordPerPage(this.page);
    }

    // Pagination Display Products per Page
    displayRecordPerPage(page) {

        this.startingRecord = ((page - 1) * this.pageSize);
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = (this.endingRecord > this.totalRecountCount)
            ? this.totalRecountCount : this.endingRecord;
        this.catalog = this.items.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
    }

    handleValueChange(event) {
        this.descriptions = [];

        this.fitlers = event.detail;
        
        if (this.fitlers.length > 0) {
            this.showfilterDisplay = true;
            this.catalogListFilter();
            for (let i = 0; i < this.fitlers.length; i++) {
                let opt = this.optionslst.filter(el => el.label == this.fitlers[i]);
                if (opt[0]) {
                    this.descriptions.push(opt[0]);
                }
            }
        } else {
            this.showfilterDisplay = false;
            this.catalogListFilter();
        }
        this.fireDataLayerEvent('filter', '', this.fitlers, '', 'productdetail__c', '/product/productdetail', '', '');   
    }

    // Catalog Filter data for Specific Product
    catalogListFilter() {
        getCatalogsFilter({ prodId: this.prodrecId, userId: USER_ID, criteria: JSON.stringify(this.fitlers) })
            .then(result => {
                if (result != null) {
                    this.catalog = result.map(row => ({
                        ...row,
                        isViewInMeeting: row.MSD_CORE_Delivery_Framework__c === 'View in Meeting',
                        isViewImmediately: row.MSD_CORE_Delivery_Framework__c === 'View Immediately',
                        isViewUponRequest: row.MSD_CORE_Delivery_Framework__c === 'View upon Request',
                        cardBgColorCss: 'runcardpad',
                        lcardBgColorCss: 'slds-card bggray',
                        divrunpad: 'slds-var-p-around_x-small shadow_cls shdnopad',
                    }));
                } else {
                    this.healthcare = true;
                }
            })
            .catch(error => {
                this.error = error;
            });
    }

    // Pagination
    handleCustomEvent(event) {

        window.scrollTo(0, 0);
        this.pageNumber = event.detail;
    }

    // For scrolling on Accordion
    handleScroll() {
        this.footer = true;
    }

    // Called Content Connector
    handleClick(event) {

        var urlval = event.target.dataset.name;
        var prescheck = event.target.dataset.check;
        this.fireDataLayerEvent('button', '', 'View resource', '', 'contentconnector', prescheck, event.currentTarget.dataset.cname, this.product.Name);

        // ----------- START ----------- E2ESE-911 ----------- Ravi Modi ----------- 12/20/2022
        var catalogId = event.currentTarget.dataset.id;
        var readcheck = event.currentTarget.dataset.read;
        if (readcheck) {
            updateReadCheck({ catalogid: catalogId })
            .then(result => {
                return refreshApex(this.catalogListData);
            })
            .catch(error => {
                console.log('Error In updateReadCheck-->', { error });
            })
        }
        // ----------- END ----------- E2ESE-911 ----------- Ravi Modi ----------- 12/20/2022
        
        if (prescheck == 'true') {
            window.open(urlval);
        } else if (prescheck == 'false') {
            generateSingedURL({ docurl: urlval })
            .then(result => {
                window.open(result);
            })
            .catch(error => {
                console.log({ error });
            });
        }
    }

    handleLinkClick(event) {
        if(event.currentTarget.dataset.prodname == 'pi.pdf' ) {
            this.fireDataLayerEvent("link", '', event.currentTarget.dataset.prodname, '', event.currentTarget.dataset.prodlabel, event.currentTarget.dataset.prodpath, '', event.currentTarget.dataset.value);// RT GA bug
        }else {
            this.fireDataLayerEvent("link", '', event.currentTarget.dataset.prodlabel, '', event.currentTarget.dataset.prodlabel, event.currentTarget.dataset.prodpath, '', event.currentTarget.dataset.value);// RT GA bug
        }
    }

    // On Schedule Appointment button click
    scheduleclk(event) {
        try {
            var prodId = event.currentTarget.dataset.id;
            var urlpath = this.siteName.Schedule+'?recordId='+prodId+'&page='+this.pageNumber+'&prevPage=productdetail&prodid='+this.prodrecId;
            // this.fireDataLayerEvent('button', this.siteName.Schedule, 'Schedule Appointment', '', this.siteApiName.Schedule, this.siteName.Schedule, event.currentTarget.dataset.name, this.product.Name);
            this.fireDataLayerEvent('button', '', event.currentTarget.dataset.btnname, '', this.siteApiName.Schedule, urlpath, event.currentTarget.dataset.cname, event.currentTarget.dataset.pname); //RT UAT bug
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    name: this.siteApiName.Schedule,
                    url: this.siteName.Schedule+'?recordId='+prodId+'&page='+this.pageNumber+'&prevPage=productdetail&prodid='+this.prodrecId
                }
            });
        } catch (error) {
            console.log('ERROR In Schedule00<',{error});       
        }
    }

    setshortDescription() {
        const isMobile = screen.width < 768;
        const limit = isMobile ? mobileHigherLimit : higherlimit;

        this.catalog = this.catalog.map(record => {
            const hasDescription = record.MSD_CORE_Description__c != null && record.MSD_CORE_Description__c !== '';
            const shouldShowReadMore = hasDescription && record.MSD_CORE_Show_Read_More__c === true && record.MSD_CORE_Description__c.length > limit;
            const shortDescription = hasDescription 
                ? (record.MSD_CORE_Description__c.length > limit 
                    ? this.doSubstring(record.MSD_CORE_Description__c, 0, limit) 
                    : record.MSD_CORE_Description__c) 
                : '';

            return {
                ...record,
                isReadMore: shouldShowReadMore,
                shortDescription: shortDescription,
                catalogID: catConstant + record.Id,
                catalogDesID: catdescConstant + record.Id
            };
        });
    }
/*

    // For Read More Functionality
    setshortDescription() {
        let productList = this.catalog;
        this.catalog = productList.map(
            record => Object.assign({ "isReadMore": (record.MSD_CORE_Description__c != null && record.MSD_CORE_Description__c != '') ? (record.MSD_CORE_Show_Read_More__c === true && record.MSD_CORE_Description__c.length > higherlimit) ? true : false : false },
                { "shortDescription": (record.MSD_CORE_Description__c != null && record.MSD_CORE_Description__c != '') ? record.MSD_CORE_Description__c.length > higherlimit ? this.doSubstring(record.MSD_CORE_Description__c, 0, higherlimit) : record.MSD_CORE_Description__c : '' },
                { "catalogID": catConstant + record.Id },
                { "catalogDesID": catdescConstant + record.Id },
                record
            )
        );
    }
*/
    // For Read More Functionality
    doSubstring(description, lowerlimit, higherlimit) {
        let _description = description.substring(lowerlimit, higherlimit);
        return _description;
    }

    // For Read More Functionality
    handleReadMore(event) {
        this.fireDataLayerEvent('link', '', 'read more', '', 'productdetail__c', '/product/productdetail', event.currentTarget.dataset.contname, event.currentTarget.dataset.prodtname); //RT-N-1053
        const selectedRecordId = event.currentTarget.dataset.id;
        let catID = 'catdesc' + selectedRecordId.substr(3);
        let newID = '[data-id="' + catID + '"]';
        let divObj = this.template.querySelector(newID);
        divObj.innerHTML = this.getCatalogDescription(selectedRecordId.substr(3));
    }


    // For Read More Functionality
    getCatalogDescription(recordID) {
        let _description;
        let _catalogList = this.catalog;
        _catalogList.forEach(item => {
            if (item.Id == recordID) {
                _description = item.MSD_CORE_Description__c;
            }
        });
        return _description;
    }

    // For Show and Hide Accordion
    @api
    hidefooter(detaildata) {
        if (detaildata == 'true') {
            sessionStorage.setItem("SelectedValue", false);
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
        if(this.footer){
          sessionStorage.setItem("SelectedValue", false);
        }
    }

    //data
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, resName, prdtName) {

        this.dispatchEvent(new CustomEvent('datalayereventbrandcontent', {
            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'product',
                page_purpose: 'product detail',
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
                page_title: 'product detail',
            },
            bubbles: true,
            composed: true
        }));
    }

    fireDataClickEvent(category, action, label, module, linkedtext, linkedurl, prdtname) {
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {
            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'product',
                page_purpose: 'product detail',
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
                page_title: 'product detail',

            },
            bubbles: true,
            composed: true
        }));
    }

    //Google Analytics Event
    fireOnLoadEvent() {
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                data_design_category: '',
                data_design_action: '',
                data_design_label: '',
                data_design_module: '',
                page_type: 'product',
                page_purpose: 'product detail',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'productdetail__c',
                link_url: '/product/productdetail',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: this.product.Name,
                content_count: this.totalCount,
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'product detail',
            },
            bubbles: true,
            composed: true
        }));
    }

    showModal(event) {
        event.stopPropagation();
        this.isShowModal = true;
    }

    closeModal(event) {
        event.stopPropagation();
        this.isShowModal = false;
    }
}