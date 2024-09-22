import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import newlogo2 from '@salesforce/resourceUrl/banner';
import newlogo6 from '@salesforce/resourceUrl/active2';
import newlogo7 from '@salesforce/resourceUrl/rightarrow2';
import newlogo9 from '@salesforce/resourceUrl/downarrow';
import uparrow from '@salesforce/resourceUrl/uparrowicon';
import getCatalogPerProdSaved from '@salesforce/apex/MSD_CORE_ProductList.getCatalogPerProdSaved';
import document from '@salesforce/resourceUrl/calender';
import cntuser from '@salesforce/resourceUrl/contact2';
import accounticon from '@salesforce/resourceUrl/account';
import personicon from '@salesforce/resourceUrl/personicon';//Rusheel
import phoneicon from '@salesforce/resourceUrl/phone';
import messageicon from '@salesforce/resourceUrl/MSD_CORE_Message';
import bookicon from '@salesforce/resourceUrl/booknew';
import warrow from '@salesforce/resourceUrl/whitearrow';
import accountmanagement from '@salesforce/label/c.MSD_CORE_AccountManagement';
import accountdesg from '@salesforce/label/c.MSD_CORE_AccountManagementDesg';
import accountphone from '@salesforce/label/c.MSD_CORE_AccountManagementPhone';
import accountmail from '@salesforce/label/c.MSD_CORE_AccountManagementEmail';
import noprofile from '@salesforce/resourceUrl/noprofile';
import newgetproductlist from '@salesforce/apex/MSD_CORE_ProductList.newgetproductlist';
import newgetproductlistActive from '@salesforce/apex/MSD_CORE_ProductList.newgetproductlistActive';
import USER_ID from "@salesforce/user/Id";
import getPrimaryExecutive from '@salesforce/apex/MSD_CORE_ProductList.getPrimaryExecutive';

import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import getAllSiteNameAndAPINames from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getAllSiteNameAndAPINames';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';
import getNextDate from '@salesforce/apex/MSD_CORE_RedirectController.getNextDate';

export default class Dashboardall extends NavigationMixin(LightningElement) {

    @api recordId;
    exeContacts = [];
    AE = { accountmanagement, accountdesg, accountphone, accountmail };

    noprofile = noprofile;
    logo5 = newlogo2;               //Banner image
    logo7 = newlogo6;               //Active icon
    logo8 = newlogo7;               //Arrow icon
    logo10 = newlogo9;               //Down Arrow icon

    docicon = document;             //Calender icon
    cntuser = cntuser;              //User icon
    accounticon = accounticon;
    phoneicon = phoneicon;          //Phone icon
    messageicon = messageicon;      //Message icon
    bookicon = bookicon;            //Browse icon
    warrow = warrow;                //White arrow icon
    personicon = personicon;
    products = [];                       //Products
    savedcon;                       //Saved Contact
    error;
    roleId;                         //Role Id
    userid = USER_ID;               //User id

    uparrowimg = uparrow;
    norecord = false;
    norecordlib = false;
    showPrimaryExecutive = false;
    primaryExecutive = [];
    @track primaryemail = '';
    proddata = [];
    products2 = [];
    showmore = false;
    showmore1 = false;

    actprod = [];
    actprod2 = [];
    @track showmoredisp = false;
    @track showmoredisp1 = false;

    nodatate = false;

    @track prodlstpage;
    @track prodlstpageapi;
    @track librarypage;
    @track librarypageapi;
    @track myContactspage;
    @track myContactspageapi;
    @track librarydetailpage;
    @track librarydetailpageapi;
    @track appointmentpage;
    @track appointmentpageapi;
    @track requestpage;
    @track requestpageapi;
    @track settingurl;
    @track settingapi;
	  @track showInfocard = false;
    @track pageName = ''
    @track contactrole = '';

    // // constructor
    // constructor() {
    //     super();
    //     console.log('Constructor');
    // }

