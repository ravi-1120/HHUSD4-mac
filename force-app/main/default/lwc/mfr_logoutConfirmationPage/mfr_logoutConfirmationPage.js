import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { createRecord } from 'lightning/uiRecordApi';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import Id from '@salesforce/user/Id';

import newlogo3 from '@salesforce/resourceUrl/banner';
import rarrow from '@salesforce/resourceUrl/rarrow';
import newlogo from '@salesforce/resourceUrl/merck2';
import newlogo1 from '@salesforce/resourceUrl/menu2';
import menu_rightsider from '@salesforce/resourceUrl/menu_rightsider';
import imgPersonalized from '@salesforce/resourceUrl/personalized'
import logo from '@salesforce/resourceUrl/vmi';
import Header from '@salesforce/label/c.MFR_Portal_Label';
import Header1 from '@salesforce/label/c.MFR_Portal_Label1';
import Header1_02 from '@salesforce/label/c.MFR_Portal_Label1_02';
import Header1_03 from '@salesforce/label/c.MFR_Portal_Label1_03';
import Header2 from '@salesforce/label/c.MFR_Portal_Label_2';
import Header3 from '@salesforce/label/c.MFR_Portal_Label_3';
import Header4 from '@salesforce/label/c.MFR_Portal_Label_4';
import Header5 from '@salesforce/label/c.MFR_Portal_Label_5';
import Header6 from '@salesforce/label/c.MFR_Portal_Label_6';
import Header7 from '@salesforce/label/c.MFR_Portal_Label_7';
import Header8 from '@salesforce/label/c.MFR_Portal_Label_8';
import logoutpagejs from '@salesforce/resourceUrl/logoutpagejs';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole'; //RT-N-1053
import USER_ID from "@salesforce/user/Id";//RT-N-1053

import isguest from '@salesforce/user/isGuest'


export default class Mfr_logoutConfirmationPage extends NavigationMixin(LightningElement) {
  label = { Header, Header1_02, Header1_03, Header1, Header2, Header3, Header4, Header5, Header6, Header7, Header8 };
  logo5 = newlogo3;
  imgpersonal = imgPersonalized;
  logo1 = newlogo;
  logo2 = newlogo1;
  vmi = logo;
  menurightsider = menu_rightsider
  rightArrow = rarrow;

  navigatelogin;
  @track navigatelogin;
  @track navigateloginname;
  @track navigatecontact;
  @track navigatecontactname;
  @track contactrole = ''; // RT-N-1053

  @track navigatedashboard;
  @track navigatedashboardAPI

  /* @wire(getSiteNameAndAPIName, {pageName :'login'})
     wiredgetSiteNameAndAPIName(value) {
         console.log('Wired Count');
         console.log(value);
         const { data, error } = value;
         if (data) {
             console.log('apiname'+data.siteAPIName)
             this.navigatelogin = data.siteAPIName;
         } else if (error) {
             this.error = error;
             console.log('error in getSiteNameAndAPIName ' + JSON.stringify(this.error));
         }
     }*/

  get isGuestUser() {
    return isguest;  
  } 

  getnames() {
    getSiteNameAndAPIName({ pageName: 'login' })
      .then((result) => {
        console.log({ result });
        this.navigatelogin = result.siteAPIName;
        this.navigateloginname = result.siteName;
      })
      .catch((error) => {
        console.log(' User Calling Error' + JSON.stringify(error));
        this.error = error;
      });
  }
  @wire(getContactRole, { userId:USER_ID }) //RT-N-1053
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

  getnamesnew() {
    getSiteNameAndAPIName({ pageName: 'contactmanager' })
      .then((result) => {
        console.log('getnamesnew-->' + JSON.stringify(result));
        this.navigatecontact = result.siteAPIName;
        this.navigatecontactname = result.siteName;
      })
      .catch((error) => {
        console.log(' User Calling Error' + JSON.stringify(error));
        this.error = error;
      });
  }

  get backgroundStyle() {
    return `background-image:url(${newlogo3})`;
  }
  preventBack() {
    window.history.forward();
  }

  connectedCallback() {
    console.log('Connected Call Back of Logout Confirmation');
    //code
    //   setTimeout(() => {
    //     eval("$A.get('e.force:refreshView').fire();");
    // }, 100);

    // eval("$A.get('e.force:refreshView').fire();");
    // window.location.reload(true)
    this.fireOnLoadEvent();

    this.dispatchEvent(new CustomEvent('backblock', { bubbles: true, composed: true, detail: '' }));

    console.log('Logout confimation');
    //setTimeout("preventBack()", 0);
    //window.location.replace(this.url);

    this.getnames();
    this.getnamesnew();
    console.log('Call back ENDED');

  }

  @wire(getSiteNameAndAPIName, { pageName: 'Dashboard' })
  wiredgetSiteNameAndAPIName(value) {
      console.log('Wired Count');
      console.log(value);
      const { data, error } = value;
      if (data) {
          this.navigatedashboard = data.siteAPIName;
          this.navigatedashboardAPI = data.siteName;

          if(!this.isGuestUser){
              this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                  name: this.navigatedashboardAPI,
                  url: this.navigatedashboard
                },
              });
          }
      } else if (error) {
          this.error = error;
          console.log('error in getSiteNameAndAPIName ' + JSON.stringify(this.error));
      }
  }


  // renderedCallback(){
  //   // this.dispatchEvent(new CustomEvent('backblock', {bubbles: true, composed : true ,detail : ''}));
  //   console.log('Rendered CAll back');

  //   try {

  //     Promise.all([
  //       loadScript(this, logoutpagejs)
  //         ]).then(() => {
  //             console.log('Files loaded');
  //         })
  //       .catch(error => {
  //           console.log('error-->',error.body.message);
  //       });
  //   } catch (error) {
  //     console.log({error}); 
  //   }
  // }
  login() {
    this.fireDataLayerEvent('button','','login','', this.navigateloginname,this.navigatelogin,''); //RT-N-1053
    this[NavigationMixin.Navigate]({
      // type: 'comm__namedPage',
      type: 'standard__webPage',
      attributes: {
        name: this.navigateloginname,
        url: this.navigatelogin
      },
    });
  }

  mfrcontactyouraccountmanager() {
    this.fireDataLayerEvent('button','','contact','', this.navigatecontactname,this.navigatecontact,''); //RT-N-1053
    //console.log('Sucess');
    this[NavigationMixin.Navigate]({
      // type: 'comm__namedPage',
      type: 'standard__webPage',
      attributes: {
        name: this.navigatecontactname,
        url: this.navigatecontact
      },

    });
  }

  //Google Analytics Event
  fireDataLayerEvent(category, action, label,module,linkedtext, linkedurl, productname) {
    console.log('event triggered');
   this.dispatchEvent(new CustomEvent('datalayereventmodule', {
      
       detail: {               
            data_design_category: category,                
            data_design_action: action,
            data_design_label: label,
            data_design_module:module,
            page_type: 'homepage',
            page_purpose:'homepage',
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
            page_localproductname:productname,
            sfmc_id:USER_ID,
            sfmc_audience: this.contactrole,
            page_url: location.href,
            page_title: 'dashboard',

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
                data_design_module:'',       
                page_type: 'logout',
                page_purpose:'logout',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text:'',
                link_url:'',
                content_saved:'',
                content_appointments:'',
                content_requests:'',
                content_name:'',
                page_localproductname: '',
                content_count:'',
                sfmc_id: '',
                sfmc_audience:'',
                page_url: location.href,
                page_title: 'logout-confirm-page',                 
        },
        bubbles: true,
        composed: true
    }));
  }
}