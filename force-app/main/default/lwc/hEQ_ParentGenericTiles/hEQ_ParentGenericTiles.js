import { LightningElement, track } from 'lwc';
import getRecords from '@salesforce/apex/HEQ_ContentVersionController.getRecords';
import getCustomerRecords from '@salesforce/apex/HEQ_ContentVersionController.getCustomerRecords';
import bookmarkResource from '@salesforce/apex/HEQ_ContentVersionController.bookmarkResource';
import unBookmarkResource from '@salesforce/apex/HEQ_ContentVersionController.unBookmarkResource';
import USER_ID from '@salesforce/user/Id';
import getUserPreferences from '@salesforce/apex/HEQ_Addmore.getUserPreferences';
import getUserProfileName from '@salesforce/apex/HEQ_HeaderController.getUserProfileName';
import { NavigationMixin } from 'lightning/navigation';

export default class HEQ_ParentGenericTiles extends NavigationMixin(LightningElement) {
    @track sections = [];
    @track profileName;
    @track savedCategories = [];
    showSpinner = false;

    connectedCallback() {
        this.getUserData();
    }
    getUserData() {
        getUserProfileName()
            .then(profileName => {
                this.profileName = profileName;
                this.fetchUserPreferences();
            })
            .catch(error => console.error('Error getting profile name:', error));

    }