    // Called when Page is loaded
    connectedCallback() {
        sessionStorage.setItem("SFMC_ID", USER_ID);
        console.log('COnnected Callback');
        // console.log(this.AE.accountmail);

        // this.fireOnLoadEvent();

        this.getsitename();
        // this.pageviewevents();
    }

    getsitename() {


        getSiteNameAndAPIName({ pageName: 'ProductList' })
            .then((result) => {
                this.prodlstpage = result.siteAPIName;
                this.prodlstpageapi = result.siteName;
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
        getSiteNameAndAPIName({ pageName: 'Library' })
            .then((result) => {
                this.librarypage = result.siteAPIName;
                this.librarypageapi = result.siteName;
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
        getSiteNameAndAPIName({ pageName: 'MyContacts' })
            .then((result) => {
                this.myContactspage = result.siteAPIName;
                this.myContactspageapi = result.siteName;
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
        getSiteNameAndAPIName({ pageName: 'Librarydetail' })
            .then((result) => {
                this.librarydetailpage = result.siteAPIName;
                this.librarydetailpageapi = result.siteName;
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
        getSiteNameAndAPIName({ pageName: 'Appointment' })
            .then((result) => {
                this.appointmentpage = result.siteAPIName;
                this.appointmentpageapi = result.siteName;
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
        getSiteNameAndAPIName({ pageName: 'Request' })
            .then((result) => {
                this.requestpage = result.siteAPIName;
                this.requestpageapi = result.siteName;
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
    }

    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        console.log({ value });
        const { data, error } = value;
        if (data) {
            console.log({ data });
            this.contactrole = data;
        }
        if (error) {
            console.log({ error });
        }
    }

    @wire(newgetproductlistActive, { userId: USER_ID })
    // @wire(newgetproductlist, {userId : '0057X0000044lyIQAQ'})
    wiredgetProducts2(value) {

        console.log('Get Product2');
        console.log({ value });
        const { data, error } = value;
        // console.log('data.condata.length-->',data.condata.length);
        if (data != undefined) {
            this.norecord = false;
            console.log('1st', this.norecord);
            console.log({ data });
            this.proddata = data;
            // this.products = data.condata;

            for (var key in data.condata) {
                console.log({ key });
                //  console.log('2 data.condata[key].Meeting_Requests__r-->',data.condata[key].Meeting_Requests__r);
                // if (key <= 2) {
                if (this.actprod.length < 3) {
                    if (data.condata[key].Libraries__r) {
                        // this.products.push(data.condata[key]);
                    }
                    if (data.condata[key].Meeting_Requests__r) {
                        this.actprod.push(data.condata[key]);
                    }
                    // }else if(key >= 3 || key <= 6){
                } else if (this.actprod.length >= 3) {
                    if (data.condata[key].Libraries__r) {
                        //   this.products2.push(data.condata[key]);
                    }
                    if (data.condata[key].Meeting_Requests__r) {
                        this.actprod2.push(data.condata[key]);
                    }
                }
            }
            //  console.log('this.products==>',this.products);
            // console.log('this.products2==>',this.products2);
            console.log('2 this.actprod2==>', this.actprod);
            console.log('2 this.actprod2==>', this.actprod2);

            // if (this.products2.length >0) {
            //    this.showmoredisp = true;
            //   }
            if (this.actprod2.length > 0) {
                this.showmoredisp1 = true;
                //Added by Sabari - : [MFRUS-117] Prescribing Information link update
                let actvrecords =  JSON.parse(JSON.stringify(this.actprod2))
                actvrecords.forEach(obj =>{
                    if(obj.hasOwnProperty("MSD_CORE_Product_Description__c") && obj.hasOwnProperty("MSD_CORE_Prescribing_Information__c")){
                        if(obj.MSD_CORE_Prescribing_Information__c){
                            if(obj.MSD_CORE_Product_Description__c.toLowerCase().includes("prescribing information"))
                            {
                                let modifiedDescription = obj.MSD_CORE_Product_Description__c.replace(/Prescribing Information/i,"<a style='color:#333333;' target='_blank' href='"+obj.MSD_CORE_Prescribing_Information__c+"'><u>Prescribing Information</u></a>");
                                obj.MSD_CORE_Product_Description__c = modifiedDescription;
                            }
                        }
                   }
                });
                this.actprod2 = [...actvrecords];
            }
            else {
                this.showmoredisp1 = false;
            }

            this.savedcon = data.savedcount;
            console.log('2 saved count' + this.savedcon);
            // console.log('data.condata.Libraries__r.length-->'+data.condata.Libraries__r.length);
            console.log('2 data.condata.length-->' + JSON.stringify(data.condata));
            if (data.length == 0) {
                this.norecord = true;
                console.log('2nd', this.norecord);
            }
            if (data == undefined || this.actprod.length == 0) {
                this.norecord = true;
                console.log('3rd', this.norecord);
            }
            else {
                //Added by Sabari - : [MFRUS-117] Prescribing Information link update
                let actvrecords =  JSON.parse(JSON.stringify(this.actprod))
                actvrecords.forEach(obj =>{
                    if(obj.hasOwnProperty("MSD_CORE_Product_Description__c") && obj.hasOwnProperty("MSD_CORE_Prescribing_Information__c")){
                        if(obj.MSD_CORE_Prescribing_Information__c){
                            if(obj.MSD_CORE_Product_Description__c.toLowerCase().includes("prescribing information"))
                            {
                                let modifiedDescription = obj.MSD_CORE_Product_Description__c.replace(/Prescribing Information/i,"<a style='color:#333333;' target='_blank' href='"+obj.MSD_CORE_Prescribing_Information__c+"'><u>Prescribing Information</u></a>");
                                obj.MSD_CORE_Product_Description__c = modifiedDescription;
                            }
                        }
                   }
                });
                this.actprod = [...actvrecords];
                this.norecord = false;
                console.log('4th', this.norecord);
            }
        } else if (error) {
            console.log({ error });
        } else if (data == undefined) {
            console.log('2 undefined');
            this.norecord = true;
            console.log('5th', this.norecord);
        }

    }
    @wire(newgetproductlist, { userId: USER_ID })
    // @wire(newgetproductlist, {userId : '0057X0000044lyIQAQ'})
    wiredgetProducts(value) {
        console.log('Get Product');
        console.log({ value });
        const { data, error } = value;
        // console.log('data.condata.length-->',data.condata.length);
        if (data != undefined) {
            this.norecordlib = false;
            console.log('6th', this.norecordlib);
            console.log({ data });
            this.proddata = data;
            // this.products = data.condata;

            for (var key in data.condata) {
                console.log({ key });
                // console.log('data.condata[key].Meeting_Requests__r-->',data.condata[key].Meeting_Requests__r);
                // if (key <= 2) {
                if (this.products.length < 3) {
                    if (data.condata[key].Libraries__r) {
                        this.products.push(data.condata[key]);
                    }

                    //  if (data.condata[key].Meeting_Requests__r) {
                    //    this.actprod.push(data.condata[key]);
                    // }
                    // }else if(key >= 3 || key <= 6){
                } else if (this.products.length >= 3) {
                    if (data.condata[key].Libraries__r) {
                        this.products2.push(data.condata[key]);
                    }
                    // if (data.condata[key].Meeting_Requests__r) {
                    //   this.actprod2.push(data.condata[key]);
                    //  }
                }
            }
            console.log('this.products==>', this.products);
            console.log('this.products2==>', this.products2);
            console.log('this.products==>', this.products.length);
            console.log('this.products2==>', this.products2.length);
            // console.log('this.actprod2==>',this.actprod);
            // console.log('this.actprod2==>',this.actprod2);

            if (this.products2.length > 0) {
                this.showmoredisp = true;
                //Added by Sabari - : [MFRUS-117] Prescribing Information link update
                let actvrecords =  JSON.parse(JSON.stringify(this.products2))
                actvrecords.forEach(obj =>{
                    if(obj.hasOwnProperty("MSD_CORE_Product_Description__c") && obj.hasOwnProperty("MSD_CORE_Prescribing_Information__c")){
                        if(obj.MSD_CORE_Prescribing_Information__c){
                            if(obj.MSD_CORE_Product_Description__c.toLowerCase().includes("prescribing information"))
                            {
                                let modifiedDescription = obj.MSD_CORE_Product_Description__c.replace(/Prescribing Information/i,"<a style='color:#333333;' target='_blank' href='"+obj.MSD_CORE_Prescribing_Information__c+"'><u>Prescribing Information</u></a>");
                                obj.MSD_CORE_Product_Description__c = modifiedDescription;
                            }
                        }
                   }
                });
                this.products2 = [...actvrecords];
            }
            else {
                this.showmoredisp = false;
            }
            //  if (this.actprod2.length >0) {
            //     this.showmoredisp1 = true;
            // }

            this.savedcon = data.savedcount;
            console.log('saved count' + this.savedcon);
            // console.log('data.condata.Libraries__r.length-->'+data.condata.Libraries__r.length);
            //    console.log('data.condata.length-->'+JSON.stringify(data.condata));
            console.log('data.condata.length-->' + JSON.stringify(data.condata).length);

            console.log("pproduct length", this.proddata.length);
            console.log(data);
            // console.log(data);
            if (data.length == 0) {
                this.norecordlib = true;
                console.log('7th', this.norecordlib);
            }
            if (data == undefined || this.products.length == 0) {
                this.norecordlib = true;
                console.log('8th New', this.norecordlib);
            }
            else {
                //Added by Sabari - : [MFRUS-117] Prescribing Information link update
                let actvrecords =  JSON.parse(JSON.stringify(this.products))
                actvrecords.forEach(obj =>{
                    if(obj.hasOwnProperty("MSD_CORE_Product_Description__c") && obj.hasOwnProperty("MSD_CORE_Prescribing_Information__c")){
                        if(obj.MSD_CORE_Prescribing_Information__c){
                            if(obj.MSD_CORE_Product_Description__c.toLowerCase().includes("prescribing information"))
                            {
                                let modifiedDescription = obj.MSD_CORE_Product_Description__c.replace(/Prescribing Information/i,"<a style='color:#333333;' target='_blank' href='"+obj.MSD_CORE_Prescribing_Information__c+"'><u>Prescribing Information</u></a>");
                                obj.MSD_CORE_Product_Description__c = modifiedDescription;
                            }
                        }
                   }
                });
                this.products = [...actvrecords];
                this.norecordlib = false;
                console.log('9th', this.norecordlib);
            }
        } else if (error) {
            console.log({ error });
        } else if (data == undefined) {
            console.log('undefined');
            this.norecordlib = true;
            console.log('10th', this.norecordlib);
        }

    }

    // @wire(activereq, {userId : USER_ID})
    // wiredactivereq(value){
    //     console.log('Get Activity');
    //     console.log({value});
    //     const { data, error } = value;

    //     if (data != undefined) {
    //         this.norecord = false;
    //         console.log({data});
    //         for(var key in data){
    //             console.log({key});
    //             if (key <= 2) {
    //                 this.actprod.push(data[key]);
    //             }else{
    //                 this.actprod2.push(data[key]);
    //             }
    //         }

    //         console.log('actprod-->',this.actprod);
    //         console.log('actprod 2-->',this.actprod2);
    //         if(data.length == 0){
    //             this.norecord = true;
    //         }
    //     }else if (error) {
    //         console.log({error});
    //     } else if(data == undefined){
    //         console.log('undefined');
    //         this.norecord = true;
    //     }
    // }

    @wire(getNextDate, {userId:USER_ID})
    wiredgetNextDate(value) {
        const { data, error } = value;
        if(data){
		    console.log('nextreviewdate==>',data[0].MSD_CORE_Next_Review_Date__c);
			const today = new Date();
			console.log('today==>',today);
			const targetDate = new Date(data[0].MSD_CORE_Next_Review_Date__c); 
			console.log('targetDate==>',targetDate);
			const timeDifference = targetDate.getTime() - today.getTime();
			console.log('timeDifference==>',timeDifference);
			const daysDifference = Math.floor(timeDifference / (1000 * 60 * 60 * 24));
			console.log('daysDifference==>',daysDifference);			
			if (daysDifference <= 10) { 
				console.log("The target date is exactly 10 days from today.");
				this.showInfocard = true;
			    console.log('showInfocard==>',this.showInfocard);
				 }
            console.log('dataaccount',data);
			console.log('showInfocard==>',this.showInfocard);				
        }
        else if(error){
            console.log(error);
        }
    }
    @wire(getAllSiteNameAndAPINames)
    async WiredgetSiteNameAndAPIName({ error, data }) {
        console.log('login mheee--->', { data });
        console.log('settingurl>>>', data.siteAPINamesdebuglog.setting);
        console.log('settingApi>>>', data.siteNames.setting);
        this.settingurl = data.siteAPINamesdebuglog.setting;
        this.settingapi = data.siteNames.setting;

        console.log({ error });
        if (data) {
            this.siteName = data.siteAPINamesdebuglog;
            this.siteApiName = data.siteNames;
        }
        if (error) {
            console.log({ error });
        }
    }
    handleUpdate(){
            location.href = this.settingurl + '?tab=2';
            this.fireDataLayerEvent('button', '', 'update', 'horizontal', 'settings__c', '/settings', '');
    }
    handlegaevent(event){
        let btnName = event.currentTarget.dataset.name;
        if(btnName == 'phone'){
            this.fireDataLayerEvent('link', '', 'phone', 'horizontal', 'Dashboard__c', '/dashboard', '');
        }else if(btnName == 'email'){
            this.fireDataLayerEvent('link', '', 'email', 'horizontal', 'Dashboard__c', '/dashboard', '');
        }
    }

    showmoreclk() {
        this.showmore = true;
    }
    showlessclk() {
        this.showmore = false;
    }
    showmoreclk1() {
        console.log('Show more true');
        this.showmore1 = true;
    }
    showlessclk1() {
        this.showmore1 = false;
    }
    savedCountUpdate(event){

    }
    //saved count
    getCatalogPerProduct(productId) {
        getCatalogPerProdSaved({ recId: productId, userId: USER_ID })
            // getCatalogPerProdSaved({ recId: 'a8M7X0000004V6BUAU',userId:'0057X0000044lyIQAQ'})
            .then((result) => {

                this.savedcon = result.length;
                console.log(' this.savedcon--' + this.savedcon);

            })
            .catch((error) => {
                console.log(' Error in Get saved count 555' + JSON.stringify(error));
                this.error = error;
            });
    }
    @wire(getPrimaryExecutive, { userId: USER_ID })
    //  @wire(getPrimaryExecutive, {userId: '0057X0000044lyIQAQ'})
    wiredPrimaryExecutive({ error, data }) {
        console.log('-->wiredPrimaryExecutive<--');
        console.log({ data });

        if (data) {
            this.primaryExecutive = data.map(row => ({
                ...row,
                fullPhotoURL: row.FullPhotoUrl,
                MediumPhotoUrl: row.MediumPhotoUrl,
                isPicturePresent: this.hasProfilePicture(row.FullPhotoUrl),
                formatNumber:this.getFormattedPhnNumber(row.Phone), 
                formatEmail:this.getFormattedEmail(row.Email),
                isPhoneAvailable:this.hasPhoneNumber(row.Phone),
                isEmailAvailable:this.hasEmail(row.Email) 
            
                
            }));
            //  <!-- Mukesh 412/413/410-->

            console.log('Primary Executive' + JSON.stringify(data));
            if (this.primaryExecutive.length > 0) {
                console.log(this.primaryExecutive[0].Email.length);
                console.log(this.primaryExecutive[0].Email);
                this.primaryemail=this.primaryExecutive[0].Email;

                // let emailval = this.primaryExecutive[0].Email;

                // let width = screen.width;
                // let emailname = emailval.substring(0, emailval.lastIndexOf("@"));
                // let domain = emailval.substring(emailval.lastIndexOf("@") + 1);
                // console.log('Email--> ' + emailname);
                // console.log('Email--> ' + domain);
                // console.log("Phone recent change "+this.primaryExecutive[0].formatNumber);

                // if (width < 768) {
                //     if (emailname.length >= 8) {
                //         let newemailname = emailname.substring(0, 6) + '....' + '@' + domain;
                //         let emailprefix = newemailname.substring(0, newemailname.indexOf('.com'));
                //         this.primaryemail = emailprefix + '.com';
                //         console.log('newemailname' + newemailname);
                //     }
                //     else {
                //         this.primaryemail = this.primaryExecutive[0].Email;
                //         let emailprefix = this.primaryemail.substring(0, this.primaryemail.indexOf('.com'));
                //         this.primaryemail = emailprefix + '.com';
                //     }
                // }
                // else {
                //     if (emailname.length >= 20) {
                //         let newemailname = emailname.substring(0, 18) + '....' + '@' + domain;
                //         this.primaryemail = newemailname;
                //         let emailprefix = this.primaryemail.substring(0, this.primaryemail.indexOf('.com'));
                //         this.primaryemail = emailprefix + '.com';
                //         console.log('newemailname' + newemailname);
                //     }
                //     else {
                //         this.primaryemail = this.primaryExecutive[0].Email;
                //         let emailprefix = this.primaryemail.substring(0, this.primaryemail.indexOf('.com'));
                //         this.primaryemail = emailprefix + '.com';
                //     }
                // }

                this.showPrimaryExecutive = true;
            } else {
                this.showPrimaryExecutive = false;
            }
            console.log('Primary Executive' + JSON.stringify(data));
            console.log('Primary executive data = ' + this.primaryExecutive);

        }
        if (error) {
            console.log('Error' + JSON.stringify(error));

        }
    }
    hasProfilePicture(photourl) {
        if (photourl.indexOf('/profilephoto/005/F') > -1) {
            return false;
        }
        return true;
    }

    renderedCallback() {
        let mapWidth = this.template.querySelector('.con_div');
        console.log('height rendered call back' + JSON.stringify(mapWidth));
        if (mapWidth.style.height) {
            console.log('height' + mapWidth.style.height);
        }
        if (this.contactrole) {
            sessionStorage.setItem("SFMC_Audience", this.contactrole);
            this.fireOnLoadEvent();
        }
        //Added by Sabari - : [MFRUS-117] Prescribing Information link update
        let finddescelements = this.template.querySelectorAll('.activeprods');
        finddescelements.forEach((element)=>{
        const datavalue = element.getAttribute("data-value");
        if(datavalue!=null && datavalue != ''){
            console.log('inside rendered '+datavalue);
            element.innerHTML = '<b>'+datavalue+'</b>';
        }
        });
    }


    // Navigate Pages
    navigatepage(event) {

        let getnameval = event.currentTarget.dataset.name;
        console.log({ getnameval });
        console.log('event.currentTarget.dataset-->', event.currentTarget.dataset);


        let recId = '';
        let tabname = '';
        if (getnameval == 'Save') {
            recId = event.currentTarget.dataset.id;
            tabname = event.currentTarget.dataset.name;
        } else if (getnameval == 'Appointment') {
            recId = event.currentTarget.dataset.id;
            tabname = event.currentTarget.dataset.name;
        } else if (getnameval == 'Request') {
            recId = event.currentTarget.dataset.id;
            tabname = event.currentTarget.dataset.name;
        } else if (getnameval == 'Activity') {
            recId = event.currentTarget.dataset.id;
            tabname = event.currentTarget.dataset.name;
        }



        if (getnameval == 'ProductList') {
            this.fireDataLayerEvent('button', '', 'browse catalog', 'horizontal', this.prodlstpageapi, this.prodlstpage, '');
            if (this.prodlstpageapi != undefined && this.prodlstpage != undefined)
                this[NavigationMixin.Navigate]({
                    // type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: this.prodlstpageapi,
                        url: this.prodlstpage
                    },
                });
        } else if (getnameval == 'Library') {
            this.fireDataLayerEvent('button', '', 'view all library', 'vertical', this.librarypageapi, this.librarypage, ''); //RT-1053
            if (this.librarypageapi != undefined && this.librarypage != undefined)
                this[NavigationMixin.Navigate]({
                    // type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: this.librarypageapi,
                        url: this.librarypage
                    },
                });
        }
        else if (getnameval == 'MyContacts') {
            this.fireDataLayerEvent('button', '', 'view all contacts', 'vertical', this.myContactspageapi, this.myContactspage, '');
            if (this.myContactspageapi != undefined && this.myContactspage != undefined)
                this[NavigationMixin.Navigate]({
                    // type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: this.myContactspageapi,
                        url: this.myContactspage
                    },
                });
        } else if (getnameval == 'Save') {
            if (this.librarydetailpageapi != undefined && this.librarydetailpage != undefined)
                this.fireDataLayerEvent('button', '', 'library', 'vertical', this.librarydetailpageapi, this.librarydetailpage, event.currentTarget.dataset.prodname); //RT-1053
            this[NavigationMixin.Navigate]({
                // type: 'comm__namedPage',
                // attributes: {
                //     name: this.librarydetailpageapi,
                //     url: this.librarydetailpage
                // },
                // state: {
                //     recordId: recId,
                //     tab: tabname
                // }
                type: 'standard__webPage',
                attributes: {
                    name: this.librarydetailpageapi,
                    url: this.librarydetailpage + '?recordId=' + recId + '&tab=' + tabname
                }
            });
        }
        else if (getnameval == 'Appointment') {
            this.fireDataLayerEvent('button', '', 'appointments', 'vertical', this.appointmentpageapi, this.appointmentpage, '');
            if (this.appointmentpageapi != undefined && this.appointmentpage != undefined)
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        name: this.appointmentpageapi,
                        url: this.appointmentpage + '?recordId=' + recId + '&tab=' + tabname
                    }
                });
        }
        else if (getnameval == 'Request') {
            this.fireDataLayerEvent('button', '', 'view request', 'vertical', this.requestpageapi, this.requestpage, event.currentTarget.dataset.actprodname);  //RT-1053          
            if (this.requestpageapi != undefined && this.requestpage != undefined)
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        name: this.appointmentpageapi,
                        url: this.requestpage + '?recordId=' + recId + '&tab=' + tabname
                    }
                });
        }
        else if (getnameval == 'Activity') {
            if (this.requestpageapi != undefined && this.requestpage != undefined)
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        name: this.appointmentpageapi,
                        url: this.requestpage + '?recordId=' + recId + '&tab=' + tabname
                    }
                });
        }
    }
    //data
    fireDataLayerEvent(category, action, label, module, linkedtext, linkedurl, productname) {
        console.log('event triggered');
        this.dispatchEvent(new CustomEvent('datalayereventmodule', {

            detail: {
                data_design_category: category,
                data_design_action: action,
                data_design_label: label,
                data_design_module: module,
                page_type: 'homepage',
                page_purpose: 'homepage',
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
                page_localproductname: productname,
                sfmc_id: USER_ID,
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
                data_design_module: '',
                page_type: 'homepage',
                page_purpose: 'homepage',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: '',
                link_url: '',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'dashboard',
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