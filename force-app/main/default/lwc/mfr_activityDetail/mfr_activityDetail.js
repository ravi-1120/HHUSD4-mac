import { api, track, LightningElement, wire } from 'lwc';
import downarrow from '@salesforce/resourceUrl/downarrow';
import uparrow from '@salesforce/resourceUrl/uparrowicon';
import rightarrow from '@salesforce/resourceUrl/rightarrow2';
import { NavigationMixin } from 'lightning/navigation';

import USER_ID from '@salesforce/user/Id';          //User Id

// import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import updateReadCheck from '@salesforce/apex/MSD_CORE_Notification.updateReadCheck';

export default class Mfr_activityDetail extends NavigationMixin(LightningElement) {

    @api productID;
    @api meetingRequestObj;
    arrow = rightarrow;
    downarrow = downarrow;
    uparrow = uparrow;
    showmorevar;
    showAutomore = true;
    siteName;
    siteApiName;
    @track contactrole;
    @api prodname;
    @api content;
    @track prodnamefinal;

    handleShow() {
        this.showmorevar = true;
        this.showAutomore = false;
    }

    refreshactivitydetail() {
        eval("$A.get('e.force:refreshView').fire();");
    }

    redirect(event) {
        console.log('prodname>>>'+this.prodname);
        console.log('contname>>>'+this.content);
        var resid = event.target.dataset.id;
        console.log({ resid });
        var notificationId = event.target.dataset.notiid;
        console.log({notificationId});
        var pageapi;
        var pagename;
        this.fireDataClickEvent("button", '', "view activity", '');
        if (resid != undefined) {
            getSiteNameAndAPIName({ pageName: 'viewschedule' })
                .then((result) => {
                    console.log({ result });
                    pageapi = result.siteName;
                    pagename = result.siteAPIName;
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            name: pageapi,
                            url: pagename + '?recordId=' + resid
                        },
                    });
                    this.updateReadCheckVal(notificationId);
                })
                .catch((error) => {
                    console.log({ error });
                });
        } else {
            getSiteNameAndAPIName({ pageName: 'Librarydetail' })
                .then((result) => {
                    console.log({ result });
                    let navvar = result.siteAPIName + '?recordId=' + this.productID + '&tab=Save';
                    location.href = navvar;
                    this.updateReadCheckVal(notificationId);
                })
                .catch((error) => {
                    console.log({ error });
                });
        }
    }

    updateReadCheckVal(meetingid){
        
        updateReadCheck({meetid: meetingid})
                .then((result) => {
                    console.log('Result of updateReadCheck==>',{result});
                })
                .catch((error) => {
                    console.log('Error of updateReadCheck==>',{error});
                });
    }

    redirectReq(event) {
        console.log('redirectReq');
        let req = this.template.querySelector(".notifcls");
        if (req) {


            var resid = event.target.dataset.id;
            console.log({ resid });
            var pageapi;
            var pagename;
            console.log('this.prodname==>',this.prodname);
            
            this.fireDataClickEvent("button", '', "view activity", '');
            if (resid != undefined) {
                getSiteNameAndAPIName({ pageName: 'viewschedule' })
                    .then((result) => {
                        console.log({ result });
                        pageapi = result.siteName;
                        pagename = result.siteAPIName;
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                name: pageapi,
                                url: pagename + '?recordId=' + resid
                            },
                        });
                    })
                    .catch((error) => {
                        console.log({ error });
                        this.error = error;
                    });
            }
        }
    }

    hidemore() {
        this.showmorevar = false;
        this.showAutomore = true;
    }
    @api refreshActivityDetail() {
        this.showAutomore = false;
    }

    connectedCallback() {
        //console.log('this.prodname====1111>>>',this.prodname);
        console.log('this.content-->>>>>>>',this.content);
        console.log('this.meetingRequestObj.activity=====',this.meetingRequestObj.activity);
        this.contactrole = sessionStorage.getItem("SFMC_Audience");
        this.prodnamefinal=this.prodname;
    }

    renderedCallback() {
        console.log('req');
        let req = this.template.querySelector('.request');
        if (req) {
            req.setAttribute('target', '')
        }
    }

    clkHandle(event) {
        event.preventDefault();
    }
    handleredirect(event){
console.log('testing for link');
    }
    fireDataClickEvent(category, action, label, module) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'resources',
                page_purpose: 'product resources',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'detail__c',
                link_url: '/library/detail',
                content_count: '',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: this.content,
                page_localproductname: this.prodnamefinal,
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'library detail',

            },
            bubbles: true,
            composed: true
        }));
    }
}