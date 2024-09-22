import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import pdsMyRequestcss from '@salesforce/resourceUrl/pdsMyRequestcss';
import USER_ID from "@salesforce/user/Id";
import getRequestPage from '@salesforce/apex/PDS_DashboardController.getRequestPage';
import getPicklistValues from '@salesforce/apex/PDS_CustomLookupController.getPicklistValue';
import filterRequests from '@salesforce/apex/PDS_MyRequestsController.filterRequests';
import getApplicationSettings from '@salesforce/apex/PDS_CustomMetadataHandler.getApplicationSettings';
import myReq from '@salesforce/label/c.PDS_MyRequests';
import back from '@salesforce/label/c.PDS_Back';
import donationDate from '@salesforce/label/c.PDS_DonationDate';
import ngo from '@salesforce/label/c.PDS_NGO';
import vReq from '@salesforce/label/c.PDS_viewReq';
import noResultMsg from '@salesforce/label/c.PDS_NoResults';
import noReqMsg from '@salesforce/label/c.PDS_NoReqMsg';
import search from '@salesforce/label/c.PDS_SearchLabel';
import mmopsearch from '@salesforce/label/c.PDS_MMOP_Search';
import alldonationTypes from '@salesforce/label/c.PDS_AllDonationTypes';
import allStatuses from '@salesforce/label/c.PDS_AllStatuses';
import mmop from '@salesforce/label/c.PDS_MMOP';

export default class PdsMyRequests extends NavigationMixin(LightningElement) {

    @track myrequests;
    @track noresult = false;
    @track searchText = '';
    @track status = '';
    @track statusOptions = [];
    @track donationTypes = []
    appSettings = [];
    @track reqstatus;
    @track pending;
    @track approved;
    @track reviewed;
    @track prodsordered;
    @track closed;
    @track country;
    userId = USER_ID;
    @track isInputsDisabled = false;
    @track isMDPrecType;
    @track isMMOPrecType;
    showSpinner = false;
    @track isMMOP = false;
    @track isMDP = false;
    @track initialLoad = false;
    @track noRecords = false;
    @track searchFilter = false;
    @track currentPage = 1;
    @track paginationRequests = [];
    @track blockEle = true;
    pageSize;
    firstLoad = true;
    label={
      myReq,
      back,
      donationDate,
      ngo,
      vReq,
      noResultMsg,
      noReqMsg,
      search,
      alldonationTypes,
      allStatuses,
      mmop,
      mmopsearch
    };

    async connectedCallback() {
        this.showSpinner = true;
        Promise.all([
            loadStyle(this, pdsMyRequestcss)
        ])
        await this.getPageAccess();
        await this.getApplicationSettingsMethod();
        this.fetchRequests();
        this.fetchStatusPicklistValues();
        
    }

    renderedCallback() {
        if (this.firstLoad) {
            setTimeout(() => {
                this.updateActivePageClass();
            }, 600);
            this.firstLoad = false;
        }
    }

    get searchPlaceholder() {
        if (this.isMDP) {
            return this.label.search;
        } else{
            return this.label.mmopsearch;
        } 
    }
    handleSearch(event) {
        
        this.searchText = event.detail.value;
        this.searchFilter = true;
        this.fetchRequests();
        
    }
    resetSearch() {
        this.template.querySelector('[data-id="search"]').value = '';
        this.searchText = '';
        this.fetchRequests();
        console.log('resetSearch'+this.searchText);
    }

    handleStatusChange(event) {
        this.status = event.detail.value;
        this.fetchRequests();
        this.searchFilter = true;
        console.log('this.status' + this.status);
    }
    handleTypeChange(event) {
        this.type = event.detail.value;
        this.fetchRequests();
        this.searchFilter = true;
        console.log('this.type' + this.type);
    }
    fetchRequests() {
        // this.showSpinner = true;
        console.log('Fetching requests for user: ' + this.userId);
        filterRequests({ userId: this.userId, searchText: this.searchText, status: this.status, dtype: this.type })
            .then(result => {
                console.log('result' + JSON.stringify(result));
                
                this.myrequests = result.map(request => {
                    if (request.RecordType.Name === 'MDP') {
                        request.isMDPrecType = true;
                    } else if (request.RecordType.Name === 'MMOP') {
                        request.isMMOPrecType = true;
                    }
                    if (request.Product_Line_Items__r && request.Product_Line_Items__r.length > 0) {
                        request.country = request.Product_Line_Items__r[0].PDS_Country__c;
                    }
                    request.date = this.formatDate(request.PDS_Request_Submit_Date__c);
                    this.setPropertiesForRequest(request);
                    return request;
                });
                this.initialLoad = true;
                this.noRecords = this.myrequests.length === 0;
                this.error = undefined;
                this.currentPage = 1;
                this.updateDisplayedRequests();
                this.showSpinner = false;
                this.blockEle = false;
            })
            .catch(error => {
                this.error = error;
                console.log('Error fetching requests:', error);
                this.showSpinner = false;
                this.myrequests = [];
                this.initialLoad = true;
                this.noRecords = true;
            });
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        const month = ('' + (date.getMonth() + 1)).slice(-2);
        const day = ('' + date.getDate()).slice(-2);
        const year = date.getFullYear();
        return `${month}/${day}/${year}`;
    }

