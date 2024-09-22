import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';

import sitepath from '@salesforce/label/c.MSD_CORE_HEQ_SitePath';
import errormsg from '@salesforce/label/c.MSD_CORE_HEQ_PreviewError';
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
// import noImage from '@salesforce/resourceUrl/HEQ_No_Image';

import getResourceData from '@salesforce/apex/MSD_CORE_HEQ_PreviewController.getResourceData';
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';
import FileDetails from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.FileDetails';
import AddToCart from '@salesforce/label/c.MSD_CORE_Add_to_Cart';
import Details from '@salesforce/label/c.MSD_CORE_Details';
import FileName from '@salesforce/label/c.MSD_CORE_File_Name';
import FileSize from '@salesforce/label/c.MSD_CORE_File_Size';
import FileType from '@salesforce/label/c.MSD_CORE_File_Type';
import Close from '@salesforce/label/c.MSD_CORE_Close_Btn';
import cancel from '@salesforce/label/c.MSD_CORE_Cancel';
import OK from '@salesforce/label/c.MSD_CORE_Ok';

export default class MSD_CORE_HEQ_AddToCart extends NavigationMixin(LightningElement) {
    @api id;
    @track recordId;
    @track resource;
    @track contentsize;
    @track filetype;
    @track iframeurl;
    @track profileName;
    @track isVideoResource = false;
    @track showModal = false;
    @track deliveryMethod = '';
    @track customer = '';
    @track isOkDisabled = true;
    @track deliverySelection = false;
    // @track getSelectedCustomer = null;
    @track customerSelection= false;

    @track zoomLevel = 100;
    @track imageUrl;
    showSpinner = false;
    topicId;

    @track showuser = false;

    label = {
        errormsg,
        AddToCart,
        Details,
        FileName,
        FileSize,
        FileType,
        Close,
        cancel,
        OK
    }

