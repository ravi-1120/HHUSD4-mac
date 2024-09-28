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
import EnterNewName from '@salesforce/label/c.MSD_CORE_HEQ_Enter_New_Name';
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
    @track isSaveButtonDisabled = true;
    @track newSearchName = '';
    @track errorMessage = '';
    @track isViewSavedModalOpen = false;
    @track isDeleteModalOpen = false;
    @track isSaveModalOpen = false
    @track searchToDeleteId;
    @track searchName = '';
    @track isSaveButtonDisabled = true;
    @track selectedFilters = {};
    @track isSidebar = true;
    @track showSpinner = false;
    @track keyword = '';
    @track type = '';
    @track errorMessage = '';
    @track categoryNames = [];
    @api selectedCategoriesArray;
    @api showSaveSearch = false;

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
        EnterNewName,
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

    connectedCallback() {
        this.keyword = this.getUrlParamValue(window.location.href, 'keyword');
        this.type = this.getUrlParamValue(window.location.href, 'type');
        this.categoryList = this.getUrlParamValue(window.location.href, 'category');
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

    @api updateCategories(categoriesIdsUpdated, filteridvalue) {
        this.updatechildCheckbox(filteridvalue, false, this.searchCategory);
        this.updateParentCheckboxes(this.searchCategory);
        let selectedCategories = this.extractChilds(this.searchCategory);
        this.dispatchEvent(new CustomEvent('selectedcategories', {
            detail: selectedCategories,
            bubbles: true,
            composed: true
        }));
        let selectedcategoriesid = this.extractCheckedCategoryNames(this.searchCategory);
        this.dispatchEvent(new CustomEvent('categoriesid', {
            detail: selectedcategoriesid,
            bubbles: true,
            composed: true
        }));
    }

    @api
    clearAllCategory(){
        this.handleClear();
    }

    @api
    loadCheckedCategories(categories) {
        this.updateIsChecked(this.searchCategory, categories);
    }

    @api
    handleSelectedFilters(SelectedFilters) {
        this.selectedFilters = SelectedFilters;
        console.log('### searchCategory ' + JSON.stringify(this.searchCategory));
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
            .then(result => {
                if (result === "Name already used.") {
                    this.errorMessage = result;
                } else {
                    // Find the index of the search to update
                    const searchIndex = this.savedSearches.findIndex(search => search.Id === this.currentSearchId);
                    if (searchIndex !== -1) {
                        this.savedSearches[searchIndex].MSD_CORE_Search_Name__c = this.newSearchName;
                        this.savedSearches = [...this.savedSearches];
                    }
                    this.closeRenameModal();
                    this.loadSavedSearches();
                    this.errorMessage = null;
                }
            })
            .catch(error => {
                this.errorMessage = error.body.message || 'An unexpected error occurred.'; // Set the error message
                console.error('Error renaming saved search:', error);
            });
    }


    handleSaveSearch() {
        const filters = (this.selectedFilters && Object.keys(this.selectedFilters).length > 0)
            ? JSON.stringify(this.selectedFilters)
            : JSON.stringify({
                keyword: this.keyword,
                type: this.type || null
            });

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
        const categoryName = event.currentTarget.dataset.id;
        const isChecked = event.detail.checked;
        const selectedEvent = new CustomEvent('checkboxchange', {
            detail: { isChecked: isChecked },
            bubbles: true,
        });
        this.dispatchEvent(selectedEvent);
        this.updatechildCheckbox(categoryName, isChecked, this.searchCategory);
        this.updateParentCheckboxes(this.searchCategory);
        this.handleFetchData();
    }

    handleFetchData() {
        let selectedcategoriesid = this.extractCheckedCategoryNames(this.searchCategory);
        this.dispatchEvent(new CustomEvent('categoriesid', {
            detail: selectedcategoriesid,
            bubbles: true,
            composed: true
        }));
        let selectedCategories = this.extractChilds(this.searchCategory);
        this.dispatchEvent(new CustomEvent('selectedcategories', {
            detail: selectedCategories,
            bubbles: true,
            composed: true
        }));
    }

    // Select child category Checkbox if user click on parent 
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

    // Use for deselect the parent category checkbox
    updateParentCheckboxes(categories) {
        for (let category of categories) {
            if (category.childCategories && category.childCategories.length > 0) {
                this.updateParentCheckboxes(category.childCategories);

                const allChildrenChecked = category.childCategories.every((child) => child.isChecked);
                const anyChildUnchecked = category.childCategories.some((child) => !child.isChecked);
                if (allChildrenChecked) {
                    category.isChecked = true;
                } else if (anyChildUnchecked) {
                    category.isChecked = false;
                }
            }
        }
        this.searchCategory = [...this.searchCategory];
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

        this.dispatchEvent(new CustomEvent('clearcategories', {
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
                id: category.id,
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
        //this.selectedFilters= null;
        const searchId = event.currentTarget.dataset.id;
        const selectedSearch = this.savedSearches.find(search => search.Id === searchId);
        console.log('selected logs', selectedSearch);

        if (selectedSearch && selectedSearch.MSD_CORE_Selected_Filters__c) {
            const filters = JSON.parse(selectedSearch.MSD_CORE_Selected_Filters__c);
            this.keyword = filters.keyword;
            this.type = filters.type;
        }

        if (selectedSearch) {
            const selectedFilters = selectedSearch.MSD_CORE_Selected_Filters__c;
            this.dispatchEvent(new CustomEvent('getsavedsearch', {
                detail: selectedFilters
            }));

            console.log('detail==>', JSON.stringify(selectedFilters));
            this.isViewSavedModalOpen = false;

            if (selectedFilters) {
                const parsedFilters = JSON.parse(selectedFilters);

                if (parsedFilters.Filters && Object.keys(parsedFilters.Filters).length > 0) {
                    this.handleSubmit();
                } else {
                    this.handleClear();
                }
            }
        }
    }

    handleRenameSavedSearch(event) {
        this.currentSearchId = event.currentTarget.dataset.id;
        this.newSearchName = this.savedSearches.find(search => search.Id === this.currentSearchId).MSD_CORE_Search_Name__c;
        this.isSaveButtonDisabled = !this.newSearchName || this.newSearchName.trim() === '';
        this.openRenameModal();
        console.log('Initial New Search Name:', this.newSearchName);
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
        this.searchName = '';
        this.isSaveButtonDisabled = !this.searchName || this.searchName.trim() === '';
    }

    closeSaveModal() {
        this.isSaveModalOpen = false;
        this.searchName = '';

    }

    handleNameChange(event) {
        this.searchName = event.target.value;
        console.log('this.searchName==>', JSON.stringify(this.searchName));
        this.errorMessage = '';
        this.isSaveButtonDisabled = !this.searchName || this.searchName.trim() === '';
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
        this.isSaveButtonDisabled = true;
    }

    handleNewNameChange(event) {
        console.log('isSaveButtonDisabled', JSON.stringify(this.isSaveButtonDisabled));
        this.newSearchName = event.target.value;
        this.isSaveButtonDisabled = !this.newSearchName || this.newSearchName.trim() === '';
        console.log('this.newSearchName==>', JSON.stringify(this.newSearchName));
        this.errorMessage = '';

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