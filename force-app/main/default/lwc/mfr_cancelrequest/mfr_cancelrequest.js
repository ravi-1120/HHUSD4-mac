import { LightningElement, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import right_arrow from '@salesforce/resourceUrl/rightarrow2';
//import close_icon from '@salesforce/resourceUrl/cancelicon';
import USER_ID from "@salesforce/user/Id";

import crossmark from '@salesforce/resourceUrl/cross';
import cssfile from '@salesforce/resourceUrl/mfrcancelreq';
import updatestatus from '@salesforce/apex/MSD_CORE_RequestController.updatestatus';
import getmeetingname from '@salesforce/apex/MSD_CORE_RequestController.getmeetingname';

export default class Mfr_cancelrequest extends LightningElement {

    @api openpopup = false;
    @api resourceid;
    meetingname;
    
    @track iscomingsoon;
    @track resourcename;
    @track productname;
    @track isWinrevairProduct = false;

    arrowicon = right_arrow;
    //closeicon = close_icon;
    cross = crossmark;
    @track contactrole = '';

    @track noTitle = false;

    // For CSS Load
    renderedCallback() {

        Promise.all([
            loadStyle(this, cssfile)
        ]).then(() => {
            console.log('Files loaded');
        })
        .catch(error => {
            console.log(error.body.message);
        });
    }

    connectedCallback(){

        console.log('connected callback');
        this.contactrole = sessionStorage.getItem('SFMC_Audience');
        this.getname();
    }

    viewRequest(event){
        this.fireDataLayerEvent('button','/product/productdetail','view request','modal')
        location.reload();
    }

    getname(){
        getmeetingname({reqId: this.resourceid})
            .then(result => {
                console.log('result:',{result});
                this.meetingname = result.Name;
                this.resourcename = result.MSD_CORE_Resource__r.MSD_CORE_Resource_Title__c;
                this.productname = result.MSD_CORE_Product_Payor__r.Name;
                this.iscomingsoon = result.MSD_CORE_Resource__r.MSD_CORE_Content_Type__c != 'Coming Soon'? false : true;
                this.isWinrevairProduct = result.MSD_CORE_Product_Payor__r.Name == 'WINREVAIR™' ? true : false;
                if(result.MSD_CORE_Product_Payor__r.MSD_CORE_Remove_Title_Description__c){
                    this.noTitle = true;
                }
                
            })
            .catch(error => {
                console.log({error});
            })
    }

    // For Opne Popup Model
    @api
    openModel(){
        this.openpopup = true;
    }

    // For Closing Popup Model
    closeModel(){
        this.fireDataLayerEvent('button','/library/viewschedule','back to screen_close','modal')
        this.openpopup = false;
    }

    closeModelcross() {
        this.fireDataLayerEvent('button','/library/viewschedule','back to screen_X','modal')
        this.openpopup = false;
    }

    // For Cancel Request Button
    cancelreq(){
        console.log('this.resourceid::->',this.resourceid);
        updatestatus({reqId: this.resourceid})
            .then(result => {
                if (result!=null) {
                    this.fireDataLayerEvent('button','/library/viewschedule','cancel request','modal');
                    this.openpopup = false;
                    window.location.reload(); //For Reload Page
                }else {
                    console.log('Some Error Occured!!!');
                }
            })
            .catch (error => {
                console.log({error});
            })
    }

   fireDataLayerEvent(category, action,label,module) {
    console.log('event triggered');
    this.dispatchEvent(new CustomEvent('datalayereventbrand', {
        detail: {
            data_design_category: category,
            data_design_action: action,
            data_design_label: label,
            data_design_module:module,
            page_type: 'product',
            page_purpose:'appointment',
            page_audience: 'payor',
            page_marketname: 'united_states',
            page_region: 'us',
            page_contentclassification: 'non-commercial',
            link_text:'scheduled',
            link_url:'/scheduled',
            content_count:'',
            content_saved:'',
            content_appointments:'',
            content_requests:'',
            // content_name:this.meetingname,
            content_name:this.resourcename,
            // page_localproductname:this.resourcename,
            page_localproductname:this.productname,
            sfmc_id:USER_ID,
            sfmc_audience: this.contactrole,
            page_url: location.href,
            page_title: 'scheduled',
        },
        bubbles: true,
        composed: true
    }));
}

}