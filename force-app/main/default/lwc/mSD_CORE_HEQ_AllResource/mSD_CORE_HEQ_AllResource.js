import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Apex Method
import fetchResources from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.fetchResources';
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';
import fetchResourcesFromSavedSearch from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.fetchResourcesFromSavedSearch';
import saveResourcesInCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.saveResourcesInCollection';
import getCollectionList from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getCollectionList';

//Custom Labels
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
import home from '@salesforce/label/c.MSD_CORE_HEQ_Home';
import recordsperpage from '@salesforce/label/c.MSD_CORE_HEQ_AllResourceRecordPerPage';
import recordperpageoption from '@salesforce/label/c.MSD_CORE_HEQ_AllResourcerecordsPerPageOptions';
import sitepath from '@salesforce/label/c.MSD_CORE_HEQ_SitePath_For_Download';

//Static Resource
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';

export default class MSD_CORE_HEQ_AllResource extends NavigationMixin(LightningElement) {

    @track selectedCategories = [];
    @track keyword = '';
    @track type = '';
    @track sections = [];
    @track profileName;
    @track categoryList = undefined;
    @track selectedDocumentIds = [];
    @track collectionId;
    @track isListView = false;
    @track searchKeyword = '';
    @track showSpinner = false;
    @track isCollectionModel = false;
    @track isConfirmModel = false;
    @track collectionList = [];
    @track selectedCategoriesArray = [];
    @track selectedCategoriesRecievedFromChild = [];
    @track categoriesIdsUpdated = [];
    @track categoryNameAndIdMap = [];

    @track paginatedTopics = [];
    allRecords = [];

    @track menuOptions = [
        { action: 'download', label: 'Download', downloadActive: true, isModelBox: false },
        { action: 'preview', label: 'Preview & Details', downloadActive: false, isModelBox: false },
        { action: 'email', label: 'Email to customer', downloadActive: false, isModelBox: false },
        { action: 'addToCollection', label: 'Add to collection', downloadActive: false, isModelBox: true },
        { action: 'print', label: 'Print to customer', downloadActive: false, isModelBox: true }
    ];
    label = {
        home
    }

    // Pagination
    @track isPagination = false;
    @track totalRecords = 0;
    @track totalPages = 1;
    @track currentPage = 1;
    @track recordsPerPage = recordsperpage;
    @track recordsPerPageOptions = [];
    @track searchCategory = [];
    @api isChecked;

    connectedCallback() {
        this.getUserData();
        this.getCollectionList();
        this.keyword = this.getUrlParamValue(window.location.href, 'keyword');
        this.type = this.getUrlParamValue(window.location.href, 'type');
        this.categoryList = this.getUrlParamValue(window.location.href, 'category');

        if (this.type == 'Browse All') {
            this.loadSearch(null, this.type, null, null);
        }

        if (this.getUrlParamValue(window.location.href, 'action') == 'collection') {
            this.isCollection = true;
            this.collectionId = this.getUrlParamValue(window.location.href, 'cid');
        }

        if (this.categoryList) {
            this.loadSearch(null, this.type, null, this.categoryList);
        }

        if (this.keyword && this.type) {
            this.isSearch = true;
            this.searchKeyword = 'Search Criteria: ' + this.keyword;
            this.loadSearch(this.keyword, this.type, null, null);
        }

        if (((this.type).toLowerCase() == 'new materials' || (this.type).toLowerCase() == 'expiring soon') && this.categoryList == undefined) {
            this.loadSearch(null, this.type, null, null);
        }
        if (((this.type).toLowerCase() == 'therapeutic area' || (this.type).toLowerCase() == 'topics') && this.categoryList == undefined) {
            this.loadSearch(null, this.type, null, null);
        }

        if (this.sectionsSent != null) {
            this.sections = this.sectionsSent;
        }

        this.recordsPerPageOptions = recordperpageoption.split(',').map(option => parseInt(option.trim()));
    }


