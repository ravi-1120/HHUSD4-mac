import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';

import sitepath from '@salesforce/label/c.MSD_CORE_SitePath';
import errormsg from '@salesforce/label/c.MSD_CORE_PreviewError';

import getResourceData from '@salesforce/apex/MSD_CORE_PreviewController.getResourceData';
// import getBusinessRule from '@salesforce/apex/MSD_CORE_PreviewController.getBusinessRule';

export default class HEQ_Preview extends NavigationMixin(LightningElement) {

    @track recordId;
    @track resource;
    @track contentsize;
    @track filetype;
    @track iframeurl;
    // @track isButtonVisible;
    @track showSpinner = false;
    label = {
        errormsg
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
                console.log('result of getResourceData>>',result);
                if (result.MSD_CORE_Video_Resource__c == null) {
                    if (result.FileType == 'PDF') {
                        this.resource = result;
                        this.iframeurl = sitepath + 'MSD_CORE_PreviewResource?recordId='+this.recordId;
                        this.filetype = this.resource.FileType;
                        this.contentsize = (this.resource.ContentSize / (1024 * 1024)).toFixed(2);
                    }
                } else {
                    this.resource = result;
                    this.iframeurl = this.resource.MSD_CORE_Video_Resource__c;
                    this.filetype = 'Video';
                    this.contentsize = (this.resource.ContentSize / (1024 * 1024)).toFixed(2);
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                console.log('error in getResourceData>>>',error);
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

    handleDownload() {
        window.open(sitepath+'/sfc/servlet.shepherd/version/download/'+this.recordId, '_self');
    }
}