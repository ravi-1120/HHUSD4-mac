import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';

import USER_ID from '@salesforce/user/Id';

//Apex Classes
import getImages from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getImages';
import createCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.createCollection';
import updateCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.updateCollection';
import getCollectionRecord from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getCollectionRecord';
import getResourceData from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getResourceData';

//Custom Labels
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
import newCollection from '@salesforce/label/c.MSD_CORE_HEQ_New_Collection';
import createBtn from '@salesforce/label/c.MSD_CORE_Create';
import cancelBtn from '@salesforce/label/c.MSD_CORE_Cancel';
import cllName from '@salesforce/label/c.MSD_CORE_HEQ_Collection_Name';
import pleaseEnterCLName from '@salesforce/label/c.MSD_CORE_HEQ_Please_Enter_CLName';
import collectionplaceholder from '@salesforce/label/c.MSD_CORE_HEQ_CollectionName_Placeholder';
import bannderHeader from '@salesforce/label/c.MSD_CORE_HEQ_Banner_Header_Title';
import browseBtn from '@salesforce/label/c.MSD_CORE_Browse';
import removeBtn from '@salesforce/label/c.MSD_CORE_Remove';
import closeBtn from '@salesforce/label/c.MSD_CORE_Close_Btn';
import activeLabel from '@salesforce/label/c.MSD_CORE_HEQ_Active_Label';
import save from '@salesforce/label/c.MSD_CORE_Save';
import editcollection from '@salesforce/label/c.MSD_CORE_HEQ_EditCollection';
import home from '@salesforce/label/c.MSD_CORE_HEQ_Home';
import sitepath from '@salesforce/label/c.MSD_CORE_HEQ_SitePath_For_Download';
import collectionbannerheader from '@salesforce/label/c.MSD_CORE_HEQ_CollectionModelHeader';
import addnewcollection from '@salesforce/label/c.MSD_CORE_HEQ_AddNewCollection';
import collections from '@salesforce/label/c.MSD_CORE_HEQ_Collections';
import newcollection from '@salesforce/label/c.MSD_CORE_HEQ_NewCollection';
import itemselected from '@salesforce/label/c.MSD_CORE_HEQ_itemselected';

//Static Resource
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';

export default class mSD_CORE_HEQ_UserCollections extends NavigationMixin(LightningElement) {

    @track collectionName = '';
    @track selectedImageUrl = '';
    @track collectionData = {};
    @track images = [];
    @track isModalOpen = false;
    @track isSelectedImage = false;
    @track isThumbnailUrl = false;
    @track isEdit = false;
    @track resourceId;
    @track resource = [];
    @track showSpinner = false;
    @track showresource = false;

    collectionId;
    userId = USER_ID;
    resId;
    nameError;
    allValid;

    labels = {
        newCollection,
        createBtn,
        cancelBtn,
        cllName,
        pleaseEnterCLName,
        bannderHeader,
        browseBtn,
        removeBtn,
        closeBtn,
        activeLabel,
        save,
        editcollection,
        home,
        collectionplaceholder,
        collectionbannerheader,
        collections,
        addnewcollection,
        newcollection,
        itemselected
    };

    connectedCallback() {
        this.editUrl();
        this.loadImages();
        if (this.resourceId) {
            this.showresource = true;
            this.getResourceData();
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.collectionId = currentPageReference.state?.cid;
            this.resourceId = currentPageReference.state?.resourceId;
            this.fetchCollectionData();
        }
    }

    fetchCollectionData() {
        this.showSpinner = true;
        if (this.collectionId) {
            getCollectionRecord({ collectionId: this.collectionId, userId: this.userId })
                .then(result => {
                    console.log('Result from getCollectionRecord:', result);
                    if (result) {
                        this.collectionData = {
                            ...result,
                            ThumbnailUrl: result.imageUrl !== '' ? `${thumbURL}${result.imageUrl}` : 'noImage'
                        };
                        const versionId = this.extractVersionId(this.collectionData.ThumbnailUrl);
                        this.isThumbnailUrl = !!versionId;
                    } else {
                        this.collectionData = {};
                        this.isThumbnailUrl = false;
                    }
                    this.error = null;
                    this.showSpinner = false;
                })
                .catch(error => {
                    this.collectionData = {};
                    this.isThumbnailUrl = false;
                    this.error = error.body ? error.body.message : 'Unknown error occurred';
                    this.showSpinner = false;
                    console.error('Error fetching collection record:', this.error);
                });
        }
    }

