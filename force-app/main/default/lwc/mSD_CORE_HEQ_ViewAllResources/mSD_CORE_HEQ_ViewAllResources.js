import { LightningElement, track, wire, api } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import getRecords from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.getRecords';
import getCustomerRecords from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.getCustomerRecords';
import bookmarkResource from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.bookmarkResource';
import fetchResources from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.fetchResources';
import saveResourcesInCollection from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.saveResourcesInCollection';
import fetchResourcesFromSavedSearch from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.fetchResourcesFromSavedSearch';
import getContentRecords from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.getContentRecords';
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';
import unBookmarkResource from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.unBookmarkResource';
import { NavigationMixin } from 'lightning/navigation';
//Custom Labels
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
//Static Resource
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';

export default class MSD_CORE_HEQ_ViewAllResources extends NavigationMixin(LightningElement) {
    @track sections = [];
    @track isSearch = false;
    @track profileName;
    @track selectedCategories = [];
    @track keyword = '';
    @track type = '';
    showSpinner = false;
    @track searchKeyword = '';
    @track categoryList = undefined;

    @track isCollection = false;
    @track selectedDocumentIds = [];
    @track gridItems = [];
    @track soonToExpireItems = [];
    @api sectionsSent = [];


    connectedCallback() {
        this.getUserData();
        this.keyword = this.getUrlParamValue(window.location.href, 'keyword');
        this.type = this.getUrlParamValue(window.location.href, 'type');
        this.categoryList = this.getUrlParamValue(window.location.href, 'category');
        console.log('catList ' + this.categoryList+ this.type);
        // console.log('type in connected callback==>', type);


        if (this.getUrlParamValue(window.location.href, 'action') == 'collection') {
            this.isCollection = true;
            this.collectionId = this.getUrlParamValue(window.location.href, 'cid');
            console.log('collectionId->' + this.collectionId);
        }

        if (this.categoryList) {
            console.log('Vertical Layout ' + this.categoryList + this.type);
            this.loadSearch(null, this.type, null, this.categoryList);
        }

        if (this.keyword && this.type) {
            this.isSearch = true;
            console.log('keyword Search ' + this.keyword);
            this.searchKeyword = 'Search Criteria: ' + this.keyword;
            this.loadSearch(this.keyword, this.type, null, null);
        }

        if (this.type == 'Browse All') {
            console.log('Browse All');
            this.loadSearch(null, this.type, null, null);
        }

        if (((this.type).toLowerCase() == 'new materials'|| (this.type).toLowerCase() == 'expiring soon') && this.categoryList ==undefined) {
            console.log('### 1 '+(this.type).toLowerCase());
            this.loadSearch(null, this.type, null, null);
        }
        if (((this.type).toLowerCase() == 'therapeutic area'|| (this.type).toLowerCase() == 'topics') && this.categoryList ==undefined){
            console.log('### 1 '+(this.type).toLowerCase());
            console.log('Loading Therapeutic Area or Topics' + JSON.stringify(this.categoryList));
            this.loadSearch(null, this.type, null, null);
        }

        if(this.sectionsSent != null) {
            console.log('### this.sectionsSent '+this.sectionsSent);
            this.sections = this.sectionsSent;
        }
        
    }
    
    // async loadContentRecords() {
    //     try {
    //         const data = await getContentRecords();
    //         console.log('Data fetched:', data);
    //         const sortedByModifiedDate = data.sort((a, b) => new Date(b.lastModifiedDate) - new Date(a.lastModifiedDate));
    //         console.log('sortedByModifiedDate ===>' , JSON.stringify(sortedByModifiedDate));

    //         this.gridItems = sortedByModifiedDate.map((item, index) => ({
    //             id: item.id,
    //             heading: item.FileType,
    //             imageUrl: item.imageUrl,
    //             boldText: item.boldText,
    //             normalText: item.normalText,
    //             normalText1: item.fulfillmentMethod,
    //             code: item.resourceCode,
    //             expiryDays: item.expiryDays,
    //             headerClass: `header-color-${index + 1}`,
    //             showMenu: false
    //         }));
    //         console.log('### gridItems '+JSON.stringify(this.gridItems));
    //         console.log('griditems console===>' , JSON.stringify(this.gridItems));

    //         const soonToExpire = data.filter(item => item.expiryDays <= 100).sort((a, b) => a.expiryDays - b.expiryDays);
    //         this.soonToExpireItems = soonToExpire.slice(0, 5).map((item, index) => ({
    //             id: item.id,
    //             heading: item.FileType,
    //             imageUrl: HomepageImage,
    //             boldText: item.boldText,
    //             normalText: item.normalText,
    //             normalText1: item.fulfillmentMethod,
    //             code: item.resourceCode,
    //             expiryDays: item.expiryDays,
    //             headerClass: `header-color-${index + 1}`,
    //             showMenu: false
    //         }));
    //     } catch (error) {
    //         console.error('Error fetching content:', error);
    //     }
    // }

