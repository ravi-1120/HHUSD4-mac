import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import msdLogo from '@salesforce/resourceUrl/PDSMSDWhiteLogo';
import getCopyrightLabel from '@salesforce/apex/PDS_Utility.getCopyrightLabel';
export default class PdsFooter extends LightningElement {
    msdLogo = msdLogo;
    copyright = '';
    connectedCallback() {
        this.getCopyrightLabel();
        // Promise.all([
        //     loadStyle(this, PDSExternalCSS)
        // ])
    }

    getCopyrightLabel(){
        getCopyrightLabel({})
        .then((result) => {
            this.copyright = result;
        })
        .catch((error) => {
            console.log('error-->', { error });
        })
    }
}