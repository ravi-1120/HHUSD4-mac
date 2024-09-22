import { LightningElement, track, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';

// 
import USER_ID from '@salesforce/user/Id';
import USERPROFILE_Name from '@salesforce/schema/User.Profile.Name';

// Custom Label
import ViewSaved from '@salesforce/label/c.MSD_CORE_HEQ_View_Saved';
import Close from '@salesforce/label/c.MSD_CORE_Close_Btn';
import SavedSearch from '@salesforce/label/c.MSD_CORE_HEQ_Saved_Search';
import SaveSearch from '@salesforce/label/c.MSD_CORE_HEQ_Save_Search';
import Rename from '@salesforce/label/c.MSD_CORE_HEQ_Rename';
import ConfirmDelete from '@salesforce/label/c.MSD_CORE_Confirm_Delete';
import warningmsg1 from '@salesforce/label/c.MSD_CORE_HEQ_Warning_msg1';
import NewName from '@salesforce/label/c.MSD_CORE_HEQ_New_Name';
import cancel from '@salesforce/label/c.MSD_CORE_Cancel';
import Save from '@salesforce/label/c.MSD_CORE_Save';
import Filter from '@salesforce/label/c.MSD_CORE_HEQ_Filter';
import editName from '@salesforce/label/c.MSD_CORE_HEQ_Edit_Name';
import errormsg from '@salesforce/label/c.MSD_CORE_Name_already_used';
import keywordsearch from '@salesforce/label/c.MSD_CORE_HEQ_KeywordSearch';
import submit from '@salesforce/label/c.MSD_CORE_Submit';
import clearall from '@salesforce/label/c.MSD_CORE_HEQ_ClearAll';
import noresultfound from '@salesforce/label/c.MSD_CORE_HEQ_NoRecordFound';

//Static Resource
import doublelefticon from '@salesforce/resourceUrl/MSD_CORE_HEQ_DoubleLeftOutlined';
import doublerightticon from '@salesforce/resourceUrl/MSD_CORE_HEQ_DoubleRightOutlined';
import editIcon from '@salesforce/resourceUrl/MSD_CORE_HEQ_Edit_icon';
import deleteIcon from '@salesforce/resourceUrl/MSD_CORE_HEQ_Delete_Icon';
import Fontstyle from '@salesforce/resourceUrl/MSD_CORE_HEQ_Save';

// Apex
import getSearchCategory from '@salesforce/apex/MSD_CORE_HEQ_SearchCategoryController.getSearchCategory';
import getSavedSearches from '@salesforce/apex/MSD_CORE_HEQ_SearchCategoryController.getSavedSearches';
import renameSavedSearch from '@salesforce/apex/MSD_CORE_HEQ_SearchCategoryController.renameSavedSearch';
import deleteSavedSearch from '@salesforce/apex/MSD_CORE_HEQ_SearchCategoryController.deleteSavedSearch';
import saveSearch from '@salesforce/apex/MSD_CORE_HEQ_SearchCategoryController.saveSearch';

export default class mSD_CORE_HEQ_SearchCategory extends LightningElement {

    @track searchCategory;
    @track savedSearches = [];
    @track currentSearchId = null;
    @track newSearchName = '';
    @track isRenameModalOpen = false;
    @track isViewSavedModalOpen = false;
    @track isDeleteModalOpen = false;
    @track isSaveModalOpen = false
    @track searchToDeleteId;
    @track searchName = '';
    @track selectedFilters = {};
    @track isSidebar = true;
    @track showSpinner = false;
    @track keyword = '';
    @track errorMessage = '';
    @track categoryNames = [];
    @api selectedCategoriesArray;

    currentUserProfileId;

    lefticon = doublelefticon;
    righticon = doublerightticon;
    editIcon = editIcon;
    deleteIcon = deleteIcon;

    label = {
        ViewSaved,
        Close,
        SavedSearch,
        Rename,
        ConfirmDelete,
        warningmsg1,
        SaveSearch,
        NewName,
        Save,
        cancel,
        Filter,
        editName,
        errormsg,
        keywordsearch,
        submit,
        clearall,
        noresultfound
    }

    get isSaveButtonDisabled() {
        // Disable the button if searchName is empty or null
        return !this.searchName || this.searchName.trim() === '';
    }

    connectedCallback() {
        this.keyword = this.getUrlParamValue(window.location.href, 'keyword');
        this.loadSavedSearches();

        loadStyle(this, Fontstyle)
            .then(() => {
                console.log('Styles loaded successfully');
            })
            .catch(error => {
                console.error('Error loading styles', error);
            });
        this.addEventListener('selectedfiltersupdate', this.handleSelectedFiltersUpdate);
    }

    @api updateCategories(categoriesIdsUpdated) {
        console.log('updateCategories Called ' , JSON.stringify(categoriesIdsUpdated));
        console.log('updateCategories Called ' , JSON.stringify(this.searchCategory));
        // Iterate through the searchCategory array and update `isChecked` for matching categories
        this.searchCategory = this.searchCategory.map(category => ({
            ...category,
            isChecked: categoriesIdsUpdated.includes(category.id), 
            // Set isChecked to true if the category is in the list
            childCategories: category.childCategories.map(child => ({
                ...child,
                isChecked: categoriesIdsUpdated.includes(child.id), 
                // Set isChecked for child categories
                childCategories: child.childCategories.map(grandChild => ({
                    ...grandChild,
                    isChecked: categoriesIdsUpdated.includes(grandChild.id), 
                    // Set isChecked for grandchild categories
                }))
            }))
        }));

        console.log('Updated searchCategory with checked state:', JSON.stringify(this.searchCategory));
    }


    @api
    loadCheckedCategories(categories) {
        this.updateIsChecked(this.searchCategory, categories);
    }

    @api
    handleSelectedFilters(SelectedFilters) {
        this.selectedFilters = SelectedFilters;
        console.log('### searchCategory '+JSON.stringify(this.searchCategory));
    }

    // Get logged in User Profile
    @wire(getRecord, { recordId: USER_ID, fields: [USERPROFILE_Name] })
    userDetails({ error, data }) {
        if (data) {
            console.log('userDetails data>>', data);
            this.currentUserProfileId = data.fields.Profile.displayValue;
            this.getSearchCategory();
        } else if (error) {
            console.log('error>>>', error);
        }
    }

    // Get Search Category Metadata
    getSearchCategory() {
        this.showSpinner = true;
        getSearchCategory({ profile: this.currentUserProfileId })
            .then(result => {
                console.log('getSearchCategory result>>', result);
                this.searchCategory = result.map(category => ({
                    ...category,
                    isOpen: false,
                    selectedcategorycls: 'folder-item ',
                    isChecked: false,
                    isIconVisible: category.childCategories.length == 0 ? false : true,
                    iconName: this.getIconName(category.isOpen),
                    childCategories: category.childCategories.map(child => ({
                        ...child,
                        isOpen: false,
                        isChecked: false,
                        selectedcategorycls: 'folder-item ',
                        iconName: this.getIconName(child.isOpen),
                        isIconVisible: child.childCategories.length == 0 ? false : true,
                        childCategories: child.childCategories.map(grandChild => ({
                            ...grandChild,
                            isOpen: false,
                            selectedcategorycls: 'folder-item ',
                            isChecked: false,
                            isIconVisible: grandChild.childCategories.length == 0 ? false : true,
                            iconName: this.getIconName(grandChild.isOpen)
                        }))
                    }))
                }));
                this.showSpinner = false;
            })
            .catch(error => {
                console.log('error>>', JSON.stringify(error));
                this.showSpinner = false;
            })
    }

    loadSavedSearches() {
        // Get Save Search
        getSavedSearches()
            .then(result => {
                console.log('result of SavedSearches::>>', result);
                this.savedSearches = result;
            })
            .catch(error => {
                console.error('Error retrieving saved searches', error);
            });
    }

    confirmDelete() {
        // delete Save search
        deleteSavedSearch({ searchId: this.searchToDeleteId })
            .then(() => {
                this.savedSearches = this.savedSearches.filter(search => search.Id !== this.searchToDeleteId);
                this.closeDeleteModal();
            })
            .catch(error => {
                console.error('Error deleting saved search', error);
            });
    }

    saveNewName() {
        renameSavedSearch({ searchId: this.currentSearchId, newName: this.newSearchName })
            .then(() => {
                const searchIndex = this.savedSearches.findIndex(search => search.Id === this.currentSearchId);
                if (searchIndex != null && searchIndex != '') {
                    this.savedSearches[searchIndex].Save_Search_Name__c = this.newSearchName;
                    this.savedSearches = [...this.savedSearches];
                }
                this.closeRenameModal();
                this.loadSavedSearches();
            })
            .catch(error => {
                console.error('Error renaming saved search', error);
            });
    }

    handleSaveSearch() {
        const filters = (this.selectedFilters && Object.keys(this.selectedFilters).length > 0)
            ? JSON.stringify(this.selectedFilters)
            : JSON.stringify({ keyword: this.keyword });

        saveSearch({ searchName: this.searchName, selectedFilters: filters })
            .then(result => {
                console.log('Save Search Result:', result);
                if (result == "Name already used.") {
                    this.errorMessage = errormsg;
                } else {
                    this.loadSavedSearches();
                    this.closeSaveModal();
                    console.log('Saved Searches Loaded:', JSON.stringify(this.savedSearches));
                    this.errorMessage = null;
                }
            })
            .catch(error => {
                // Extract and display error message
                this.errorMessage = error.body.message || 'An unexpected error occurred.';
                console.error('Error Saving Search:', error);
                console.log('Error Message:', this.errorMessage);
                // Do not close the modal on error
            });
    }

    updateIsChecked(categories, ref) {
        for (let category of categories) {
            if (ref.includes(category.developerName)) {
                category.isChecked = true;
            } else {
                category.isChecked = false;
            }
            if (category.childCategories.length > 0) {
                this.updateIsChecked(category.childCategories, ref);
            }
        }
    }

    toggleChildCategories(sectionName, categories) {
        for (let category of categories) {
            if (category.id === sectionName) {
                category.isOpen = !category.isOpen;
                category.selectedcategorycls = category.isOpen ? 'folder-item highlightcls' : 'folder-item';
                category.iconName = this.getIconName(category.isOpen);
            } else if (category.childCategories) {
                this.toggleChildCategories(sectionName, category.childCategories);
            }
        }
    }

    handleCheck(event) {
        console.log('handleCheck');
        const categoryName = event.currentTarget.dataset.id;
        console.log('categoryName---->'+JSON.stringify(categoryName));
        const isChecked = event.detail.checked;
        console.log('isChecked----->'+JSON.stringify(isChecked));
        const selectedEvent = new CustomEvent('checkboxchange', {
            detail: { isChecked: isChecked },
            bubbles: true, 
        });
        this.dispatchEvent(selectedEvent);
        this.updatechildCheckbox(categoryName, isChecked, this.searchCategory);
        const updateResult = this.updatechildCheckbox(categoryName, isChecked, this.searchCategory);
        console.log('updateResult----->'+JSON.stringify(updateResult));
        this.updateParentCheckboxes(this.searchCategory);
        const selectedFilter = this.selectedCategoriesArray;
        console.log('selectedFilter----->'+JSON.stringify(selectedFilter));
    }

    updatechildCheckbox(categoryName, isChecked, categories) {
        for (let category of categories) {
            if (category.id === categoryName) {
                category.isChecked = isChecked;
                if (category.childCategories.length > 0) {
                    for (let child of category.childCategories) {
                        child.isChecked = isChecked;
                        if (child.childCategories.length > 0) {
                            for (let grandchild of child.childCategories) {
                                grandchild.isChecked = isChecked;
                            }
                        }
                    }
                }
            } else {
                if (category.childCategories.length > 0) {
                    this.updatechildCheckbox(categoryName, isChecked, category.childCategories);
                }
            }
        }
        this.searchCategory = [...this.searchCategory];
    }

    updateParentCheckboxes(categories) {
        for (let category of categories) {
            if (category.childCategories.length > 0) {
                let allChildrenChecked = true;
                let anyChildChecked = false;
                for (let child of category.childCategories) {
                    if (!child.isChecked) {
                        allChildrenChecked = false;
                    } else {
                        anyChildChecked = true;
                    }
                }
                if (!allChildrenChecked) {
                    category.isChecked = false;
                } else {
                    category.isChecked = true;
                }
                this.updateParentCheckboxes(category.childCategories);
            }
        }
        this.searchCategory = [...this.searchCategory];
    }

    handleSubmit() {
        let selectedcategoriesid = this.extractCheckedCategoryNames(this.searchCategory);
        console.log('selectedcategoriesid----->'+JSON.stringify(selectedcategoriesid));
        this.dispatchEvent(new CustomEvent('categoriesid', {
            detail: selectedcategoriesid,
            bubbles: true,
            composed: true
        }));
        let selectedCategories = this.extractChilds(this.searchCategory);
        console.log('selectedCategories----->'+JSON.stringify(selectedCategories));
        this.dispatchEvent(new CustomEvent('selectedcategories', {
            detail: selectedCategories,
            bubbles: true,
            composed: true
        }));
    }

  

    handleClear() {
        function traverse(categoryList) {
            categoryList.forEach(category => {
                category.isChecked = false;
                if (category.childCategories && category.childCategories.length > 0) {
                    traverse(category.childCategories);
                }
            });
        }
        traverse(this.searchCategory);
        let selectedcategoriesid = this.extractCheckedCategoryNames(this.searchCategory);
        this.dispatchEvent(new CustomEvent('categoriesid', {
            detail: selectedcategoriesid,
            bubbles: true,
            composed: true
        }));
    }

    extractChilds(categories) {
        return categories
            .filter(category => category.isChecked || (category.childCategories && category.childCategories.some(child => this.isAnyChildChecked(child))))
            .map(category => ({
                name: category.name,
                isChecked: category.isChecked,
                id:category.id,
                childCategories: this.extractChilds(category.childCategories)
            }));
    }

    isAnyChildChecked(category) {
        if (category.isChecked) {
            return true;
        }
        if (category.childCategories && category.childCategories.length > 0) {
            return category.childCategories.some(child => this.isAnyChildChecked(child));
        }
        return false;
    }

    extractCheckedCategoryNames(categories) {
        let names = [];
        function traverse(categoryList) {
            categoryList.forEach(category => {
                if (category.isChecked) {
                    names.push(category.id);
                }

                if (category.childCategories && category.childCategories.length > 0) {
                    traverse(category.childCategories);
                }
            });
        }

        traverse(categories);
        return names;
    }

    handleViewSavedSearch(event) {
        const searchId = event.currentTarget.dataset.id;
        const selectedSearch = this.savedSearches.find(search => search.Id === searchId);
        if (selectedSearch) {
            this.dispatchEvent(new CustomEvent('getsavedsearch', {
                detail: selectedSearch.MSD_CORE_Selected_Filters__c
            }));
            this.isViewSavedModalOpen = false;
        }
    }

    handleRenameSavedSearch(event) {
        this.currentSearchId = event.currentTarget.dataset.id;
        this.newSearchName = this.savedSearches.find(search => search.Id === this.currentSearchId).MSD_CORE_Search_Name__c;
        this.openRenameModal();
    }

    toggleSection(event) {
        const sectionName = event.currentTarget.dataset.id;
        this.toggleChildCategories(sectionName, this.searchCategory);
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    getIconName(isOpen) {
        return isOpen ? 'utility:up' : 'utility:down';
    }

    // Saved Search
    openViewSavedModal() {
        this.isViewSavedModalOpen = true;
        this.loadSavedSearches();
    }

    closeViewSavedModal() {
        this.isViewSavedModalOpen = false;
    }

    openSaveSearchModal() {
        this.isSaveModalOpen = true;
        this.errorMessage = null;
    }

    closeSaveModal() {
        this.isSaveModalOpen = false;
        this.searchName = '';

    }

    handleNameChange(event) {
        this.searchName = event.target.value;
    }

    openRenameModal() {
        this.isRenameModalOpen = true;
        this.isViewSavedModalOpen = false;
    }

    handleDeleteSavedSearch(event) {
        const searchId = event.currentTarget.dataset.id;
        this.openDeleteModal(searchId);
    }

    openDeleteModal(searchId) {
        this.searchToDeleteId = searchId;
        this.isDeleteModalOpen = true;
        this.isViewSavedModalOpen = false;
    }

    closeRenameModal() {
        this.isRenameModalOpen = false;
        this.newSearchName = '';
        this.isViewSavedModalOpen = true;
    }

    handleNewNameChange(event) {
        this.newSearchName = event.target.value;
    }

    closeDeleteModal() {
        this.isDeleteModalOpen = false;
        this.isViewSavedModalOpen = true;
    }

    closesidebar() {
        this.isSidebar = false;
        this.sidebarevent();
    }

    opensidebar() {
        this.isSidebar = true;
        this.sidebarevent();
    }

    sidebarevent() {
        this.dispatchEvent(new CustomEvent('expandcollapssidebar', {
            detail: this.isSidebar
        }));
    }
}