import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import newlogo2 from '@salesforce/resourceUrl/banner';
import newlogo6 from '@salesforce/resourceUrl/active2';
import newlogo7 from '@salesforce/resourceUrl/rightarrow2';
import document from '@salesforce/resourceUrl/calender';
import newlogo9 from '@salesforce/resourceUrl/downarrow';
import uparrow from '@salesforce/resourceUrl/uparrowicon';
import banner from '@salesforce/resourceUrl/PurpleBanner';
import mheedashpipeimg1 from '@salesforce/resourceUrl/mheedashpipeimg1';
import mheedashpipeimg2 from '@salesforce/resourceUrl/mheedashpipeimg2';
import whitearrow from '@salesforce/resourceUrl/whitearrow';
// import mheeearrowexp from '@salesforce/resourceUrl/mheeearrowexp';
import accounticon from '@salesforce/resourceUrl/account';
import usericon from '@salesforce/resourceUrl/MSD_CORE_Usericon';
import phone from '@salesforce/resourceUrl/MSD_CORE_Phone';
import bookicon from '@salesforce/resourceUrl/ActiveMHEE';
import noprofile from '@salesforce/resourceUrl/noprofile';
import message from '@salesforce/resourceUrl/MSD_CORE_Message';
import USER_ID from "@salesforce/user/Id";
import getPrimaryExecutive from '@salesforce/apex/MSD_CORE_Dashboard.getPrimaryExecutive';
import getAllConfigurations from '@salesforce/apex/MSD_CORE_Dashboard.getAllConfigurations';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MHEESitePageConfiguration.getAllSiteNameAndAPINames';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import mheedomain from '@salesforce/label/c.MSD_CORE_MHEE_Domain_URL';
import mfrportalurl from '@salesforce/label/c.MSD_CORE_Domain_URL';
import crossmark from '@salesforce/resourceUrl/cross';
import Mheecontactbanner from '@salesforce/resourceUrl/Mheecontactbanner';
import MHEEImages from '@salesforce/resourceUrl/MHEEImages';
import getActiveRequests from '@salesforce/apex/MSD_CORE_RequestController.getActiveRequestsTest'; 
import getMeetingsWrapper from '@salesforce/apex/MSD_CORE_RequestController.getMeetingRequestsWrapper';
const monthShortNames = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

export default class MSD_CORE_Dashboard extends NavigationMixin(LightningElement) { 
    docicon = document;             //Calender icon
    uparrowimg = uparrow;
    logo5 = newlogo2;               //Banner image
    logo7 = newlogo6;               //Active icon
    logo8 = newlogo7;               //Arrow icon
    logo10 = newlogo9;               //Down Arrow icon
    bannerimg = banner;
    cross = crossmark;
    mheedomain = mheedomain;
    MHEEImages = MHEEImages;
    Mheecontactbanner = Mheecontactbanner;
    mheedashpipeimg1 = mheedashpipeimg1;
    mheedashpipeimg2 = mheedashpipeimg2;
    warrow = whitearrow;
    book = bookicon;
    // mheeearrowexp = mheeearrowexp;
    accicon = accounticon;
    phoneicon = phone;
    messageicon = message;
    user = usericon;
    noprofile=noprofile
    mfrportalurl =mfrportalurl;
    @track primaryExecutive;
    @track showPrimaryExecutive = false;

    @track pipelinepage;
    @track pipelinepageapi;
    @track contactrole = '';
    @track configurations = [];
    @track showResponse = false;
    @track todaylist = false;
    @track currentmontlist = false;
    @track recordsToDisplay;
    @track listOne = [];
    @track listTwo = [];
    @track recordid;
    error;
    
    

    // @wire(getAllConfigurations)
    // wiredConfigurations({ error, data }) {
    //     if (data) {
    //         console.log('configurationsdata>>' + data);
    //         this.configurations = data;
    //         //this.configurations = [...data].sort((a, b) => a.index - b.index);
    //         console.log('configurationsdata11>>' + this.configurations);
    //         console.log('configurations>>' + JSON.stringify(this.configurations));
    //         this.error = undefined;
    //     } else if (error) {
    //         this.error = error;
    //         this.configurations = undefined;
    //     }
    // }