    handleMenuClick(event) {
        const { action, itemId } = event.detail;

        switch (action) {
            case 'print':
                console.log(`Print item ${itemId}`);
                break;
            case 'preview':
                console.log(`Preview item ${itemId}`);
                break;
            case 'download':
                console.log(`Download item ${itemId}`);
                break;
            case 'email':
                console.log(`Email item ${itemId}`);
                break;
            case 'addToCollection':
                console.log(`Add item ${itemId} to collection`);
                break;
        }
        this.handleShowMenu({ detail: { itemId, gridType: event.detail.gridType } });
    }

    handleMenuClick(event) {
        const { action, itemId, category } = event.detail;

        switch (action) {
            case 'print':
                console.log(`Print item ${itemId} from category ${category}`);
                break;
            case 'preview':
                console.log(`Preview item ${itemId} from category ${category}`);
                break;
            case 'download':
                console.log(`Download item ${itemId} from category ${category}`);
                break;
            case 'email':
                console.log(`Email item ${itemId} from category ${category}`);
                break;
            case 'addToCollection':
                console.log(`Add item ${itemId} to collection in category ${category}`);
                break;
        }
        this.handleShowMenu({ detail: { itemId, gridType: event.detail.gridType, category } });
    }

    @track menuOptions = [
        { action: 'print', label: 'Print to customer' },
        { action: 'preview', label: 'Preview' },
        { action: 'download', label: 'Download' },
        { action: 'email', label: 'Email to customer' },
        { action: 'addToCollection', label: 'Add to Collection' }
    ];

    handleShowMenu(event) {
        const { itemId, gridType, category } = event.detail;

        // let itemUpdate = gridType === 'grid1' ? this.gridItems : this.soonToExpireItems;

        // itemUpdate = itemUpdate.map(item => {
        //     if (item.id === itemId) {
        //         return { ...item, showMenu: !item.showMenu };
        //     }
        //     return { ...item, showMenu: false };
        // });

        // if (gridType === 'grid1') {
        //     this.gridItems = itemUpdate;
        // } else {
        //     this.soonToExpireItems = itemUpdate;
        // }


        // let itemUpdate = gridType === 'grid1' ? this.sections[0].topics : this.soonToExpireItems;

        // itemUpdate = itemUpdate.map(item => {
        //     if (item.id === itemId) {
        //         return { ...item, showMenu: !item.showMenu };
        //     }
        //     return { ...item, showMenu: false };
        // });

        // if (gridType === 'grid1') {
        //     this.gridItems = itemUpdate;
        // } else {
        //     this.soonToExpireItems = itemUpdate;
        // }

        this.sections = this.sections.map((section, index) => {
            section.topics = section.topics.map((item, idx) => {
                if (item.id === itemId) {
                    item.showMenu = !item.showMenu;
                }
                return item;
            });    
            return section;
        });
        

        console.log(`Category for item ${itemId}: ${category}`); // Use category as needed
    }

    handleRemovePill(event) {
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
        this.sections = this.sections.map((section, index) => {
            section.topics = section.topics.map((item, idx) => {
                if (item.contentdocumentid === documentId) {
                    item.isSelectedTile = !item.isSelectedTile;
                    item.isSelectedTileColor = !item.isSelectedTile ? 'slds-var-m-top_medium ' : 'slds-var-m-top_medium grey-background'

                    if (item.isSelectedTile && !this.selectedDocumentIds.includes(item.contentdocumentid)) {
                        this.selectedDocumentIds = [...this.selectedDocumentIds, item.contentdocumentid];
                    } else if (!item.isSelectedTile) {
                        this.selectedDocumentIds = this.selectedDocumentIds.filter(id => id !== item.contentdocumentid);
                    }
                }
                return item;
            });    
            return section;
        });
        console.log('this.sections>>>'+JSON.stringify(this.sections));
        console.log('selectedDocumentIds--->' + JSON.stringify(this.selectedDocumentIds));
    }

    handleAdd() {
        console.log('handleAdd');
        saveResourcesInCollection({ collectionId: this.collectionId, documentIds: this.selectedDocumentIds })
            .then(result => {
                this.handleCancel();
            })
            .catch(error => {
                console.log('error->' + JSON.stringify(error));
            });
    }

