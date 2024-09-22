import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';

//Apex Classes
import getUserPreferences from '@salesforce/apex/MSD_CORE_HEQ_Addmore.getUserPreferences';
import bookmarkResource from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.bookmarkResource';
import getCustomerRecords from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.getCustomerRecords';
import getRecords from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.getRecords';
import unBookmarkResource from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.unBookmarkResource';
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';
import getContentRecords from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.getContentRecords';
import getPicklist from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.getPicklist';
import FileDetails from '@salesforce/apex/MSD_CORE_HEQ_ResourceController.FileDetails';
import getCustomerCollectionList from '@salesforce/apex/MSD_CORE_HEQ_CollectionController.getCustomerCollections';

//Custom Labels
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
import ExpiringSoon from '@salesforce/label/c.MSD_CORE_HEQ_Expiring_Soon';
import New from '@salesforce/label/c.MSD_CORE_HEQ_New';
import ViewAll from '@salesforce/label/c.MSD_CORE_HEQ_View_All';
import sitepath from '@salesforce/label/c.MSD_CORE_HEQ_SitePath_For_Download';
import customerProfileName from '@salesforce/label/c.MSD_CORE_HEQ_CustomerProfile';

//Static Resource
import noImage from '@salesforce/resourceUrl/MSD_CORE_HEQ_No_Image';
import HomepageImage from '@salesforce/resourceUrl/MSD_CORE_Homepage_Image';


export default class mSD_CORE_HEQ_ParentGenericTiles extends NavigationMixin(LightningElement) {

    @track sections = [];
    @track savedCategories = [];
    @track gridItems = [];
    @track soonToExpireItems = [];
    @track therapeuticAreaOptions = [];
    @track topicOptions = [];
    @track showMenu = false;
    @track profileName;
    @track imageUrl;
    @track recordId;
    @track collectionItems;

    @track menuOptions = [
        { action: 'download', label: 'Download', downloadActive: true },
        { action: 'preview', label: 'Preview & Details', downloadActive: false, isModelBox: false },
        { action: 'email', label: 'Email to customer', downloadActive: false, isModelBox: false },
        { action: 'addToCollection', label: 'Add to collection', downloadActive: false, isModelBox: true },
        { action: 'print', label: 'Print to customer', downloadActive: false, isModelBox: false }
    ];

    @track collectionOptions = [
        { action: 'Open', label: 'Open', downloadActive: false },
    ];

    currentItemId;
    showSpinner = false;
    label = {
        New,
        ExpiringSoon,
        ViewAll
    };

    // @track gridItems = [
    //     { id: '1', heading: 'Customizable', imageUrl: HomepageImage, boldText: 'What are Cancer Biometers Lorem Ipsum contra et tua', normalText: 'Text Line 1 Lorem ipsum contra et tu ', normalText1:'Text Line 2 Lorem ipsum tu a contra', code:'US-NON-1234', expiryDays: 100,
    //         headerClass: 'header-color-1'
    //      },
    //     { id: '2', heading: 'Customizable', imageUrl: HomepageImage, boldText: 'What are Cancer Biometers Lorem Ipsum contra et tua', normalText: 'Text Line 1 Lorem ipsum contra et tu ', normalText1:'Text Line 2 Lorem ipsum tu a contra', code:'US-NON-1234', expiryDays: 100,headerClass: 'header-color-2' },
    //     { id: '3', heading: 'Static', imageUrl: HomepageImage, boldText: 'What are Cancer Biometers Lorem Ipsum contra et tua', normalText: 'Text Line 1 Lorem ipsum contra et tu ', normalText1:'Text Line 2 Lorem ipsum tu a contra', code:'US-NON-1234', expiryDays: 100,headerClass: 'header-color-3' },
    //     { id: '4', heading: 'Static', imageUrl: HomepageImage, boldText: 'What are Cancer Biometers Lorem Ipsum contra et tua', normalText: 'Text Line 1 Lorem ipsum contra et tu ', normalText1:'Text Line 2 Lorem ipsum tu a contra', code:'US-NON-1234', expiryDays: 100,headerClass: 'header-color-4' },
    //     { id: '5', heading: 'Vedio', imageUrl: HomepageImage, boldText: 'What are Cancer Biometers Lorem Ipsum contra et tua', normalText: 'Text Line 1 Lorem ipsum contra et tu ', normalText1:'Text Line 2 Lorem ipsum tu a contra', code:'US-NON-1234', expiryDays: 100,headerClass: 'header-color-5' },
    // ];

