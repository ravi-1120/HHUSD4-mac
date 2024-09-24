import { LightningElement, track, api } from 'lwc';

// Apex Method
import fetchResources from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.fetchResources';

//Custom Labels
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';

export default class MSD_CORE_HEQ_ResourcePopup extends LightningElement {

    @track showSpinner = false;
    @track showResourcePopup = true;
    @track allRecords;
    @track lengthofResourcesSelected;
    @track allRecords = [];
    @track menuOptions = [];
    @track selectedDocumentIds = [];

    hideSaveSearch = true

    @api type = "Browse All";
    @api submitButton;


    connectedCallback() {
        this.showSpinner = true;
        if (this.type == 'Browse All') {
            this.loadSearch(null, this.type, null, null);
        }
    }

    closeModal() {
        // this.showResourcePopup = !this.showResourcePopup;
        const closemodelpopup = new CustomEvent('closemodelpopup', {
            detail: true
        });
        this.dispatchEvent(closemodelpopup);
    }

    loadSearch(keyword, type, category, catName) {
        this.showSpinner = true;

        fetchResources({ keyword: keyword, type: type, category: category, categoryName: catName }).then(result => {
            console.log('Result of fetchResources::>>', result);
            this.showSpinner = false;
            this.manageLoadData(result, keyword, type, category, catName);
        }).catch(error => {
            console.log('loadSearch error->>' + error.message);
            this.showSpinner = false;
        });
    }

    manageLoadData(result, keyword, type, category, catName) {
        try{
            let section = { title: 'Browse All', topics: [] };
            if (result.length > 0) {
                section.topics = result.map(item => {
                    let headerclassval = 2;
                    let filetype;
                    if (item.FileType == 'PDF') {
                        headerclassval = 2;
                        filetype = 'Static';
                    }
                    if (item.MSD_CORE_Video_Resource__c) {
                        headerclassval = 5;
                        filetype = 'Video';
                    }
                    let updatedURL = this.getThumbnailURL(item.FileType);
                    let videoThumbURL = item.Id;

                    let descriptionVal = item.MSD_CORE_Therapeutic_Area__c ? item.MSD_CORE_Therapeutic_Area__c.replace(/;/g, ', ') : item.MSD_CORE_Therapeutic_Area__c;
                    let topicVal = item.MSD_CORE_Topic__c ? item.MSD_CORE_Topic__c.replace(/;/g, ', ') : item.MSD_CORE_Topic__c;

                    let expirationDate;
                    if (item.MSD_CORE_Expiration_Date__c) {
                        expirationDate = new Intl.DateTimeFormat('en-US', {
                            year: 'numeric',
                            month: '2-digit',
                            day: '2-digit'
                        }).format(new Date(item.MSD_CORE_Expiration_Date__c));
                    }

                    return {
                        id: item.Id,
                        title: item.Title,
                        subtitle: item.MSD_CORE_Topic__c,
                        imageUrl: (item.Id) ? updatedURL + videoThumbURL : noImage,
                        contentdocumentid: item.ContentDocumentId,
                        isBookmarked: item.isBookmarked == 'true' ? true : false,
                        heading: filetype,
                        boldText: item.Title,
                        normalText: descriptionVal,
                        normalText1: topicVal,
                        code: item.MSD_CORE_Resource_Code__c,
                        expiryDays: expirationDate,
                        showSelector: true,
                        isSelectedTile: false,
                        headerClass: `header-color-${headerclassval}`,
                        headerClasslist: `header-color-list-${headerclassval}`,
                        showMenu: false,
                        showCheckbox: true,
                        isNewItem: item.MSD_CORE_IsNewItem__c == 'true' ? true : false
                    };

                });
                this.allRecords = section.topics;
                this.sections = [{ title: 'Browse All', topics: this.allRecords }];
            } else {
                section = { title: 'Search Results', topics: false };
                this.allRecords = section.topics;
            }
        }catch(e){
            console.error('Error in Merging ', e);
        }
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
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=THUMB720BY480');
        }
        return updatedThumbURL;
    }

    handleDocumentSelection(event) {
        const documentId = event.detail.id;
        this.sections = this.sections.map((section, index) => {
            section.topics = section.topics.map((item, idx) => {
                if (item.contentdocumentid === documentId) {
                    item.isSelectedTile = !item.isSelectedTile;
                    item.isSelectedList = !item.isSelectedList;
                    if ((item.isSelectedTile || item.isSelectedList) && !this.selectedDocumentIds.includes(item.contentdocumentid)) {
                        this.selectedDocumentIds = [...this.selectedDocumentIds, item.contentdocumentid];
                    } else if (!item.isSelectedTile || !item.isSelectedList) {
                        this.selectedDocumentIds = this.selectedDocumentIds.filter(id => id !== item.contentdocumentid);
                    }
                }
                return item;
            });
            return section;
        });
        this.lengthofResourcesSelected = (this.selectedDocumentIds && this.selectedDocumentIds.length > 0) ? this.selectedDocumentIds.length : 0;
    }

    handleExpandCollapsSidebar(){
        const filterSection = this.template.querySelector('.filter-screen');
        filterSection.classList.toggle('filter-hide');
    }

    handleSelectedCategories(event){
        console.log('handleSelectedCategories ', event.detail);
    }

    handleCheckboxChange(event){
        console.log('handleCheckboxChange', event.detail);
    }

    handleSelectedFilters(event){
        console.log('handleSelectedFilters', event.detail);
    }
    
    handleCategoriesUpdate(event){
        console.log('handleCategoriesUpdate', event.detail);
    }
       
    handlecategoriesid(event){
        console.log('handlecategoriesid', event.detail);
        this.loadSearch(null, this.type, event.detail, null);
    }

    handleShareClick(){
        const selectedEvent = new CustomEvent('selectedresources', {
            detail: { resources: this.selectedDocumentIds}
        });
        this.dispatchEvent(selectedEvent);
    }
    
}