    setPropertiesForRequest(request) {
        if (request.PDS_Donation_Request_Status__c === 'Pending') {
            request.divlabelStatus = 'pending-cls';
            request.iconlabelStatus = 'pending-icon';
            request.iconName = 'utility:clock';
        } else if (request.PDS_Donation_Request_Status__c === 'Draft') {
            request.divlabelStatus = 'pending-cls';
            request.iconlabelStatus = 'pending-icon';
            request.iconName = 'utility:note';
        } else if (request.PDS_Donation_Request_Status__c === 'Approved' || request.PDS_Donation_Request_Status__c === 'Products Ordered') {
            request.divlabelStatus = 'prod-ordered-cls';
            request.iconlabelStatus = 'prod-ordered-icon';
            request.iconName = 'utility:success';
        } else if (request.PDS_Donation_Request_Status__c === 'Closed') {
            request.divlabelStatus = 'closed-cls';
            request.iconlabelStatus = 'closed-icon';
            request.iconName = 'utility:clear';
        } else if (request.PDS_Donation_Request_Status__c === 'Reviewed') {
            request.divlabelStatus = 'reviewed-cls';
            request.iconlabelStatus = 'reviewed-icon';
            request.iconName = 'utility:preview';
        } else if (request.PDS_Donation_Request_Status__c === 'Need Additional Details') {
            request.divlabelStatus = 'closed-cls';
            request.iconlabelStatus = 'closed-icon';
            request.iconName = 'utility:info_alt';
        }
    }
    get hasData() {
        return this.myrequests && this.myrequests.length > 0;
    }
    get noSearchData() {
        return this.initialLoad && this.searchFilter && this.myrequests.length === 0;
    }

    get hasNoData() {
        return this.initialLoad && this.noRecords && !this.searchFilter;
    }

   doScrolup() {
        document.body.scrollTop = document.documentElement.scrollTop = 0;
    }

    gotoDashboard() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'Home',
                url: '/'
            }
        });
    }

    async getPageAccess() {
        try {
            const data = await getRequestPage({ userid: this.userId });
            if (data) {
                if (data === 'MDP') {
                    this.isMDP = true;
                } else if (data === 'MMOP') {
                    this.isMMOP = true;
                }
            }
        } catch (error) {
            console.error({ error });
        }
    }

    async getApplicationSettingsMethod() {
        try {
            let flowName = (this.isMMOP) ? 'MMOP_Flow_Settings' : 'MDP_Flow_Settings';
            console.log('Result settings ' + JSON.stringify(flowName));
            const data = await getApplicationSettings({ flowDeveloperName: flowName });
            if (data) {
                this.appSettings = data;
                console.log('Result settings ' + JSON.stringify(data));
                this.pageSize = this.appSettings.pds_maximum_pagination_requests__c ?? 10;              
            }
        } catch (error) {
            console.error({ error });
        }
    }

    fetchStatusPicklistValues() {
        getPicklistValues({ objectType: 'PDS_Donation_Request__c', selectedField: 'PDS_Donation_Request_Status__c' })
            .then(data => {
                let status = [{ label: allStatuses, value: '' }];
                data.forEach(statusValue => {
                    if (!(this.isMMOP && statusValue === 'Need Additional Details')) {
                        status.push({
                            label: statusValue,
                            value: statusValue
                        });
                    }
                });
                this.statusOptions = status;
            })
            .catch(error => {
                console.error('Error fetching status picklist values:', error);
            });
    }

    @wire(getPicklistValues, { objectType: 'PDS_Donation_Request__c', selectedField: 'PDS_Donation_Type__c' })
    WiredgettypelistValues({ error, data }) {
        if (data) {
            console.log('Result of donationType-->', JSON.stringify(data));
            let dtypes = [];
            dtypes.push({ label: alldonationTypes, value: '' });
            data = data.filter(dtypeValue => dtypeValue !== 'Humanitarian-On Going');
            data.forEach(dtypeValue => {
                dtypes.push({
                    label: dtypeValue,
                    value: dtypeValue
                });
            });

            this.donationTypes = dtypes;
        } if (error) {
            console.log('ERROR in status-->', { error });
        }
    }


    navigateToDashboard() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'Home',
                url: '/'
            }
        });
    }
    navigateToviewRequest() {
        const requestId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: 'Request_Detail__c',
                url: '/my-requests/request-detail' + '?id=' + requestId
            }
        });
    }

    //Pagination
    get totalPages() {
        return Math.ceil(this.myrequests.length / this.pageSize);
    }

    get shouldPaginate() {
        return this.myrequests.length > this.pageSize;
    }

    get previousButtonClass() {
        return this.currentPage === 1 ? 'disabled' : 'action_button';
    }

    get nextButtonClass() {
        return this.currentPage === this.totalPages ? 'disabled' : 'action_button';
    }

    get pageNumbers() {
        const totalPages = this.totalPages;
        let start = Math.max(this.currentPage - 2, 1);
        let end = Math.min(start + 4, totalPages);

        if (end - start < 4) {
            start = Math.max(1, end - 4);
        }

        const pages = [];
        for (let i = start; i <= end; i++) {
            pages.push(i);
        }
        return pages;
    }

    updateDisplayedRequests() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.paginationRequests = this.myrequests.slice(start, end);
    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updateDisplayedRequests();
            this.updateActivePageClass();
            this.doScrolup();
        }
    }

    previousPage() {
        console.log('Clicked Previous');
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updateDisplayedRequests();
            this.updateActivePageClass();
            this.doScrolup();
        }
    }

    changePage(event) {
        this.currentPage = Number(event.target.dataset.page);
        this.updateDisplayedRequests();
        this.updateActivePageClass();
        this.doScrolup();
    }

    updateActivePageClass() {
        const pageButtons = this.template.querySelectorAll('.page_button');
        pageButtons.forEach(button => {
            const pageNumber = Number(button.dataset.page);
            if (pageNumber === this.currentPage) {
                button.classList.add('active');
            } else {
                button.classList.remove('active');
            }
        });
    }
}