    connectedCallback() {
        this.getUserData();
        this.fetchFileDetails();
        this.configurePicklist();
    }

    getUserData() {
        getUserProfileName()
            .then(profileName => {
                this.profileName = profileName;
                if(this.profileName == customerProfileName){
                    this.loadCollectionData();
                }
                this.fetchUserPreferences();
                this.loadContentRecords();
            })
            .catch(error => console.error('Error getting profile name:', error));
    }

    get isAccountExeProfile() {
        return this.profileName == 'HEQ - Account Exe';
    }

    async loadContentRecords() {
        try {
            const data = await getContentRecords();
            console.log('Data fetched:', data);
            const sortedByModifiedDate = data.sort((a, b) => new Date(b.lastModifiedDate) - new Date(a.lastModifiedDate));
            console.log('sortedByModifiedDate ===>', JSON.stringify(sortedByModifiedDate));
            this.gridItems = sortedByModifiedDate.slice(0, 5).map(item => {
                let updatedURL = this.getThumbnailURL(item.FileType);
                let videoThumbURL = item.id;

                let descriptionVal = item.normalText ? item.normalText.replace(/;/g, ', ') : item.normalText;
                let topicVal = item.topic ? item.topic.replace(/;/g, ', ') : item.topic;

                return {
                    id: item.id,
                    heading: this.getFileType(item.FileType),
                    imageUrl: (item.id) ? updatedURL + videoThumbURL : noImage,
                    boldText: item.boldText,
                    normalText: descriptionVal,
                    normalText1: topicVal,
                    code: item.resourceCode,
                    expiryDays: item.expiryDays,
                    headerClass: item.headerColorCssClass,
                    showMenu: false,
                    contentDocumentId: item.contentDocumentId,
                    downloadLink: sitepath + '/sfc/servlet.shepherd/document/download/' + item.contentDocumentId + '?operationContext=S1',
                    isNewItem: item.isNewItem
                }
            })
            console.log('### gridItems ' + JSON.stringify(this.gridItems));
            this.gridItems.forEach(gridItem => {
                console.log('Griditems==>>', JSON.stringify(gridItem));
                console.log('Grid item isNewItem:', gridItem.isNewItem);
                this.fetchFileDetails(gridItem);
            });
            console.log('griditems console===>', JSON.stringify(this.gridItems));

            // let expiryDays = 0;
            // if (item.expiryDays) {
            //     const expirationDate = new Date(item.expiryDays);
            //     const currentDate = new Date();
            //     const timeDifference = expirationDate - currentDate;
            //     expiryDays = Math.ceil(timeDifference / (1000 * 60 * 60 * 24));
            // }

            // const soonToExpire = data.filter(item => item.expiryDays <= 100).sort((a, b) => a.expiryDays - b.expiryDays);

            const currentDate = new Date();

            const soonToExpire = data.filter(item => {
                const expirationDate = new Date(item.expiryDays);
                const timeDiff = expirationDate - currentDate;
                const daysDiff = timeDiff / (1000 * 60 * 60 * 24);
                return daysDiff <= 100;
            }).sort((a, b) => {
                const expirationDateA = new Date(a.Expiration_Date__c);
                const expirationDateB = new Date(b.Expiration_Date__c);
                return expirationDateA - expirationDateB;
            });


            this.soonToExpireItems = soonToExpire.slice(0, 5).map(item => {
                let updatedURL = this.getThumbnailURL(item.FileType);
                let videoThumbURL = item.id;

                let descriptionVal = item.normalText ? item.normalText.replace(/;/g, ', ') : item.normalText;
                let topicVal = item.topic ? item.topic.replace(/;/g, ', ') : item.topic;
                
                return {
                    id: item.id,
                    heading: this.getFileType(item.FileType),
                    imageUrl: (item.id) ? updatedURL + videoThumbURL : noImage,
                    boldText: item.boldText,
                    normalText: descriptionVal,
                    normalText1: topicVal,
                    code: item.resourceCode,
                    expiryDays: item.expiryDays,
                    headerClass: item.headerColorCssClass,
                    showMenu: false,
                    contentDocumentId: item.contentDocumentId,
                    downloadLink: sitepath + '/sfc/servlet.shepherd/document/download/' + item.contentDocumentId + '?operationContext=S1',
                    isNewItem: item.isNewItem
                }
            })
        } catch (error) {
            console.error('Error fetching content:', error);
        }
    }

