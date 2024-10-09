import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Apex Method
import getCartItems from '@salesforce/apex/MSD_CORE_HEQ_CartController.getCartRecords';
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';
import updateCartQuantity from '@salesforce/apex/MSD_CORE_HEQ_CartController.updateCartQuantity';
import deleteCartItem from '@salesforce/apex/MSD_CORE_HEQ_CartController.deleteCartItem';
import addOrUpdateCartRecords from '@salesforce/apex/MSD_CORE_HEQ_CartController.addOrUpdateCartRecords';
import submitPrintOrder from '@salesforce/apex/MSD_CORE_HEQ_CartController.submitPrintOrder';

//Custom Labels
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
import customerProfileName from '@salesforce/label/c.MSD_CORE_HEQ_CustomerProfile';

//Static Resources
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';

export default class MSD_CORE_HEQ_Cart extends NavigationMixin(LightningElement) {

    @track showSpinner = false;
    @track showResourceSelector = false;
    @track displayedData = [];
    @track profileName;
    @track quantityValue;
    @track currentCartId;
    @track isSelfPrint = false;
    @track selfPrintAddress = false;
    @track deleteConfirmation = false;
    @track showOtherAddress = false;
    @track accountId = '';
    @track selectedCustomer;

    connectedCallback() {
        this.showSpinner = true;
        this.getUserData();
        this.getCartRecords();
    }

    renderedCallback() {
        this.displayedData = this.displayedData?.length ? this.displayedData : undefined;
    }

