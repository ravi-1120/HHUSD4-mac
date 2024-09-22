import { LightningElement,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import AMO_FONTS from '@salesforce/resourceUrl/AMO_Fonts'
import Merck_logo from '@salesforce/label/c.Merck_Logo';
import MerckContact from '@salesforce/resourceUrl/MerckContact';

export default class MSD_CORE_medicalhome extends NavigationMixin(LightningElement) {
    imageUrl = Merck_logo;
    MerckContact = MerckContact;
    fontsBaseUrl = AMO_FONTS;
    @track menu = false;
    @track icon = true;
    buttonType;
    showWelcomePopup = true;
   @track CI = false;

    connectedCallback() {
        if (this.hasPopupClosed) {
            this.showWelcomePopup = false;
            
        }
    }
   
    redirectToReport() {
       window.location.href = 'https://msdlogin--hhusd3.sandbox.my.site.com/AE/';
   }
   navigateToCI() {
       this[NavigationMixin.Navigate]({
           type: 'standard__webPage',
           attributes: {
               url: '/CI'
           }
       });
   }
   handleButtonChoice(event) {
    this.showWelcomePopup = false;
    this.buttonType = event.detail.buttonType;
    this.hasPopupClosed = true;
    if (this.buttonType === 'Non-US') {
        window.location.href = 'https://www.msd.com/contact-us/worldwide-locations/';
    } else if(this.buttonType === 'Merck Employee') {
          this.CI = true;
    }
   }

   menuOpen = false;

   get menuClass() {
       return this.menuOpen ? 'off-screen-menu active' : 'off-screen-menu';
   }

   get hamClass() {
       return this.menuOpen ? 'ham-menu active' : 'ham-menu';
   }

   toggleMenu() {
       this.menuOpen = !this.menuOpen;
   }

}