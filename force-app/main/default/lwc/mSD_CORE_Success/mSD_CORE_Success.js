import { LightningElement,api,wire,track } from 'lwc';
import successicon from '@salesforce/resourceUrl/successicon';
import MSD_CORE_MedicalSettings_Url from '@salesforce/label/c.MSD_CORE_MedicalSettings_Url';
import { NavigationMixin } from 'lightning/navigation';
export default class MSD_CORE_Success extends NavigationMixin(LightningElement) {
    @api mobilescreen = false;
    pageName = 'Success';
    successicon = successicon;
    MSD_CORE_MedicalSettings_Url

handleNavigate(){
    console.log(MSD_CORE_MedicalSettings_Url);
    var prevurl = MSD_CORE_MedicalSettings_Url;
    console.log('prevurl');
    var orgurl = prevurl.replace("settings","logout-confirmation-page/mfr-contactyouraccountmanager");
  console.log('orgurl');
    window.open(orgurl, "_self");
   this.fireDataLayerEvent("link", '', "contact merck", 'registration_flow', 'Register', '/SelfRegister');
}


//google analytics
 fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'account management',
                page_purpose: 'registration',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: linkedtext,
                link_url: linkedurl,
                content_count: '',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                sfmc_id: '',
                sfmc_audience: '',
                page_url: location.href,
                page_title: 'Self Registration',

            },
            bubbles: true,
            composed: true
        }));
    }


}