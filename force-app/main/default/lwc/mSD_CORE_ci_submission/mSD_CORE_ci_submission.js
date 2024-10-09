import { LightningElement,track,api } from 'lwc';
import Button from '@salesforce/label/c.MSD_ae_warningbtn';
import ADVERSEEVENTCONFIRMATION from '@salesforce/label/c.MSD_CORE_ae_Adverse_Event_Confirmation';
import SERVICECLOUDCASENUMBER from '@salesforce/label/c.MSD_CORE_ae_ServiceCloud_Case_Number';
import SUBMISSIONDATETIME from '@salesforce/label/c.MSD_CORE_ae_Submission_Date_Time';

export default class MSD_CORE_ci_submission extends LightningElement {
    label = {
        Button,
        ADVERSEEVENTCONFIRMATION,
        SERVICECLOUDCASENUMBER,
        SUBMISSIONDATETIME
      } 
      @track buttonClicked = false;
      @track isLoading = true;
      @api caseDetails;
      get caseNumber() {
        return this.caseDetails.caseNumber || '';
    }
    connectedCallback() {
        console.log('Case Details received from review and Confirmation:', JSON.stringify(this.caseDetails));
        if (this.caseDetails && this.caseDetails.caseNumber) {
            this.isLoading = false;
            console.log('Case Number is available:', this.caseDetails.caseNumber);
        } else {
            console.warn('Case Number is not available yet.');
        }
    }
  
    handleButtonClick() {
        console.log('Submit New Competitive Information Report');
        const resetEvent = new CustomEvent('resetreport', {
            detail: {
                message: 'Reset requested from submission page.'
            }
        });
        this.dispatchEvent(resetEvent);
        this.isLoading = true;
        this.showNotification('info', 'Starting a new Competitive Information Report.');
    }
  
      get currentDateTime() {
          let now = new Date();
          let month = String(now.getMonth() + 1).padStart(2, '0');
          let day = String(now.getDate()).padStart(2, '0');
          let year = now.getFullYear();
          let hours = now.getHours();
          let minutes = String(now.getMinutes()).padStart(2, '0');
          let ampm = hours >= 12 ? 'PM' : 'AM';
          hours = hours % 12;
          hours = hours ? hours : 12;
          hours = String(hours).padStart(2, '0');
          return `${month}/${day}/${year}, ${hours}:${minutes} ${ampm}`;
      }
  
      showNotification(type, message) {
          this.template.querySelector('c-custom-toast').showToast(type, message);
      }
  }