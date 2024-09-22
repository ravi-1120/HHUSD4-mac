import { LightningElement, wire, track } from 'lwc';
import mercklogo from '@salesforce/resourceUrl/MSD_CORE_Mercklogo';
import menuHeaderNew from '@salesforce/resourceUrl/MenuHeaderNew';
import Notificationbell from '@salesforce/resourceUrl/blackbellicon';
import close from '@salesforce/resourceUrl/msd_close';
import menuicon from '@salesforce/resourceUrl/whitemenu';
import { NavigationMixin } from 'lightning/navigation';
import getunreadNotification from '@salesforce/apex/MSD_CORE_Notification.getMHEEUnreadNotificationCount';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getSiteNameAndAPIName';

import USER_ID from "@salesforce/user/Id";
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';



export default class MSD_CORE_Header_White extends NavigationMixin(LightningElement) {
    merck = mercklogo;
    MenuHeaderNew = menuHeaderNew;
    close = close
    notificationicon = Notificationbell;
    menu = menuicon;
    @track notiCount; // For User Story :1097 by Tausif
    @track contactrole;
    menupg = false;
    notificationpg = false;
    navigatedashboard;
    connectedCallback() {
        console.log('getNotificationCount');
        this.getNotificationCount();// For User Story :1097 by Tausif
        this.setVisibility();
    }
    setVisibility(){
        if (window.location.href.includes("notification")) {// For User Story :1097 by Tausif
            this.notificationpg = true;
            this.menupg = false;
        } else {
            this.menupg = true;
            this.notificationpg = false;
        }
    }
    // For User Story :1097 by Tausif
    getNotificationCount() {
        getunreadNotification({ userid: USER_ID })
            .then((result) => {
                console.log({ result });
                if (result > 0) {
                    this.notiCount = result;
                }
            })
            .catch((error) => {
                console.log({ error });
            })
    }

    handleClickMenu(event) {
     
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.siteAPINames.Menu,
                url: this.siteNames.Menu
            }
        })
    }
    
    @wire(getContactRole, { userId:USER_ID })
    wiredgetContactRole(value) {
        console.log({value});
        const { data, error } = value;
        if(data) {
            console.log({data});
            this.contactrole = data;
        }
        if(error) {
            console.log({error});
        }
    }


    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({ error, data }) {
        console.log('Data of All Site Name-->', { data });
        console.log('Error of All Site Name-->', { error });
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
            this.navigatedashboard = this.siteNames.Dashboard;
        }
        if (error) {
            console.log({ error });
        }
    }
    handleClose(event) {
    	this.fireDataClickEvent('button', '', 'back to screen_X', 'modal', 'Home', '/'); 
        console.log('Close Menu');
        //window.history.back(); 
        var cc = document.cookie;
        let ca = cc.split(';');

        // console.log(ca);
        for (let i = 0; i < ca.length; i++) {
            if (ca[i].startsWith(" https://")) {
                /* [Sabari - 10/23] : INC2850539 */
                window.location.href = ca[i].replace(/=+$/,'');
                console.log(ca[i]);
            }
        }
        //R5-INC2747447 - Added by Sabari

    }
    // For User Story :1097 by Tausif
    get isCountVisible() {
        return (this.notiCount !== undefined && this.notiCount > 0) ? true : false;
    }
    notificationclick() {// For User Story :1097 by Tausif
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                name: this.siteAPINames.Notification,
                url: this.siteNames.Notification
            }
        })
        this.fireDataClickEvent('button', '', 'notificiation', 'header', '', '');   //RT-1053
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
    navigation(event) {
        var name = event.target.dataset.name;
        console.log('nameno>>>'+name);
        let pageapi = '';
        let pagename = '';

        getSiteNameAndAPIName({ pageName: name })
            .then((result) => {
                pagename = result.siteAPIName;
                console.log({ pagename });
                pageapi = result.siteName;
                console.log({ pageapi });
                if (result != null || result !== '' || result !== undefined) {
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
    }
}