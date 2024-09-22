import { LightningElement ,wire,api,track} from 'lwc';

import newlogo from '@salesforce/resourceUrl/merck2';
import newlogo1 from '@salesforce/resourceUrl/rightarrow';
import newlogo4 from '@salesforce/resourceUrl/merck2';
import newlogo5 from '@salesforce/resourceUrl/menu2';
import newlogo2 from '@salesforce/resourceUrl/banner';
import newlogo3 from '@salesforce/resourceUrl/uparrow';
import newlogo6 from '@salesforce/resourceUrl/active2';
import newlogo7 from '@salesforce/resourceUrl/rightarrow2';
import newlogo9 from '@salesforce/resourceUrl/downarrow';
import newlogo8 from '@salesforce/resourceUrl/calender';
import document from '@salesforce/resourceUrl/calender';
import phoneiconblack from '@salesforce/resourceUrl/phone1';;
import cntuser from '@salesforce/resourceUrl/contact2';
import phoneicon from '@salesforce/resourceUrl/phone';
import messageicon from '@salesforce/resourceUrl/message';
import bookicon from '@salesforce/resourceUrl/book';
import warrow from '@salesforce/resourceUrl/whitearrow';
import noprofile from '@salesforce/resourceUrl/noprofile';

import ftlogo1 from '@salesforce/resourceUrl/image';
import ftlogo2 from '@salesforce/resourceUrl/truste';
import ftlogo3 from '@salesforce/resourceUrl/truste';
import {NavigationMixin} from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import USER_ID from "@salesforce/user/Id";
//import getContactDetails from '@salesforce/apex/GetContactDetailsOnCommunityPage.getContactDetails'; 
//import getprodcuctcount from '@salesforce/apex/MSD_CORE_ProductList.getCatalogCount';
import getExecutiveContacts from '@salesforce/apex/MSD_CORE_ProductList.getExecutiveContacts';
import getPrimaryExecutive from '@salesforce/apex/MSD_CORE_ProductList.getPrimaryExecutive';
import { getRecord } from 'lightning/uiRecordApi';
import isguest from '@salesforce/user/isGuest'
import AM_Title from '@salesforce/label/c.AccountManagement';
import AM_Disc from '@salesforce/label/c.AccountManagementDesg';
import AM_Email from '@salesforce/label/c.AccountManagementEmail';
import AM_Phone from '@salesforce/label/c.AccountManagementPhone';
import NavigateToDashboard from '@salesforce/label/c.NavigateToDashboard';    //Custom label for navigation to dashboard page
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import getAccountLockStatus from '@salesforce/apex/MSD_CORE_RedirectController.getAccountLockStatus';
import accounticon from '@salesforce/resourceUrl/account';  //R4
export default class Dashboardall extends  NavigationMixin(LightningElement) {

@api recordId;
exeContacts = [];
logo1 = newlogo;
logo2 = newlogo1;
logo3 = newlogo4;
logo4 = newlogo5;
logo5 = newlogo2;
logo6 = newlogo3;
logo7 = newlogo6;
logo8 = newlogo7;
logo9 = newlogo8;
logo10=newlogo9;
docicon = document;
cntuser = cntuser;
phoneicon = phoneicon;
phoneiconblack=phoneiconblack;
messageicon = messageicon;
bookicon = bookicon;
warrow = warrow;
ftlogo1 = ftlogo1;
ftlogo2 = ftlogo2;
ftlogo3 = ftlogo3;
noprofile = noprofile
products;
savedcon;
profilePicture;
accounticon = accounticon;  //R4
width_ProPic ='78px';
@track primaryemail='';
navigatedashboard;
    @track navigatelibrary;
    @track navigatelibraryname;
    @track pageNamelist;
@track contactrole = '';
    @track isAccountLocked = false;
 prodcountData;
    error;
    currentPageReference = null; 
    urlStateParameters = null;
    prodId;
    roleId;
   primaryExecutive = [];

   label = {
    NavigateToDashboard
}

   
   
@wire(getSiteNameAndAPIName, {pageName :'Dashboard'})
    wiredgetSiteNameAndAPIName(value) {
        console.log('Wired Count');
        console.log(value);
        const { data, error } = value;
        if (data) {
            console.log('apiname'+data.siteAPIName)
            this.navigatedashboard = data.siteAPIName;
        } else if (error) {
            this.error = error;
            console.log('error in getSiteNameAndAPIName ' + JSON.stringify(this.error));
        }
    }

