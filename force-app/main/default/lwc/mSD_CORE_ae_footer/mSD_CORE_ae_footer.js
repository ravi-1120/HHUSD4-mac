import { LightningElement, track} from 'lwc';
import PRIVACYPOLICY from '@salesforce/label/c.MSD_CORE_ae_Privacy_Policy';
import TERMSOFUSE from '@salesforce/label/c.MSD_CORE_ae_Terms_of_Use';
import FORWARDLOOKINGSTATEMENT from '@salesforce/label/c.MSD_CORE_ae_Forward_Looking_Statement';
import ACCESSIBILITY from '@salesforce/label/c.MSD_CORE_ae_Accessibility';
import REPORTANISSUE from '@salesforce/label/c.MSD_CORE_ae_Report_an_Issue';
import FOOTERMESSAGE from '@salesforce/label/c.MSD_CORE_ae_Footer_Message';
import PRIVACYPOLICYURL from '@salesforce/label/c.MSD_CORE_ae_Privacy_Policy_URL';
import TERMSOFUSEURL from '@salesforce/label/c.MSD_CORE_ae_Terms_of_Use_URL';
import FORWARDLOOKINGSTATEMENTURL from '@salesforce/label/c.MSD_CORE_ae_Forward_Looking_Statement_URL';
import ACCESSIBILITYURL from '@salesforce/label/c.MSD_CORE_ae_Accessibility_For_All_URL';
import REPORTANISSUEURL from '@salesforce/label/c.MSD_CORE_ae_Report_An_Issue_URL';


export default class MSD_CORE_ae_footer extends LightningElement {

    label = {
        PRIVACYPOLICY,
        TERMSOFUSE,
        FORWARDLOOKINGSTATEMENT,
        ACCESSIBILITY,
        REPORTANISSUE,
        FOOTERMESSAGE,
        PRIVACYPOLICYURL,
        TERMSOFUSEURL,
        FORWARDLOOKINGSTATEMENTURL,
        ACCESSIBILITYURL,
        REPORTANISSUEURL
    }
    showModal = false;
    @track yyyy;

    connectedCallback() {
        var today = new Date();
        this.yyyy = today.getFullYear();
        console.log(this.yyyy);
    }

    redirectPrivacy() {
        window.open(this.label.PRIVACYPOLICYURL);
    }

    redirectTermsofUse() {
        window.open(this.label.TERMSOFUSEURL);
    }

    redirectForwardLookingStatement(){
        window.open(this.label.FORWARDLOOKINGSTATEMENTURL);
    }

    redirectAccessibility(){
        window.open(this.label.ACCESSIBILITYURL);
    }
    handleReport() {
        this.showModal = true;
    }
    handleClose() {
        this.showModal = false;
    }
    handleReportSuccess(event) {
        this.showModal = false;
        this.showNotification('success', event.detail.message);
    }
    
    showNotification(type, message) {
        this.template.querySelector('c-custom-toast').showToast(type, message);
    }
    
    // redirectReportAnIssue(){
    //     window.open(this.label.REPORTANISSUEURL);
    // }
}