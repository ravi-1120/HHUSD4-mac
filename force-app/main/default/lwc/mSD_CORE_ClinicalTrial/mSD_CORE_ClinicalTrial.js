/**
  * Auther:              Ravi Modi (Focal CXM)
  * Component Name:      mSD_CORE_ClinicalTrial
  * Description:         Used for Display Clinical trial in Study Detail Page
  * Used in:             MHEE Portal Site Study Detail Community Page (mSD_CORE_StudyDetail)
  * Created Date:        14th March 2023
  * Lastmodified Date:   16th March 2023
  */ 

import { LightningElement, api, track,wire } from 'lwc';

// Static Resource
import navigate from '@salesforce/resourceUrl/MSD_CORE_Navigation';
import USER_ID from '@salesforce/user/Id';   //getting user id.
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
export default class MSD_CORE_ClinicalTrial extends LightningElement {

    navigateicon = navigate;
    @track contactrole = '';    // for storing contact role
    @api clinicaltrialdata;                     //Storing ClinicalTrial Data
    @api clinicalcontname;            // storing content name for GA 

    @wire(getContactRole, { userId:USER_ID })
    wiredgetContactRole(value) {
        console.log({value});
        const { data, error } = value;
        if(data) {
            console.log({data});
            this.contactrole = data;
            console.log('raviteja>>>>>',data);
        }
        if(error) {
            console.log({error});
        }
    }

    linkclick(event){
    let linkname = event.currentTarget.dataset.linkname;
    let contname = this.clinicalcontname
    this.fireDataLayerEvent('link', '', linkname, '','StudyDetail__c', '/studydetail', contname);    //RT GA 1122
    }

    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, contentvalue) {
      console.log('event triggered');
      this.dispatchEvent(new CustomEvent('datalayereventmodule', {

          detail: {
              data_design_category: category,
              data_design_action: action,
              data_design_label: label,
              data_design_module: module,
              page_type: 'resources',
              page_purpose: 'product detail',
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
              content_name: contentvalue,
              page_localproductname: '',
              sfmc_id: USER_ID,
              sfmc_audience: this.contactrole,
              page_url: location.href,
              page_title: 'Study Details',

          },
          bubbles: true,
          composed: true
      }));
  }
}