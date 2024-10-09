import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

//Apex Class
import getResourceData from '@salesforce/apex/MSD_CORE_HEQ_PreviewController.getResourceData';
import customerProfileName from '@salesforce/label/c.MSD_CORE_HEQ_CustomerProfile';
import saveDownloadHistory from '@salesforce/apex/MSD_CORE_HEQ_DownloadHistory.saveDownloadHistory';
import getResourceDetails from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.getResourceDetails';
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';
import getFileDetails from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.FileDetails';

//Custom Labels
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
import home from '@salesforce/label/c.MSD_CORE_HEQ_Home';
import sitepath from '@salesforce/label/c.MSD_CORE_HEQ_SitePath';

//Static Resource
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';

export default class MSD_CORE_HEQ_ResourceDetail extends NavigationMixin(LightningElement) {
    
    @track profileName;
    @track resourceDetails = {};
    @track fieldNames = [];
    @track displayedFields = [];
    @track zoomLevel = 100;
    @track imageUrl;
    @track showSpinner = false;
    @track iframeurl;
    @track resourceName;
    @track videoResource = false;
    @track cid;
    
    topicId;
    retUrl;
    labels = {
        home
    };

    connectedCallback() {
        this.showSpinner = true;
        const urlParams = new URLSearchParams(window.location.search);
        let topicIdval = urlParams.get('topicId');
        this.topicId = topicIdval.split('-');
        this.retUrl = urlParams.has('ret_URL') ? urlParams.get('ret_URL') : null;
        this.getUserData();
        this.fetchFileDetails();
        this.resourceData();

        const decodedRetUrl = decodeURIComponent(window.location.href);
        this.cid = this.getUrlParamValue(decodedRetUrl, 'cid');
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    // renderedCallback() {
    //     const container = this.template.querySelector('.thumbnail-container');
    //     if (this.zoomLevel > 100) {
    //         container.classList.add('scroll-enabled');
    //     } else {
    //         container.classList.remove('scroll-enabled');
    //     }
    // }

    // get zoomPercentage() {
    //     return this.zoomLevel;
    // }

    // get thumbnailStyle() {
    //     return `transform: scale(${this.zoomLevel / 100});`;
    // }

    // get containerStyle(){
    //     return `${this.zoomLevel > 100 ? 'overflow: scroll;' : 'overflow: hidden;'}`;
    // }

    // get showMinusButton() {
    //     return this.zoomLevel > 100;
    // }

    // get isPlusDisabled() {
    //     return this.zoomLevel >= 200;
    // }

    // get isMinusDisabled() {
    //     return this.zoomLevel <= 100;
    // }

    // zoomIn() {
    //     if (this.zoomLevel < 200) {
    //         this.zoomLevel += 20;
    //     }
    // }

    // zoomOut() {
    //     if (this.zoomLevel > 100) {
    //         this.zoomLevel -= 20;
    //     }
    // }

    getUserData() {
        getUserProfileName()
            .then(profileName => {
                this.profileName = profileName;
                console.log('Profile Name:', this.profileName);
                // this.fetchResourceDetails();
            })
            .catch(error => console.error('Error getting profile name:', error));
    }

    fetchFileDetails() {
        this.showSpinner = true;
        getFileDetails({ recordId: this.topicId[0] })
        .then(result => {
            console.log('result>>>',result);
            if (result && result.length > 0) {
                const detail = result[0];
                let fileTypedata = {
                    fileType: detail["File Type"]
                };
                let updatedURL = this.getThumbnailURL(fileTypedata.fileType);
                let videoThumbURL = this.topicId[0];
                console.log('Video ' + JSON.stringify(detail));
                if(detail.MSD_CORE_Video_Resource__c){
                    videoThumbURL = detail.ThumbnailURL__c;
                }
                this.imageUrl = (this.topicId) ? updatedURL+videoThumbURL : noImage;
                this.displayedFields = detail;
                this.displayedFields = Object.entries(this.displayedFields).map(([key, value]) => {
                    let formattedValue = value;
        
                    if (key.toLowerCase().includes('date')) {
                        formattedValue = this.formatDate(value);
                    } else if (key.toLowerCase().includes('size')) {
                        if(this.videoResource){
                            formattedValue = 'N/A';
                        }else{
                            formattedValue = this.formatFileSize(value);
                        }
                    } else if (key.toLowerCase().includes('file type') && this.videoResource) {
                        formattedValue = 'N/A';
                    } else {
                        formattedValue = this.addSpaceAfterSemicolon(value);
                    }
        
                    return { key, value: formattedValue };
                });
                console.log('this.displayedFields>>'+JSON.stringify(this.displayedFields));
            } 
            this.showSpinner = false;
        })
        .catch(error => {
            this.showSpinner = false;
            console.error('Error fetching topic details:', error);
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
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=SVGZ');
        }

        console.log('Updated ThumbURL:', updatedThumbURL);
        return updatedThumbURL;
    }

    addSpaceAfterSemicolon(value) {
        if (value && typeof value === 'string') {
            return value.replace(/;/g, '; ');
        }
        return value;
    }

    formatDate(value) {
        const date = new Date(value);
        if (!isNaN(date.getTime())) { 
            const month = String(date.getMonth() + 1).padStart(2, '0'); 
            const day = String(date.getDate()).padStart(2, '0');
            const year = date.getFullYear();
            return `${month}/${day}/${year}`;
        }
        return value;
    }

    formatFileSize(value) {
        if (typeof value === 'number') {
            return (value / (1024 * 1024)).toFixed(2) + ' MB'; // Convert bytes to MB
        }
        return value;
    }
    
    redirectToHome() {
        const redirectURL = (this.retUrl != null || this.retUrl != undefined) ? this.retUrl : '/landing-page';
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: redirectURL
            }
        });
    }

    handleBrowseAll() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources?type=Browse%20All'
            }
        });
    }

    handleDownload(){
        if(this.profileName == customerProfileName){
            this.saveDownloadActivity();
        }
        const anchor = document.createElement('a');
        anchor.href = this.iframeurl;
        anchor.download = this.resourceName;
        anchor.target = '_blank';
        document.body.appendChild(anchor);
        anchor.click();
        document.body.removeChild(anchor);
    }

    resourceData() {
        this.showSpinner = true;
        getResourceData({recordId : this.topicId[0]})
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

            this.resourceName = result.contentVersion.Title;
            if (result.contentVersion.FileType == 'PDF') {
                this.iframeurl = sitepath + '/sfc/servlet.shepherd/document/download/'+result.contentVersion.ContentDocumentId+'?operationContext=S1';
            } 
            if (result.contentVersion.MSD_CORE_Video_Resource__c) {
                this.videoResource = true;
                this.iframeurl = result.contentVersion.MSD_CORE_Video_Resource__c;
            }

            this.showSpinner = false;
        })
            .catch ((error) => {
            console.log('error in getResourceData>>>', error);
            this.showSpinner = false;
        })
    }

    saveDownloadActivity() {
        console.log('saveDownloadActivity Called');
        saveDownloadHistory({ resourceId: this.topicId[0], cid: this.cid })
            .then((result) => {
                console.log('saveDownloadHistory ', result);
            })
            .catch((error) => {
                console.log('Error in saveDownloadActivity>>>', error);
            })
    }

    // fetchResourceDetails() {
    //     const metadataType = 'MSD_CORE_Resource_Configs__mdt';
    //     const fieldNames = ['MSD_CORE_Resource_Fields__c', 'MSD_CORE_Profile__c'];

    //     console.log('Fetching resource details with profile name:', this.profileName);

    //     getResourceDetails({ metadataType, recordApiName: this.profileName, fieldNames })
    //         .then(result => {
    //             console.log('Fetched Resource Details:', JSON.stringify(result));
    //             this.resourceDetails = result;
    //             if (result.MSD_CORE_Resource_Fields__c) {
    //                 this.fieldNames = result.MSD_CORE_Resource_Fields__c.split(',');
    //                 this.prepareDisplayedFields();
    //             }
    //         })
    //         .catch(error => {
    //             console.error('Error fetching resource details:', error);
    //         });
    // }
}