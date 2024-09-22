import { LightningElement, wire, track } from 'lwc';
import imgpopup from '@salesforce/resourceUrl/imgpopup';
import avtar from '@salesforce/resourceUrl/avtar'
import firstimg from '@salesforce/resourceUrl/firstimg'
import secimg from '@salesforce/resourceUrl/secimg'
import phone from '@salesforce/resourceUrl/msd_phone'
import email from '@salesforce/resourceUrl/msd_email'
import noprofile from '@salesforce/resourceUrl/noprofile';
import getPrimaryExecutive from '@salesforce/apex/MSD_CORE_Dashboard.getPrimaryExecutive';
import USER_ID from "@salesforce/user/Id";
import arrow from '@salesforce/resourceUrl/rightarrow2';
import { NavigationMixin } from 'lightning/navigation';
import whitearrow from '@salesforce/resourceUrl/whitearrow';
import crossmark from '@salesforce/resourceUrl/cross';
import RightTopArrow from '@salesforce/resourceUrl/RightTopArrow';
import getEnableDisease from '@salesforce/apex/MSD_CORE_Dashboard.getEnableDisease';

import MSD_CORE_MedicalInfo_Url from '@salesforce/label/c.MSD_CORE_MedicalInfo_Url';
import MSD_CORE_MedicalSettings_Url from '@salesforce/label/c.MSD_CORE_MedicalSettings_Url';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import larrow from '@salesforce/resourceUrl/larrow';
import navigationarrow from '@salesforce/resourceUrl/navigationarrow';
import HeaderArrow from '@salesforce/resourceUrl/menuarrownew';
import domainurl from '@salesforce/label/c.MSD_CORE_Domain_URL';

import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';

export default class MSD_CORE_Menu extends NavigationMixin(LightningElement) {
    imgpopup = imgpopup;
    avtar = avtar;
    domainurl = domainurl;
    firstimg = firstimg;
    secimg = secimg;
    phone = phone;
    email = email;
    noprofile=noprofile;
    primaryExecutive;
    warrow = whitearrow;
    cross = crossmark;
    showExternalSiteWarning = false;

    @track datasetidval;
    @track contactrole = '';
    @track diseaseEnable = false;
    righttoparrow = RightTopArrow;

    leftarrow = larrow;         //For Mobile Screen
    navarrow = navigationarrow;         //For Mobile Screen
    @track showResponse = false;     //For Mobile Screen
    HeaderArrow = HeaderArrow;   //For Mobile Screen
    cross = crossmark;  //For Mobile Screen 
    
    @track siteAPINames;
    @track siteNames;

    connectedCallback() {
        sessionStorage.setItem("SFMC_ID",USER_ID );
        this.contactrole = sessionStorage.getItem("SFMC_Audience");
        this.fireOnLoadEvent();

    }    
    Showpopup() {

        this.showResponse = true;
    }

    @wire(getPrimaryExecutive, { userId: USER_ID })
    wiredPrimaryExecutive({ error, data }) {
        console.log({ data });
        if (data) {
             this.primaryExecutive = data.map(row => ({
                    ...row,
                    Email: this.getEmailBody(row.Email),
                    fullPhotoURL:row.FullPhotoUrl,   //mukesh
                    MediumPhotoUrl:row.MediumPhotoUrl,  //mukesh 
                    primaryemail: this.getprimaryemail(row.Email),
                    isPicturePresent:this.hasProfilePicture(row.FullPhotoUrl),
                    formatNumber:this.getFormattedPhnNumber(row.Phone), 
                formatEmail:this.getFormattedEmail(row.Email),
                isPhoneAvailable:this.hasPhoneNumber(row.Phone),
                isEmailAvailable:this.hasEmail(row.Email) 
                }));
            if (this.primaryExecutive.length > 0) {
                this.showPrimaryExecutive = true;
            } else {
                this.showPrimaryExecutive = false;
            }
            console.log('Primary Executive' + JSON.stringify(data));
            console.log('Primary executive data = ' + this.primaryExecutive);
        }
        if (error) {
            console.log({ error });
        }
    }

    @wire(getEnableDisease)
        WiredgetEnableDisease({error, data}) {
        console.log('getEnableDisease : ',{data});
        console.log({error});
        if (data) {
            this.diseaseEnable = data;
            console.log('diseaseEnable',this.diseaseEnable);
        }
        if (error) {
            console.log({error});
        } 
     }

