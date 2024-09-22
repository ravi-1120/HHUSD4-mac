import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import newlogo7 from '@salesforce/resourceUrl/rightarrow2';
import getproductlist from '@salesforce/apex/MSD_CORE_Notification.getProductList';
import updatenotification from '@salesforce/apex/MSD_CORE_Notification.updateNotification';
import USER_ID from "@salesforce/user/Id";
import jobcode from '@salesforce/label/c.nonbrandjobcode';
import getSiteNameAndAPIName from '@salesforce/apex/MSD_CORE_MFRSitePageConfiguration.getSiteNameAndAPIName';
import getContactRole from '@salesforce/apex/MSD_CORE_ProductList.getContactRole';

export default class Notification extends NavigationMixin(LightningElement) {

    label = { jobcode };
    @api recordId;
    exeContacts = [];
    logo8 = newlogo7;               //Arrow icon
    @track products = [];                       //Products
    savedcon;                       //Saved Contact
    error;
    roleId;                         //Role Id
    userid = USER_ID;               //User id
    norecord = false;
    @track contactrole = '';

    // Called when Page is loaded
    connectedCallback() {
        console.log('COnnected Callback');
        this.fireOnLoadEvent();
        this.getnotificationdata();
    }

    renderedCallback() {
        //Added by Sabari - : [MFRUS-117] Prescribing Information link update
        let finddescelements = this.template.querySelectorAll('.activeprods');
        finddescelements.forEach((element)=>{
        const datavalue = element.getAttribute("data-value");
        if(datavalue!=null && datavalue != ''){
            console.log('inside rendered '+datavalue);
            element.innerHTML = datavalue;
        }
        });
    }

    @wire(getContactRole, { userId: USER_ID })
    wiredgetContactRole(value) {
        console.log({ value });
        const { data, error } = value;
        if (data) {
            console.log({ data });
            this.contactrole = data;
            console.log('raviteja>>>>>', data);
        }
        if (error) {
            console.log({ error });
        }
    }

    // GET Notification Data USER Specified
    getnotificationdata() {
        console.log('<-------------getnotification-------------->');
        getproductlist({ userId: USER_ID })
            .then((result) => {
                console.log('<-----IN GET Notification----->');
                console.log({ result });
                console.log('RESUTL');

                if (result.size == 0) {
                    console.log('Null');
                    this.norecord = true;
                } else {
                    try {
                        let c = result;
                        for (let key in c) {
                            this.products.push({ value: c[key], key: key });
                        }
                    } catch (error) {
                        console.log({ error });
                    }
                }
                console.log(this.products);
                if (this.products.length == 0) {
                    this.norecord = true;
                } else {
                    this.norecord = false;
                    //Added by Sabari - : [MFRUS-117] Prescribing Information link update
                    let actvrecords =  JSON.parse(JSON.stringify(this.products))
                    console.log('actvrecords'+JSON.stringify(this.products));
                    actvrecords.forEach(obj =>{
                        if(obj.value.hasOwnProperty("proddesc") && obj.value.hasOwnProperty("prodpilink")){
                            if(obj.value.prodpilink){
                                if(obj.value.proddesc.toLowerCase().includes("prescribing information"))
                                {
                                    let modifiedDescription = obj.value.proddesc.replace(/Prescribing Information/i,"<a style='color:#333333;' target='_blank' href='"+obj.value.prodpilink+"'><u>Prescribing Information</u></a>");
                                    obj.value.proddesc = modifiedDescription;
                                }
                            }
                    }
                    });
                    this.products = [...actvrecords];
                }
            })
            .catch((error) => {
                console.log('<-----IN GET Notification ERROR----->');
                console.log({ error });
            })
    }

    // Redirect Page
    redirectpage(event) {
        let proddname = event.currentTarget.dataset.prod;
        console.log('Redirect Page');
        let name = event.currentTarget.dataset.name;
        console.log({ name });
        let prodId;
        let tabname;
        let labelval;
        if (name == 'Saved') {
            tabname = 'Save';
            labelval = 'Saved';
            prodId = event.currentTarget.dataset.id;
        } else if (name == 'Appointments') {
            tabname = 'Appointment';
            labelval = 'Appointments';
            prodId = event.currentTarget.dataset.id;
        } else if (name == 'Closed') {
            tabname = 'Closed';
            labelval = 'Closed';
            prodId = event.currentTarget.dataset.id;
        } else if (name == 'Activity') {
            tabname = 'Activity';
            labelval = 'Activity';
            prodId = event.currentTarget.dataset.id;
        } else if (name == 'Pending') {
            tabname = 'Request';
            labelval = 'Pending';
            prodId = event.currentTarget.dataset.id;
        }

        let productid = prodId;
        this.updatenotification(labelval, productid);
        let pageapi;
        let pagename;

        console.log({tabname});

        getSiteNameAndAPIName({ pageName: 'Librarydetail' })
            .then((result) => {
                console.log({ result });
                pageapi = result.siteName;
                pagename = result.siteAPIName;
                // 
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        name: pageapi,
                        url: pagename + '?recordId=' + prodId + '&tab=' + tabname
                    }
                });

