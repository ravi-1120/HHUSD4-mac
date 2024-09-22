import { LightningElement, track, api } from 'lwc';
import tileImage from '@salesforce/resourceUrl/HealthEQ_tile';
import { NavigationMixin } from 'lightning/navigation';

export default class HEQ_GenericTiles extends NavigationMixin(LightningElement) {
    @api id;
    @api title;
    @api subtitle;
    @api contentdocumentid;
    @track isBookmarked;
    @track sectionsDetails;
    @api iscollection;

    // @api
    // get sections() {
    //     return this.sectionsDetails;
    // }
    // set sections(value) {
    //     this.sectionsDetails = value;
    //     console.log('sections ' + JSON.stringify(this.sectionsDetails));
    // }


    handleCheck(event){
        console.log('handleCheck');
        const isSelected = event.target.checked;
        const selectedEvent = new CustomEvent('selectdocument', {
            detail: { id: this.contentdocumentid, isSelected: isSelected }
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

    connectedCallback() {
        console.log('connected callback of tile detail ' + JSON.stringify(this.sections));
    }

    handleKeystroke(event) {
        let bkId = event.target.dataset.aid;
        if (event.key === 'Enter') {
            event.preventDefault();
            const element = this.template.querySelector(`[data-aid="${bkId}"]`);
            if(element){
                element.click();
            }
        }
    }

    handleViewDetails(event) {
        const topicId = event.target.dataset.id;
        const topicTitle = this.title;
        console.log('View details for topic ID: generictiles', topicId);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/detailed?topicId=${encodeURIComponent(topicId)}&title=${encodeURIComponent(topicTitle)}`
            }
        });
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
    
    handlePreview(event) {
        let resourceId = event.target.dataset.id;
        console.log('resourceId>>',resourceId);
        resourceId = resourceId.split('-');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/preview?recordId=${encodeURIComponent(resourceId[0])}`
            }
        });
    }
}