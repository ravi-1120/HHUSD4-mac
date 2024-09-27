import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, track, api } from 'lwc';
//import { ShowToastEvent } from 'lightning/platformShowToastEvent';


//Apex Classes
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';
import deleteCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.deleteCollection';
import getCollectionsRecords from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getCollections';
import duplicateCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.duplicateCollection';
import getCollectionsWithName from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getExistingCopiesCount';
import getSharedCustomer from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getSharedCustomer';
import removeResourceFromCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.removeResourceFromCollection';
import getResourceTitlesAndCodes from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getResourceTitlesAndCodes';

//Static Resource
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';

//Custom Labels
import collectionItems from '@salesforce/label/c.MSD_CORE_HEQ_Collection_Items';
import home from '@salesforce/label/c.MSD_CORE_HEQ_Home';
import collectionTitle from '@salesforce/label/c.MSD_CORE_HEQ_Collection_Title';
import createdDate from '@salesforce/label/c.MSD_CORE_Created_Date';
import headerName from '@salesforce/label/c.MSD_CORE_Name';
import newCollectionBtn from '@salesforce/label/c.MSD_CORE_HEQ_New_Collection_Btn';
import noCollectionFound from '@salesforce/label/c.MSD_CORE_HEQ_No_Collection_Found';
import resultOf from '@salesforce/label/c.MSD_CORE_Of';
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
import sharedWith from '@salesforce/label/c.MSD_CORE_HEQ_Shared_With';
import recordperpage from '@salesforce/label/c.MSD_CORE_HEQ_CollectionRecordPerPage';
import recordperpageoption from '@salesforce/label/c.MSD_CORE_HEQ_CollectionPerPageOptions';
import shareddate from '@salesforce/label/c.MSD_CORE_HEQ_Shared_date';
import sharedby from '@salesforce/label/c.MSD_CORE_HEQ_Shared_by';
import customerProfileName from '@salesforce/label/c.MSD_CORE_HEQ_CustomerProfile';

export default class HEQMyCollections extends NavigationMixin(LightningElement) {

    @track data = false;
    // @track resultsPerPage = "1";
    // @track currentPage = 1;
    // @track totalPages = 1;
    @track displayedData = [];
    @track columns = [];
    @track showConfirmationModal = false;
    @track collectionToDelete = null;
    @track profileName;
    @track collectionData = {};
    @track @track isThumbnailUrl = false;
    // @track sortField = 'createdDate';
    // @track sortDirection = 'desc';

    @track sortBy = 'createdDate'; // Default sort field
    @track sortDateDirection = 'desc';
    @track sortItemsDirection = 'desc';
    @track sortSharedByDirection = 'desc';
    @track newResourceIds = [];
    @track createdDateSortIcon;
    @track itemsSortIcon;
    @track nameSortIcon;

    showSpinner = false;

    @track showCustomerModal = false;
    @track sharedCustomers = [];
    @track collectionId = null;
    @track resources = [];

    // @track showResourceModal = false;
    @track isResourceModalOpen = false;
    @track resources = [];
    // @track selectedCollectionId = '';
    @track showCustomerModal = false;


    // Pagination
    @track totalRecords = 0;
    @track totalPages = 1;
    @track currentPage = 1;
    @track recordsPerPage = recordperpage;
    @track recordsPerPageOptions = [];
    @track isPagination = false;
    @track paginatedData = [];

    sharedCustomerColumns = [
        { label: 'First Name', fieldName: 'FirstName', type: 'text' },
        { label: 'Last Name', fieldName: 'LastName', type: 'text' },
        { label: 'Email', fieldName: 'Email', type: 'text' }
    ];

    // resourceColumns = [
    //     { label: 'Resource Name', fieldName: 'Title', type: 'text' },
    //     { label: 'Job Number', fieldName: 'MSD_CORE_Resource_Code__c', type: 'text' }
    // ];

    labels = {
        collectionTitle,
        newCollectionBtn,
        createdDate,
        headerName,
        collectionItems,
        sharedWith,
        noCollectionFound,
        resultOf,
        home,
        shareddate,
        sharedby
    };

    resultsOptions = [
        // { label: '10', value: '10' },
        { label: '25', value: '25' },
        { label: '50', value: '50' },
        { label: '100', value: '100' }
    ];

