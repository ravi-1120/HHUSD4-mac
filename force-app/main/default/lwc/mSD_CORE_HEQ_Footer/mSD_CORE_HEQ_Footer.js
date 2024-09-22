import { LightningElement, track } from 'lwc';

// Custom Label
import HEQ_Copyright_Text1 from '@salesforce/label/c.MSD_CORE_HEQ_Copyright_Text1';
import HEQ_Copyright_Text2 from '@salesforce/label/c.MSD_CORE_HEQ_Copyright_Text2';
import HEQ_Copyright_Text3 from '@salesforce/label/c.MSD_CORE_HEQ_Copyright_Text3';
import Address1 from '@salesforce/label/c.MSD_CORE_HEQ_Address1';
import Address2 from '@salesforce/label/c.MSD_CORE_HEQ_Address2';
import ContactUs from '@salesforce/label/c.MSD_CORE_HEQ_Contact_us';
import ViewOptions from '@salesforce/label/c.MSD_CORE_HEQ_View_Options';
import HEQ_MerckLogoLink from '@salesforce/label/c.MSD_CORE_HEQ_MerckLogo';
import HEQ_AccessibilityLogoLink from '@salesforce/label/c.MSD_CORE_HEQ_AccessibilityLogo';
import HEQ_MercklogoTarget from '@salesforce/label/c.MSD_CORE_HEQ_MercklogoTarget';
import HEQ_AccessibilityLogoTarget from '@salesforce/label/c.MSD_CORE_HEQ_AccessibilityLogoTarget';
import AdditionalSites from '@salesforce/label/c.MSD_CORE_HEQ_Merck_sites';

// Static Resource
import HEQ_MerckLogo from '@salesforce/resourceUrl/MSD_CORE_HEQ_MerckLogo';
import HEQ_Logo from '@salesforce/resourceUrl/MSD_CORE_HEQ_Footer_Logo';
import HEQ_Accessibilitylogo from '@salesforce/resourceUrl/MSD_CORE_HEQ_Accessibility';
import HEQ_Privacy_Choices from '@salesforce/resourceUrl/MSD_CORE_HEQ_Privacy_Choices';

// Apex Class
import getFooterConfig from '@salesforce/apex/MSD_CORE_HEQ_FooterController.getFooterConfig';

export default class mSD_CORE_HEQ_Footer extends LightningElement {

    @track additionalMerckSites = [];
    @track footerLinks = [];
    
    label = {
        HEQ_Copyright_Text1,
        HEQ_Copyright_Text2,
        HEQ_Copyright_Text3,
        Address1,
        Address2,
        ContactUs,
        ViewOptions,
        HEQ_MerckLogoLink,
        AdditionalSites,
        HEQ_AccessibilityLogoLink,
        HEQ_MercklogoTarget,
        HEQ_AccessibilityLogoTarget
    };
    HEQ_Accessibilitylogo = HEQ_Accessibilitylogo;
    HEQ_MerckLogo = HEQ_MerckLogo;
    HEQ_Logo = HEQ_Logo;
    HEQ_Privacy_Choices = HEQ_Privacy_Choices;

    connectedCallback() {
        this.loadFooterConfig();
    }

    loadFooterConfig() {
        getFooterConfig()
            .then(result => {
                if (result) {
                    this.footerLinks = result.footerLinks;
                    this.additionalMerckSites = result.additionalMerckSites;
                }
            })
            .catch(error => {
                console.error('Error retrieving footer metadata:', error);
            });
    }

}