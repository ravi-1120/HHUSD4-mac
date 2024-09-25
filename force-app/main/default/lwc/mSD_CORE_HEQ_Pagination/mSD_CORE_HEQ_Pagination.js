import { LightningElement, api, track } from 'lwc';

//Static Resource
import leftarrow from '@salesforce/resourceUrl/MSD_CORE_HEQ_LeftArrow';
import rightarrow from '@salesforce/resourceUrl/MSD_CORE_HEQ_RightArrow';
export default class MSD_CORE_HEQ_Pagination extends LightningElement {

    @api totalRecords;
    @api currentPage;
    @api recordsPerPageOptions;
    @api recordsPerPage;
    @api totalPages;
    @track pageNumbers = [];
    showFirstEllipsis = false;
    showLastEllipsis = false;

    rightarrowicon = rightarrow;
    leftarrowicon = leftarrow;


    connectedCallback() {
        this.updatePaginationValues();
    }

    @api
    updatecurrentpage(page,records,totalpage){
        this.currentPage = page;
        this.totalRecords = records;
        this.totalPages = totalpage;
        this.updatePaginationValues();
    }

    updatePaginationValues() {
        this.pageNumbers = [];
        this.showFirstEllipsis = false;
        this.showLastEllipsis = false;

        if (this.totalPages > 3) {
            this.pageNumbers.push({ number: 1, class: this.getPageClass(1) });
    
            const rangeStart = Math.max(2, this.currentPage - 1);
            const rangeEnd = Math.min(this.totalPages - 1, this.currentPage + 1);
    
            if (rangeStart > 2) {
                this.pageNumbers.push({ number: '...', class: 'pagination-page' });
            }

            for (let i = rangeStart; i <= rangeEnd; i++) {
                this.pageNumbers.push({ number: i, class: this.getPageClass(i) });
            }
            
            if (rangeEnd < this.totalPages - 1) {
                this.pageNumbers.push({ number: '...', class: 'pagination-page' });
            }

            if (this.totalPages > 1) {
                this.pageNumbers.push({ number: this.totalPages, class: this.getPageClass(this.totalPages) });
            }
        } else {
            for (let i = 1; i <= this.totalPages; i++) {
                this.pageNumbers.push({ number: i, class: this.getPageClass(i) });
            }
        }
        this.isPreviousDisabled = this.currentPage === 1;
        this.isNextDisabled = this.currentPage === this.totalPages;    
    }

    getPageClass(page) {
        return page === this.currentPage ? 'pagination-page active' : 'pagination-page';
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginationValues();
            this.dispatchPageChangeEvent();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginationValues();
            this.dispatchPageChangeEvent();
        }
    }

    handlePageClick(event) {
        if (event.target.dataset.page != '...') {
            this.currentPage = parseInt(event.target.dataset.page, 10);
            this.updatePaginationValues();
            this.dispatchPageChangeEvent();
        }
    }

    handleRecordsPerPageChange(event) {
        this.recordsPerPage = parseInt(event.target.value, 10);
        this.updatePaginationValues();
        this.dispatchPageOptionChangeEvent();
    }

    dispatchPageChangeEvent() {
        this.dispatchEvent(new CustomEvent('pagechange', {
            detail: {
                currentPage: this.currentPage,
                recordsPerPage: this.recordsPerPage,
            }
        }));
    }

    dispatchPageOptionChangeEvent() {
        this.dispatchEvent(new CustomEvent('pageoptionchange', {
            detail: {
                currentPage: this.currentPage,
                recordsPerPage: this.recordsPerPage,
            }
        }));
    }

    get recordsPerPageOptionsData() {
        return this.recordsPerPageOptions.map(option => {
            return {
                label: option,
                value: option,
            };
        });
    }
}