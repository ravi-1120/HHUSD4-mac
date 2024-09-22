import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';

import sitepath from '@salesforce/label/c.MSD_CORE_HEQ_SitePath';
import errormsg from '@salesforce/label/c.MSD_CORE_HEQ_PreviewError';
import AddToCart from '@salesforce/label/c.MSD_CORE_Add_to_Cart';
import AddToCollection from '@salesforce/label/c.MSD_CORE_Add_Collection';

import getResourceData from '@salesforce/apex/MSD_CORE_HEQ_PreviewController.getResourceData';
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';
// import getBusinessRule from '@salesforce/apex/MSD_CORE_PreviewController.getBusinessRule';

export default class MSD_CORE_HEQ_Preview extends NavigationMixin(LightningElement) {

    @api id;
    @track recordId;
    @track resource;
    @track contentsize;
    @track filetype;
    @track iframeurl;
    @track profileName;
    @track isVideoResource = false;
    // @track isButtonVisible;
    @track showSpinner = false;
    label = {
        errormsg,
        AddToCart,
        AddToCollection
    }


    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            var urlStateParameters = currentPageReference.state;
            this.recordId = urlStateParameters.recordId;
        }
    }

    connectedCallback() {
        // this.businessRule();
        this.resourceData();
        this.getUserData();
    }

    getUserData() {
        getUserProfileName()
            .then(profileName => {
                console.log('profileName>>>',profileName);
                this.profileName = profileName;
            })
            .catch(error => console.error('Error getting profile name:', error));

    }
    get isCustomerProfile() {
        return this.profileName == 'HEQ Customer';
    }
    get isAccountExeProfile() {
        return this.profileName == 'HEQ - Account Exe';
    }

    // Commenting because as of now we don't have userstory related to this
    // businessRule() {
    //     getBusinessRule() 
    //         .then((result) => {
    //             console.log('result ofgetBusinessRule>>',result);
    //             this.isButtonVisible = result.MSD_CORE_Can_Download__c;
    //         })
    //         .catch((error) => {
    //             console.log('error in getBusinessRule>>>',error);
    //         })
    // }

    resourceData() {
        this.showSpinner = true;
        getResourceData({recordId : this.recordId})
            .then((result) => {
                if(result.message){
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: `/error`
                        }
                    });
                }

            console.log('result of getResourceData>>', result);

            if (result.contentVersion.FileType == 'PDF') {
                this.resource = result.contentVersion;
                this.iframeurl = sitepath + '/sfc/servlet.shepherd/document/download/'+this.resource.ContentDocumentId+'?operationContext=S1';
                console.log('this.iframeurl>>>>>',this.iframeurl);
                this.filetype = this.resource.FileType;
                this.contentsize = (this.resource.ContentSize / (1024 * 1024)).toFixed(2);
            } 
            if (result.contentVersion.MSD_CORE_Video_Resource__c) {
                this.resource = result.contentVersion;
                this.isVideoResource = true;
                this.iframeurl = this.resource.MSD_CORE_Video_Resource__c;
                this.filetype = 'Video';
                this.contentsize = (this.resource.ContentSize / (1024 * 1024)).toFixed(2);
            }

            this.showSpinner = false;
        })
            .catch ((error) => {
            console.log('error in getResourceData>>>', error);
            this.showSpinner = false;
        })
    }

    handleCancel() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/`
            }
        });
    }

    handleAddToCart(event) {
        console.log('Add to Cart clicked');
        let resourceId = event.target.dataset.id;
        console.log('resourceId preview>>',resourceId);
        resourceId = resourceId.split('-');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/add-to-cart?recordId=${encodeURIComponent(resourceId[0])}`
            }
        });
    }

//     handleAddToCart(event) {
//     const resourceId = event.target.dataset.id;
//     if (resourceId) {
//         console.log('Add to Cart clicked');
//         console.log('resourceId preview>>', resourceId);

//         // Redirect to the add-to-cart page with the encoded resourceId
//         this[NavigationMixin.Navigate]({
//             type: 'standard__webPage',
//             attributes: {
//                 url: `/add-to-cart?recordId=${encodeURIComponent(resourceId)}`
//             }
//         });
//     } else {
//         console.error('resourceId is undefined or null');
//     }
// }


    handleAddToCollection() {
        console.log('Add to Collection clicked');
    }
}