import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import tileImage from '@salesforce/resourceUrl/MSD_CORE_HealthEQ_tile';

// Apex Method
import getCollectionList from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getCollectionList';
import addResourceToCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.addResourceToCollection';

// Custom Labels
import sitepath from '@salesforce/label/c.MSD_CORE_HEQ_SitePath_For_Download';
import NewItem from '@salesforce/label/c.MSD_CORE_HEQ_New_Item';
import addtocollection from '@salesforce/label/c.MSD_CORE_Add_Collection';
import collectionbody from '@salesforce/label/c.MSD_CORE_HEQ_CollectionModelBody';
import createNew from '@salesforce/label/c.MSD_CORE_HEQ_CreateNew';
import cancel from '@salesforce/label/c.MSD_CORE_Cancel';
import submit from '@salesforce/label/c.MSD_CORE_Submit';

export default class mSD_CORE_HEQ_GenericTiles extends NavigationMixin(LightningElement) {

    @api id;
    @api title;
    @api subtitle;
    @api jobcode;
    @api description;
    @api fulfillment;
    @api contentdocumentid;
    @api iscollection;
    @api category;
    @api item;
    @api gridType;
    @api menuOptions;
    @api genericview;
    @api iscloseicon;
    @track isBookmarked;
    @track sectionsDetails;
    @track isCollectionModel = false;
    @track isConfirmModel = false;
    @track collectionList = [];
    @track selecteddocRecordId;
    @track selectedCollectionName;
    @track selecteddocCollectionId;
    @track selectedResourceName;
    @track showSpinner = false;
    @track showPrintUser = false;
    @track showuser = false;
    @api feature;

    label = {
        NewItem,
        addtocollection,
        collectionbody,
        createNew,
        cancel,
        submit
    }

    connectedCallback() {
        console.log('connected callback of tile detail ' + JSON.stringify(this.sections));
        console.log('@api items in generic tiles==>', JSON.stringify(this.item));
        this.getCollectionList();
    }

    getItemClass(item) {
        return item.isChecked ? 'grid-item grey-background' : 'grid-item';
    }

    getCollectionList(){
        this.showSpinner = true;
        getCollectionList()
        .then(result => {
            console.log('result of getCollectionList>>', result);
            if (result.length>0) {
                for(let key in result) {
                    this.collectionList.push({value: result[key].Id, label: result[key].MSD_CORE_Collection_Name__c});
                }
            }
            console.log('>collectionList>>'+JSON.stringify(this.collectionList));
            this.showSpinner = false;
        })
        .catch(error => {
            console.error('Error getCollectionList::', error);
            this.showSpinner = false;
        });
    }

    get getListView() {
        console.log('Get Tile View');
        console.log('this.isTileView>>>', this.isTileView);
        return this.genericview == 'list' ? true : false;
    }

    handleShowMenu(event) {
        const itemId = event.currentTarget.dataset.id;
        const showMenuEvent = new CustomEvent('showmenu', {
            detail: { itemId, gridType: this.gridType }
        });
        this.dispatchEvent(showMenuEvent);
    }

    handleMenuClick(event) {
        const action = event.target.dataset.action;
        const itemId = event.target.dataset.id;
        console.log('### 3 action ' + action);
        console.log('### 4 action ' + itemId);
        const menuClickEvent = new CustomEvent('menuclick', {
            detail: { action, itemId }
        });

        switch (action) {
            case 'print':
                this.showPrintUser = true;
                console.log(`Print item ${itemId}`);
                break;
            case 'preview':
                this.handlePreview(itemId);
                break;
            case 'download':
                break;
            case 'Open':
                this.handleOpen(itemId);
                break;
            case 'email':
                this.showuser = true;
                console.log(`Email item ${itemId}`);
                break;
            case 'addToCollection':
                console.log(`Add item ${itemId} to collection`);
                break;
        }
    }


    handleSendEmail(event) {
        console.log('send email method called. 1111' + JSON.stringify(event.detail));
        this.showuser = false;
    }

