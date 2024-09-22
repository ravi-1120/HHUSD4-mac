import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';

//Apex Classes
import getCollectionRecord from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getCollectionRecord';
import getResources from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getResourcesFromCollection';
import removeResourceFromCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.removeResourceFromCollection';
import deleteCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.deleteCollection';
import shareCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.shareCollection';
import getSharedCustomer from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getSharedCustomer';
import unShareCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.unShareCollection';
import getUser from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getuser';
import getCustomerCollectionList from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getCustomerCollections';

//Static Resource
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';

//Custom Labels
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
import sharedWith from '@salesforce/label/c.MSD_CORE_HEQ_Shared_With';
import noResults from '@salesforce/label/c.MSD_CORE_No_Results';
import addMoreResource from '@salesforce/label/c.MSD_CORE_HEQ_Add_New_Resource';
import collectionItem from '@salesforce/label/c.MSD_CORE_HEQ_Collection_Item';
import addItem from '@salesforce/label/c.MSD_CORE_HEQ_Add_Item';
import noItemsShared from '@salesforce/label/c.MSD_CORE_HEQ_No_Collection_Shared';
import customerProfileName from '@salesforce/label/c.MSD_CORE_HEQ_CustomerProfile';
import aeProfileName from '@salesforce/label/c.MSD_CORE_HEQ_AEProfile';
import home from '@salesforce/label/c.MSD_CORE_HEQ_Home';
import sitepath from '@salesforce/label/c.MSD_CORE_HEQ_SitePath_For_Download';
import collections from '@salesforce/label/c.MSD_CORE_HEQ_Collections';
import addnewcollection from '@salesforce/label/c.MSD_CORE_HEQ_AddNewCollection';


export default class MSD_CORE_HEQ_ViewCollection extends NavigationMixin(LightningElement) {

    @track activeTab = 'resources';
    @track collectionData = [];
    @track showConfirmationModal = false;
    @track collectionToDelete = null;
    @track resources = [];
    @track isModalOpen = false;
    @track recToDelete;
    @track showuser = false;
    @track sharedCustomerData = [];
    @track nosharedCustomer = false;
    @track unsharecollectionpopup = false;
    @track selectedcustomerid;
    @track isCustomer = false;
    @track isAccountExe = false;
    @track collectionRecord;
    @track showSpinner = false;
    @track selectedcustomername;
    @track selectedcustomeremail;

    collectionId;
    userId = USER_ID;
    popupTitle;
    collectionItems;

    labels = {
        sharedWith,
        noResults,
        collectionItem,
        addItem,
        noItemsShared,
        addMoreResource,
        home,
        collections,
        addnewcollection
    };

    @track menuOptions = [
        { action: 'download', label: 'Download', downloadActive: true, isModelBox: false },
        { action: 'preview', label: 'Preview & Details', downloadActive: false, isModelBox: false }
    ];

