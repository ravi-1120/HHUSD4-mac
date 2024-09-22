import { LightningElement } from 'lwc';
import HEQLOGO from '@salesforce/resourceUrl/MSD_CORE_HEQ_Logo';
import USERICON from '@salesforce/resourceUrl/MSD_CORE_HEQ_User_Icon';
import CustomerButton from '@salesforce/label/c.MSD_CORE_HEQ_Customer_Button';
import MerckEmployeeButton from '@salesforce/label/c.MSD_CORE_HEQ_MerckEmployee_Button';
import { NavigationMixin } from 'lightning/navigation';
import isGuest from '@salesforce/user/isGuest';


export default class mSD_CORE_HEQ_LandingPage extends NavigationMixin(LightningElement) {
    imageUrl = HEQLOGO; 
    usericon = USERICON;

    label ={
        CustomerButton,
        MerckEmployeeButton
    }

    connectedCallback() {
        if (!isGuest) {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `/landing-page`
                }
            });
        }
    }

    handleCustomerClick() {
        window.location.href = this.label.CustomerButton;
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__webPage',
        //     attributes: {
        //         url: `/landing-page`
        //     }
        // });
    }

    handleMerckEmployeeClick() {
          window.location.href = this.label.MerckEmployeeButton;

        //this[NavigationMixin.Navigate]({
            //type: 'standard__webPage',
            //attributes: {
             //   url: `/landing-page`
           // }
       // });
    }

    
}