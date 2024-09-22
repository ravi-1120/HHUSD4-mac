import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';
//Apex Classes
import getImages from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getImages';
import createCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.createCollection';
import updateCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.updateCollection';
import getCollectionRecord from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getCollectionRecord';
//Custom Labels
import thumbURL from '@salesforce/label/c.HEQ_Sandbox_URL';
import newCollection from '@salesforce/label/c.HEQ_New_Collection';
import createBtn from '@salesforce/label/c.HEQ_Create';
import cancelBtn from '@salesforce/label/c.HEQ_Cancel';
import cllName from '@salesforce/label/c.HEQ_Collection_Name';
import pleaseEnterCLName from '@salesforce/label/c.HEQ_Please_Enter_CLName';
import bannderHeader from '@salesforce/label/c.HEQ_Banner_Header_Title';
import browseBtn from '@salesforce/label/c.HEQ_Browse';
import removeBtn from '@salesforce/label/c.HEQ_Remove';
import closeBtn from '@salesforce/label/c.HEQ_Close_Btn';
import activeLabel from '@salesforce/label/c.HEQ_Active_Label';

export default class MSD_CORE_UserCollections extends NavigationMixin(LightningElement) {
    @track collectionName = '';
    @track selectedImageUrl = '';
    @track collectionData = {};
    @track images = [];
    @track isModalOpen = false;
    @track isSelectedImage = false;
    @track isThumbnailUrl = false;
    @track isEdit = false;

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
        activeLabel
    };

    connectedCallback() {
        this.editUrl();
        this.loadImages();
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.collectionId = currentPageReference.state?.cid;
            this.fetchCollectionData();
        }
    }

    fetchCollectionData() {
        this.showSpinner = true;
        if (this.collectionId) {
            console.log('collection ID in edit:', this.collectionId);
            getCollectionRecord({ collectionId: this.collectionId, userId: this.userId })
                .then(result => {
                    console.log('Result from getCollectionRecord:', result);
                    if (result) {
                        this.collectionData = {
                            ...result,
                            ThumbnailUrl: result.imageUrl !== '' ? `${thumbURL}${result.imageUrl}` : 'noImage'
                        };
                        console.log('Mapped collectionData:', this.collectionData);
                        const versionId = this.extractVersionId(this.collectionData.ThumbnailUrl);
                        this.isThumbnailUrl = !!versionId;
                    } else {
                        this.collectionData = {};
                        this.isThumbnailUrl = false;
                    }
                    this.error = null;
                    this.showSpinner = false;
                    console.log('Collection Data in edit result:', JSON.stringify(result));
                    console.log('Collection Data in edit:', JSON.stringify(this.collectionData));
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
            createCollection({ name: this.collectionName, imageUrls })
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
                });
        } else {
            const firstInvalidInput = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea, lightning-radio-group')]
                .find(inputCmp => !inputCmp.checkValidity());
            if (firstInvalidInput) {
                firstInvalidInput.focus();
            }
        }
    }

    extractVersionId(url) {
        if(url == undefined || url == ''){
            return '';
        }
        const match = url.match(/versionId=([^&]+)/);
        const versionId = match ? match[1] : '';
        return (versionId && versionId !== 'undefined') ? versionId : '';
    }

    handleCancel() {
        this.navigateToCollections();
    }

    loadImages() {
        getImages()
            .then(result => {
                this.images = result.map(img => {
                    let updatedThumbURL = thumbURL;

                    if (img.fileType === 'JPG') {
                        updatedThumbURL = thumbURL.replace('ORIGINAL_Png', 'ORIGINAL_Jpg');
                    }

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
            });
    }

    handleUpdate() {
        const name = this.collectionName || this.collectionData.name || '';
        const imageUrls = this.resId || this.extractVersionId(this.collectionData.ThumbnailUrl) || '';
        console.log('Collection ID:', this.collectionId);
        console.log('Collection Name:', name);
        console.log('Collection Image:', imageUrls);

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
}