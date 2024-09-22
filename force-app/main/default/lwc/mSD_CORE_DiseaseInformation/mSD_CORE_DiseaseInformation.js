import { LightningElement, track, api, wire } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader'; 
import {refreshApex} from '@salesforce/apex';

// Static Resource
import banner from '@salesforce/resourceUrl/PurpleBanner';
import bookmarkremove from '@salesforce/resourceUrl/bookmarkSelect';
import bookmarkselect from '@salesforce/resourceUrl/like';
import rarrow from '@salesforce/resourceUrl/rarrow';
import diseaseinfo from '@salesforce/resourceUrl/MSD_CORE_DiseaseInfo';
import USER_ID from '@salesforce/user/Id';

// Apex Class
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import getAllDiseaseInformation from '@salesforce/apex/MSD_CORE_DiseaseInformationController.getAllDiseaseInformation';
import getSavedDiseaseInformation from '@salesforce/apex/MSD_CORE_DiseaseInformationController.getSavedDiseaseInformation';
import createDiseaseLibrary from '@salesforce/apex/MSD_CORE_DiseaseInformationController.createDiseaseLibrary';
import deleteDiseaseLibrary from '@salesforce/apex/MSD_CORE_DiseaseInformationController.deleteDiseaseLibrary';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';

export default class MSD_CORE_DiseaseInformation extends LightningElement {
    
    bannerimg = banner;
    bookmarkselect = bookmarkselect;
    bookmarkremove = bookmarkremove;
    rightarrow = rarrow;
    
    @track siteAPINames;
    @track siteNames;
    @track allresourcetab = "slds-tabs_default__item slds-is-active";
    @track saveresourcetab = "slds-tabs_default__item";
    @track mobilescreen;
    @track searchKey = '';
    @track savedsearchKey = '';
    @track rowLimit = 6;
    @track rowOffSet = 0;
    @track rowSavedOffSet = 0;
    @track diseaseinformationlist;
    @track saveddiseaseinformationlist;
    @track totaldisease;
    @track totalsavedisease;
    @track isloadMore = true;
    @track isSavedloadMore = true;
    @track noresultfound = false;
    @track nosavedresultfound = false;
    @track nodata = false;
    @track nosaveddata = false;
    @track selectedtab = "All";
    @track isLoadCompleted = false;
    @track isSavedLoadCompleted = false;
    @track ctrCounter = 1;
    @track ctrSavedCounter = 1;
    @track isAllDiseaseMobile = true;
    @track selectedTabMobile = 'All';
    @track countertab = 0;
    @track contactrole = '';
    @track diseasesize;

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

    // ConnectedCallback
    connectedCallback() {
        var screenwidth = (window.innerWidth > 0) ? window.innerWidth : screen.width;
        if (screenwidth > 768) {
            this.mobilescreen = false;
        } else {
            this.mobilescreen = true;
        }
        console.log('this.mobilescreen--->',this.mobilescreen);
        this.mobileViewLoad();
        this.resetAllDiseaseTab();
        this.resetSavedDiseaseTab();
        this.loadAllData(true);
        //this.fireOnLoadEvent();
        //this.getAllDiseaseData(true);
				
    }

    loadAllData(isPageLoad){
        console.log('load ALL');
        console.log({isPageLoad});
        if(isPageLoad){
            this.isLoadCompleted = false;
            this.isSavedLoadCompleted = false;
            this.getAllDiseaseData(false);
            this.getSavedDiseaseData(false);
        }else{
            if(this.selectedtab == 'All'){
                if (!isPageLoad && this.ctrCounter == this.totaldisease + 1) {
                    return false;
                }
                this.isLoadCompleted = false;
                this.getAllDiseaseData(false);
            } else{
                if (!isPageLoad && this.ctrSavedCounter == this.totalsavedisease + 1) {
                    return false;
                }
                this.isSavedLoadCompleted = false;
                this.getSavedDiseaseData(false);
            }
        }
    }
    handlegaevent(event){
        let labelname = event.currentTarget.dataset.name;
        this.fireDataLayerEvent('top_nav_breadcrumb','',labelname,'navigation','','','','Home','/');
    }
    resetAllDiseaseTab() {
        this.diseaseinformationlist = [];
        this.isloadMore = true;
        this.rowOffSet = 0;
        this.searchKey = '';
        this.ctrCounter = 1;
    }