    hasProfilePicture(photourl){
        if(photourl.indexOf('/profilephoto/005/F')>-1){
            return false;
        }else{
            return true;
        }
    }

    handlegaevent(event){
        let lablname = event.currentTarget.dataset.name;
        if(lablname == 'phone'){
            this.fireDataLayerEvent('link', '', 'phone',  '', 'Menu__c', '/menu');
        }else if(lablname == 'email'){
            this.fireDataLayerEvent('link', '', 'email',  '', 'Menu__c', '/menu');
        }
         
    }
    getprimaryemail(email) {
        this.primaryemail=email;
        // let emailval = email; //R4
        // var width = screen.width;
        // let emailname = emailval.substring(0, emailval.lastIndexOf("@"));
        // let domain = emailval.substring(emailval.lastIndexOf("@") + 1);
        // console.log('Email--> ' + emailname);
        // console.log('Email--> ' + domain);
        
        // if (width < 768) {
        //     if (emailname.length >= 8) {
        //         let newemailname = emailname.substring(0, 5) + '...' + '@' + domain;
        //         let emailprefix = newemailname.substring(0,newemailname.indexOf('.com') );
        //         this.primaryemail = emailprefix+'.com';
        //         console.log('newemailname' + newemailname);
        //     }
        //     else {
        //         this.primaryemail = email;
        //         let emailprefix =  this.primaryemail.substring(0, this.primaryemail.indexOf('.com') );
        //         this.primaryemail = emailprefix+'.com';
        //     }
        // }
        // else{
        //     if (emailname.length >= 20) {
        //         let newemailname = emailname.substring(0, 18) + '...' + '@' + domain;
        //         this.primaryemail = newemailname;
        //         let emailprefix =  this.primaryemail.substring(0, this.primaryemail.indexOf('.com') );
        //         this.primaryemail = emailprefix+'.com';
        //         console.log('newemailname' + newemailname);

        //         var width = screen.width;
        //         console.log('OUTPUT : ', width);
        //     }
        //     else {
        //         this.primaryemail = email;
        //         let emailprefix =  this.primaryemail.substring(0, this.primaryemail.indexOf('.com') );
        //         this.primaryemail = emailprefix+'.com';
        //     }
        // }
        return this.primaryemail;
    }
   

    getEmailBody(emailfieldval) {
                 
        var emailval=emailfieldval;
        var width = screen.width;
        var emailname   = emailval.substring(0, emailval.lastIndexOf("@"));
        var domain = emailval.substring(emailval.lastIndexOf("@") +1);
        console.log('Email--> '+emailname);
        console.log('Email--> '+domain);        
        var finalemail;                    
        if (width < 768) {
            if(emailname.length>=8)
            {
                let newemailname=emailname.substring(0,5)+'...'+'@'+domain;  
                this.primaryemail=newemailname;
                finalemail = newemailname;                                                        
            }
            else
            {
                this.primaryemail=emailname;                
                finalemail =  emailval;                
            }
        }
        else{
            if(emailname.length>=25)
            {
                let newemailname=emailname.substring(0,21)+'...'+'@'+domain;  
                this.primaryemail=newemailname;
                finalemail = newemailname;                                            
            }
            else
            {
                this.primaryemail=emailval;
                finalemail = emailval;
            }
        }
        console.log({finalemail});                            
        return finalemail;
                
    }    

    // For getting all Sites API Name and Url
    @wire(getAllSiteNameAndAPINames)
    WiredgetSiteNameAndAPIName({error, data}) {
        console.log({data});
        console.log({error});
        if (data) {
            this.siteAPINames = data.siteAPINames;
            this.siteNames = data.siteNames;
        }
        if (error) {
            console.log({error});
        } 
    }

