import { LightningElement } from 'lwc';
import AMO_FONTS from '@salesforce/resourceUrl/AMO_Fonts'
import Merck_logo from '@salesforce/label/c.Merck_Logo';
import { NavigationMixin } from 'lightning/navigation';
export default class MSD_CORE_ci_header extends NavigationMixin(LightningElement) {
    imageUrl = Merck_logo;
    fontsBaseUrl = AMO_FONTS;
    navigateToHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/Home'
            }
        });
    }
}