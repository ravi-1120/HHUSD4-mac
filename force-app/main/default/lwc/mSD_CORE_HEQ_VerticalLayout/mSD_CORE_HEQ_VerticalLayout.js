import { LightningElement, track, api } from 'lwc';
import getTherapeuticAreaContent from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.getTherapeuticAreaContent';
import getTopicContent from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.getTopicContent';
import getPicklist from '@salesforce/apex/MSD_CORE_HEQ_ContentVersionController.getPicklist';
import HomepageImage from '@salesforce/resourceUrl/MSD_CORE_Homepage_Image';
import { NavigationMixin } from 'lightning/navigation';
import thumbURL from '@salesforce/label/c.MSD_CORE_HEQ_SandboxURL';
import ViewAll from '@salesforce/label/c.MSD_CORE_HEQ_View_All';
import sitepath from '@salesforce/label/c.MSD_CORE_HEQ_SitePath_For_Download';


export default class MSD_CORE_HEQ_VerticalLayout extends NavigationMixin(LightningElement) {
    @track therapeuticAreaOptions = [];
    @track topicOptions = [];
    @track selectedTherapeuticArea;
    @track selectedTherapeuticArea1  = 'Pan-Tumor';
    @track selectedTopic;
    @track therapeuticCards = [];
    @track topicCards = [];
    scrollAmount = 350;


    @track selectedTumorType = '';
    @track tumorCards = [];
    @track allTumorCards = []; // This will contain both dynamic and static data
    // Static data for Tumor Types
    tumorTypeOptions = [
        { label: 'Pan-Tumor', value: 'Pan-Tumor' }
        // { label: 'Breast Cancer', value: 'Breast Cancer' },
        // { label: 'Colorectal Cancer', value: 'Colorectal Cancer' }
    ];



    label = {
        ViewAll
    }

    @track menuOptions = [
        { action: 'download', label: 'Download', downloadActive : true },
        { action: 'preview', label: 'Preview & Details', downloadActive : false },
        { action: 'email', label: 'Email to customer', downloadActive : false },
        { action: 'addToCollection', label: 'Add to Collection', downloadActive : false },
        { action: 'print', label: 'Print to customer', downloadActive : false }
    ];

    handleShowMenu(event) {
        const itemId = event.currentTarget.dataset.id;
        console.log('Menu button clicked for item ID:', itemId);
        this.therapeuticCards = this.therapeuticCards.map(card => {
            if (card.id === itemId) {
                card.showMenu = !card.showMenu;
                console.log('Toggling showMenu:', card.showMenu);
            } else {
                card.showMenu = false;
            }
            return card;
        });

        this.topicCards = this.topicCards.map(card => {
            if (card.id === itemId) {
                card.showMenu = !card.showMenu;
                console.log('Toggling showMenu:', card.showMenu);
            } else {
                card.showMenu = false;
            }
            return card;
        });
    }