    getFileType(fileType) {
        let typeOfFile = '';
        switch (fileType) {
            case 'PDF':
                typeOfFile = 'Static';
                break;
            case 'Video':
                typeOfFile = 'Video';
                break;
            default:
                typeOfFile = 'Static';
                break;
        }

        return typeOfFile;
    }

    async loadCollectionData() {
        try {
            const data = await getCustomerCollectionList();
            if (data) {
                console.log('CollectionData ' + JSON.stringify(data));
                const sortedByModifiedDate = data.sort((a, b) => new Date(b.createdDate) - new Date(a.createdDate));

                this.collectionItems = sortedByModifiedDate.slice(0, 5).map(item => {
                    let updatedURL = this.getThumbnailURL('Thumb');
                    return {
                        id: item.id,
                        heading: 'Collections',
                        imageUrl: (item.imageUrl) ? updatedURL + item.imageUrl : noImage,
                        boldText: item.name,
                        normalText: 'Shared On : ' + item.createdDate,
                        normalText1: 'Shared By : ' + item.sharedBy,
                        expiryDays: false,
                        headerClass: 'header-color-6',
                        showMenu: false,
                        notTruncated: true
                    }
                })
            }
        } catch (error) {
            console.error('Error loadCollectionData:', error);
        }
    }

