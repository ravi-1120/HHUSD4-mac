import { LightningElement, api, wire, track } from 'lwc';
import logo1 from '@salesforce/resourceUrl/box';
import USER_ID from "@salesforce/user/Id";
import newlogo from '@salesforce/resourceUrl/merck2';
import newlogo1 from '@salesforce/resourceUrl/menu2';
import getMerckSites from '@salesforce/apex/MSD_CORE_MerckSites.getMerckSites';
import newlogo3 from '@salesforce/resourceUrl/banner';
import jobcode from '@salesforce/label/c.nonbrandjobcode';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole'; // getting contact role from backend
import crossmark from '@salesforce/resourceUrl/cross';
import HeaderArrow from '@salesforce/resourceUrl/HeaderArrow';
import logo from '@salesforce/resourceUrl/vmi';
export default class OtherMerckSites extends LightningElement {
    logo1 = newlogo;
    logo2 = newlogo1;
    logo5 = newlogo3; 
    vmi = logo;
    box = logo1; error;
    @api Description;
    @api Heading2;
    @api Heading1;
    @api site;
    @track contactrole = '';
    user = USER_ID;
    OtherMercksites

    @track naigateToExternalSite = false;
    @track MerckSite;
    cross = crossmark;
    HeaderArrow=HeaderArrow;

    connectedCallback() {
        console.log('COnnected Callback');
        this.fireOnLoadEvent();
    }

    @wire(getMerckSites)
    wiredgetMerckSites({ error, data }) {
        if (data) {
            this.OtherMercksites = data;
            console.log('OtherMercksites1--->' + JSON.stringify(this.OtherMercksites));
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
    get backgroundStyle() {
        return `background-image:url(${newlogo3})`;
    }
    visitsite(event){
     var headername = event.currentTarget.dataset.headname;
     console.log('headername>>>'+headername);
     if(headername=='Merck Vaccines'){
        this.fireDataLayerEvent("button", '', "visit merckvaccines", '', 'otherMerckSites__c', 'https://www.merckvaccines.com/'); //RT GA 1122
     }else{
        this.fireDataLayerEvent("button", '', "visit merckconnect", '', 'otherMerckSites__c', 'https://www.merckconnect.com/'); // RT GA 1122
     }
    // this.fireDataLayerEvent("button", '', "visit merckconnect", '', 'othermercksites__c', 'https://www.merckvaccines.com/', this.catalogName, this.productName);
    }
//MSD_CORE_MerckSites
    handleVisitSite(event) {
        var siteId = event.currentTarget.dataset.id;
        console.log(event.currentTarget.dataset.id);
        console.log(event.target.dataset.id);
        if (this.OtherMercksites.length > 0) {
            this.OtherMercksites.forEach(ele => {
                console.log(JSON.stringify(ele));
                if (ele.Id == siteId) {
                    console.log('site-->' + ele.MSD_CORE_Site__c);
                    window.open(ele.MSD_CORE_Site__c,'__blank');
                }
            });
        }
    }
  label = {jobcode};
    navigatePopup(event){
				this.naigateToExternalSite = true;
        var siteData = event.currentTarget.dataset.id;
        console.log(siteData);
        this.MerckSite = siteData;
        this.naigateToExternalSite = true;
    }

    closeResponse(event) {
        var lablelname = event.currentTarget.dataset.label;
        if (lablelname == 'back to screen_X') {
             this.naigateToExternalSite = false;
        }else {
             this.naigateToExternalSite = false;
        }
    } 


    // google analytics
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl) {

        this.dispatchEvent(new CustomEvent('datalayereventbrandcontent', {
            detail: {
                // event_category: category,
                // event_action: action,
                // event_label: label,
                // page_type: 'registration',
                // page_purpose: 'registration',
                // page_audience: 'payor',
                // page_marketname: 'united_states',
                // page_region: 'us',
                // page_contentclassification: 'non-commercial',
                // page_localproductname: prdtName,
                // content_name: resName
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
                page_title: 'schedule',
            },
            bubbles: true,
            composed: true
        }));
    }
    //RT GA 1122
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
                link_text: 'otherMerckSites__c',
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