    openCustomerModal() {
        this.showCustomerModal = true;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    get hasSharedCustomers() {
        return this.sharedCustomers && this.sharedCustomers.length > 0;
    }

    get hasResources() {
        return this.resources && this.resources.length > 0;
    }


    connectedCallback() {
        this.getCollections();
        this.showSpinner = true;
        this.getUserData();
        this.sortBy = 'createdDate';
        this.sortDateDirection = 'desc';
        this.sortItemsDirection = 'desc';
        this.sortSharedByDirection = 'desc';
        this.recordsPerPageOptions = recordperpageoption.split(',').map(option => parseInt(option.trim()));
        this.createdDateSortIcon = 'utility:arrowup';
        this.itemsSortIcon = 'utility:arrowup';
        this.nameSortIcon = 'utility:arrowup';
    }

    getUserData() {
        getUserProfileName()
            .then(profileName => {
                this.profileName = profileName;
            })
            .catch(error => console.error('Error getting profile name:', error));

    }

    get isAccountExeProfile() {
        return this.profileName == 'HEQ - Account Exe';
    }

    handleResultsPerPageChange(event) {
        this.resultsPerPage = event.detail.value;
        this.currentPage = 1;
        this.totalPages = Math.ceil(this.data.length / parseInt(this.resultsPerPage));
        this.updateDisplayedData();
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.updateDisplayedData();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.updateDisplayedData();
        }
    }