 getnames(){
        getSiteNameAndAPIName({pageName: 'Dashboard'})
            .then((result)=>{
                console.log({result});
                this.navigatelibrary = result.siteAPIName;
                this.navigatelibraryname = result.siteName;
                console.log("Get names");
            })
            .catch((error) => {
                console.log(' User Calling Error'+JSON.stringify(error));
                this.error = error;
            });
    }

navigate(event){
         
        console.log({event});
        console.log("Navigate Method");
        var prodId = event.currentTarget.dataset.id;
        console.log({prodId});

        this[NavigationMixin.Navigate]({
            // type: 'comm__namedPage',
            type: 'standard__webPage',
            attributes: {
                name: this.navigatelibraryname,
                url: this.navigatelibrary+'?recordId='+prodId
            }
            // state: {
            //     recordId: prodId
            // }
        });
    }


    get mTitle() {
       return AM_Title;
    }

    get mSubTitle() {
       return AM_Disc;
    }

    get mPhone() {
        return AM_Phone;
    }

    
    get mEmail() {
       return AM_Email;
    }
    
    get isGuestUser() {
     return isguest;
         
     } 
    connectedCallback() {
        //this.userCheck();
      //  this.getproduct();
        this.getnames();
        this.fireOnLoadEvent();
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

  @wire(getExecutiveContacts)
    wiredExecutiveContacts({ error, data }) {
        if (data) {
            this.exeContacts = data;
            console.log('Contacts'+ JSON.stringify(data));
        } 
        if(error){
            console.log('Error'+ JSON.stringify(error));
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
   
    @wire(getPrimaryExecutive, {'userId': USER_ID})
    wiredPrimaryExecutive({ error, data }) {
        if (data) {
            //old code Mukesh
            // this.primaryExecutive = data; 

            this.primaryExecutive = data.map(row => ({
                ...row,
                // fullPhotoURL: row.FullPhotoUrl,
                // MediumPhotoUrl: row.MediumPhotoUrl,
                // isPicturePresent: this.hasProfilePicture(row.FullPhotoUrl),
                formatNumber:this.getFormattedPhnNumber(row.Phone), 
                formatEmail:this.getFormattedEmail(row.Email),
                isPhoneAvailable:this.hasPhoneNumber(row.Phone),
                isEmailAvailable:this.hasEmail(row.Email) 
            
                
            }));
            console.log('Primary Executive'+ JSON.stringify(data));
             if(this.primaryExecutive.length > 0){
                 console.log(this.primaryExecutive[0].Email.length);
                // this.primaryemail=this.primaryExecutive[0].Email;
                //  let emailval=this.primaryExecutive[0].Email;
                //  var width = screen.width;
                //     let emailname   = emailval.substring(0, emailval.lastIndexOf("@"));
                //     let domain = emailval.substring(emailval.lastIndexOf("@") +1);
                //  console.log('Email--> '+emailname);
                //  console.log('Email--> '+domain);
                 
                
                //  if (width < 768) {
                //      if (emailname.length >= 8) {
                //         let newemailname = emailname.substring(0, 6) + '....' + '@' + domain;
                //         let emailprefix = newemailname.substring(0,newemailname.indexOf('.com') );
                //         this.primaryemail = emailprefix+'.com';
                //         console.log('newemailname' + newemailname);
                //     }
                //     else
                //     {
                //         this.primaryemail = this.primaryExecutive[0].Email;
                //         let emailprefix =  this.primaryemail.substring(0, this.primaryemail.indexOf('.com') );
                //         this.primaryemail = emailprefix+'.com';  
                //     }
                //  }
                //   else{
                //     if (emailname.length >= 20) {
                //         let newemailname = emailname.substring(0, 18) + '....' + '@' + domain;
                //         this.primaryemail = newemailname;
                //         let emailprefix =  this.primaryemail.substring(0, this.primaryemail.indexOf('.com') );
                //         this.primaryemail = emailprefix+'.com';
                //         console.log('newemailname' + newemailname);
    
                //         var width = screen.width;
                //         console.log('OUTPUT : ', width);
                //     }
                //     else {
                //         this.primaryemail = this.primaryExecutive[0].Email;
                //         let emailprefix =  this.primaryemail.substring(0, this.primaryemail.indexOf('.com') );
                //         this.primaryemail = emailprefix+'.com';
                 //    }
                //     }
                 this.primaryemail=this.primaryExecutive[0].Email;
                    
                
                console.log('this.primaryExecutive[0].MediumPhotoUrl recent change ' + this.primaryExecutive[0].MediumPhotoUrl);
                // this.profilePicture = this.primaryExecutive[0].FullPhotoUrl;
                 if(this.hasProfilePicture(this.primaryExecutive[0].MediumPhotoUrl)){
                    this.width_ProPic = '84px';//R4
                     this.profilePicture = this.primaryExecutive[0].MediumPhotoUrl;  //  <!-- Mukesh -->
                   
                 }else{
                    this.width_ProPic = '78px';//R4
                     this.profilePicture =  this.noprofile;
                     console.log( 'noprofile ' +this.noprofile);
                 }
                this.showPrimaryExecutive = true;
            } else {
                this.showPrimaryExecutive = false;
                this.profilePicture = this.noprofile;
            }
            console.log('Primary Executive' + JSON.stringify(data));
            console.log('Primary executive data = ' + this.primaryExecutive);

        }
        if (error) {
            console.log('Error' + JSON.stringify(error));

        }
    }
    
 /*userCheck(){
     getContactDetails({ userId: USER_ID})
            .then((result)=>{
                console.log({result});
                     this.roleId = result.Role__c;
                     console.log('this.roleId-->',this.roleId);
                     if(this.roleId != undefined && this.roleId != null ){
                        this.roleProductMapping(this.roleId);
                        this.getproduct(this.roleId);
                    }
            })
            .catch((error) => {
                console.log(' User Calling Error'+JSON.stringify(error));
            });
            console.log('userdata---'+this.roleId);
    }*/
    handlerOnclickProduct(event){
        this.prodId = event.currentTarget.dataset.id;
        alert(this.prodId);
        let toNavigateUrl = '/librarydetails?recordId='+`${this.prodId}`;
        console.log('entered')
        this.navigateToNewRecordPage(toNavigateUrl);
    }

    navigateToNewRecordPage(url) {
        console.log('toNavigateUrl=='+url);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

  /* getproduct(){
        getprodcuctcount()
            .then((result)=>{
                console.log('userdata27---'+JSON.stringify(result));
                     this.prodcountData = result
            })
            .catch((error) => {
                console.log(' User Calling Error27'+JSON.stringify(error));
            });
            console.log('userdata---'+this.roleId);
    }*/

    navigatepage(event){
        
        var getnameval = event.currentTarget.dataset.name;

        if (getnameval == 'ProductList') {
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                    name: 'Productlistpage__c',
                    url: '/s/product-list-page'
                },
            });
        } else if (getnameval == 'Library') {
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                    name: 'library__c',
                    url: '/s/library'
                },
            });
        }
         else if (getnameval == 'MyContacts') {
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                    name: 'mycontacts__c',
                    url: '/s/my-contacts'
                },
            });
        } else if (getnameval == 'Librarydetail') {
            var recId = event.currentTarget.dataset.id;
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                type: 'standard__webPage',
                attributes: {
                    name: 'detail__c',
                    url: '/s/library/detail'+'?recordId='+recId
                }
                // state: {
                //     recordId: recId
                // }
            });
        } else {
            console.log('else');
        }
        
    }

    handleClick(event){        
        let btnName = event.currentTarget.dataset.name;
        if(btnName == 'phone'){
            this.fireDataClickEvent('link','','phone_primary','','mycontacts__c','/my-contacts');
        }else if (btnName == 'email'){
            this.fireDataClickEvent('link','','email_primary','','mycontacts__c','/my-contacts');
        }
        
    }

    handlenavigatedashboard(event){
        this.fireDataClickEvent('top_nav_breadcrumb','','Dashboard','navigation','',this.navigatedashboard);   
    }

    //Google Analytics Event
    fireDataClickEvent(category, action, label, module,linkedtext,linkedurl) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {
             detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: 'contact',
                page_purpose:'contact',
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
                page_title: 'my-contacts',

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
                    data_design_category: '',
                    data_design_action: '',
                    data_design_label: '',
                    data_design_module:'',       
                    page_type: 'contact',
                    page_purpose:'contact',
                    page_audience: 'payor',
                    page_marketname: 'united_states',
                    page_region: 'us',
                    page_contentclassification: 'non-commercial',
                    link_text:'mycontacts__c',
                    link_url:'/my-contacts',
                    content_saved:'',
                    content_appointments:'',
                    content_requests:'',
                    content_name:'',
                    page_localproductname: '',
                    content_count:'',
                    sfmc_id: USER_ID,
                    sfmc_audience:this.contactrole,
                    page_url: location.href,
                    page_title: 'my-contacts',                 
            },
            bubbles: true,
            composed: true
        }));
    }
    hasProfilePicture(photourl){
        if(photourl.indexOf('/profilephoto/005/F')>-1){
            return false;
        }else{
            return true;
        }
    }
    hasPhoneNumber(phoneNumber){
        if(phoneNumber===null){
            return false;
        }

        return true;

    }
    hasEmail(email){
        if(email===null){
            return false;
        }

        return true;

    }
    //  <!-- Mukesh -->
     getFormattedPhnNumber(phnNumber){
         
       let formattedNumber="tel:";
       formattedNumber+=phnNumber;
       console.log('EVENT TRIGGERED Recent chnages '+ formattedNumber );
       return formattedNumber;
       
     }
     //  <!-- Mukesh -->

     getFormattedEmail(email){
       let formattedemail="mailto:";
       formattedemail+=email;
       console.log('EVENT TRIGGERED Recent chnages '+ formattedemail );
       return formattedemail;
       
     }
}