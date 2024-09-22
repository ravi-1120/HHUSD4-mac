import { LightningElement, track, wire } from 'lwc';
import menuarrow from '@salesforce/resourceUrl/menuarrow'
import { NavigationMixin } from 'lightning/navigation';
import communityPath from '@salesforce/community/basePath';
import header from '@salesforce/label/c.menuheader';
import resources from '@salesforce/label/c.menuresources';
import portal from '@salesforce/label/c.menuportal';
import dashboard from '@salesforce/label/c.menudashboard';
import logo from '@salesforce/resourceUrl/vmi';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import product from '@salesforce/label/c.menuproduct';
import account from '@salesforce/label/c.menuaccount';
import other from '@salesforce/label/c.menuother';
import contact from '@salesforce/label/c.menucontact';
import library from '@salesforce/label/c.menulibrary';
import settings from '@salesforce/label/c.menusettings';
import logout from '@salesforce/label/c.menulogout';
import isguest from '@salesforce/user/isGuest'
import lockgrey from '@salesforce/resourceUrl/lockicongrey';
import lockblack from '@salesforce/resourceUrl/lockiconblack';
import jobcode from '@salesforce/label/c.nonbrandjobcode';
import getAccountLockStatus from '@salesforce/apex/MSD_CORE_RedirectController.getAccountLockStatus';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

// For mobile screen
import larrow from '@salesforce/resourceUrl/larrow';
import navigationarrow from '@salesforce/resourceUrl/navigationarrow';
import crossmark from '@salesforce/resourceUrl/cross';
import HeaderArrow from '@salesforce/resourceUrl/menuarrownew';
import getMHEEURL from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getMHEEURL';
// End for Mobile Screen


import USER_ID from "@salesforce/user/Id";


export default class Menu extends NavigationMixin(LightningElement) {

    @track url;
    vmi = logo;
    @track myAccountflag = false;
    arrow = menuarrow;
    lockicongrey = lockgrey;
    lockiconblack = lockblack;
    navigateContacts;
    navigateContactsname;
    navigatelibrary;
    navigatelibraryname;
    navigatelogin;
    navigateloginname;
    navigatelogoutconfirm;
    navigatelogoutconfirmname;
    navigateothermercksites;
    navigateothermercksitesname;
    navigateproduct;
    navigateproductname;
    navigatesetting;
    navigatesettingname;
    navigatedashboard;
    navigatedashboardname;
    navigatelearnmore;
    navigatelearnmorename;
    main_menu = true;
    myAccountflag_mob = false;
    domainurl = domainurl;
    @track isAccountLocked = false;
    @track prevwelcpg = false;

    leftarrow = larrow;         //For Mobile Screen
    navarrow = navigationarrow;         //For Mobile Screen
    @track showResponse = false;     //For Mobile Screen
    HeaderArrow = HeaderArrow;   //For Mobile Screen
    cross = crossmark;  //For Mobile Screen

    @track contactrole = '';    

    label = { header, resources, portal, dashboard, product, account, other, contact, library, settings, logout, jobcode };
    connectedCallback() {
        //code
        this.contactrole = sessionStorage.getItem('SFMC_Audience');
        this.myAccountflag = false;
        this.getsitename();
        this.fireOnLoadEvent();
        // kept this logic to get prev page url to check it is from welcpg
        const previousURL = document.referrer;
        console.log('previousURL???' + previousURL);
        if (previousURL.includes('welcomepage') || previousURL.includes('forgotpasswordnew')){
            console.log('enteredurl');
            this.prevwelcpg = true;
        }
        console.log('prevwelcpg>>' + this.prevwelcpg);
    }
    