    getResourceData() {
        this.showSpinner = true;
        getResourceData({ resourceId: this.resourceId })
            .then(result => {
                console.log('result of getResourceData>>', result);
                let expiryDays = 0;
                if (result.MSD_CORE_Expiration_Date__c) {
                    const expirationDate = new Date(result.MSD_CORE_Expiration_Date__c);
                    const currentDate = new Date();
                    const timeDifference = expirationDate - currentDate; // Difference in milliseconds
                    expiryDays = Math.ceil(timeDifference / (1000 * 60 * 60 * 24)); // Convert milliseconds to days
                }
                let headerclassval = 2;
                let filetype;
                if (result.FileType == 'PDF') {
                    headerclassval = 2;
                    filetype = 'PDF';
                }
                if (result.MSD_CORE_Video_Resource__c) {
                    headerclassval = 5;
                    filetype = 'Video';
                }
                let updatedURL = this.getThumbnailURL(result.FileType);
                let videoThumbURL = result.Id;
                this.resource = {
                    id: result.Id,
                    title: result.Title,
                    subtitle: result.MSD_CORE_Topic__c,
                    imageUrl: (result.Id) ? updatedURL + videoThumbURL : noImage,
                    contentdocumentid: result.ContentDocumentId,
                    heading: filetype,
                    boldText: result.Title ? result.Title : '',
                    normalText: result.Description ? result.Description : '',
                    normalText1: result.MSD_CORE_Fulfillment_Method__c ?  result.MSD_CORE_Fulfillment_Method__c : '',
                    code: result.MSD_CORE_Resource_Code__c ? result.MSD_CORE_Resource_Code__c : '',
                    expiryDays: expiryDays,
                    headerClass: `header-color-${headerclassval}`,
                    headerClasslist: `header-color-list-${headerclassval}`,
                    showMenu: false,
                    isSelectedTile: false,
                    isSelectedList: false,
                    isSelectedTileColor: 'slds-var-m-around_medium ',
                    isSelectedListColor: 'listviewcls ',
                    downloadLink: sitepath + 'sfc/servlet.shepherd/document/download/' + result.ContentDocumentId + '?operationContext=S1',
                    isNewItem: result.MSD_CORE_IsNewItem__c
                }

                console.log('this.resource>>'+JSON.stringify(this.resource));
                
                this.showSpinner = false;
            })
            .catch(error => {
                console.error('Error getting resource data:'+ JSON.stringify(error));
                this.showSpinner = false;
            });
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

    handleSubmit() {
        this.validateInput();
        this.allValid = [
            ...this.template.querySelectorAll('lightning-input')
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (this.allValid) {
            const imageUrls = this.resId || this.extractVersionId(this.collectionData.ThumbnailUrl) || '';
            // create collection
            this.createCollection(imageUrls, null);
        } else {
            const firstInvalidInput = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, lightning-radio-group')]
                .find(inputCmp => !inputCmp.checkValidity());
            if (firstInvalidInput) {
                firstInvalidInput.focus();
            }
        }
    }

    // Create Collection
    createCollection(imageUrls, resourceId) {
        this.showSpinner = true;
        createCollection({ name: this.collectionName.trim(), imageUrls: imageUrls, resourceId : resourceId })
            .then((result) => {
                console.log('createCollection result>>',result);
                if (result === 'Name already used.') {
                    this.nameError = 'Collection with the same name already exists';
                } else if (result === 'Success') {
                    this.nameError = false;
                    this.resetFields();
                    this.navigateToCollections();
                }
                this.showSpinner = false;
            })
            .catch(error => {
                console.error('Error:', error);
                this.showSpinner = false;
            });
    }

    handleUpdate() {
        const name = this.collectionName || this.collectionData.name || '';
        const imageUrls = this.resId || this.extractVersionId(this.collectionData.ThumbnailUrl) || '';

        // Update Collection record
        updateCollection({ collectionId: this.collectionId, name, imageUrls })
            .then((result) => {
                if (result === 'Repeated Name') {
                    this.nameError = 'Collection with the same name already exists';
                } else if (result === 'Success') {
                    this.nameError = false;
                    this.resetFields();
                    this.navigateToCollections();
                }
            })
            .catch(error => {
                console.error('Error:', error);
                this.dispatchEvent(new CustomEvent('showtoast', {
                    detail: {
                        title: 'Error',
                        message: 'An error occurred while updating the collection. Please try again.',
                        variant: 'error'
                    }
                }));
            });
    }

    // Handle Create Collection with Resource
    handleCreatewithResource() {
        this.validateInput();
        this.allValid = [
            ...this.template.querySelectorAll('lightning-input')
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (this.allValid) { 
            const imageUrls = this.resId || this.extractVersionId(this.collectionData.ThumbnailUrl) || '';
            // create collection with Resource
            this.createCollection(imageUrls, this.resourceId);
        } else {
            const firstInvalidInput = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, lightning-radio-group')]
                .find(inputCmp => !inputCmp.checkValidity());
            if (firstInvalidInput) {
                firstInvalidInput.focus();
            }
        }
    }

    validateInput() {
        const inputField = this.template.querySelector('[data-id="clName"]');
        const value = inputField.value.trim();

        if (value === '') {
            inputField.setCustomValidity('Please enter a valid Collection Name');
        } else {
            inputField.setCustomValidity('');
        }

        inputField.reportValidity();
    }
    
    loadImages() {
        this.showSpinner = true;
        getImages()
            .then(result => {
                this.images = result.map(img => {
                    let updatedThumbURL = thumbURL;

                    if (img.fileType === 'JPG') {
                        updatedThumbURL = thumbURL.replace('ORIGINAL_Png', 'ORIGINAL_Jpg');
                    }
                    this.showSpinner = false;
                    return {
                        Id: img.id,
                        Title: img.title,
                        FileType: img.fileType,
                        ThumbnailUrl: `${updatedThumbURL}${img.id}`
                    };
                });
            })
            .catch(error => {
                console.error('Error loading images:', error);
                this.showSpinner = false;
            });
    }

    handlecloseresourceclick(event) {
        console.log('handlecloseresourceclick:::',event.detail);
        this.showresource = false;
        this.resourceId = null;
    }

    extractVersionId(url) {
        if (url == undefined || url == '') {
            return '';
        }
        const match = url.match(/versionId=([^&]+)/);
        const versionId = match ? match[1] : '';
        return (versionId && versionId !== 'undefined') ? versionId : '';
    }

    editUrl() {
        const currentUrl = window.location.href;
        this.isEdit = currentUrl.includes('/resources/collections/edit');
    }

    handleNameChange(event) {
        this.collectionName = event.target.value;
    }

    openImageModal() {
        this.isModalOpen = true;
    }

    closeImageModal() {
        this.isModalOpen = false;
    }

    handleImageSelect(event) {
        const imageUrl = event.currentTarget.dataset.imagepreview;
        this.resId = event.currentTarget.dataset.id;
        this.isSelectedImage = true;
        this.selectedImageUrl = imageUrl;
        this.isModalOpen = false;
        this.isThumbnailUrl = false;
    }

    handleDeletePreview() {
        this.isSelectedImage = false;
        this.selectedImageUrl = '';
        this.isThumbnailUrl = false;
        this.collectionData.ThumbnailUrl = '';
    }

    handleCancel() {
        window.history.back();
        // this.navigateToCollections();
    }

    resetFields() {
        this.collectionName = '';
        this.selectedImageUrl = '';
        this.isSelectedImage = false;
        this.isThumbnailUrl = false;
        this.collectionData = {};
    }

    navigateToCollections() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections'
            }
        });
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