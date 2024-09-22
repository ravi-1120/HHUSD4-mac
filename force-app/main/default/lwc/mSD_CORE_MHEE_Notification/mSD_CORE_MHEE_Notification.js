/**
 * Auther:              Ravi Modi (Focal CXM)
 * Component Name:      MSD_CORE_MHEE_Notification
 * Description:         Used for Display Notification
 * Used in:             MHEE Portal Site Notifcation Community Page
 * Created Date:        08th May 2023
 * Lastmodified Date:   15th May 2023
 */

import { LightningElement,wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import USER_ID from "@salesforce/user/Id";

import downarrow from '@salesforce/resourceUrl/downarrow';
import uparrow from '@salesforce/resourceUrl/uparrowicon';
import rightarrow from '@salesforce/resourceUrl/rightarrow2';
import jobcode from '@salesforce/label/c.nonbrandjobcode';
import getMHEENotification from '@salesforce/apex/MSD_CORE_Notification.getMHEENotification';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import updateReadCheck from '@salesforce/apex/MSD_CORE_Notification.updateReadCheck';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
export default class MSD_CORE_MHEE_Notification extends NavigationMixin(LightningElement) { 

    rightarrow = rightarrow;
    uparrow = uparrow;
    downarrow = downarrow;
    label = {jobcode};
    @track notificationmainvalue;
    @track notificationdata;
    @track showemptystate = false;
    @track contactrole = '';
    @track showmoredata = false;
    @track siteAPINames;                    //Site Page Api Name    
    @track siteNames;                       //Site Page URL
    pageSize = 6; //default value we are assigning Tausif
    pageNumber = 1//default value we are assigning Tausif
    totalCount = 0;//default value we are assigning Tausif 
    // Method Name:         WiredgetSiteNameAndAPIName
    // Method Use:          Used for getting all community site page and url for the navigation
    // Developer Name:      Ravi Modi
    // Created Date:        15th May 2023
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({error, data}) {
        console.log('getAllSiteNameAndAPINames-->',{data});
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
        } else if (error) {
            console.log('ERROR in Getting Sites Name-->',{error});
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
    connectedCallback() {
        this.fireOnLoadEvent()
    }

    // Method Name:         renderedCallback
    // Method Use:          Used for rendering latest value
    // Developer Name:      Ravi Modi
    // Created Date:        18th May 2023
    renderedCallback() {
        refreshApex(this.notificationmainvalue);
        setTimeout(() => {
            let boxes = this.template.querySelectorAll('.mainparent');
            let notibars = this.template.querySelectorAll('.notification-bar');
            let lastChilds = this.template.querySelectorAll('.parentnotificationmain:last-child[c-mSD_CORE_MHEE_Notification_mSD_CORE_MHEE_Notification]');
        
                for(let i=0; i < boxes.length; i++ ){
                    console.log('boxes.offsetWidth'+boxes[i].offsetWidth);
                    console.log('boxes.offsetHeight'+boxes[i].offsetHeight);
                    console.log('lastChilds.offsetWidth'+lastChilds[i].offsetWidth);
                    console.log('lastChilds.offsetHeight'+lastChilds[i].offsetHeight);
                    let newHeight = lastChilds[i].offsetHeight;
                    notibars[i].style.marginBottom = newHeight+'px';
                
            }
        }, 3000);
        

    }

    // Method Name:         wiredgetMHEENotification
    // Method Use:          Used gettin MHEE Notification list
    // Developer Name:      Ravi Modi
    // Created Date:        15th May 2023
    @wire(getMHEENotification, {userid: USER_ID,pageSize: '$pageSize', pageNumber: '$pageNumber'})
    wiredgetMHEENotification(value) {
        const { data, error } = value;
        this.notificationmainvalue = value;
        console.log('Get MHEE Value Notification-->',{value});
        if (data) {
            if (data.totalParentNotificationCount === 0) {
                this.showemptystate = true;
            }
            this.totalCount = data.totalParentNotificationCount;
            console.log('totalCount',this.totalCount);
            var parentnotilst = data.parentNotificationList;
            this.notificationdata =[];
            for(var key in parentnotilst){
                if (parentnotilst[key].length > 0) {
                    this.notificationdata.push({value:parentnotilst[key],key:key});
                }
            }
            console.log('notificationdata>>',this.notificationdata);
            console.log('notificationdata>>', this.notificationdata.value);
        }
        else if (error) {
            console.log('Error in Notification Data');
            console.log({error});
        }

     
            
    }
    
    // Method Name:         showhidenotification
    // Method Use:          Used for hide/show child notification
    // Developer Name:      Ravi Modi
    // Created Date:        15th May 2023
    showhidenotification(event) {
        let btnname = event.currentTarget.dataset.btnclk;
        let notificationId = event.currentTarget.dataset.id;
        if (btnname == 'show') {
            let notificationdiv = this.template.querySelector('[data-showid='+notificationId+']');
            let hidedetaildiv = this.template.querySelector('[data-hidedetail='+notificationId+']');
            let showdetaildiv = this.template.querySelector('[data-showdetail='+notificationId+']');
            if (notificationdiv) {
                notificationdiv.classList.toggle('showchildnotification');
            }
            if (hidedetaildiv) {
                hidedetaildiv.classList.toggle('showshowmore');
            }
            if (showdetaildiv) {
                showdetaildiv.classList.toggle('hideshowmore');
            }
        } else {
            let notificationdiv = this.template.querySelector('[data-showid='+notificationId+']');
            let hidedetaildiv = this.template.querySelector('[data-hidedetail='+notificationId+']');
            let showdetaildiv = this.template.querySelector('[data-showdetail='+notificationId+']');
            if (notificationdiv) {
                notificationdiv.classList.toggle('showchildnotification');
            }
            if (hidedetaildiv) {
                hidedetaildiv.classList.toggle('showshowmore');
            }
            if (showdetaildiv) {
                showdetaildiv.classList.toggle('hideshowmore');
            }
        }
    }
 
    // Method Name:         navigate
    // Method Use:          Used for navigation
    // Developer Name:      Ravi Modi
    // Created Date:        15th May 2023
    navigate(event) {
        let meetid = event.currentTarget.dataset.id;
        let notificationId = event.currentTarget.dataset.notificationid;
        let navigationPage = event.currentTarget.dataset.name;
        if(navigationPage == 'requestpage'){
            this.updateRead(notificationId,meetid);
            this.fireDataLayerEvent("button", '', "view request", '', 'RequestDetail__c', '/requestappointment/requestdetail', '', '', '', '', '');
        }
        else{
            this.fireDataLayerEvent("button", '', "browse catalog", '', 'pipeline__c', '/pipeline', '', '', '', '', '');
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    name: this.siteAPINames.Pipeline,
                    url: this.siteNames.Pipeline
                }
            })

        }
    }


    // Method Name:         updateRead
    // Method Use:          Used for Read the Notification
    // Developer Name:      Ravi Modi
    // Created Date:        15th May 2023
    updateRead(notificationid,meetid) {
        updateReadCheck({meetid: notificationid})
        .then((result) => {
            console.log('Result of updateReadCheck==>',{result});
            refreshApex(this.notificationmainvalue);
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    name: this.siteAPINames.RequestDetail,
                    url: this.siteNames.RequestDetail + '?recordId=' + meetid
                }
            })
        })
        .catch((error) => {
            console.log('Error of updateReadCheck==>',{error});
        });   
    }
    get showPagination() {
        return this.totalCount <= 6 ? false : true;
    }
    handleCustomEvent(event){
        console.log('Handle CustomEvent');
        console.log({event});
        console.log('handlePagination ---- ',  event.detail);
        this.pageNumber = event.detail;
        console.log('this.pageNumber-->',this.pageNumber);
    }
    //Google analytics RT 
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, contentname, prdtName, savedcnt, appcnt, pendcnt) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventbrand', {
            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'menu',
                page_purpose: 'notifications',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: linkedtext,
                link_url: linkedurl,
                content_count: '',
                content_saved: savedcnt,
                content_appointments: appcnt,
                content_requests: pendcnt,
                content_name: contentname,
                page_localproductname: prdtName,
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'Notifications',
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
                page_type: 'menu',
                page_purpose: 'notifications',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'Notification__c',
                link_url: '/notification',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'notifications',
            },
            bubbles: true,
            composed: true
        }));
    }
}