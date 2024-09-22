import HEALTHCARE from '@salesforce/label/c.MSD_CORE_ae_HealthcareButton';
import ConsentTitle from '@salesforce/label/c.MSD_CORE_ae_consentTitle';
import AEWELCOMEBODY from '@salesforce/label/c.MSD_CORE_ae_welcomeBody';
import AEConsentBodyText1 from '@salesforce/label/c.MSD_CORE_ae_welcomeBody1';
import IamMerckEmployee from '@salesforce/label/c.MSD_CORE_ae_welcomeButton1';
import IamMerckPSP from '@salesforce/label/c.MSD_CORE_ae_welcomeButton2';
import AEConsentWelcome from '@salesforce/label/c.MSD_CORE_ae_welcomeHeader';
import MERCK_PRIVACY_URL from '@salesforce/label/c.MSD_ae_privacyUrl';
import { LightningElement } from 'lwc';

export default class MSD_CORE_ae_welcomePopup extends LightningElement {

  label = {
    IamMerckEmployee,
    IamMerckPSP,
    AEConsentBodyText1,
    AEConsentWelcome,
    ConsentTitle,
    AEWELCOMEBODY,
    HEALTHCARE
  }
  merckPrivacyUrl = MERCK_PRIVACY_URL;

  handleKeystroke(event) {
    var eleId = event.currentTarget.dataset.id;
    var currentElement = this.template.querySelector(`[data-id="${eleId}"]`);
    var firstElement = this.template.querySelector('[data-id="hcp-btn1"]');
    var lastElement = this.template.querySelector('[data-id="hcp-btn2"]');
    var thirdElement = this.template.querySelector('[data-id="hcp-btn3"]');

    let isTabPressed = event.key === 'Tab' || event.keyCode === 9;
    if (!isTabPressed) return;

    if (event.shiftKey) {
      if (currentElement === firstElement) {
        lastElement.focus();
        event.preventDefault();
      }
    } else {
      if (currentElement === lastElement) {
        firstElement.focus();
        event.preventDefault();
      }else{
        if(currentElement === thirdElement) {
        thirdElement.focus();
        event.preventDefault();  
      }
    }
    }
  }
  closepopup(event) {
    this.buttonType = event.currentTarget.dataset.value;
    const selectedEvent = new CustomEvent('buttonchoice', {
    detail: { buttonType: this.buttonType },
    });
    this.dispatchEvent(selectedEvent);
  }

}