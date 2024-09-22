import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import newlogo from '@salesforce/resourceUrl/merck2';
import newlogo1 from '@salesforce/resourceUrl/menu2';
import HeaderArrow from '@salesforce/resourceUrl/HeaderArrow';
import Notificationbell from '@salesforce/resourceUrl/Notificationbell';
import logo from '@salesforce/resourceUrl/vmiblack';
import USER_ID from "@salesforce/user/Id";
import getnotificationcount from '@salesforce/apex/MSD_CORE_Notification.getNotificationCount';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import getMHEEURL from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getMHEEURL';
import getAccountLockStatus from '@salesforce/apex/MSD_CORE_RedirectController.getAccountLockStatus';

import jobcode from '@salesforce/label/c.nonbrandjobcode';
import isguest from '@salesforce/user/isGuest'
import { loadStyle } from 'lightning/platformResourceLoader';
import cssfile from '@salesforce/resourceUrl/librarypagecss';
import strUserId from '@salesforce/user/Id';
import crossmark from '@salesforce/resourceUrl/cross';
import getactivity from '@salesforce/apex/MSD_CORE_Notification.getActivity';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import {getRecord} from 'lightning/uiRecordApi';
import HealthEconomicEvidenceLink from '@salesforce/label/c.MSD_CORE_HealthEconomicEvidence';
import mheeheader from '@salesforce/label/c.MSD_CORE_MHEE_Header';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

// // Import message service features required for subscribing and the message channel
// import {subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext} from 'lightning/messageService';
// import recordSelected from '@salesforce/messageChannel/MyMessageChannel__c';
export default class Header extends NavigationMixin(LightningElement) {
     domain;
     logo1 = newlogo;
     logo2 = newlogo1;
     HeaderArrow=HeaderArrow;
     notificationicon = Notificationbell;
     vmi = logo;
     cross = crossmark; 
     mheeheader = mheeheader;
     noticount;
     @track prfName;
     userId = strUserId;
     subscription = null;
     @track showResponse=false;
     navigatedashboard;
     navigatedashboardname;
     navigatemenu;
     navigatemenuname;
     navigatenotification;
     navigatenotificationname;
     navigatelogin;
     navigateloginname;
     runonce = false;
     @track contactrole = '';
     @track isAccountLocked = false;
     @track logodisable = false;  // based on current page url of welcome page we are making this variable true
     label = {jobcode};
     @track accountId;//Account Id
     @track portalType;
     domainurl = domainurl;

