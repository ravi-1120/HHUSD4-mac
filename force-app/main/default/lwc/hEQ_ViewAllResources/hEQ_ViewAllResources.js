import { LightningElement, track, wire ,api} from 'lwc';
import USER_ID from '@salesforce/user/Id';
import getRecords from '@salesforce/apex/HEQ_ContentVersionController.getRecords';
import getCustomerRecords from '@salesforce/apex/HEQ_ContentVersionController.getCustomerRecords';
import bookmarkResource from '@salesforce/apex/HEQ_ContentVersionController.bookmarkResource';
import fetchResources from '@salesforce/apex/HEQ_HeaderController.fetchResources';
import saveResourcesInCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.saveResourcesInCollection';
import fetchResourcesFromSavedSearch from '@salesforce/apex/HEQ_HeaderController.fetchResourcesFromSavedSearch';
import getUserProfileName from '@salesforce/apex/HEQ_HeaderController.getUserProfileName';
import unBookmarkResource from '@salesforce/apex/HEQ_ContentVersionController.unBookmarkResource';
import { NavigationMixin } from 'lightning/navigation';

export default class HEQ_ViewAllResources extends  NavigationMixin(LightningElement) {
    @track sections = [];
    @track isSearch = false;
    @track profileName;
    @track selectedCategories = [];
    @track keyword = '';
    @track type = '';
    showSpinner = false;
    @track searchKeyword = '';

    @track isCollection = false;
    @track selectedDocumentIds = [];

    connectedCallback() {
        this.getUserData();
        this.keyword = this.getUrlParamValue(window.location.href, 'keyword');
        this.type = this.getUrlParamValue(window.location.href, 'type');


        if(this.getUrlParamValue(window.location.href, 'action') == 'collection'){
            this.isCollection = true;
            this.collectionId = this.getUrlParamValue(window.location.href, 'cid');
            console.log('collectionId->'+this.collectionId);
        }

        if(this.keyword && this.type){
            this.isSearch = true;
            this.searchKeyword = 'Search Criteria: '+this.keyword;
            this.loadSearch(this.keyword,this.type,null);
        }
        if(this.type == 'Browse All'){
            this.loadSearch(null,this.type,null);
        }
    }