                if (proddname) {
                    this.fireDataClickEvent('button', '', '', "view request", pageapi, pagename + '?recordId=' + prodId + '&tab=' + tabname , proddname); //RT UAT Bug
                } else {
                    this.fireDataClickEvent('button', '', '', "view request", pageapi, pagename + '?recordId=' + prodId + '&tab=' + tabname , ''); //RT UAT Bug
                }
                
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });

    }

    updatenotification(labelval, productid) {
        updatenotification({ userid: USER_ID, label: labelval, prodId: productid })
            .then((result) => {
                console.log('::::RESULT updatenotification::::');
                console.log(this.productName);
                console.log(this.recId);
                console.log({ result });
            })
            .catch((error) => {
                console.log('::::ERROR updatenotification::::');
                console.log({ error });
            })
    }

    // Navigate Pages
    navigatepage(event) {

        let getnameval = event.currentTarget.dataset.name;
        let proddname = event.currentTarget.dataset.prod;
        console.log({proddname});
        console.log({ getnameval });
        let recId;
        if (getnameval == 'Librarydetail') {
            recId = event.currentTarget.dataset.id;
            console.log({ recId });
        }

        let pageapi;
        let pagename;

        getSiteNameAndAPIName({ pageName: getnameval })
            .then((result) => {
                console.log({ result });
                pageapi = result.siteName;
                pagename = result.siteAPIName;
            })
            .catch((error) => {
                console.log({ error });
                this.error = error;
            });
        setTimeout(() => {

            if (getnameval == 'ProductList') {
                if (proddname) {
                    this.fireDataClickEvent('button', '', '', 'browse catalog', pageapi, pagename,proddname);
                } else {
                    this.fireDataClickEvent('button', '', '', 'browse catalog', pageapi, pagename,'');
                }
                this[NavigationMixin.Navigate]({
                    // type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: pageapi,
                        url: pagename
                    },
                });
            } else if (getnameval == 'Library') {
                this[NavigationMixin.Navigate]({
                    // type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: pageapi,
                        url: pagename
                    },
                });
            }
            else if (getnameval == 'MyContacts') {
                this[NavigationMixin.Navigate]({
                    // type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: pageapi,
                        url: pagename
                    },
                });
            } else if (getnameval == 'Librarydetail') {

                let tabname = 'Activity';

                this.updatenotification(tabname, recId);


                if (proddname) {
                    this.fireDataClickEvent('button', '', '', "view request", pageapi, pagename + '?recordId=' + recId + '&tab=' + tabname , proddname); //RT UAT Bug
                } else {
                    this.fireDataClickEvent('button', '', '', "view request", pageapi, pagename + '?recordId=' + recId + '&tab=' + tabname , ''); //RT UAT Bug
                }
                //console.log('prodname>>'+event.currentTarget.dataset.pname);
                console.log('Tab name=' + tabname + '<<>>' + recId);
                this[NavigationMixin.Navigate]({
                    // type: 'comm__namedPage',
                    type: 'standard__webPage',
                    attributes: {
                        name: pageapi,
                        url: pagename + '?recordId=' + recId + '&tab=' + tabname
                    }

                });
            }
        }, 1200);
    }

    //Google Analytics Event
    fireDataClickEvent(category, action, module, label, linkedtext, linkedurl, prodname) {
        this.dispatchEvent(new CustomEvent('fireDataClickEvent', {
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
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: prodname,
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'notification',
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
                page_type: 'menu',
                page_purpose: 'notifications',
                page_audience: 'payor',
                page_marketname: 'united_states',
                page_region: 'us',
                page_contentclassification: 'non-commercial',
                link_text: 'notification__c',
                link_url: '/menu/notification',
                content_saved: '',
                content_appointments: '',
                content_requests: '',
                content_name: '',
                page_localproductname: '',
                content_count: '',
                sfmc_id: USER_ID,
                sfmc_audience: this.contactrole,
                page_url: location.href,
                page_title: 'notification',
            },
            bubbles: true,
            composed: true
        }));
    }
}