    resetSavedDiseaseTab() {
        this.saveddiseaseinformationlist = [];
        this.isSavedloadMore = true;
        this.rowSavedOffSet = 0;
        this.savedsearchKey = '';
        this.ctrSavedCounter = 1;
    }

    getAllDiseaseData(isSearch) {
        getAllDiseaseInformation ({ pageSize: this.rowLimit, offset: this.rowOffSet, searchKey: this.searchKey })
        .then(result => {
            console.log('getAllDiseaseInformation->',result);
            if(isSearch){
                this.diseaseinformationlist = result.diseaselist;
                this.diseasesize = this.diseaseinformationlist.size();
                
            } else {
                let newResult = this.setStyling(result.diseaselist, 'All');
                if (this.diseaseinformationlist == undefined) {
                    this.diseaseinformationlist = [];
                }
                let updatedRecords = [...this.diseaseinformationlist, ...newResult];
                this.diseaseinformationlist = [];
                this.diseaseinformationlist = [...updatedRecords];
            }

            this.totaldisease = result.totaldisease;
            console.log('this.diseaseinformationlist-->',this.diseaseinformationlist);
            console.log('this.totaldisease-->',this.totaldisease);
            console.log('diseasesize>>' , this.diseasesize);
            console.log('diseasesize>>total>>' , this.totaldisease.length);

            if(this.totaldisease == 0){
                this.nodata = true;
            } else {
                this.nodata = false;
                if (this.diseaseinformationlist.length == 0) {
                    this.noresultfound = true;
                } else {
                    this.noresultfound = false;
                }
            }
            if (this.diseaseinformationlist.length == this.totaldisease) {
                this.isloadMore = false;
            }
            this.isLoadCompleted = true;
        })
        .catch(error => {
            console.log('ERROR getAllDiseaseInformation-->', { error });
        })
    }

    getSavedDiseaseData(isSearch) {
        getSavedDiseaseInformation({ pageSize: this.rowLimit, offset: this.rowSavedOffSet, searchKey: this.savedsearchKey })
        .then(result => {
            console.log('getSavedDiseaseInformation->',result);
            if(isSearch){
                this.saveddiseaseinformationlist = result.diseaselist;
            } else {
                let newResult = this.setStyling(result.diseaselist, 'All');
                if (this.saveddiseaseinformationlist == undefined) {
                    this.saveddiseaseinformationlist = [];
                }
                let updatedRecords = [...this.saveddiseaseinformationlist, ...newResult];
                this.saveddiseaseinformationlist = [];
                this.saveddiseaseinformationlist = [...updatedRecords];
            }

            this.totalsavedisease = result.totaldisease;
            console.log('this.saveddiseaseinformationlist-->>',this.saveddiseaseinformationlist);
            console.log('this.totalsavedisease-->>',this.totalsavedisease);

            if(this.totalsavedisease == 0){
                this.nosaveddata = true;
            } else {
                this.nosaveddata = false;
                if (this.saveddiseaseinformationlist.length == 0) {
                    this.nosavedresultfound = true;
                } else {
                    this.nosavedresultfound = false;
                }
            }
            if (this.saveddiseaseinformationlist.length == this.totalsavedisease) {
                this.isSavedloadMore = false;
            }
            this.isSavedLoadCompleted = true;
        })
        .catch(error => {
            console.log('ERROR getSavedDiseaseInformation-->', { error });
        })
    }


