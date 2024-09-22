import { LightningElement, track, api } from 'lwc';
import policytitle from '@salesforce/label/c.MSD_CORE_cipolicy_title'
import subtitle from '@salesforce/label/c.MSD_CORE_cipolicy_subtitle';
import statement1 from '@salesforce/label/c.MSD_CORE_cipolicy_statement1';
import statement2 from '@salesforce/label/c.MSD_CORE_cipolicy_statement2';
import statement3 from '@salesforce/label/c.MSD_CORE_cipolicy_statement3';
import statement4 from '@salesforce/label/c.MSD_CORE_cipolicy_statement4';
import lettertitle from '@salesforce/label/c.MSD_CORE_cipolicy_lettertitle';
import fieldpolicy from '@salesforce/label/c.MSD_CORE_cipolicy_fieldpolicy';
import acknowledgment from '@salesforce/label/c.MSD_CORE_ciportal_acknowledgment';
import Previous from '@salesforce/label/c.MSD_CORE_ciportal_prevnavi';
import Next from '@salesforce/label/c.MSD_CORE_ciportal_nextnavi';
export default class MSD_CORE_ci_policymodal extends LightningElement {
    @api label = {
        CONTINUE: 'Continue'
    };
    @track isAcknowledged = false;
    @track showError = false;
    @api modal;
    _localModal = false;
    label={
        policytitle,
        subtitle,
        statement1,
        statement2,
        statement3,
        statement4,
        lettertitle,
        fieldpolicy,
        acknowledgment,
        Previous,
        Next
    }
    connectedCallback() {
        this.lockScrolling();
        this._localModal = this.modal;
    }
    disconnectedCallback() {
        this.unlockScrolling();
    }

    lockScrolling() {
        document.body.classList.add('no-scroll');
    }

    unlockScrolling() {
        document.body.classList.remove('no-scroll');
    }

    handleCheckboxChange(event) {
        this.isAcknowledged = event.target.checked;
        this.showError = false;
    }

    handleContinue() {
        if (this.isAcknowledged) {
            this.template.querySelector('[data-id="popup-modal"]').classList.remove('slds-fade-in-open');
            this.template.querySelector('.slds-backdrop').classList.remove('slds-backdrop_open');
            this._localModal = !this._localModal;
            const changeEvent = new CustomEvent('modalchange', {
            detail: this._localModal
        });
        this.dispatchEvent(changeEvent);
            this.unlockScrolling();
        } else {
            this.showError = true;
        }
    }
}