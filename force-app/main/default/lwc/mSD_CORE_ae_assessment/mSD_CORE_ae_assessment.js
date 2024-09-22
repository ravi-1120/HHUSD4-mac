import ASSESSMENT_QUALITY_COMPLAINT from '@salesforce/label/c.MSD_CORE_ae_assessment1';
import ASSESSMENT_LEGAL_ISSUE from '@salesforce/label/c.MSD_CORE_ae_assessment2';
import ASSESSMENT_PRODUCT_QUESTION from '@salesforce/label/c.MSD_CORE_ae_assessment3';
import ASSESSMENT_QUESTION from '@salesforce/label/c.MSD_Core_ae_assessment_question';
import { LightningElement } from 'lwc';
// import ASSESSMENT_DUPLICATE_AE from '@salesforce/label/c.MSD_CORE_ae_assessment4';
import AssesmentReportIndividuals from '@salesforce/label/c.MSD_CORE_ae_Assessment_Report_Individuals';
import RADIOGROUP_NO from '@salesforce/label/c.MSD_CORE_ae_radio_NO';
import RADIOGROUP_YES from '@salesforce/label/c.MSD_CORE_ae_radio_Yes';


export default class MSD_CORE_ae_assessment extends LightningElement {
        
    label = {
        ASSESSMENT_QUESTION,
        ASSESSMENT_QUALITY_COMPLAINT,
        ASSESSMENT_LEGAL_ISSUE,
        ASSESSMENT_PRODUCT_QUESTION,
        // ASSESSMENT_DUPLICATE_AE,
        RADIOGROUP_NO,
        RADIOGROUP_YES,
        AssesmentReportIndividuals
    }

    showWarning = false;
    showMainContent = true;

    handleShowMainContent() {
        this.sendCustomEvent('New');
    }
    
    sendCustomEvent(value){
        this.showWarning = false;
        this.showMainContent = true;
        const Assessment = new CustomEvent('change', { 
            detail: value
        });
        this.dispatchEvent(Assessment);
    }

    handleradioInput(event) {
        console.log('MSD_CORE_ae_assessment - handleradioInput:', event.target.dataset.val);
        var field = event.target.dataset.val;
            if (field === 'No') {
                this.sendCustomEvent('Next');
            } else {
                this.showWarning = true;
                this.showMainContent = false;
            };

    }

}