    setStyling(diseasedata,tabName) {
        if(tabName == 'All'){
            let _ctrCounter = this.ctrCounter;
            let _alldisease = diseasedata.map(
                record => {
                    const fields = Object.assign(record)
                    _ctrCounter++;
                    return fields
                });
            this.ctrCounter = _ctrCounter;
            return _alldisease;
        } else{
            let _ctrCounter = this.ctrCounterSaved;
            let _savedisease = diseasedata.map(
                record => {
                    const fields = Object.assign({ "cssStyle": this.savedTabCount == 1 ? 'border_cls3 slds-p-vertical_small slds-p-left_medium' : (_ctrCounter == this.savedTabCount) ? 'border_cls2 slds-p-vertical_small slds-p-left_medium' : 'border_cls slds-p-vertical_small slds-p-left_medium' }, record)
                    _ctrCounter++;
                    return fields
                });
            this.ctrSavedCounter = _ctrCounter;
            return _savedisease;
        }
    }

    //renderedCallback
    renderedCallback() {
        Promise.all([
            loadStyle(this, diseaseinfo),
        ]).then(() => {
            console.log('Files loaded');
        })
        .catch(error => {
            console.log(error.body.message);
        });
        this.fireOnLoadEvent();
    }

    // Handle Search
    handleSearch(event) {
        this.searchKey = event.target.value;
        this.rowOffSet = 0;
        this.isloadMore = true;
        this.getAllDiseaseData(true);
        //this.fireDataLayerEvent('search','',this.searchKey,'', '','Disease_Information__c','/disease-information');
    }

    handlegasearch(event){
        this.searchKey = event.target.value;
        this.fireDataLayerEvent('search','',this.searchKey,'', '','','','Disease_Information__c','/disease-information');
    }

    // Handle Search
    handleSavedSearch(event) {
        this.savedsearchKey = event.target.value;
        this.rowSavedOffSet = 0;
        this.isloadMore = true;
        this.getSavedDiseaseData(true);
    }

    // Handle Tab Change
    hanldetabchange(event) {
        try {   
            this.selectedtab = event.target.value;
            let allsearch = this.template.querySelector('.allsearch');
            if (allsearch) {
                allsearch.value = '';
            }
            let savesearch = this.template.querySelector('.savesearch');
            if (savesearch) {
                savesearch.value = '';
            }
            if(this.countertab != 0) {
                this.resetAllDiseaseTab();
                this.resetSavedDiseaseTab();
                this.loadAllData(true);
            }
            this.countertab +=1;
        } catch (error) {
            console.log('hanldetabchange>>>>',{error});   
        }

        let tabval = event.currentTarget.dataset.tabval;
        if(tabval == 'all'){
            this.fireDataLayerEvent('content_switcher','','all resources','', '',this.totaldisease,'','Disease_Information__c','/disease-information');
        }else if (tabval == 'saved'){
            this.fireDataLayerEvent('content_switcher','','saved resources','', '','',this.totalsavedisease,'Disease_Information__c','/disease-information');
        }
        
    }


    // Handle Bookmark Remove
    handlebookmarkremove(event) {
        let contentname = event.currentTarget.dataset.conname;
        let dislibraryid = event.currentTarget.dataset.id;
        let tempdis = JSON.parse(JSON.stringify(this.diseaseinformationlist));
        for(var key in tempdis) {
            if (tempdis[key].Id == dislibraryid) {
                delete tempdis[key].Disease_Info_Librarys__r;
            }
        }
        this.diseaseinformationlist = tempdis;
        let tempsavedis = JSON.parse(JSON.stringify(this.saveddiseaseinformationlist));
        for(var key in tempsavedis) {
            if (tempsavedis[key].MSD_CORE_Disease_Information__c == dislibraryid) {
                tempsavedis.splice(key, 1);
            }
        }
        this.saveddiseaseinformationlist = tempsavedis;
        if(this.saveddiseaseinformationlist.length == 0) {
            this.nosaveddata = true;
        }
        if(dislibraryid){
            deleteDiseaseLibrary({ diseaseid: dislibraryid }) 
            .then(result => {
                console.log('deleteDiseaseLibrary result==>>',result);
                if(result == 'Success') {
                }
            })
            .catch(error => {
                console.log('deleteDiseaseLibrary error==>>',error);
            })
        }
       this.fireDataLayerEvent('bookmark','','remove resource','', contentname,'','','Disease_Information__c','/disease-information'); 
    }

