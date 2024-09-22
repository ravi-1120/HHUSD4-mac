import { LightningElement } from 'lwc';
import Id from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import getAccountLockStatus from '@salesforce/apex/MSD_CORE_RedirectController.getAccountLockStatus';
import redirect from '@salesforce/resourceUrl/redirect';
import { loadStyle } from 'lightning/platformResourceLoader';
import MSD_CORE_MedicalSettings_Url from '@salesforce/label/c.MSD_CORE_MedicalSettings_Url';

export default class MSD_CORE_Redirect extends NavigationMixin(LightningElement) {
    userId = Id;
    redirect = redirect;
    connectedCallback() {
        console.log('LOGGED IN USER : '+this.userId);
        getAccountLockStatus({ userId: this.userId })
            .then((result) => {
                console.log('RESULT : ',{ result });
                if(result.accountStatus == 'Locked'){
                    //location.href = result.siteAPIName + '?tab=2';
                     window.open(MSD_CORE_MedicalSettings_Url+'?tab=2', '_self');
                }
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }

        renderedCallback() {
        Promise.all([
            loadStyle(this, redirect)
        ]).then(() => {
        })
            .catch(error => {
                console.log(error.body.message);
            });
    }
}