     Showpopup() {
     
          this.showResponse = true;
          this.fireDataLayerEvent('button','','medical affairs','header', 'Home', '/merckmhee/',''); //RT-1053
     }
     closeResponse(event) {
          var lablelname = event.currentTarget.dataset.label;
          if (lablelname == 'back to screen_X') {
               this.showResponse = false;
               this.fireDataLayerEvent('button','','back to screen_X','modal', 'Home','merckportal/',''); //RT-N-1053
          }else {
               this.showResponse = false;
               this.fireDataLayerEvent('button','','return to mfr portal','modal', 'Home','merckportal/',''); //RT-N-1053
          }
          
     } 
          get isGuestUser() {
          return isguest;
         
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
  @wire(getAccountLockStatus, {userId:USER_ID})
    wiredgetAccountLockStatus(value) {
        const { data, error } = value;
        if(data){
            this.data = data;
            console.log('this.data==>',this.data);
            console.log(this.data.accountStatus,'accountstatus');
            if(this.data.accountStatus=='Locked'){
                this.isAccountLocked = true;
            }
            console.log(this.isAccountLocked,'isAccountLocked');
        }
        else if(error){
            console.log(error);
        }
    }
     
    @wire(CurrentPageReference)
    WiredgetStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.portalType = currentPageReference.state.pType;
            this.accountId = currentPageReference.state.recordId;
        }
    }

     gotoNotification(event){
          // window.open('https://test.merckformularyresources.com/s/menu/notification', '_self');
          console.log("notification url redirect from js");

          var dcookies = document.cookie;
          var dclen = dcookies.split(";");
          // console.log(dclen);
          var cookielst = [];
          
          for(var i =0; i < dclen.length; i++){
               if(dclen[i].startsWith(" https://")){
                    // dclen.splice(i, 1);
               }
               else{
                    cookielst.push(dclen[i].trim());
               }
          }

          document.cookie = " ";
          document.cookie = cookielst.join("; ");
          document.cookie = window.location.href;
          this.fireDataLayerEvent('button','','notificiation','header', this.navigatenotificationname,this.navigatenotification,''); //RT-1053
          this[NavigationMixin.Navigate]({
               // type: 'comm__namedPage',
               type: 'standard__webPage',
               attributes: {
                   name: this.navigatenotificationname,
                   url: this.navigatenotification
               }
           });
     }
     navigatedash(event){
          console.log('Raviteja>>>>141');
          // this[NavigationMixin.Navigate]({
          //      // type: 'comm__namedPage',
          //      type: 'standard__webPage',
          //      attributes: {
          //       name :this.navigatedashboardname,
          //       url: this.navigatedashboard
          //      }
          //  });
          window.location.href = this.navigatedashboard;
          this.fireDataLayerEvent('button','','logo','header', 'Home','/merckportal/',''); //RT-1053
          
     }
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

     connectedCallback(){
          // this.getnotification();
          // this.subscribeToMessageChannel();
          const currenweltUrl = window.location.href.split("/").join("");
          console.log('raviteja>>welcomepage' , currenweltUrl);
          if(currenweltUrl.includes('welcomepage') || currenweltUrl.includes('organic-login') || currenweltUrl.includes('organic') || currenweltUrl === this.domainurl.split("/").join("")){
              this.logodisable = true;
          }
          console.log('logodiable>>' + this.logodisable);
        //   const currentPageReference = this.pageRef;
        //   console.log('raviteja>>currentPageReference' , currentPageReference);
        //   const currentState = currentPageReference.state;
        //   console.log('raviteja>>currentState' , currentState);
        //   const previousPageReference = currentState.prevPageRef;
        //   console.log('raviteja>>previousPageReference' , previousPageReference);

          this.getdashboardnames();
          this.getloginnames();
          this.getnotificationnames();
          this.getmenunames();
          this.getnoticount();
          var x = document.createElement("TITLE");    
          var t = document.createTextNode("Rusheel");    
          x.appendChild(t);    
          document.head.appendChild(x);

        setTimeout(() => {
         this.dispatchEvent(new CustomEvent('hideHeader', {
            detail: '',
            bubbles: true,
            composed: true
        }));
        }, 200);
        

     }