    Showpopup() {

        this.showResponse = true;
    }
    closeResponse() {
        this.showResponse = false;
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
    handleHealthEconomicEvidence() {
        window.open(this.domain);
    }

    getsitename() {
        getSiteNameAndAPIName({ pageName: 'Dashboard' })
            .then((result) => {
                console.log({ result });
                this.navigatedashboard = result.siteAPIName;
                this.navigatedashboardname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
            getSiteNameAndAPIName({ pageName: 'logoutcconfirmationpage' })
            .then((result) => {
                console.log({ result });
                this.navigatelogoutconfirm = result.siteAPIName;
                this.navigatelogoutconfirmname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
            getSiteNameAndAPIName({ pageName: 'Learnmore' })
            .then((result) => {
                console.log({ result });
                this.navigatelearnmore = result.siteAPIName;
                this.navigatelearnmorename = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
            getSiteNameAndAPIName({ pageName: 'ProductList' })
            .then((result) => {
                console.log({ result });
                this.navigateproduct = result.siteAPIName;
                this.navigateproductname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
            getSiteNameAndAPIName({ pageName: 'Library' })
            .then((result) => {
                console.log({ result });
                this.navigatelibrary = result.siteAPIName;
                this.navigatelibraryname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
            getSiteNameAndAPIName({ pageName: 'othermercksites' })
            .then((result) => {
                console.log({ result });
                this.navigateothermercksites = result.siteAPIName;
                this.navigateothermercksitesname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
            getSiteNameAndAPIName({ pageName: 'MyContacts' })
            .then((result) => {
                console.log({ result });
                this.navigateContacts = result.siteAPIName;
                this.navigateContactsname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
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
            getSiteNameAndAPIName({ pageName: 'setting' })
            .then((result) => {
                console.log({ result });
                this.navigatesetting = result.siteAPIName;
                this.navigatesettingname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
            getSiteNameAndAPIName({ pageName: 'setting' })
            .then((result) => {
                console.log({ result });
                this.navigatesettingcomplete = result.siteAPIName+ '?tab=2';
                this.navigatesettingname = result.siteName;
            })
            .catch((error) => {
                console.log(' User Calling Error' + JSON.stringify(error));
                this.error = error;
            });
    }

    get isGuestUser() {
        return isguest;

    }

    onclickhandlerLogout(event) {

        let gaLabel = event.target.dataset.designLabel;
        if(this.myAccountflag) {
            gaLabel = 'my account;' + gaLabel;
        }
        console.log('event.target.dataset.designCategory>>>',event.target.dataset.designCategory);
        console.log('event.target.dataset.id>>>',event.target.dataset.id);
        console.log('gaLabel>>>',gaLabel);
        console.log('event.target.dataset.designModule>>>',event.target.dataset.designModule);
        this.fireDataLayerEvent(event.target.dataset.designCategory,'', gaLabel,  event.target.dataset.designModule,'logout','/logout');


        //  Page.ClientScript.RegisterStartupScript(this.GetType(),"clearHistory","ClearHistory();",true);
        // sessionStorage.clear();
        var backlen = history.length;
        history.go(-backlen);
        //window.history.deleteAll();
        //location.replace();

        console.log('INside Community path before');
        console.log('onclickhandlerLogout communityPath-->>',communityPath);
        this.url = communityPath+ '/secur/logout.jsp?retUrl=%2Fmerckportal%2Flogout-confirmation-page';
        //this.url = communityPath+ '/secur/logout.jsp?retUrl=%2Fmerckportal%2Flogout-confirmation-page%2Fmfr-contactyouraccountmanager';
        // this.url=communityPath+'/secur/logout.jsp?';
        //this.url=this.url.replaceAll(this.navigatedashboard, "/");
        // this.url = '/s/logout-confirmation-page';
        console.log('INside Community path TEST-->' + this.url);
        // let deletingAll = window.history.deleteAll()
        // console.log({deletingAll});
        // window.history.forward();
        window.location.replace(this.url);
        //this.navigateToNewRecordPage(this.url);
        //this.cache.clean();

    }

    

    myAccountHanlder() {
        console.log('INside mY Account Hanlder' + this.myAccountflag);

        // Added for Mobile View
        var width = screen.width;
        console.log('OUTPUT : ', width);
        if (width < 768) {
            this.myAccountflag = false;
            if (this.myAccountflag_mob) {
                this.main_menu = true;
                this.myAccountflag_mob = false;
            }
            else {
                this.main_menu = false;
                this.myAccountflag_mob = true;

            }
            console.log('OUTPUT : ', this.main_menu);
            console.log('OUTPUT : ', this.myAccountflag_mob);
        }
        else {
        if (this.myAccountflag) {
            this.myAccountflag = false;
        }
        else {
            this.myAccountflag = true;
            }

        }



    }
    handleContactClick(event) {
        console.log('on contact click');
    }

    navigatetolm(){
        console.log('navigatelearnmore>>' + this.navigatelearnmore);
        // window.location.href = this.navigatelearnmore;
        window.location.href = this.domainurl + '/organic-learn-more';
    }

    onclickhandler(event) {
        console.log('onclickhanler');
        console.log('onclickhanler' + event.target.id);
        console.log('onclickhanler--->' + event.target.dataset.id);
        //this.handleclickonMenu(event);

        // Event
        let gaLabel = event.target.dataset.designLabel;
        if(this.myAccountflag) {
            gaLabel = 'my account;' + gaLabel;
        }

        
        let toNavigateUrl = event.target.dataset.id;
        console.log('entered')
        this.fireDataLayerEvent(event.target.dataset.designCategory,'', gaLabel,  event.target.dataset.designModule,gaLabel,toNavigateUrl);
        this.navigateToNewRecordPage(toNavigateUrl);
    }

    navigateToNewRecordPage(url) {
        console.log('toNavigateUrl==' + url);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
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


    // Event
    fireDataLayerEvent(category, action, label, module,linkedtext,linkedurl) {
        
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {
            detail: {
                // event_category: category,
                // event_action: action,
                // event_label: label,
                // module: module,
                // page_type: 'menu',
                // page_purpose: 'site navigation',
                // page_audience: 'payor',
                // page_marketname: 'united_states',
                // page_region: 'us',
                // page_contentclassification: 'non-commercial'
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: 'logout', //RT-1053
                page_purpose: 'logout',//'site navigation', RT-1053
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
                page_localproductname:'',                
                sfmc_id:USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'menu',                      
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
                        // event_category: category,
                        // event_action: action,
                        // page_type: 'menu',
                        // page_purpose:'site navigation',
                        // page_audience: 'payor',
                        // page_marketname: 'united_states',
                        // page_region: 'us',
                        // page_contentclassification: 'non-commercial',
                        data_design_category: '',
                        data_design_action: '',
                        data_design_label: '',
                        data_design_module:'',       
                        page_type: 'logout', //'menu', RT-1053
                        page_purpose: 'logout',//'site navigation', RT-1053
                        page_audience: 'payor',
                        page_marketname: 'united_states',
                        page_region: 'us',
                        page_contentclassification: 'non-commercial',
                        link_text:'menu__c',
                        link_url:'/menu',
                        content_saved:'',
                        content_appointments:'',
                        content_requests:'',
                        content_name:'',
                        page_localproductname: '',
                        content_count:'',
                        sfmc_id: USER_ID,
                        sfmc_audience:this.contactrole,
                        page_url: location.href,
                        page_title: 'menu',                      
                },
                bubbles: true,
                composed: true
            }));
        }

}