    fetchFileDetails(gridItem) {
        console.log('Griditems in fetch==>>', JSON.stringify(gridItem));
        if (typeof gridItem === 'undefined') {
            console.error('Invalid gridItem:', gridItem);
            return;
        }
        FileDetails({ recordId: gridItem.id })
            .then(result => {
                console.log('result>>>', result);
                if (result && result.length > 0) {
                    const detail = result[0];
                    let updatedURL = this.getThumbnailURL(detail.FileType);
                    let videoThumbURL = recordId;
                    console.log('Video ' + videoThumbURL);
                    if (detail.MSD_CORE_Video_Resource__c) {
                        videoThumbURL = detail.ThumbnailURL__c;
                    }
                    gridItem.imageUrl = updatedURL + recordId;

                    this.gridItems = [...this.gridItems];
                    console.log('gridItem.imageUrl==>', gridItem.imageUrl);

                    return;
                }
            })
            .catch(error => {
                console.error('Error fetching topic details:', error);
                this.imageUrl = noImage;
            })
            .finally(() => {
                this.showSpinner = false;
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
                updatedThumbURL = thumbURL.replace('rendition=ORIGINAL_png', 'rendition=THUMB720BY480');
        }

        console.log('Updated ThumbURL:', updatedThumbURL);
        return updatedThumbURL;
    }

    configurePicklist() {
        const picklistFieldsConfig = [
            { objectApiName: 'ContentVersion', fieldApiName: 'MSD_CORE_Therapeutic_Area__c', propertyName: 'therapeuticAreaOptions' },
            { objectApiName: 'ContentVersion', fieldApiName: 'MSD_CORE_Topic__c', propertyName: 'topicOptions' }
        ];

        picklistFieldsConfig.forEach(({ objectApiName, fieldApiName, propertyName }) => {
            getPicklist({ objectApiName, fieldApiName })
                .then(result => {
                    console.log('resultpicklist==>', result);
                    this[propertyName] = result.map(entry => ({ label: entry.label, value: entry.value }));
                    if (propertyName === 'therapeuticAreaOptions' && this.therapeuticAreaOptions.length > 0) {
                        this.selectedTherapeuticArea = this.therapeuticAreaOptions[0].value;
                    }
                    if (propertyName === 'topicOptions' && this.topicOptions.length > 0) {
                        this.selectedTopic = this.topicOptions[0].value;
                    }
                })
                .catch(error => {
                    console.error(`Error retrieving ${fieldApiName} picklist values`, error);
                });
        });
    }

    handleTherapeuticAreaChange(event) {
        this.selectedTherapeuticArea = event.detail.value;
        console.log('Selected Therapeutic Area:', this.selectedTherapeuticArea);

        this.queryRecords({ therapeuticArea: this.selectedTherapeuticArea, topic: this.selectedTopic });
    }

    handleTopicChange(event) {
        this.selectedTopic = event.detail.value;
        console.log('Selected Therapeutic Area:', this.selectedTopic);
        this.queryRecords({ therapeuticArea: this.selectedTherapeuticArea, topic: this.selectedTopic });
    }

    queryRecords({ therapeuticArea, topic }) {
        /*getFilteredContent({ therapeuticArea, topic })
            .then(result => {
                console.log('Queried Records:', result);
                this.records = result;
            })
            .catch(error => {
                console.error('Error querying records:', error);
            });*/
    }


    // @track gridItems1 = [
    //     { id: '6', heading: 'Customizable', imageUrl: HomepageImage, boldText: 'What are Cancer Biometers Lorem Ipsum contra et tua', normalText: 'Text Line 1 Lorem ipsum contra et tu ', normalText1:'Text Line 2 Lorem ipsum tu a contra', code:'US-NON-1234', expiryDays: 100,
    //         headerClass: 'header-color-1'
    //         },
    //     { id: '7', heading: 'Customizable', imageUrl: HomepageImage, boldText: 'What are Cancer Biometers Lorem Ipsum contra et tua', normalText: 'Text Line 1 Lorem ipsum contra et tu ', normalText1:'Text Line 2 Lorem ipsum tu a contra', code:'US-NON-1234', expiryDays: 100,headerClass: 'header-color-2' },
    //     { id: '8', heading: 'Static', imageUrl: HomepageImage, boldText: 'What are Cancer Biometers Lorem Ipsum contra et tua', normalText: 'Text Line 1 Lorem ipsum contra et tu ', normalText1:'Text Line 2 Lorem ipsum tu a contra', code:'US-NON-1234', expiryDays: 100,headerClass: 'header-color-3' },
    //     { id: '9', heading: 'Static', imageUrl: HomepageImage, boldText: 'What are Cancer Biometers Lorem Ipsum contra et tua', normalText: 'Text Line 1 Lorem ipsum contra et tu ', normalText1:'Text Line 2 Lorem ipsum tu a contra', code:'US-NON-1234', expiryDays: 100,headerClass: 'header-color-4' },
    //     { id: '10', heading: 'Vedio', imageUrl: HomepageImage, boldText: 'What are Cancer Biometers Lorem Ipsum contra et tua', normalText: 'Text Line 1 Lorem ipsum contra et tu ', normalText1:'Text Line 2 Lorem ipsum tu a contra', code:'US-NON-1234', expiryDays: 100,headerClass: 'header-color-5' },
    // ];

    get headerStyle() {
        return (item) => {
            return `background-color: ${item.backgroundColor};`;
        };
    }

    truncateText(text, maxLength) {
        return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
    }

    // Prepare data with truncated text
    get preparedGridItems() {
        return this.gridItems.map(item => ({
            ...item,
            truncatedBoldText: this.truncateText(item.boldText, 50),
            truncatedNormalText: this.truncateText(item.normalText, 40),
            truncatedNormalText1: this.truncateText(item.normalText1, 40)
        }));
    }

    handleForward() {
        const container = this.template.querySelector('.grid-container');
        if (container) {
            container.scrollBy({ left: 500, behavior: 'smooth' });
        } else {
            console.error('No grid container found for forward navigation.');
        }
    }

    handleBackward() {
        const container = this.template.querySelector('.grid-container');
        if (container) {
            container.scrollBy({ left: -300, behavior: 'smooth' });
        } else {
            console.error('No grid container found for backward navigation.');
        }
    }

    handleBackwardClick() {
        const container = this.template.querySelector('.grid-containers');
        if (container) {
            container.scrollBy({ left: -300, behavior: 'smooth' });
        } else {
            console.error('No grid container found for backward navigation.');
        }
    }

    handleForwardClick() {
        const container = this.template.querySelector('.grid-containers');
        if (container) {
            container.scrollBy({ left: 500, behavior: 'smooth' });
        } else {
            console.error('No grid container found for forward navigation.');
        }
    }

    handleForwardSelection() {
        const cardContainer = this.template.querySelector('[data-id="scroll-grid"]');
        cardContainer.scrollBy({
            top: 0,
            left: 350,
            behavior: 'smooth'
        });
    }

    handleBackSelection() {
        const cardContainer = this.template.querySelector('[data-id="scroll-grid"]');
        cardContainer.scrollBy({
            top: 0,
            left: -350,
            behavior: 'smooth'
        });
    }

     handleBusinessForwardClick() {
        const cardContainer = this.template.querySelector('[data-id="businessContainer"]');
        cardContainer.scrollBy({
            top: 0,
            left: 350,
            behavior: 'smooth' // Smooth scrolling
        });
    }

    handleBusinessBackwardClick() {
        const cardContainer = this.template.querySelector('[data-id="businessContainer"]');
        cardContainer.scrollBy({
            top: 0,
            left: -350,
            behavior: 'smooth' // Smooth scrolling
        });
    }

    // handleViewAll(event) {
    //     event.preventDefault();
    //     console.log('handleViewAll called');
    // }

    handleShowMenu(event) {
        const { itemId, gridType, category } = event.detail;
        console.log('### 2 handleShowMenu Parent ' + JSON.stringify(event.detail));
        let itemUpdate = gridType === 'grid1' ? this.gridItems : this.soonToExpireItems;
        if(gridType === 'grid3') itemUpdate = this.collectionItems;

        itemUpdate = itemUpdate.map(item => {
            if (item.id === itemId) {
                return { ...item, showMenu: !item.showMenu };
            }
            return { ...item, showMenu: false };
        });

        if (gridType === 'grid1') {
            this.gridItems = itemUpdate;
        } else if(gridType === 'grid3') {
            this.collectionItems = itemUpdate;
        } else {
            this.soonToExpireItems = itemUpdate;
        }

        console.log(`Category for item ${itemId}: ${category}`); // Use category as needed
    }

    // handleShowMenu(event) {
    //     const itemId = event.currentTarget.dataset.id;
    //     this.gridItems = this.gridItems.map(item => {
    //         if (item.id === itemId) {
    //             return { ...item, showMenu: !item.showMenu };
    //         }
    //         return { ...item, showMenu: false };
    //     });
    // }

    // handleShowMenus(event) {
    //     const itemId = event.currentTarget.dataset.id;
    //     this.gridItems = this.gridItems1.map(item => {
    //         if (item.id === itemId) {
    //             return { ...item, showMenu: !item.showMenu };
    //         }
    //         return { ...item, showMenu: false };
    //     });
    // }

    handleCloseMenu() {
        this.showMenu = false;
    }

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



    handlePreview(event) {
        event.preventDefault();
        const itemId = event.target.dataset.id;
    }

    handleSelect(event) {
        const itemId = event.target.dataset.id;
        const isChecked = event.target.checked;
        // Implement select logic
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
                    let descriptionVal = item.MSD_CORE_Therapeutic_Area__c ? item.MSD_CORE_Therapeutic_Area__c.replace(/;/g, ', ') : item.MSD_CORE_Therapeutic_Area__c;
                    let topicVal = item.MSD_CORE_Topic__c ? item.MSD_CORE_Topic__c.replace(/;/g, ', ') : item.MSD_CORE_Topic__c;

                    return {
                        id: item.Id,
                        title: item.Title,
                        description: descriptionVal,
                        jobCode: item.MSD_CORE_Resource_Code__c,
                        ExpiryDate: item.MSD_CORE_Expiration_Date__c,
                        fulfillment: item.MSD_CORE_Fulfillment_Method__c,
                        subtitle: topicVal,
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
                    let descriptionVal = item.MSD_CORE_Therapeutic_Area__c ? item.MSD_CORE_Therapeutic_Area__c.replace(/;/g, ', ') : item.MSD_CORE_Therapeutic_Area__c;
                    let topicVal = item.MSD_CORE_Topic__c ? item.MSD_CORE_Topic__c.replace(/;/g, ', ') : item.MSD_CORE_Topic__c;

                    return {
                        id: item.Id,
                        title: item.Title,
                        description: descriptionVal,
                        JobCode: item.MSD_CORE_Resource_Code__c,
                        ExpiryDate: item.MSD_CORE_Expiration_Date__c,
                        fulfillment: item.MSD_CORE_Fulfillment_Method__c,
                        subtitle: topicVal,
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
            // case 'Collections':
            //     this.loadDynamicSection('Collections', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'CreatedDate DESC', 5);
            //     break;
            case 'Expiring soon':
                this.loadDynamicSection('Expiring Soon', userId, 'Id, Title, MSD_CORE_Topic__c', 'MSD_CORE_Expiration_Date__c != NULL', 'MSD_CORE_Expiration_Date__c ASC', 5);
                break;
            // case 'Therapeutic Area':
            //     this.loadDynamicSection('Therapeutic Area', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
            //     break;
            // case 'Topic':
            //     this.loadDynamicSection('Topics', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
            //     break;
            // case 'Health Equity':
            //     this.loadDynamicSection('Health Equity', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
            //     break;
            case 'New':
                this.loadDynamicSection('New Materials', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
                break;
            // case 'D&I Artbanks':
            //     this.loadDynamicSection('D&I Artbanks', userId, 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
            //     break;
            default:
                console.warn(`Unknown category: ${category}`);
                break;
        }
    }

    loadAECategory(category) {
        console.log('Category in loadAECategory:', category);
        switch (category) {
            // case 'Collections':
            //     this.loadSection('Collections', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'CreatedDate DESC', 5);
            //     break;
            case 'Expiring soon':
                this.loadSection(
                    'Expiring Soon',
                    'ContentVersion',
                    'Id, Description, Title, FileType, MSD_CORE_Is_Thumbnail__c, MSD_CORE_Is_Active__c, MSD_CORE_Therapeutic_Area__c, MSD_CORE_Topic__c, MSD_CORE_Video_Resource__c, MSD_CORE_Expiration_Date__c, LastModifiedDate, MSD_CORE_Resource_Code__c, MSD_CORE_Fulfillment_Method__c',
                    "MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND FileType IN ('PDF', 'VIDEO') AND MSD_CORE_Expiration_Date__c > TODAY",
                    'MSD_CORE_Expiration_Date__c ASC',
                    5
                );
                break;
            // case 'Therapeutic Area':
            //     this.loadSection('Therapeutic Area', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
            //     break;
            // case 'Topic':
            //     this.loadSection('Topics', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
            //     break;
            // case 'Health Equity':
            //     this.loadSection('Health Equity', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
            //     break;
            case 'New':
                this.loadSection(
                    'New Materials',
                    'ContentVersion',
                    'Id, Description, Title, FileType, MSD_CORE_Is_Thumbnail__c, MSD_CORE_Is_Active__c, MSD_CORE_Therapeutic_Area__c, MSD_CORE_Topic__c, MSD_CORE_Video_Resource__c, MSD_CORE_Expiration_Date__c, LastModifiedDate, MSD_CORE_Resource_Code__c, MSD_CORE_Fulfillment_Method__c',
                    "MSD_CORE_Is_Active__c = true AND MSD_CORE_Is_Thumbnail__c = false AND FileType IN ('PDF', 'VIDEO') AND MSD_CORE_Expiration_Date__c > TODAY",
                    'LastModifiedDate DESC',
                    5
                );

                break;
            // case 'D&I Artbanks':
            //     this.loadSection('D&I Artbanks', 'ContentVersion', 'Id, Title, MSD_CORE_Topic__c', '', 'LastModifiedDate DESC', 5);
            //     break;
            default:
                console.warn(`Unknown category: ${category}`);
                break;
        }
    }

    ViewDetails(event) {
        const topicId = event.target.dataset.id;
        console.log('View details for topic ID:', topicId);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/detailed?topicId=${encodeURIComponent(topicId)}`
            }
        });
    }

    handleViewAll(event) {
        const sectionTitle = event.target.dataset.title;
        // const category = event.target.dataset.category;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                // url: `/resources?category=${encodeURIComponent(category)}&title=${encodeURIComponent(sectionTitle)}`
                url: `/resources?type=${encodeURIComponent(sectionTitle)}`
            }
        });
    }

    handleCollectionViewAll(){
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/collections`
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