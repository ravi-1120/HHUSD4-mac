import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import getproductlist from '@salesforce/apex/MSD_CORE_ProductList.getproductlist';
//import getContactDetails from '@salesforce/apex/GetContactDetailsOnCommunityPage.getContactDetails';
import USER_ID from "@salesforce/user/Id";
import banner_img from '@salesforce/resourceUrl/banner';
import prescribinginfo from '@salesforce/resourceUrl/prescribinginfo';
import mediguide from '@salesforce/label/c.MSD_CORE_MedicationGuide';        //Label for Medical Guide
import patientinfo from '@salesforce/label/c.MSD_CORE_PatientInformation';   //Label for Patient Information
import preinfo from '@salesforce/label/c.MSD_CORE_PrescribingInformation';   //Label for Prescribing Information
import prodlabel from '@salesforce/label/c.MSD_CORE_Product';                //Label for Prescribing Information
import prodsublabel from '@salesforce/label/c.MSD_CORE_Product_Subheader';   //Label for Prescribing Information

import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';

export default class Mfr_ProductsList extends NavigationMixin(LightningElement) {

    products; //Product Data
    error; // Error Message
    currentPageReference = null;
    urlStateParameters = null;
    prodId; //Selected Product Id
    roleId;
    presinfo = prescribinginfo;

    norecord = false;
    navigateproductlist;
    navigateproductlistname;
    label = {
        mediguide,
        patientinfo,
        preinfo,
        prodlabel,
        prodsublabel
    }

    @track contactrole = '';
    
    // Banner Background Image
    get backgroundStyle() {
        return `background-image:url(${banner_img})`;
    }

    renderedCallback(){
        //code
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
        }
    }
    //Added wire method
    @wire(getSiteNameAndAPIName, {pageName :'productdetail'})
    wiredgetSiteNameAndAPIName(value) {
        console.log('Wired Count');
        console.log(value);
        const { data, error } = value;
        if (data) {
            console.log('apiname'+data.siteAPIName)
            this.navigateproductlist = data.siteAPIName;
            this.navigateproductlistname = data.siteName;
            console.log('this.navigateproductlist>>>',this.navigateproductlist);
            console.log('this.navigateproductlistname>>',this.navigateproductlistname);
        } else if (error) {
            this.error = error;
            console.log('error in getSiteNameAndAPIName ' + JSON.stringify(this.error));
        }
    }

    // Connected Callback
    connectedCallback() {
        this.contactrole = sessionStorage.getItem('SFMC_Audience');
        this.getproductlistdata();
        this.fireOnLoadEvent();
    }

    // Get all Products list
    getproductlistdata() {
        getproductlist({userid : USER_ID})
            .then((result) => {
                console.log('getproductlist : ',{result});
                if(result != null){
                    /* 10 Jul 2023 - E2ESE-1251 - MFR2023SepR4 */
                    this.products = result.map(row => ({
                        ...row,
                        showComingSoon : row.Catalogs__r ? false : true
                    }));

                    setTimeout(() => {
                        this.colourchange();
                    }, 1000);
                } else {
                    this.norecord = true;
                }

                console.log('this.products : ',this.products);
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }

    //Shadow color
    colourchange(){
        for(var key in this.products){
            var colorcode = this.products[key].MSD_CORE_Colourcode__c;
            console.log({colorcode});
            var card = this.template.querySelector('[data-fill="'+colorcode+'"]');
            card.setAttribute('style', '');
        }
    }
    
    // <!-- Modified by Sabari - MFRUS-67 -->
    addColourcode(event){
     const colorcode = event.target.getAttribute('data-fill');
     if(colorcode){
         const tgt = event.target.querySelector('.setcolorcode');
         tgt.style.backgroundColor = colorcode;
         tgt.style.display='block';
     }
    }

    removeColourcode(event){
      const tgt = event.target.querySelector('.setcolorcode');
      if(tgt){
      tgt.style.display='none';
      }
    }

    handlerOnclickProduct(event) {
        this.prodId = event.target.dataset.id;
        if (this.navigateproductlistname != undefined && this.navigateproductlist != undefined){
            this.fireDataLayerEvent("link",'', event.target.dataset.value,'',this.navigateproductlistname,this.navigateproductlist,event.target.dataset.value);
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                    // name: 'productdetail__c',
                    // url: '/s/product/productdetail'
                    name : this.navigateproductlistname,
                    url: this.navigateproductlist+'?recordId='+this.prodId
                }
                // ,
                // state: {
                //     recordId: this.prodId
                // }
            });
        }
    }

    clickupdate(event){
        const refvalue = event.detail;
        let datatransfer = new CustomEvent('productupdate',{detail:refvalue});
    }

    navigateToNewRecordPage(url) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    // Added New Method for the Events
    handlePreInfo(event) {
        this.fireDataLayerEvent("link",'',event.target.dataset.prodlabel,'',event.target.dataset.prodlabel,event.target.dataset.prodpath, event.target.dataset.value);
    }

    handleLinkClick(event) {
        if(event.currentTarget.dataset.prodname == 'pi.pdf' ) {
            this.fireDataLayerEvent("link", '', event.currentTarget.dataset.prodname, '', event.currentTarget.dataset.prodlabel, event.currentTarget.dataset.prodpath, '', event.currentTarget.dataset.value);// RT GA bug
        }else {
            this.fireDataLayerEvent("link", '', event.currentTarget.dataset.prodlabel, '', event.currentTarget.dataset.prodlabel, event.currentTarget.dataset.prodpath, '', event.currentTarget.dataset.value);// RT GA bug
        }
    }
    
    // Events
    fireDataLayerEvent(category, action, label, module,linkedtext, linkedurl,prdtName) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventbrand', {
            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: 'product',
                page_purpose:'product listing',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text:linkedtext,
                link_url:linkedurl,
                content_count:'',
                content_saved:'',
                content_appointments:'',
                content_requests:'',
                content_name:'',
                page_localproductname:prdtName,                
                sfmc_id:USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'product list',  
            },
            bubbles: true,
            composed: true
        }));
    }

    //Google Analytics Event
    fireOnLoadEvent() {
        console.log('EVENT TRIGGERED');
        this.dispatchEvent(new CustomEvent('fireOnLoadEvent', {
            detail: {                   
                    // page_type: 'product',
                    // page_purpose:'product listing',
                    // page_audience: 'payor',
                    // page_marketname: 'united_states',
                    // page_region: 'us',
                    // page_contentclassification: 'non-commercial',
                    // page_localproductname: '',
                    // content_count:'',
                    // sfmc_id: USER_ID,
                    // sfmc_audience:this.contactrole
                    data_design_category: '',
                    data_design_action: '',
                    data_design_label: '',
                    data_design_module:'',       
                    page_type: 'product',
                    page_purpose:'product listing',
                    page_audience: 'payor',
                    page_marketname: 'united_states',
                    page_region: 'us',
                    page_contentclassification: 'non-commercial',
                    link_text:'Product-list-page',
                    link_url:'/product-list-page',
                    content_saved:'',
                    content_appointments:'',
                    content_requests:'',
                    content_name:'',
                    page_localproductname: '',
                    content_count:'',
                    sfmc_id: USER_ID,
                    sfmc_audience:this.contactrole,
                    page_url: location.href,
                    page_title: 'product list',  
            },
            bubbles: true,
            composed: true
        }));
    }
}