    handleRemovePill(event){
        console.log('handleRemovePill');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/'
            }
        });
        
    }

    handleDocumentSelection(event) {
        const documentId = event.detail.id;
        const isSelected = event.detail.isSelected;

        var docId = documentId.split('-');

        if (isSelected) {
            this.selectedDocumentIds = [...this.selectedDocumentIds, docId[0]];
        } else {
            this.selectedDocumentIds = this.selectedDocumentIds.filter(id => id !== docId[0]);
        }

        console.log('selectedDocumentIds->'+JSON.stringify(this.selectedDocumentIds));
    }

    handleAdd(){
        console.log('handleAdd');
        saveResourcesInCollection({collectionId: this.collectionId,documentIds: this.selectedDocumentIds})
        .then(result=>{
            this.handleCancel();
        })
        .catch(error=>{
            console.log('error->'+JSON.stringify(error));
        });
    }

    handleCancel(){
        console.log('handleCancel');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections/view?cid='+this.collectionId,
            }
        });
    }

    getUserData() {
        console.log('getUserData called in HEQ_ViewAllResources');
        getUserProfileName()
            .then(profileName => {            
                this.profileName = profileName;
                console.log('Profile Name in beginning :', JSON.stringify(this.profileName));
                const category = this.getUrlParamValue(window.location.href, 'category');
                if (category) {
                    this.loadSection(category);
                }
            })
            .catch(error => console.error('Error getting profile name in getUserProfileName section :', error));
    }

    loadSearch(keyword, type, category) {
        console.log(keyword+'--'+type+'--'+category);
        fetchResources({ keyword: keyword ,type: type, category : category }).then(result => {
            console.log('Result:', JSON.stringify(result));
            console.log('-->'+result.length);
            let section;
            if (result.length > 0) {
                if(type == 'Browse All'){
                    section = { title: 'Browse All', topics: [] };
                }else{
                    section = { title: 'Search Results', topics: [] };
                }
              
                section.topics = result.map(item => {
                    return {
                        id: item.Id,
                        title: item.Title,
                        subtitle: item.MSD_CORE_Topic__c,
                        contentdocumentid: item.ContentDocumentId,
                        isBookmarked: item.isBookmarked == 'true' ? true : false
                    };
                });
            }else{
                section = { title: 'Search Results', topics: false};
            }
            // console.log('section>>>>>',JSON.stringify(section));
            // this.sections = section;

            this.sections = [...[], section];
            console.log('Sections:', JSON.stringify(this.sections));
        }).catch(error => {
            console.log('error->>' + JSON.stringify(error));
        });
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }
    
    // loadSection(sectionTitle) {
    //     getCustomerRecords({ 
    //         userId: USER_ID,
    //         fields: 'Id, Title, MSD_CORE_Topic__c, MSD_CORE_Expiration_Date__c', 
    //         conditions: '', 
    //         sortOrder: 'LastModifiedDate DESC', 
    //         limitSize: null 
    //     })
    //     .then(result => {
    //         let section = { title: sectionTitle, topics: [] };
    //         section.topics = result.map(item => {
    //             return {
    //                 id: item.Id,
    //                 title: item.Title,
    //                 subtitle: item.MSD_CORE_Topic__c
    //             };
    //         });
    //         this.sections = [...this.sections, section];
    //         console.log('Sections:', JSON.stringify(this.sections));
    //     })
    //     .catch(error => {
    //         console.error(`Error fetching records for ${sectionTitle}:`, error);
    //     });
    // }

    loadSection(sectionTitle) {
        console.log('Profile Name for HEQ_ViewAllResources in loadSection:', JSON.stringify(this.profileName));
        if(this.profileName === 'HEQ - Account Exe'){
            console.log('HEQ- Account Exe Profile getRecords called');
            const objectName = 'ContentVersion';
            const fields = 'Id, Title, MSD_CORE_Topic__c';
            const conditions = '';
            const sortOrder = 'LastModifiedDate DESC';
            const limitSize = null;

            if (sectionTitle === 'Expiring Soon') {
                this.loadAEDynamicSection('Expiring Soon', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', 'MSD_CORE_Expiration_Date__c != NULL', 'MSD_CORE_Expiration_Date__c ASC', null);
            } else {
                this.loadAEDynamicSection(sectionTitle, objectName, fields, conditions, sortOrder, limitSize);
            }
            // getRecords({ objectName, fields, conditions, sortOrder, limitSize })
            // .then(result => {
            //     console.log('Result:', JSON.stringify(result));
            //     let section = { title: sectionTitle, topics: [] };
            //     section.topics = result.map(item => {
            //         return {
            //             id: item.Id,
            //             title: item.Title,
            //             subtitle: item.MSD_CORE_Topic__c
            //         };
            //     });
            //     this.sections = [...this.sections, section];
            //     console.log('Sections:', JSON.stringify(this.sections));
            // })
            // .catch(error => {
            //     console.error(`Error fetching records for ${sectionTitle}:`, error);
            // });
        } else if (this.profileName === 'HEQ Customer'){
            console.log('HEQ Customer Profile getCustomerRecords called');
        let fields = 'Id, Title, MSD_CORE_Topic__c';
        let conditions = '';
        let sortOrder = 'LastModifiedDate DESC';
        let limitSize = null;

        if (sectionTitle === 'Expiring Soon') {
            fields += ', MSD_CORE_Expiration_Date__c';
            conditions = 'MSD_CORE_Expiration_Date__c != NULL';
            sortOrder = 'MSD_CORE_Expiration_Date__c ASC';
            limitSize = null;
        }

        this.loadDynamicSection(sectionTitle, USER_ID, fields, conditions, sortOrder, limitSize);
    }
}
    loadAEDynamicSection(title, objectName, fields, conditions, sortOrder, limitSize) {
        console.log('loadAEDynamicSection getRecords are called');
        getRecords({ 
            objectName: objectName,
            fields: fields,
            conditions: conditions,
            sortOrder: sortOrder,
            limitSize: limitSize
        })
        .then(result => {
            console.log('Result:', JSON.stringify(result));
            let section = { title: title, topics: [] };
            section.topics = result.map(item => {
                return {
                    id: item.Id,
                    title: item.Title,
                    subtitle: item.MSD_CORE_Topic__c,
                    expirationDate: item.MSD_CORE_Expiration_Date__c ,
                    isBookmarked: item.isBookmarked == 'true' ? true : false
                };
            });
            this.sections = [...this.sections, section];
            console.log('Sections:', JSON.stringify(this.sections));
        })
        .catch(error => {
            console.error(`Error fetching records for ${title}:`, error);
        });
    }


    loadDynamicSection(title, userId, fields, conditions, sortOrder, limitSize) {
        getCustomerRecords({
            userId: userId,
            fields: fields,
            conditions: conditions,
            sortOrder: sortOrder,
            limitSize: limitSize
        })
        .then(result => {
            console.log('Result:', JSON.stringify(result));
            let section = { title: title, topics: [] };
            section.topics = result.map(item => {
                return {
                    id: item.Id,
                    title: item.Title,
                    subtitle: item.MSD_CORE_Topic__c,
                    expirationDate: item.MSD_CORE_Expiration_Date__c,
                    isBookmarked: item.isBookmarked == 'true' ? true : false
                };
            });
            this.sections = [...this.sections, section];
            console.log('Sections:', JSON.stringify(this.sections));
        })
        .catch(error => {
            console.error(`Error fetching records for ${title}:`, error);
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
    handleSelectedCategories(event) {
        const selectedCategories = event.detail;
        console.log('Received selectedCategories from HEQ_SearchCategory component:', JSON.stringify(selectedCategories));
        const Filters = this.FilterCategories(selectedCategories);
        const SelectedFilters = {
            keyword: this.keyword,
            Filters: Filters,
            type: this.type
        };       
        console.log('Filtered Categories:', JSON.stringify(SelectedFilters, null, 2));
        this.selectedCategories = SelectedFilters;
        this.dispatchEvent(new CustomEvent('selectedfilters', {
            detail: SelectedFilters,
            bubbles: true,
            composed: true
        }));
    }

    @api
    handleSavedSearch(data){

        console.log('handleSavedSearch');
        let data1 = JSON.parse(data);
        var categoryList = this.extractLabels(data1);
        console.log('categoryList->'+categoryList);

        this.searchKeyword = 'Search Criteria: '+data1.keyword;

        this.template.querySelector('c-h-e-q_-search-category').loadCheckedCategories(categoryList);

        fetchResourcesFromSavedSearch({ keyword: data1.keyword ,type: data1.type, category : categoryList }).then(result => {
            console.log('Result:', JSON.stringify(result));
            console.log('-->'+result.length);
            let section;
            if (result.length > 0) {
              section = { title: 'Search Results', topics: [] };
                section.topics = result.map(item => {
                    return {
                        id: item.Id,
                        title: item.Title,
                        subtitle: item.MSD_CORE_Topic__c,
                        isBookmarked: item.isBookmarked == 'true' ? true : false
                    };
                });
            }else{
                section = { title: 'Search Results', topics: false};
            }
            // console.log('section>>>>>',JSON.stringify(section));
            // this.sections = section;

            this.sections = [...[], section];
            console.log('Sections:', JSON.stringify(this.sections));
        }).catch(error => {
            console.log('Errorr>>',error);
            console.log('Errorr>>'+error);
            console.log('error->>' + JSON.stringify(error));
        });

    }

    extractLabels(data) {
        let labels = [];
    
        function traverse(obj, parentLabel) {
            for (let key in obj) {
                if (typeof obj[key] === 'object') {
                    traverse(obj[key], key);
                } else if (key === 'isChecked' && obj[key] === true) {
                    labels.push(parentLabel);
                }
            }
        }
    
        traverse(data.Filters, null);
        return labels;
    }

    // Created By Ravi
    handlecategoriesid(event) {
        const categoriesid = event.detail;
        console.log('>>categoriesid>>>', JSON.stringify(categoriesid));
        this.loadSearch(this.keyword,this.type,categoriesid);
    }
    
    FilterCategories(categories) {
        const result = {};
        categories.forEach(category => {
            if (category.childCategories && category.childCategories.length > 0) {
                result[category.name] = {childCategories: this.FilterCategories(category.childCategories), isChecked: category.isChecked}
            } else {
                // result[category.name] = {};
                result[category.name] = {isChecked: category.isChecked};
            }
        });
        return result;
    }
}