    handleButtonClick() {
        this.showSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections/new'
            }
        });
    }

    getCollections() {
        getCollectionsRecords()
            .then(result => {
                if (result.length > 0) {
                    console.log('result>>',result);
                    let updatedURL = this.getThumbnailURL('THUMB');
                    this.data = result.map(item => {
                        let thumbnailId;
                        
                        if (this.profileName === customerProfileName) {
                            thumbnailId = item.latestFileId ? `${updatedURL}${item.latestFileId}` : noImage;
                        } else {
                            thumbnailId = item.imageUrl ? `${updatedURL}${item.imageUrl}` : noImage;
                        }

                        return {
                            ...item,
                            ThumbnailUrl: thumbnailId
                        };
                    });

                    this.allRecords = this.data;
                    this.totalRecords = this.allRecords.length;
                    if (this.totalRecords > 0) {
                        this.isPagination = true;
                    }
                    this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));

                    this.handlesorting('createdDate');
                    this.updatePagination();
                    this.columns = Object.keys(this.data[0]).filter(key => key !== 'ThumbnailUrl');
                } else {
                    this.data = undefined;
                    this.totalPages = 1;
                    this.displayedData = undefined;
                }
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error loading getCollectionsRecords:', error);
            });
    }

    // Pagination
    updatePagination() {
        const startIndex = (this.currentPage - 1) * parseInt(this.recordsPerPage);
        const endIndex = startIndex + parseInt(this.recordsPerPage);
        this.paginatedData = this.allRecords.slice(startIndex, endIndex);
        this.displayedData = this.paginatedData; 
        this.displayedData = this.data.slice(startIndex, endIndex);
        console.log('this.displayedData>>'+JSON.stringify(this.displayedData));
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


    handleSort(event) {
        const field = event.currentTarget.dataset.field;
        this.handlesorting(field);
    }

    handlesorting(field) {
        let sortorder;
        if (field == 'Items') {
            this.sortItemsDirection = (this.sortItemsDirection == 'asc') ? 'dsc' : 'asc';
            sortorder = this.sortItemsDirection;
        } else if (field == 'createdDate') {
            this.sortDateDirection = (this.sortDateDirection == 'asc') ? 'dsc' : 'asc';
            sortorder = this.sortDateDirection;
        } else if (field == 'sharedby') {
            this.sortSharedByDirection = (this.sortSharedByDirection == 'asc') ? 'dsc' : 'asc';
            sortorder = this.sortSharedByDirection;
        }
        this.sortRecords(field,sortorder);
        this.getSortIcon(field,sortorder);
        this.updatePagination();
    }


    sortRecords(field,order) {
        // this.displayedData.sort((a, b) => {
        this.allRecords.sort((a, b) => {
            let valueA;
            let valueB;
            if (field == 'createdDate') {
                valueA = new Date(a.createdDate);
                valueB = new Date(b.createdDate);
            } else if (field == 'Items') {
                valueA = a.resourceCount;
                valueB = b.resourceCount;
            } else if (field == 'sharedby') {
                valueA = a.sharedBy;
                valueB = b.sharedBy;
            }
            if (order === 'asc') {
                return valueB - valueA;
            } else if (order === 'dsc') {
                return valueA - valueB;
            } else {
                return 0;
            }
        });
    }


    getSortIcon(field, order) {
        if (field == 'createdDate') {
            this.createdDateSortIcon = order === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
        } else if (field == 'Items') {
            this.itemsSortIcon = order === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
        } else if (field == 'sharedby') {
            this.nameSortIcon = order === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
        }
    }



    updateDisplayedData() {

        const itemsPerPage = parseInt(this.resultsPerPage);
        const startIndex = (this.currentPage - 1) * itemsPerPage;
        const endIndex = startIndex + itemsPerPage;

        this.displayedData = this.data.slice(startIndex, endIndex).map(item => {
            if (item.createdDate) {
                item.formattedDate = this.formatDate(item.createdDate);
            }
            return item;
        });
    }


    formatDate(dateString) {
        
        const date = new Date(dateString);
        const day = ('0' + date.getDate()).slice(-2);
        const month = ('0' + (date.getMonth() + 1)).slice(-2);
        const year = date.getFullYear();
        const hours = ('0' + date.getHours()).slice(-2);
        const minutes = ('0' + date.getMinutes()).slice(-2);
        const seconds = ('0' + date.getSeconds()).slice(-2);

        // Return formatted date and time in "MM/DD/YYYY HH:MM:SS" 24-hour format
        return `${month}/${day}/${year} ${hours}:${minutes}:${seconds}`;
    }

    closeConfirmationModal() {
        this.showConfirmationModal = false;
        this.collectionToDelete = null;
    }

    handleDeleteConfirm() {
        console.log('handleDeleteConfirm: Initiating collection delete process.');
        console.log('handleDeleteConfirm: Collection ID to delete:', this.collectionToDelete);

        this.showSpinner = true;
        deleteCollection({ collectionId: this.collectionToDelete })
            .then(result => {
                console.log('handleDeleteConfirm: Delete operation result:', result);
                if (result === 'Collection deleted successfully') {
                    this.getCollections(); // Refresh the collections list after deletion
                    this.showConfirmationModal = false;
                    this.collectionToDelete = null;
                    this.currentPage = 1;
                    this.updatePagination();
                    this.showNotification('success', 'Collection has been successfully deleted.');
                } else {
                    console.error('handleDeleteConfirm: ' + result);
                    this.currentPage = 1;
                    this.updatePagination();
                    this.showNotification('Error', 'Error deleting collection', 'error');
                }
                this.showSpinner = false;
            })
            .catch(error => {
                console.error('handleDeleteConfirm: Error deleting collection:', error);
                this.showSpinner = false;
            });
    }

    handleCollectionClick(event) {
        let clId = event.currentTarget.dataset.id;
        this.showSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections/view?cid=' + clId
            }
        });
        this.handleDelete();
    }

    handleEdit(event) {
        // let itemId = event.currentTarget.dataset.id;
        // let itemName = event.currentTarget.dataset.name;
        let clId = event.currentTarget.dataset.id;
        this.showSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                // url: '/resources/collections/edit?itemId=' + itemId+ '&itemName=' + encodeURIComponent(itemName)
                // url: '/resources/collections/edit?itemId='+ itemId
                url: '/resources/collections/edit?cid=' + clId
            }
        });
    }

    handleDeleteClick(event) {
        this.collectionToDelete = event.currentTarget.dataset.id;
        // this.collectionToDelete = 'aA1cW0000000ewjSAA';
        console.log('handleDeleteClick: collectionToDelete', this.collectionToDelete);
        this.showConfirmationModal = true;
    }


    handleDuplicate(event) {
        const collectionId = event.currentTarget.dataset.id;
        const collectionName = event.currentTarget.dataset.name;
        const imageUrl = event.currentTarget.dataset.imageurl;

        // Extract the versionId from the imageUrl
        const versionId = this.extractVersionId(imageUrl);

        // Create the thumbnail URL using the versionId
        const thumbnailUrl = versionId ? `${thumbURL}${versionId}` : noImage;

        this.showSpinner = true;

        this.getExistingCopiesCount(collectionName)
            .then(count => {
                let newName;
                count = parseInt(count, 10);
                if (isNaN(count) || count === 0) {
                    newName = `Copy of ${collectionName}`;
                } else {
                    newName = `Copy of ${collectionName}-(${count + 1})`;
                }
                return duplicateCollection({
                    collectionId: collectionId,
                    newName: newName,
                    versionId: versionId
                });
            })
            .then(result => {
                if (result.success) {
                    this.showNotification('success', 'Collection has been successfully copied.');
                    this.handleDelete();
                    //return this.removeResourceFromCollection(result.newCollectionId, this.newResourceIds);

                    if (Array.isArray(result.newResourceIds) && result.newResourceIds.length > 0) {
                        this.newResourceIds = result.newResourceIds;
                        console.log('New Resource IDs:', this.newResourceIds);

                        // Remove resources from the duplicated collection


                    } else {
                        console.warn('No new resource IDs returned from duplication');
                        return Promise.resolve();
                    }
                } else {
                    this.showNotification('error', result.message);
                    return Promise.reject(new Error(result.message));
                }
            })
            .then(() => {
                this.getCollections(); // Refresh the list of collections
            })
            .catch(error => {
                console.error('Error in duplication process:', error);
                this.showNotification('error', 'Error in duplication process');
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleDelete() {
        removeResourceFromCollection({ contentDocumentId: this.recToDelete, collectionId: this.collectionId })
            .then(() => {
                this.resources = this.resources.filter((record) => record.ContentDocumentId !== this.recToDelete);
                console.log('this.resources----->' + JSON.stringify(this.resources));
                this.closeModal();
                // this.dispatchEvent(
                //     new ShowToastEvent({
                //         title: 'Success',
                //         message: 'Resource removed',
                //         variant: 'success'
                //     })
                // );
            })
            .catch((error) => {
                //console.log('error->' + JSON.stringify(error));
                console.log('this.error----->' + JSON.stringify(error));
            });
    }


    getExistingCopiesCount(originalName) {
        return getCollectionsWithName({ nameLike: originalName })
            .then(countOfCollection => {
                console.log('### countOfCollection ' + countOfCollection);
                return countOfCollection;
            });
    }

    extractVersionId(url) {
        if (url == undefined || url == '') {
            return '';
        }
        const match = url.match(/versionId=([^&]+)/);
        const versionId = match ? match[1] : '';
        return (versionId && versionId !== 'undefined') ? versionId : '';
    }

    showNotification(type, message) {
        this.template.querySelector('c-custom-toast').showToast(type, message);
    }

    handleSharedCollectionClick(event) {
        const collectionId = event.currentTarget.dataset.id; // Assuming this is where your collection ID is stored
        console.log('collectionId----->' + JSON.stringify(collectionId));
        this.collectionId = collectionId;
        console.log('collectionId----->' + JSON.stringify(this.collectionId));
        this.showSpinner = true;
        getSharedCustomer({ collectionId: this.collectionId })
            .then(result => {
                console.log('resultSharedCollection---->' + JSON.stringify(result));
                this.sharedCustomers = result;
                console.log('this.sharedCustomers---->' + JSON.stringify(this.sharedCustomers));
                this.showCustomerModal = true;
                this.showSpinner = false;
            })
            .catch(error => {
                console.error('Error fetching shared customers:', error);
                this.showSpinner = false;
            });
    }

    closeCustomerModal() {
        this.showCustomerModal = false;
        this.sharedCustomers = [];
    }

    // handleResourceClick(event) {
    //     this.selectedCollectionId = event.target.dataset.id;
    //     this.fetchResources();
    //     this.showResourceModal = true;
    // }

    handleResourceClick(event) {
        const collectionId = event.target.dataset.id;
        this.fetchResources(collectionId);
    }

    fetchResources(collectionId) {
        this.showSpinner = true;
        getResourceTitlesAndCodes({ collectionId: collectionId })
            .then((result) => {
                console.log('resourcesResult---->' + JSON.stringify(result));
                this.resources = result;
                console.log('this.resources----->' + JSON.stringify(this.resources));
                this.isResourceModalOpen = true;
                this.showSpinner = false;
            })
            .catch((error) => {
                console.error('Error fetching resources:', error);
                this.showSpinner = false;
            });
    }

    closeResourceModal() {
        this.isResourceModalOpen = false;
        this.resources = [];
    }

    getThumbnailURL(fileType) {
        console.log('ThumbURL Return ' + fileType);
        let updatedThumbURL;

        switch (fileType.toUpperCase()) {
            case 'JPG':
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=ORIGINAL_Jpg');
                console.log('Updated ThumbURL for JPG:', updatedThumbURL);
                break;
            case 'PNG':
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=ORIGINAL_Png');
                console.log('Updated ThumbURL for PNG:', updatedThumbURL);
                break;
            case 'PDF':
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=SVGZ');
                break;
            default:
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=THUMB720BY480');
        }

        return updatedThumbURL;
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