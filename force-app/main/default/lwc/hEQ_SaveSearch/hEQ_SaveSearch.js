import { LightningElement, track, wire, api } from 'lwc';
import saveSearch from '@salesforce/apex/HEQ_SearchCategoryController.saveSearch';
import getSavedSearches from '@salesforce/apex/HEQ_SearchCategoryController.getSavedSearches';
import deleteSavedSearch from '@salesforce/apex/HEQ_SearchCategoryController.deleteSavedSearch';
import renameSavedSearch from '@salesforce/apex/HEQ_SearchCategoryController.renameSavedSearch';

export default class HEQ_SaveSearch extends LightningElement {
    @track searchName = '';
    @track savedSearches = [];
    @track isSaveModalOpen = false;
    @track isViewSavedModalOpen = false;
    @track isDeleteModalOpen = false;
    @track isRenameModalOpen = false;
    @track newSearchName = '';
    @track currentSearchId = null;
    @track selectedFilters = {};
    @track keyword = '';

        connectedCallback() {
            this.keyword = this.getUrlParamValue(window.location.href, 'keyword');
        this.loadSavedSearches();
    }
    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    
    loadSavedSearches() {
        console.log('Loading saved searches...');
        getSavedSearches()
            .then(result => {
                this.savedSearches = result;
                console.log('this.saved searches in', JSON.stringify(this.savedSearches));
            })
            .catch(error => {
                console.error('Error retrieving saved searches', error);
            });
    }


    handleNameChange(event) {
        this.searchName = event.target.value;
    }

    handleNewNameChange(event) {
        this.newSearchName = event.target.value;
    }

    openSaveSearchModal() {
        this.isSaveModalOpen = true;
    }

    closeSaveModal() {
        this.isSaveModalOpen = false;
        this.searchName = '';
    }

    openViewSavedModal() {
        this.isViewSavedModalOpen = true;
         this.loadSavedSearches();
    }

    closeViewSavedModal() {
        this.isViewSavedModalOpen = false;
    }

    openRenameModal() {
        this.isRenameModalOpen = true;
    }

    closeRenameModal() {
        this.isRenameModalOpen = false;
        this.newSearchName = '';
    }

    openDeleteModal(searchId) {
        this.searchToDeleteId = searchId;
        this.isDeleteModalOpen = true;
    }

    closeDeleteModal() {
        this.isDeleteModalOpen = false;
    }

    confirmDelete() {
        deleteSavedSearch({ searchId: this.searchToDeleteId })
            .then(() => {
                this.savedSearches = this.savedSearches.filter(search => search.Id !== this.searchToDeleteId);
                this.closeDeleteModal();
            })
            .catch(error => {
                console.error('Error deleting saved search', error);
            });
    }

    handleViewSavedSearch(event) {
        console.log('handleViewSavedSearch');
        const searchId = event.currentTarget.dataset.id;
        const selectedSearch = this.savedSearches.find(search => search.Id === searchId);
        if (selectedSearch) {
            // this.dispatchEvent(new CustomEvent('applysearch', {
            //     detail: {
            //         filters: JSON.parse(selectedSearch.SelectedFilters__c),
            //         keywords: selectedSearch.Keywords__c
            //     }
            // }));
            this.template.querySelector('c-h-e-q_-view-all-resources').handleSavedSearch(selectedSearch.HEQ_Selected_Filters__c);
            this.isViewSavedModalOpen = false;
        }
    }

    handleDeleteSavedSearch(event) {
        const searchId = event.currentTarget.dataset.id;
        this.openDeleteModal(searchId);
    }

   handleRenameSavedSearch(event) {
        this.currentSearchId = event.currentTarget.dataset.id;
        this.newSearchName = this.savedSearches.find(search => search.Id === this.currentSearchId).Save_Search_Name__c;
        this.openRenameModal();
    }

    saveNewName() {
        renameSavedSearch({ searchId: this.currentSearchId, newName: this.newSearchName })
            .then(() => {
                const searchIndex = this.savedSearches.findIndex(search => search.Id === this.currentSearchId);
                if (searchIndex != null && searchIndex !='') {
                    this.savedSearches[searchIndex].Save_Search_Name__c = this.newSearchName;
                    this.savedSearches = [...this.savedSearches];
                }
                this.closeRenameModal();
                this.loadSavedSearches();
                console.log('closeRenamemodal called',closeRenameModal);
            })
            .catch(error => {
                console.error('Error renaming saved search', error);
            });
    }

    handleSaveSearch() {
        try {
            const filters = (this.selectedFilters && Object.keys(this.selectedFilters).length > 0) 
            ? JSON.stringify(this.selectedFilters) 
            : JSON.stringify({ keyword: this.keyword });
            
            saveSearch({
                searchName: this.searchName,
                selectedFilters: filters
            })
                .then(() => {
                    this.loadSavedSearches();
                    this.closeSaveModal();
                    console.log('savedSearches console', JSON.stringify(this.savedSearches));
                })
                .catch(error => {
                    console.error('Error saving search', error);
                });
        } catch (error) {
            console.error('An error occurred in saving the record');
            this.handleError(error);
        }
    }

    handleSelectedFilters(event) {
        this.selectedFilters = event.detail;
        console.log('Received selectedFilters:', JSON.stringify(this.selectedFilters));
    }
}