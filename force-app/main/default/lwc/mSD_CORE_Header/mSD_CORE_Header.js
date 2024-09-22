import { LightningElement, wire, track } from 'lwc';
import mercklogo from '@salesforce/resourceUrl/merck2';
import Notificationbell from '@salesforce/resourceUrl/Notificationbell';
import menuicon from '@salesforce/resourceUrl/MSD_CORE_Menuicon';
import { NavigationMixin} from 'lightning/navigation';
import getOrgDomain from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getOrgDomain';
import getunreadNotification from '@salesforce/apex/MSD_CORE_Notification.getMHEEUnreadNotificationCount';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import USER_ID from "@salesforce/user/Id";
import isGuestUsr from '@salesforce/user/isGuest';
import HeaderArrow from '@salesforce/resourceUrl/HeaderArrow';
import crossmark from '@salesforce/resourceUrl/cross';
import mfrheader from '@salesforce/label/c.MSD_CORE_MFR_Header';
import mfrportalurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
import logo from '@salesforce/resourceUrl/vmiblack';


export default class MSD_CORE_Header extends NavigationMixin(LightningElement) {

    isGuestUser = isGuestUsr;
    merck = mercklogo;
    notificationicon = Notificationbell;
    HeaderArrow=HeaderArrow;
    cross = crossmark;
    mfrheader = mfrheader;
    mfrportalurl = mfrportalurl;
    vmi = logo;
    
    menu = menuicon;
    @track siteAPINames;
    @track siteNames;
    @track contactrole = '';
    @track notiCount; // For User Story :1097 by Tausif
    @track showResponse=false;



     Showpopup() {
     
          this.showResponse = true;
          //this.fireDataLayerEvent('button','','medical affairs','header', 'Home', '/merckportal/',''); //RT-1053
          console.log ('showpopup --- ');
     }
     closeResponse(event) {
          var lablelname = event.currentTarget.dataset.label;
          if (lablelname == 'back to screen_X') {
               this.showResponse = false;
               this.fireDataLayerEvent('button','','back to screen_X','modal', 'Home','merckmhee/',''); //RT-N-1053
          }else {
               this.showResponse = false;
               this.fireDataLayerEvent('button','','return to mfr portal','modal', 'Home','merckmhee/',''); //RT-N-1053
          }
          
     }
    // For User Story :1097 by Tausif
    getNotificationCount() {
        getunreadNotification({ userid: USER_ID })
            .then((result) => {
                console.log({ result });
                if (result> 0) {
                    this.notiCount = result;
                }
            })
            .catch((error) => {
                console.log({ error });
            })
    }

    

    @wire(getOrgDomain, {})
    wiredgetdomain(value) {
        const { data, error } = value;
        if (data) {
            console.log('<<::::domain result///////::::>>');
            console.log({ data });

        }
        else if (error) {
            console.log('<<::::domain error//////////::::>>');
            console.log(error);

        }
    }

    connectedCallback() {
        sessionStorage.setItem("SFMC_ID", USER_ID);
        this.contactrole = sessionStorage.getItem("SFMC_Audience");
        console.log('isGuestUser-->',this.isGuestUser);
        this.getNotificationCount();// For User Story :1097 by Tausif
    }


    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log({ data });
        console.log({ error });
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
        }
        if (error) {
            console.log({ error });
        }
    }

    handleClickMenu(event) {

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
          console.log('MENU REDIRECT');  //R5-INC2747447 - Added by Sabari

        this.fireDataClickEvent('button', '', 'menu', 'header', this.siteAPINames.Menu, this.siteNames.Menu); //RT-1053

        this[NavigationMixin.Navigate]({
            // type: 'comm__namedPage',
            type: 'standard__webPage',
            attributes: {
                name: this.siteAPINames.Menu,
                url: this.siteNames.Menu
            }
        })
    }

    logoclick() {
        this.fireDataClickEvent('button', '', 'logo', 'header', this.siteAPINames.Dashboard, this.siteNames.Dashboard); 
        console.log('urlredirection' , this.siteNames.Dashboard);  //RT-1053
        window.location.href = this.siteNames.Dashboard;
    }
    notificationclick() {
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
          this.fireDataClickEvent('button', '', 'notificiation', 'header', '', '');   //RT-1053



        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.siteAPINames.Notification,
                url: this.siteNames.Notification
            }
        })
       // this.fireDataClickEvent('button', '', 'notificiation', 'header', '', '');   //RT-1053
    }

    //Google Analytics Event
    fireDataClickEvent(category, action, label, module, linkedtext, linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'menu',
                page_purpose: 'site navigation',
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
                page_title: 'header',

            },
            bubbles: true,
            composed: true
        }));
    }

 

    // For User Story :1097 by Tausif
    get isCountVisible() {
        return (this.notiCount !== undefined && this.notiCount > 0) ? true : false;
    }

    handleHealthEconomicEvidence(){
        //   window.open('/merckportal/', '_blank');
        window.open(this.mfrportalurl + '/dashboard');
        // window.location.href = this.mfrportalurl + '/merckportal/';
      }

}