    @wire(getAllConfigurations)
    wiredConfigurations({ error, data }) {
        if (data) {
            this.configurations = data;
            this.configurations = data.map(config => {
                return {
                    ...config,
                    imagelink: `${MHEEImages}/MHEE images/${config.Image_link__c}`
                };
            });
            console.log('Updated configurations:', JSON.stringify(this.configurations));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.configurations = undefined;
        }
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

    // @wire(getActiveRequests)
    // WiredgetActiveRequests({ error, data }) {
    //     console.log('Active Request::::95 data', { data });
    //     console.log('Active Request::::', { error });
    //     if (data) {
    //         this.recordsToDisplay = data;
    //     }
    //     if (error) {
    //         console.log({ error });
    //     }
    // }

    // @wire(getMeetingsWrapper)
    // WiredgetMeetingsWrapper({ error, data }) {
    //     console.log('Active Request::::95 data', { data });
    //     console.log('Active Request::::', { error });
    //     if (data) {
    //         this.recordsToDisplay = data;
    //         console.log('recordsToDisplay>>' + this.recordsToDisplay);
    //         console.log('recordsToDisplay>>string' + JSON.stringify(this.recordsToDisplay));
    //     }
    //     if (error) {
    //         console.log({ error });
    //     }
    // }

    @wire(getMeetingsWrapper)
        wiredgetMeetingsWrapper({ error, data }) {
            if (data) {
               console.log('datawrapperapptmnts>>' + data);
               console.log('datawrapperapptmntsstring>>' + JSON.stringify(data));
            // this.listOne = data.map(row => ({
            //     ...row,
            //     blueback     : row.appointmentHeading == 'Today' ? 'backseccls1' : 'backseccls',
            //     resourcecls  : row.appointmentHeading == 'Today' ? 'resourcecls1' : 'resourcecls',
            //     aecls        : row.appointmentHeading == 'Today' ? 'aecls1' : 'aecls',
            //     todaydatecls : row.appointmentHeading == 'Today' ? 'datebackcls' : '',
            //     day          : this.getDay(row.appointmentDetails.appdate),
            //     month        : this.getMonth(row.appointmentDetails.appdate),
            //     restitle     : row.appointmentDetails.title
            // }));

            this.listOne = data.map(row => {
            // Map each appointment detail to extract day, month, and title
            const appointmentDetails = row.appointmentDetails.map(detail => ({
                ...detail,
                day: this.getDay(detail.appdate),
                month: this.getMonth(detail.appdate),
                time: this.getTimeValueSplit(detail.apptime),
                restitle: this.gettitle(detail.title),
                description1: detail.description
            }));

            return {
                ...row,
                blueback: row.appointmentHeading === 'Today' ? 'backseccls1' : 'backseccls',
                resourcecls: row.appointmentHeading === 'Today' ? 'resourcecls1' : 'resourcecls',
                aecls: row.appointmentHeading === 'Today' ? 'aecls1' : 'aecls',
                todaydatecls: row.appointmentHeading === 'Today' ? 'datebackcls' : 'datebackcls1',
                appointmentDetails // Updated appointmentDetails with day, month, and restitle
            };
        });
               console.log('listOne>>' + JSON.stringify(this.listOne));

                this.error = undefined;
            } else if (error) {
                console.log({ error });
            }
        }

    get hasData() {
        return this.listOne && this.listOne.length > 0;
    }
    
    
    gettitle(title) {
        if (!title) return ''; 
        const titleList = title.split(',');
        return titleList[0].trim();
    }

    getDay(date) {
        let d = new Date(date);
        return d.getDate();
    }

    getMonth(date) {
        let d = new Date(date);
        return monthShortNames[d.getMonth()];
    }

    getTimeValueSplit(strTime) {
        let timeval = strTime;
        if(timeval.endsWith('AM')){
            timeval = timeval.slice(0, -2);
            timeval = timeval+ ' AM';
        }
        if(timeval.endsWith('PM')){
            timeval = timeval.slice(0, -2);
             timeval = timeval+ ' PM';
        }
        return timeval;
    } 

    onallresources(){
        window.open(this.mheedomain + '/all-resources');
    }

    @wire(getPrimaryExecutive, { userId: USER_ID })
    wiredPrimaryExecutive({ error, data }) {
        console.log({ data });
        if (data) {
            this.primaryExecutive = data.map(row => ({
                    ...row,
                    Email: this.getEmailBody(row.Email),
                    fullPhotoURL: row.FullPhotoUrl, //<!--Mukesh-->
                    MediumPhotoUrl: row.MediumPhotoUrl, //<!--Mukesh-->
                    primaryemail: this.getprimaryemail(row.Email),
                    isPicturePresent:this.hasProfilePicture(row.FullPhotoUrl),
                    formatNumber:this.getFormattedPhnNumber(row.Phone), //<!--Mukesh-->
                formatEmail:this.getFormattedEmail(row.Email),//<!--Mukesh-->
                isPhoneAvailable:this.hasPhoneNumber(row.Phone),//<!--Mukesh-->
                isEmailAvailable:this.hasEmail(row.Email)//<!--Mukesh-->
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

    onlearnmore(){
       window.open(this.mfrportalurl + '/organic-learn-more?dashboard=no');
      // window.location.href = this.mfrportalurl + '/organic-learn-more?dashboard=no';
    }
    ongetstarted() {
        this.showResponse = true;
    }
    
    tabclick(event){
        this.recordid = event.currentTarget.dataset.recordid;
        window.open(this.mheedomain +'/requestappointment/requestdetail?recordId='+this.recordid);
    }

    onviewappslink(){
        window.open(this.mheedomain + '/requestappointment?tab=Pending');
    }

    closeResponse() {
        this.showResponse = false;
    }

    handleHealthEconomicEvidence(){
        window.open(this.mfrportalurl + '/dashboard');
    }

    handlegaevent(event){
       let buttonName = event.currentTarget.dataset.id;
       if (buttonName == 'phone'){
           this.fireDataLayerEvent('link','','phone','','Home','/');
       }else if (buttonName == 'email') {
           this.fireDataLayerEvent('link','','email','','Home','/');
       }
        
    }

    handleViewresource(event){
        let tabname = event.currentTarget.dataset.name;
        console.log('tabname>>' + this.tabname);
        if (tabname == 'Pipeline Information'){
            window.location.href = this.mheedomain + '/pipeline';
        } else if (tabname == 'Disease State Decks') {
            window.location.href = this.mheedomain + '/disease-information';
        } 
    }

    getprimaryemail(email) {

        this.primaryemail=email;

        //let emailval = email; //R4

        // var width = screen.width;
        // let emailname = emailval.substring(0, emailval.lastIndexOf("@"));
        // let domain = emailval.substring(emailval.lastIndexOf("@") + 1);
        // console.log('Email--> ' + emailname);
        // console.log('Email--> ' + domain);
        

        // if (width < 768) {
        //     if (emailname.length >= 8) {
        //         let newemailname = emailname.substring(0, 6) + '....' + '@' + domain;
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
        //         let newemailname = emailname.substring(0, 18) + '....' + '@' + domain;
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
                let newemailname=emailname.substring(0,6)+'....'+'@'+domain;  
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
                let newemailname=emailname.substring(0,21)+'....'+'@'+domain;  
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
            this.pipelinepageapi = data.siteAPINames.Pipeline;
            this.pipelinepage = data.siteNames.Pipeline;
        }
        if (error) {
            console.log({error});
        } 
    }

    connectedCallback(){ 
        console.log('Connected Call back');
        let scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
        }
        window.scrollTo(scrollOptions);
        
        var name = sessionStorage.getItem("Name");
        console.log({name});
        var user = sessionStorage.getItem("User");
        console.log({user});
        console.log('User Icon'+usericon );

        sessionStorage.setItem("SFMC_ID",USER_ID );
    }

    renderedCallback(){
        if(this.contactrole) {
            sessionStorage.setItem("SFMC_Audience",this.contactrole);
            this.fireOnLoadEvent();
        }
        console.log('contactrole>>' , this.contactrole);
    }   

    navigation(event){
        this.fireDataLayerEvent('button','','browse pipeline information','Horizontal',this.pipelinepageapi,this.pipelinepage);// RT-N-1053
        this[NavigationMixin.Navigate]({
            type:'standard__webPage',
            //type: 'comm__namedPage',
            attributes: {
                name: this.pipelinepageapi,
                url: this.pipelinepage
            },
        });
    }


    // Analytics Events
    fireDataLayerEvent(category, action, label,module,linkedtext, linkedurl) {
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
                page_localproductname:'',                
                sfmc_id:USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'dashboard',

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
                    page_type: 'homepage',
                    page_purpose:'homepage',
                    page_audience: 'payor',
                    page_marketname: 'united_states',
                    page_region: 'us',
                    page_contentclassification: 'non-commercial',
                    link_text:'Home',
                    link_url:'/merckmhee',
                    content_saved:'',
                    content_appointments:'',
                    content_requests:'',
                    content_name:'',
                    page_localproductname: '',
                    content_count:'',
                    sfmc_id: USER_ID,
                    sfmc_audience:this.contactrole,
                    page_url: location.href,
                    page_title: 'dashboard',  
            },
            bubbles: true,
            composed: true
        }));
    } //  <!-- Mukesh -->
    hasPhoneNumber(phoneNumber){
        if(phoneNumber===null){
            return false;
        }

        return true;

    } //  <!-- Mukesh -->
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