    getUserData() {
        getUserProfileName()
            .then(profileName => {
                this.profileName = profileName;
                if (this.profileName == customerProfileName) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: '/error'
                        }
                    });
                }
                console.log('Profile Name:', this.profileName);
            })
            .catch(error => console.error('Error getting profile name:', error));
    }

    handleSelectedResources(event) {
        console.log('handleSelectedResources', JSON.stringify(event.detail.itemIds));

        const customerIds = this.currentCartId ? [this.currentCartId] : [];
        let itemIds = event.detail.itemIds;
        console.log('currentCartId', JSON.stringify(customerIds));

        if(itemIds?.length){    
            addOrUpdateCartRecords({
                customerIds: customerIds,
                resourceIds: itemIds,
                selfPrint: this.isSelfPrint
            }).then((result) => {
                if (result === 'Success') {
                    this.showResourceSelector = false;
                    this.currentCartId = '';
                    this.isSelfPrint = false;
                    this.getCartRecords();
                }
                console.log('result of addOrUpdateCartRecords>>', result);
                this.showSpinner = false;
            }).catch(error => {
                console.error('Error in addOrUpdateCartRecords: ' + JSON.stringify(error));
                this.showSpinner = false;
            });
        }
    }

    getCartRecords() {
        this.showSpinner = true;

        getCartItems({
        }).then((result) => {
            console.log('getCartItems>>', result);
            if (result) {
                let updatedURL = this.getThumbnailURL('THUMB');
                this.displayedData = result.map(item => ({
                    ...item,
                    resources: item.resources.map(resource => ({
                        ...resource,
                        ThumbnailUrl: resource.resourceId ? `${updatedURL}${resource.resourceId}` : noImage
                    }))
                }));
                console.log('result of getCartRecords>>', this.displayedData);
                this.showSpinner = false;
            }
        }).catch(error => {
            console.error('Error in getCartRecords: ' + JSON.stringify(error.message));
            this.showSpinner = false;
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
            default:
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=THUMB720BY480');
        }

        console.log('Updated ThumbURL:', updatedThumbURL);
        return updatedThumbURL;
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

    handleContinuebrowsing() {
        this.showSpinner = true;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources?type=' + encodeURIComponent('Browse All')
            }
        });
    }

    handleAddmoreItems(event) {
        this.currentCartId = event.currentTarget.dataset.id;
        this.isSelfPrint = event.currentTarget.dataset.isselfprint
        console.log('current Id>>' , this.currentCartId);
        console.log('current isSelfPrint>>' , this.isSelfPrint);
        this.showResourceSelector = true;
    }

    handleQuantity(event) {
        const resourceId = event.currentTarget.dataset.id;
        let newQuantity = parseInt(event.target.value, 10);

        if (isNaN(newQuantity) || newQuantity < 1) {
            newQuantity = 1;
        } else if (newQuantity > 100) {
            newQuantity = 100;
        }

        event.target.value = newQuantity
        this.validateInput(event.target);

        this.handleChangeQty(resourceId, newQuantity);
        console.log(`Quantity for resource ${resourceId}:`, newQuantity);
    }

    handleIncrement(event) {
        const resourceId = event.currentTarget.dataset.id;
        let currentQuantity = this.getQuantityByResourceId(resourceId);
        let newQuantity = Math.min(currentQuantity + 1, 100);


        this.handleChangeQty(resourceId, newQuantity);
        console.log(`Incremented quantity for resource ${resourceId}:`, newQuantity);
    }

    handleDecrement(event) {
        const resourceId = event.currentTarget.dataset.id;
        let currentQuantity = this.getQuantityByResourceId(resourceId);

        if (currentQuantity > 1) {
            let newQuantity = Math.max(currentQuantity - 1, 1);
            this.handleChangeQty(resourceId, newQuantity);
        }
    }

    handleChangeQty(resourceId, newQuantity) {
        this.displayedData = this.displayedData.map(item => ({
            ...item,
            resources: item.resources.map(resource =>
                resource.cartId === resourceId
                    ? { ...resource, quantity: newQuantity }
                    : resource
            )
        }));

        updateCartQuantity({
            recordId: resourceId,
            newQuantity: newQuantity
        }).then((result) => {
            console.log('updateCartQuantity>>', result);
            if (result) {
                this.showSpinner = false;
            }
            this.updateCartCountEvent();
        }).catch(error => {
            console.error('Error in updateCartQuantity: ' + JSON.stringify(error));
            this.showSpinner = false;
        });
    }

    getQuantityByResourceId(resourceId) {
        for (let item of this.displayedData) {
            for (let resource of item.resources) {
                if (resource.cartId === resourceId) {
                    return resource.quantity;
                }
            }
        }
        return 1;
    }

    handleDeleteItem(event){
        this.currentItemToDelete = '';
        this.currentItemToDelete = event.currentTarget.dataset.id;
        this.deleteConfirmation = true;
    }

    handleClosePopup(){
        this.deleteConfirmation = false;
    }

    handleDeleteCartItem() {
        this.showSpinner = true;
        deleteCartItem({
            cartItemId: this.currentItemToDelete
        }).then((result) => {
            console.log('handleDeleteItem>>', result);
            if (result) {
                this.getCartRecords();
                this.updateCartCountEvent();
                this.currentItemToDelete = '';
                this.deleteConfirmation = false;
                this.showSpinner = false;
            }
        }).catch(error => {
            console.error('Error in handleDeleteCartItem: ' + JSON.stringify(error));
            this.showSpinner = false;
        });
    }

    validateInput(inputElement) {
        inputElement.setCustomValidity("");
        inputElement.reportValidity();
    }

    handleCloseSelector(){
        this.showResourceSelector = false;
        this.currentCartId = '';
        this.isSelfPrint = false;
    }

    handleCloseOtherAddress(){
        this.showOtherAddress = false;
    }

    handleAddressRefresh(){
        this.showSpinner = true;
        this.getCartRecords();
        this.showOtherAddress = false;
        this.showSpinner = false;
    }

    handleChangeAddress(event){
        const {account, selfprint, customer} = event.currentTarget.dataset;
        this.accountId = account;
        this.selfPrintAddress = selfprint;
        this.showOtherAddress = true;
        this.selectedCustomer = customer;
    }

    handlePrintOrder() {
        this.showSpinner = true;
        if(this.displayedData){
            submitPrintOrder({})
            .then((result) => {
                console.log('submitPrintOrder>>', result);
                if (result) {
                    this.showSpinner = false;
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: '/order-confirmation'
                        }
                    });
                }
            }).catch(error => {
                console.error('Error in submitPrintOrder: ' + JSON.stringify(error));
                this.showSpinner = false;
            });
        }
    }

    updateCartCountEvent(){
        this.dispatchEvent(new CustomEvent('updateCartCount', {
            detail: '',
            bubbles: true,
            composed: true,
        }));
    }
}