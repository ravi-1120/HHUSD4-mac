import { LightningElement, track } from 'lwc';
import REPORTISSUE from '@salesforce/label/c.MSD_CORE_ae_An_Issue';
import REPORTISSUESTATEMENT1 from '@salesforce/label/c.MSD_CORE_ae_Report_an_Issue_statement';
import REPORTISSUESTATEMENT2 from '@salesforce/label/c.MSD_CORE_ae_Report_an_Issue_statement1';
import CONTINUE from '@salesforce/label/c.MSD_CORE_ae_Continue';


export default class MSD_CORE_ae_reportModal extends LightningElement {  
    @track isChildModal = true;

    label = {
      REPORTISSUE,
      REPORTISSUESTATEMENT1,
      REPORTISSUESTATEMENT2,
      CONTINUE
    }

    handleKeystroke(event) {
        var eleId = event.currentTarget.dataset.id;
        var currentElement = this.template.querySelector(`[data-id="${eleId}"]`);
        var firstElement = this.template.querySelector('[data-id="hcp-btn1"]');
        var lastElement = this.template.querySelector('[data-id="hcp-btn2"]');
    
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
          }
        }
      }
    closepopup() {
        //this.modal = false;
        this.isChildModal = false
        this.dispatchEvent(new CustomEvent('cancel'));
        
    }
    toggleModal() {
        // this.modal = false;
        this.isChildModal = false;
        this.dispatchEvent(new CustomEvent('continue'));
    }

}