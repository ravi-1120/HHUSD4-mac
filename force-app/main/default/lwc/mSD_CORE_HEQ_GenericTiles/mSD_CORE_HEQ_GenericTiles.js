import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';

// Apex Method
import getCollectionList from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getCollectionList';
import addResourceToCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.addResourceToCollection';
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';
import getUser from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getuser';
import saveDownloadHistory from '@salesforce/apex/MSD_CORE_HEQ_DownloadHistory.saveDownloadHistory';
import recordDownloadAndPreview from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.recordDownloadAndPreview';
import sendEmailNotification from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.sendEmailNotification';
import addOrUpdateCartRecords from '@salesforce/apex/MSD_CORE_HEQ_CartController.addOrUpdateCartRecords';

// Custom Labels
import sitepath from '@salesforce/label/c.MSD_CORE_HEQ_SitePath_For_Download';
import NewItem from '@salesforce/label/c.MSD_CORE_HEQ_New_Item';
import addtocollection from '@salesforce/label/c.MSD_CORE_Add_Collection';
import collectionbody from '@salesforce/label/c.MSD_CORE_HEQ_CollectionModelBody';
import createNew from '@salesforce/label/c.MSD_CORE_HEQ_CreateNew';
import cancel from '@salesforce/label/c.MSD_CORE_Cancel';
import submit from '@salesforce/label/c.MSD_CORE_Submit';
import customerProfileName from '@salesforce/label/c.MSD_CORE_HEQ_CustomerProfile';

