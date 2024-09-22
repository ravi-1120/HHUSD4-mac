import { LightningElement, track, wire } from 'lwc';
import newlogo from '@salesforce/resourceUrl/merck2';
import newlogo1 from '@salesforce/resourceUrl/MenuHeaderNew';
import newlogo3 from '@salesforce/resourceUrl/bellicon';
import newlogo4 from '@salesforce/resourceUrl/menuclose';
import logo from '@salesforce/resourceUrl/vmiblack';
import Notificationbell from '@salesforce/resourceUrl/blackbellicon';
import USER_ID from "@salesforce/user/Id";
import isguest from '@salesforce/user/isGuest'
import crossmark from '@salesforce/resourceUrl/cross';
import HeaderArrow from '@salesforce/resourceUrl/menuarrownew';
import getnotificationcount from '@salesforce/apex/MSD_CORE_Notification.getNotificationCount';
import getMHEEURL from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getMHEEURL';
import { NavigationMixin } from 'lightning/navigation';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import mheeheader from '@salesforce/label/c.MSD_CORE_MHEE_Header';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import getAccountLockStatus from '@salesforce/apex/MSD_CORE_RedirectController.getAccountLockStatus';
import jobcode from '@salesforce/label/c.nonbrandjobcode';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

export default class Menu_header extends NavigationMixin(LightningElement) {
    merck = newlogo;
    MenuHeaderNew = newlogo1;
    vmi = logo;
    bell = newlogo3;
    close = newlogo4;
    mheeheader = mheeheader;
    domainurl = domainurl;
    notificationicon = Notificationbell; HeaderArrow = HeaderArrow;
    cross = crossmark;
    noticount;
    @track showResponse = false;
    @track notificationpg = false;
    @track menupg = false;
    @track contactrole = '';
    navigatedashboard;
    @track isAccountLocked = false;
    label = {jobcode};
    @track domain;
    @track prevwelcpg = false;

    // notifi_close = false;

    // menu_count = 0 ;

    Showpopup() {
        this.fireDataLayerEvent('button','','medical affairs','header', 'Home','/merckportal/','','homepage','homepage');//RT GA bug
        this.showResponse = true;
    }
    closeResponse(event) {
        this.showResponse = false;
        let buttonname = event.currentTarget.dataset.id;
        console.log('buttonename>>>'+buttonname);
        var pagename = window.location.href;
        console.log('pagename>>',pagename);
        if (pagename.endsWith('menu')){
            this.fireDataLayerEvent('button','',buttonname,'modal', 'Home','/merckportal/','','menu','site navigation'); //RT GA 1122
        }else if (pagename.endsWith('notification')){
            this.fireDataLayerEvent('button','',buttonname,'modal', 'Home','/merckportal/','','menu','notifications'); //RT GA 1122
        }
        
    }

