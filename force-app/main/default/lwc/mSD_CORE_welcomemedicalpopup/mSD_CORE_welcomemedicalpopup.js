import { LightningElement, track } from 'lwc';
import ConsentTitle from '@salesforce/label/c.MSD_CORE_ae_consentTitle';
import AEWELCOMEBODY from '@salesforce/label/c.MSD_CORE_ae_welcomeBody';
import AEConsentBodyText1 from '@salesforce/label/c.MSD_CORE_ae_welcomeBody1';
import AEConsentWelcome from '@salesforce/label/c.MSD_CORE_ae_welcomeHeader';
import MERCK_PRIVACY_URL from '@salesforce/label/c.MSD_ae_privacyUrl';
import MERCK_EMPLOYEE from '@salesforce/label/c.MSD_CORE_ci_MerckEmployee';
import NON_US from '@salesforce/label/c.MSD_CORE_ci_NonUs';
import MERCK_VENDOR from '@salesforce/label/c.MSD_CORE_ci_MerckVendor';
import MERCK_PATIENT from '@salesforce/label/c.MSD_CORE_ci_Patient';
import MERCK_HCP from '@salesforce/label/c.MSD_CORE_ci_HCP';

export default class MSD_CORE_welcomemedicalpopup extends LightningElement {
    label = {
        AEConsentBodyText1,
        AEConsentWelcome,
        ConsentTitle,
        AEWELCOMEBODY,
        MERCK_HCP,
        MERCK_PATIENT,
        MERCK_VENDOR,
        NON_US,
        MERCK_EMPLOYEE
      }
      merckPrivacyUrl = MERCK_PRIVACY_URL;
     @track openModal = true;
    
      handleKeystroke(event) {
        var eleId = event.currentTarget.dataset.id;
        var currentElement = this.template.querySelector(`[data-id="${eleId}"]`);
        var firstElement = this.template.querySelector('[data-id="first"]');
        var secondElement = this.template.querySelector('[data-id="second"]');
        var thirdElement = this.template.querySelector('[data-id="third"]');
        var fourthElement = this.template.querySelector('[data-id="fourth"]');
        var fifthElement = this.template.querySelector('[data-id="fifth"]');
      
        let isTabPressed = event.key === 'Tab' || event.keyCode === 9;
        if (!isTabPressed) return;
      
        if (event.shiftKey) {
          if (currentElement === firstElement) {
          fifthElement.focus();
          event.preventDefault();
          } else if (currentElement === secondElement) {
          firstElement.focus();
          event.preventDefault();
          } else if (currentElement === thirdElement) {
          secondElement.focus();
          event.preventDefault();
          } else if (currentElement === fourthElement) {
          thirdElement.focus();
          event.preventDefault();
          } else if (currentElement === fifthElement) {
          fourthElement.focus();
          event.preventDefault();
          }
        } else {
          if (currentElement === firstElement) {
          secondElement.focus();
          event.preventDefault();
          } else if (currentElement === secondElement) {
          thirdElement.focus();
          event.preventDefault();
          } else if (currentElement === thirdElement) {
          fourthElement.focus();
          event.preventDefault();
          } else if (currentElement === fourthElement) {
          fifthElement.focus();
          event.preventDefault();
          } else if (currentElement === fifthElement) {
          firstElement.focus();
          event.preventDefault();
          }
        }
      }
      closepopup(event) {
        this.openModal = false;
        this.buttonType = event.currentTarget.dataset.value;
        console.log('buttonType', this.buttonType);
        const selectedEvent = new CustomEvent('buttonchoice', {
            detail: { buttonType: this.buttonType }
        });
        this.dispatchEvent(selectedEvent);
    }
    
    }