    deliveryMethodOptions = [
        { label: 'e-delivery', value: 'e-delivery' },
        { label: 'print', value: 'print' },
        { label: 'download', value: 'download' },
        { label: 'email-to-self', value: 'email-to-self' }
    ];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            var urlStateParameters = currentPageReference.state;
            this.recordId = urlStateParameters.recordId;
        }
    }

    connectedCallback() {
        this.resourceData();
        this.getUserData();
        this.showSpinner = true;
        const urlParams = new URLSearchParams(window.location.search);
        // let topicIdval = urlParams.get('Id');
        // let topicIdval= this.recordId;
        // console.log('topicIdval',topicIdval );
        // this.topicId = topicIdval.split('-');
        this.fetchFileDetails();
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

    resourceData() {
        this.showSpinner = true;
        getResourceData({recordId : this.recordId})
            .then((result) => {
                 // if(result.message){
                //     this[NavigationMixin.Navigate]({
                //         type: 'standard__webPage',
                //         attributes: {
                //             url: `/error`
                //         }
                //     });
                // }

                if (result.contentVersion.FileType == 'PDF') {
                    this.resource = result.contentVersion;
                    this.iframeurl = sitepath + 'MSD_CORE_PreviewResource?recordId=' + this.recordId;
                    this.filetype = this.resource.FileType;
                    this.contentsize = (this.resource.ContentSize / (1024 * 1024)).toFixed(2);
                } else if (result.contentVersion.MSD_CORE_Video_Resource__c) {
                    this.resource = result.contentVersion;
                    this.isVideoResource = true;
                    this.iframeurl = this.resource.MSD_CORE_Video_Resource__c;
                    this.filetype = 'Video';
                    this.contentsize = (this.resource.ContentSize / (1024 * 1024)).toFixed(2);
                }

                this.showSpinner = false;
            })
            .catch((error) => {
                console.log('error in getResourceData>>>', error);
                this.showSpinner = false;
            });
    }

    handleAddToCart() {
        this.showModal = true;
    }

    getSelectedCustomer(event){
        var getSelectedCustomer = event.detail;
        console.log('getSelectedCustomer'+JSON.stringify(event.detail));
        if(getSelectedCustomer != null){
            this.customerSelection= true;
        }
        else{
            this.customerSelection= false;
        }
        this.showuser = false;
        this.updateOkDisabled();

    }

    closeCustomerModel(event) {
        this.showuser = false;
    }

    closeModal() {
        this.showModal = false;
        this.deliveryMethod = '';
        this.customer = '';
        // this.isOkDisabled = true;
    }

    handleChange(event) {
        const { name, value } = event.target;
        if (name === 'deliveryMethod') {
            this.deliveryMethod = value;
            if(event.target.value!=null){
               this.deliverySelection = true;
            } else{
                this.deliverySelection = false;
            }
            this.updateOkDisabled();
        }
    }

    // handleOk() {
    //     this.showModal = false;
    //     this.deliverySelection= false;
    //     this.getSelectedCustomer= null;
    // }
    handleOk() {
    this.showModal = false;
    this.deliverySelection = false;
    this.customerSelection = false;
    this.deliveryMethod = null;
    this.customer = null;
    this.isOkDisabled = true;
}

    chooseCustomer() {
        this.showuser = true;
    }

    closeCustomerModal(event) {
        console.log('closeCustomerModal');
        this.showuser = false;
    }

    closeCustomerModel(event) {
        this.showuser = false;
    }

    // Close popup
    closePopup() {
        this.isPopupOpen = false;
        this.filteredCustomers = [];isOkDisabled
        // this.searchKey = null;
        this.norecord = false;
        this.updateOkDisabled();
    }


  
  updateOkDisabled(){
    if(this.customerSelection && this.deliverySelection){
        this.isOkDisabled = false;
        console.log('Value of isOkDisabled is:-', this.isOkDisabled);
    } else{
        this.isOkDisabled = true; 
        console.log('Value of isOkDisabled is:-', this.isOkDisabled);
    }
  }

// handleSelectCustomer() {
//     console.log('Selected Customer ID:', this.selectedCustomerId);

//     // Verify if selectedCustomerId is set and if filteredCustomers has data
//     if (this.selectedCustomerId && this.filteredCustomers.length > 0) {
//         // Filter to find the selected customer
//         const selectedCustomer = this.filteredCustomers.find(customer => 
//             customer.Id === this.selectedCustomerId
//         );
//         console.log('Selected Customer:', JSON.stringify(selectedCustomer));

//         if (selectedCustomer) {
//             // this.isOkDisabled = false;
//             this.selectedCustomers = [selectedCustomer];
//             this.customerSelection = true;
//         } else {
//             console.warn('Customer not found.');
//             this.selectedCustomers = [];
//         }
//     } else {
//         // this.isOkDisabled = true;
//         this.customerSelection = false;
//         console.warn('No selectedCustomerId or filteredCustomers is empty.');
//         this.selectedCustomers = [];
//     }

//     this.closePopup();
// }


    get zoomPercentage() {
        return this.zoomLevel;
    }

    get thumbnailStyle() {
        return `transform: scale(${this.zoomLevel / 100});`;
    }

    get containerStyle(){
        return `${this.zoomLevel > 100 ? 'overflow: scroll;' : 'overflow: hidden;'}`;
    }

    get showMinusButton() {
        return this.zoomLevel > 100;
    }

    get isPlusDisabled() {
        return this.zoomLevel >= 200;
    }

    get isMinusDisabled() {
        return this.zoomLevel <= 100;
    }

    zoomIn() {
        if (this.zoomLevel < 200) {
            this.zoomLevel += 20;
        }
    }

    zoomOut() {
        if (this.zoomLevel > 100) {
            this.zoomLevel -= 20;
        }
    }

    fetchFileDetails() {
    FileDetails({ recordId: this.recordId })
    .then(result => {
        console.log('result>>>', result);
        if (result && result.length > 0) {
            const detail = result[0];
            let updatedURL = this.getThumbnailURL(detail.FileType);
            let videoThumbURL = this.recordId;
            console.log('Video ' + videoThumbURL);
            if (detail.MSD_CORE_Video_Resource__c) {
                videoThumbURL = detail.ThumbnailURL__c;
            }
            this.imageUrl =  updatedURL + this.recordId;


            return;
        }
    })
    .catch(error => {
        console.error('Error fetching topic details:', error);
        this.imageUrl = noImage; 
    })
    .finally(() => {
        this.showSpinner = false;
    });
}


    getThumbnailURL(fileType) {
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
                console.log('Updated ThumbURL for pdf:', updatedThumbURL);
                break;
            default:
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=SVGZ');
        }
        console.log('Updated ThumbURL:', updatedThumbURL);
        return updatedThumbURL;
    }
}