    getCollectionList() {
        getCollectionList()
            .then(result => {
                console.log('result of getCollectionList>>', result);
                if (result.length > 0) {
                    for (let key in result) {
                        this.collectionList.push({ value: result[key].Id, label: result[key].MSD_CORE_Collection_Name__c });
                    }
                }
                console.log('>collectionList>>' + JSON.stringify(this.collectionList));
            })
            .catch(error => console.error('Error getCollectionList::', error));
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    getUserData() {
        getUserProfileName()
            .then(profileName => {
                console.log('profileName>>', profileName);
                this.profileName = profileName;
                const category = this.getUrlParamValue(window.location.href, 'category');
                if (category) {
                    this.loadSection(category);
                }
            })
            .catch(error => console.error('Error getUserProfileName::', error));
    }

    loadSearch(keyword, type, category, catName) {
        this.showSpinner = true;

        fetchResources({ keyword: keyword, type: type, category: category, categoryName: catName }).then(result => {
            console.log('Result of fetchResources::>>', result);
            this.showSpinner = false;
            this.manageLoadData(result, keyword, type, category, catName);
        }).catch(error => {
            console.log('loadSearch error->>' + error.message);
            this.showSpinner = false;
        });
    }

    closeFilter(event) {
        const filterValue = event.currentTarget.dataset.filter;
        console.log('filterValue----->' + JSON.stringify(filterValue));

        console.log('selectedCat List----->', JSON.stringify(this.selectedCategoriesArray));

        this.selectedCategoriesArray = this.selectedCategoriesArray.filter(filter => filter !== filterValue);
        console.log('selectedCat List After----->', JSON.stringify(this.selectedCategoriesArray));
        // for each loop on the selectedCategoriesArray and remove that particular filter and return the categories id.
        // console.log('### categoriesIdsUpdated length '+this.categoriesIdsUpdated.length);

        console.log('### categoryNameAndIdMap '+this.categoryNameAndIdMap);

        this.categoryNameAndIdMap.forEach(category => {
            console.log('### category.name '+category.name);
            if(category.name === filterValue) {
                const index = this.categoriesIdsUpdated.indexOf(category.idValue);
                if (index > -1) { // only splice array when item is found
                    this.categoriesIdsUpdated.splice(index, 1); // 2nd parameter means remove one item only
                }
            }
            console.log('### categoriesIdsUpdated '+this.categoriesIdsUpdated);
        });
        console.log('### categoriesIdsUpdated length '+this.categoriesIdsUpdated.length);


        const childComponent = this.template.querySelector('c-m-s-d_-c-o-r-e_-h-e-q_-search-category');
        if (childComponent) {
            childComponent.updateCategories(this.categoriesIdsUpdated); 
        }

        if (this.selectedCategoriesRecievedFromChild[0].name === filterValue) {
            console.log('Found Parent ' + filterValue);
            this.categoriesIdsUpdated = null;
        }

        // For Each of selectedCategoriesRecievedFromChild.child
        // Get all child categories for parent value
        // Delete all child cat from selectedCategoriesArray

        this.loadSearch(this.keyword, this.type, this.categoriesIdsUpdated, null);
    }

    // closeFilter(event) {
    //     const filterValue = event.currentTarget.dataset.filter;
    //     console.log('filterValue----->' + JSON.stringify(filterValue));
    //     console.log('selectedCat List----->', JSON.stringify(this.selectedCategoriesArray));

    //     // Remove the parent category from the selectedCategoriesArray
    //     this.selectedCategoriesArray = this.selectedCategoriesArray.filter(filter => filter !== filterValue);
    //     console.log('selectedCat List After----->', JSON.stringify(this.selectedCategoriesArray));

    //     console.log('### categoryNameAndIdMap ' + this.categoryNameAndIdMap);

    //     // Update categoriesIdsUpdated by removing the parent category
    //     this.categoryNameAndIdMap.forEach(category => {
    //         console.log('### category.name ' + category.name);
    //         if (category.name === filterValue) {
    //             const index = this.categoriesIdsUpdated.indexOf(category.idValue);
    //             if (index > -1) { // only splice array when item is found
    //                 this.categoriesIdsUpdated.splice(index, 1); // 2nd parameter means remove one item only
    //             }
    //         }
    //         console.log('### categoriesIdsUpdated ' + this.categoriesIdsUpdated);
    //     });

    //     console.log('### categoriesIdsUpdated length ' + this.categoriesIdsUpdated.length);

    //     const childComponent = this.template.querySelector('c-m-s-d-c-o-r-e-h-e-q_-search-category');
    //     if (childComponent) {
    //         childComponent.updateCategories(this.categoriesIdsUpdated);
    //     }

    //     // If the parent category matches, clear categoriesIdsUpdated (if needed)
    //     if (this.selectedCategoriesRecievedFromChild[0].name === filterValue) {
    //         console.log('Found Parent ' + filterValue);
    //         this.categoriesIdsUpdated = null;
    //     }

    //     // New code to handle removal of child categories associated with the parent
    //     this.selectedCategoriesRecievedFromChild.forEach(parentCategory => {
    //         if (parentCategory.name === filterValue) {
    //             console.log('Found Parent ' + filterValue);

    //             // Iterate over each child of the parent category
    //             parentCategory.childCategories.forEach(childCategory => {
    //                 // Remove the child category from selectedCategoriesArray
    //                 this.selectedCategoriesArray = this.selectedCategoriesArray.filter(
    //                     filter => filter !== childCategory.name
    //                 );

    //                 // Optionally remove child category IDs from categoriesIdsUpdated as well
    //                 const childIndex = this.categoriesIdsUpdated.indexOf(childCategory.idValue);
    //                 if (childIndex > -1) {
    //                     this.categoriesIdsUpdated.splice(childIndex, 1);
    //                 }
    //             });
    //         }
    //     });

    //     console.log('Updated selectedCategoriesArray After Removing Children ----->', JSON.stringify(this.selectedCategoriesArray));

    //     // Update the child component again with the newly updated category IDs after removing child categories
    //     if (childComponent) {
    //         childComponent.updateCategories(this.categoriesIdsUpdated);
    //     }

    //     // Continue with your loadSearch function
    //     this.loadSearch(this.keyword, this.type, this.categoriesIdsUpdated, null);
    // }



    handleCheckboxChange(event) {
        const isChecked = event.detail.isChecked;
        console.log('isChecked in parent component ----->' + JSON.stringify(isChecked));
        const filter = event.detail.filter;
        console.log('Filter to uncheck ----->' + JSON.stringify(filter));
    }

    manageLoadData(result, keyword, type, category, catName) {
        console.log('Manage Load Data', result);
        let section;
        this.resetVariableValue();
        if (result.length > 0) {
            if (type == 'Browse All') {
                section = { title: 'Browse All', topics: [] };
            } else {
                section = { title: 'Search Results', topics: [] };
            }
            section.topics = result.map(item => {
                let headerclassval = 2;
                let filetype;
                if (item.FileType == 'PDF') {
                    headerclassval = 2;
                    filetype = 'PDF';
                }
                if (item.MSD_CORE_Video_Resource__c) {
                    headerclassval = 5;
                    filetype = 'Video';
                }
                let updatedURL = this.getThumbnailURL(item.FileType);
                let videoThumbURL = item.Id;

                let descriptionVal = item.MSD_CORE_Therapeutic_Area__c ? item.MSD_CORE_Therapeutic_Area__c.replace(/;/g, ', ') : item.MSD_CORE_Therapeutic_Area__c;
                let topicVal = item.MSD_CORE_Topic__c ? item.MSD_CORE_Topic__c.replace(/;/g, ', ') : item.MSD_CORE_Topic__c;

                console.log('Manage Load Data topicVal', topicVal);





                // let expirationDate = new Date(item.MSD_CORE_Expiration_Date__c).toLocaleDateString('en-US');
                let expirationDate;
                if (item.MSD_CORE_Expiration_Date__c) {
                    expirationDate = new Intl.DateTimeFormat('en-US', {
                        year: 'numeric',
                        month: '2-digit',
                        day: '2-digit'
                    }).format(new Date(item.MSD_CORE_Expiration_Date__c));
                }

                console.log('Manage Load Data expirationDate', expirationDate);

                return {
                    id: item.Id,
                    title: item.Title,
                    subtitle: item.MSD_CORE_Topic__c,
                    imageUrl: (item.Id) ? updatedURL + videoThumbURL : noImage,
                    contentdocumentid: item.ContentDocumentId,
                    isBookmarked: item.isBookmarked == 'true' ? true : false,
                    heading: filetype,
                    boldText: item.Title,
                    normalText: descriptionVal,
                    normalText1: topicVal,
                    code: item.MSD_CORE_Resource_Code__c,
                    expiryDays: expirationDate,
                    headerClass: `header-color-${headerclassval}`,
                    headerClasslist: `header-color-list-${headerclassval}`,
                    showMenu: false,
                    isSelectedTile: false,
                    isSelectedList: false,
                    isSelectedTileColor: 'slds-var-m-around_medium ',
                    isSelectedListColor: 'listviewcls ',
                    downloadLink: sitepath + 'sfc/servlet.shepherd/document/download/' + item.ContentDocumentId + '?operationContext=S1',
                    isNewItem: item.MSD_CORE_IsNewItem__c == 'true' ? true : false
                };

            });
            this.allRecords = section.topics;
            console.log('this.allRecords------>' + JSON.stringify(this.allRecords));
            this.totalRecords = this.allRecords.length;
            console.log('this.totalRecords----->' + JSON.stringify(this.totalRecords));
            if (this.totalRecords > 0) {
                this.isPagination = true;
            }
            this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
            this.updatePagination();
        } else {
            section = { title: 'Search Results', topics: false };
            console.log('section------>' + JSON.stringify(section));
            this.allRecords = section.topics;
            this.totalRecords = this.allRecords.length;
            if (this.totalRecords > 0) {
                this.isPagination = true;
            }
            this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
            this.updatePagination();
        }
    }

    resetVariableValue() {
        this.totalRecords = 0;
        this.totalPages = 1;
        this.currentPage = 1;
    }

    // Pagination
    updatePagination() {
        const startIndex = (this.currentPage - 1) * parseInt(this.recordsPerPage);
        const endIndex = startIndex + parseInt(this.recordsPerPage);
        this.paginatedTopics = this.allRecords.slice(startIndex, endIndex);
        this.sections = [{ title: 'Browse All', topics: this.paginatedTopics }];
        console.log('this.sections>>>>>>>'+JSON.stringify(this.sections));
        // Sync 2 Pagination Components
        let pagination = this.template.querySelectorAll('c-m-s-d_-c-o-r-e_-h-e-q_-pagination');
        for (let index = 0; index < pagination.length; index++) {
            pagination[index].updatecurrentpage(this.currentPage, this.totalRecords, this.totalPages);
        }
    }

    handlePageOptionChange(event) {
        this.currentPage = 1;
        this.recordsPerPage = event.detail.recordsPerPage;
        this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
        this.updatePagination();
    }

    handlePageChange(event) {
        this.currentPage = event.detail.currentPage;
        this.recordsPerPage = event.detail.recordsPerPage;
        this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
        this.updatePagination();
    }

    // For Search Category
    handlecategoriesid(event) {
        const categoriesid = event.detail;
        this.categoriesIdsUpdated = event.detail;
        console.log('handlecategoriesid ** categoriesid>>>', JSON.stringify(categoriesid));
        this.loadSearch(this.keyword, this.type, categoriesid, null);
    }


    handleSelectedCategories(event) {
        const selectedCategories = event.detail;
        this.selectedCategoriesRecievedFromChild = event.detail;
        console.log('handleSelectedCategories ** selectedCategories>>>', JSON.stringify(selectedCategories));
        const Filters = this.filterCategories(selectedCategories);
        console.log('Processed Filters:', JSON.stringify(Filters, null, 2));
        this.currentFilters = Filters;
        console.log('handleCheck');
        

        const selectedCategoriesArray = [];
        const processCategory = (categoryName, categoryData) => {
            console.log('Processing Category:', categoryName, categoryData);

            if (categoryData.isChecked) {
                selectedCategoriesArray.push(categoryName);
                this.categoryNameAndIdMap.push({name:categoryName, idValue : categoryData.idVal});
                console.log('Selected Category:', categoryName);

            }
            if (categoryData.childCategories) {
                Object.keys(categoryData.childCategories).forEach(childCategoryName => {
                    processCategory(childCategoryName, categoryData.childCategories[childCategoryName]);
                });
            }
        };
        Object.keys(Filters).forEach(parentCategoryName => {
            processCategory(parentCategoryName, Filters[parentCategoryName]);
        });

        this.selectedCategoriesArray = selectedCategoriesArray;
        console.log('Selected Categories (Parent + Child)::', JSON.stringify(this.selectedCategoriesArray, null, 2));
        console.log('### categoryNameAndIdMap '+JSON.stringify(this.categoryNameAndIdMap));
        const SelectedFilters = {
            keyword: this.keyword,
            Filters: Filters,
            type: this.type
        };
        console.log('SelectedFilters----->' + JSON.stringify(SelectedFilters));

        this.template.querySelector('c-m-s-d_-c-o-r-e_-h-e-q_-search-category').handleSelectedFilters(SelectedFilters);
    }

    // For Search Category
    filterCategories(categories) {
        const result = {};
        categories.forEach(category => {
            if (category.childCategories && category.childCategories.length > 0) {
                result[category.name] = { childCategories: this.filterCategories(category.childCategories), isChecked: category.isChecked, idVal : category.id  }
            } else {
                result[category.name] = { isChecked: category.isChecked, idVal : category.id };
            }
        });
        return result;
    }

    handleSavedSearch(event) {
        this.showSpinner = true;
        let data1 = JSON.parse(event.detail);
        var categoryList = this.extractLabels(data1);
        this.searchKeyword = 'Search Criteria: ' + data1.keyword;
        this.template.querySelector('c-m-s-d_-c-o-r-e_-h-e-q_-search-category').loadCheckedCategories(categoryList);
        fetchResourcesFromSavedSearch({ keyword: data1.keyword, type: data1.type, category: categoryList }).then(result => {
            console.log('Result of fetchResourcesFromSavedSearch:', result);
            this.showSpinner = false;
            this.manageLoadData(result, data1.keyword, data1.type, categoryList, null);
            this.sectionsSent = true;
        }).catch(error => {
            this.showSpinner = false;
            console.log('error in fetchResourcesFromSavedSearch->>' + JSON.stringify(error));
        });
    }

    extractLabels(data) {
        let labels = [];
        function traverse(obj, parentLabel) {
            for (let key in obj) {
                if (typeof obj[key] === 'object') {
                    traverse(obj[key], key);
                } else if (key === 'isChecked' && obj[key] === true) {
                    labels.push(parentLabel);
                }
            }
        }
        traverse(data.Filters, null);
        return labels;
    }

    getThumbnailURL(fileType) {
        let updatedThumbURL;
        switch (fileType.toUpperCase()) {
            case 'JPG':
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=ORIGINAL_Jpg');
                break;
            case 'PNG':
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=ORIGINAL_Png');
                break;
            case 'PDF':
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=SVGZ');
                break;
            default:
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=SVGZ');
        }
        return updatedThumbURL;
    }

    handleShowMenu(event) {
        const { itemId, gridType, category } = event.detail;
        this.sections = this.sections.map((section, index) => {
            section.topics = section.topics.map((item, idx) => {
                if (item.id === itemId) {
                    item.showMenu = !item.showMenu;
                }
                return item;
            });
            return section;
        });
        console.log('>>this.sections>>>' + JSON.stringify(this.sections));
    }

    handleDocumentSelection(event) {
        const documentId = event.detail.id;
        this.sections = this.sections.map((section, index) => {
            section.topics = section.topics.map((item, idx) => {
                if (item.contentdocumentid === documentId) {
                    item.isSelectedTile = !item.isSelectedTile;
                    item.isSelectedList = !item.isSelectedList;
                    item.isSelectedTileColor = !item.isSelectedTile ? 'slds-var-m-around_medium ' : 'slds-var-m-around_medium grey-background'
                    item.isSelectedListColor = !item.isSelectedList ? 'listviewcls ' : 'listviewcls grey-background'
                    if ((item.isSelectedTile || item.isSelectedList) && !this.selectedDocumentIds.includes(item.contentdocumentid)) {
                        this.selectedDocumentIds = [...this.selectedDocumentIds, item.contentdocumentid];
                    } else if (!item.isSelectedTile || !item.isSelectedList) {
                        this.selectedDocumentIds = this.selectedDocumentIds.filter(id => id !== item.contentdocumentid);
                    }
                }
                return item;
            });
            return section;
        });
    }

    // For adding resource to the Collection
    handleAdd() {
        this.showSpinner = true;
        saveResourcesInCollection({ collectionId: this.collectionId, documentIds: this.selectedDocumentIds })
            .then(result => {
                this.handleCancel();
                this.showSpinner = false;
            })
            .catch(error => {
                console.log('error->' + JSON.stringify(error));
                this.showSpinner = false;
            });
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections/view?cid=' + this.collectionId,
            }
        });
    }

    // Sidebar
    handleExpandCollapsSidebar() {
        const tilecontent = this.template.querySelector('.tileviewcls');
        tilecontent.classList.toggle('margincls-tile');
        const listcontent = this.template.querySelector('.listviewcls');
        listcontent.classList.toggle('margincls-tile');
        const bottompagination = this.template.querySelector('.bottompagination');
        bottompagination.classList.toggle('margincls-tile');
        const sidebar = this.template.querySelector('.sidebar');
        sidebar.classList.toggle('width-sidebar');
    }

    handleViewClick(event) {
        let view = event.currentTarget.dataset.name;
        this.isListView = view == 'list' ? true : false;
    }

    redirectToHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/landing-page'
            }
        });
    }
}