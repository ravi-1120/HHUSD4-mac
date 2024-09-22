/** 
  * Auther:              Ravi Modi (Focal CXM)
  * Component Name:      mSD_CORE_FLSPopup
  * Description:         Used for Display Forward Looking Statement Popup modal
  * Used in:             MHEE Portal Site Study Detail Community Page (mSD_CORE_StudyDetail)
  * Created Date:        14th March 2023
  * Lastmodified Date:   16th March 2023
  */

import { LightningElement, track, wire, api } from 'lwc';

import crossmark from '@salesforce/resourceUrl/cross';

export default class MSD_CORE_FLSPopup extends LightningElement {

    cross = crossmark;                      //Static Resource Cross button

    @track openmodalbox = false;

    // Method Name:         closeModal
    // Method Use:          Used for closing the modal popup
    // Developer Name:      Ravi Modi
    // Created Date:        14th March 2023
    closeModal() {
        this.openmodalbox = false;
    }

    // Method Name:         openModal
    // Method Use:          Used for Open the modal popup
    // Developer Name:      Ravi Modi
    // Created Date:        14th March 2023
    @api
    openModal() {
        this.openmodalbox = true;
    }
}