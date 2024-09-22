import { LightningElement, track } from 'lwc';

//Static Resources
import dihLogin from '@salesforce/resourceUrl/MSD_CORE_HEQ_FEP';

export default class MSD_CORE_HEQ_VerifyEmail extends LightningElement {

    @track dihURL;
    showSpinner = false;

    connectedCallback() {
        const queryString = window.location.search;
        this.showSpinner = true;
        if(dihLogin){
            this.dihURL = dihLogin + '/index.html' + queryString;
        }
        console.log('URL ' + dihLogin);
        this.showSpinner = false;
    }
}