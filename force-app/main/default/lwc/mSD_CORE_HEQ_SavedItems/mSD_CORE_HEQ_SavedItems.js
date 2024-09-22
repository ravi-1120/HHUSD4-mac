import bookmarkResource from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.bookmarkResource';
import getUserResources from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.getUserResources';
import unBookmarkResource from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.unBookmarkResource';
import USER_ID from '@salesforce/user/Id';
import NoSaved from '@salesforce/label/c.MSD_CORE_HEQ_No_Saved_Items';
import { LightningElement, track } from 'lwc';

export default class mSD_CORE_HEQ_SavedItems extends LightningElement {

    @track sections = [];
    showSpinner = false;
    topicsError = false;

    label= {
        NoSaved
    }

    connectedCallback() {
        this.showSpinner = true;
        this.loadUserResources();
    }

    loadUserResources() {
        getUserResources({})
            .then(result => {
                console.log('Result:', JSON.stringify(result));
                let section = { title: 'Saved Items', topics: [] };
                section.topics = result.map(item => {
                    return {
                        id: item.Id,
                        title: item.Title,
                        subtitle: item.MSD_CORE_Topic__c,
                        expirationDate: item.MSD_CORE_Expiration_Date__c,
                        isBookmarked: true
                    };
                });
                this.sections = [...this.sections, section];
                this.topicsError = this.sections.some(section => section.topics.length === 0);
                this.showSpinner = false;
                console.log('Sections Saved Items:', JSON.stringify(this.sections));
            })
            .catch(error => {
                console.error(`Error fetching records for ${title}:`, error);
                this.showSpinner = false;
            });
    }

    handleBookmark(event) {
        this.showSpinner = true;
        console.log('event' + JSON.stringify(event.detail));
        let contentVersionId = String(event.detail.id.split("-", 1));
        const userId = USER_ID;
        bookmarkResource({ userId, contentVersionId })
            .then(result => {
                if (result == 'success') {
                    this.sections.forEach(section => {
                        section.topics.forEach(topic => {
                            if (!topic.isBookmarked && topic.id === contentVersionId) {
                                topic.isBookmarked = true;
                            }
                        });
                    });
                }
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error creating a bookmark', error.message);
            });
    }

    handleUnBookmark(event) {
        this.showSpinner = true;
        console.log('UnBookmark' + JSON.stringify(event.detail));
        let contentVersionId = String(event.detail.id.split("-", 1));
        const userId = USER_ID;
        unBookmarkResource({ userId, contentVersionId })
            .then(result => {
                if (result == 'success') {
                    this.sections = this.sections.map(section => ({
                        ...section,
                        topics: section.topics.filter(topic => topic.id !== contentVersionId)
                    }));
                    this.topicsError = this.sections.some(section => section.topics.length === 0);
                }
                console.log('Auth' + JSON.stringify(this.sections));
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error unbookmarking', error.message);
            });
    }
}