    handleMenuClick(event) {
        const action = event.target.dataset.action;
        const itemId = event.target.dataset.id;
        const contID = event.target.dataset.contentdocumentid;
        console.log('contentdocumentid in verticallayout', contID);
        console.log(`Action: ${action}, Item ID: ${itemId}`);

        const menuClickEvent = new CustomEvent('menuclick', {
            detail: { action, itemId }
        });

        this.therapeuticCards = this.therapeuticCards.map(card => {
            if (card.id == itemId) {
                card.showMenu = false;
            }
            return card;
        });

        this.topicCards = this.topicCards.map(card => {
            if (card.id == itemId) {
                card.showMenu = false;
            }
            return card;
        });
        switch (action) {
            case 'print':
                console.log(`Print item ${itemId}`);
                break;
            case 'preview':
                this.handlePreview(itemId);
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
    }
    
    connectedCallback() {
    this.configurePicklist()
        .then(() => {
            // Ensure `selectedTherapeuticArea` and `selectedTopic` have valid values before making queries
            if (this.selectedTherapeuticArea) {
                this.queryTherapeuticAreaContent(this.selectedTherapeuticArea);
            }
            if (this.selectedTopic) {
                this.queryTopicContent(this.selectedTopic);
            }
        })
        .catch(error => {
            console.error('Error in connectedCallback:', error);
        });
}

     handleForward() {
        const cardContainer = this.template.querySelector('[data-id="cardContainer"]');
        cardContainer.scrollBy({
            top: 0,
            left: this.scrollAmount,
            behavior: 'smooth' // Smooth scrolling
        });
    }


   handleBackward() {
        const cardContainer = this.template.querySelector('[data-id="cardContainer"]');
        cardContainer.scrollBy({
            top: 0,
            left: -this.scrollAmount,
            behavior: 'smooth' // Smooth scrolling
        });
    }

    handleBackwardClick() {
        const cardContainer = this.template.querySelector('[data-id="cardContainers"]');
        cardContainer.scrollBy({
            top: 0,
            left: -this.scrollAmount,
            behavior: 'smooth' // Smooth scrolling
        });
    }


    handleForwardClick() {
        const cardContainer = this.template.querySelector('[data-id="cardContainers"]');
        cardContainer.scrollBy({
            top: 0,
            left: this.scrollAmount,
            behavior: 'smooth' // Smooth scrolling
        });
    }

     handletumorForwardClick() {
        const cardContainer = this.template.querySelector('[data-id="tumarcardContainer"]');
        cardContainer.scrollBy({
            top: 0,
            left: this.scrollAmount,
            behavior: 'smooth' // Smooth scrolling
        });
    }

    handletumorBackwardClick() {
        const cardContainer = this.template.querySelector('[data-id="tumarcardContainer"]');
        cardContainer.scrollBy({
            top: 0,
            left: -this.scrollAmount,
            behavior: 'smooth' // Smooth scrolling
        });
    }



    configurePicklist() {
    const picklistFieldsConfig = [
        { objectApiName: 'ContentVersion', fieldApiName: 'MSD_CORE_Therapeutic_Area__c', propertyName: 'therapeuticAreaOptions' },
        { objectApiName: 'ContentVersion', fieldApiName: 'MSD_CORE_Topic__c', propertyName: 'topicOptions' }
    ];

    const picklistPromises = picklistFieldsConfig.map(({ objectApiName, fieldApiName, propertyName }) =>
        getPicklist({ objectApiName, fieldApiName })
            .then(result => {
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
            })
    );

    return Promise.all(picklistPromises);
}


    handleTherapeuticAreaChange(event) {
        this.selectedTherapeuticArea = event.detail.value;
        console.log('Selected Therapeutic Area:', this.selectedTherapeuticArea);
        this.queryTherapeuticAreaContent(this.selectedTherapeuticArea);
    }

    handleTopicChange(event) {
        this.selectedTopic = event.detail.value;
        console.log('Selected Topic:', this.selectedTopic);
        this.queryTopicContent(this.selectedTopic);
    }

    getThumbnailURL(fileType,recordId) {
        console.log('ThumbURL Return HEQ_verticalLayout' + fileType);
        console.log('Generating thumbnail URL...HEQ_verticalLayout');
        console.log('File Type:HEQ_verticalLayout', fileType);
        console.log('Record ID:HEQ_verticalLayout', recordId);
        let updatedThumbURL = `${thumbURL}${recordId}`;

        switch (fileType.toUpperCase()) {
            case 'JPG':
                updatedThumbURL = updatedThumbURL.replace('rendition=ORIGINAL_png', 'rendition=ORIGINAL_Jpg');
                console.log('Updated ThumbURL for JPG:HEQ_verticalLayout', updatedThumbURL);
                break;
            case 'PNG':
                updatedThumbURL = updatedThumbURL.replace('rendition=ORIGINAL_png', 'rendition=ORIGINAL_Png');
                console.log('Updated ThumbURL for PNG:HEQ_verticalLayout', updatedThumbURL);
                break;
            case 'PDF':
                updatedThumbURL = updatedThumbURL.replace('rendition=ORIGINAL_png', 'rendition=SVGZ');
                console.log('Updated ThumbURL for PDF:HEQ_verticalLayout', updatedThumbURL);
                break;
            default:
                updatedThumbURL = updatedThumbURL.replace('rendition=ORIGINAL_png', 'rendition=SVGZ');
        }

        console.log('Updated ThumbURL:', updatedThumbURL);
        return updatedThumbURL;
    }

// queryTherapeuticAreaContent(therapeuticArea) {
//     getTherapeuticAreaContent({ therapeuticArea })
//         .then(result => {
//             this.therapeuticCards = result.map(record => {
//                 let updatedURL = this.getThumbnailURL(record.FileType, record.Id);
//                 console.log('Record:', record);
//                 return {
//                     id: record.Id,
//                     contentType: record.FileType,
//                     title: record.Title,
//                     textLine1: record.Description,
//                     textLine2: record.MSD_CORE_Fulfillment_Method__c,
//                     referenceCode: record.MSD_CORE_Resource_Code__c,
//                     expiryDays: this.calculateExpiryDays(record.MSD_CORE_Expiration_Date__c),
//                     imageUrl: updatedURL,
//                     contentDocumentId: record.ContentDocumentId,
//                         downloadLink: sitepath+'/sfc/servlet.shepherd/document/download/'+record.ContentDocumentId+'?operationContext=S1'
//                 };
//             });
//             console.log('Thereapatic card==>', JSON.stringify(this.therapeuticCards))
//         })
//         .catch(error => {
//             console.error('Error querying therapeutic area content:', error);
//         });
// }

queryTherapeuticAreaContent(therapeuticArea) {
    getTherapeuticAreaContent({ therapeuticArea })
        .then(result => {
            this.therapeuticCards = result.map(record => {
                let updatedURL = this.getThumbnailURL(record.FileType, record.Id);
                let backgroundColor = '';
                let typeOfFile = '';
                switch (record.FileType) {
                    case 'PDF':
                        backgroundColor = '#58A58E'; // Green for PDF
                        typeOfFile = 'Static';
                        break;
                    case 'Video':
                        backgroundColor = '#5493C6'; // Blue for Video
                        typeOfFile = 'Video';
                        break;
                    case 'Customizable':
                        backgroundColor = '#FF9500'; // Amber for Customizable
                        break;
                    default:
                        backgroundColor = '#C4C4C4'; // Default color for other file types
                        break;
                }

                let descriptionVal = record.MSD_CORE_Therapeutic_Area__c ? record.MSD_CORE_Therapeutic_Area__c.replace(/;/g, ', ') : record.MSD_CORE_Therapeutic_Area__c;
                let topicVal = record.MSD_CORE_Topic__c ? record.MSD_CORE_Topic__c.replace(/;/g, ', ') : record.MSD_CORE_Topic__c;
                
                return {
                    id: record.Id,
                    contentType: typeOfFile,
                    title: record.Title,
                    textLine1: descriptionVal,
                    textLine2: topicVal,
                    referenceCode: record.MSD_CORE_Resource_Code__c,
                    expiryDays: this.calculateExpiryDays(record.MSD_CORE_Expiration_Date__c),
                    imageUrl: updatedURL,
                    contentDocumentId: record.ContentDocumentId,
                    downloadLink: sitepath+'/sfc/servlet.shepherd/document/download/'+record.ContentDocumentId+'?operationContext=S1',
                    backgroundColor: backgroundColor,
                    isNewItem: record.MSD_CORE_IsNewItem__c
                };
            });
            console.log('Therapeutic card==>', JSON.stringify(this.therapeuticCards))
        })
        .catch(error => {
            console.error('Error querying therapeutic area content:', error);
        });
}





    queryTopicContent(topic) {
        getTopicContent({ topic })
            .then(result => {
                console.log('Topic Cards Received:', JSON.stringify(result));
                this.topicCards = result.map(record => {
                    let updatedURL = this.getThumbnailURL(record.FileType, record.Id);
                    console.log('Record:', record);
                    let backgroundColor = '';
                    let typeOfFile = '';
                    switch (record.FileType) {
                        case 'PDF':
                            backgroundColor = '#58A58E'; // Green for PDF
                            typeOfFile = 'Static';
                            break;
                        case 'Video':
                            backgroundColor = '#5493C6'; // Blue for Video
                            typeOfFile = 'Video';
                            break;
                        case 'Customizable':
                            backgroundColor = '#FF9500'; // Amber for Customizable
                            break;
                        default:
                            backgroundColor = '#C4C4C4'; // Default color for other file types
                            break;
                    }

                    let descriptionVal = record.MSD_CORE_Therapeutic_Area__c ? record.MSD_CORE_Therapeutic_Area__c.replace(/;/g, ', ') : record.MSD_CORE_Therapeutic_Area__c;
                    let topicVal = record.MSD_CORE_Topic__c ? record.MSD_CORE_Topic__c.replace(/;/g, ', ') : record.MSD_CORE_Topic__c;

                    return {
                        id: record.Id,
                        contentType: typeOfFile,
                        title: record.Title,
                        textLine1: descriptionVal,
                        textLine2: topicVal,
                        referenceCode: record.MSD_CORE_Resource_Code__c,
                        expiryDays: this.calculateExpiryDays(record.MSD_CORE_Expiration_Date__c),
                        imageUrl: updatedURL,
                        contentDocumentId: record.ContentDocumentId,
                        downloadLink: sitepath + '/sfc/servlet.shepherd/document/download/' + record.contentDocumentId + '?operationContext=S1',
                        backgroundColor: backgroundColor,
                        isNewItem: record.MSD_CORE_IsNewItem__c == 'true' ? true : false
                    };
                });
            })
            .catch(error => {
                console.error('Error querying topic content:', error);
            });
    }

    calculateExpiryDays(expirationDate) {
        if (!expirationDate) {
            return 0;
        }

        // const today = new Date();
        // const expDate = new Date(expirationDate);
        // const timeDifference = expDate - today;

        // const daysDifference = Math.ceil(timeDifference / (1000 * 60 * 60 * 24));

        // return daysDifference > 0 ? daysDifference : 0;

        let formattedDate = new Intl.DateTimeFormat('en-US', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }).format(new Date(expirationDate));

        return formattedDate;
    }