//Static Resource
import tileImage from '@salesforce/resourceUrl/MSD_CORE_HealthEQ_tile';

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
    @track showPopup = false;
    @track profileName;
    @track cid;
    @track resId;
    @api feature;

    urlParams;

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
        this.getUserData();

        const url = window.location.href;
        const parts = url.includes('/healtheq') ? url.split('/healtheq') : null;
        if (parts && parts.length > 1) {
            this.urlParams = parts[1].trim();
        }
        const decodedRetUrl = decodeURIComponent(url);
        this.cid = this.getUrlParamValue(decodedRetUrl, 'cid');
        console.log('cid >>' + this.cid);

        const paramValue = this.getUrlParamValue(window.location.href, 'Id');
        getUser({ userId: paramValue })
            .then(result => {
                this.userVar = result;
                this.userId = paramValue;
                const firstName = this.userVar.FirstName || '';
                const lastName = this.userVar.LastName || '';
                this.fullName = `${firstName} ${lastName}`.trim();
                console.log("getUser generic tiles==>: " + JSON.stringify(this.fullName));
            })
            .catch(error => {
                console.log("getUser error==>: " + JSON.stringify(error));
            });

        // document.addEventListener('click', this.closeDropdown.bind(this));

    }


    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    getUserData() {
        getUserProfileName()
            .then(profileName => {
                this.profileName = profileName;
                console.log('Profile Name:', this.profileName);
            })
            .catch(error => console.error('Error getting profile name:', error));
    }

    // closeDropdown(event) {
    //     console.log('Called closeDropdown', event.target);
    //     const dropdownElement = this.template.querySelector('.hide-dropdown');
    //     if (dropdownElement && !dropdownElement.contains(event.target)) {
    //         this.dispatchEvent(new CustomEvent("closedropdown", {
    //             detail: 'closedropdown'
    //         }))
    //     }
    // }

    getItemClass(item) {
        return item.isChecked ? 'grid-item grey-background' : 'grid-item';
    }

    getCollectionList() {
        this.showSpinner = true;
        getCollectionList()
            .then(result => {
                console.log('result of getCollectionList>>', result);
                if (result.length > 0) {
                    for (let key in result) {
                        this.collectionList.push({ value: result[key].Id, label: result[key].MSD_CORE_Collection_Name__c });
                    }
                } else {
                    this.collectionList.push({ value: '', label: 'No Collection found!' });
                }
                console.log('>collectionList>>' + JSON.stringify(this.collectionList));
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
        console.log('handleShowMenu>>> ', event.target);
        const itemId = event.currentTarget.dataset.id;
        const showMenuEvent = new CustomEvent('showmenu', {
            detail: { itemId, gridType: this.gridType }
        });
        this.dispatchEvent(showMenuEvent);
    }



    handleDownload(event) {
        event.preventDefault();
        let { link, resourcename, id } = event.currentTarget.dataset;
        console.log('#Link ' + link);
        if (this.profileName == customerProfileName) {
            this.saveDownloadActivity(id);
        }
        const anchor = document.createElement('a');
        anchor.href = link;
        anchor.target = '_self';
        anchor.download = resourcename;
        document.body.appendChild(anchor);
        anchor.click();
        document.body.removeChild(anchor);
    }

    saveDownloadActivity(id) {
        console.log('saveDownloadActivity Called');
        saveDownloadHistory({ resourceId: id, cid: this.cid })
            .then((result) => {
                console.log('saveDownloadHistory ', result);
            })
            .catch((error) => {
                console.log('Error in saveDownloadActivity>>>', error);
            })
    }

    handleMenuClick(event) {
        const action = event.target.dataset.action;
        const itemId = event.target.dataset.id;
        this.resId = itemId;
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
                recordDownloadAndPreview({ resourceId: itemId, isDownload: false })
                    .then(() => {
                        console.log('### User Activity Recorded');
                    })
                    .catch(error => {
                        console.log('### Error Occcured while recording User Activity');
                    });
                break;
            case 'download':
                recordDownloadAndPreview({ resourceId: itemId, isDownload: true })
                    .then(() => {
                        console.log('### User Activity Recorded');
                    })
                    .catch(error => {
                        console.log('### Error Occcured while recording User Activity');
                    });
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

    handleSendEmail(arr) {
        console.log('send email method called. 1111' + this.item.id + '>>>' + this.item.boldText + '>>>>>' + JSON.stringify(arr));
        this.showSpinner = true;
        sendEmailNotification({
            userInfoMapList: arr,
            orderNum: this.item.id,
            resourceName: this.item.boldText,
            resourceID: this.item.code,
            username: this.fullName,
            recordID: this.item.id,
            userId: this.userId

        }).then((result) => {
            console.log('result of sendEmailNotification>>', result);
            this.showPopup = true;
            console.log('successpopup', this.showPopup);
            this.showSpinner = false;
        }).catch(error => {
            console.log('Error in sendEmailNotification: ' + JSON.stringify(error));
            this.showSpinner = false;
        });

        this.showuser = false;
    }

    handleAddToCart(data, selfprint) {
        this.showSpinner = true;
        let idList = data.map(item => item.id);
        let resourceId = [];
        resourceId.push(this.item.id);

        console.log('Ids>>', resourceId);
        console.log('Customers>>', idList);
        addOrUpdateCartRecords({
            customerIds: idList,
            resourceIds: resourceId,
            selfPrint: selfprint
        }).then((result) => {
            if(result === 'Success'){
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: `/cart`
                    }
                });
            }
            console.log('result of updateCartRecords>>', result);
            this.showSpinner = false;
        }).catch(error => {
            console.log('Error in updateCartRecords: ' + JSON.stringify(error));
            this.showSpinner = false;
        });

        this.showuser = false;
    }


    closePopup() {
        this.showPopup = false;
    }

    closeModal() {
        this.showPrintUser = false;
    }
    closeEmailModal() {
        this.showuser = false;
    }

    // handleAddToCart() {
    //     console.log('Add to cartnmethod called.');
    //     this.showPrintUser = false;
    //     this.showSpinner = true;
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__webPage',
    //         attributes: {
    //             url: `/cart`
    //         }
    //     });
    // }

    closeCustomerModel(event) {
        this.showPrintUser = false;
    }

    getSelectedCustomer(event) {
        var getSelectedCustomer = event.detail;
        console.log('getSelectedCustomer' + JSON.stringify(event.detail));
        if (getSelectedCustomer != null) {

            if (event.detail.feature == 'print') {
                this.handleAddToCart(getSelectedCustomer.data, getSelectedCustomer.selfprint);
            } else if (event.detail.feature == 'edeliver') {
                this.handleSendEmail(event.detail.data);
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
            recordDownloadAndPreview({ resourceId: contDocId, isDownload: false })
                .then(() => {
                    console.log('### User Activity Recorded');
                })
                .catch(error => {
                    console.log('### Error Occcured while recording User Activity');
                });
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `/resources/detailed?topicId=${encodeURIComponent(contDocId)}&ret_URL=${this.urlParams}`
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
        const inputField = this.template.querySelector('[data-id="collectioncombo"]');
        const value = inputField.value.trim();
        if (value === '') {
            inputField.setCustomValidity('Please select collection record');
            inputField.reportValidity();
        } else {
            this.selecteddocCollectionId = event.detail.value;
            inputField.setCustomValidity('');
        }
    }

    handlecollectionsubmit(event) {
        if (this.selecteddocCollectionId == undefined || this.selecteddocCollectionId == '') {
            const inputField = this.template.querySelector('[data-id="collectioncombo"]');
            const value = inputField.value.trim();
            if (value === '') {
                inputField.setCustomValidity('Please select collection record');
                inputField.reportValidity();
            } else {
                inputField.setCustomValidity('');
            }
        } else {
            this.showSpinner = true;
            addResourceToCollection({
                "collectionId": this.selecteddocCollectionId,
                "resourceId": this.selecteddocRecordId
            }).then((result) => {
                console.log('result of addResourceToCollection>>', result);
                if (result == 'Resource already mapped!') {
                    this.showSpinner = false;
                    this.isCollectionModel = false;
                    this.showNotification('success', 'Resource already mapped!');
                } else {
                    this.isCollectionModel = false;
                    this.selectedCollectionName = result;
                    this.showSpinner = false;
                    this.isConfirmModel = true;
                }
            }).catch(error => {
                console.log('Error in addResourceToCollection: ' + JSON.stringify(error));
                this.showSpinner = false;
            });
        }
    }

    handleCloseConfirmModel(event) {
        this.isConfirmModel = false;
    }

    // Toast Message
    showNotification(type, message) {
        this.template.querySelector('c-custom-toast').showToast(type, message);
    }

    // Close icon click on Resource 
    closeResource() {
        const closeresource = new CustomEvent('closeresourceclick', {
            detail: { id: this.item.contentDocumentId, name: this.item.title }
        })
        this.dispatchEvent(closeresource);
    }

    // Preview
    handlePreview(resourceId) {
        console.log('### 5 resourceId>>', resourceId);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/detailed?topicId=${encodeURIComponent(resourceId)}&ret_URL=${encodeURIComponent(this.urlParams)}`
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

    handleCheckbox() {
        console.log('Checkbox');
    }

    handleResourceName(event) {
        this.selectedResourceName = event.currentTarget.dataset.resourcename;
        this.selecteddocRecordId = event.currentTarget.dataset.contentdocumentid;
    }
}