    closeModal() {
        this.showPrintUser = false;
    }
    closeEmailModal(){
        this.showuser = false;
    }

    handleAddToCart() {
        console.log('Add to cartnmethod called.');
        this.showPrintUser = false;
        this.showSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/cart`
            }
        });
    }

    closeCustomerModel(event) {
        this.showPrintUser = false;
    }

    getSelectedCustomer(event){
        var getSelectedCustomer = event.detail;
        console.log('getSelectedCustomer'+ JSON.stringify(event.detail));
        if(getSelectedCustomer != null){

           if (this.feature === 'print') {
                this.handleAddToCart();
            } else {
                this.handleSendEmail(event.detail);
            }
        }
        this.showPrintUser = false;

    }


    handleCheck(event) {
        console.log('handleCheck');
        console.log('this.contentdocumentid>>', this.contentdocumentid);
        const selectedEvent = new CustomEvent('selectdocument', {
            detail: { id: this.contentdocumentid, isSelected: true }
        });
        this.dispatchEvent(selectedEvent);
    }


    @api
    get bookmarked() {
        return this.isBookmarked;
    }
    set bookmarked(value) {
        this.isBookmarked = value;
        console.log('isBookMarked ' + this.isBookmarked);
    }

    tileImageUrl = tileImage;


    handleKeystroke(event) {
        let bkId = event.target.dataset.aid;
        if (event.key === 'Enter') {
            event.preventDefault();
            const element = this.template.querySelector(`[data-aid="${bkId}"]`);
            if (element) {
                element.click();
            }
        }
    }

    handleViewDetails(event) {
        const topicTitle = 'Test';
        const contDocId = event.target.dataset.id;
        if (this.category == 'Collections') {
            this.handleOpen(contDocId);
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `/resources/detailed?topicId=${encodeURIComponent(contDocId)}&title=${encodeURIComponent(topicTitle)}`
                }
            });
        }
    }


    handleBookmark(event) {
        const customBookmarkEvent = new CustomEvent('handlebookmark', {
            detail: {
                id: this.id
            }
        })
        this.dispatchEvent(customBookmarkEvent);
    }

    handleUnBookmark(event) {
        const customUnBookmarkEvent = new CustomEvent('handleunbookmark', {
            detail: {
                id: this.id
            }
        })
        this.dispatchEvent(customUnBookmarkEvent);
    }

    // For Model Open(Add to Collection)
    modelClick(event) {
        this.selectedResourceName = event.currentTarget.dataset.resourcename;
        this.selecteddocRecordId = event.currentTarget.dataset.contentdocumentid;
        this.isCollectionModel = true;
    }

    handleCloseCollectionModel() {
        this.isCollectionModel = false;
    }

    handleCollectionChange(event) {
        this.selecteddocCollectionId = event.detail.value;
    }

    handlecollectionsubmit(event) {
        this.isCollectionModel = false;
        this.showSpinner = true;
        addResourceToCollection({
            "collectionId": this.selecteddocCollectionId,
            "resourceId": this.selecteddocRecordId
        }).then((result) => {
            console.log('result of addResourceToCollection>>', result);
            this.selectedCollectionName = result;
            this.showSpinner = false;
        }).catch(error => {
            console.log('Error in addResourceToCollection: ' + JSON.stringify(error));
            this.showSpinner = false;
        });

        this.isConfirmModel = true;
    }

    handleCloseConfirmModel(event) {
        this.isConfirmModel = false;
    }

    // Close icon click on Resource 
    closeResource() {
        const closeresource = new CustomEvent('closeresourceclick', {
            detail: true
        })
        this.dispatchEvent(closeresource);
    }

    // Preview
    handlePreview(resourceId) {
        console.log('### 5 resourceId>>', resourceId);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/preview?recordId=${encodeURIComponent(resourceId)}`
            }
        });
    }

    handleCreateNew(event) {
        let resourceId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/collections/new?resourceId=${encodeURIComponent(resourceId)}`
            }
        });
    }

    handleOpen(contDocId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections/view?cid=' + contDocId
            }
        });
    }
}