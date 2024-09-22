import { LightningElement, wire, track } from 'lwc';
import getStudyDetails from '@salesforce/apex/MSD_CORE_Pipeline.getStudyDetails';
import dossierresourceimage from '@salesforce/resourceUrl/dossierimage1';
import mheebookmark from '@salesforce/resourceUrl/mheebookmark';
import rightarrowicon from '@salesforce/resourceUrl/mheebookmark';
import leftarrowicon from '@salesforce/resourceUrl/mheebookmark';

export default class MSD_CORE_AMCP_All_Dossiers extends LightningElement {
    @track placeholderText = 'Search';
    @track dossiers = [];
    @track error;
    @track searchKey = '';
    @track therapeuticArea = '';
    @track sortby = 'Name'; // Default sorting
    @track pageSize = 5; // Default page size
    @track offset = 0; // Default offset
    @track resourceType = 'AMCP'; // Default resource type
    @track errorMessage;
    currentPage = 1;
    @track pageItems = [];

    dossierresource = dossierresourceimage; 
    mheebookmark = mheebookmark;
    leftarrowicon = leftarrowicon; 
    rightarrowicon = rightarrowicon;

    @wire(getStudyDetails, {
        searchKey: '$searchKey',
        therapeuticArea: '$therapeuticArea',
        sortBy: '$sortby',
        pageSize: '$pageSize',
        offset: '$offset',
        resourceType: '$resourceType'
    })
    wiredDossiers(result) {
        if (result.data) {
            this.dossiers = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.dossiers = undefined;
            this.error = result.error;
            this.errorMessage = this.extractErrorMessage(this.error);
        }
    }

    extractErrorMessage(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        return 'An unknown error occurred';
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
    }

    handleSort(event) {
        const value = event.target.value;
        const validSortOptions = ['Name', 'MSD_CORE_Therapeutic__c', 'CreatedDate'];
        this.sortby = validSortOptions.includes(value) ? value : 'Name'; // Default to 'Name' if invalid
    }

    resetValue() {
        this.searchKey = '';
        this.therapeuticArea = '';
        this.sortby = 'Name'; 
        this.pageSize = 5; 
        this.offset = 0; 
    }

    get sortoptions() {
        return [
            { label: 'Alphabetical', value: 'Name' },
            { label: 'Therapeutic', value: 'MSD_CORE_Therapeutic__c' },
            { label: 'Most Recent', value: 'CreatedDate' }
        ];
    }

    get showPagination() {
        console.log('this.totalPages:: '+this.totalPages);
        return this.totalPages > 1;
    }

    goToPage(event) {
        const pageNumber = parseInt(event.currentTarget.dataset.pagenumber, 10);
        if (pageNumber >= 1 && pageNumber <= this.totalPages) {
            this.renderPage(pageNumber);
        }
    }


    goToNextPage() {
        if (this.currentPage < this.totalPages) {
            this.renderPage(this.currentPage + 1);
        }
    }
    
    goToPreviousPage() {
        if (this.currentPage > 1) {
            this.renderPage(this.currentPage - 1);
        }
    }

    renderPage(pageNumber) {
        const startIndex = (pageNumber - 1) * this.pageSize;
        const endIndex = Math.min(startIndex + this.pageSize, this.totalItems);
        this.pageItems = this.dossiers.slice(startIndex, endIndex);
        this.currentPage = pageNumber;
    }


    get totalItems() {
        return this.dossiers.length;
    }

    get totalPages() {
        console.log('this.totalItems:: '+this.totalItems);
        console.log('this.pageSize:: '+this.pageSize);
        return Math.ceil(this.totalItems / this.pageSize);
    }

    get pageArray() {
        return Array.from({ length: this.totalPages }, (_, index) => index + 1);
    }
}