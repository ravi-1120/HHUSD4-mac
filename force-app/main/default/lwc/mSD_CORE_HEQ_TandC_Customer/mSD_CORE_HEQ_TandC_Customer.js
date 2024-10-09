import { LightningElement, api, track } from 'lwc';
import home from '@salesforce/label/c.MSD_CORE_HEQ_Home';
import updateUserPreference from '@salesforce/apex/MSD_CORE_HEQ_UserPreferenceController.updateUserPreference';
import getTermsAndConditions from '@salesforce/apex/MSD_CORE_HEQ_UserPreferenceController.getTermsAndConditions';
//import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';
import { NavigationMixin } from 'lightning/navigation';

export default class MSD_CORE_HEQ_TandC_Customer extends NavigationMixin(LightningElement) {
    @api isPopup = false;

    labels = { home };
    @track headerText = '';
    @track contentText = '';
    @track footerText = '';
    @track isAccepted = false;

    connectedCallback() {
        this.loadTermsAndConditions();
    }

    async loadTermsAndConditions() { 
    try {
        const termsAndConditions = await getTermsAndConditions();

        if (termsAndConditions) {
            this.headerText = termsAndConditions.MSD_CORE_Header__c;
            this.contentText = termsAndConditions.MSD_CORE_Content__c;
            this.footerText = termsAndConditions.MSD_CORE_Footer__c;
        }
    } catch (error) {
        console.error('Error fetching terms and conditions:', error);
    }
}


    handleCheckboxChange(event) {
        this.isAccepted = event.target.checked;
    }

    get isButtonDisabled() {
        return !this.isAccepted;
    }

    async handlePopup() {
        if (this.isAccepted) {
            try {
                await updateUserPreference({ acceptedTC: true });
                this.dispatchEvent(new CustomEvent('tandcaccepted', { detail: true }));
                if (this.isPopup) {
                    this.dispatchEvent(new CustomEvent('closepopup'));
                }
            } catch (error) {
                console.error('Error updating user preference:', error);
            }
        }
    }

    // handleClose() {
    //     if (this.isPopup) {
    //         this.dispatchEvent(new CustomEvent('closepopup'));
    //     } else {
    //         this.redirectToHome();
    //     }
    // }

    handleClose() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/dih-login'
            }
        });
    }
}