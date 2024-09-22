import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import updateUserPreference from '@salesforce/apex/MSD_CORE_HEQ_UserPreferenceController.updateUserPreference';
import getTermsAndConditions from '@salesforce/apex/MSD_CORE_HEQ_UserPreferenceController.getTermsAndConditions';
import getUserProfileName from '@salesforce/apex/MSD_CORE_HEQ_HeaderController.getUserProfileName';

export default class MSD_CORE_HEQ_TandC extends NavigationMixin(LightningElement) {
    @track isShow = true;
    @track headerText = '';
    @track contentText = '';
    @track footerText = '';
    @track profileName;
    @track isAccepted = false;

    connectedCallback() {
        this.getUserData();
        console.log('connected call back in t&C');
    }

    getUserData() {
        getUserProfileName()
            .then(profileName => {
                this.profileName = profileName;
                console.log('this.userData in T&C==>', JSON.stringify(profileName));
                this.loadTermsAndConditions();
            })
            .catch(error => console.error('Error getting profile name:', error));
    }

    async loadTermsAndConditions() {
        try {
            //const profileName = this.profileName;
            console.log('this.profileNameLoadTerms in T&C==>', this.profileName);
            const termsAndConditions = await getTermsAndConditions({ profileName: this.profileName });
            console.log('termsAndConditions==>', termsAndConditions);
            if (termsAndConditions) {
                this.headerText = termsAndConditions.MSD_CORE_Header__c;
                console.log('this.headerText'+this.headerText);
                this.contentText = termsAndConditions.MSD_CORE_Content__c;
                console.log('this.contentText'+this.contentText);
                this.footerText = termsAndConditions.MSD_CORE_Footer__c;
                console.log('this.footerText'+this.footerText);
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
                this.isShow = false;
                const event = new CustomEvent('tandcaccepted', { detail: true });
                this.dispatchEvent(event);
            } catch (error) {
                console.error('Error updating user preference:', error);
            }
        }
    }

    handleClose() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/'
            }
        });
    }
}