import { LightningElement, track } from 'lwc';

import cancel from '@salesforce/label/c.MSD_CORE_Cancel';
import Close from '@salesforce/label/c.MSD_CORE_Close_Btn';
import helplinks from '@salesforce/label/c.MSD_CORE_HEQ_Helpful_links';
import Proceed from '@salesforce/label/c.MSD_CORE_HEQ_Proceed';
import popupmsg from '@salesforce/label/c.MSD_CORE_HEQ_Popup_msg';

import getHelpLinks from '@salesforce/apex/MSD_CORE_HEQ_FooterController.getHelpLinks';

export default class MSD_CORE_HEQ_HelpLinks extends LightningElement {
    @track helpLinks = [];
    @track showPopup = false;
    @track selectedLink = '';

    label = {
        cancel,
        Close,
        helplinks,
        Proceed,
        popupmsg
    }

    connectedCallback() {
        this.loadHelpLinks();
    }

    loadHelpLinks() {
        getHelpLinks()
            .then(result => {
                this.helpLinks = result; 
            })
            .catch(error => {
                console.error('Error retrieving help links:', error);
            });
    }

    handleLinkClick(event) {
    const url = event.target.dataset.url;
    const interstitialPopup = event.target.dataset.interstitial === 'true';

    if (interstitialPopup) {
        this.selectedLink = url;
        this.showPopup = true;
    } else {
        window.open(url);
    }
}


    handleProceed() {
        window.open(this.selectedLink, '_blank'); 
        this.showPopup = false; 
    }

    handleCancel() {
        this.showPopup = false; 
    }
}