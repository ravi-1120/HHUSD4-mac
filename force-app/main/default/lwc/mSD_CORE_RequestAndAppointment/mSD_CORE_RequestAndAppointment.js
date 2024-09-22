import { LightningElement, track, wire, api } from 'lwc';
import banner from '@salesforce/resourceUrl/PurpleBanner';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import getRequestsCount from '@salesforce/apex/MSD_CORE_RequestController.getMHEERequestsCount';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import cssfile from '@salesforce/resourceUrl/librarypagecss';
import { CurrentPageReference } from 'lightning/navigation';
import USER_ID from "@salesforce/user/Id";
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';


const requestType = ['Approved', 'Pending', 'Closed'];
export default class MSD_CORE_RequestAndAppointment extends LightningElement {
    bannerimg = banner;
    @track siteNames;
    @track ApprovedCount = 0;
    @track PendingCount = 0;
    @track ClosedCount = 0;
    @track tabsetOptions = [];
    @track tab1Bool = false;
    @track tab2Bool = true;
    @track tab3Bool = false;
      @track tab1CSS = 'slds-tabs_default__item';
      @track tab2CSS ='slds-tabs_default__item slds-is-active';
      @track tab3CSS = 'slds-tabs_default__item';
      @track contactrole = '';

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


    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            if (currentPageReference.state && currentPageReference.state.tab) {
                this.setDefaultTab(currentPageReference.state.tab)
            }
        }
    }

    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log({ data });
        console.log({ error });
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
        }
        if (error) {
            console.log({ error });
        }
    }
    @wire(getRequestsCount, { userid: USER_ID })
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
    getRequestMappedValue(RequestData) {
        let _requestData = RequestData.map(
            record =>
                Object.assign({
                    "Status": (record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Approved') ? 'Approved'
                        : (record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Pending') ? 'Pending'
                            : (record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Closed') ? 'Closed'
                                : (record.MSD_CORE_Status__c != null && record.MSD_CORE_Status__c == 'Rejected') ? 'Closed' : 'NULL'
                },
                    record
                )
        );
        return _requestData;
    }
    setRequestCount(meetingRequestsData) {
        let requests = this.getRequestMappedValue(meetingRequestsData);
        console.log({ requests });
        try {
            requestType.forEach(record => {
                console.log('MEETING REQUEST');
                console.log({ record });
                var results = requests.filter(row => {
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
                else if (record == 'Closed') {
                    results.forEach(record => {
                        this.ClosedCount += parseInt(record.expr0);
                    });
                }
            });
            this.getMobileRequestStatus();

        } catch (error) {
            console.log('exception in setRequestCount ' + error)
        }
    }
    getMobileRequestStatus() {
        let appointmentsLabel = 'Appointments (' + this.ApprovedCount + ')';
        let pendingLabel = 'Pending requests (' + this.PendingCount + ')';
        let closedLabel = 'Closed requests (' + this.ClosedCount + ')';

        this.tabsetOptions = [
            { label: appointmentsLabel, value: 'Appointments' },
            { label: pendingLabel, value: 'Pending requests' },
            { label: closedLabel, value: 'Closed requests' }
        ];
    }
    handlenavigatedashboard(event) {
        this.fireDataLayerEvent("top_nav_breadcrumb",'','dashboard', "navigation",'Home' , 'merckmhee/','','');//RT GA 1122
    }

    handlePickListChange(event) {
        console.log("pick list changed");
        var tabValue = event.currentTarget.value;
        console.log("tab Value ===>" + tabValue);

        
            this.setDefaultTab(tabValue);
    }
    handleTabClick(event) {
        if (event.currentTarget.dataset.id != undefined) {
            let tabName = event.currentTarget.dataset.id
            console.log('TAB NAME ' + tabName);
            this.setTabVisibility(tabName);
        }
        var tabname = event.currentTarget.dataset.name;
        var actcount = event.currentTarget.dataset.count;
        console.log('tabname>>>'+tabname);
        this.fireDataLayerEvent('content_switcher','',tabname,'','RequestAppointment__c' , '/requestappointment' + '?tab=appointment','',actcount);//RT GA 1122
    }
    setTabVisibility(tabName) {
        switch (tabName) {
            case '1':
                this.tab1Bool = true;
                this.tab2Bool = false;
                this.tab3Bool = false;
                this.tab1CSS = 'slds-tabs_default__item slds-is-active';
                this.tab2CSS = 'slds-tabs_default__item';
                this.tab3CSS = 'slds-tabs_default__item';
                break;
            case '2':
                this.tab1Bool = false;
                this.tab2Bool = true;
                this.tab3Bool = false;
                this.tab1CSS = 'slds-tabs_default__item';
                this.tab2CSS = 'slds-tabs_default__item slds-is-active';
                this.tab3CSS = 'slds-tabs_default__item';
                break;
            case '3':
                this.tab1Bool = false;
                this.tab2Bool = false;
                this.tab3Bool = true;
                this.tab1CSS = 'slds-tabs_default__item';
                this.tab2CSS = 'slds-tabs_default__item';
                this.tab3CSS = 'slds-tabs_default__item slds-is-active';
                break;
        }
    }
    connectedCallback() {
        
        console.log('Rendered call back');
        Promise.all([
           // loadStyle(this, cssfile),
        ]).then(() => {
            console.log('Files loaded!!');
        })
            .catch(error => {
                console.log(error.body.message);
            });

            this.fireOnLoadEvent();

            let scrollOptions = {
                left: 0,
                top: 0,
                behavior: 'smooth'
            }
            window.scrollTo(scrollOptions);
    }
    setDefaultTab(tabName) {
        if (tabName == 'Pending requests') {
            this.setTabVisibility('2');
            this.value = 'Pending requests';
        }
        if (tabName == 'Appointments') {
            this.setTabVisibility('1');
            this.value = 'Appointments';
        }
        if (tabName == 'Closed requests') {
            this.setTabVisibility('3');
             this.value = 'Closed requests';
        }
    }
    //Google analytics
    // RT GA bug
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
                        data_design_module:'',       
                        page_type: 'resources',
                        page_purpose:'product resources',
                        page_audience: 'payor',
                        page_marketname: 'united_states',
                        page_region: 'us',
                        page_contentclassification: 'non-commercial',
                        link_text:'RequestAppointment__c',
                        link_url:'/requestappointment',
                        content_saved:'',
                        content_appointments:'',
                        content_requests:'',
                        content_name:'',
                        page_localproductname: '',
                        content_count:'',
                        sfmc_id: USER_ID,
                        sfmc_audience:this.contactrole,
                        page_url: location.href,
                        page_title: 'Requests and Appointments',
            },
            bubbles: true,
            composed: true
        }));
    }
    
    // RT GA bug
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl,contname,contentcount) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {
            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'resources',
                page_purpose: 'product resources', // RT UAT bug
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: linkedtext,
                link_url: linkedurl,
                content_count: contentcount,
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: contname,
                page_localproductname: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'dashboard',
            },
            bubbles: true,
            composed: true
        }));
    }
}