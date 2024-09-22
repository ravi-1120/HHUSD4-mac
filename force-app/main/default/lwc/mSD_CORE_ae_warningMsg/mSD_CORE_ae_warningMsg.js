import { LightningElement,api } from 'lwc';
import WarningMsg from '@salesforce/label/c.MSD_CORE_ae_warningmsg1';
import Phone from '@salesforce/label/c.MSD_CORE_ae_merckPhone';
import WarningMsg2 from '@salesforce/label/c.MSD_CORE_ae_warningmsg2';
import Email from '@salesforce/label/c.MSD_CORE_ae_merckSupport_Email';
import Button from '@salesforce/label/c.MSD_ae_warningbtn';
import WarningMsg3 from '@salesforce/label/c.MSD_CORE_ae_warningmsg3';

export default class MSD_CORE_ae_warningMsg extends LightningElement {
    buttonClicked = false;
    @api isSubmitClicked;   
    handleButtonClick() {
        console.log('MSD_CORE_ae_warningMsg - handleButtonClick');
        this.buttonClicked = true;
        this.dispatchEvent(new CustomEvent('showmaincontent'));
    }
    label = {
        WarningMsg,
        Phone,
        WarningMsg2,
        Email,
        Button,
        WarningMsg3
      }
    get phoneHref() {
        return `tel:${this.label.Phone}`;
    }

    get emailHref() {
        return `mailto:${this.label.Email}`;
    }
    
    handleKeystroke(event) {
        console.log('MSD_CORE_ae_warningMsg - handleKeystroke:', event.key);
      let isTabPressed = event.key === 'Tab' || event.keyCode === 9;
      if (isTabPressed) {
          event.preventDefault();
          this.template.querySelector('[data-id="your-button-id"]').focus();
      }
  }
  
}