getdashboardnames(){
        getSiteNameAndAPIName({pageName: 'Dashboard'})
            .then((result)=>{
                console.log({result});
                this.navigatedashboard = result.siteAPIName;
                this.navigatedashboardname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error'+JSON.stringify(error));
                this.error = error;
            });
    }
    getmenunames(){
        getSiteNameAndAPIName({pageName: 'menu'})
            .then((result)=>{
                console.log({result});
                this.navigatemenu = result.siteAPIName;
                this.navigatemenuname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error'+JSON.stringify(error));
                this.error = error;
            });
    }
    getnotificationnames(){
        getSiteNameAndAPIName({pageName: 'notification'})
            .then((result)=>{
                console.log({result});
                this.navigatenotification = result.siteAPIName;
                this.navigatenotificationname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error'+JSON.stringify(error));
                this.error = error;
            });
    }
    getloginnames(){
        getSiteNameAndAPIName({pageName: 'login'})
            .then((result)=>{
                console.log({result});
                this.navigatelogin = result.siteAPIName;
                this.navigateloginname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error'+JSON.stringify(error));
                this.error = error;
            });
    }
     // FOR LOADING CSS FILE FROM STATIC RESOURCES
     renderedCallback() {
          console.log('Rendered call back');
          Promise.all([
              loadStyle(this, cssfile)
          ]).then(() => {
              console.log('Files loaded!!');
          })
              .catch(error => {
                  console.log(error.body.message);
              });
              console.log('END Rendered call back');

          let logoToFocus = this.template.querySelector(".logo");
          if(logoToFocus && ! this.runonce){
               //logoToFocus.scrollIntoView({behavior: "smooth", block: "start", inline: "nearest"});
               window.scrollTo(0,0);
               this.runonce = true;

          }
      }
  
        @wire(getMHEEURL, {})
        wiredgetdomain(value) {
          console.log('<<getMHEEURL ::::domain result///////::::>> ' + value);
            const { data, error } = value;
            if(data){                 
                 console.log(data);
                 this.domain = data;
                 
            }
            else if(error){
                 console.log('<< getMHEEURL::::domain error//////////::::>>');
                 console.log(error);
                
            }
        }

     
     getnoticount() {
          getnotificationcount({userid : USER_ID})
          .then((result) => {
               console.log('<<::::getnotificationcount result::::>>');
               console.log({result});
               if(result.total != 0){
                    this.noticount = result.total;
               }
          })
          .catch((error) => {
               console.log('<<::::getnotificationcount error::::>>');
               console.log({error});
          })
     }

     getnotification(){
          console.log("GET Notification Count");

          getnotificationcount({userid : USER_ID})
          .then((result) => {
               console.log('<<::::getnotificationcount result::::>>');
               console.log({result});
               if(result.total != 0){
                    this.noticount = result.total;
               }
          })
          .catch((error) => {
               console.log('<<::::getnotificationcount error::::>>');
               console.log({error});
          })
     }
     /*login(){
          this.fireDataLayerEvent('button','','login','', this.navigateloginname,this.navigatelogin,''); //RT-N-1053
          this[NavigationMixin.Navigate]({
               // type: 'comm__namedPage',
               type: 'standard__webPage',
               attributes: {
                   name: this.navigateloginname,
                   url: this.navigatelogin
                   
               },
           }); 
     } */

     login(){
        if (typeof this.portalType !== 'undefined' && this.portalType !== null && 
            typeof this.accountId !== 'undefined' && this.accountId !== null) {
            window.location.href = this.domainurl+'/organic-login?pType=' + encodeURIComponent(this.portalType) + '&recordId=' + encodeURIComponent(this.accountId);
        } else {
            window.location.href = this.domainurl+'/organic-login';
        }
     }
     menuredirect(event){
          
          var dcookies = document.cookie;
          if (dcookies !=null){

          
          var dclen = dcookies.split(";");
          // console.log(dclen);
          var cookielst = [];
          
          for(var i =0; i < dclen.length; i++){
               // console.log("hdr>>",dclen[i]);
               // console.log(dclen[i].startsWith(" https://"));
               if(dclen[i].startsWith(" https://")){
                    // dclen.splice(i, 1);
               }
               else{
                    cookielst.push(dclen[i].trim());
               }
          }

          console.log(cookielst);

          document.cookie = " ";
          // console.log("1>>>",document.cookie);
          document.cookie = cookielst.join("; ");
          // console.log("2>>>",document.cookie);
          document.cookie = window.location.href;

          }
          // console.log("3>>>",document.cookie);
          console.log('MENU REDIRECT');
          this.fireDataLayerEvent('button','','menu','header', this.navigatemenuname, this.navigatemenu,''); //RT-1053
          window.location.href = this.navigatemenu; // changed to window method from navi maxin to recevie prev url in menu page
        //   this[NavigationMixin.Navigate]({
        //        // type: 'comm__namedPage',
        //        type: 'standard__webPage',
        //        attributes: {
        //            name: this.navigatemenuname,
        //            url: this.navigatemenu
        //        },
               
        //    });
     }
     handleHealthEconomicEvidence(){
          this.fireDataLayerEvent('button','','continue to medical affairs','modal', 'Home', 'merckmhee/',''); //RT-N-1053
          console.log ('baseurl --- '+this.domain);
          window.open(this.domain);
      }
}