    // Handle Bookmark
    handlebookmark(event) {
        let contentname = event.currentTarget.dataset.conname;
        let disid = event.currentTarget.dataset.id;
        let tempdis = JSON.parse(JSON.stringify(this.diseaseinformationlist));
        for(var key in tempdis) {
            if (tempdis[key].Id == disid) {
                Object.assign(tempdis[key], { Disease_Info_Librarys__r: 'Test', Id: disid});
            }
        }
        this.diseaseinformationlist = tempdis;
        if(disid){
            createDiseaseLibrary({ diseaseid: disid }) 
            .then(result => {
                console.log('createDiseaseLibrary result==>>',result);
                if(result == 'Success') {
                    this.savedsearchKey = '';
                    this.rowSavedOffSet = 0;
                    this.isSavedloadMore = true;
                    this.getSavedDiseaseData(true);
                }
            })
            .catch(error => {
                console.log('createDiseaseLibrary error==>>',error);
            })
        }
    this.fireDataLayerEvent('bookmark','','save resource','', contentname,'','','Disease_Information__c','/disease-information');
    }

    // View Resource
    viewResource(event) {
        let contentname = event.currentTarget.dataset.conname;
        let disurl = event.currentTarget.dataset.url;
        console.log({disurl});
        window.open(disurl,'_blank');
        this.fireDataLayerEvent('button','','view resource','', contentname,'','','Disease_Information__c','/disease-information');
    }

    // Mobile View
    mobileViewLoad() {
        this.tabsetOptions = [
            { label: 'All resources', value: 'All' },
            { label: 'Saved resources', value: 'Saved' },
        ]
    }

    // Mobile View Tab 
    handleMobileTabChange(event) {
        this.selectedtab = event.currentTarget.value;
        if (this.selectedtab == 'All') {
            this.isAllDiseaseMobile = true;
        } else {
            this.isAllDiseaseMobile = false;
        }
        this.mobileViewLoad();
        this.resetAllDiseaseTab();
        this.resetSavedDiseaseTab();
        this.loadAllData(true);
    }

    // Load More Disease Information
    @api
    loadMoreDiseaseInformation(data) {
        if (this.isloadMore && this.isLoadCompleted && this.selectedtab == 'All') {
            if (this.totaldisease != this.rowOffSet) {
                this.rowOffSet = this.rowOffSet + this.rowLimit;
            }
            this.loadAllData(false);
        } 
        if (this.isSavedloadMore && this.isSavedLoadCompleted && this.selectedtab == 'Saved') {
            if (this.totalsavedisease != this.rowSavedOffSet) {
                this.rowSavedOffSet = this.rowSavedOffSet + this.rowLimit;
            }
            this.loadAllData(false);
        }
    }

    // Analytics Events
    fireDataLayerEvent(category, action, label, module, contentname, contentcount, contentsaved, linkedtext, linkedurl) {
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {
          
           detail: {               
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: 'product',
                page_purpose:'product detail',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text:linkedtext,
                link_url:linkedurl,
                content_count: contentcount,
                content_saved: contentsaved,
                content_appointments:'',
                content_requests:'',
                content_name: contentname,
                page_localproductname:'',                
                sfmc_id:USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'disease information',

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
                    page_purpose:'product detail',
                    page_audience: 'payor',
                    page_marketname: 'united_states',
                    page_region: 'us',
                    page_contentclassification: 'non-commercial',
                    link_text:'Disease_Information__c',
                    link_url:'/disease-information',
                    content_saved:'',
                    content_appointments:'',
                    content_requests:'',
                    content_name:'',
                    page_localproductname: '',
                    content_count: this.totaldisease,
                    sfmc_id: USER_ID,
                    sfmc_audience:this.contactrole,
                    page_url: location.href,
                    page_title: 'disease information', 
            },
            bubbles: true,
            composed: true
        }));
    }
}