    @wire(getMHEEURL, {})
    wiredgetdomain(value) {
        const { data, error } = value;
        if(data){
            this.domain = data;
        }
        else if(error){
            console.log(error);
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

    connectedCallback() {
        this.getnotification();

        if (window.location.href.includes("notification")) {
            this.notificationpg = true;
        } else {
            this.menupg = true;
        }

        const previousURL = document.referrer.split("/").join("");
        console.log('previousURL???' + previousURL);

        if (previousURL.includes('welcomepage') || previousURL.includes('organic') || previousURL.includes('login') || previousURL === this.domainurl.split("/").join("")){
            console.log('enteredurl');
            this.prevwelcpg = true;
        }
        console.log('prevwelcpg>>' + this.prevwelcpg);
        // console.log(document.cookie);
        // var cc  =document.cookie;
        // let ca = cc.split(';');
        // console.log(ca[0]);
        // for(let i = 0; i <ca.length; i++) {
        //     console.log(ca[i]);
        // }
        // function listVisits(historyItems) {
        //     if (historyItems.length) {
        //       console.log(`URL ${historyItems[0].url}`);
        //     //   const gettingVisits = browser.history.getVisits({
        //     //     url: historyItems[0].url
        //     //   });
        //     //   gettingVisits.then(gotVisits);
        //     }
        //   }

        //   let searching = window.history.search({
        //     text: "",
        //     startTime: 0,
        //     maxResults: 1
        //   });
        console.log(window.history[-1]);
        //   searching.then(listVisits);
    }
    

    get isGuestUser() {
        return isguest;
    }

    @wire(getSiteNameAndAPIName, { pageName: 'Dashboard' })
    wiredgetSiteNameAndAPIName(value) {
        console.log('Wired Count');
        console.log(value);
        const { data, error } = value;
        if (data) {
            console.log('apiname' + data.siteAPIName)
            this.navigatedashboard = data.siteAPIName;
        } else if (error) {
            this.error = error;
            console.log('error in getSiteNameAndAPIName ' + JSON.stringify(this.error));
        }
    }

    getnotification() {
        console.log("GET Notification Count");

        getnotificationcount({ userid: USER_ID })
            .then((result) => {
                console.log('<<::::getnotificationcount result::::>>');
                console.log({ result });
                if (result.total != 0) {
                    this.noticount = result.total;
                }
            })
            .catch((error) => {
                console.log('<<::::getnotificationcount error::::>>');
                console.log({ error });
            })
    }

    // Close Menu
    closemenu() {
        console.log('Close Menu');
        // history.back();
        var cc = document.cookie;
        console.log('cc',cc);
        let ca = cc.split(';');
        console.log('ca',ca);
        
        for (let i = 0; i < ca.length; i++) {
            if (ca[i].startsWith(" https://")) {
                /* [Sabari - 10/23] : INC2850539 */
                window.location.href = ca[i].replace(/=+$/,'');
                console.log(ca[i]);
            }
        }
        // history.go(-this.menu_count);
    }
    backtowelpg(){
        window.history.back();
    }

    gotoLogin() {

    }

    onclickhandler(event) {
        let toNavigateUrl = event.target.dataset.id;
        console.log({toNavigateUrl});
        console.log('entered');
        // this.navigateToNewRecordPage(toNavigateUrl);
        var pageapi = '';
        var pagename = '';

        getSiteNameAndAPIName({ pageName: toNavigateUrl })
            .then((result) => {
                console.log({result});
                pagename = result.siteAPIName;
                console.log({ pagename });
                pageapi = result.siteName;
                console.log({ pageapi });
                if (result != null || result != '' || result != undefined) {

                    this[NavigationMixin.Navigate]({
                        // type: 'comm__namedPage',
                        type: 'standard__webPage',
                        attributes: {
                            name: pageapi,
                            url: pagename
                        },
                    });
                }
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
    }

    navigation(event) {
        var name = event.target.dataset.name;
        console.log('nameno>>>'+name);
        // var urlval;
        // var apival;
        var pageapi = '';
        var pagename = '';

        getSiteNameAndAPIName({ pageName: name })
            .then((result) => {
                pagename = result.siteAPIName;
                console.log({ pagename });
                pageapi = result.siteName;
                console.log({ pageapi });
                if (result != null || result != '' || result != undefined) {
                    this[NavigationMixin.Navigate]({
                        // type: 'comm__namedPage',
                        type: 'standard__webPage',
                        attributes: {
                            name: pageapi,
                            url: pagename
                        }
                    });
                }
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });

            if (name == 'menu') {
                this.fireDataLayerEvent('button','','menu','header', 'Home','/merckportal/','','homepage','homepage');//RT GA bug
            }else{
                this.fireDataLayerEvent('button','','notificiation','header', 'Home','/merckportal/','','homepage','homepage');//RT GA bug
            }

        // if (name == 'menu') {
        //     // this.notifi_close = false;
        //     urlval = '/s/menu';
        //     apival = 'menu__c';

        //     // console.log(window.location.href);
        // }else if (name == 'notification') {
        //     // this.notifi_close = true;
        //     urlval = '/s/menu/notification';
        //     apival = 'notification__c';
        //     // console.log(window.location.href);
        // }
        // this.menu_count = this.menu_count + 1;
        // console.log(this.menu_count);
        // this[NavigationMixin.Navigate]({
        //     type: 'comm__namedPage',
        //     attributes: {
        //         name: apival,
        //         url: urlval
        //     }
        // });
    }

    handleHealthEconomicEvidence() {
        window.open(this.domain);
        this.fireDataLayerEvent('button','','continue to medical affairs','modal', 'Home','/merckportal/','','homepage','homepage'); //RT GA 1122
    }
    navigatetodash(){
        this.fireDataLayerEvent('button','','logo','header', 'Home','/merckportal/','','homepage','homepage');//RT GA bug
    }
    fireDataLayerEvent(category, action, label,module,linkedtext, linkedurl, productname, pgtype, pgpurpose) {
        console.log('event triggered');
       this.dispatchEvent(new CustomEvent('datalayereventmodule', {
          
           detail: {               
                data_design_category: category,                
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: pgtype,
                page_purpose: pgpurpose,
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
}