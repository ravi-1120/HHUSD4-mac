import { LightningElement, track } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';

//Apex Class
import getDownloadHistory from '@salesforce/apex/MSD_CORE_HEQ_DownloadHistory.getDownloadHistory';
import saveDownloadHistory from '@salesforce/apex/MSD_CORE_HEQ_DownloadHistory.saveDownloadHistory';
import customerProfileName from '@salesforce/label/c.MSD_CORE_HEQ_CustomerProfile';
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';

//Custom Labels
import recordsperpage from '@salesforce/label/c.MSD_CORE_HEQ_AllResourceRecordPerPage';
import recordperpageoption from '@salesforce/label/c.MSD_CORE_HEQ_AllResourcerecordsPerPageOptions';
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';
import sitepath from '@salesforce/label/c.MSD_CORE_HEQ_SitePath_For_Download';

export default class MSD_CORE_HEQ_DownloadHistory extends NavigationMixin(LightningElement) {

    @track displayedData = undefined;
    @track showPopup = false;
    @track showSpinner = false;
    @track sortDirection = "asc";
    @track showPagination1 = true;
    @track profileName;
    
    // Pagination
    @track isPagination = false;
    @track totalRecords = 0;
    @track totalPages = 1;
    @track currentPage = 1;
    @track recordsPerPage = recordsperpage;
    @track recordsPerPageOptions = [];
    @track allRecords = [];

    connectedCallback() {
        this.getDownloadHistory();
        this.getUserData();
        this.recordsPerPageOptions = recordperpageoption.split(',').map(option => parseInt(option.trim()));
    }

    getDownloadHistory() {
        this.showSpinner = true;
        console.log('getDownloadHistory Called');
        getDownloadHistory({ userId: USER_ID })
            .then((result) => {
                if (result) {
                    this.allRecords = result;
                    let updatedURL = this.getThumbnailURL('THUMB');
                    this.allRecords = result.map(item => ({
                        ...item,
                        ThumbnailUrl: item.resourceId ? `${updatedURL}${item.resourceId}` : noImage,
                        DownloadURL: sitepath + '/sfc/servlet.shepherd/document/download/' + item.documentId + '?operationContext=S1',
                    })).sort((a, b) => new Date(b.downloadedDate) - new Date(a.downloadedDate));
                    console.log('this.allRecords------>' + JSON.stringify(this.allRecords));
                    this.totalRecords = this.allRecords.length;
                    console.log('this.totalRecords----->' + JSON.stringify(this.totalRecords));
                    if (this.totalRecords > 0) {
                        this.isPagination = true;
                    }
                    this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
                    this.updatePagination();
                }
                console.log('Download History:', result);
                this.showSpinner = false;
            })
            .catch((error) => {
                console.error('Error in getDownloadHistory:', error);
            });

    }

    getUserData() {
        getUserProfileName()
            .then(profileName => {
                this.profileName = profileName;
                console.log('Profile Name:', this.profileName);
            })
            .catch(error => console.error('Error getting profile name:', error));
    }

    renderedCallback(){
        this.displayedData = this.displayedData?.length ? this.displayedData : undefined;
    }

    saveDownloadActivity(id, cid) {
        console.log('saveDownloadActivity Called');
        saveDownloadHistory({ resourceId: id, cid: cid })
            .then((result) => {
                console.log('saveDownloadHistory ', result);
                this.getDownloadHistory();
            })
            .catch((error) => {
                console.log('Error in saveDownloadActivity>>>', error);
            })
    }

    resetVariableValue() {
        this.totalRecords = 0;
        this.totalPages = 1;
        this.currentPage = 1;
    }

    // Pagination
    updatePagination() {
        const startIndex = (this.currentPage - 1) * parseInt(this.recordsPerPage);
        const endIndex = startIndex + parseInt(this.recordsPerPage);
        this.paginatedTopics = this.allRecords.slice(startIndex, endIndex);
        this.displayedData = (this.paginatedTopics.length > 0) ? this.paginatedTopics : this.displayedData;
        // Sync 2 Pagination Components
        let pagination = this.template.querySelectorAll('c-m-s-d_-c-o-r-e_-h-e-q_-pagination');
        for (let index = 0; index < pagination.length; index++) {
            pagination[index].updatecurrentpage(this.currentPage, this.totalRecords, this.totalPages);
        }
    }

    handlePageOptionChange(event) {
        this.currentPage = 1;
        this.recordsPerPage = event.detail.recordsPerPage;
        this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
        this.updatePagination();
    }

    handlePageChange(event) {
        this.currentPage = event.detail.currentPage;
        this.recordsPerPage = event.detail.recordsPerPage;
        this.totalPages = Math.ceil(this.allRecords.length / parseInt(this.recordsPerPage));
        this.updatePagination();
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

    handleDownload(event){
        this.showSpinner = true;
        event.preventDefault();
        let { link, title, check, cid, resid } = event.currentTarget.dataset;
        console.log('downloadHistory >>' , check);
        if(check === "false"){
            if(this.profileName == customerProfileName){
                this.saveDownloadActivity(resid, cid);
            }
            const anchor = document.createElement('a');
            anchor.href = link;
            anchor.target = '_self';
            anchor.download = title;
            document.body.appendChild(anchor);
            anchor.click();
            document.body.removeChild(anchor);
        }else{
            this.showPopup = true;
        }
        this.showSpinner = false;
    }

    get shareSortIcon() {
        return this.sortDirection === 'dsc' ? 'utility:arrowdown' : 'utility:arrowup';
    }

    sortRecords(order) {
        this.displayedData.sort((a, b) => {
            const dateA = new Date(a.downloadedDate);
            const dateB = new Date(b.downloadedDate);

            if (order === 'asc') {
                return dateB - dateA;
            } else if (order === 'dsc') {
                return dateA - dateB;
            } else {
                return 0;
            }
        });
    }

    handleSort(){
        this.sortDirection = (this.sortDirection == 'asc') ? 'dsc' : 'asc';
        this.sortRecords(this.sortDirection);
    }

    redirectToHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/landing-page'
            }
        });
    }

    handleCloseConfirmModel(){
        this.showPopup = false;
    }
}