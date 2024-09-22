import { LightningElement, api, wire, track } from 'lwc';
import getResourceDetails from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.getResourceDetails';
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';
import FileDetails from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.FileDetails';
//Custom Labels
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
//Static Resource
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';

export default class MSD_CORE_HEQ_ResourceDetail extends LightningElement {
    @track profileName;
    @track resourceDetails = {};
    @track fieldNames = [];
    @track displayedFields = [];
    topicId;
    @track zoomLevel = 100;
    @track imageUrl;
    showSpinner = false;

    connectedCallback() {
        this.showSpinner = true;
        const urlParams = new URLSearchParams(window.location.search);
        let topicIdval = urlParams.get('topicId');
        this.topicId = topicIdval.split('-');
        this.getUserData();
        this.fetchFileDetails();
    }

    renderedCallback() {
        const container = this.template.querySelector('.thumbnail-container');
        if (this.zoomLevel > 100) {
            container.classList.add('scroll-enabled');
        } else {
            container.classList.remove('scroll-enabled');
        }
    }

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
        FileDetails({ recordId: this.topicId[0] })
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
                        formattedValue = this.formatFileSize(value);
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