    handleCancel() {
        console.log('handleCancel');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/resources/collections/view?cid=' + this.collectionId,
            }
        });
    }

    getUserData() {
        console.log('getUserData called in HEQ_ViewAllResources');
        getUserProfileName()
            .then(profileName => {
                this.profileName = profileName;
                // this.loadContentRecords();
                console.log('Profile Name in beginning :', JSON.stringify(this.profileName));
                const category = this.getUrlParamValue(window.location.href, 'category');
                if (category) {
                    this.loadSection(category);
                }
            })
            .catch(error => console.error('Error getting profile name in getUserProfileName section :', error));
    }

    loadSearch(keyword, type, category, catName) {
       console.log('Loading search with keyword:', keyword, ' type:', type, ' category:', category);
        console.log('method called load search');
        fetchResources({ keyword: keyword, type: type, category: category, categoryName: catName }).then(result => {
            console.log('called fetchresources log');
              console.log('Search results fetched:', JSON.stringify(result));
            console.log('Result:', JSON.stringify(result));
            let section;
            if (result.length > 0) {
                if (type == 'Browse All') {
                    section = { title: 'Browse All', topics: [] };
                } else {
                    section = { title: 'Search Results', topics: [] };
                }

                section.topics = result.map(item => {
                    let expiryDays = 0;
                    if (item.MSD_CORE_Expiration_Date__c) {
                        const expirationDate = new Date(item.MSD_CORE_Expiration_Date__c);
                        const currentDate = new Date();
                        const timeDifference = expirationDate - currentDate; // Difference in milliseconds
                        expiryDays = Math.ceil(timeDifference / (1000 * 60 * 60 * 24)); // Convert milliseconds to days
                    }
                    let headerclassval = 2;
                    let filetype;
                    if(item.FileType == 'PDF'){
                        headerclassval = 2;
                        filetype = 'PDF';
                    } 
                    if (item.MSD_CORE_Video_Resource__c) {
                        headerclassval = 5;
                        filetype = 'Video';
                    }
                    let updatedURL = this.getThumbnailURL(item.FileType);
                    let videoThumbURL = item.Id;
                    return {
                        id: item.Id,
                        title: item.Title,
                        subtitle: item.MSD_CORE_Topic__c,
                        imageUrl: (item.Id) ? updatedURL+videoThumbURL : noImage,
                        contentdocumentid: item.ContentDocumentId,
                        isBookmarked: item.isBookmarked == 'true' ? true : false,
                        heading: filetype,
                        boldText: item.Title,
                        normalText: item.Description,
                        normalText1: item.MSD_CORE_Fulfillment_Method__c,
                        code: item.MSD_CORE_Resource_Code__c,
                        expiryDays: expiryDays,
                        headerClass: `header-color-${headerclassval}`,
                        showMenu: false,
                        isSelectedTile: false,
                        isSelectedTileColor: 'slds-var-m-top_medium '
                    };
                });
            } else {
                section = { title: 'Search Results', topics: false };
            }
            // console.log('section>>>>>',JSON.stringify(section));
            // this.sections = section;
            this.sections = [...[], section];
            console.log('Updated sections after search:', JSON.stringify(this.sections));

        }).catch(error => {
            console.log('error->>' + JSON.stringify(error));
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
        if (this.profileName === 'HEQ - Account Exe') {
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
        } else if (this.profileName === 'HEQ Customer') {
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
        // getRecords({
        //     objectName: objectName,
        //     fields: fields,
        //     conditions: conditions,
        //     sortOrder: sortOrder,
        //     limitSize: limitSize
        // })
        //     .then(result => {
        //         console.log('Result:', JSON.stringify(result));
        //         let section = { title: title, topics: [] };
        //         section.topics = result.map(item => {
        //             return {
        //                 id: item.Id,
        //                 title: item.Title,
        //                 subtitle: item.MSD_CORE_Topic__c,
        //                 expirationDate: item.MSD_CORE_Expiration_Date__c,
        //                 isBookmarked: item.isBookmarked == 'true' ? true : false
        //             };
        //         });
        //         this.sections = [...this.sections, section];
        //         console.log('Sections:', JSON.stringify(this.sections));
        //     })
        //     .catch(error => {
        //         console.error(`Error fetching records for ${title}:`, error);
        //     });
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
    handleSavedSearch(data) {

        console.log('handleSavedSearch');
        let data1 = JSON.parse(data);
        var categoryList = this.extractLabels(data1);
        console.log('categoryList->' + categoryList);

        this.searchKeyword = 'Search Criteria: ' + data1.keyword;

        // this.template.querySelector('c-h-e-q_-search-category').loadCheckedCategories(categoryList);
        this.template.querySelector('c-m-s-d_-c-o-r-e_-h-e-q_-search-category').loadCheckedCategories(categoryList);

        fetchResourcesFromSavedSearch({ keyword: data1.keyword, type: data1.type, category: categoryList }).then(result => {
            console.log('Result:', JSON.stringify(result));
            console.log('-->' + result.length);
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
            } else {
                section = { title: 'Search Results', topics: false };
            }
            // console.log('section>>>>>',JSON.stringify(section));
            // this.sections = section;

            this.sections = [...[], section];
            console.log('Sections:', JSON.stringify(this.sections));

            this.dispatchEvent(new CustomEvent('resultsreturned', {
                detail: this.sections
            }));

            console.log('Events sent!');
            return this.sections;

        }).catch(error => {
            console.log('Errorr>>', error);
            console.log('Errorr>>' + error);
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
        this.loadSearch(this.keyword, this.type, categoriesid, null);
    }

    FilterCategories(categories) {
        const result = {};
        categories.forEach(category => {
            if (category.childCategories && category.childCategories.length > 0) {
                result[category.name] = { childCategories: this.FilterCategories(category.childCategories), isChecked: category.isChecked }
            } else {
                // result[category.name] = {};
                result[category.name] = { isChecked: category.isChecked };
            }
        });
        return result;
    }
}