    handleViewAll(event) {
        const sectionTitle = event.target.dataset.title;
        const selectedTopic =  event.target.dataset.category;
        console.log('selectedTopic verticallayout', selectedTopic);
        console.log('sectionTitle verticallayout', sectionTitle);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources?type=${encodeURIComponent(sectionTitle)}&category=${encodeURIComponent(selectedTopic)} `
            }
        });
    }

    handlePreview(resourceId) {
        console.log('### verticallayout resourceId>>', resourceId);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/preview?recordId=${encodeURIComponent(resourceId)}`
            }
        });
    }

    handleViewDetails(event) {
        // const topicTitle = topicCard.title;
        const contDocId = event.target.dataset.id;
        console.log('View details for topic ID: verticallayout');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/resources/detailed?topicId=${encodeURIComponent(contDocId)}`
            }
        });
    }

   staticTumorCards = [
        {
            id: '1',
            contentType: 'PDF',
            title: 'Lung Cancer Treatment',
            description: 'Overview of lung cancer treatments.',
            imageUrl: 'https://example.com/lung-cancer.png',
            expiryDays: 120
        },
        {
            id: '2',
            contentType: 'Video',
            title: 'Breast Cancer Awareness',
            description: 'Breast cancer awareness campaign.',
            imageUrl: 'https://example.com/breast-cancer.png',
            expiryDays: 90
        },
        {
            id: '3',
            contentType: 'Customizable',
            title: 'Colorectal Cancer Screening',
            description: 'Information on colorectal cancer screening.',
            imageUrl: 'https://example.com/colorectal-cancer.png',
            expiryDays: 60
        }
    ];
    // Handle Tumor Type change from the combobox
     handleTumorTypeChange(event) {
        this.selectedTumorType = event.detail.value;

        // Fetch or set dynamic cards based on selected tumor type
        this.tumorCards = [
            // Add dynamic content here, similar to the static cards
            {
                id: '4',
                contentType: 'PDF',
                title: this.selectedTumorType + ' Research Paper',
                description: 'Detailed research paper on ' + this.selectedTumorType,
                imageUrl: 'https://example.com/research.png',
                expiryDays: 45,
                isNewItem: true
            },
            {
                id: '5',
                contentType: 'Video',
                title: this.selectedTumorType + ' Treatment Video',
                description: 'Explaining treatments for ' + this.selectedTumorType,
                imageUrl: 'https://example.com/treatment-video.png',
                expiryDays: 30
            }
        ];

        // Merge static and dynamic cards
        this.allTumorCards = [...this.tumorCards, ...this.staticTumorCards];
    }

      getCardBackgroundClass(contentType) {
        switch (contentType) {
            case 'PDF':
                return 'card-content pdf-background';
            case 'Video':
                return 'card-content video-background';
            case 'Customizable':
                return 'card-content customizable-background';
            default:
                return 'card-content';
        }
    }

  
}