import { LightningElement, track } from 'lwc';
//Static Resources
import dihLogin from '@salesforce/resourceUrl/MSD_CORE_HEQ_FEP';

export default class MSD_CORE_HEQ_DIH_ResetPassword extends LightningElement {

    @track dihURL;
    showSpinner = false;

    connectedCallback() {
        const queryString = window.location.search;
        this.showSpinner = true;
        let resetURL = (queryString) ? '/index.html'+queryString : '/index.html?screenToRender=forgotPassword';
        this.dihURL = dihLogin + resetURL;
        console.log('URL ' + this.dihURL);
        this.showSpinner = false;
    }
}