    get isResourcesEmpty() {
        return this.resources.length === 0;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.collectionId = currentPageReference?.state?.cid;
            this.fetchCollectionData();
            this.fetchResource();
        }
    }

    connectedCallback() {
        this.showSpinner = true;
        this.getSharedCustomer();

        getUser({ userId: USER_ID })
            .then(result => {
                if (result.Profile.Name == customerProfileName) {
                    this.isCustomer = true;
                    this.loadCollectionRecord();
                }
                if (result.Profile.Name == aeProfileName) {
                    this.isAccountExe = true;
                }
                  this.showSpinner = false;
            })
            .catch(error => {
                console.log("getUser Collection Page" + JSON.stringify(error));
            })
    }

    getSharedCustomer() {
        this.showSpinner = true;
        getSharedCustomer({collectionId: this.collectionId})
            .then(result => {
                console.log('result of getSharedCustomer::>',result);
                if(result == null){
                    this.nosharedCustomer = true;
                    this.showSpinner = false;
                } else {
                    this.nosharedCustomer = false;
                    this.sharedCustomerData = result;
                    this.showSpinner = false;
                }
            })
            .catch(error =>{
                this.showSpinner = false;
                console.log('error of getSharedCustomer::>>'+JSON.stringify(error));
            });
    }

    async loadCollectionRecord() {
        try {
            this.showSpinner = true;
            const result = await getCustomerCollectionList({ collectionId: this.collectionId });
            if (result) {
                console.log('Collection View Record' + JSON.stringify(result));
                let collRecord = result[0];
                let updatedURL = this.getThumbnailURL('THUMB');
                this.collectionRecord = {
                ...collRecord,
                imageUrl: collRecord.imageUrl ? updatedURL + collRecord.imageUrl : noImage
            };
              this.showSpinner = false;
            }
        } catch (error) {
            console.error('Error loadCollectionRecord:', error);
        }
    }

    redirectToHome() {
        this.showSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/landing-page'
            }
        });
    }

    handleShowMenu(event) {
        const { itemId, gridType, category } = event.detail;
        let itemUpdate;
        if(gridType === 'grid1') itemUpdate = this.collectionItems;

        itemUpdate = itemUpdate.map(item => {
            if (item.id === itemId) {
                return { ...item, showMenu: !item.showMenu };
            }
            return { ...item, showMenu: false };
        });

        if (gridType === 'grid1') {
            this.collectionItems = itemUpdate;
        }
    }

    handleMenuClick(event) {
        const { action, itemId } = event.detail;

        switch (action) {
            case 'print':
                console.log(`Print item ${itemId}`);
                break;
            case 'preview':
                console.log(`Preview item ${itemId}`);
                break;
            case 'download':
                console.log(`Download item ${itemId}`);
                break;
            case 'email':
                console.log(`Email item ${itemId}`);
                break;
            case 'addToCollection':
                console.log(`Add item ${itemId} to collection`);
                break;
        }
        this.handleShowMenu({ detail: { itemId, gridType: event.detail.gridType } });
    }

    fetchResource() {
        this.showSpinner = true;
        console.log('fetchResources->' + this.collectionId);
        if (this.collectionId) {
            getResources({ collectionId: this.collectionId })
                .then(result => {
                    console.log('Fetch Resources New result->' , result);
                    let updatedURL = this.getThumbnailURL('Thumb');
                    this.resources = result.map(doc => ({
                        ...doc,
                        previewUrl: doc.id ? updatedURL+doc.id : noImage
                    }));


                    //New
                    this.collectionItems = result.map(item => {
                    
                    let headerclassval = 'header-color-2';
                    let filetype;
                    if (item.fileType == 'pdf') {
                        headerclassval = 'header-color-2';
                        filetype = 'Static';
                    }
                    if (item.videoLink) {
                        headerclassval = 'header-color-5';
                        filetype = 'Video';
                    }
                    return {
                        id: item.id,
                        heading: filetype,
                        imageUrl: (item.id) ? updatedURL + item.id : noImage,
                        boldText: item.title,
                        normalText: item.therapeuticArea,
                        normalText1: item.topic,
                        expiryDays: item.expiryDate,
                        code: item.jobCode,
                        headerClass: headerclassval,
                        downloadLink: sitepath + '/sfc/servlet.shepherd/document/download/' + item.docId + '?operationContext=S1',
                        showMenu: false,
                        notTruncated: true
                    }
                })
                    this.showSpinner = false;
                })
                .catch(error => {
                    console.log('error->' + JSON.stringify(error));
                });
        }
    }

    handleDeleteIcon(event) {
        const { id, name } = event.currentTarget.dataset;
        this.recToDelete = id;
        this.popupTitle = name;
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleDelete() {
        removeResourceFromCollection({ contentDocumentId: this.recToDelete, collectionId: this.collectionId })
            .then(result => {
                if(result){
                    console.log('removeResource1>>' + JSON.stringify(result));
                    this.resources = this.resources.filter((record) => record.ContentDocumentId !== this.recToDelete);
                    console.log('this.resources----->'+JSON.stringify(this.resources));
                    this.closeModal();
                }
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
                console.log('this.error----->'+JSON.stringify(error));
            });
    }

    fetchCollectionData() {
        this.showSpinner = true;
        if (this.collectionId) {
            console.log('collection ID' + this.collectionId);
            getCollectionRecord({ collectionId: this.collectionId, userId: this.userId })
                .then(result => {
                    console.log('result ' + JSON.stringify(result));
                    if (result) {
                        this.collectionData = {
                            ...result,
                            ThumbnailUrl: result.imageUrl ? `${thumbURL}${result.imageUrl}` : noImage
                        };
                    } else {
                        this.collectionData = null;
                    }
                    this.error = null;
                    this.showSpinner = false;
                    console.log('Collection Data ' + JSON.stringify(result));
                    console.log('Collection Data ' + JSON.stringify(this.collectionData));
                })
                .catch(error => {
                    console.log('error->' + JSON.stringify(error));
                    this.collectionData = null;
                    this.error = error.body ? error.body.message : 'Unknown error occurred';
                    this.showSpinner = false;
                    console.error('Error fetching collection record:', this.error);
                });
        }
    }

    handleBackClick() {
        this.showSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections'
            }
        });
    }

    handleEditClick(event) {
        console.log('Edit button clicked');
        let clId = event.currentTarget.dataset.id;
        this.showSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections/edit?cid=' + clId
            }
        });
    }

    handleDeleteClick(event) {
        this.collectionToDelete = event.currentTarget.dataset.id;
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
                console.log('handleDeleteConfirm:::>', result);
                if (result === 'Collection deleted successfully') {
                    this.collections(); // Refresh the collections list after deletion
                    this.showConfirmationModal = false;
                    this.showNotification('success', 'Collection has been successfully deleted.');
                    this.collectionToDelete = null;
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

    collections() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections'
            }
        });
    }

    handleAddItemClick() {
        console.log('Add Item button clicked');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources?type=${encodeURIComponent('Browse All')}&action=collection&cid=${encodeURIComponent(this.collectionId)}`
            }
        });
    }

    handleTabClick(event) {
        this.activeTab = event.target.dataset.tab;
    }

    get resourcesTabClass() {
        return `tab-button ${this.activeTab === 'resources' ? 'active' : ''}`;
    }

    get sharedWithTabClass() {
        return `tab-button ${this.activeTab === 'sharedWith' ? 'active' : ''}`;
    }

    get isResourcesActive() {
        return this.activeTab === 'resources';
    }

    get isSharedWithActive() {
        return this.activeTab === 'sharedWith';
    }

    showNotification(type, message) {
        this.template.querySelector('c-custom-toast').showToast(type, message);
    }

    handleselectuserClick(event) {
        console.log('Handle Select User');
        this.showuser = true;
    }

    closeCustomerModal(event) {
        console.log('closeCustomerModal');
        this.showuser = false;
    }

    handleSaveUser(event) {
        console.log('handleSaveUser');
    }

    handlePreview(event) {
        let resourceId = event.target.dataset.id;
        resourceId = resourceId.split('-');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/preview?recordId=${encodeURIComponent(resourceId[0])}`
            }
        });
    }

    closeCustomerModel(event) {
        this.showuser = false;
    }

    getSelectedCustomer(event){
        console.log('getSelectedCustomer'+JSON.stringify(event.detail));
        this.shareCollectionToUser(event.detail.data);
    }

    shareCollectionToUser(cids){
        this.showSpinner = true;
        console.log('cids>>>',cids);
        shareCollection({customerIds: cids, collectionId: this.collectionId})
            .then(result => {
                console.log('result of sharecollection::>>',result);
                this.showSpinner = false;
                this.showuser = false;
                this.getSharedCustomer();
            })
            .catch(error => {
                console.error('error of sharecollection::>>'+JSON.stringify(error));
                this.showSpinner = false;
                this.showuser = false;
            });
    }

    handleunsharecollection(event) {
        this.showSpinner = true;
        this.selectedcustomerid = event.currentTarget.dataset.id;
        this.selectedcustomername = event.currentTarget.dataset.fname + ' ' +event.currentTarget.dataset.lname;
        this.selectedcustomeremail = event.currentTarget.dataset.email;
        this.unsharecollectionpopup = true;
        this.showSpinner = false;
    }

    unshareCollection() {
        this.showSpinner = true;
        unShareCollection({customerId: this.selectedcustomerid, collectionId: this.collectionId})
            .then(result => {
                console.log('result of unsharecollection::>>',result);
                this.showSpinner = false;
                this.unsharecollectionpopup = false;
                this.getSharedCustomer();
            })
            .catch(error => {
                console.error('error of unShareCollection::>>'+JSON.stringify(error));
                this.showSpinner = false;
                this.unsharecollectionpopup = false;
            });
    }

    closeUnshareModal() {
        this.unsharecollectionpopup = false;
    }

    navigateToCollections() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections'
            }
        });
    }

    navigateToNewCollections() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections/new'
            }
        });
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
            case 'THUMB':
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=THUMB720BY480');
                break;
            default:
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=SVGZ');
        }

        console.log('Updated ThumbURL:', updatedThumbURL);
        return updatedThumbURL;
    }
}