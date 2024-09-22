import { LightningElement, track, api } from 'lwc';
import PATIENTINFORMATIONGUIDANCE from '@salesforce/label/c.MSD_CORE_ae_Patient_Information_Guidance';
import PATIENTINFORMATIONFIRSTINSTRUCTION from '@salesforce/label/c.MSD_CORE_ae_Patient_Information_First_Instruction';
import PATIENTINFORMATIONFOURTHINSTRUCTION from '@salesforce/label/c.MSD_CORE_ae_Patient_Information_Fourth_Instruction';
import PATIENTINFORMATIONSECONDINSTRUCTION from '@salesforce/label/c.MSD_CORE_ae_Patient_Information_Second_Instruction';
import PATIENTINFORMATIONSECOND2INSTRU from '@salesforce/label/c.MSD_CORE_ae_Patien_Information_Second2_Instruction';
import PATIENTINFORMATIONTHIRDINSTRUCTION from '@salesforce/label/c.MSD_CORE_ae_Patient_Information_Third_Instruction';
// import CLOSEBUTTON from '@salesforce/label/c.MSD_CORE_ae_Close_Button';
import CONTINUE from '@salesforce/label/c.MSD_CORE_ae_Continue';



export default class MSD_CORE_ae_instructions extends LightningElement {
    label = {
        PATIENTINFORMATIONGUIDANCE,
        PATIENTINFORMATIONFOURTHINSTRUCTION,
        PATIENTINFORMATIONFIRSTINSTRUCTION,
        PATIENTINFORMATIONSECONDINSTRUCTION,
        PATIENTINFORMATIONSECOND2INSTRU,
        PATIENTINFORMATIONTHIRDINSTRUCTION,
        CONTINUE
    }
    @api modal;

    // Create a local private variable to track modal state
    _localModal = false;

    connectedCallback() {
        // Set initial value of _localModal based on the value passed from parent
        this._localModal = this.modal;
    }

    toggleModal() {
        // Toggle the local modal value
        this._localModal = !this._localModal;

        // Fire an event to notify parent of the change
        const changeEvent = new CustomEvent('modalchange', {
            detail: this._localModal
        });
        this.dispatchEvent(changeEvent);
    }
}