    handleNavigation(event) {
        let navigation = event.currentTarget.dataset.id;
        switch (navigation) {
            case 'dashboard':
                this.fireDataLayerEvent('top_nav_primary', '', 'dashboard',  'navigation', this.siteNames.Dashboard, this.siteAPINames.Dashboard); //Event Added
                this.navigation(this.siteAPINames.Dashboard, this.siteNames.Dashboard);
                break;
            case 'mhee':
               // this.fireDataLayerEvent('top_nav_primary', '', 'mhee',  'navigation', this.siteNames.Dashboard, this.siteAPINames.Dashboard); //Event Added
                this.fireDataLayerEvent('button', '', 'return to mhee portal',  'modal', 'Home', '/'); //Event Added
                this.navigation(this.siteAPINames.Dashboard, this.siteNames.Dashboard);
                break;    
            case 'pipeline':
                this.fireDataLayerEvent('top_nav_primary', '', 'pipeline', 'navigation', this.siteNames.Pipeline, this.siteAPINames.Pipeline); //Event Added
                this.navigation(this.siteAPINames.Pipeline, this.siteNames.Pipeline);
                break;
            case 'settings':
                this.showExternalSiteWarning = true;
                this.datasetidval = 'medicalsettings';
                this.fireDataLayerEvent('top_nav_primary', '', 'settings',  'navigation', this.datasetidval, this.datasetidval); //Event Added
                break;
            case 'medicalinfo':
                //window.open('https://www.merckmedicalportal.com/s/medical-information', '_blank');
                this.datasetidval = 'medicalinfonavigate';
               this.showExternalSiteWarning = true;
               this.fireDataLayerEvent('top_nav_primary', '', 'medicalinfo',  'navigation', this.datasetidval, this.datasetidval); //Event Added
                break;
            case 'medicalinfonavigate':
                //this.fireDataLayerEvent('top_nav_primary', '', 'medicalinfonavigate', 'navigation', MSD_CORE_MedicalInfo_Url, MSD_CORE_MedicalInfo_Url); //Event Added
                this.fireDataLayerEvent('button', '', 'medical information', 'modal', MSD_CORE_MedicalInfo_Url, MSD_CORE_MedicalInfo_Url); //Event Added
                window.open(MSD_CORE_MedicalInfo_Url, '_blank');
                break;
            case 'medicalsettings':
                //this.fireDataLayerEvent('top_nav_primary', '', 'medicalsettings',  'navigation', MSD_CORE_MedicalInfo_Url, MSD_CORE_MedicalSettings_Url); //Event Added
                this.fireDataLayerEvent('button', '', 'account settings',  'modal', MSD_CORE_MedicalInfo_Url, MSD_CORE_MedicalSettings_Url); //Event Added
                window.open(MSD_CORE_MedicalSettings_Url, '_blank');
                break;
            case 'disease':
                this.fireDataLayerEvent('top_nav_primary', '', 'disease', 'navigation', this.siteNames.DiseaseInformation, this.siteAPINames.DiseaseInformation); //Event Added
                this.navigation(this.siteAPINames.DiseaseInformation, this.siteNames.DiseaseInformation);
                break;
            case 'request':
                this.fireDataLayerEvent('top_nav_primary', '', 'request', 'navigation', this.siteNames.RequestAppointment, this.siteAPINames.RequestAppointment); //Event Added
                this.navigation(this.siteAPINames.RequestAppointment, this.siteNames.RequestAppointment);
                break;
            default:
                break;
        }
        

    }
    navigation(name, url) {
        this[NavigationMixin.Navigate]({
            // type: 'comm__namedPage',
            type: 'standard__webPage',
            attributes: {
                name: name,
                url: url
            }
        });
    }

    closeResponse(event){
        this.showExternalSiteWarning=false;
        this.fireDataLayerEvent('button', '', 'back to screen_X',  'modal', 'Menu__c', '/menu'); 
    }

    closeResponse() {
        this.showResponse = false;
    }
    closeResponse1(){
        this.showExternalSiteWarning=false;
    }
    handleHealthEconomicEvidence(){
        window.open(this.domainurl + '/dashboard', "_blank");
    } 

   fireDataLayerEvent(category, action, label,module,linkedtext, linkedurl) {
        console.log('event triggered');
       this.dispatchEvent(new CustomEvent('datalayereventmodule', {
          
           detail: {               
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module:module,
                page_type: 'menu',
                page_purpose:'site navigation',
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
                    data_design_category: '',
                    data_design_action: '',
                    data_design_label: '',
                    data_design_module:'', 
                    page_type: 'menu',
                    page_purpose:'site navigation',
                    page_audience: 'payor',
                    page_marketname: 'united_states',
                    page_region: 'us',
                    page_contentclassification: 'non-commercial',
                    link_text:'Menu__c',
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