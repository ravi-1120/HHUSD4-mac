import { LightningElement, track, api, wire } from 'lwc';
import AMOHCPSchdulerController from '@salesforce/apex/AMOHCPSchdulerController.getHCPAttestaion';
import footers from '@salesforce/resourceUrl/HCPFooterImages';
import medicalInformation from '@salesforce/label/c.Medical_Information';
import AMOFooter from '@salesforce/label/c.AMO_Footer';
import AMOFooterMessage from '@salesforce/label/c.AMO_Footer_Message';
import AMOFooterJobCode from '@salesforce/label/c.AMO_Footer_Job_Code';
import AMOContinue from '@salesforce/label/c.AMO_Continue';
import PrivacyPolicyLink from '@salesforce/label/c.Privacy_Policy_Link';
import TermsOfUseLink from '@salesforce/label/c.Terms_of_Use_Link';
import AccessibilityLink from '@salesforce/label/c.Accessibility_Link';
import APECPrivacyLink from '@salesforce/label/c.APEC_Privacy_Link';
import TrusteePrivacyLink from '@salesforce/label/c.Trustee_Privacy_Link';
import CookieLink from '@salesforce/label/c.Cookie_Settings';
import PrivacyPolicy from '@salesforce/label/c.Privacy_Policy_Label';
import TermToUse from '@salesforce/label/c.Terms_of_Use_Label';
import MedicalInformationLabel from '@salesforce/label/c.Medical_Information_Label';
import CookiePreferences from '@salesforce/label/c.Cookie_Preferences';
import AMOMedicalInformationContinue from '@salesforce/label/c.AMO_Medical_Information_Continue';
const GA_CLICK = 'click';
const GA_MI_EVT = 'Medical Information';
const GA_MI_CONTINUE = 'Merck Medical Portal redirect continue';


export default class HcpFooter extends LightningElement {
    label = {
        medicalInformation,
        AMOFooter,
        AMOFooterMessage,
        AMOFooterJobCode,
        AMOContinue,
        PrivacyPolicyLink,
        TermsOfUseLink,
        AccessibilityLink,
        APECPrivacyLink,
        TrusteePrivacyLink,
        CookieLink,
        PrivacyPolicy,
        TermToUse,
        MedicalInformationLabel,
        CookiePreferences,
        AMOMedicalInformationContinue
    };

    @track isShowModal = false;
    @api modalcls = "slds-modal slds-fade-in-open slds-modal_large";
    @track medicalPortal;
    @track showResponse = false;

    sealOne = footers + '/HCPFooterImages/seal.svg';
    sealTwo = footers + '/HCPFooterImages/seal1.svg';
    accessibilityicon = footers + '/HCPFooterImages/accessibility.png';

    showMedical() {
        AMOHCPSchdulerController({ isHCP: true })
            .then((result) => {
                this.medicalPortal = result;
                console.log('medicalPortal' + JSON.stringify(this.medicalPortal));
            })
            .catch((error) => {
                this.error = error;
                console.log('error' + JSON.stringify(error));
            })
        this.isShowModal = true;
    this.handleDataLayerEvent(GA_MI_EVT, GA_CLICK);
    }

    redirectMedical() {
        window.open(this.medicalPortal,'dialers').focus();
        this.isShowModal = false;
        this.handleDataLayerEvent(GA_MI_CONTINUE, GA_CLICK);
    }

    hideModalBox() {
        this.isShowModal = false;
    }

    redirectPrivacy() {
        window.open(this.label.PrivacyPolicyLink);
    }

    redirectTermsofUse() {
        window.open(this.label.TermsOfUseLink);
    }

    redirectCookie() {
        window.location('javascript:Optanon.ToggleInfoDisplay()');
    }

    handleAccessibility() {
        window.open(this.label.AccessibilityLink);
    }

    redirectAPECPrivacy() {
        window.open(this.label.APECPrivacyLink);
    }

    redirectVerifiedPrivacy() {
        window.open(this.label.TrusteePrivacyLink);
    }

    handleDataLayerEvent(category,action) {
        let evt = { event_category: category, event_action: action, event_label: "askmerck.com" };
        const medicalInfoGAEvt = new CustomEvent("datalayerevent", {
            detail: evt,
            bubbles: true,
            composed: true,
        });
        this.dispatchEvent(medicalInfoGAEvt);
    }
    
}