    fetchUserPreferences() {
        console.log('User ID in fetchUserPreferences for HEQ_ParentGenericTiles:', USER_ID);
        const userId = this.getUrlParamValue(window.location.href, 'Id');
        getUserPreferences({ userId: userId })
            .then(result => {
                if (result) {
                    this.savedCategories = result.split(',');
                    console.log('Saved categories for HEQ_ParentGenericTiles:', JSON.stringify(this.savedCategories));
                    if (this.savedCategories.length > 0) {
                        console.log('Saved categories found and called loadSections');
                        this.loadSections(this.savedCategories);
                        console.log('Categories loading in HEQ_ParentGenericTiles:', JSON.stringify(this.savedCategories));
                    } else {
                        console.log('No saved categories found');
                        this.loadSectionsBasedOnProfile();
                    }
                } else {
                    this.loadSectionsBasedOnProfile();
                }
            })
            .catch(error => {
                console.error('Error fetching user preferences for HEQ_ParentGenericTiles:', error);
                this.loadSectionsBasedOnProfile();
            });
    }
    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }

    loadSectionsBasedOnProfile() {
        console.log('Profile name for Tiles Customer:', this.profileName);
        if (!this.savedCategories.length) {
            if (this.profileName === 'HEQ - Account Exe') {
                this.AESections();
            } else if (this.profileName === 'HEQ Customer') {
                console.log('HEQ Customer profile');
                this.CustomerSections();
            }
        }
    }
    AESections() {
        this.loadSection('Health Equity', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
        this.loadSection('Expiring Soon', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', 'MSD_CORE_Expiration_Date__c != NULL', 'MSD_CORE_Expiration_Date__c ASC', 5);
        this.loadSection('Therapeutic Area', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
        this.loadSection('Topics', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
    }

    loadSection(sectionTitle, objectName, fields, conditions, sortOrder, limitSize) {
        getRecords({ objectName, fields, conditions, sortOrder, limitSize })
            .then(result => {
                let section = { title: sectionTitle, topics: [] };
                section.topics = result.map(item => {
                    return {
                        id: item.Id,
                        title: item.Title,
                        subtitle: item.MSD_CORE_Topic__c,
                        isBookmarked: item.isBookmarked == 'true' ? true : false
                    };
                });
                this.sections = [...this.sections, section];
                console.log('Sections in loadSection that are loading:', JSON.stringify(this.sections));
            })
            .catch(error => {
                console.error(`Error fetching records for ${sectionTitle}:`, error);
            });
    }


    CustomerSections() {
        const userId = USER_ID;
        console.log('User ID in CustomerSections:', userId);
        this.loadDynamicSection('Collections', userId, 'Id, Title, MSD_CORE_Topic__c, CreatedDate', '', 'CreatedDate DESC', 5);
        this.loadDynamicSection('Expiring Soon', userId, 'Id, Title, MSD_CORE_Topic__c, MSD_CORE_Expiration_Date__c', 'MSD_CORE_Expiration_Date__c != NULL', 'MSD_CORE_Expiration_Date__c ASC', 5);
        this.loadDynamicSection('Therapeutic Area', userId, 'Id, Title, MSD_CORE_Topic__c, LastModifiedDate', '', 'LastModifiedDate DESC', 5);
        this.loadDynamicSection('Topics', userId, 'Id, Title, MSD_CORE_Topic__c, LastModifiedDate', '', 'LastModifiedDate DESC', 5);
    }

    loadDynamicSection(sectionTitle, userId, fields, conditions, sortOrder, limitSize) {
        getCustomerRecords({ userId, fields, conditions, sortOrder, limitSize })
            .then(result => {
                let section = { title: sectionTitle, topics: [] };
                section.topics = result.map(item => {
                    return {
                        id: item.Id,
                        title: item.Title,
                        subtitle: item.MSD_CORE_Topic__c,
                        isBookmarked: item.isBookmarked == 'true' ? true : false
                    };
                });
                this.sections = [...this.sections, section];
                console.log('Sections:', JSON.stringify(this.sections));
            })
            .catch(error => {
                console.error(`Error fetching records for ${sectionTitle}:`, error);
            });
    }

    SelectedCategories(event) {
        const selectedCategories = event.detail.categories;
        console.log('Selected categories received in parent component:', JSON.stringify(selectedCategories));
        this.sections = [];
        this.loadSections(selectedCategories);
    }
    loadSections(categories) {
        console.log('Categories in loadSections are called');
        if (this.profileName === 'HEQ - Account Exe') {
        categories.forEach(category => this.loadAECategory(category));
        } else if (this.profileName === 'HEQ Customer') {
            categories.forEach(category => this.loadCategory(category));
        }
    }

    loadCategory(category) {
        console.log('Category in loadCategory:', category);
        const userId = USER_ID;
        switch (category) {
            case 'Collections':
                this.loadDynamicSection('Collections', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'CreatedDate DESC', 5);
                break;
            case 'Expiring soon':
                this.loadDynamicSection('Expiring Soon', userId, 'Id, Title, MSD_CORE_Topic__c', 'MSD_CORE_Expiration_Date__c != NULL', 'MSD_CORE_Expiration_Date__c ASC', 5);
                break;
            case 'Therapeutic Area':
                this.loadDynamicSection('Therapeutic Area', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
                break;
            case 'Topic':
                this.loadDynamicSection('Topics', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
                break;
            case 'Health Equity':
                this.loadDynamicSection('Health Equity', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
                break;
            case 'New':
                this.loadDynamicSection('New - (05)', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
                break;
            case 'D&I Artbanks':
                this.loadDynamicSection('D&I Artbanks', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
                break;
            default:
                console.warn(`Unknown category: ${category}`);
                break;
        }
    }

    loadAECategory(category) {
        console.log('Category in loadAECategory:', category);
        switch(category) {
            case 'Collections':
                this.loadSection('Collections', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'CreatedDate DESC', 5);
                break;
            case 'Expiring soon':
                this.loadSection('Expiring Soon', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', 'MSD_CORE_Expiration_Date__c != NULL', 'MSD_CORE_Expiration_Date__c ASC', 5);
                break;
            case 'Therapeutic Area':
                this.loadSection('Therapeutic Area', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
                break;
            case 'Topic':
                this.loadSection('Topics', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
                break;
            case 'Health Equity':
                this.loadSection('Health Equity', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
                break;
            case 'New':
                this.loadSection('New - (05)', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
                break; 
            case 'D&I Artbanks':
                this.loadSection('D&I Artbanks', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
                break;
            default:
                console.warn(`Unknown category: ${category}`);
                break;
        }
}

    ViewDetails(event) {
        const topicId = event.target.dataset.id;
        console.log('View details for topic ID:', topicId);
    }

    handleViewAll(event) {
        const sectionTitle = event.target.dataset.title;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources?category=${encodeURIComponent(sectionTitle)}`
            }
        });
    }

    MoreOptions() {
        console.log('More Options link clicked');
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
                    this.sections.forEach(section => {
                        section.topics.forEach(topic => {
                            if (topic.isBookmarked && topic.id === contentVersionId) {
                                topic.isBookmarked = false;
                            }
                        });
                    });
                }
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                console.error('Error unbookmarking', error.message);
            });
    }

}