import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
//import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import basePath from "@salesforce/community/basePath";
//Apex Classes
import getCollectionsRecords from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getCollections';
import deleteCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.deleteCollection';
import getUserProfileName from '@salesforce/apex/HEQ_HeaderController.getUserProfileName';
//Static Resource
import noImage from '@salesforce/resourceUrl/HEQ_No_Image';
//Custom Labels
import thumbURL from '@salesforce/label/c.HEQ_Sandbox_URL';
import collectionTitle from '@salesforce/label/c.HEQ_Collection_Title';
import newCollectionBtn from '@salesforce/label/c.HEQ_New_Collection_Btn';
import createdDate from '@salesforce/label/c.HEQ_Created_Date';
import headerName from '@salesforce/label/c.HEQ_Name';
import collectionItems from '@salesforce/label/c.HEQ_Collection_Items';
import sharedWith from '@salesforce/label/c.HEQ_Shared_With';
import noCollectionFound from '@salesforce/label/c.HEQ_No_Collection_Found';
import resultOf from '@salesforce/label/c.HEQ_Of';



export default class HEQMyCollections extends NavigationMixin(LightningElement) {

    @track data = false;
    @track resultsPerPage = "10";
    @track currentPage = 1;
    @track totalPages = 1;
    @track displayedData = [];
    @track columns = [];
    @track showConfirmationModal = false;
    @track collectionToDelete = null;
    @track profileName;

    showSpinner = false;

    labels = {
        collectionTitle,
        newCollectionBtn,
        createdDate,
        headerName,
        collectionItems,
        sharedWith,
        noCollectionFound,
        resultOf
    };

    resultsOptions = [
        { label: '10', value: '10' },
        { label: '25', value: '25' },
        { label: '50', value: '50' },
        { label: '100', value: '100' }
    ];

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    connectedCallback() {
        this.getCollections();
        this.showSpinner = true;
        this.getUserData();
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

    handleButtonClick(){
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
                if(result.length > 0){
                    this.data = result.map(item => ({
                        ...item,
                        ThumbnailUrl: item.imageUrl ? `${thumbURL}${item.imageUrl}` : noImage
                    }));
                    this.columns = Object.keys(this.data[0]).filter(key => key !== 'ThumbnailUrl');
                    console.log('this.data ' + JSON.stringify(this.columns));
                    this.totalPages = Math.ceil(this.data.length / parseInt(this.resultsPerPage));
                    this.updateDisplayedData();
                }else{
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

    updateDisplayedData() {
        const itemsPerPage = parseInt(this.resultsPerPage);
        const startIndex = (this.currentPage - 1) * itemsPerPage;
        const endIndex = startIndex + itemsPerPage;
        this.displayedData = this.data.slice(startIndex, endIndex);
        console.log('this.displayedData' + JSON.stringify(this.displayedData));
    }

    handleDeleteClick(event) {
         this.collectionToDelete = event.currentTarget.dataset.id;
        // this.collectionToDelete = 'aA1cW0000000ewjSAA';
        console.log('handleDeleteClick: collectionToDelete', this.collectionToDelete);
        this.showConfirmationModal = true;
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
                    this.showNotification('success', 'Collection has been successfully deleted.');
                } else {
                    console.error('handleDeleteConfirm: ' + result);
                    this.showNotification('Error', 'Error deleting collection', 'error');
                }
                this.showSpinner = false;
            })
            .catch(error => {
                console.error('handleDeleteConfirm: Error deleting collection:', error);
                this.showSpinner = false;
            });
    }

    handleCollectionClick(event){
        let clId = event.currentTarget.dataset.id;
        this.showSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections/view?cid='+clId
            }
        });
    }

        handleEdit(event){
            // let itemId = event.currentTarget.dataset.id;
            // let itemName = event.currentTarget.dataset.name;
            let clId = event.currentTarget.dataset.id;
            this.showSpinner = true;
            this[NavigationMixin.Navigate]({    
                type: 'standard__webPage',
                attributes: {
                    // url: '/resources/collections/edit?itemId=' + itemId+ '&itemName=' + encodeURIComponent(itemName)
                    // url: '/resources/collections/edit?itemId='+ itemId
                    url: '/resources/collections/edit?cid='+clId
                }
            });
        }

    showNotification(type, message) {
        this.template.querySelector('c-custom-toast').showToast(type, message);
    }
}