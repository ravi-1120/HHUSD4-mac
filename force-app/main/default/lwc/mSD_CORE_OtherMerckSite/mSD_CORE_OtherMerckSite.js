import { LightningElement, api, wire , track} from 'lwc';

import banner from '@salesforce/resourceUrl/PurpleBanner';
import logo1 from '@salesforce/resourceUrl/box';
import USER_ID from "@salesforce/user/Id";
import getMerckSites from '@salesforce/apex/MSD_CORE_Dashboard.getMerckSites';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
export default class MSD_CORE_OtherMerckSite extends LightningElement {

    box = logo1;
    bannerimg = banner;
    error;
    OtherMercksites;
    @track contactrole = '';

    @wire(getMerckSites)
    wiredgetMerckSites({ error, data }) {
        console.log({ data });
        if (data) {
            this.OtherMercksites = data;
            console.log('this.OtherMercksites-->', this.OtherMercksites);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.OtherMercksites = undefined;
        }
    }
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

    //MSD_CORE_MerckSites
    handleVisitSite(event) {
        var siteId = event.currentTarget.dataset.id;
        console.log({ siteId });
        if (this.OtherMercksites.length > 0) {
            this.OtherMercksites.forEach(ele => {
                if (ele.Id == siteId) {
                    window.open(ele.MSD_CORE_Site__c, '__blank');
                }
            });
        }
    }

    connectedCallback() {
        this.fireOnLoadEvent()
        console.log('connected call back');
        setTimeout(() => { 
            console.log('Timeout');
            var top = this.template.querySelector('.bannercls');
            console.log('Top-->',top);
            top.scrollIntoView();
        }, 2000);
    }
    visitsite(event){
    var sitename = event.currentTarget.dataset.sitename;
    if(sitename =='Merck Vaccines'){
        this.fireDataLayerEvent("button", '', "visit merckvaccines", '', 'othermercksites__c', 'https://www.merckvaccines.com/'); //RT GA 1122
     }else{
        this.fireDataLayerEvent("button", '', "visit merckconnect", '', 'othermercksites__c', 'https://www.merckconnect.com/'); // RT GA 1122
     }
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
                page_type: 'other',
                page_purpose: 'reference',
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
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'Other Merck Sites',

            },
            bubbles: true,
            composed: true
        }));
    }
    fireOnLoadEvent() {
        console.log('EVENT TRIGGERED');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {
                data_design_category: '',
                data_design_action: '',
                data_design_label: '',
                data_design_module: '',
                page_type: 'other',
                page_purpose: 'reference',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'OtherMerckSites__c',
                link_url: '/othermercksites',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'Other Merck Sites',
            },
            bubbles: true,
            composed: true
        }));
    }

}