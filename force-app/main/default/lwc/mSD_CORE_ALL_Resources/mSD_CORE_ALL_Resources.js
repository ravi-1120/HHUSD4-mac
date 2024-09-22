import { LightningElement, track } from 'lwc';
import mheebookmark from '@salesforce/resourceUrl/mheebookmark';
import leftarrowicon from '@salesforce/resourceUrl/leftarrowicon';
import rightarrowicon from '@salesforce/resourceUrl/rightarrowicon';

import getCatalogResources from '@salesforce/apex/MSD_CORE_Pipeline.getPhaseDetail';

export default class MSD_CORE_ALL_Resources extends LightningElement {
    @track resources = [];
    @track pageItems = [];
    placeholderText = '';

    @track searchKey = '';
    @track sortby = 'Name';

    amcpDossiers = false;
    diseaseStateDecks = false;
    pipelineInformation = false;

    @track currentPage = 1;
    @track itemsPerPage = 5;

    mheebookmark = mheebookmark;
    leftarrowicon = leftarrowicon;
    rightarrowicon = rightarrowicon;

    get sortoptions() {
        return [
            { label: 'Alphabatical', value: 'Name' },
            { label: 'Therapeutic', value: 'MSD_CORE_Medical_Therapeutic_Area__r.Name' },
            { label: 'Most recent', value: 'LastModifiedDate' }
        ];
    }

    get totalItems() {
        return this.resources.length;
    }

    get totalPages() {
        return Math.ceil(this.totalItems / this.itemsPerPage);
    }

    get pageArray() {
        const jsonArray = Array.from({ length: this.totalPages }, (_, index) => {
            const number = index + 1;
            return {
                number: index + 1,
                css: number === this.currentPage ? `pagination-button2` : `pagination-button3`,
                text: number === this.currentPage ? `button-text3` : `button-text2`
            };
        });

        return jsonArray;
    }

    get showPagination() {
        return this.totalPages > 1 ? true : false;
    }

    get amcpDossiersCss() {
        return this.amcpDossiers ? 'select5 select4' : 'select5';
    }

    get diseaseStateDecksCss() {
        return this.diseaseStateDecks ? 'select5 select4' : 'select5';
    }

    get pipelineInformationCss() {
        return this.pipelineInformation ? 'select5 select4' : 'select5';
    }

    connectedCallback() {
        this.placeholderText = 'Search';

        this.loadPhaseDetail();
    }

    loadPhaseDetail() {

        getCatalogResources({ searchKey: this.searchKey, sortby: this.sortby })
            .then(result => {
                this.resources = result;

                this.resources.forEach(resource => {
                    let style = '';
                    const bgColor = resource.MSD_CORE_Medical_Therapeutic_Area__r?.MSD_CORE_BG_color__c;
                    if (bgColor !== undefined) {
                        style += 'background-color : ' + bgColor + ' !important;';
                    } 

                    const textColor = resource.MSD_CORE_Medical_Therapeutic_Area__r?.MSD_CORE_Text_color__c;
                    if (textColor !== undefined) {
                        style += 'color : ' + textColor + ' !important;';
                    } 
                    
                    resource['style'] = style;
                });

                this.renderPage(1);
            })
            .catch(error => {

            });
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
        this.resetValue();
        this.loadPhaseDetail();
    }

    resetValue() {
        /*this.PhaseDetail = [];
        this.isloadMore = true;
        this.ctrCounter = 1;
        this.rowOffSet = 0;*/
    }

    handleSort(event) {
        this.sortby = event.target.value;
        this.resetValue();
        this.loadPhaseDetail();
    }

    handleAmcpDossiers() {
        this.amcpDossiers = !this.amcpDossiers;
    }

    handlediseaseStateDecks() {
        this.diseaseStateDecks = !this.diseaseStateDecks;
    }

    handlePipelineInformation() {
        this.pipelineInformation = !this.pipelineInformation;
    }

    openResource(event) {
        let link = event.currentTarget.dataset.link;

        if(link && link.trim().length > 0) {
            window.location.href = '/merckmhee/view-resource?link=' + link;
        }
    }

    goToPage(event) {
        let pageNumber = parseInt(event.currentTarget.dataset.pagenumber);
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
        // Calculate the start and end index for slicing the resources array
        const startIndex = (pageNumber - 1) * this.itemsPerPage;
        const endIndex = Math.min(startIndex + this.itemsPerPage, this.totalItems);
    
        // Get the items for the current page
        this.pageItems = this.resources.slice(startIndex, endIndex);
    
        // Update the current page
        this.currentPage = pageNumber;
    }
}