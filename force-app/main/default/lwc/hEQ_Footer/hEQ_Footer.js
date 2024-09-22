import { LightningElement, track } from 'lwc';

// Custom Label
import HEQ_Consumer_health_data_privacy_policy from '@salesforce/label/c.HEQ_Consumer_health_data_privacy_policy';
import HEQ_Cookie_preferences from '@salesforce/label/c.HEQ_Cookie_preferences';
import HEQ_Privacy_policy from '@salesforce/label/c.HEQ_Privacy_policy';
import HEQ_Site_map from '@salesforce/label/c.HEQ_Site_map';
import HEQ_Terms_of_use from '@salesforce/label/c.HEQ_Terms_of_use';
import HEQ_Your_Privacy_Choices from '@salesforce/label/c.HEQ_Your_Privacy_Choices';
import HEQ_Accessibility from '@salesforce/label/c.HEQ_Accessibility';
import HEQ_Copyright_Text1 from '@salesforce/label/c.HEQ_Copyright_Text1';
import HEQ_Copyright_Text2 from '@salesforce/label/c.HEQ_Copyright_Text2';
import HEQ_MerckLogoLink from '@salesforce/label/c.HEQ_MerckLogo';
import HEQ_AccessibilityLogoLink from '@salesforce/label/c.HEQ_AccessibilityLogo';
import HEQ_MercklogoTarget from '@salesforce/label/c.HEQ_MercklogoTarget';
import HEQ_AccessibilityLogoTarget from '@salesforce/label/c.HEQ_AccessibilityLogoTarget';

// Static Resource
import HEQ_MerckLogo from '@salesforce/resourceUrl/HEQ_MerckLogo';
import HEQ_Accessibilitylogo from '@salesforce/resourceUrl/HEQ_Accessibility';
import HEQ_Privacy_Choices from '@salesforce/resourceUrl/HEQ_Privacy_Choices';

// Apex Class
import getPortalSetting from '@salesforce/apex/HEQ_FooterController.getPortalSetting';

export default class HEQ_Footer extends LightningElement {

    @track footermetadata;
    label = {
        HEQ_Consumer_health_data_privacy_policy,
        HEQ_Cookie_preferences,
        HEQ_Privacy_policy,
        HEQ_Site_map,
        HEQ_Terms_of_use,
        HEQ_Your_Privacy_Choices,
        HEQ_Accessibility,
        HEQ_Copyright_Text1,
        HEQ_Copyright_Text2,
        HEQ_MerckLogoLink,
        HEQ_AccessibilityLogoLink,
        HEQ_MercklogoTarget,
        HEQ_AccessibilityLogoTarget
    }
    HEQ_Accessibilitylogo = HEQ_Accessibilitylogo;
    HEQ_MerckLogo = HEQ_MerckLogo;
    HEQ_Privacy_Choices = HEQ_Privacy_Choices;

    // ConnectedCallback
    connectedCallback(){
        this.getPortalSetting();
    }

    // Get Footer Metadata
    getPortalSetting(){
        getPortalSetting()
        .then(result => {
            console.log('result>>',result);
            this.footermetadata = result;
            console.log('this.footermetadata>>',this.footermetadata);
        })
        .catch(error => {
            console.log('error>>'+JSON.stringify(error));
        })
    }
}